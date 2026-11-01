import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../data/models/booking_model.dart';

/// قسيمة حجز فندق HotelBeds.
///
/// المحتوى بالإنجليزية عمدًا: هي وثيقة يقدّمها النزيل لموظف الاستقبال في
/// أي بلد، والإنجليزية هي اللغة التي يفهمها كل موظفي الفنادق. لذلك تبقى
/// القسيمة من اليسار لليمين دائمًا.
/// عندما تكون لغة التطبيق غير الإنجليزية (أي لغة من اللغات التسع)، تظهر
/// ترجمة صغيرة بلغة المستخدم تحت كل عنوان حتى يفهمها النزيل أيضًا — دون أن
/// تختفي الإنجليزية التي يحتاجها الفندق.
///
/// تحتوي كل ما تشترطه HotelBeds في الـ Certification:
/// اسم الفندق وعنوانه، اسم صاحب الحجز، عدد النزلاء لكل غرفة وأعمار الأطفال،
/// رقم حجز HotelBeds، تاريخا الوصول والمغادرة، نوع الغرفة والوجبات،
/// ملاحظات السعر (rate comments)، وعبارة "Payable through ..." (بالإنجليزية كما هي).
class HotelVoucherPage extends StatelessWidget {
  final BookingModel booking;
  const HotelVoucherPage({super.key, required this.booking});

