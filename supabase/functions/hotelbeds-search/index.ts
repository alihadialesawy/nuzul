// supabase/functions/hotelbeds-search/index.ts
//
// Edge Function آمنة تستدعي HotelBeds Booking API (Availability) من السيرفر.
// مفتاح الـ API والـ Secret يُقرآن من Supabase Secrets ولا يصلان للتطبيق.
//
// النسخة 2 (جاهزة لمسار الـ Certification):
// - تُرجع لكل فندق الغرف والأسعار كاملة: rateKey, rateType (BOOKABLE/RECHECK),
//   paymentType (AT_WEB/AT_HOTEL), boardName, cancellationPolicies,
//   rateCommentsId, hotelMandatory, sellingRate, taxes, promotions, offers.
//   ← هذا يسمح لصفحة التفاصيل بعرض الغرف بدون استدعاء Availability مرة ثانية
//     (شرط من HotelBeds: Availability → CheckRate (RECHECK فقط) → Booking).
// - كل الغرف تُطلب في استدعاء واحد (occupancies متعددة).
// - أعمار الأطفال تُرسل فعليًا (paxes type=CH).
// - Accept-Encoding: gzip (شرط من HotelBeds).
// - sourceMarket (افتراضيًا US).
// - السعر المعروض يحترم hotelMandatory (لا نبيع بغير sellingRate الإلزامي).
// - Log إحصائي يوضّح هل أسعار AT_HOTEL (الدفع في الفندق) متاحة لحسابنا.
//
// الصور: كما في النسخة السابقة، طلب Content API واحد لكل الأكواد،
// وكل رابط يمر عبر hotelbeds-image-proxy ليعمل على Flutter Web.

import { serve } from 'https://deno.land/std@0.168.0/http/server.ts';
import { atHotelFees, sellingPrice, toUsd } from '../_shared/hotelbeds.ts';

const HOTELBEDS_API_KEY = Deno.env.get('HOTELBEDS_API_KEY')!;
const HOTELBEDS_SECRET = Deno.env.get('HOTELBEDS_SECRET')!;
// بيئة الاختبار. عند الإنتاج: https://api.hotelbeds.com
const HOTELBEDS_BASE_URL = 'https://api.test.hotelbeds.com';

const SUPABASE_URL = Deno.env.get('SUPABASE_URL')!;

// نسبة الربح وتحويل العملة يأتيان من _shared/hotelbeds.ts — نفس الدوال
// التي يستخدمها hotelbeds-prepare عند الدفع، فيتطابق السعر المعروض مع المسحوب.

const DEFAULT_SOURCE_MARKET = 'US';

// أقصى عدد فنادق في الرد (حد HotelBeds الأعلى 2000).
const DEFAULT_MAX_HOTELS = 200;

// مهلة استدعاء Availability.
const AVAILABILITY_TIMEOUT_MS = 30000;

const IMAGE_PROXY_PARAM = 'url';
const HOTELBEDS_PHOTO_BASE = 'https://photos.hotelbeds.com/giata/bigger/';
const MAX_HOTELS_WITH_IMAGES = 100;
const IMAGES_TIMEOUT_MS = 6000;

// عمر افتراضي للطفل إن لم يرسل التطبيق الأعمار (مؤقت فقط —
// قبل الـ Certification يجب أن تجمع الواجهة عمر كل طفل).
const FALLBACK_CHILD_AGE = 8;

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

function json(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, 'Content-Type': 'application/json' },
  });
}

/// X-Signature = SHA256(apiKey + secret + الوقت بالثواني) بصيغة hex.
async function computeSignature(): Promise<string> {
  const timestamp = Math.floor(Date.now() / 1000);
  const raw = `${HOTELBEDS_API_KEY}${HOTELBEDS_SECRET}${timestamp}`;
  const data = new TextEncoder().encode(raw);
  const hashBuffer = await crypto.subtle.digest('SHA-256', data);
  return Array.from(new Uint8Array(hashBuffer))
    .map((b) => b.toString(16).padStart(2, '0'))
    .join('');
}

async function hotelbedsHeaders(): Promise<Record<string, string>> {
  return {
    'Api-key': HOTELBEDS_API_KEY,
    'X-Signature': await computeSignature(),
    'Accept': 'application/json',
    'Accept-Encoding': 'gzip', // شرط HotelBeds. Deno يفك الضغط تلقائيًا.
  };
}

function round2(n: number): number {
  return Math.round(n * 100) / 100;
}

function toNum(v: unknown): number | null {
  if (v === null || v === undefined || v === '') return null;
  const n = Number(v);
  return Number.isFinite(n) ? n : null;
}

