import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/price_text.dart';
import '../../core/widgets/app_footer.dart';
import '../../core/widgets/app_banner.dart';
import '../../data/models/hotel_model.dart';
import '../../data/models/selected_room.dart';
import '../../data/repositories/booking_repository.dart';
import '../../data/repositories/hotelbeds_booking_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show Supabase;
import '../../core/services/payment_service.dart';
import '../../localization/app_localizations.dart';
import '../legal/dispute_resolution_page.dart';
import '../legal/privacy_notice_page.dart';
import '../legal/terms_of_service_page.dart';
import '../../core/constants/legal_versions.dart';

final bookingRepositoryProvider = Provider((ref) => BookingRepository());
final paymentServiceProvider = Provider((ref) => PaymentService());
final hotelBedsBookingRepositoryProvider = Provider((ref) => HotelBedsBookingRepository());

/// نص حسب لغة التطبيق (اللغات التسع).
String _tb(
    BuildContext context, {
      required String ar,
      required String en,
      required String es,
      required String tr,
      required String id,
      required String hi,
      required String ur,
      required String fr,
      required String bn,
    }) {
  switch (Localizations.localeOf(context).languageCode) {
    case 'ar':
      return ar;
    case 'es':
      return es;
    case 'tr':
      return tr;
    case 'id':
      return id;
    case 'hi':
      return hi;
    case 'ur':
      return ur;
    case 'fr':
      return fr;
    case 'bn':
      return bn;
    default:
      return en;
  }
}

/// "BED AND BREAKFAST" → "Bed And Breakfast"
String _titleCase(String s) => s
    .toLowerCase()
    .split(' ')
    .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
    .join(' ');

String _usd(double v) => '\$${v.toStringAsFixed(2)} USD';

/// ينظّف نصوص HotelBeds من الرموز التالفة (�) والمحارف غير المرئية/الخاصة
/// التي تظهر كمربعات أو رموز غريبة، ويوحّد المسافات.
String _cleanSupplierText(String s) => s
    .replaceAll(RegExp(r'[�-\u0000-\u0008\u000B\u000C\u000E-\u001F\u007F-\u009F]'), ' ')
    .replaceAll(RegExp(r'[ \t]{2,}'), ' ')
    .trim();

/// Stripe غير مدعوم حاليًا إلا على Android/iOS (وWeb إن تم إعداده لاحقًا).
/// على أنظمة سطح المكتب (Windows/macOS/Linux) نتخطى الدفع الفعلي مؤقتًا
/// ونسجّل الحجز بحالة "قيد الانتظار" ليتم إتمام الدفع لاحقًا من جهاز مدعوم.
bool get _isStripeSupportedPlatform {
  if (kIsWeb) return true;
  return defaultTargetPlatform == TargetPlatform.android ||
      defaultTargetPlatform == TargetPlatform.iOS;
}

class BookingPage extends ConsumerStatefulWidget {
  final HotelModel hotel;
  final DateTime checkIn;
  final DateTime checkOut;
  final int guests;

  /// أنواع الغرف المختارة مع كمية كل نوع (يدعم اختيار أكتر من نوع غرفة
  /// في نفس الحجز). لو القائمة فاضية أو لم تُمرَّر، يُستخدم السعر
  /// الأساسي للفندق كنوع غرفة افتراضي بكمية 1.
  final List<SelectedRoom>? selectedRooms;

  const BookingPage({
    super.key,
    required this.hotel,
    required this.checkIn,
    required this.checkOut,
    required this.guests,
    this.selectedRooms,
  });

  @override
  ConsumerState<BookingPage> createState() => _BookingPageState();
}

class _BookingPageState extends ConsumerState<BookingPage> {
  bool _isSubmitting = false;
  String? _errorMessage;

  // بيانات صاحب الحجز (فنادق HotelBeds فقط) — كما في الهوية.
  final _holderFormKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();

  // الموافقة على الشروط (التحكيم) + إقرار ولاية الإقامة (Seller of Travel).
  bool _acceptedTerms = false;
  bool _confirmedResidency = false;

  /// هل مُلئت بيانات صاحب الحجز تلقائيًا من حجز سابق/الملف الشخصي؟
  bool _prefilled = false;

  /// غرفة HotelBeds المختارة (null للفنادق المحلية).
  SelectedRoom? get _hbRoom {
    final rooms = widget.selectedRooms;
    if (rooms == null || rooms.isEmpty) return null;
    return rooms.first.isHotelBeds ? rooms.first : null;
  }

  @override
  void initState() {
    super.initState();
    _emailController.text = Supabase.instance.client.auth.currentUser?.email ?? '';
    _prefillHolder();
  }