  static String _date(DateTime d) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return '${days[d.weekday - 1]}, ${months[d.month - 1]} ${d.day}, ${d.year}';
  }

  static String _title(String s) => s
      .toLowerCase()
      .split(' ')
      .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
      .join(' ');

  @override
  Widget build(BuildContext context) {
    final v = _VoucherText.of(context);
    // ترجمة مساعدة بلغة المستخدم تحت العنوان الإنجليزي (null = الإنجليزية، لا شيء).
    String? a(String Function(_VoucherText) pick) => v.isEnglish ? null : pick(v);

    final b = booking;
    final nights = b.checkOut.difference(b.checkIn).inDays;
    final rooms = b.voucherRooms;
    final cancelled = b.status == 'cancelled';
    final roomComments = rooms
        .map((r) => r.rateComments)
        .whereType<String>()
        .where((c) => c.trim().isNotEmpty)
        .toSet();
    final comments = roomComments.isNotEmpty
        ? roomComments.join('\n\n')
        : (b.rateComments ?? '');

    return Scaffold(
      appBar: AppBar(title: Text(v.isEnglish ? 'Booking voucher' : v.voucherTitle)),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: ListView(
              padding: const EdgeInsets.all(AppSizes.md),
              children: [
                if (!v.isEnglish)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSizes.sm),
                    child: Container(
                      padding: const EdgeInsets.all(AppSizes.sm),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.06),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        v.notice,
                        style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                      ),
                    ),
                  ),
                // القسيمة نفسها من اليسار لليمين دائمًا (وثيقة إنجليزية للفندق).
                Directionality(
                  textDirection: TextDirection.ltr,
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSizes.lg),
                      child: SelectionArea(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // ── الرأس ──
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // شعار بنص داكن (FLY كحلي) للخلفيات البيضاء.
                                      // لو لم يوجد الملف يظهر الاسم نصًا كما كان.
                                      const _VoucherLogo(),
                                      const SizedBox(height: 4),
                                      const Text('Hotel booking voucher',
                                          style: TextStyle(color: AppColors.textSecondary)),
                                      if (!v.isEnglish) _Sub(v.hotelVoucher, rtl: v.rtl),
                                    ],
                                  ),
                                ),
                                if (cancelled)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      border: Border.all(color: AppColors.error),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Column(
                                      children: [
                                        const Text('CANCELLED',
                                            style: TextStyle(
                                                color: AppColors.error, fontWeight: FontWeight.bold)),
                                        if (!v.isEnglish)
                                          _Sub(v.cancelled, rtl: v.rtl, color: AppColors.error),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                            const Divider(height: AppSizes.lg * 2),

                            _Field('Booking reference', b.supplierReference ?? '—',
                                sub: a((t) => t.bookingRef), rtl: v.rtl, big: true, copy: true),
                            if (b.clientReference != null)
                              _Field('Flynoom reference', b.clientReference!, sub: a((t) => t.flynoomRef), rtl: v.rtl),
                            if (cancelled && b.cancellationReference != null)
                              _Field('Cancellation reference', b.cancellationReference!,
                                  sub: a((t) => t.cancellationRef), rtl: v.rtl),

                            const SizedBox(height: AppSizes.md),
                            _Section('Hotel', sub: a((t) => t.hotel), rtl: v.rtl),
                            Text(b.hotelName ?? '',
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            if (b.hotelAddress != null) Text(b.hotelAddress!),
                            if (b.hotelAddress == null && b.hotelCity != null) Text(b.hotelCity!),
                            if (b.hotelPhone != null) Text('Phone: ${b.hotelPhone}'),

                            const SizedBox(height: AppSizes.md),
                            _Section('Stay', sub: a((t) => t.stay), rtl: v.rtl),
                            _Field('Check-in', _date(b.checkIn),
                                sub: a((t) => t.checkIn), valueSub: a((t) => t.date(b.checkIn)), rtl: v.rtl),
                            _Field('Check-out', _date(b.checkOut),
                                sub: a((t) => t.checkOut), valueSub: a((t) => t.date(b.checkOut)), rtl: v.rtl),
                            _Field('Nights', '$nights', sub: a((t) => t.nights), rtl: v.rtl),
                            _Field('Lead guest', b.holderFullName.isNotEmpty ? b.holderFullName : '—',
                                sub: a((t) => t.leadGuest), rtl: v.rtl),

                            const SizedBox(height: AppSizes.md),
                            _Section('Rooms', sub: a((t) => t.rooms), rtl: v.rtl),
                            if (rooms.isEmpty)
                              _Field(
                                'Room',
                                [
                                  if (b.roomName != null) _title(b.roomName!),
                                  if (b.boardName != null) _title(b.boardName!),
                                ].join(' · '),
                                sub: a((t) => t.room),
                                rtl: v.rtl,
                              ),
                            for (var i = 0; i < rooms.length; i++)
                              Padding(
                                padding: const EdgeInsets.only(bottom: AppSizes.sm),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${rooms[i].rooms} × ${_title(rooms[i].name)}',
                                      style: const TextStyle(fontWeight: FontWeight.w600),
                                    ),
                                    if (rooms[i].boardName != null)
                                      Text('Board: ${_title(rooms[i].boardName!)}'),
                                    Text(
                                      'Guests per room: ${rooms[i].adults} adult${rooms[i].adults == 1 ? '' : 's'}'
                                          '${rooms[i].children > 0 ? ', ${rooms[i].children} child${rooms[i].children == 1 ? '' : 'ren'}' : ''}'
                                          '${rooms[i].childAges.isNotEmpty ? ' (ages ${rooms[i].childAges.join(', ')})' : ''}',
                                    ),
                                    if (!v.isEnglish)
                                      _Sub(
                                        v.guestsLine(rooms[i].adults, rooms[i].children, rooms[i].childAges),
                                        rtl: v.rtl,
                                      ),
                                  ],
                                ),
                              ),

                            if (b.payAtHotelFees.isNotEmpty) ...[
                              const SizedBox(height: AppSizes.md),
                              _Section('Payable at the hotel', sub: a((t) => t.payableAtHotel), rtl: v.rtl),
                              for (final f in b.payAtHotelFees)
                                Text(
                                  '${_title((f['type'] ?? 'Fee').toString())}: '
                                      '${((f['amount'] as num?) ?? 0).toStringAsFixed(2)} ${f['currency'] ?? ''}',
                                ),
                              const Text(
                                'Mandatory fees not included in the amount paid online.',
                                style: TextStyle(fontSize: 12, color: AppColors.textHint),
                              ),
                              if (!v.isEnglish) _Sub(v.mandatoryFees, rtl: v.rtl),
                            ],

                            if (comments.trim().isNotEmpty) ...[
                              const SizedBox(height: AppSizes.md),
                              _Section('Important information', sub: a((t) => t.importantInfo), rtl: v.rtl),
                              Text(comments.trim(),
                                  style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                            ],

                            const Divider(height: AppSizes.lg * 2),
                            // ── العبارة الإلزامية من HotelBeds (بالإنجليزية كما هي) ──
                            Text(
                              'Payable through ${b.supplierName ?? 'HOTELBEDS'}, acting as agent for the '
                                  'service operating company, details of which can be provided upon request. '
                                  'VAT: ${b.supplierVat ?? '—'} Reference: ${b.supplierReference ?? '—'}',
                              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                            ),
                            const SizedBox(height: AppSizes.sm),
                            const Text(
                              'Booked by FLYNOOM LLC · flynoom.com',
                              style: TextStyle(fontSize: 12, color: AppColors.textHint),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppSizes.sm),
                Text(
                  v.printTip,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 12, color: AppColors.textHint),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// سطر ترجمة صغير بلغة المستخدم تحت النص الإنجليزي.
/// العربية والأردية من اليمين لليسار، وباقي اللغات من اليسار لليمين.
class _Sub extends StatelessWidget {
  final String text;
  final bool rtl;
  final Color color;
  const _Sub(this.text, {this.rtl = false, this.color = AppColors.textHint});

  @override
  Widget build(BuildContext context) => Text(
    text,
    textDirection: rtl ? TextDirection.rtl : TextDirection.ltr,
    style: TextStyle(fontSize: 11, color: color, height: 1.3),
  );
}

class _Section extends StatelessWidget {
  final String title;
  final String? sub;
  final bool rtl;
  const _Section(this.title, {this.sub, this.rtl = false});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 4),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title.toUpperCase(),
          style: const TextStyle(
            fontSize: 12,
            letterSpacing: 1,
            fontWeight: FontWeight.bold,
            color: AppColors.textSecondary,
          ),
        ),
        if (sub != null) _Sub(sub!, rtl: rtl),
      ],
    ),
  );
}

