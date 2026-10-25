import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/error_view.dart';
import '../../core/widgets/loading_view.dart';
import '../../core/widgets/empty_view.dart';
import '../../data/models/inbox_item_model.dart';
import '../../data/repositories/inbox_repository.dart';
import '../../data/repositories/hotelbeds_booking_repository.dart' show CancellationQuote;
import '../../localization/app_localizations.dart';
import '../booking/booking_page.dart'
    show bookingRepositoryProvider, hotelBedsBookingRepositoryProvider;
import 'hotel_receipt_page.dart';
import 'hotel_voucher_page.dart';

final inboxRepositoryProvider = Provider((ref) => InboxRepository());

/// نص حسب لغة التطبيق (اللغات التسع).
String _tm(
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

/// تاريخ بصيغة أمريكية واضحة: "Oct 12, 2026" (بدل 12/10/2026 الملتبسة).
String _usDate(DateTime d) {
  const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  return '${months[d.month - 1]} ${d.day}, ${d.year}';
}

String _usd(double v) => '\$${v.toStringAsFixed(2)}';

/// محاولات HotelBeds غير المكتملة لا تُعرض كحجوزات.
const _hiddenStatuses = {'awaiting_payment', 'failed'};

/// المصدر الموحّد لكل الحجوزات (فنادق + طيران عبر Duffel + سيارات) --
/// نفس المصدر بالضبط المستخدم في شاشة Inbox، بدل جدول bookings المحلي
/// وحده (اللي كان بيفوّت حجوزات الطيران الحقيقية تمامًا).
// autoDispose: تُعاد قراءة الحجوزات من قاعدة البيانات في كل مرة تُفتح فيها
// الصفحة (بدونه كانت تعرض نسخة قديمة محفوظة، فلا يظهر الحجز الجديد ولا
// تتحدث الحالة بعد الإلغاء).
final myBookingsProvider = FutureProvider.autoDispose<List<InboxItemModel>>((ref) async {
  final repo = ref.watch(inboxRepositoryProvider);
  final result = await repo.fetchInboxItems();

  return result.when(
    success: (items) => items
        .where((item) =>
    (item.type == InboxItemType.hotelBooking ||
        item.type == InboxItemType.flightBooking ||
        item.type == InboxItemType.carBooking) &&
        !_hiddenStatuses.contains(item.status))
        .toList(),
    failure: (message) => throw Exception(message),
  );
});

class MyBookingsPage extends ConsumerWidget {
  const MyBookingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final bookingsAsync = ref.watch(myBookingsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.myBookings),
        actions: [
          IconButton(
            tooltip: MaterialLocalizations.of(context).refreshIndicatorSemanticLabel,
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(myBookingsProvider),
          ),
        ],
      ),
      body: bookingsAsync.when(
        loading: () => LoadingView(message: l10n.loadingBookings),
        error: (error, _) => ErrorView(
          message: l10n.errorLoadBookings,
          onRetry: () => ref.invalidate(myBookingsProvider),
        ),
        data: (items) {
          if (items.isEmpty) {
            return EmptyView(
              message: l10n.noBookingsYet,
              icon: Icons.receipt_long_outlined,
            );
          }
          return RefreshIndicator(
            onRefresh: () => ref.refresh(myBookingsProvider.future),
            child: ListView.builder(
              padding: const EdgeInsets.all(AppSizes.md),
              itemCount: items.length,
              itemBuilder: (context, index) => _BookingCard(item: items[index]),
            ),
          );
        },
      ),
    );
  }
}

class _BookingCard extends ConsumerStatefulWidget {
  final InboxItemModel item;
  const _BookingCard({required this.item});

  @override
  ConsumerState<_BookingCard> createState() => _BookingCardState();
}

class _BookingCardState extends ConsumerState<_BookingCard> {
  bool _isCancelling = false;

  /// حجز فندق مؤكد انتهت إقامته (تاريخ الخروج قبل اليوم) → يُعرض "مكتمل".
  /// عرض فقط؛ لا يغيّر الحالة في قاعدة البيانات.
  bool get _isCompleted {
    final b = widget.item.hotelBooking;
    if (widget.item.type != InboxItemType.hotelBooking || b == null) return false;
    if (widget.item.status != 'confirmed') return false;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final out = DateTime(b.checkOut.year, b.checkOut.month, b.checkOut.day);
    return out.isBefore(today);
  }

