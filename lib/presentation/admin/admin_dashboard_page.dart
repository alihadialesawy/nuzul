import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../core/widgets/app_banner.dart';

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
/// قسم إدارة (حجوزات، فنادق...). الوصول لهذي الشاشة محمي أصلًا على
/// مستوى الـ router نفسه (redirect في app.dart)، فمفيش داعي لأي تحقق
/// إضافي هنا.
class AdminDashboardPage extends StatelessWidget {
  const AdminDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final sections = [
      (
      icon: Icons.receipt_long_outlined,
      color: const Color(0xFF0984E3),
      title: _t3(context, ar: 'إدارة الحجوزات', en: 'Manage Bookings', es: 'Gestionar Reservas'),
      description: _t3(
        context,
        ar: 'مراجعة، تأكيد، أو إلغاء حجوزات الفنادق والرحلات والسيارات',
        en: 'Review, confirm, or cancel hotel, flight, and car bookings',
        es: 'Revisa, confirma o cancela reservas de hoteles, vuelos y coches',
      ),
      route: AppRoutes.adminBookings,
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
      route: AppRoutes.adminHotels,
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
                  onTap: () => context.push(section.route),
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