// supabase/functions/_shared/sanctions.ts
//
// العقوبات الأمريكية (OFAC): FLYNOOM LLC شركة أمريكية، فيُمنع عليها بيع
// إقامات في الدول/المناطق الخاضعة لعقوبات شاملة، حتى لو عرضها المزوّد
// (HOTELBEDS شركة أوروبية ولا تطبّق العقوبات الأمريكية نفسها؛ كوبا مثلًا
// موجودة في مخزونها).
//
// ⚠️ راجع هذه القائمة مع المحامي عند أي تغيير في برامج العقوبات:
//   https://ofac.treasury.gov/sanctions-programs-and-country-information
// وأي تعديل هنا يجب أن ينعكس على البند 3 في شروط الخدمة (9 لغات).

/// دول تخضع لعقوبات أمريكية شاملة (ISO-3166 alpha-2 كما يرجعها HotelBeds).
export const BLOCKED_COUNTRY_CODES = new Set<string>([
  'CU', // كوبا
  'IR', // إيران
  'KP', // كوريا الشمالية
]);

/// أكواد وجهات HotelBeds محظورة بعينها (إن ظهرت وجهة داخل منطقة محظورة
/// ودولتها غير محظورة بالكامل). أضف الكود هنا عند اكتشافه.
export const BLOCKED_DESTINATION_CODES = new Set<string>([]);

/// مناطق أوكرانيا الخاضعة لعقوبات شاملة: القرم، ودونيتسك، ولوغانسك.
/// نستخدم مربعات إحداثيات تقريبية (واسعة قليلًا عمدًا) لفنادق دولة UA.
const BLOCKED_UA_BOXES: Array<{ name: string; minLat: number; maxLat: number; minLon: number; maxLon: number }> = [
  { name: 'Crimea', minLat: 44.3, maxLat: 46.3, minLon: 32.4, maxLon: 36.7 },
  { name: 'Donetsk/Luhansk', minLat: 46.9, maxLat: 50.2, minLon: 36.6, maxLon: 40.3 },
];

/// هل الوجهة محظورة بالكامل؟ (حسب كود الدولة أو كود الوجهة)
export function isBlockedDestination(countryCode: string | null | undefined, destinationCode: string): boolean {
  if (BLOCKED_DESTINATION_CODES.has(destinationCode.toUpperCase())) return true;
  return !!countryCode && BLOCKED_COUNTRY_CODES.has(countryCode.toUpperCase());
}

/// هل الفندق داخل منطقة محظورة في أوكرانيا؟ (يُستدعى فقط إن كانت الدولة UA)
export function isBlockedUkraineLocation(lat: number | null, lon: number | null): boolean {
  if (lat == null || lon == null) return false;
  return BLOCKED_UA_BOXES.some(
    (b) => lat >= b.minLat && lat <= b.maxLat && lon >= b.minLon && lon <= b.maxLon,
  );
}