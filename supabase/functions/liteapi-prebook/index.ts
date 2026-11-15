// supabase/functions/liteapi-prebook/index.ts
//
// المرحلة 2 من الانتقال إلى LiteAPI: التحقق من السعر (prebook) — تجريبي فقط.
// لا يحجز شيئًا ولا يسحب مالًا: يثبّت السعر مؤقتًا ويُرجع prebookId والسعر النهائي
// وسياسة الإلغاء والرسوم، قبل أن نطلب الدفع من الزبون.
//
// الهدف الأهم الآن: نعرف هل الرسوم "غير المشمولة" (included=false) تُدفع في الفندق
// أم تُضاف عند الحجز، ونعرف شكل الرد بالضبط (قسم debug + raw).
//
// السر المطلوب: LITEAPI_KEY.
//
// الطلب (POST):
//   أ) { "offerId": "..." }                       ← من نتيجة liteapi-search
//   ب) أو بحث ثم تحقق تلقائي من أول فندق يطابق الاسم:
//      { "cityName": "Detroit", "countryCode": "US", "checkin": "2026-12-14",
//        "checkout": "2026-12-17", "adults": 2, "hotelName": "Hollywood" }

import { serve } from 'https://deno.land/std@0.168.0/http/server.ts';

const LITEAPI_KEY = Deno.env.get('LITEAPI_KEY') ?? '';
const API = 'https://api.liteapi.travel/v3.0';
const BOOK = 'https://book.liteapi.travel/v3.0';

const cors = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

function json(body: Record<string, unknown>): Response {
  return new Response(JSON.stringify(body), { headers: { ...cors, 'Content-Type': 'application/json' } });
}

async function call(url: string, init: RequestInit = {}, timeoutMs = 30000): Promise<{ status: number; data: any }> {
  const ctrl = new AbortController();
  const t = setTimeout(() => ctrl.abort(), timeoutMs);
  try {
    const res = await fetch(url, {
      ...init,
      signal: ctrl.signal,
      headers: { 'X-API-Key': LITEAPI_KEY, accept: 'application/json', 'content-type': 'application/json' },
    });
    const text = await res.text();
    let data: any = null;
    try {
      data = text ? JSON.parse(text) : null;
    } catch {
      data = { raw: text.slice(0, 1000) };
    }
    return { status: res.status, data };
  } finally {
    clearTimeout(t);
  }
}

const num = (v: unknown): number | null => {
  const n = Number(v);
  return Number.isFinite(n) ? n : null;
};
const amount = (v: any): number | null => (Array.isArray(v) ? num(v[0]?.amount) : num(v?.amount));

/// نسخة مختصرة من الرد للمراجعة: نحذف النصوص الطويلة جدًا (مثل offerId).
function trim(v: any, depth = 0): any {
  if (depth > 7) return '…';
  if (typeof v === 'string') return v.length > 160 ? `${v.slice(0, 60)}…(${v.length} chars)` : v;
  if (Array.isArray(v)) return v.slice(0, 5).map((x) => trim(x, depth + 1));
  if (v && typeof v === 'object') {
    const o: Record<string, unknown> = {};
    for (const [k, x] of Object.entries(v)) o[k] = trim(x, depth + 1);
    return o;
  }
  return v;
}

/// يبحث ويُرجع أرخص offerId لأول فندق يطابق الاسم (أو أول فندق).
async function findOffer(b: any): Promise<{ offerId: string | null; hotelId?: string; hotelName?: string; searchPrice?: number | null; error?: unknown }> {
  const children: number[] = Array.isArray(b.children) ? b.children.map(Number).filter((a: number) => a >= 0 && a <= 17) : [];
  const r = await call(`${API}/hotels/rates`, {
    method: 'POST',
    body: JSON.stringify({
      cityName: String(b.cityName ?? ''),
      countryCode: String(b.countryCode ?? '').toUpperCase(),
      checkin: String(b.checkin ?? ''),
      checkout: String(b.checkout ?? ''),
      occupancies: [{ adults: Number(b.adults ?? 2) || 2, children }],
      currency: 'USD',
      guestNationality: 'US',
      margin: 0, // أسعار الجملة الصافية
      limit: 50,
      maxRatesPerHotel: 1,
      timeout: 15,
    }),
  });
  if (r.status !== 200) return { offerId: null, error: r.data };
  const names = new Map<string, string>();
  for (const h of r.data?.hotels ?? []) names.set(String(h.id), String(h.name ?? ''));
  const want = String(b.hotelName ?? '').toLowerCase();
  const items: any[] = r.data?.data ?? [];
  const hit = items.find((d) => !want || (names.get(String(d.hotelId)) ?? '').toLowerCase().includes(want));
  if (!hit) return { offerId: null, error: 'No hotel matched hotelName in search results.' };
  const rt = hit.roomTypes?.[0];
  return {
    offerId: rt?.offerId ?? null,
    hotelId: hit.hotelId,
    hotelName: names.get(String(hit.hotelId)),
    searchPrice: amount(rt?.offerRetailRate),
  };
}

serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: cors });
  if (!LITEAPI_KEY) return json({ ok: false, code: 'not_configured', error: 'LITEAPI_KEY is missing.' });

  try {
    const b = await req.json().catch(() => ({}));
    let offerId = String(b.offerId ?? '').trim();
    let found: Record<string, unknown> = {};

    if (!offerId) {
      const f = await findOffer(b);
      if (!f.offerId) return json({ ok: false, code: 'no_offer', error: f.error ?? 'No offer found.' });
      offerId = f.offerId;
      found = { hotelId: f.hotelId, hotelName: f.hotelName, searchPriceUsd: f.searchPrice };
    }

    const started = Date.now();
    const pb = await call(`${BOOK}/rates/prebook`, {
      method: 'POST',
      body: JSON.stringify({ offerId, usePaymentSdk: false }),
    });
    const ms = Date.now() - started;
    console.log(`LITEAPI PREBOOK HTTP ${pb.status} in ${ms}ms`);

    if (pb.status !== 200) {
      return json({ ok: false, code: 'prebook_failed', status: pb.status, ms, ...found, error: trim(pb.data) });
    }

    const d = pb.data?.data ?? pb.data ?? {};
    // نجمع كل الرسوم من كل الأسعار في العرض.
    const rates: any[] = (d.roomTypes ?? []).flatMap((rt: any) => rt?.rates ?? []);
    const fees = rates.flatMap((r: any) => (Array.isArray(r?.retailRate?.taxesAndFees) ? r.retailRate.taxesAndFees : []));

    return json({
      ok: true,
      ms,
      ...found,
      summary: {
        prebookId: d.prebookId ?? null,
        hotelId: d.hotelId ?? null,
        currency: d.currency ?? null,
        price: num(d.price) ?? amount(d.offerRetailRate) ?? null,
        suggestedSellingPrice: num(d.suggestedSellingPrice) ?? amount(d.suggestedSellingPrice),
        priceDifferencePercent: num(d.priceDifferencePercent),
        cancellationChanged: d.cancellationChanged ?? null,
        boardChanged: d.boardChanged ?? null,
        refundableTag: rates[0]?.cancellationPolicies?.refundableTag ?? null,
        cancelPolicyInfos: rates[0]?.cancellationPolicies?.cancelPolicyInfos ?? null,
        hotelRemarks: rates[0]?.cancellationPolicies?.hotelRemarks ?? null,
        // ملاحظات الفندق كاملة كنص عادي (تذكر غالبًا الرسوم التي تُدفع في الفندق).
        remarksText: String(rates[0]?.remarks ?? '')
          .replace(/<br\s*\/?>/gi, '\n')
          .replace(/<[^>]+>/g, '')
          .replace(/&nbsp;/g, ' ')
          .replace(/&amp;/g, '&')
          .replace(/[ \t]+/g, ' ')
          .replace(/\n\s*\n+/g, '\n')
          .trim(),
        feesIncluded: fees.filter((f: any) => f?.included === true),
        feesNotIncluded: fees.filter((f: any) => f?.included === false),
        paymentTypes: rates[0]?.paymentTypes ?? null,
      },
      debug: {
        topLevelKeys: Object.keys(pb.data ?? {}),
        dataKeys: Object.keys(d),
        raw: trim(d),
      },
    });
  } catch (e) {
    console.log('liteapi-prebook error', String(e));
    return json({ ok: false, code: 'server_error', error: String(e) });
  }
});