// ─────────────────────────── الغرف والإشغال ───────────────────────────

interface RoomSpec {
  adults: number;
  childAges: number[];
}

/// يبني قائمة الغرف من الطلب:
/// - الصيغة الجديدة: roomsSpec = [{adults: 2, childAges: [5, 9]}, ...] (لكل غرفة).
/// - الصيغة القديمة (توافق مع التطبيق الحالي): adults/children/rooms
///   كمجاميع، تُوزَّع على الغرف بالتساوي، و childAges اختيارية.
function buildRoomSpecs(body: any): RoomSpec[] {
  if (Array.isArray(body.roomsSpec) && body.roomsSpec.length > 0) {
    return body.roomsSpec.map((r: any) => ({
      adults: Math.max(1, Number(r.adults) || 1),
      childAges: (Array.isArray(r.childAges) ? r.childAges : [])
        .map((a: any) => Number(a))
        .filter((a: number) => Number.isFinite(a) && a >= 0 && a <= 17),
    }));
  }

  const rooms = Math.max(1, Number(body.rooms) || 1);
  const totalAdults = Math.max(rooms, Number(body.adults) || 2);
  const totalChildren = Math.max(0, Number(body.children) || 0);
  const ages: number[] = Array.isArray(body.childAges)
    ? body.childAges.map((a: any) => Number(a)).filter((a: number) => Number.isFinite(a))
    : [];

  if (totalChildren > 0 && ages.length < totalChildren) {
    console.log(`⚠️ childAges missing (${ages.length}/${totalChildren}) → fallback age ${FALLBACK_CHILD_AGE}`);
  }

  const specs: RoomSpec[] = [];
  let adultsLeft = totalAdults;
  let childIndex = 0;
  for (let i = 0; i < rooms; i++) {
    const roomsLeft = rooms - i;
    const a = Math.ceil(adultsLeft / roomsLeft);
    adultsLeft -= a;
    const cCount = Math.ceil((totalChildren - childIndex) / roomsLeft);
    const childAges: number[] = [];
    for (let c = 0; c < cCount; c++) {
      childAges.push(ages[childIndex] ?? FALLBACK_CHILD_AGE);
      childIndex++;
    }
    specs.push({ adults: a, childAges });
  }
  return specs;
}

/// يجمع الغرف المتطابقة في occupancy واحدة (rooms = العدد)،
/// وكل الغرف تُرسل في استدعاء Availability واحد.
function buildOccupancies(specs: RoomSpec[]) {
  const groups = new Map<string, { spec: RoomSpec; count: number }>();
  for (const s of specs) {
    const key = `${s.adults}|${[...s.childAges].sort((x, y) => x - y).join(',')}`;
    const g = groups.get(key);
    if (g) g.count++;
    else groups.set(key, { spec: s, count: 1 });
  }
  return [...groups.values()].map(({ spec, count }) => {
    const occ: any = {
      rooms: count,
      adults: spec.adults,
      children: spec.childAges.length,
    };
    if (spec.childAges.length > 0) {
      occ.paxes = spec.childAges.map((age) => ({ type: 'CH', age }));
    }
    return occ;
  });
}

// ─────────────────────────── الأسعار ───────────────────────────

async function mapRate(r: any, currency: string) {
  const net = toNum(r.net) ?? 0;
  const sellingRate = toNum(r.sellingRate);
  const hotelMandatory = r.hotelMandatory === true;
  // سعر البيع بعملة HotelBeds ثم بالدولار (نفس معادلة الدفع بالضبط).
  const price = sellingPrice(net, sellingRate, hotelMandatory);
  const priceUsd = await toUsd(price, currency);
  // الرسوم الإلزامية التي تُدفع في الفندق (resort fee، ضرائب المدينة...).
  const atHotel = await atHotelFees(r);

  return {
    rateKey: r.rateKey,
    rateClass: r.rateClass ?? null, // NOR عادي / NRF غير مسترد
    rateType: r.rateType, // BOOKABLE أو RECHECK
    paymentType: r.paymentType ?? 'AT_WEB', // AT_WEB أو AT_HOTEL
    net,
    sellingRate,
    hotelMandatory,
    price, // بعملة HotelBeds
    priceUsd, // ما يُدفع الآن (USD) — هذا ما يُسحب من البطاقة
    payAtHotelUsd: atHotel.totalUsd, // يُدفع في الفندق (تقديري بالدولار)
    totalUsd: round2(priceUsd + atHotel.totalUsd), // السعر الشامل (FTC)
    atHotelFees: atHotel.fees,
    allotment: r.allotment ?? null,
    boardCode: r.boardCode ?? null,
    boardName: r.boardName ?? null,
    rooms: r.rooms ?? 1,
    adults: r.adults ?? null,
    children: r.children ?? 0,
    childrenAges: r.childrenAges ?? null,
    packaging: r.packaging === true,
    rateCommentsId: r.rateCommentsId ?? null,
    rateComments: r.rateComments ?? null,
    // from = تاريخ/وقت بتوقيت الوجهة (مع الـ offset) — يُعرض كما هو.
    cancellationPolicies: (r.cancellationPolicies ?? []).map((p: any) => ({
      amount: toNum(p.amount) ?? 0,
      from: p.from,
    })),
    taxes: r.taxes
      ? {
          allIncluded: r.taxes.allIncluded === true,
          taxes: (r.taxes.taxes ?? []).map((t: any) => ({
            included: t.included === true,
            amount: toNum(t.amount),
            currency: t.currency ?? null,
            clientAmount: toNum(t.clientAmount),
            clientCurrency: t.clientCurrency ?? null,
            type: t.type ?? null,
          })),
        }
      : null,
    promotions: (r.promotions ?? []).map((p: any) => ({
      code: p.code ?? null,
      name: p.name ?? null,
      remark: p.remark ?? null,
    })),
    offers: (r.offers ?? []).map((o: any) => ({
      code: o.code ?? null,
      name: o.name ?? null,
      amount: toNum(o.amount),
    })),
  };
}