  Color get _statusColor {
    if (_isCompleted) return AppColors.primary;
    switch (widget.item.status) {
      case 'confirmed':
        return AppColors.success;
      case 'cancelled':
        return AppColors.error;
      default:
        return AppColors.warning;
    }
  }

  String _statusLabel(AppLocalizations l10n) {
    if (_isCompleted) {
      return _tm(context,
          ar: 'مكتمل', en: 'Completed', es: 'Completada', tr: 'Tamamlandı', id: 'Selesai',
          hi: 'पूर्ण', ur: 'مکمل', fr: 'Terminé', bn: 'সম্পন্ন');
    }
    switch (widget.item.status) {
      case 'confirmed':
        return l10n.statusConfirmed;
      case 'cancelled':
        return l10n.statusCancelled;
      default:
        return l10n.statusPending;
    }
  }

  /// إلغاء الحجز متاح حاليًا لحجوزات الفنادق فقط (نفس السلوك القديم) --
  /// إلغاء رحلات Duffel محتاج تدفق منفصل عبر Duffel API مش مبني لسه.
  /// لا إلغاء لحجز انتهت إقامته.
  bool get _canCancel {
    if (widget.item.type != InboxItemType.hotelBooking) return false;
    if (_isCompleted) return false;
    // حجوزات HotelBeds: الإلغاء فقط للمؤكدة (عبر الفندق + الاسترداد).
    if (widget.item.hotelBooking?.isHotelBeds == true) {
      return widget.item.status == 'confirmed';
    }
    return widget.item.status == 'pending' || widget.item.status == 'confirmed';
  }

  /// القسيمة متاحة لحجوزات HotelBeds المؤكدة أو الملغاة (للرجوع إليها).
  bool get _hasVoucher {
    final b = widget.item.hotelBooking;
    return b != null &&
        b.isHotelBeds &&
        b.supplierReference != null &&
        (b.status == 'confirmed' || b.status == 'cancelled');
  }