class _Field extends StatelessWidget {
  final String label;
  final String value;
  final String? sub;

  /// القيمة بلغة المستخدم تحت القيمة الإنجليزية (للتواريخ).
  final String? valueSub;
  final bool rtl;
  final bool big;
  final bool copy;
  const _Field(this.label, this.value,
      {this.sub, this.valueSub, this.rtl = false, this.big = false, this.copy = false});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 2),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: 170,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(color: AppColors.textSecondary)),
              if (sub != null) _Sub(sub!, rtl: rtl),
            ],
          ),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: big ? 18 : 14,
                ),
              ),
              if (valueSub != null) _Sub(valueSub!, rtl: rtl),
            ],
          ),
        ),
        if (copy && value != '—')
          IconButton(
            tooltip: 'Copy',
            icon: const Icon(Icons.copy, size: 16),
            onPressed: () => Clipboard.setData(ClipboardData(text: value)),
          ),
      ],
    ),
  );
}

/// نصوص الترجمة المساعدة في القسيمة باللغات التسع.
/// ترتيب كل قائمة: [en, ar, es, tr, id, hi, ur, fr, bn].
class _VoucherText {
  final String lang;
  const _VoucherText(this.lang);

  static const _langs = ['en', 'ar', 'es', 'tr', 'id', 'hi', 'ur', 'fr', 'bn'];

  static _VoucherText of(BuildContext context) {
    final code = Localizations.localeOf(context).languageCode;
    return _VoucherText(_langs.contains(code) ? code : 'en');
  }

  bool get isEnglish => lang == 'en';
  bool get rtl => lang == 'ar' || lang == 'ur';

  String _p(List<String> v) => v[_langs.indexOf(lang)];

