// supabase/functions/liteapi-search/index.ts
//
// البحث عن الفنادق عبر LiteAPI (Nuitee) — المرحلة 1 من الانتقال من HotelBeds.
//
// ⚠️ يُرجع **نفس شكل رد hotelbeds-search** (hotels[].rooms[].rates[] ...)، حتى
// تعمل الواجهة الحالية دون تغيير كبير. الفروق:
//   • rateKey = offerId من LiteAPI (يُستخدم لاحقًا في prebook).
//   • code = معرّف فندق LiteAPI (مثل "lp4b60c")، و supplier = "liteapi".
//   • العرض الواحد في LiteAPI يغطي كل الغرف المطلوبة معًا، فـ rate.rooms = عدد الغرف،
//     و price/priceUsd = سعر الإقامة لكل الغرف (الواجهة تقسم على rooms).
//   • cancellationPolicies.from بتوقيت GMT (+00:00)، لا بتوقيت الفندق.
//
// الأسعار: سعر الجملة (margin: 0) + عمولتنا (LITEAPI_MARKUP_PERCENT)، ولا تقل
// أبدًا عن السعر المعلن للفندق (SSP). الرسوم غير المشمولة = تُدفع في الفندق، وتُضاف إلى totalUsd (FTC).
//
// الطلب (POST) — الوجهة بإحدى طريقتين:
//   { "destinationCode": "QCA" }  ← من جدول hotelbeds_destinations (ما ترسله الواجهة)، يُحوَّل إلى placeId
//   أو { "cityName": "Dubai", "countryCode": "AE", ... }   أو   { "placeId": "...", ... }
//   + checkIn, checkOut (YYYY-MM-DD)
//   + roomsSpec: [{adults: 2, childAges: [5]}]   أو adults/children/rooms/childAges (الصيغة القديمة)
//   + maxHotels (افتراضيًا 200)

import { serve } from 'https://deno.land/std@0.168.0/http/server.ts';
import { adminClient, round2, toNum } from '../_shared/hotelbeds.ts';
import { isBlockedDestination, isBlockedUkraineLocation } from '../_shared/sanctions.ts';
import { lookupIpCountry } from '../_shared/fraud.ts';
import {
  amountOf,
  LITEAPI_API,
  LITEAPI_KEY,
  liteapi,
  liteAtHotelFees,
  liteCancellation,
  liteSellingPrice,
  remarksText,
  resolveDestinationCode,
} from '../_shared/liteapi.ts';

const DEFAULT_MAX_HOTELS = 200;

// صور LiteAPI (static.cupid.travel) لا تسمح بالتحميل من نطاق آخر على Flutter Web،
// فنمررها عبر نفس الوسيط المستخدم لصور HotelBeds.
const SUPABASE_URL = Deno.env.get('SUPABASE_URL') ?? '';
function proxify(url: unknown): string | null {
  const u = String(url ?? '');
  if (!u.startsWith('https://')) return null;
  return `${SUPABASE_URL}/functions/v1/hotelbeds-image-proxy?url=${encodeURIComponent(u)}`;
}
const OFFERS_PER_HOTEL = 15;
const FALLBACK_CHILD_AGE = 8;

// تخزين مؤقت للنتائج (نفس البحث خلال 10 دقائق) — يخفف نسبة البحث إلى الحجز
// (شرط LiteAPI لمجانية الخدمة) ويسرّع الرجوع من صفحة الفندق إلى النتائج.
const CACHE_MS = 10 * 60 * 1000;
const cache = new Map<string, { at: number; body: unknown }>();

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

interface RoomSpec {
  adults: number;
  childAges: number[];
}

