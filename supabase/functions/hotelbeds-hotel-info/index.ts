// supabase/functions/hotelbeds-hotel-info/index.ts
//
// معلومات الفندق الحقيقية من HotelBeds Content API (hotels/{code}/details)
// لصفحة الفندق: العنوان، وأوقات الوصول والمغادرة، والحد الأدنى للعمر،
// والمعالم القريبة، وأقرب المطارات/المحطات.
//
// ⚠️ نُرجع فقط ما يوجد فعلًا في بيانات الفندق. أي حقل غير متوفر يُرجع null
// أو قائمة فارغة، والواجهة تخفيه (لا قيم افتراضية ثابتة — ادعاء مضلل).
//
// الطلب:  POST { code: "135812" }   (كود HotelBeds بدون البادئة hb_)
// الرد:   { ok, address, checkIn, checkOut, minAge, pointsOfInterest[], terminals[] }

import { serve } from 'https://deno.land/std@0.168.0/http/server.ts';
import {
  corsHeaders,
  fail,
  fetchWithTimeout,
  HOTELBEDS_BASE_URL,
  hotelbedsHeaders,
  ok,
} from '../_shared/hotelbeds.ts';

const CACHE_MS = 6 * 3600 * 1000;
const cache = new Map<string, { at: number; data: Record<string, unknown> }>();

const TIME_RE = /^(\d{1,2}):(\d{2})/;

/// "15:00:00" → "15:00". غير ذلك → null.
function hhmm(v: unknown): string | null {
  const m = TIME_RE.exec(String(v ?? '').trim());
  if (!m) return null;
  const h = Number(m[1]);
  if (h > 23) return null;
  return `${String(h).padStart(2, '0')}:${m[2]}`;
}

function desc(f: any): string {
  return String(f?.description?.content ?? '').toLowerCase();
}

function parse(h: any): Record<string, unknown> {
  // ───── العنوان ─────
  const address = [h?.address?.content, h?.city?.content, h?.stateCode, h?.postalCode, h?.countryCode]
    .filter((s) => typeof s === 'string' && s.trim())
    // نص العنوان عند HotelBeds يحوي أحيانًا أجزاء "0" فارغة ("No:17, 0") — نحذفها.
    .flatMap((s: string) => s.split(','))
    .map((s: string) => s.trim())
    .filter((s: string) => s.length > 0)
    .filter((s: string) => !/^0+$/.test(s)) // رموز بريدية "0" في مدن بلا رموز (مثل دبي)
    .join(', ') || null;

  // ───── السياسات من facilities ─────
  const facilities: any[] = Array.isArray(h?.facilities) ? h.facilities : [];
  let checkIn: string | null = null;
  let checkOut: string | null = null;
  let minAge: number | null = null;

  for (const f of facilities) {
    const d = desc(f);
    if (!checkIn && /check-?\s?in/.test(d) && !/check-?\s?out/.test(d) && !/age/.test(d)) {
      checkIn = hhmm(f?.timeFrom) ?? hhmm(f?.timeTo);
    }
    if (!checkOut && /check-?\s?out/.test(d)) {
      checkOut = hhmm(f?.timeTo) ?? hhmm(f?.timeFrom);
    }
    if (minAge == null && /age/.test(d) && /check-?\s?in|minimum|min\./.test(d)) {
      const n = Number(f?.number);
      if (Number.isFinite(n) && n >= 12 && n <= 30) minAge = n;
    }
  }

  // ───── المعالم القريبة (المسافة بالأمتار) ─────
  const pois = (Array.isArray(h?.interestPoints) ? h.interestPoints : [])
    .map((p: any) => ({ name: String(p?.poiName ?? '').trim(), distanceM: Number(p?.distance) }))
    .filter((p: any) => p.name && Number.isFinite(p.distanceM) && p.distanceM >= 0)
    .sort((a: any, b: any) => a.distanceM - b.distanceM)
    // إزالة التكرار بالاسم
    .filter((p: any, i: number, arr: any[]) => arr.findIndex((q) => q.name.toLowerCase() === p.name.toLowerCase()) === i)
    .slice(0, 8);

  // ───── أقرب المطارات/المحطات (المسافة بالكيلومتر) ─────
  const terminals = (Array.isArray(h?.terminals) ? h.terminals : [])
    .map((t: any) => ({
      code: String(t?.terminalCode ?? '').trim(),
      name: String(t?.name?.content ?? t?.description?.content ?? '').trim() || null,
      distanceKm: Number(t?.distance),
    }))
    .filter((t: any) => t.code && Number.isFinite(t.distanceKm) && t.distanceKm >= 0)
    .sort((a: any, b: any) => a.distanceKm - b.distanceKm)
    .slice(0, 3);

  return { address, checkIn, checkOut, minAge, pointsOfInterest: pois, terminals };
}

serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders });
  try {
    const body = await req.json().catch(() => ({}));
    const code = String(body?.code ?? '').replace(/^hb_/, '').trim();
    if (!/^\d{1,10}$/.test(code)) return fail('bad_request', 'Invalid hotel code.');

    const hit = cache.get(code);
    if (hit && Date.now() - hit.at < CACHE_MS) return ok({ ...hit.data, cached: true });

    const res = await fetchWithTimeout(
      `${HOTELBEDS_BASE_URL}/hotel-content-api/1.0/hotels/${encodeURIComponent(code)}/details` +
        `?language=ENG&useSecondaryLanguage=false`,
      { method: 'GET', headers: await hotelbedsHeaders() },
      10000,
    );
    if (!res.ok) {
      console.log(`HOTEL INFO ${code}: HTTP ${res.status}`);
      return fail('supplier_error', 'Hotel information is not available right now.');
    }
    const h = (await res.json())?.hotel;
    if (!h) return fail('not_found', 'Hotel not found.');

    const data = parse(h);
    cache.set(code, { at: Date.now(), data });
    console.log(
      `HOTEL INFO ${code}: in=${data.checkIn ?? '-'} out=${data.checkOut ?? '-'} age=${data.minAge ?? '-'} ` +
        `pois=${(data.pointsOfInterest as unknown[]).length} terminals=${(data.terminals as unknown[]).length}`,
    );
    return ok(data);
  } catch (e) {
    console.log('hotelbeds-hotel-info error', String(e));
    return fail('server_error', 'Hotel information is not available right now.');
  }
});