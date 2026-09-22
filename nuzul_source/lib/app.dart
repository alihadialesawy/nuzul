import 'core/widgets/app_nav_rail.dart';
import 'presentation/profile/my_coins_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'core/theme/app_theme.dart';
import 'core/providers/locale_provider.dart';
import 'core/widgets/app_bottom_nav_bar.dart';
import 'localization/app_localizations.dart';
import 'presentation/auth/login_page.dart';
import 'presentation/auth/register_page.dart';
import 'presentation/auth/controllers/admin_controller.dart';
import 'presentation/home/home_page.dart';
import 'presentation/hotel_details/hotel_details_page.dart';
import 'presentation/booking/booking_page.dart';
import 'presentation/flights/flight_booking_page.dart';
import 'presentation/flights/duffel_flight_booking_page.dart';
import 'presentation/flights/flight_hotel_bundle_booking_page.dart';
import 'presentation/car_rental/car_booking_page.dart';
import 'presentation/my_bookings/my_bookings_page.dart';
import 'presentation/flights/flights_search_page.dart';
import 'presentation/ai_travel/ai_travel_page.dart';
import 'presentation/profile/profile_page.dart';
import 'presentation/support/support_page.dart';
import 'presentation/about/about_page.dart';
import 'presentation/admin/admin_dashboard_page.dart';
import 'presentation/admin/admin_bookings_page.dart';
import 'presentation/admin/admin_hotels_page.dart';
import 'presentation/community/community_page.dart';
import 'presentation/inbox/inbox_page.dart';

/// أسماء المسارات
class AppRoutes {
  AppRoutes._();
  static const String home = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String hotelDetails = '/hotel-details';
  static const String booking = '/booking';
  static const String flightBooking = '/flight-booking';
  static const String duffelFlightBooking = '/duffel-flight-booking';
  static const String flightHotelBundleBooking = '/flight-hotel-bundle-booking';
  static const String carBooking = '/car-booking';
  static const String myBookings = '/my-bookings';
  static const String flights = '/flights';
  static const String aiTravel = '/ai-travel';
  static const String myCoins = '/my-coins';
  static const String profile = '/profile';
  static const String support = '/support';
  static const String about = '/about';
  static const String adminDashboard = '/admin';
  static const String adminBookings = '/admin/bookings';
  static const String adminHotels = '/admin/hotels';
  static const String community = '/community';
  static const String inbox = '/inbox';
}