/// نفس منطق hotelbeds-search: roomsSpec، أو مجاميع تُوزَّع على الغرف.
function buildRoomSpecs(body: any): RoomSpec[] {
  if (Array.isArray(body.roomsSpec) && body.roomsSpec.length > 0) {
    return body.roomsSpec.slice(0, 9).map((r: any) => ({
      adults: Math.min(Math.max(1, Number(r.adults) || 1), 8),
      childAges: (Array.isArray(r.childAges) ? r.childAges : [])
        .map((a: any) => Number(a))
        .filter((a: number) => Number.isInteger(a) && a >= 0 && a <= 17),
    }));
  }
  const rooms = Math.min(Math.max(1, Number(body.rooms) || 1), 9);
  const totalAdults = Math.max(rooms, Number(body.adults) || 2);
  const totalChildren = Math.max(0, Number(body.children) || 0);
  const ages: number[] = Array.isArray(body.childAges)
    ? body.childAges.map((a: any) => Number(a)).filter((a: number) => Number.isFinite(a))
    : [];
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

/// يحوّل عرضًا واحدًا (roomType في LiteAPI) إلى "غرفة" بسعر واحد بشكل HotelBeds.
async function mapOffer(rt: any, roomCount: number) {
  const rates: any[] = Array.isArray(rt?.rates) ? rt.rates : [];
  const first = rates[0] ?? {};
  const net = amountOf(rt?.offerRetailRate) ??
    round2(rates.reduce((s, r) => s + (amountOf(r?.retailRate?.total) ?? 0), 0));
  const suggested = amountOf(rt?.suggestedSellingPrice);
  const priceUsd = liteSellingPrice(net, suggested);
  const atHotel = await liteAtHotelFees(rates);
  const { policies, refundable } = liteCancellation(first, net);
  // اسم الغرفة: أسماء الغرف المختلفة في العرض (غرفتان مختلفتان = "A + B").
  const names = [...new Set(rates.map((r) => String(r?.name ?? '').trim()).filter(Boolean))];
  const boards = [...new Set(rates.map((r) => String(r?.boardName ?? '').trim()).filter(Boolean))];
  const remarks = [...new Set(rates.map((r) => remarksText(r?.remarks)).filter(Boolean))].join('\n') || null;

  return {
    code: String(rt?.offerId ?? '').slice(0, 24), // مفتاح عرض داخلي للواجهة
    name: names.join(' + ') || 'Room',
    rates: [{
      rateKey: String(rt?.offerId ?? ''),
      rateClass: refundable ? 'NOR' : 'NRF',
      rateType: 'RECHECK', // LiteAPI يتطلب prebook دائمًا قبل الحجز
      paymentType: 'AT_WEB',
      net,
      sellingRate: suggested,
      hotelMandatory: false,
      price: priceUsd, // العملة دائمًا USD في LiteAPI (currency: USD في الطلب)
      priceUsd, // ما يُسحب من بطاقة الزبون
      payAtHotelUsd: atHotel.totalUsd, // كل ما يُدفع في الفندق
      mandatoryFeesUsd: atHotel.mandatoryUsd, // رسوم الفندق الإلزامية (resort fee...)
      governmentTaxesUsd: atHotel.governmentUsd, // ضرائب حكومية تُدفع في الفندق
      totalUsd: round2(priceUsd + atHotel.totalUsd), // السعر الشامل (FTC)
      atHotelFees: atHotel.fees,
      allotment: null,
      boardCode: first.boardType ?? null,
      boardName: boards.join(' + ') || null,
      rooms: roomCount,
      adults: rates.reduce((s, r) => s + (Number(r?.adultCount) || 0), 0) || null,
      children: rates.reduce((s, r) => s + (Number(r?.childCount) || 0), 0),
      childrenAges: rates.flatMap((r) => (Array.isArray(r?.childrenAges) ? r.childrenAges : [])).join(',') || null,
      packaging: false,
      rateCommentsId: null,
      rateComments: remarks,
      cancellationPolicies: policies,
      taxes: null,
      promotions: [],
      offers: [],
      paymentTypes: rt?.paymentTypes ?? first?.paymentTypes ?? null,
    }],
  };
}

const ipNationalityMemo = new Map<string, { at: number; c: string }>();

async function visitorNationality(req: Request): Promise<string> {
  const fwd = req.headers.get('x-forwarded-for');
  const ip = (fwd ? fwd.split(',')[0].trim() : '') || req.headers.get('cf-connecting-ip') || '';
  if (!ip) return 'US';
  const hit = ipNationalityMemo.get(ip);
  if (hit && Date.now() - hit.at < 6 * 3600 * 1000) return hit.c;
  const country = await lookupIpCountry(ip);
  const c = country === 'IQ' ? 'IQ' : 'US';
  ipNationalityMemo.set(ip, { at: Date.now(), c });
  if (ipNationalityMemo.size > 5000) ipNationalityMemo.delete(ipNationalityMemo.keys().next().value!);
  return c;
}

serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders });
  if (!LITEAPI_KEY) return json({ error: 'LITEAPI_KEY is not configured' }, 500);

  try {
    const body = await req.json().catch(() => ({}));
    const checkIn = String(body.checkIn ?? body.checkin ?? '');
    const checkOut = String(body.checkOut ?? body.checkout ?? '');
    let cityName = String(body.cityName ?? '').trim();
    let countryCode = String(body.countryCode ?? '').trim().toUpperCase();
    let placeId = String(body.placeId ?? '').trim();
    const destinationCode = String(body.destinationCode ?? '').trim().toUpperCase();

    // كود وجهة من الواجهة → اسم ودولة، و placeId احتياطي.
    // البحث بالاسم أولًا: placeId لمدينة مثل مكة أعطى 12 فندقًا فقط مقابل 100 بالاسم
    // (منطقة المكان في الخريطة أضيق من المدينة). placeId يُستخدم فقط إن لم يجد الاسم شيئًا.
    let fallbackPlaceId = '';
    if (destinationCode && !placeId && !cityName) {
      const dest = await resolveDestinationCode(adminClient(), destinationCode);
      if (!dest) return json({ error: `Unknown destination ${destinationCode}` }, 400);
      cityName = dest.name;
      countryCode = dest.countryCode;
      fallbackPlaceId = dest.placeId ?? '';
      if (body.usePlaceId === true && fallbackPlaceId) placeId = fallbackPlaceId; // للمقارنة أثناء الاختبار
    }

    if (!/^\d{4}-\d{2}-\d{2}$/.test(checkIn) || !/^\d{4}-\d{2}-\d{2}$/.test(checkOut) || checkOut <= checkIn) {
      return json({ error: 'checkIn and checkOut (YYYY-MM-DD) are required' }, 400);
    }
    if (!placeId && (!cityName || !/^[A-Z]{2}$/.test(countryCode))) {
      return json({ error: 'placeId, or cityName + countryCode, is required' }, 400);
    }

    // عقوبات: دولة الوجهة محظورة → لا نتائج (نفس سلوك hotelbeds-search).
    if (countryCode && isBlockedDestination(countryCode, '')) {
      console.log(`SANCTIONS BLOCK country=${countryCode} city=${cityName}`);
      return json({ hotels: [], blocked: true, supplier: 'liteapi', search: { destinationCode, cityName, countryCode, checkIn, checkOut } });
    }

    const roomSpecs = buildRoomSpecs(body);
    const occupancies = roomSpecs.map((s) => ({ adults: s.adults, children: s.childAges }));
    const maxHotels = Math.min(500, Math.max(1, Number(body.maxHotels) || DEFAULT_MAX_HOTELS));

    // جنسية الضيف عند LiteAPI (بعض الأسعار تختلف حسبها): العراق إن كان الزائر يتصفح من العراق،
    // وإلا الولايات المتحدة. (الدفع نفسه يتحقق من بلد البطاقة في liteapi-book.)
    const guestNationality = await visitorNationality(req);

    const cacheKey = JSON.stringify([placeId, cityName.toLowerCase(), countryCode, checkIn, checkOut, occupancies, maxHotels, guestNationality]);
    const hit = cache.get(cacheKey);
    if (hit && Date.now() - hit.at < CACHE_MS) {
      return json({ ...(hit.body as Record<string, unknown>), cached: true });
    }

    const rates = (destination: Record<string, string>) =>
      liteapi(`${LITEAPI_API}/hotels/rates`, {
        method: 'POST',
        body: JSON.stringify({
          ...destination,
          checkin: checkIn,
          checkout: checkOut,
          occupancies,
          currency: 'USD',
          guestNationality, // US أو IQ
          margin: 0, // أسعار الجملة الصافية — بدونها تُضاف عمولة لوحة LiteAPI الافتراضية (15%)
          limit: maxHotels,
          maxRatesPerHotel: OFFERS_PER_HOTEL,
          timeout: 20,
        }),
      }, 40000);
    const isEmpty = (x: { status: number; data: any }) =>
      x.status === 204 || (x.status === 200 && !(x.data?.data?.length)) ||
      (x.status >= 400 && x.status < 500); // اسم لم يُعرف (مثل "Orlando, Florida")

    const started = Date.now();
    let r = await rates(placeId ? { placeId } : { cityName, countryCode });
    let searchedBy = placeId ? 'placeId' : 'cityName';
    if (!placeId && fallbackPlaceId && isEmpty(r)) {
      console.log(`LITE SEARCH ${cityName},${countryCode}: nothing by name (HTTP ${r.status}) → placeId ${fallbackPlaceId}`);
      r = await rates({ placeId: fallbackPlaceId });
      searchedBy = 'placeId';
    }
    const ms = Date.now() - started;

    if (r.status === 204 || (r.status === 200 && !(r.data?.data?.length))) {
      console.log(`LITE SEARCH ${cityName || placeId} ${checkIn}→${checkOut}: 0 hotels (${ms}ms)`);
      const empty = { hotels: [], supplier: 'liteapi', search: { cityName, countryCode, placeId, checkIn, checkOut, rooms: roomSpecs } };
      cache.set(cacheKey, { at: Date.now(), body: empty });
      return json(empty);
    }
    if (r.status !== 200) {
      console.log(`LITE SEARCH FAILED HTTP ${r.status}: ${JSON.stringify(r.data).slice(0, 400)}`);
      return json({ error: r.data?.error?.message ?? 'Hotel search failed', status: r.status }, r.status >= 500 ? 502 : r.status);
    }

    const info = new Map<string, any>();
    for (const h of r.data?.hotels ?? []) if (h?.id) info.set(String(h.id), h);

    let items: any[] = r.data.data;
    // أوكرانيا: نستبعد القرم ودونيتسك ولوغانسك (إحداثيات).
    items = items.filter((d) => {
      const h = info.get(String(d.hotelId)) ?? {};
      return !isBlockedUkraineLocation(toNum(h.latitude), toNum(h.longitude));
    });

    const stats = { hotels: 0, offers: 0, refundable: 0, payAtHotelFees: 0 };
    const hotels = (await Promise.all(items.map(async (d) => {
      const h = info.get(String(d.hotelId)) ?? {};
      const hc = String(h.country_code ?? countryCode ?? '').toUpperCase();
      if (hc && isBlockedDestination(hc, '')) return null;

      const rooms = await Promise.all((d.roomTypes ?? []).map((rt: any) => mapOffer(rt, roomSpecs.length)));
      const allRates = rooms.flatMap((x: any) => x.rates);
      if (allRates.length === 0) return null;
      stats.offers += allRates.length;
      stats.refundable += allRates.filter((x: any) => x.rateClass === 'NOR').length;
      stats.payAtHotelFees += allRates.filter((x: any) => x.payAtHotelUsd > 0).length;

      const cheapest = allRates.reduce((a: any, b: any) => (b.totalUsd < a.totalUsd ? b : a));
      const stars = toNum(h.stars);
      return {
        supplier: 'liteapi',
        code: String(d.hotelId),
        name: h.name ?? '',
        categoryCode: stars ? `${stars}EST` : null,
        categoryName: stars ? `${stars} STARS` : null,
        destinationCode: destinationCode || null,
        destinationName: h.city_name ?? cityName ?? null,
        zoneCode: null,
        zoneName: null,
        address: h.address ?? null,
        latitude: toNum(h.latitude),
        longitude: toNum(h.longitude),
        rating: toNum(h.rating), // تقييم الضيوف من 10
        reviewCount: toNum(h.review_count),
        currency: 'USD',
        minRate: Math.min(...allRates.map((x: any) => x.net)),
        maxRate: Math.max(...allRates.map((x: any) => x.net)),
        minPrice: Math.min(...allRates.map((x: any) => x.price)),
        minTotalUsd: cheapest.totalUsd,
        minPriceUsd: cheapest.priceUsd,
        minPayAtHotelUsd: cheapest.payAtHotelUsd,
        hasPayAtHotel: false, // كل أسعار LiteAPI تُدفع الآن (AT_WEB)
        imageUrl: proxify(h.main_photo ?? h.thumbnail),
        rooms: rooms.sort((a: any, b: any) => a.rates[0].totalUsd - b.rates[0].totalUsd),
      };
    }))).filter(Boolean);

    stats.hotels = hotels.length;
    console.log(
      `LITE SEARCH ${cityName || placeId},${countryCode} ${checkIn}→${checkOut} occ=${JSON.stringify(occupancies)} ` +
        `hotels=${stats.hotels} offers=${stats.offers} refundable=${stats.refundable} ` +
        `withHotelFees=${stats.payAtHotelFees} ${ms}ms`,
    );

    const result = {
      hotels,
      supplier: 'liteapi',
      search: {
        destinationCode: destinationCode || null,
        searchedBy,
        cityName,
        countryCode,
        placeId: placeId || null,
        checkIn,
        checkOut,
        rooms: roomSpecs,
        searchedAt: new Date().toISOString(),
      },
      stats,
    };
    cache.set(cacheKey, { at: Date.now(), body: result });
    if (cache.size > 200) cache.delete(cache.keys().next().value!);
    return json(result);
  } catch (e) {
    const isTimeout = e instanceof DOMException && e.name === 'AbortError';
    console.log(isTimeout ? 'LITE SEARCH TIMEOUT' : `LITE SEARCH ERROR ${String(e)}`);
    return json({ error: isTimeout ? 'Hotel search timeout' : String(e) }, isTimeout ? 504 : 500);
  }
});
