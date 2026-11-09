/// موسم الحج: لا حجوزات لفنادق مكة المكرمة (وجهة HotelBeds: QCA) خلال فترة
/// منع دخول مكة لغير حاملي تصريح الحج.
///
/// ⚠️ نسخة مطابقة لـ supabase/functions/_shared/hajj.ts (الخادم هو الحَكَم
/// النهائي؛ هذه للتنبيه المبكر في الواجهة فقط). حدّث الملفين معًا كل سنة من
/// الإعلان الرسمي السعودي. التواريخ تقريبية وفيها هامش أمان.
library;

const String kMakkahDestinationCode = 'QCA';

class HajjBlockWindow {
  final DateTime from; // أول يوم ممنوع
  final DateTime to; // آخر يوم ممنوع (شامل)
  const HajjBlockWindow(this.from, this.to);
}

/// حج 1448 هـ (عرفة تقريبًا 15–16 مايو 2027)، وحج 1449 هـ (عرفة تقريبًا 4–5 مايو 2028).
final List<HajjBlockWindow> kHajjBlockWindows = [
  HajjBlockWindow(DateTime.utc(2027, 4, 1), DateTime.utc(2027, 5, 25)),
  HajjBlockWindow(DateTime.utc(2028, 3, 21), DateTime.utc(2028, 5, 14)),
];

/// هل تتقاطع إقامة في مكة مع موسم الحج؟ (الليالي من الوصول حتى ليلة ما قبل المغادرة)
bool isMakkahHajjSeasonConflict(String? destinationCode, DateTime checkIn, DateTime checkOut) {
  if ((destinationCode ?? '').toUpperCase() != kMakkahDestinationCode) return false;
  final start = DateTime.utc(checkIn.year, checkIn.month, checkIn.day);
  final end = DateTime.utc(checkOut.year, checkOut.month, checkOut.day);
  for (final w in kHajjBlockWindows) {
    final wEnd = w.to.add(const Duration(days: 1));
    if (start.isBefore(wEnd) && end.isAfter(w.from)) return true;
  }
  return false;
}