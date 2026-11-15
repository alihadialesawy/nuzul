import 'package:flutter/foundation.dart';

/// مورّد الفنادق المستخدم في البحث.
///
/// أثناء الانتقال من HotelBeds إلى LiteAPI:
///   • التشغيل المحلي (debug: زر ▶ أو flutter run)  → LiteAPI تلقائيًا.
///   • نسخة النشر (release: Netlify، Google Play، App Store) → HotelBeds،
///     لأن صفحة الفندق والدفع والحجز ما زالت مبنية عليه (المراحل 3–6).
///
/// لتغيير ذلك يدويًا في أي تشغيل:
///   --dart-define=HOTEL_SUPPLIER=hotelbeds   أو   --dart-define=HOTEL_SUPPLIER=liteapi
///
/// عند اكتمال كل المراحل نجعل الافتراضي 'liteapi' في الحالتين.
const String kHotelSupplier = String.fromEnvironment(
  'HOTEL_SUPPLIER',
  defaultValue: kDebugMode ? 'liteapi' : 'hotelbeds',
);

bool get kUseLiteApi => kHotelSupplier == 'liteapi';

/// اسم Edge Function البحث حسب المورّد. كلاهما يُرجع نفس شكل الرد.
String get kHotelSearchFunction {
  final fn = kUseLiteApi ? 'liteapi-search' : 'hotelbeds-search';
  if (kDebugMode) debugPrint('HOTEL SEARCH → $fn');
  return fn;
}