  String get voucherTitle => _p(const [
    'Booking voucher', 'قسيمة الحجز', 'Bono de reserva', 'Rezervasyon belgesi', 'Voucher pemesanan',
    'बुकिंग वाउचर', 'بکنگ واؤچر', 'Bon de réservation', 'বুকিং ভাউচার',
  ]);
  String get notice => _p(const [
    '',
    'اعرض هذه القسيمة على موظف الاستقبال عند الوصول. هي بالإنجليزية ليفهمها الفندق في أي بلد، والترجمة الصغيرة لك أنت.',
    'Muestra este bono en la recepción al llegar. Está en inglés para que el hotel lo entienda en cualquier país; la traducción pequeña es para ti.',
    'Varışta bu belgeyi resepsiyona gösterin. Otelin her ülkede anlaması için İngilizcedir; küçük çeviri sizin içindir.',
    'Tunjukkan voucher ini ke resepsionis saat tiba. Voucher dalam bahasa Inggris agar dipahami hotel di negara mana pun; terjemahan kecil untuk Anda.',
    'पहुँचने पर यह वाउचर रिसेप्शन पर दिखाएँ। यह अंग्रेज़ी में है ताकि किसी भी देश में होटल इसे समझ सके; छोटा अनुवाद आपके लिए है।',
    'آمد پر یہ واؤچر استقبالیہ پر دکھائیں۔ یہ انگریزی میں ہے تاکہ کسی بھی ملک میں ہوٹل اسے سمجھ سکے؛ چھوٹا ترجمہ آپ کے لیے ہے۔',
    'Présentez ce bon à la réception à votre arrivée. Il est en anglais pour être compris par l\'hôtel dans tous les pays ; la petite traduction est pour vous.',
    'পৌঁছে এই ভাউচারটি রিসেপশনে দেখান। এটি ইংরেজিতে যাতে যেকোনো দেশের হোটেল বুঝতে পারে; ছোট অনুবাদটি আপনার জন্য।',
  ]);
  String get hotelVoucher => _p(const [
    'Hotel booking voucher', 'قسيمة حجز فندق', 'Bono de reserva de hotel', 'Otel rezervasyon belgesi',
    'Voucher pemesanan hotel', 'होटल बुकिंग वाउचर', 'ہوٹل بکنگ واؤچر', 'Bon de réservation d\'hôtel',
    'হোটেল বুকিং ভাউচার',
  ]);
  String get cancelled => _p(const [
    'Cancelled', 'ملغى', 'Cancelada', 'İptal edildi', 'Dibatalkan', 'रद्द', 'منسوخ', 'Annulée', 'বাতিল',
  ]);
  String get bookingRef => _p(const [
    'Booking reference', 'رقم الحجز', 'Referencia de reserva', 'Rezervasyon numarası', 'Kode pemesanan',
    'बुकिंग नंबर', 'بکنگ نمبر', 'Référence de réservation', 'বুকিং নম্বর',
  ]);
  String get flynoomRef => _p(const [
    'Flynoom reference', 'رقم Flynoom', 'Referencia Flynoom', 'Flynoom numarası', 'Kode Flynoom',
    'Flynoom नंबर', 'Flynoom نمبر', 'Référence Flynoom', 'Flynoom নম্বর',
  ]);
  String get cancellationRef => _p(const [
    'Cancellation reference', 'رقم الإلغاء', 'Referencia de cancelación', 'İptal numarası',
    'Kode pembatalan', 'रद्दीकरण नंबर', 'منسوخی نمبر', 'Référence d\'annulation', 'বাতিল নম্বর',
  ]);
  String get hotel => _p(const [
    'Hotel', 'الفندق', 'Hotel', 'Otel', 'Hotel', 'होटल', 'ہوٹل', 'Hôtel', 'হোটেল',
  ]);
  String get stay => _p(const [
    'Stay', 'الإقامة', 'Estancia', 'Konaklama', 'Menginap', 'ठहराव', 'قیام', 'Séjour', 'থাকা',
  ]);
  String get checkIn => _p(const [
    'Check-in', 'تاريخ الدخول', 'Entrada', 'Giriş', 'Check-in', 'चेक-इन', 'چیک اِن', 'Arrivée', 'চেক-ইন',
  ]);
  String get checkOut => _p(const [
    'Check-out', 'تاريخ المغادرة', 'Salida', 'Çıkış', 'Check-out', 'चेक-आउट', 'چیک آؤٹ', 'Départ', 'চেক-আউট',
  ]);
  String get nights => _p(const [
    'Nights', 'عدد الليالي', 'Noches', 'Gece sayısı', 'Jumlah malam', 'रातें', 'راتیں', 'Nuits', 'রাত',
  ]);
  String get leadGuest => _p(const [
    'Lead guest', 'اسم النزيل الرئيسي', 'Huésped principal', 'Ana misafir', 'Tamu utama', 'मुख्य मेहमान',
    'مرکزی مہمان', 'Voyageur principal', 'প্রধান অতিথি',
  ]);
  String get rooms => _p(const [
    'Rooms', 'الغرف', 'Habitaciones', 'Odalar', 'Kamar', 'कमरे', 'کمرے', 'Chambres', 'রুম',
  ]);
  String get room => _p(const [
    'Room', 'الغرفة', 'Habitación', 'Oda', 'Kamar', 'कमरा', 'کمرہ', 'Chambre', 'রুম',
  ]);
  String get _guestsPerRoom => _p(const [
    'Guests per room', 'النزلاء في كل غرفة', 'Huéspedes por habitación', 'Oda başına misafir',
    'Tamu per kamar', 'प्रति कमरा मेहमान', 'فی کمرہ مہمان', 'Voyageurs par chambre', 'প্রতি রুমে অতিথি',
  ]);
  String get _adults => _p(const [
    'adults', 'بالغ', 'adultos', 'yetişkin', 'dewasa', 'वयस्क', 'بالغ', 'adulte(s)', 'প্রাপ্তবয়স্ক',
  ]);
  String get _children => _p(const [
    'children', 'طفل', 'niños', 'çocuk', 'anak', 'बच्चे', 'بچے', 'enfant(s)', 'শিশু',
  ]);
  String get _ages => _p(const [
    'ages', 'الأعمار', 'edades', 'yaşlar', 'usia', 'उम्र', 'عمریں', 'âges', 'বয়স',
  ]);

