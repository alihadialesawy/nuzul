import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app.dart';
import '../constants/app_colors.dart';

/// يختار النص المناسب حسب اللغة الحالية من بين الـ 9 لغات المدعومة.
String navText(
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

/// شريط التنقل السفلي الثابت — بيظهر في كل شاشات التطبيق (مربوط عبر
/// ShellRoute في app.dart، مش مكرر يدويًا في كل صفحة). التبويب النشط
/// بيتحدد حسب الرابط الحالي؛ لو المستخدم في شاشة مش من الخمسة
/// الرئيسية (زي شاشة الحجز أو الدفع)، مفيش تبويب متحدد كنشط.
class AppBottomNavBar extends StatelessWidget {
  final String currentLocation;

  const AppBottomNavBar({super.key, required this.currentLocation});

  int get _selectedIndex {
    if (currentLocation == AppRoutes.home) return 0;
    if (currentLocation == AppRoutes.community) return 1;
    if (currentLocation == AppRoutes.myBookings) return 2;
    if (currentLocation == AppRoutes.inbox) return 3;
    if (currentLocation == AppRoutes.profile) return 4;
    return -1;
  }

  void _onTap(BuildContext context, int index) {
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
    final items = [
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

    return SafeArea(
      top: false,
      child: Container(
        height: 62,
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: AppColors.divider, width: 1)),
        ),
        child: Row(
          children: [
            for (var i = 0; i < items.length; i++)
              Expanded(
                child: InkWell(
                  onTap: () => _onTap(context, i),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _selectedIndex == i ? items[i].activeIcon : items[i].icon,
                        color: _selectedIndex == i ? AppColors.primary : AppColors.textSecondary,
                        size: 24,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        items[i].label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          color: _selectedIndex == i ? AppColors.primary : AppColors.textSecondary,
                          fontWeight: _selectedIndex == i ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}