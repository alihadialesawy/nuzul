import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'core/theme/app_theme.dart';
import 'core/providers/locale_provider.dart';
import 'localization/app_localizations.dart';
import 'presentation/splash/splash_page.dart';
import 'presentation/auth/login_page.dart';
import 'presentation/auth/register_page.dart';
import 'presentation/home/home_page.dart';
import 'presentation/booking/booking_page.dart';
import 'presentation/my_bookings/my_bookings_page.dart';

/// أسماء المسارات
class AppRoutes {
  AppRoutes._();
  static const String splash = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String home = '/home';
  static const String booking = '/booking';
  static const String myBookings = '/my-bookings';
}

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: AppRoutes.splash,
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => const SplashPage(),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: AppRoutes.register,
        builder: (context, state) => const RegisterPage(),
      ),
      GoRoute(
        path: AppRoutes.home,
        builder: (context, state) => const HomePage(),
      ),
      GoRoute(
        path: AppRoutes.booking,
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>;
          return BookingPage(
            hotel: extra['hotel'],
            checkIn: extra['checkIn'],
            checkOut: extra['checkOut'],
            guests: extra['guests'],
          );
        },
      ),
      GoRoute(
        path: AppRoutes.myBookings,
        builder: (context, state) => const MyBookingsPage(),
      ),
    ],
  );
});

class NuzulApp extends ConsumerWidget {
  const NuzulApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final locale = ref.watch(localeProvider);

    return MaterialApp.router(
      title: 'نزل - Nuzul',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,

      routerConfig: router,

      // اللغة الحالية تتغير تلقائيًا عند الضغط على زر التبديل
      locale: locale,
      supportedLocales: const [
        Locale('ar'),
        Locale('en'),
      ],
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
    );
  }
}