// ─────────────────────────── الصور ───────────────────────────

function proxify(originalUrl: string): string {
  return `${SUPABASE_URL}/functions/v1/hotelbeds-image-proxy?${IMAGE_PROXY_PARAM}=${encodeURIComponent(originalUrl)}`;
}

function pickMainImagePath(images: any[] | undefined): string | null {
  if (!images || images.length === 0) return null;
  const sorted = [...images].sort(
    (a, b) => (a.visualOrder ?? a.order ?? 999) - (b.visualOrder ?? b.order ?? 999),
  );
  const general = sorted.find((img) => img.imageTypeCode === 'GEN');
  return (general ?? sorted[0])?.path ?? null;
}

async function fetchMainImages(codes: number[]): Promise<Map<number, string>> {
  const result = new Map<number, string>();
  if (codes.length === 0) return result;

  const controller = new AbortController();
  const timer = setTimeout(() => controller.abort(), IMAGES_TIMEOUT_MS);

  try {
    const params = new URLSearchParams({
      codes: codes.join(','),
      fields: 'code,images',
      language: 'ENG',
      from: '1',
      to: String(codes.length),
      useSecondaryLanguage: 'false',
    });

    const res = await fetch(
      `${HOTELBEDS_BASE_URL}/hotel-content-api/1.0/hotels?${params.toString()}`,
      { method: 'GET', headers: await hotelbedsHeaders(), signal: controller.signal },
    );

    if (!res.ok) {
      console.log('Content API images request failed:', res.status);
      return result;
    }

    const data = await res.json();
    for (const h of data?.hotels ?? []) {
      const path = pickMainImagePath(h.images);
      if (h.code != null && path) {
        result.set(Number(h.code), proxify(`${HOTELBEDS_PHOTO_BASE}${path}`));
      }
    }
    console.log(`Images: ${result.size}/${codes.length} hotels`);
  } catch (e) {
    console.log('Content API images error:', String(e));
  } finally {
    clearTimeout(timer);
  }
  return result;
}

