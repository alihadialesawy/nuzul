// supabase/functions/liteapi-hotel-info/index.ts
//
// المرحلة 3 من الانتقال إلى LiteAPI: معلومات الفندق لصفحة الفندق
// (GET /data/hotel) — بنفس شكل رد hotelbeds-hotel-info، مع حقول إضافية:
//   images[]       معرض الصور كاملًا (عبر hotelbeds-image-proxy ليعمل على الويب)
//   description    وصف الفندق (نص عادي) بلغة الزائر إن توفرت
//   importantInfo  معلومات مهمة من الفندق (الهوية، البطاقة عند الوصول ...)
//   facilities[]   المرافق بلغة الزائر
//
// ⚠️ نُرجع فقط ما يوجد فعلًا في بيانات الفندق. أي حقل غير متوفر = null أو قائمة فارغة.
//
// الطلب:  POST { code: "lp1faeef", language: "ar" }
// الرد:   { ok, address, checkIn, checkOut, minAge, pointsOfInterest[], terminals[],
//           images[], description, importantInfo, facilities[], starRating, rating, reviewCount }

import { serve } from 'https://deno.land/std@0.168.0/http/server.ts';
import { corsHeaders, fail, ok } from '../_shared/hotelbeds.ts';
import { LITEAPI_API, LITEAPI_KEY, liteapi, remarksText } from '../_shared/liteapi.ts';

const CACHE_MS = 6 * 3600 * 1000;
const cache = new Map<string, { at: number; data: Record<string, unknown> }>();

const LANGS = new Set(['en', 'ar', 'es', 'tr', 'id', 'hi', 'ur', 'fr', 'bn']);
const MAX_IMAGES = 40;
const MAX_FACILITIES = 40;

const SUPABASE_URL = Deno.env.get('SUPABASE_URL') ?? '';
function proxify(url: unknown): string | null {
  const u = String(url ?? '').trim();
  if (!u.startsWith('https://')) return null;
  return `${SUPABASE_URL}/functions/v1/hotelbeds-image-proxy?url=${encodeURIComponent(u)}`;
}

/// "04:00 PM" / "4 PM" / "16:00" / "12:00:00" → "16:00". غير ذلك → null.
function hhmm(v: unknown): string | null {
  const m = /^(\d{1,2})(?::(\d{2}))?(?::\d{2})?\s*([AaPp][Mm])?/.exec(String(v ?? '').trim());
  if (!m) return null;
  let h = Number(m[1]);
  const min = m[2] ?? '00';
  const ap = m[3]?.toUpperCase();
  if (ap === 'PM' && h < 12) h += 12;
  if (ap === 'AM' && h === 12) h = 0;
  if (h > 23 || Number(min) > 59) return null;
  return `${String(h).padStart(2, '0')}:${min}`;
}

function text(v: unknown): string | null {
  const t = remarksText(String(v ?? '').replace(/<\/p>\s*<p>/gi, '\n').replace(/<\/?(li|ul|ol)[^>]*>/gi, '\n'));
  return t && t.length > 1 ? t : null;
}