  static const _days = <String, List<String>>{
    'ar': ['الإثنين', 'الثلاثاء', 'الأربعاء', 'الخميس', 'الجمعة', 'السبت', 'الأحد'],
    'es': ['lunes', 'martes', 'miércoles', 'jueves', 'viernes', 'sábado', 'domingo'],
    'tr': ['Pazartesi', 'Salı', 'Çarşamba', 'Perşembe', 'Cuma', 'Cumartesi', 'Pazar'],
    'id': ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'],
    'hi': ['सोमवार', 'मंगलवार', 'बुधवार', 'गुरुवार', 'शुक्रवार', 'शनिवार', 'रविवार'],
    'ur': ['پیر', 'منگل', 'بدھ', 'جمعرات', 'جمعہ', 'ہفتہ', 'اتوار'],
    'fr': ['lundi', 'mardi', 'mercredi', 'jeudi', 'vendredi', 'samedi', 'dimanche'],
    'bn': ['সোমবার', 'মঙ্গলবার', 'বুধবার', 'বৃহস্পতিবার', 'শুক্রবার', 'শনিবার', 'রবিবার'],
  };
  static const _months = <String, List<String>>{
    'ar': ['يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو', 'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر'],
    'es': ['enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio', 'julio', 'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre'],
    'tr': ['Ocak', 'Şubat', 'Mart', 'Nisan', 'Mayıs', 'Haziran', 'Temmuz', 'Ağustos', 'Eylül', 'Ekim', 'Kasım', 'Aralık'],
    'id': ['Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni', 'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'],
    'hi': ['जनवरी', 'फ़रवरी', 'मार्च', 'अप्रैल', 'मई', 'जून', 'जुलाई', 'अगस्त', 'सितंबर', 'अक्तूबर', 'नवंबर', 'दिसंबर'],
    'ur': ['جنوری', 'فروری', 'مارچ', 'اپریل', 'مئی', 'جون', 'جولائی', 'اگست', 'ستمبر', 'اکتوبر', 'نومبر', 'دسمبر'],
    'fr': ['janvier', 'février', 'mars', 'avril', 'mai', 'juin', 'juillet', 'août', 'septembre', 'octobre', 'novembre', 'décembre'],
    'bn': ['জানুয়ারি', 'ফেব্রুয়ারি', 'মার্চ', 'এপ্রিল', 'মে', 'জুন', 'জুলাই', 'আগস্ট', 'সেপ্টেম্বর', 'অক্টোবর', 'নভেম্বর', 'ডিসেম্বর'],
  };

  /// التاريخ بلغة المستخدم: "الجمعة، 30 أكتوبر 2026" / "viernes, 30 octubre 2026".
  String date(DateTime d) {
    final day = _days[lang]?[d.weekday - 1];
    final month = _months[lang]?[d.month - 1];
    if (day == null || month == null) return '';
    return '$day${rtl ? '،' : ','} ${d.day} $month ${d.year}';
  }