// ─────────────────────────── المعالج ───────────────────────────

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  try {
    const body = await req.json();
    const { destinationCode, checkIn, checkOut } = body;

    if (!destinationCode || !checkIn || !checkOut) {
      return json({ error: 'destinationCode, checkIn, and checkOut are required' }, 400);
    }

    const roomSpecs = buildRoomSpecs(body);
    const occupancies = buildOccupancies(roomSpecs);

    const sourceMarket: string =
      typeof body.sourceMarket === 'string' && body.sourceMarket.length === 2
        ? body.sourceMarket.toUpperCase()
        : DEFAULT_SOURCE_MARKET;

    const maxHotels = Math.min(2000, Math.max(1, Number(body.maxHotels) || DEFAULT_MAX_HOTELS));

    const filter: Record<string, unknown> = { maxHotels };
    // paymentType اختياري: AT_WEB | AT_HOTEL | BOTH. بدونه ترجع كل الأنواع.
    if (['AT_WEB', 'AT_HOTEL', 'BOTH'].includes(body.paymentType)) {
      filter.paymentType = body.paymentType;
    }

    const availabilityRQ = {
      stay: { checkIn, checkOut },
      occupancies,
      destination: { code: destinationCode },
      sourceMarket,
      filter,
    };

    const controller = new AbortController();
    const timer = setTimeout(() => controller.abort(), AVAILABILITY_TIMEOUT_MS);

    let response: Response;
    try {
      response = await fetch(`${HOTELBEDS_BASE_URL}/hotel-api/1.0/hotels`, {
        method: 'POST',
        headers: { ...(await hotelbedsHeaders()), 'Content-Type': 'application/json' },
        body: JSON.stringify(availabilityRQ),
        signal: controller.signal,
      });
    } finally {
      clearTimeout(timer);
    }

    const data = await response.json();

    if (!response.ok) {
      return json(
        { error: data?.error?.message ?? 'HotelBeds request failed', details: data },
        response.status,
      );
    }

    const rawHotels: any[] = data?.hotels?.hotels ?? [];

    const codesForImages = rawHotels
      .slice(0, MAX_HOTELS_WITH_IMAGES)
      .map((h) => Number(h.code))
      .filter((c) => !Number.isNaN(c));
    const images = await fetchMainImages(codesForImages);

    // إحصائيات للتشخيص (تظهر في Logs الخاصة بالـ Function).
    const stats = { BOOKABLE: 0, RECHECK: 0, AT_WEB: 0, AT_HOTEL: 0, mandatory: 0 };

    const hotels = await Promise.all(rawHotels.map(async (h: any) => {
      const currency = String(h.currency ?? 'EUR').toUpperCase();
      const rooms = await Promise.all((h.rooms ?? []).map(async (room: any) => {
        const rates = await Promise.all((room.rates ?? []).map(async (r: any) => {
          const m = await mapRate(r, currency);
          if (m.rateType === 'RECHECK') stats.RECHECK++;
          else stats.BOOKABLE++;
          if (m.paymentType === 'AT_HOTEL') stats.AT_HOTEL++;
          else stats.AT_WEB++;
          if (m.hotelMandatory) stats.mandatory++;
          return m;
        }));
        return { code: room.code, name: room.name, rates };
      }));

      const allRates: any[] = rooms.flatMap((r: any) => r.rates);
      const minPrice = allRates.length > 0
        ? Math.min(...allRates.map((x) => x.price))
        : toNum(h.minRate) ?? 0;
      // السعر الرئيسي في القوائم: أقل سعر شامل بالدولار (يشمل رسوم الفندق الإلزامية).
      const cheapest = allRates.length > 0
        ? allRates.reduce((a, b) => (b.totalUsd < a.totalUsd ? b : a))
        : null;
      const hasPayAtHotel = allRates.some((x) => x.paymentType === 'AT_HOTEL');

      return {
        code: h.code,
        name: h.name,
        categoryCode: h.categoryCode ?? null,
        categoryName: h.categoryName ?? null,
        destinationCode: h.destinationCode ?? null,
        destinationName: h.destinationName ?? null,
        zoneCode: h.zoneCode ?? null,
        zoneName: h.zoneName ?? null,
        latitude: toNum(h.latitude),
        longitude: toNum(h.longitude),
        currency,
        minRate: toNum(h.minRate) ?? 0, // net من HotelBeds
        maxRate: toNum(h.maxRate) ?? 0, // net من HotelBeds
        minPrice: round2(minPrice), // أقل سعر بيع بعملة HotelBeds
        minTotalUsd: cheapest?.totalUsd ?? null, // أقل سعر شامل بالدولار
        minPriceUsd: cheapest?.priceUsd ?? null, // ما يُدفع الآن لنفس السعر
        minPayAtHotelUsd: cheapest?.payAtHotelUsd ?? null,
        hasPayAtHotel,
        imageUrl: images.get(Number(h.code)) ?? null,
        rooms,
      };
    }));

    console.log(
      `Availability ${destinationCode} ${checkIn}→${checkOut} market=${sourceMarket} ` +
        `occ=${JSON.stringify(occupancies)} hotels=${hotels.length} rates: ` +
        `BOOKABLE=${stats.BOOKABLE} RECHECK=${stats.RECHECK} AT_WEB=${stats.AT_WEB} ` +
        `AT_HOTEL=${stats.AT_HOTEL} hotelMandatory=${stats.mandatory}`,
    );

    return json({
      hotels,
      search: {
        destinationCode,
        checkIn,
        checkOut,
        sourceMarket,
        rooms: roomSpecs,
        searchedAt: new Date().toISOString(),
      },
      stats,
    });
  } catch (e) {
    const isTimeout = e instanceof DOMException && e.name === 'AbortError';
    return json(
      { error: isTimeout ? 'HotelBeds availability timeout' : String(e) },
      isTimeout ? 504 : 500,
    );
  }
});