function parse(h: any): Record<string, unknown> {
  // نص العنوان يحوي المدينة أحيانًا ("Palm Jumeirah, Dubai") — نحذف الأجزاء المكررة.
  const seenParts = new Set<string>();
  const address = [h?.address, h?.city, h?.zip, String(h?.country ?? '').toUpperCase()]
    .flatMap((s) => String(s ?? '').split(','))
    .map((s) => s.trim())
    .filter((s) => s && !/^0+$/.test(s))
    .filter((s) => !seenParts.has(s.toLowerCase()) && !!seenParts.add(s.toLowerCase()))
    .join(', ') || null;

  const times = h?.checkinCheckoutTimes ?? {};
  const checkIn = hhmm(times.checkin_start ?? times.checkinStart ?? times.checkin);
  const checkOut = hhmm(times.checkout);

  // الصورة الافتراضية أولًا، ثم حسب order. urlHd إن وُجد (أوضح في المعرض).
  const imgs: any[] = Array.isArray(h?.hotelImages) ? h.hotelImages : [];
  const seen = new Set<string>();
  const images = imgs
    .slice()
    .sort((a, b) => (b?.defaultImage === true ? 1 : 0) - (a?.defaultImage === true ? 1 : 0) ||
      (Number(a?.order) || 999) - (Number(b?.order) || 999))
    .map((i) => String(i?.urlHd || i?.url || '').trim())
    .filter((u) => u && !seen.has(u) && seen.add(u))
    .slice(0, MAX_IMAGES)
    .map(proxify)
    .filter(Boolean);
  if (images.length === 0 && h?.main_photo) {
    const p = proxify(h.main_photo);
    if (p) images.push(p);
  }

  const facilityNames: string[] = [
    ...(Array.isArray(h?.hotelFacilities) ? h.hotelFacilities : []),
    ...(Array.isArray(h?.facilities) ? h.facilities.map((f: any) => f?.name) : []),
  ]
    .map((f) => String(f ?? '').trim())
    .filter(Boolean);
  const facilities = [...new Map(facilityNames.map((f) => [f.toLowerCase(), f])).values()].slice(0, MAX_FACILITIES);

  const num = (v: unknown) => (Number.isFinite(Number(v)) && v !== null && v !== '' ? Number(v) : null);

  return {
    address,
    checkIn,
    checkOut,
    minAge: null, // LiteAPI لا يعطي حقلًا مستقلًا؛ يظهر أحيانًا داخل importantInfo
    pointsOfInterest: [],
    terminals: [],
    images,
    description: text(h?.hotelDescription),
    importantInfo: text(h?.hotelImportantInformation),
    facilities,
    starRating: num(h?.starRating),
    rating: num(h?.rating),
    reviewCount: num(h?.reviewCount),
  };
}

serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders });
  if (!LITEAPI_KEY) return fail('config', 'LITEAPI_KEY is not configured');
  try {
    const body = await req.json().catch(() => ({}));
    const code = String(body?.code ?? '').replace(/^hb_/, '').trim();
    if (!/^[A-Za-z0-9_-]{2,40}$/.test(code)) return fail('bad_request', 'Invalid hotel code.');
    const lang = LANGS.has(String(body?.language ?? '')) ? String(body.language) : 'en';

    const key = `${code}|${lang}`;
    const hit = cache.get(key);
    if (hit && Date.now() - hit.at < CACHE_MS) return ok({ ...hit.data, cached: true });

    const get = (language: string) =>
      liteapi(`${LITEAPI_API}/data/hotel?${new URLSearchParams({ hotelId: code, language })}`, { method: 'GET' }, 12000);

    let r = await get(lang);
    let h = r.data?.data;
    // لغة غير متوفرة لهذا الفندق → الإنجليزية.
    if ((r.status !== 200 || !h) && lang !== 'en') {
      r = await get('en');
      h = r.data?.data;
    }
    if (r.status !== 200 || !h) {
      console.log(`LITE HOTEL INFO ${code}/${lang}: HTTP ${r.status} ${JSON.stringify(r.data).slice(0, 200)}`);
      return fail(r.status === 404 ? 'not_found' : 'supplier_error', 'Hotel information is not available right now.');
    }

    const data = parse(h);
    cache.set(key, { at: Date.now(), data });
    if (cache.size > 500) cache.delete(cache.keys().next().value!);
    console.log(
      `LITE HOTEL INFO ${code}/${lang}: in=${data.checkIn ?? '-'} out=${data.checkOut ?? '-'} ` +
        `images=${(data.images as unknown[]).length} facilities=${(data.facilities as unknown[]).length} ` +
        `desc=${data.description ? (data.description as string).length : 0}`,
    );
    return ok(data);
  } catch (e) {
    const isTimeout = e instanceof DOMException && e.name === 'AbortError';
    console.log('liteapi-hotel-info error', isTimeout ? 'timeout' : String(e));
    return fail('server_error', 'Hotel information is not available right now.');
  }
});