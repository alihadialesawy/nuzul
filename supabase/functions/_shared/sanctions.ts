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

import { fetchWithTimeout, HOTELBEDS_BASE_URL, hotelbedsHeaders } from './hotelbeds.ts';

/// دول تخضع لعقوبات أمريكية شاملة (ISO-3166 alpha-2 كما يرجعها HotelBeds).
export const BLOCKED_COUNTRY_CODES = new Set<string>([
  'CU', // كوبا
  'IR', // إيران
  'KP', // كوريا الشمالية
]);

/// دول لا نبيع فيها إقامات بقرار تجاري/احتياطي (ليست عقوبات أمريكية شاملة):
///   • روسيا وبيلاروسيا: فنادق كثيرة مملوكة لأشخاص على قائمة SDN، وبطاقات
///     Visa/Mastercard لا تعمل هناك، فلا فائدة تجارية والمخاطرة عالية.
///   • سوريا: رُفعت العقوبات الشاملة في يوليو 2025 (EO 14312)، لكن عقوبات SDN
///     باقية. محظورة حتى يراجعها المحامي.
/// تُطبَّق على موقع الفندق فقط (لا على بلد البطاقة أو IP؛ الزبون مقيم في أمريكا).
/// ⚠️ أي تعديل هنا يجب أن ينعكس على البند 3 في شروط الخدمة (9 لغات).
export const NOT_OFFERED_COUNTRY_CODES = new Set<string>([
  'RU', // روسيا
  'BY', // بيلاروسيا
  'SY', // سوريا
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
  if (!countryCode) return false;
  const c = countryCode.toUpperCase();
  return BLOCKED_COUNTRY_CODES.has(c) || NOT_OFFERED_COUNTRY_CODES.has(c);
}

/// هل الفندق داخل منطقة محظورة في أوكرانيا؟ (يُستدعى فقط إن كانت الدولة UA)
export function isBlockedUkraineLocation(lat: number | null, lon: number | null): boolean {
  if (lat == null || lon == null) return false;
  return BLOCKED_UA_BOXES.some(
    (b) => lat >= b.minLat && lat <= b.maxLat && lon >= b.minLon && lon <= b.maxLon,
  );
}

const destinationCountryCache = new Map<string, string | null>();

/// دولة وجهة HotelBeds (ISO-2) من Content API. null عند تعذّر الاستعلام.
export async function destinationCountryCode(destinationCode: string): Promise<string | null> {
  const key = String(destinationCode ?? '').toUpperCase();
  if (!key) return null;
  if (destinationCountryCache.has(key)) return destinationCountryCache.get(key)!;
  try {
    const params = new URLSearchParams({ fields: 'code,countryCode', codes: key, language: 'ENG', from: '1', to: '1' });
    const res = await fetchWithTimeout(
      `${HOTELBEDS_BASE_URL}/hotel-content-api/1.0/locations/destinations?${params.toString()}`,
      { method: 'GET', headers: await hotelbedsHeaders() },
      6000,
    );
    if (!res.ok) return null;
    const c = (await res.json())?.destinations?.[0]?.countryCode;
    const country = typeof c === 'string' && c ? c.toUpperCase() : null;
    destinationCountryCache.set(key, country);
    return country;
  } catch {
    return null;
  }
}

/// فحص الفندق عند الحجز (لا البحث فقط): الدولة + مناطق أوكرانيا المحظورة.
/// يرجع سبب الحظر أو null. عند تعذّر معرفة الدولة نسمح (fail-open) ونسجّل،
/// لأن فحص دولة البطاقة ودولة الزائر يبقيان في بوابة الاحتيال.
export async function blockedHotelReason(hotel: any): Promise<string | null> {
  const destination = String(hotel?.destinationCode ?? '');
  const country = await destinationCountryCode(destination);
  if (!country) console.log(`SANCTIONS: country unknown for destination ${destination || '-'}`);
  if (isBlockedDestination(country, destination)) return `sanctioned_destination:${country ?? destination}`;
  if (country === 'UA') {
    const lat = Number(hotel?.latitude);
    const lon = Number(hotel?.longitude);
    if (isBlockedUkraineLocation(Number.isFinite(lat) ? lat : null, Number.isFinite(lon) ? lon : null)) {
      return 'sanctioned_region:UA';
    }
  }
  return null;
}