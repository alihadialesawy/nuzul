import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app.dart';
import '../constants/app_colors.dart';
import '../constants/app_sizes.dart';
import '../providers/locale_provider.dart';
import 'currency_selector_button.dart';
import '../../presentation/auth/controllers/auth_controller.dart';
import '../../presentation/auth/controllers/admin_controller.dart';

/// يختار النص المناسب حسب اللغة الحالية (عربي/إنجليزي/إسباني).
String appBannerText(
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

/// البانر المشترك اللي بيظهر أعلى كل شاشات التطبيق: خلفية صورة، اللوجو،
/// وأزرار الإجراءات (AI / تسجيل الدخول / العملة / اللغة / الحساب) في
/// الزاوية العلوية اليسار. لو اتبعتله [tabsBar]، بيظهر فوق منطقة بيضاء
/// (زي شريط تبويبات الصفحة الرئيسية)؛ لو مبعتش، البانر بيبقى بس شريط
/// علوي بسيط (للشاشات التانية زي تسجيل الدخول والحجز). زرار رجوع
/// (سهم) بيظهر تلقائيًا في أقصى اليسار لو فيه صفحة سابقة نقدر نرجعلها.
/// أيقونة لوحة تحكم الأدمن (⚙️) بتظهر بس لو المستخدم الحالي أدمن.
///
/// ملحوظة: الأزرار هنا عمدًا بسيطة (IconButton/OutlinedButton عادي، من
/// غير Material مخصص بـ elevation/InkWell) — نسخة "زجاجية" أنيق أكتر
/// كانت بتسبب خلل معروف في محرك Flutter على Windows desktop
/// ("Cannot hit test a render box with no size") بيجمّد الماوس، فرجعنا
/// للتصميم البسيط المستقر.
class AppBanner extends ConsumerWidget implements PreferredSizeWidget {
  final Widget? tabsBar;
  final double bannerHeight;
  final String? assetVariant;

  const AppBanner({
    super.key,
    this.tabsBar,
    this.bannerHeight = 260,
    this.assetVariant,
  });

  @override
  Size get preferredSize => Size.fromHeight(bannerHeight);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final isAdmin = ref.watch(isAdminProvider);
    final canPop = Navigator.of(context).canPop();

    return SizedBox(
      height: bannerHeight,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Builder(
            builder: (context) {
              final isMobile = MediaQuery.of(context).size.width < 600;
              final variantSuffix = assetVariant != null ? '${assetVariant}_' : '';
              final assetPath = isMobile
                  ? 'assets/images/banner_${variantSuffix}mobile.png'
                  : 'assets/images/banner_${variantSuffix}desktop.png';
              final defaultAssetPath = isMobile
                  ? 'assets/images/banner_mobile.png'
                  : 'assets/images/banner_desktop.png';
              return Image.asset(
                assetPath,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Image.asset(
                  defaultAssetPath,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Image.asset(
                    'assets/images/banner_desktop.png',
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(color: AppColors.primaryDark),
                  ),
                ),
              );
            },
          ),
          Container(color: Colors.black.withOpacity(0.25)),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSizes.md, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (canPop) ...[
                        IconButton(
                          icon: const Icon(Icons.arrow_back, color: Colors.white),
                          onPressed: () => context.pop(),
                        ),
                        const SizedBox(width: 4),
                      ],
                      GestureDetector(
                        onTap: () => context.go(AppRoutes.home),
                        child: const Text(
                          'SkyNoom',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 30,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            if (isAdmin) ...[
                              IconButton(
                                icon: const Icon(Icons.admin_panel_settings_outlined, color: Colors.white),
                                tooltip: appBannerText(
                                  context,
                                  ar: 'لوحة تحكم الأدمن',
                                  en: 'Admin dashboard',
                                  es: 'Panel de administración',
                                ),
                                onPressed: () => context.push(AppRoutes.adminDashboard),
                              ),
                              const SizedBox(width: 4),
                            ],
                            Flexible(
                              child: OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.white,
                                  side: const BorderSide(color: Colors.white, width: 1.2),
                                  shape: const StadiumBorder(),
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                ),
                                onPressed: () => context.push(AppRoutes.aiTravel),
                                icon: const Icon(Icons.auto_awesome, size: 14),
                                label: const Text('AI', style: TextStyle(fontSize: 13)),
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              icon: const Icon(Icons.person_outline, color: Colors.white),
                              onPressed: () async {
                                if (user == null) {
                                  await context.push(AppRoutes.login);
                                  if (context.mounted) context.push(AppRoutes.profile);
                                } else {
                                  context.push(AppRoutes.profile);
                                }
                              },
                            ),
                            const CurrencySelectorButton(),
                            PopupMenuButton<Locale>(
                              icon: const Icon(Icons.language, color: Colors.white),
                              onSelected: (locale) => ref.read(localeProvider.notifier).setLocale(locale),
                              itemBuilder: (context) => const [
                                PopupMenuItem(value: Locale('ar'), child: Text('العربية')),
                                PopupMenuItem(value: Locale('en'), child: Text('English')),
                                PopupMenuItem(value: Locale('es'), child: Text('Español')),
                              ],
                            ),
                            IconButton(
                              icon: const Icon(Icons.receipt_long_outlined, color: Colors.white),
                              onPressed: () async {
                                if (user == null) {
                                  await context.push(AppRoutes.login);
                                  if (context.mounted) context.push(AppRoutes.myBookings);
                                } else {
                                  context.push(AppRoutes.myBookings);
                                }
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.support_agent_outlined, color: Colors.white),
                              onPressed: () => context.push(AppRoutes.support),
                            ),
                            if (user == null)
                              Flexible(
                                child: OutlinedButton(
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.white,
                                    side: const BorderSide(color: Colors.white, width: 1.2),
                                    shape: const StadiumBorder(),
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                  ),
                                  onPressed: () => context.push(AppRoutes.login),
                                  child: Text(
                                    appBannerText(context, ar: 'تسجيل الدخول', en: 'Sign in', es: 'Iniciar sesión'),
                                    style: const TextStyle(fontSize: 13),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (tabsBar != null) ...[
                    const Spacer(),
                    tabsBar!,
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}