  String guestsLine(int adults, int children, List<int> ages) {
    final sep = rtl ? '، ' : ', ';
    return '$_guestsPerRoom: $adults $_adults'
        '${children > 0 ? '$sep$children $_children' : ''}'
        '${ages.isNotEmpty ? ' ($_ages: ${ages.join(sep)})' : ''}';
  }

  String get payableAtHotel => _p(const [
    'Payable at the hotel', 'يُدفع في الفندق', 'A pagar en el hotel', 'Otelde ödenecek',
    'Dibayar di hotel', 'होटल में देय', 'ہوٹل میں قابلِ ادائیگی', 'À payer à l\'hôtel', 'হোটেলে প্রদেয়',
  ]);
  String get mandatoryFees => _p(const [
    '',
    'رسوم إلزامية غير مشمولة في المبلغ المدفوع عبر الموقع، تُدفع للفندق.',
    'Cargos obligatorios no incluidos en el importe pagado en línea; se pagan al hotel.',
    'Çevrim içi ödenen tutara dahil olmayan zorunlu ücretler; otele ödenir.',
    'Biaya wajib yang tidak termasuk dalam jumlah yang dibayar online; dibayar ke hotel.',
    'अनिवार्य शुल्क जो ऑनलाइन भुगतान में शामिल नहीं हैं; होटल को दिए जाते हैं।',
    'لازمی فیس جو آن لائن ادائیگی میں شامل نہیں؛ ہوٹل کو ادا کی جاتی ہے۔',
    'Frais obligatoires non inclus dans le montant payé en ligne ; à régler à l\'hôtel.',
    'বাধ্যতামূলক ফি যা অনলাইনে পরিশোধিত অর্থে অন্তর্ভুক্ত নয়; হোটেলে দিতে হয়।',
  ]);
  String get importantInfo => _p(const [
    'Important information',
    'معلومات مهمة (من الفندق، بالإنجليزية)',
    'Información importante (del hotel, en inglés)',
    'Önemli bilgiler (otelden, İngilizce)',
    'Informasi penting (dari hotel, dalam bahasa Inggris)',
    'महत्वपूर्ण जानकारी (होटल से, अंग्रेज़ी में)',
    'اہم معلومات (ہوٹل کی طرف سے، انگریزی میں)',
    'Informations importantes (de l\'hôtel, en anglais)',
    'গুরুত্বপূর্ণ তথ্য (হোটেল থেকে, ইংরেজিতে)',
  ]);
  String get printTip => _p(const [
    'Tip: on the website, press Ctrl+P to print or save this voucher as PDF.',
    'تلميح: على الموقع اضغط Ctrl+P لطباعة القسيمة أو حفظها بصيغة PDF.',
    'Consejo: en el sitio web, pulsa Ctrl+P para imprimir o guardar este bono en PDF.',
    'İpucu: web sitesinde bu belgeyi yazdırmak veya PDF olarak kaydetmek için Ctrl+P\'ye basın.',
    'Tips: di situs web, tekan Ctrl+P untuk mencetak atau menyimpan voucher ini sebagai PDF.',
    'सुझाव: वेबसाइट पर इस वाउचर को प्रिंट करने या PDF के रूप में सहेजने के लिए Ctrl+P दबाएँ।',
    'مشورہ: ویب سائٹ پر اس واؤچر کو پرنٹ کرنے یا PDF کے طور پر محفوظ کرنے کے لیے Ctrl+P دبائیں۔',
    'Astuce : sur le site, appuyez sur Ctrl+P pour imprimer ou enregistrer ce bon en PDF.',
    'টিপ: ওয়েবসাইটে এই ভাউচার প্রিন্ট বা PDF হিসেবে সংরক্ষণ করতে Ctrl+P চাপুন।',
  ]);
}

/// شعار Flynoom في رأس القسيمة. يُطبع أيضًا عند Ctrl+P / الحفظ كـ PDF.
class _VoucherLogo extends StatelessWidget {
  const _VoucherLogo();

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/images/logo_flynoom_dark.png',
      height: 40,
      fit: BoxFit.contain,
      alignment: AlignmentDirectional.centerStart,
      filterQuality: FilterQuality.high,
      errorBuilder: (_, __, ___) => const Text(
        'FLYNOOM',
        style: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w900,
          letterSpacing: 2,
          color: AppColors.primary,
        ),
      ),
    );
  }
}