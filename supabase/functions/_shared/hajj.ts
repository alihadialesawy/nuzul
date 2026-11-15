// supabase/functions/_shared/hajj.ts
//
// موسم الحج: تمنع السلطات السعودية دخول مكة المكرمة لغير حاملي تصريح الحج
// لعدة أسابيع قبل الحج وأيامًا بعده (وتتوقف تصاريح العمرة). أي حجز فندق في
// مكة خلال هذه الفترة لن يستطيع الزبون (القادم بتأشيرة سياحية) استخدامه.
// لذلك نمنع حجوزات فنادق مكة (وجهة HotelBeds: QCA) التي تتقاطع مع النافذة.
//
// ⚠️ التواريخ تقريبية (التقويم الهجري يُحدَّد برؤية الهلال) وفيها هامش أمان.
// حدّثها كل سنة من الإعلان الرسمي لوزارة الحج والعمرة/وزارة الداخلية السعودية،
// وحدّث النسخة المطابقة في lib/core/constants/hajj_season.dart.
//
// يمكن تجاوزها دون إعادة نشر عبر السر HAJJ_BLOCK_WINDOWS بصيغة:
//   [{"from":"2027-04-01","to":"2027-05-25"}]

export const MAKKAH_DESTINATION_CODE = 'QCA';

interface Window {
  from: string; // YYYY-MM-DD (أول يوم ممنوع)
  to: string; // YYYY-MM-DD (آخر يوم ممنوع)
}

/// حج 1448 هـ: يوم عرفة تقريبًا 15–16 مايو 2027.
/// حج 1449 هـ: يوم عرفة تقريبًا 4–5 مايو 2028.
const DEFAULT_WINDOWS: Window[] = [
  { from: '2027-04-01', to: '2027-05-25' },
  { from: '2028-03-21', to: '2028-05-14' },
];

function windows(): Window[] {
  const raw = Deno.env.get('HAJJ_BLOCK_WINDOWS');
  if (!raw) return DEFAULT_WINDOWS;
  try {
    const parsed = JSON.parse(raw);
    if (Array.isArray(parsed)) {
      const ok = parsed.filter(
        (w: any) => /^\d{4}-\d{2}-\d{2}$/.test(String(w?.from)) && /^\d{4}-\d{2}-\d{2}$/.test(String(w?.to)),
      );
      if (ok.length) return ok;
    }
  } catch {
    console.log('HAJJ_BLOCK_WINDOWS is not valid JSON; using defaults');
  }
  return DEFAULT_WINDOWS;
}

/// يرجع نافذة الحج التي تتقاطع معها الإقامة في مكة، أو null.
/// الإقامة = الليالي من checkIn حتى اليوم السابق لـ checkOut.
export function hajjSeasonConflict(
  destinationCode: string | null | undefined,
  checkIn: string,
  checkOut: string,
): Window | null {
  if (String(destinationCode ?? '').toUpperCase() !== MAKKAH_DESTINATION_CODE) return null;
  const start = Date.parse(`${checkIn}T00:00:00Z`);
  const end = Date.parse(`${checkOut}T00:00:00Z`); // يوم المغادرة غير محسوب كليلة
  if (Number.isNaN(start) || Number.isNaN(end)) return null;
  for (const w of windows()) {
    const wFrom = Date.parse(`${w.from}T00:00:00Z`);
    const wTo = Date.parse(`${w.to}T00:00:00Z`) + 24 * 3600 * 1000; // شامل آخر يوم
    if (start < wTo && end > wFrom) return w;
  }
  return null;
}

/// المسجد الحرام (الكعبة). يُستخدم لمورّدين بلا كود وجهة (LiteAPI): أي فندق
/// في السعودية على بُعد ≤ 25 كم يُعدّ في مكة (حدود المدينة + هامش، دون جدة ~70 كم).
const KAABA = { lat: 21.4225, lon: 39.8262 };
const MAKKAH_RADIUS_KM = 25;

export function isMakkahLocation(lat: number | null, lon: number | null, countryCode?: string | null): boolean {
  if (lat == null || lon == null || !Number.isFinite(lat) || !Number.isFinite(lon)) return false;
  if (countryCode && countryCode.toUpperCase() !== 'SA') return false;
  const toRad = (d: number) => (d * Math.PI) / 180;
  const dLat = toRad(lat - KAABA.lat);
  const dLon = toRad(lon - KAABA.lon);
  const a = Math.sin(dLat / 2) ** 2 + Math.cos(toRad(KAABA.lat)) * Math.cos(toRad(lat)) * Math.sin(dLon / 2) ** 2;
  const km = 6371 * 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
  return km <= MAKKAH_RADIUS_KM;
}

/// نفس hajjSeasonConflict لكن بموقع الفندق (أو اسم مدينته) بدل كود الوجهة.
export function hajjSeasonConflictAt(
  hotel: { lat: number | null; lon: number | null; countryCode?: string | null; city?: string | null },
  checkIn: string,
  checkOut: string,
): Window | null {
  const cityIsMakkah = /^(makkah|mecca|makka|مكة)/i.test(String(hotel.city ?? '').trim()) &&
    (!hotel.countryCode || hotel.countryCode.toUpperCase() === 'SA');
  if (!cityIsMakkah && !isMakkahLocation(hotel.lat, hotel.lon, hotel.countryCode)) return null;
  return hajjSeasonConflict(MAKKAH_DESTINATION_CODE, checkIn, checkOut);
}

export const HAJJ_SEASON_MESSAGE =
  'Hotels in Makkah cannot be booked on Flynoom for these dates. During the Hajj season, ' +
  'Saudi authorities restrict entry to Makkah to holders of a Hajj permit, and Hajj ' +
  'accommodation is arranged only through the official Nusuk Hajj platform. ' +
  'Please choose other dates or a hotel in Madinah.';