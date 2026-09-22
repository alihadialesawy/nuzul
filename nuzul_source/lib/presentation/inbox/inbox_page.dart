import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../core/widgets/app_banner.dart';
import '../../core/widgets/loading_view.dart';
import '../../core/widgets/error_view.dart';
import '../../data/models/inbox_item_model.dart';
import 'controllers/inbox_controller.dart';

String _t3(
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

class InboxPage extends ConsumerWidget {
  const InboxPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final itemsAsync = ref.watch(inboxItemsProvider);

    return Scaffold(
      appBar: AppBanner(
        tabsBar: Text(
          _t3(context,
              ar: 'الرسائل', en: 'Inbox', es: 'Bandeja de entrada', tr: 'Gelen Kutusu',
              id: 'Kotak Masuk', hi: 'इनबॉक्स', ur: 'ان باکس', fr: 'Messages', bn: 'ইনবক্স'),
          style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
        ),
        bannerHeight: 160,
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(inboxItemsProvider),
        child: itemsAsync.when(
          loading: () => LoadingView(
            message: _t3(context,
                ar: 'يحمّل الرسائل...', en: 'Loading messages...', es: 'Cargando mensajes...', tr: 'Mesajlar yükleniyor...',
                id: 'Memuat pesan...', hi: 'संदेश लोड हो रहे हैं...', ur: 'پیغامات لوڈ ہو رہے ہیں...', fr: 'Chargement des messages...', bn: 'বার্তা লোড হচ্ছে...'),
          ),
          error: (error, _) => ErrorView(
            message: _t3(context,
                ar: 'تعذر تحميل الرسائل', en: 'Could not load messages', es: 'No se pudieron cargar los mensajes', tr: 'Mesajlar yüklenemedi',
                id: 'Gagal memuat pesan', hi: 'संदेश लोड नहीं हो सके', ur: 'پیغامات لوڈ نہیں ہو سکے', fr: 'Impossible de charger les messages', bn: 'বার্তা লোড করা যায়নি'),
            onRetry: () => ref.invalidate(inboxItemsProvider),
          ),
          data: (items) {
            if (items.isEmpty) {
              return LayoutBuilder(
                builder: (context, constraints) => SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: constraints.maxHeight),
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(AppSizes.lg),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.mail_outline, size: 48, color: AppColors.textSecondary),
                            const SizedBox(height: AppSizes.sm),
                            Text(
                              _t3(context,
                                  ar: 'لسه مفيش رسائل. هنعلمك بأي تحديث على حجوزاتك أو تنبيهات الأسعار.',
                                  en: 'No messages yet. We\'ll notify you about your bookings or price alerts.',
                                  es: 'Aún no hay mensajes. Te avisaremos sobre tus reservas o alertas de precio.',
                                  tr: 'Henüz mesaj yok. Rezervasyonlarınız veya fiyat uyarılarınız hakkında sizi bilgilendireceğiz.',
                                  id: 'Belum ada pesan. Kami akan memberi tahu Anda tentang pemesanan atau peringatan harga.',
                                  hi: 'अभी तक कोई संदेश नहीं। हम आपको आपकी बुकिंग या मूल्य अलर्ट के बारे में सूचित करेंगे।',
                                  ur: 'ابھی تک کوئی پیغام نہیں۔ ہم آپ کو آپ کی بکنگ یا قیمت الرٹس کے بارے میں مطلع کریں گے۔',
                                  fr: 'Aucun message pour le moment. Nous vous informerons de vos réservations ou alertes de prix.',
                                  bn: 'এখনও কোনো বার্তা নেই। আমরা আপনাকে আপনার বুকিং বা মূল্য সতর্কতা সম্পর্কে জানাব।'),
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.all(AppSizes.md),
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: AppSizes.sm),
              itemBuilder: (context, index) => _InboxCard(item: items[index]),
            );
          },
        ),
      ),
    );
  }
}

class _InboxCard extends StatelessWidget {
  final InboxItemModel item;
  const _InboxCard({required this.item});

  String _formatDate(DateTime date) => '${date.day}/${date.month}/${date.year}';