  /// يملأ بيانات صاحب الحجز تلقائيًا من آخر حجز للعميل (ثم من ملفه الشخصي)،
  /// فلا يكتبها كل مرة. تبقى الحقول قابلة للتعديل (قد يحجز لشخص آخر).
  /// لا نملأ إلا الحقول الفارغة، وأي خطأ هنا يُتجاهل بصمت.
  Future<void> _prefillHolder() async {
    final client = Supabase.instance.client;
    final userId = client.auth.currentUser?.id;
    if (userId == null) return;

    String? first, last, phone, email;
    try {
      final rows = await client
          .from('bookings')
          .select()
          .eq('user_id', userId)
          .eq('supplier', 'hotelbeds')
          .not('holder_first_name', 'is', null)
          .order('created_at', ascending: false)
          .limit(1);
      if (rows.isNotEmpty) {
        final r = rows.first;
        first = r['holder_first_name'] as String?;
        last = r['holder_last_name'] as String?;
        phone = (r['holder_phone'] ?? r['phone']) as String?;
        email = r['holder_email'] as String?;
      }
    } catch (_) {}

    if (phone == null || first == null) {
      try {
        final p = await client
            .from('profiles')
            .select('full_name, phone')
            .eq('id', userId)
            .maybeSingle();
        if (p != null) {
          phone ??= p['phone'] as String?;
          final full = (p['full_name'] as String?)?.trim() ?? '';
          if (first == null && full.isNotEmpty) {
            final parts = full.split(RegExp(r'\s+'));
            first = parts.first;
            if (parts.length > 1) last ??= parts.sublist(1).join(' ');
          }
        }
      } catch (_) {}
    }

    if (!mounted) return;
    void fill(TextEditingController c, String? v) {
      if (c.text.trim().isEmpty && v != null && v.trim().isNotEmpty) c.text = v.trim();
    }
    setState(() {
      _prefilled = first != null && first!.trim().isNotEmpty;
      fill(_firstNameController, first);
      fill(_lastNameController, last);
      fill(_phoneController, phone);
      fill(_emailController, email);
    });
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  int get _nights => widget.checkOut.difference(widget.checkIn).inDays;

  List<SelectedRoom> get _rooms =>
      (widget.selectedRooms != null && widget.selectedRooms!.isNotEmpty)
          ? widget.selectedRooms!
          : [
        SelectedRoom(
          label: '',
          pricePerNight: widget.hotel.pricePerNight,
          quantity: 1,
        ),
      ];

  double get _subtotalPerNight =>
      _rooms.fold(0, (sum, room) => sum + room.subtotalPerNight);

  double get _totalPrice => _subtotalPerNight * _nights;

  // ═══════════════════════ حجز HotelBeds الحقيقي ═══════════════════════
  //
  // 1) hotelbeds-prepare: CheckRate + السعر النهائي + ملاحظات الفندق + PaymentIntent.
  // 2) مراجعة: يرى العميل السعر النهائي بالدولار وسياسة الإلغاء والملاحظات ويوافق.
  // 3) البطاقة: يُحجز المبلغ فقط (لا يُسحب).
  // 4) hotelbeds-book: الحجز عند HotelBeds ثم السحب، أو الإلغاء إن فشل.

  Future<void> _confirmHotelBedsBooking(SelectedRoom room) async {
    if (!(_holderFormKey.currentState?.validate() ?? false)) return;

    if (!_acceptedTerms || !_confirmedResidency) {
      setState(() => _errorMessage = _tb(context,
          ar: 'يُرجى الموافقة على الشروط وتأكيد ولاية الإقامة للمتابعة.',
          en: 'Please accept the terms and confirm your state of residence to continue.',
          es: 'Acepta los términos y confirma tu estado de residencia para continuar.',
          tr: 'Devam etmek için şartları kabul edin ve ikamet ettiğiniz eyaleti onaylayın.',
          id: 'Harap setujui ketentuan dan konfirmasi negara bagian tempat tinggal Anda untuk melanjutkan.',
          hi: 'जारी रखने के लिए कृपया शर्तें स्वीकार करें और अपने निवास राज्य की पुष्टि करें।',
          ur: 'جاری رکھنے کے لیے براہ کرم شرائط قبول کریں اور اپنی رہائشی ریاست کی تصدیق کریں۔',
          fr: 'Veuillez accepter les conditions et confirmer votre État de résidence pour continuer.',
          bn: 'চালিয়ে যেতে অনুগ্রহ করে শর্তাবলি মেনে নিন এবং আপনার বসবাসের রাজ্য নিশ্চিত করুন।'));
      return;
    }

    if (!_isStripeSupportedPlatform) {
      setState(() => _errorMessage = _tb(context,
          ar: 'الدفع متاح حاليًا من الموقع أو تطبيق الجوال فقط.',
          en: 'Payment is currently available on the website or mobile app only.',
          es: 'El pago solo está disponible en el sitio web o la app móvil.',
          tr: 'Ödeme şu anda yalnızca web sitesi veya mobil uygulamada kullanılabilir.',
          id: 'Pembayaran saat ini hanya tersedia di situs web atau aplikasi seluler.',
          hi: 'भुगतान अभी केवल वेबसाइट या मोबाइल ऐप पर उपलब्ध है।',
          ur: 'ادائیگی فی الحال صرف ویب سائٹ یا موبائل ایپ پر دستیاب ہے۔',
          fr: 'Le paiement est actuellement disponible uniquement sur le site ou l\'application mobile.',
          bn: 'পেমেন্ট এখন শুধু ওয়েবসাইট বা মোবাইল অ্যাপে উপলব্ধ।'));
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    final repo = ref.read(hotelBedsBookingRepositoryProvider);

    // 1) تثبيت السعر
    final quoteResult = await repo.prepare(
      rateKey: room.rateKey!,
      hotelCode: widget.hotel.id.replaceFirst('hb_', ''),
      hotelName: widget.hotel.name,
      hotelCity: widget.hotel.city,
      hotelImage: widget.hotel.images.isNotEmpty ? widget.hotel.images.first : null,
      roomName: room.label,
      checkIn: widget.checkIn,
      checkOut: widget.checkOut,
      guests: widget.guests,
      expectedPrice: room.totalPrice,
      expectedPriceUsd: room.priceUsd,
      holder: BookingHolder(
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        email: _emailController.text.trim(),
        phone: _phoneController.text.trim(),
      ),
      consent: BookingConsent(
        acceptedTerms: _acceptedTerms,
        confirmedResidency: _confirmedResidency,
        termsVersion: kTermsVersion,
        privacyVersion: kPrivacyVersion,
        locale: Localizations.localeOf(context).languageCode,
      ),
    );
    if (!mounted) return;

    HotelBedsQuote? quote;
    quoteResult.when(
      success: (q) {
        quote = q;
      },
      failure: (message) {
        setState(() {
          _isSubmitting = false;
          _errorMessage = message;
        });
      },
    );
    if (quote == null) return;

    // 2) مراجعة وموافقة العميل
    final agreed = await _showReviewDialog(quote!);
    if (!mounted) return;
    if (agreed != true) {
      setState(() => _isSubmitting = false);
      return;
    }

    // 3) البطاقة (حجز المبلغ فقط)
    final payResult = await ref
        .read(paymentServiceProvider)
        .confirmWithClientSecret(clientSecret: quote!.clientSecret, context: context);
    if (!mounted) return;

    var authorized = false;
    payResult.when(
      success: (_) {
        authorized = true;
      },
      failure: (message) {
        setState(() {
          _isSubmitting = false;
          _errorMessage = message;
        });
      },
    );
    if (!authorized) return;

    // 4) الحجز عند الفندق
    final bookResult = await repo.book(quote!.bookingId, reviewAccepted: true);
    if (!mounted) return;

    bookResult.when(
      success: (outcome) {
        setState(() => _isSubmitting = false);
        _showHotelBedsResultDialog(outcome);
      },
      failure: (message) {
        setState(() {
          _isSubmitting = false;
          _errorMessage = message;
        });
      },
    );
  }

  Future<bool?> _showReviewDialog(HotelBedsQuote quote) {
    final currentFee = quote.currentCancellationFee;
    final upcoming = quote.upcomingPolicies;
    final hasPolicies = quote.cancellationPolicies.isNotEmpty;

    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: Text(_tb(ctx,
            ar: 'راجع حجزك قبل الدفع', en: 'Review before payment', es: 'Revisa antes de pagar',
            tr: 'Ödemeden önce gözden geçirin', id: 'Tinjau sebelum membayar',
            hi: 'भुगतान से पहले समीक्षा करें', ur: 'ادائیگی سے پہلے جائزہ لیں',
            fr: 'Vérifiez avant de payer', bn: 'পেমেন্টের আগে পর্যালোচনা করুন')),
        content: SizedBox(
          width: 460,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  [
                    widget.hotel.name,
                    if (quote.roomName != null) quote.roomName!,
                    if (quote.boardName != null) _titleCase(quote.boardName!),
                  ].join(' · '),
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                if (quote.priceChanged) ...[
                  const SizedBox(height: AppSizes.sm),
                  Text(
                    _tb(ctx,
                        ar: 'تغيّر السعر منذ بحثك. السعر أدناه هو السعر النهائي.',
                        en: 'The price has changed since your search. The price below is final.',
                        es: 'El precio cambió desde tu búsqueda. El precio de abajo es el final.',
                        tr: 'Aramanızdan bu yana fiyat değişti. Aşağıdaki fiyat nihaidir.',
                        id: 'Harga berubah sejak pencarian Anda. Harga di bawah adalah harga final.',
                        hi: 'आपकी खोज के बाद कीमत बदल गई है। नीचे दी गई कीमत अंतिम है।',
                        ur: 'آپ کی تلاش کے بعد قیمت بدل گئی ہے۔ نیچے دی گئی قیمت حتمی ہے۔',
                        fr: 'Le prix a changé depuis votre recherche. Le prix ci-dessous est définitif.',
                        bn: 'আপনার অনুসন্ধানের পর দাম বদলেছে। নিচের দামটি চূড়ান্ত।'),
                    style: const TextStyle(color: AppColors.error, fontWeight: FontWeight.w600),
                  ),
                ],
                const SizedBox(height: AppSizes.md),
                // سياسة الإلغاء
                Text(
                  _tb(ctx,
                      ar: 'سياسة الإلغاء', en: 'Cancellation policy', es: 'Política de cancelación',
                      tr: 'İptal politikası', id: 'Kebijakan pembatalan', hi: 'रद्दीकरण नीति',
                      ur: 'منسوخی کی پالیسی', fr: 'Politique d\'annulation', bn: 'বাতিল নীতি'),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                if (quote.isNonRefundable)
                  Text(
                      style: const TextStyle(color: AppColors.error, fontWeight: FontWeight.bold),
                      _tb(ctx,
                          ar: 'غير قابل للاسترداد: يُخصم كامل المبلغ عند الإلغاء.',
                          en: 'Non-refundable: the full amount is charged if you cancel.',
                          es: 'No reembolsable: se cobra el importe total si cancelas.',
                          tr: 'İade edilmez: iptal ederseniz tutarın tamamı tahsil edilir.',
                          id: 'Tidak dapat dikembalikan: jumlah penuh dikenakan jika Anda membatalkan.',
                          hi: 'नॉन-रिफ़ंडेबल: रद्द करने पर पूरी राशि ली जाएगी।',
                          ur: 'ناقابلِ واپسی: منسوخی پر پوری رقم وصول کی جائے گی۔',
                          fr: 'Non remboursable : le montant total est dû en cas d\'annulation.',
                          bn: 'অফেরতযোগ্য: বাতিল করলে পুরো টাকা কাটা হবে।'))
                else ...[
                  // الرسوم سارية من لحظة الحجز: نُبرزها بالأحمر ونذكر المبلغ من الإجمالي،
                  // حتى لا يظن العميل أن لديه إلغاءً مجانيًا.
                  if (currentFee > 0)
                    Text(_tb(ctx,
                        ar: 'غير قابل للاسترداد جزئيًا: إذا ألغيت تُخصم رسوم ${_usd(currentFee)} من ${_usd(quote.chargeAmount)}، ابتداءً من لحظة الحجز.',
                        en: 'Partially non-refundable: if you cancel, a fee of ${_usd(currentFee)} of ${_usd(quote.chargeAmount)} applies from the moment you book.',
                        es: 'Parcialmente no reembolsable: si cancelas, se cobra ${_usd(currentFee)} de ${_usd(quote.chargeAmount)} desde el momento de la reserva.',
                        tr: 'Kısmen iade edilmez: iptal ederseniz, rezervasyon anından itibaren ${_usd(quote.chargeAmount)} tutarın ${_usd(currentFee)} kadarı ücret olarak alınır.',
                        id: 'Sebagian tidak dapat dikembalikan: jika membatalkan, dikenakan biaya ${_usd(currentFee)} dari ${_usd(quote.chargeAmount)} sejak saat pemesanan.',
                        hi: 'आंशिक रूप से नॉन-रिफ़ंडेबल: रद्द करने पर बुकिंग के समय से ${_usd(quote.chargeAmount)} में से ${_usd(currentFee)} शुल्क लगेगा।',
                        ur: 'جزوی طور پر ناقابلِ واپسی: منسوخی پر بکنگ کے وقت سے ${_usd(quote.chargeAmount)} میں سے ${_usd(currentFee)} فیس لاگو ہوگی۔',
                        fr: 'Partiellement non remboursable : en cas d\'annulation, des frais de ${_usd(currentFee)} sur ${_usd(quote.chargeAmount)} s\'appliquent dès la réservation.',
                        bn: 'আংশিক অফেরতযোগ্য: বাতিল করলে বুকিংয়ের মুহূর্ত থেকে ${_usd(quote.chargeAmount)}-এর মধ্যে ${_usd(currentFee)} ফি কাটা হবে।'),
                        style: const TextStyle(color: AppColors.error, fontWeight: FontWeight.bold))
                  else if (upcoming.isNotEmpty)
                    Text(_tb(ctx,
                        ar: 'إلغاء مجاني حتى ${upcoming.first.localDateTimeText} (بتوقيت الفندق).',
                        en: 'Free cancellation until ${upcoming.first.localDateTimeText} (hotel local time).',
                        es: 'Cancelación gratuita hasta el ${upcoming.first.localDateTimeText} (hora local del hotel).',
                        tr: '${upcoming.first.localDateTimeText} tarihine kadar ücretsiz iptal (otel yerel saati).',
                        id: 'Pembatalan gratis hingga ${upcoming.first.localDateTimeText} (waktu setempat hotel).',
                        hi: '${upcoming.first.localDateTimeText} तक मुफ़्त रद्दीकरण (होटल का स्थानीय समय)।',
                        ur: '${upcoming.first.localDateTimeText} تک مفت منسوخی (ہوٹل کا مقامی وقت)۔',
                        fr: 'Annulation gratuite jusqu\'au ${upcoming.first.localDateTimeText} (heure locale de l\'hôtel).',
                        bn: '${upcoming.first.localDateTimeText} পর্যন্ত বিনামূল্যে বাতিল (হোটেলের স্থানীয় সময়)।'))
                  else if (!hasPolicies)
                      Text(_tb(ctx,
                          ar: 'إلغاء مجاني.', en: 'Free cancellation.', es: 'Cancelación gratuita.',
                          tr: 'Ücretsiz iptal.', id: 'Pembatalan gratis.', hi: 'मुफ़्त रद्दीकरण।',
                          ur: 'مفت منسوخی۔', fr: 'Annulation gratuite.', bn: 'বিনামূল্যে বাতিল।')),
                  for (final p in upcoming)
                    Text(
                      _tb(ctx,
                          ar: 'من ${p.localDateTimeText}: رسوم ${_usd(p.customerFee)}',
                          en: 'From ${p.localDateTimeText}: fee ${_usd(p.customerFee)}',
                          es: 'Desde el ${p.localDateTimeText}: cargo de ${_usd(p.customerFee)}',
                          tr: '${p.localDateTimeText} itibarıyla: ${_usd(p.customerFee)} ücret',
                          id: 'Mulai ${p.localDateTimeText}: biaya ${_usd(p.customerFee)}',
                          hi: '${p.localDateTimeText} से: शुल्क ${_usd(p.customerFee)}',
                          ur: '${p.localDateTimeText} سے: فیس ${_usd(p.customerFee)}',
                          fr: 'À partir du ${p.localDateTimeText} : frais de ${_usd(p.customerFee)}',
                          bn: '${p.localDateTimeText} থেকে: ফি ${_usd(p.customerFee)}'),
                      style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                    ),
                ],
                // ملاحظات الفندق (إلزامية قبل الدفع)
                if (quote.rateComments != null && quote.rateComments!.isNotEmpty) ...[
                  const SizedBox(height: AppSizes.md),
                  Text(
                    _tb(ctx,
                        ar: 'معلومات مهمة من الفندق', en: 'Important information from the hotel',
                        es: 'Información importante del hotel', tr: 'Otelden önemli bilgiler',
                        id: 'Informasi penting dari hotel', hi: 'होटल की महत्वपूर्ण जानकारी',
                        ur: 'ہوٹل کی اہم معلومات', fr: 'Informations importantes de l\'hôtel',
                        bn: 'হোটেলের গুরুত্বপূর্ণ তথ্য'),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _cleanSupplierText(quote.rateComments!),
                    style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                  ),
                ],
                const Divider(height: AppSizes.lg * 2),
                // الرسوم الإلزامية التي تُدفع في الفندق — تظهر قبل الدفع (FTC).
                if (quote.payAtHotelUsd > 0) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(_tb(ctx,
                            ar: 'رسوم تُدفع في الفندق (تقديرية، بالعملة المحلية)',
                            en: 'Fees payable at the hotel (estimate, in local currency)',
                            es: 'Tasas a pagar en el hotel (estimado, en moneda local)',
                            tr: 'Otelde ödenecek ücretler (tahmini, yerel para birimi)',
                            id: 'Biaya dibayar di hotel (perkiraan, mata uang lokal)',
                            hi: 'होटल में देय शुल्क (अनुमानित, स्थानीय मुद्रा में)',
                            ur: 'ہوٹل میں قابلِ ادائیگی فیس (تخمینہ، مقامی کرنسی میں)',
                            fr: 'Frais à payer à l\'hôtel (estimation, en devise locale)',
                            bn: 'হোটেলে প্রদেয় ফি (আনুমানিক, স্থানীয় মুদ্রায়)')),
                      ),
                      Text(_usd(quote.payAtHotelUsd)),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(_tb(ctx,
                            ar: 'السعر الإجمالي للإقامة', en: 'Total price of your stay',
                            es: 'Precio total de tu estancia', tr: 'Konaklamanın toplam fiyatı',
                            id: 'Total harga menginap', hi: 'आपके ठहराव की कुल कीमत',
                            ur: 'آپ کے قیام کی کل قیمت', fr: 'Prix total de votre séjour',
                            bn: 'আপনার থাকার মোট মূল্য')),
                      ),
                      Text(_usd(quote.totalUsd),
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                    ],
                  ),
                  const SizedBox(height: AppSizes.sm),
                ],
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        _tb(ctx,
                            ar: 'المبلغ الإجمالي', en: 'Total charge', es: 'Cargo total',
                            tr: 'Toplam tutar', id: 'Total tagihan', hi: 'कुल शुल्क',
                            ur: 'کل رقم', fr: 'Montant total', bn: 'মোট চার্জ'),
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ),
                    Text(
                      _usd(quote.chargeAmount),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  _tb(ctx,
                      ar: 'يُحجز المبلغ على بطاقتك ولا يُسحب إلا بعد تأكيد الفندق.',
                      en: 'The amount is held on your card and only charged once the hotel confirms.',
                      es: 'El importe se retiene en tu tarjeta y solo se cobra cuando el hotel confirma.',
                      tr: 'Tutar kartınızda bloke edilir ve yalnızca otel onayladığında tahsil edilir.',
                      id: 'Jumlah ditahan di kartu Anda dan baru ditagih setelah hotel mengonfirmasi.',
                      hi: 'राशि आपके कार्ड पर होल्ड की जाती है और होटल की पुष्टि के बाद ही ली जाती है।',
                      ur: 'رقم آپ کے کارڈ پر روکی جاتی ہے اور ہوٹل کی تصدیق کے بعد ہی وصول ہوتی ہے۔',
                      fr: 'Le montant est bloqué sur votre carte et débité seulement après confirmation de l\'hôtel.',
                      bn: 'টাকাটি আপনার কার্ডে আটকে রাখা হয় এবং হোটেল নিশ্চিত করলে তবেই কাটা হয়।'),
                  style: const TextStyle(fontSize: 12, color: AppColors.textHint),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(_tb(ctx,
                ar: 'إلغاء', en: 'Cancel', es: 'Cancelar', tr: 'Vazgeç', id: 'Batal',
                hi: 'रद्द करें', ur: 'منسوخ کریں', fr: 'Annuler', bn: 'বাতিল')),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(_tb(ctx,
                ar: 'أوافق وأتابع للدفع', en: 'Agree and pay', es: 'Aceptar y pagar',
                tr: 'Kabul et ve öde', id: 'Setuju dan bayar', hi: 'सहमत हूं और भुगतान करें',
                ur: 'متفق ہوں اور ادائیگی کریں', fr: 'Accepter et payer', bn: 'সম্মত ও পেমেন্ট')),
          ),
        ],
      ),
    );
  }

  void _showHotelBedsResultDialog(HotelBedsBookingOutcome outcome) {
    final confirmed = outcome.isConfirmed;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        icon: Icon(
          confirmed ? Icons.check_circle : Icons.hourglass_top,
          color: confirmed ? AppColors.success : AppColors.primary,
          size: 48,
        ),
        title: Text(confirmed
            ? _tb(ctx,
            ar: 'تم تأكيد حجزك', en: 'Your booking is confirmed', es: 'Tu reserva está confirmada',
            tr: 'Rezervasyonunuz onaylandı', id: 'Pemesanan Anda dikonfirmasi',
            hi: 'आपकी बुकिंग की पुष्टि हो गई', ur: 'آپ کی بکنگ کی تصدیق ہو گئی',
            fr: 'Votre réservation est confirmée', bn: 'আপনার বুকিং নিশ্চিত হয়েছে')
            : _tb(ctx,
            ar: 'حجزك قيد التأكيد', en: 'Your booking is being confirmed',
            es: 'Tu reserva se está confirmando', tr: 'Rezervasyonunuz onaylanıyor',
            id: 'Pemesanan Anda sedang dikonfirmasi', hi: 'आपकी बुकिंग की पुष्टि हो रही है',
            ur: 'آپ کی بکنگ کی تصدیق ہو رہی ہے', fr: 'Votre réservation est en cours de confirmation',
            bn: 'আপনার বুকিং নিশ্চিত করা হচ্ছে')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(widget.hotel.name, textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: AppSizes.sm),
            if (confirmed && outcome.reference != null)
              SelectableText(
                '${_tb(ctx, ar: 'رقم الحجز', en: 'Booking reference', es: 'Referencia de reserva', tr: 'Rezervasyon numarası', id: 'Nomor pemesanan', hi: 'बुकिंग संदर्भ', ur: 'بکنگ نمبر', fr: 'Référence de réservation', bn: 'বুকিং রেফারেন্স')}: ${outcome.reference}',
                textAlign: TextAlign.center,
              )
            else
              Text(
                _tb(ctx,
                    ar: 'لم يُسحب أي مبلغ بعد. سنراجع حجزك ونتواصل معك قريبًا. مرجعك: ${outcome.clientReference}',
                    en: 'Nothing has been charged yet. We are reviewing your booking and will contact you shortly. Your reference: ${outcome.clientReference}',
                    es: 'Aún no se ha cobrado nada. Estamos revisando tu reserva y te contactaremos pronto. Tu referencia: ${outcome.clientReference}',
                    tr: 'Henüz ücret alınmadı. Rezervasyonunuzu inceliyoruz ve kısa süre içinde sizinle iletişime geçeceğiz. Referansınız: ${outcome.clientReference}',
                    id: 'Belum ada tagihan. Kami sedang meninjau pemesanan Anda dan akan segera menghubungi Anda. Referensi Anda: ${outcome.clientReference}',
                    hi: 'अभी कोई राशि नहीं ली गई है। हम आपकी बुकिंग की समीक्षा कर रहे हैं और जल्द संपर्क करेंगे। आपका संदर्भ: ${outcome.clientReference}',
                    ur: 'ابھی کوئی رقم وصول نہیں کی گئی۔ ہم آپ کی بکنگ کا جائزہ لے رہے ہیں اور جلد رابطہ کریں گے۔ آپ کا حوالہ: ${outcome.clientReference}',
                    fr: 'Rien n\'a encore été débité. Nous vérifions votre réservation et vous contacterons rapidement. Votre référence : ${outcome.clientReference}',
                    bn: 'এখনও কোনো টাকা কাটা হয়নি। আমরা আপনার বুকিং পর্যালোচনা করছি এবং শীঘ্রই যোগাযোগ করব। আপনার রেফারেন্স: ${outcome.clientReference}'),
                textAlign: TextAlign.center,
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              context.pop();
            },
            child: Text(AppLocalizations.of(ctx)!.ok),
          ),
        ],
      ),
    );
  }

  Widget _holderForm(BuildContext context) {
    String? requiredField(String? v) => (v == null || v.trim().isEmpty)
        ? _tb(context,
        ar: 'مطلوب', en: 'Required', es: 'Obligatorio', tr: 'Zorunlu', id: 'Wajib',
        hi: 'आवश्यक', ur: 'ضروری', fr: 'Obligatoire', bn: 'আবশ্যক')
        : null;

    InputDecoration deco(String label) => InputDecoration(
      labelText: label,
      border: const OutlineInputBorder(),
      isDense: true,
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.md),
        child: Form(
          key: _holderFormKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _tb(context,
                    ar: 'بيانات صاحب الحجز (كما في الهوية)',
                    en: 'Main guest details (as on ID)',
                    es: 'Datos del huésped principal (como en el documento)',
                    tr: 'Ana misafir bilgileri (kimlikteki gibi)',
                    id: 'Data tamu utama (sesuai identitas)',
                    hi: 'मुख्य अतिथि का विवरण (पहचान पत्र के अनुसार)',
                    ur: 'مرکزی مہمان کی تفصیلات (شناختی کارڈ کے مطابق)',
                    fr: 'Coordonnées du client principal (comme sur la pièce d\'identité)',
                    bn: 'প্রধান অতিথির তথ্য (পরিচয়পত্র অনুযায়ী)'),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              if (_prefilled) const SizedBox(height: 2),
              if (_prefilled)
                Text(
                  _tb(context,
                      ar: 'تُملأ تلقائيًا من حجزك السابق. إذا كنت تحجز لشخص آخر، اكتب اسمه كما في هويته.',
                      en: 'Filled in from your last booking. Booking for someone else? Enter their name as on their ID.',
                      es: 'Completado con tu última reserva. ¿Reservas para otra persona? Escribe su nombre como en su documento.',
                      tr: 'Son rezervasyonunuzdan dolduruldu. Başkası için mi rezervasyon yapıyorsunuz? Kimliğindeki adını yazın.',
                      id: 'Diisi dari pemesanan terakhir Anda. Memesan untuk orang lain? Tulis namanya sesuai identitasnya.',
                      hi: 'आपकी पिछली बुकिंग से भरा गया। किसी और के लिए बुक कर रहे हैं? उनका नाम पहचान पत्र के अनुसार लिखें।',
                      ur: 'آپ کی پچھلی بکنگ سے بھرا گیا۔ کسی اور کے لیے بک کر رہے ہیں؟ ان کا نام شناختی کارڈ کے مطابق لکھیں۔',
                      fr: 'Rempli à partir de votre dernière réservation. Vous réservez pour quelqu\'un d\'autre ? Saisissez son nom comme sur sa pièce d\'identité.',
                      bn: 'আপনার আগের বুকিং থেকে পূরণ করা হয়েছে। অন্য কারও জন্য বুক করছেন? তার পরিচয়পত্র অনুযায়ী নাম লিখুন।'),
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
              const SizedBox(height: AppSizes.sm),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _firstNameController,
                      textCapitalization: TextCapitalization.words,
                      decoration: deco(_tb(context,
                          ar: 'الاسم الأول', en: 'First name', es: 'Nombre', tr: 'Ad',
                          id: 'Nama depan', hi: 'पहला नाम', ur: 'پہلا نام', fr: 'Prénom',
                          bn: 'নামের প্রথম অংশ')),
                      validator: requiredField,
                    ),
                  ),
                  const SizedBox(width: AppSizes.sm),
                  Expanded(
                    child: TextFormField(
                      controller: _lastNameController,
                      textCapitalization: TextCapitalization.words,
                      decoration: deco(_tb(context,
                          ar: 'اسم العائلة', en: 'Last name', es: 'Apellido', tr: 'Soyad',
                          id: 'Nama belakang', hi: 'उपनाम', ur: 'خاندانی نام', fr: 'Nom',
                          bn: 'নামের শেষ অংশ')),
                      validator: requiredField,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSizes.sm),
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: deco(_tb(context,
                    ar: 'البريد الإلكتروني', en: 'Email', es: 'Correo electrónico', tr: 'E-posta',
                    id: 'Email', hi: 'ईमेल', ur: 'ای میل', fr: 'E-mail', bn: 'ইমেইল')),
                validator: requiredField,
              ),
              const SizedBox(height: AppSizes.sm),
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: deco(_tb(context,
                    ar: 'رقم الهاتف', en: 'Phone number', es: 'Teléfono', tr: 'Telefon',
                    id: 'Nomor telepon', hi: 'फ़ोन नंबर', ur: 'فون نمبر', fr: 'Téléphone',
                    bn: 'ফোন নম্বর')),
                validator: requiredField,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// مربعا الموافقة قبل الدفع (حجوزات HotelBeds).
  ///
  /// ⚠️ لا تحذفهما ولا تجعلهما مُعلَّمين مسبقًا: الموافقة الصريحة هي ما يجعل
  /// بند التحكيم في شروط الخدمة قابلًا للتنفيذ (clickwrap).
  Widget _consentSection(BuildContext context) {
    void open(Widget page) =>
        Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));

    Widget link(String label, Widget page) => TextButton(
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 6),
        minimumSize: const Size(0, 32),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      onPressed: () => open(page),
      child: Text(label, style: const TextStyle(decoration: TextDecoration.underline)),
    );

    Widget check({
      required bool value,
      required ValueChanged<bool> onChanged,
      required String text,
    }) =>
        CheckboxListTile(
          value: value,
          onChanged: _isSubmitting ? null : (v) => onChanged(v ?? false),
          controlAffinity: ListTileControlAffinity.leading,
          contentPadding: EdgeInsets.zero,
          dense: true,
          title: Text(text, style: const TextStyle(fontSize: 13, height: 1.4)),
        );

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSizes.md, vertical: AppSizes.sm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            check(
              value: _acceptedTerms,
              onChanged: (v) => setState(() {
                _acceptedTerms = v;
                if (v && _confirmedResidency) _errorMessage = null;
              }),
              text: _tb(context,
                  ar: 'قرأت شروط الخدمة وأوافق عليها، بما فيها اتفاقية التحكيم الملزم والتنازل عن الدعوى الجماعية، وأوافق على إشعار الخصوصية.',
                  en: 'I have read and agree to the Terms of Service, including the binding arbitration agreement and class action waiver, and the Privacy Notice.',
                  es: 'He leído y acepto los Términos del servicio, incluido el acuerdo de arbitraje vinculante y la renuncia a demandas colectivas, y el Aviso de privacidad.',
                  tr: 'Bağlayıcı tahkim sözleşmesi ve toplu dava feragati dahil Hizmet Şartlarını ve Gizlilik Bildirimini okudum ve kabul ediyorum.',
                  id: 'Saya telah membaca dan menyetujui Ketentuan Layanan, termasuk perjanjian arbitrase yang mengikat dan pengesampingan gugatan kelompok, serta Pemberitahuan Privasi.',
                  hi: 'मैंने सेवा की शर्तें, जिनमें बाध्यकारी मध्यस्थता समझौता और सामूहिक मुकदमे का त्याग शामिल है, और गोपनीयता सूचना पढ़ ली है और उनसे सहमत हूं।',
                  ur: 'میں نے سروس کی شرائط، بشمول لازمی ثالثی معاہدہ اور اجتماعی مقدمے سے دستبرداری، اور رازداری کا نوٹس پڑھ لیا ہے اور ان سے متفق ہوں۔',
                  fr: 'J\'ai lu et j\'accepte les Conditions d\'utilisation, y compris la convention d\'arbitrage contraignant et la renonciation aux actions collectives, ainsi que l\'Avis de confidentialité.',
                  bn: 'আমি পরিষেবার শর্তাবলি, বাধ্যতামূলক সালিশি চুক্তি ও সম্মিলিত মামলা পরিত্যাগসহ, এবং গোপনীয়তা বিজ্ঞপ্তি পড়েছি ও সম্মত হচ্ছি।'),
            ),
            Padding(
              padding: const EdgeInsetsDirectional.only(start: 40),
              child: Wrap(
                spacing: 4,
                children: [
                  link(
                    _tb(context,
                        ar: 'شروط الخدمة', en: 'Terms of Service', es: 'Términos del servicio',
                        tr: 'Hizmet Şartları', id: 'Ketentuan Layanan', hi: 'सेवा की शर्तें',
                        ur: 'سروس کی شرائط', fr: 'Conditions d\'utilisation', bn: 'পরিষেবার শর্তাবলি'),
                    const TermsOfServicePage(),
                  ),
                  link(
                    _tb(context,
                        ar: 'حل النزاعات', en: 'Dispute Resolution', es: 'Resolución de disputas',
                        tr: 'Uyuşmazlık Çözümü', id: 'Penyelesaian Sengketa', hi: 'विवाद समाधान',
                        ur: 'تنازعات کا حل', fr: 'Règlement des litiges', bn: 'বিরোধ নিষ্পত্তি'),
                    const DisputeResolutionPage(),
                  ),
                  link(
                    _tb(context,
                        ar: 'إشعار الخصوصية', en: 'Privacy Notice', es: 'Aviso de privacidad',
                        tr: 'Gizlilik Bildirimi', id: 'Pemberitahuan Privasi', hi: 'गोपनीयता सूचना',
                        ur: 'رازداری کا نوٹس', fr: 'Avis de confidentialité', bn: 'গোপনীয়তা বিজ্ঞপ্তি'),
                    const PrivacyNoticePage(),
                  ),
                ],
              ),
            ),
            check(
              value: _confirmedResidency,
              onChanged: (v) => setState(() {
                _confirmedResidency = v;
                if (v && _acceptedTerms) _errorMessage = null;
              }),
              text: _tb(context,
                  ar: 'أؤكد أنني لست مقيمًا في كاليفورنيا أو فلوريدا أو هاواي أو واشنطن.',
                  en: 'I confirm that I am not a resident of California, Florida, Hawaii, or Washington.',
                  es: 'Confirmo que no resido en California, Florida, Hawái ni Washington.',
                  tr: 'California, Florida, Hawaii veya Washington\'da ikamet etmediğimi onaylıyorum.',
                  id: 'Saya menyatakan bahwa saya bukan penduduk California, Florida, Hawaii, atau Washington.',
                  hi: 'मैं पुष्टि करता/करती हूं कि मैं कैलिफ़ोर्निया, फ़्लोरिडा, हवाई या वॉशिंगटन का निवासी नहीं हूं।',
                  ur: 'میں تصدیق کرتا/کرتی ہوں کہ میں کیلیفورنیا، فلوریڈا، ہوائی یا واشنگٹن کا رہائشی نہیں ہوں۔',
                  fr: 'Je confirme ne pas résider en Californie, en Floride, à Hawaï ou dans l\'État de Washington.',
                  bn: 'আমি নিশ্চিত করছি যে আমি ক্যালিফোর্নিয়া, ফ্লোরিডা, হাওয়াই বা ওয়াশিংটনের বাসিন্দা নই।'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmBooking() async {
    final hbRoom = _hbRoom;
    if (hbRoom != null) {
      await _confirmHotelBedsBooking(hbRoom);
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    // على المنصات غير المدعومة من Stripe (سطح المكتب حاليًا)، نتخطى
    // خطوة الدفع الفعلي ونسجّل الحجز مباشرة بحالة "قيد الانتظار".
    if (!_isStripeSupportedPlatform) {
      await _createBooking(status: 'pending');
      return;
    }

    // 1. نفّذ الدفع الفعلي أولاً عبر Stripe قبل أي تسجيل بقاعدة البيانات
    final paymentService = ref.read(paymentServiceProvider);
    final paymentResult = await paymentService.pay(amount: _totalPrice, context: context);
    if (!mounted) return;

    final paymentSucceeded = paymentResult.when(
      success: (_) => true,
      failure: (message) {
        setState(() {
          _isSubmitting = false;
          _errorMessage = message;
        });
        return false;
      },
    );

    if (!paymentSucceeded) return;

    // 2. الدفع نجح فعليًا -> سجّل الحجز بحالة "مؤكد" مباشرة
    await _createBooking(status: 'confirmed');
  }

  Future<void> _createBooking({required String status}) async {
    final l10n = AppLocalizations.of(context)!;
    final repo = ref.read(bookingRepositoryProvider);
    final result = await repo.createBooking(
      hotelId: widget.hotel.id,
      roomId: 'default',
      checkIn: widget.checkIn,
      checkOut: widget.checkOut,
      guests: widget.guests,
      totalPrice: _totalPrice,
      status: status,
      hotelName: widget.hotel.name,
      hotelCity: widget.hotel.city,
      hotelImages: widget.hotel.images,
    );

    if (!mounted) return;

    result.when(
      success: (booking) {
        setState(() => _isSubmitting = false);
        _showSuccessDialog();
      },
      failure: (message) {
        setState(() {
          _isSubmitting = false;
          // الدفع نجح فعليًا بس فشل تسجيل الحجز -- رسالة مترجمة توضح الوضع
          _errorMessage = status == 'confirmed'
              ? l10n.paymentSucceededBookingError(message)
              : l10n.bookingCreateError(message);
        });
      },
    );
  }

  void _showSuccessDialog() {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.check_circle, color: AppColors.success, size: 48),
        title: Text(l10n.bookingSuccessTitle),
        content: Text(
          '${widget.hotel.name}',
          textAlign: TextAlign.center,
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.pop();
            },
            child: Text(l10n.ok),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final rooms = _rooms;

    return Scaffold(
      appBar: const AppBanner(),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSizes.md),
          children: [
            Text(
              l10n.confirmBookingTitle,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppSizes.md),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppSizes.md),
                child: Row(
                  children: [
                    Container(
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                        color: AppColors.divider,
                        borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                        image: widget.hotel.images.isNotEmpty
                            ? DecorationImage(
                          image: NetworkImage(widget.hotel.images.first),
                          fit: BoxFit.cover,
                          onError: (_, __) {},
                        )
                            : null,
                      ),
                      child: widget.hotel.images.isEmpty
                          ? const Icon(Icons.hotel, color: AppColors.textHint)
                          : null,
                    ),
                    const SizedBox(width: AppSizes.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.hotel.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.hotel.city,
                            style: const TextStyle(color: AppColors.textSecondary),
                          ),
                          // عرض كل أنواع الغرف المختارة مع كمياتها
                          for (final room in rooms)
                            if (room.label.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  '${room.quantity} × ${room.label}',
                                  style: const TextStyle(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: AppSizes.md),

            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppSizes.md),
                child: Column(
                  children: [
                    _DetailRow(
                      icon: Icons.calendar_today_outlined,
                      label: l10n.checkInLabel,
                      value: Formatters.date(widget.checkIn),
                    ),
                    const Divider(),
                    _DetailRow(
                      icon: Icons.calendar_today_outlined,
                      label: l10n.checkOutLabel,
                      value: Formatters.date(widget.checkOut),
                    ),
                    const Divider(),
                    // عدد الليالي مترجم بصيغ الجمع الصحيحة لكل لغة (مفتاح nightsCount)
                    // بدل Formatters.nights التي كانت تُرجع نصًا عربيًا ثابتًا.
                    _DetailRow(
                      icon: Icons.nights_stay_outlined,
                      label: l10n.nightsLabel,
                      value: l10n.nightsCount(_nights),
                    ),
                    const Divider(),
                    _DetailRow(
                      icon: Icons.people_outline,
                      label: l10n.guestsLabel,
                      value: '${widget.guests}',
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: AppSizes.md),

            Card(
              color: AppColors.background,
              child: Padding(
                padding: const EdgeInsets.all(AppSizes.md),
                child: Column(
                  children: [
                    // سطر سعر منفصل لكل نوع غرفة مختار (لو أكتر من نوع)
                    for (final room in rooms)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                room.label.isNotEmpty
                                    ? '${room.label} × ${room.quantity} × $_nights'
                                    : '×$_nights',
                              ),
                            ),
                            PriceText(sarAmount: room.subtotalPerNight * _nights),
                          ],
                        ),
                      ),
                    const Divider(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          l10n.totalLabel,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        PriceText(
                          sarAmount: _totalPrice,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // بيانات صاحب الحجز (فنادق HotelBeds فقط)
            if (_hbRoom != null) ...[
              const SizedBox(height: AppSizes.md),
              _holderForm(context),
              const SizedBox(height: AppSizes.md),
              _consentSection(context),
            ],

            if (_errorMessage != null) ...[
              const SizedBox(height: AppSizes.md),
              Text(
                _errorMessage!,
                style: const TextStyle(color: AppColors.error),
                textAlign: TextAlign.center,
              ),
            ],

            const SizedBox(height: AppSizes.lg),

            ElevatedButton(
              onPressed: _isSubmitting ? null : _confirmBooking,
              child: _isSubmitting
                  ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
                  : Text(l10n.confirmBookingButton),
            ),

            // ملاحظة الدفع القديمة لا تنطبق على حجوزات HotelBeds.
            if (_hbRoom == null) ...[
              const SizedBox(height: AppSizes.sm),
              Text(
                l10n.paymentNote,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textHint, fontSize: 12),
              ),
            ],

            const AppFooter(),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.textSecondary),
          const SizedBox(width: AppSizes.sm),
          Expanded(child: Text(label)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}