  /// إلغاء حجز HotelBeds: عرض الرسوم والاسترداد أولًا، ثم الإلغاء الفعلي.
  Future<void> _cancelHotelBeds() async {
    final l10n = AppLocalizations.of(context)!;
    final booking = widget.item.hotelBooking!;
    final repo = ref.read(hotelBedsBookingRepositoryProvider);

    setState(() => _isCancelling = true);
    final quoteResult = await repo.cancellationQuote(booking.id);
    if (!mounted) return;

    CancellationQuote? quote;
    quoteResult.when(
      success: (q) {
        quote = q;
      },
      failure: (message) {
        setState(() => _isCancelling = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message), backgroundColor: AppColors.error),
        );
      },
    );
    if (quote == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.cancelBookingConfirmTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(booking.hotelName ?? '', style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: AppSizes.sm),
            Text(_tm(ctx,
                ar: 'رسوم الإلغاء: ${_usd(quote!.fee)}',
                en: 'Cancellation fee: ${_usd(quote!.fee)}',
                es: 'Cargo por cancelación: ${_usd(quote!.fee)}',
                tr: 'İptal ücreti: ${_usd(quote!.fee)}',
                id: 'Biaya pembatalan: ${_usd(quote!.fee)}',
                hi: 'रद्दीकरण शुल्क: ${_usd(quote!.fee)}',
                ur: 'منسوخی فیس: ${_usd(quote!.fee)}',
                fr: 'Frais d\'annulation : ${_usd(quote!.fee)}',
                bn: 'বাতিল ফি: ${_usd(quote!.fee)}')),
            Text(
              _tm(ctx,
                  ar: 'المبلغ المسترد: ${_usd(quote!.refund)}',
                  en: 'Refund: ${_usd(quote!.refund)}',
                  es: 'Reembolso: ${_usd(quote!.refund)}',
                  tr: 'İade: ${_usd(quote!.refund)}',
                  id: 'Pengembalian dana: ${_usd(quote!.refund)}',
                  hi: 'रिफ़ंड: ${_usd(quote!.refund)}',
                  ur: 'واپسی: ${_usd(quote!.refund)}',
                  fr: 'Remboursement : ${_usd(quote!.refund)}',
                  bn: 'ফেরত: ${_usd(quote!.refund)}'),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(_tm(ctx,
                ar: 'أبقِ الحجز', en: 'Keep booking', es: 'Mantener reserva', tr: 'Rezervasyonu koru',
                id: 'Pertahankan pemesanan', hi: 'बुकिंग रखें', ur: 'بکنگ برقرار رکھیں',
                fr: 'Garder la réservation', bn: 'বুকিং রাখুন')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.cancelBookingYes, style: const TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );

    if (!mounted) return;
    if (confirmed != true) {
      setState(() => _isCancelling = false);
      return;
    }

    final result = await repo.cancel(booking.id);
    if (!mounted) return;

    result.when(
      success: (r) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(r.refund <= 0
              ? _tm(context,
              ar: 'تم إلغاء الحجز. لا يوجد مبلغ مسترد حسب سياسة الإلغاء.',
              en: 'Booking cancelled. No refund applies under the cancellation policy.',
              es: 'Reserva cancelada. No corresponde reembolso según la política de cancelación.',
              tr: 'Rezervasyon iptal edildi. İptal politikasına göre iade yapılmaz.',
              id: 'Pemesanan dibatalkan. Tidak ada pengembalian dana sesuai kebijakan pembatalan.',
              hi: 'बुकिंग रद्द हो गई। रद्दीकरण नीति के अनुसार कोई रिफ़ंड नहीं है।',
              ur: 'بکنگ منسوخ ہو گئی۔ منسوخی کی پالیسی کے مطابق کوئی رقم واپس نہیں ہوگی۔',
              fr: 'Réservation annulée. Aucun remboursement selon la politique d\'annulation.',
              bn: 'বুকিং বাতিল হয়েছে। বাতিল নীতি অনুযায়ী কোনো ফেরত নেই।')
              : _tm(context,
              ar: 'تم إلغاء الحجز. يصل المبلغ المسترد ${_usd(r.refund)} إلى بطاقتك خلال 5–10 أيام عمل.',
              en: 'Booking cancelled. Your refund of ${_usd(r.refund)} will reach your card in 5–10 business days.',
              es: 'Reserva cancelada. Tu reembolso de ${_usd(r.refund)} llegará a tu tarjeta en 5–10 días hábiles.',
              tr: 'Rezervasyon iptal edildi. ${_usd(r.refund)} iadeniz 5–10 iş günü içinde kartınıza yansıyacak.',
              id: 'Pemesanan dibatalkan. Pengembalian ${_usd(r.refund)} akan masuk ke kartu Anda dalam 5–10 hari kerja.',
              hi: 'बुकिंग रद्द हो गई। ${_usd(r.refund)} का रिफ़ंड 5–10 कार्यदिवसों में आपके कार्ड पर आएगा।',
              ur: 'بکنگ منسوخ ہو گئی۔ ${_usd(r.refund)} کی واپسی 5–10 کاروباری دنوں میں آپ کے کارڈ پر آئے گی۔',
              fr: 'Réservation annulée. Votre remboursement de ${_usd(r.refund)} arrivera sur votre carte sous 5 à 10 jours ouvrés.',
              bn: 'বুকিং বাতিল হয়েছে। ${_usd(r.refund)} ফেরত ৫–১০ কার্যদিবসে আপনার কার্ডে আসবে।')),
        ));
        ref.invalidate(myBookingsProvider);
      },
      failure: (message) {
        setState(() => _isCancelling = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message), backgroundColor: AppColors.error),
        );
      },
    );
  }

  Future<void> _confirmAndCancel() async {
    final l10n = AppLocalizations.of(context)!;
    final booking = widget.item.hotelBooking;
    if (booking == null) return;
    if (booking.isHotelBeds) {
      await _cancelHotelBeds();
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.cancelBookingConfirmTitle),
        content: Text(booking.hotelName ?? ''),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(_tm(context,
                ar: 'أبقِ الحجز', en: 'Keep booking', es: 'Mantener reserva', tr: 'Rezervasyonu koru',
                id: 'Pertahankan pemesanan', hi: 'बुकिंग रखें', ur: 'بکنگ برقرار رکھیں',
                fr: 'Garder la réservation', bn: 'বুকিং রাখুন')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.cancelBookingYes, style: const TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isCancelling = true);

    final repo = ref.read(bookingRepositoryProvider);
    final result = await repo.cancelBooking(booking.id);

    if (!mounted) return;

    result.when(
      success: (_) {
        ref.invalidate(myBookingsProvider);
      },
      failure: (message) {
        setState(() => _isCancelling = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message), backgroundColor: AppColors.error),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final item = widget.item;

    return Card(
      margin: const EdgeInsets.only(bottom: AppSizes.md),
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                _buildThumbnail(),
                const SizedBox(width: AppSizes.md),
                Expanded(child: _buildTitleColumn(context)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _statusColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                  ),
                  child: Text(
                    _statusLabel(l10n),
                    style: TextStyle(
                      color: _statusColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: AppSizes.lg),
            _buildDetailsRow(context),
            if (_hasVoucher) ...[
              const SizedBox(height: AppSizes.sm),
              // القسيمة للفندق (بلا سعر) + الإيصال للعميل (المبلغ المدفوع).
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.confirmation_number_outlined, size: 18),
                      label: Text(_tm(context,
                          ar: 'عرض القسيمة', en: 'View voucher', es: 'Ver bono', tr: 'Kuponu görüntüle',
                          id: 'Lihat voucher', hi: 'वाउचर देखें', ur: 'واؤچر دیکھیں',
                          fr: 'Voir le bon', bn: 'ভাউচার দেখুন')),
                      onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => HotelVoucherPage(booking: item.hotelBooking!),
                      )),
                    ),
                  ),
                  const SizedBox(width: AppSizes.sm),
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.receipt_long_outlined, size: 18),
                      label: Text(_tm(context,
                          ar: 'الإيصال', en: 'Receipt', es: 'Recibo', tr: 'Makbuz',
                          id: 'Kuitansi', hi: 'रसीद', ur: 'رسید',
                          fr: 'Reçu', bn: 'রসিদ')),
                      onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => HotelReceiptPage(booking: item.hotelBooking!),
                      )),
                    ),
                  ),
                ],
              ),
            ],
            if (_canCancel) ...[
              const SizedBox(height: AppSizes.sm),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: _isCancelling ? null : _confirmAndCancel,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.error,
                    side: const BorderSide(color: AppColors.error),
                  ),
                  child: _isCancelling
                      ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                      : Text(l10n.cancelBooking),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildThumbnail() {
    final item = widget.item;

    if (item.type == InboxItemType.hotelBooking) {
      final images = item.hotelBooking?.hotelImages;
      return Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: AppColors.divider,
          borderRadius: BorderRadius.circular(AppSizes.radiusSm),
          image: (images?.isNotEmpty ?? false)
              ? DecorationImage(
            image: NetworkImage(images!.first),
            fit: BoxFit.cover,
            onError: (_, __) {},
          )
              : null,
        ),
        child: (images?.isEmpty ?? true)
            ? const Icon(Icons.hotel, color: AppColors.textHint)
            : null,
      );
    }

    final icon = item.type == InboxItemType.flightBooking
        ? Icons.flight_takeoff
        : Icons.directions_car;

    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: AppColors.divider,
        borderRadius: BorderRadius.circular(AppSizes.radiusSm),
      ),
      child: Icon(icon, color: AppColors.textHint),
    );
  }

  Widget _buildTitleColumn(BuildContext context) {
    final item = widget.item;

    if (item.type == InboxItemType.hotelBooking) {
      final booking = item.hotelBooking;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            booking?.hotelName ?? '',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
          if (booking?.hotelCity != null)
            Text(
              booking!.hotelCity!,
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
        ],
      );
    }

    if (item.type == InboxItemType.flightBooking) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            [item.airline, item.flightNumber].where((s) => s != null && s.isNotEmpty).join(' · '),
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
          if (item.originCity != null && item.destinationCity != null)
            Text(
              '${item.originCity} → ${item.destinationCity}',
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
        ],
      );
    }

    // carBooking
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          item.carName ?? '',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
        ),
        if (item.carCompany != null)
          Text(
            item.carCompany!,
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
      ],
    );
  }

  Widget _buildDetailsRow(BuildContext context) {
    final item = widget.item;

    if (item.type == InboxItemType.hotelBooking) {
      final booking = item.hotelBooking;
      if (booking == null) return const SizedBox.shrink();
      final dates = Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '${_usDate(booking.checkIn)} – ${_usDate(booking.checkOut)}',
            style: const TextStyle(fontSize: 13),
          ),
          Text(
            // حجوزات HotelBeds: المبلغ المدفوع فعليًا بالدولار.
            booking.isHotelBeds && booking.chargeAmount != null
                ? '${_usd(booking.chargeAmount!)} USD'
                : Formatters.currency(booking.totalPrice),
            style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
          ),
        ],
      );
      if (!booking.isHotelBeds) return dates;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          dates,
          if (booking.supplierReference != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                '${_tm(context, ar: 'رقم الحجز', en: 'Booking reference', es: 'Referencia', tr: 'Rezervasyon no', id: 'Nomor pemesanan', hi: 'बुकिंग संदर्भ', ur: 'بکنگ نمبر', fr: 'Référence', bn: 'বুকিং রেফারেন্স')}: ${booking.supplierReference}',
                style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
            ),
          // ملغى بدون استرداد: نص محايد بدل "Refunded: $0.00" بالأخضر.
          if (booking.status == 'cancelled' &&
              booking.refundAmount != null &&
              booking.refundAmount! <= 0)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                    () {
                  final fee = booking.chargeAmount ?? 0;
                  return _tm(context,
                      ar: 'لا يوجد استرداد (رسوم الإلغاء ${_usd(fee)})',
                      en: 'No refund (cancellation fee ${_usd(fee)})',
                      es: 'Sin reembolso (cargo por cancelación ${_usd(fee)})',
                      tr: 'İade yok (iptal ücreti ${_usd(fee)})',
                      id: 'Tidak ada pengembalian (biaya pembatalan ${_usd(fee)})',
                      hi: 'कोई रिफ़ंड नहीं (रद्दीकरण शुल्क ${_usd(fee)})',
                      ur: 'کوئی واپسی نہیں (منسوخی فیس ${_usd(fee)})',
                      fr: 'Aucun remboursement (frais d\'annulation ${_usd(fee)})',
                      bn: 'কোনো ফেরত নেই (বাতিল ফি ${_usd(fee)})');
                }(),
                style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
            ),
          if (booking.status == 'cancelled' &&
              booking.refundAmount != null &&
              booking.refundAmount! > 0)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                _tm(context,
                    ar: 'المبلغ المسترد: ${_usd(booking.refundAmount!)}',
                    en: 'Refunded: ${_usd(booking.refundAmount!)}',
                    es: 'Reembolsado: ${_usd(booking.refundAmount!)}',
                    tr: 'İade edildi: ${_usd(booking.refundAmount!)}',
                    id: 'Dikembalikan: ${_usd(booking.refundAmount!)}',
                    hi: 'रिफ़ंड किया गया: ${_usd(booking.refundAmount!)}',
                    ur: 'واپس کی گئی رقم: ${_usd(booking.refundAmount!)}',
                    fr: 'Remboursé : ${_usd(booking.refundAmount!)}',
                    bn: 'ফেরত দেওয়া হয়েছে: ${_usd(booking.refundAmount!)}'),
                style: const TextStyle(fontSize: 13, color: AppColors.success),
              ),
            ),
        ],
      );
    }

    if (item.type == InboxItemType.flightBooking) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            item.departureTime != null ? Formatters.date(item.departureTime!) : '',
            style: const TextStyle(fontSize: 13),
          ),
        ],
      );
    }

    // carBooking
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          item.pickupCity ?? '',
          style: const TextStyle(fontSize: 13),
        ),
        Text(
          item.pickupDate != null ? Formatters.date(item.pickupDate!) : '',
          style: const TextStyle(fontSize: 13),
        ),
      ],
    );
  }
}