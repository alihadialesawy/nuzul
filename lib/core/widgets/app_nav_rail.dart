import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app.dart';
import '../constants/app_colors.dart';
import 'app_bottom_nav_bar.dart' show navText;
import 'sidebar_promo_flash.dart';

/// ألوان مميزة لكل تبويب في شريط التنقل، بنفس فلسفة الألوان المستخدمة
/// في أماكن تانية بالتطبيق (بروفايل، بيانات المسافرين) -- كل تبويب له
/// لون ثابت يظهر عليه (كامل لو متفعّل، شفاف جزئيًا لو لأ) بدل اللون
/// الرمادي/الأساسي الموحّد.
const List<Color> _navTabColors = [
  Color(0xFF2E86AB), // الرئيسية - أزرق
  Color(0xFF27AE60), // المجتمع - أخضر
  Color(0xFFE67E22), // رحلاتي - برتقالي
  Color(0xFF8E44AD), // الرسائل - بنفسجي
  Color(0xFFD6558E), // الحساب - وردي
];

/// نسخة شريط تنقل جانبي رفيع من AppBottomNavBar، بتظهر بدل الشريط
/// السفلي على الشاشات العريضة (سطح المكتب/الويب/تابلت بالعرض الأفقي)
/// عشان توفر المساحة العمودية اللي شريط سفلي تقليدي كان بياخدها، فمساحة
/// عرض المحتوى (نتائج البحث مثلاً) تكبر بدون سكرول زيادة. نفس منطق
/// التبويبات، الأيقونات، والترجمة بالظبط زي AppBottomNavBar (نفس دالة
/// navText مستوردة من هناك، من غير تكرار).
///
/// المساحة الفاضية أسفل آخر تبويب (Account) بقى فيها SidebarPromoFlash
/// -- عنصر صغير متحرك (أيقونة نابضة + نص بيتغيّر) للفت الانتباه لعروض
/// أو تحديثات، بدون ما ياخد مساحة كبيرة من الشريط الضيق.
class AppNavRail extends StatelessWidget {
  final String currentLocation;

  const AppNavRail({super.key, required this.currentLocation});

  int get _selectedIndex {
    if (currentLocation == AppRoutes.home) return 0;
    if (currentLocation == AppRoutes.community) return 1;
    if (currentLocation == AppRoutes.myBookings) return 2;
    if (currentLocation == AppRoutes.inbox) return 3;
    if (currentLocation == AppRoutes.profile) return 4;
    return -1;
  }

  void _onDestinationSelected(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go(AppRoutes.home);
        break;
      case 1:
        context.go(AppRoutes.community);
        break;
      case 2:
        context.go(AppRoutes.myBookings);
        break;
      case 3:
        context.go(AppRoutes.inbox);
        break;
      case 4:
        context.go(AppRoutes.profile);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final destinations = [
      (
      icon: Icons.home_outlined,
      activeIcon: Icons.home,
      label: navText(context,
          ar: 'الرئيسية', en: 'Home', es: 'Inicio', tr: 'Ana Sayfa',
          id: 'Beranda', hi: 'होम', ur: 'ہوم', fr: 'Accueil', bn: 'হোম'),
      ),
      (
      icon: Icons.groups_outlined,
      activeIcon: Icons.groups,
      label: navText(context,
          ar: 'المجتمع', en: 'Community', es: 'Comunidad', tr: 'Topluluk',
          id: 'Komunitas', hi: 'समुदाय', ur: 'کمیونٹی', fr: 'Communauté', bn: 'কমিউনিটি'),
      ),
      (
      icon: Icons.card_travel_outlined,
      activeIcon: Icons.card_travel,
      label: navText(context,
          ar: 'رحلاتي', en: 'Trips', es: 'Viajes', tr: 'Seyahatlerim',
          id: 'Perjalanan', hi: 'यात्राएँ', ur: 'سفر', fr: 'Voyages', bn: 'ভ্রমণ'),
      ),
      (
      icon: Icons.mail_outline,
      activeIcon: Icons.mail,
      label: navText(context,
          ar: 'الرسائل', en: 'Inbox', es: 'Bandeja', tr: 'Gelen Kutusu',
          id: 'Kotak Masuk', hi: 'इनबॉक्स', ur: 'ان باکس', fr: 'Messages', bn: 'ইনবক্স'),
      ),
      (
      icon: Icons.person_outline,
      activeIcon: Icons.person,
      label: navText(context,
          ar: 'الحساب', en: 'Account', es: 'Cuenta', tr: 'Hesap',
          id: 'Akun', hi: 'खाता', ur: 'اکاؤنٹ', fr: 'Compte', bn: 'অ্যাকাউন্ট'),
      ),
    ];

    final selected = _selectedIndex;

    return Container(
      width: 88,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(right: BorderSide(color: AppColors.divider, width: 1)),
      ),
      child: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 12),
            for (var i = 0; i < destinations.length; i++)
              InkWell(
                onTap: () => _onDestinationSelected(context, i),
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
                  child: Column(
                    children: [
                      Icon(
                        selected == i ? destinations[i].activeIcon : destinations[i].icon,
                        color: selected == i
                            ? _navTabColors[i]
                            : _navTabColors[i].withOpacity(0.45),
                        size: 24,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        destinations[i].label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 11,
                          color: selected == i
                              ? _navTabColors[i]
                              : _navTabColors[i].withOpacity(0.45),
                          fontWeight: selected == i ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            const Divider(height: 20, indent: 16, endIndent: 16),
            const SidebarPromoFlash(),
          ],
        ),
      ),
    );
  }
}