// مفتاح الـ Navigator الجذري — لازم يتحدد صراحةً لما بنستخدم ShellRoute
// عشان GoRouter يعرف يميّز بين الـ Navigator الأساسي والفرعي بتاع الـ Shell.
final _rootNavigatorKey = GlobalKey<NavigatorState>();

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: AppRoutes.home,
    // يمنع أي حد مش أدمن من فتح أي مسار تحت /admin مباشرة (سواء
    // بالضغط على رابط أو بكتابة الرابط يدويًا). لو حاول، بيترجّع
    // للصفحة الرئيسية فورًا بدل ما تظهر له شاشة الأدمن أصلًا.
    redirect: (context, state) {
      final goingToAdmin = state.matchedLocation.startsWith(AppRoutes.adminDashboard);
      if (!goingToAdmin) return null;

      final isAdmin = ref.read(isAdminProvider);
      if (!isAdmin) return AppRoutes.home;
      return null;
    },
    routes: [
      // كل مسارات التطبيق بقت لافّة جوّه ShellRoute واحد، عشان شريط
      // التنقل السفلي (AppBottomNavBar) يظهر ثابت في كل شاشة دايمًا،
      // بدل ما نضيفه يدويًا بكل صفحة لوحدها. الـ Scaffold الخارجي هنا
      // هو المسؤول عن bottomNavigationBar بس؛ كل صفحة لسه محتفظة
      // بالـ Scaffold/AppBanner الخاص بيها جوّه.
      ShellRoute(
        navigatorKey: GlobalKey<NavigatorState>(),
        builder: (context, state, child) {
          // نستخدم LayoutBuilder عشان نفرّق بين الشاشات الضيقة (موبايل) اللي
          // بيظهر فيها شريط تنقل سفلي تقليدي، والشاشات العريضة (سطح المكتب/
          // الويب/تابلت أفقي) اللي بيظهر فيها شريط تنقل جانبي رفيع بدلًا منه
          // — عشان الشريط السفلي كان بياخد مساحة عمودية ثمينة من غير داعي
          // على الشاشات الواسعة، فمساحة عرض المحتوى (نتائج البحث مثلاً) تكبر.
          return LayoutBuilder(
            builder: (context, constraints) {
              const wideBreakpoint = 700.0;
              final isWide = constraints.maxWidth >= wideBreakpoint;

              if (isWide) {
                return Scaffold(
                  body: Row(
                    children: [
                      AppNavRail(currentLocation: state.matchedLocation),
                      const VerticalDivider(width: 1),
                      Expanded(child: child),
                    ],
                  ),
                );
              }

              return Scaffold(
                body: child,
                bottomNavigationBar: AppBottomNavBar(currentLocation: state.matchedLocation),
              );
            },
          );
        },
        routes: [
          GoRoute(
            path: AppRoutes.home,
            builder: (context, state) => const HomePage(),
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
            path: AppRoutes.hotelDetails,
            builder: (context, state) {
              final extra = state.extra as Map<String, dynamic>;
              return HotelDetailsPage(
                hotel: extra['hotel'],
                checkIn: extra['checkIn'],
                checkOut: extra['checkOut'],
                guests: extra['guests'],
              );
            },
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
                selectedRooms: extra['selectedRooms'],
              );
            },
          ),
          GoRoute(
            path: AppRoutes.flightBooking,
            builder: (context, state) {
              final extra = state.extra as Map<String, dynamic>;
              return FlightBookingPage(
                flight: extra['flight'],
                travelDate: extra['travelDate'],
                travelers: extra['travelers'],
              );
            },
          ),
          GoRoute(
            path: AppRoutes.duffelFlightBooking,
            builder: (context, state) {
              final extra = state.extra as Map<String, dynamic>;
              return DuffelFlightBookingPage(offer: extra['offer']);
            },
          ),
          GoRoute(
            path: AppRoutes.flightHotelBundleBooking,
            builder: (context, state) {
              final extra = state.extra as Map<String, dynamic>;
              return FlightHotelBundleBookingPage(
                offer: extra['offer'],
                hotel: extra['hotel'],
                checkIn: extra['checkIn'],
                checkOut: extra['checkOut'],
                guests: extra['guests'],
              );
            },
          ),
          GoRoute(
            path: AppRoutes.carBooking,
            builder: (context, state) {
              final extra = state.extra as Map<String, dynamic>;
              return CarBookingPage(
                car: extra['car'],
                pickupCity: extra['pickupCity'],
                pickupDate: extra['pickupDate'],
                dropoffDate: extra['dropoffDate'],
              );
            },
          ),
          GoRoute(
            path: AppRoutes.myBookings,
            builder: (context, state) => const MyBookingsPage(),
          ),
          GoRoute(
            path: AppRoutes.flights,
            pageBuilder: (context, state) => CustomTransitionPage(
              key: state.pageKey,
              child: const FlightsSearchPage(),
              transitionDuration: Duration.zero,
              reverseTransitionDuration: Duration.zero,
              transitionsBuilder: (context, animation, secondaryAnimation, child) => child,
            ),
          ),
          GoRoute(
            path: AppRoutes.aiTravel,
            builder: (context, state) => const AiTravelPage(),
          ),
          GoRoute(
            path: AppRoutes.myCoins,
            builder: (context, state) => const MyCoinsPage(),
          ),
          GoRoute(
            path: AppRoutes.profile,
            builder: (context, state) => const ProfilePage(),
          ),
          GoRoute(
            path: AppRoutes.support,
            builder: (context, state) => const SupportPage(),
          ),
          GoRoute(
            path: AppRoutes.about,
            builder: (context, state) => const AboutPage(),
          ),
          GoRoute(
            path: AppRoutes.adminDashboard,
            builder: (context, state) => const AdminDashboardPage(),
          ),
          GoRoute(
            path: AppRoutes.adminBookings,
            builder: (context, state) => const AdminBookingsPage(),
          ),
          GoRoute(
            path: AppRoutes.adminHotels,
            builder: (context, state) => const AdminHotelsPage(),
          ),
          GoRoute(
            path: AppRoutes.community,
            builder: (context, state) => const CommunityPage(),
          ),
          GoRoute(
            path: AppRoutes.inbox,
            builder: (context, state) => const InboxPage(),
          ),
        ],
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
      title: 'SkyNoom',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,

      routerConfig: router,

      // اللغة الحالية تتغير تلقائيًا عند اختيارها من قائمة اللغة
      locale: locale,
      supportedLocales: const [
        Locale('ar'),
        Locale('en'),
        Locale('es'),
        Locale('tr'),
        Locale('id'),
        Locale('hi'),
        Locale('ur'),
        Locale('fr'),
        Locale('bn'),
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