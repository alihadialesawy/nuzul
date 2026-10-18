import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app.dart';
import '../../core/config/features.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../core/widgets/app_banner.dart';
import 'admin_booking_desk_page.dart';
import 'admin_group_requests_page.dart';

/// يختار النص المناسب حسب اللغة الحالية (عربي/إنجليزي/إسباني).
String _t3(
    BuildContext context, {
      required String ar,
      required String en,
      required String es,
    }) {
  switch (Localizations.localeOf(context).languageCode) {
    case 'ar':
      return ar;
    case 'es':
      return es;
    default:
      return en;
  }
}

/// نقطة الدخول الرئيسية للوحة تحكم الأدمن — بطاقات بسيطة تودّي لكل
/// قسم إدارة (حجوزات، طلبات مجموعات، فنادق...). الوصول لهذي الشاشة محمي
/// على مستوى الـ router (redirect في app.dart)، والبيانات نفسها محمية
/// بسياسات RLS عبر public.is_admin().
class AdminDashboardPage extends StatelessWidget {
  const AdminDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    // نص الحجوزات يتبع الأقسام المفعّلة فقط (الطيران والسيارات مخفيان حاليًا).
    final bookingsDescription = (kFlightsEnabled || kCarsEnabled)
        ? _t3(
      context,
      ar: 'مراجعة، تأكيد، أو إلغاء حجوزات الفنادق والرحلات والسيارات',
      en: 'Review, confirm, or cancel hotel, flight, and car bookings',
      es: 'Revisa, confirma o cancela reservas de hoteles, vuelos y coches',
    )
        : _t3(
      context,
      ar: 'مراجعة، تأكيد، أو إلغاء حجوزات الفنادق',
      en: 'Review, confirm, or cancel hotel bookings',
      es: 'Revisa, confirma o cancela reservas de hoteles',
    );

    final sections = <({
    IconData icon,
    Color color,
    String title,
    String description,
    VoidCallback onTap,
    })>[
      (
      icon: Icons.receipt_long_outlined,
      color: const Color(0xFF0984E3),
      title: _t3(context, ar: 'مكتب الحجوزات', en: 'Booking Desk', es: 'Mesa de Reservas'),
      description: _t3(
        context,
        ar: 'حجوزات HotelBeds الحقيقية: التفاصيل، والإلغاء نيابة عن العميل مع الاسترداد',
        en: 'Real HotelBeds bookings: details, and cancel on behalf of the guest with refund',
        es: 'Reservas reales de HotelBeds: detalles y cancelación con reembolso',
      ),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const AdminBookingDeskPage()),
      ),
      ),
      (
      icon: Icons.history_outlined,
      color: const Color(0xFF636E72),
      title: _t3(context, ar: 'الحجوزات القديمة', en: 'Legacy Bookings', es: 'Reservas Antiguas'),
      description: bookingsDescription,
      onTap: () => context.push(AppRoutes.adminBookings),
      ),
      (
      icon: Icons.groups_outlined,
      color: const Color(0xFFE17055),
      title: _t3(context, ar: 'طلبات المجموعات', en: 'Group Requests', es: 'Solicitudes de Grupos'),
      description: _t3(
        context,
        ar: 'طلبات 5 غرف فأكثر: عرض الطلبات، تغيير الحالة، وإضافة ملاحظات',
        en: 'Requests for 5+ rooms: view, update status, and add notes',
        es: 'Solicitudes de 5+ habitaciones: ver, cambiar estado y añadir notas',
      ),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const AdminGroupRequestsPage()),
      ),
      ),
      (
      icon: Icons.hotel_outlined,
      color: const Color(0xFF00B894),
      title: _t3(context, ar: 'إدارة الفنادق', en: 'Manage Hotels', es: 'Gestionar Hoteles'),
      description: _t3(
        context,
        ar: 'إضافة، تعديل، أو حذف الفنادق والغرف المعروضة بالتطبيق',
        en: 'Add, edit, or remove hotels and rooms shown in the app',
        es: 'Añade, edita o elimina hoteles y habitaciones en la app',
      ),
      onTap: () => context.push(AppRoutes.adminHotels),
      ),
    ];

    return Scaffold(
      appBar: AppBanner(
        tabsBar: Text(
          _t3(context, ar: 'لوحة تحكم الأدمن', en: 'Admin Dashboard', es: 'Panel de Administración'),
          style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
        ),
        bannerHeight: 160,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSizes.md),
          children: [
            for (final section in sections)
              Card(
                margin: const EdgeInsets.only(bottom: AppSizes.md),
                child: InkWell(
                  onTap: section.onTap,
                  child: Padding(
                    padding: const EdgeInsets.all(AppSizes.md),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: section.color.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(section.icon, color: section.color, size: 28),
                        ),
                        const SizedBox(width: AppSizes.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                section.title,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                section.description,
                                style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.arrow_forward_ios, size: 16, color: AppColors.textHint),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}