  @override
  Widget build(BuildContext context) {
    late final IconData icon;
    late final Color iconColor;
    late final String title;
    late final String subtitle;

    final isCancelled = item.status == 'cancelled';
    final isConfirmed = item.status == 'confirmed';

    switch (item.type) {
      case InboxItemType.hotelBooking:
        final booking = item.hotelBooking;
        icon = isCancelled ? Icons.cancel_outlined : Icons.hotel_outlined;
        iconColor = isCancelled ? AppColors.error : AppColors.success;
        title = isCancelled
            ? _t3(context, ar: 'تم إلغاء حجز ${booking?.hotelName ?? ""}', en: 'Booking cancelled: ${booking?.hotelName ?? ""}', es: 'Reserva cancelada: ${booking?.hotelName ?? ""}', tr: 'Rezervasyon iptal edildi: ${booking?.hotelName ?? ""}', id: 'Pemesanan dibatalkan: ${booking?.hotelName ?? ""}', hi: 'बुकिंग रद्द: ${booking?.hotelName ?? ""}', ur: 'بکنگ منسوخ: ${booking?.hotelName ?? ""}', fr: 'Réservation annulée : ${booking?.hotelName ?? ""}', bn: 'বুকিং বাতিল: ${booking?.hotelName ?? ""}')
            : isConfirmed
            ? _t3(context, ar: 'تم تأكيد حجز ${booking?.hotelName ?? ""}', en: 'Booking confirmed: ${booking?.hotelName ?? ""}', es: 'Reserva confirmada: ${booking?.hotelName ?? ""}', tr: 'Rezervasyon onaylandı: ${booking?.hotelName ?? ""}', id: 'Pemesanan dikonfirmasi: ${booking?.hotelName ?? ""}', hi: 'बुकिंग की पुष्टि हुई: ${booking?.hotelName ?? ""}', ur: 'بکنگ کی تصدیق ہوگئی: ${booking?.hotelName ?? ""}', fr: 'Réservation confirmée : ${booking?.hotelName ?? ""}', bn: 'বুকিং নিশ্চিত হয়েছে: ${booking?.hotelName ?? ""}')
            : (booking?.hotelName ?? '');
        subtitle = '${booking?.hotelCity ?? ""} · ${_formatDate(booking?.checkIn ?? item.timestamp)}';
        break;

      case InboxItemType.flightBooking:
        icon = isCancelled ? Icons.cancel_outlined : Icons.flight_outlined;
        iconColor = isCancelled ? AppColors.error : AppColors.success;
        title = isCancelled
            ? _t3(context, ar: 'تم إلغاء حجز الرحلة ${item.airline ?? ""}', en: 'Flight cancelled: ${item.airline ?? ""}', es: 'Vuelo cancelado: ${item.airline ?? ""}', tr: 'Uçuş iptal edildi: ${item.airline ?? ""}', id: 'Penerbangan dibatalkan: ${item.airline ?? ""}', hi: 'उड़ान रद्द: ${item.airline ?? ""}', ur: 'پرواز منسوخ: ${item.airline ?? ""}', fr: 'Vol annulé : ${item.airline ?? ""}', bn: 'ফ্লাইট বাতিল: ${item.airline ?? ""}')
            : isConfirmed
            ? _t3(context, ar: 'تم تأكيد حجز الرحلة ${item.airline ?? ""}', en: 'Flight confirmed: ${item.airline ?? ""}', es: 'Vuelo confirmado: ${item.airline ?? ""}', tr: 'Uçuş onaylandı: ${item.airline ?? ""}', id: 'Penerbangan dikonfirmasi: ${item.airline ?? ""}', hi: 'उड़ान की पुष्टि हुई: ${item.airline ?? ""}', ur: 'پرواز کی تصدیق ہوگئی: ${item.airline ?? ""}', fr: 'Vol confirmé : ${item.airline ?? ""}', bn: 'ফ্লাইট নিশ্চিত হয়েছে: ${item.airline ?? ""}')
            : (item.airline ?? '');
        subtitle = '${item.originCity ?? ""} → ${item.destinationCity ?? ""}'
            '${item.departureTime != null ? " · ${_formatDate(item.departureTime!)}" : ""}';
        break;

      case InboxItemType.carBooking:
        icon = isCancelled ? Icons.cancel_outlined : Icons.directions_car_outlined;
        iconColor = isCancelled ? AppColors.error : AppColors.success;
        title = isCancelled
            ? _t3(context, ar: 'تم إلغاء حجز السيارة ${item.carName ?? ""}', en: 'Car booking cancelled: ${item.carName ?? ""}', es: 'Reserva de coche cancelada: ${item.carName ?? ""}', tr: 'Araç rezervasyonu iptal edildi: ${item.carName ?? ""}', id: 'Pemesanan mobil dibatalkan: ${item.carName ?? ""}', hi: 'कार बुकिंग रद्द: ${item.carName ?? ""}', ur: 'کار بکنگ منسوخ: ${item.carName ?? ""}', fr: 'Réservation de voiture annulée : ${item.carName ?? ""}', bn: 'গাড়ি বুকিং বাতিল: ${item.carName ?? ""}')
            : isConfirmed
            ? _t3(context, ar: 'تم تأكيد حجز السيارة ${item.carName ?? ""}', en: 'Car booking confirmed: ${item.carName ?? ""}', es: 'Reserva de coche confirmada: ${item.carName ?? ""}', tr: 'Araç rezervasyonu onaylandı: ${item.carName ?? ""}', id: 'Pemesanan mobil dikonfirmasi: ${item.carName ?? ""}', hi: 'कार बुकिंग की पुष्टि हुई: ${item.carName ?? ""}', ur: 'کار بکنگ کی تصدیق ہوگئی: ${item.carName ?? ""}', fr: 'Réservation de voiture confirmée : ${item.carName ?? ""}', bn: 'গাড়ি বুকিং নিশ্চিত হয়েছে: ${item.carName ?? ""}')
            : (item.carName ?? '');
        subtitle = '${item.carCompany ?? ""} · ${item.pickupCity ?? ""}'
            '${item.pickupDate != null ? " · ${_formatDate(item.pickupDate!)}" : ""}';
        break;

      case InboxItemType.priceWatch:
        icon = Icons.trending_down_rounded;
        iconColor = AppColors.primary;
        title = _t3(context,
            ar: 'توفر السعر المطلوب لرحلتك', en: 'Your target price is now available',
            es: 'Tu precio objetivo ya está disponible', tr: 'Hedef fiyatınız artık uygun',
            id: 'Harga target Anda kini tersedia', hi: 'आपकी लक्षित कीमत अब उपलब्ध है',
            ur: 'آپ کی مطلوبہ قیمت اب دستیاب ہے', fr: 'Votre prix cible est maintenant disponible',
            bn: 'আপনার লক্ষ্য মূল্য এখন উপলব্ধ');
        subtitle = '${item.originCity ?? ""} → ${item.destinationCity ?? ""}'
            '${item.targetPrice != null ? " · ${item.targetPrice!.toStringAsFixed(0)}" : ""}';
        break;
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.divider),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: iconColor.withOpacity(0.1),
          child: Icon(icon, color: iconColor),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle, style: const TextStyle(color: AppColors.textSecondary)),
        trailing: Text(
          _formatDate(item.timestamp),
          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
        ),
        onTap: () => context.push(AppRoutes.myBookings),
      ),
    );
  }
}