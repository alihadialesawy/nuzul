// supabase/functions/_shared/liteapi.ts
//
// أدوات مشتركة لمورّد LiteAPI (Nuitee): الاتصال، والعمولة، والرسوم، وسياسة الإلغاء.
// تستخدمها liteapi-search الآن، ثم liteapi-prepare / liteapi-book لاحقًا،
// فيتطابق السعر المعروض في البحث مع المسحوب عند الدفع.
//
// الأسرار:
//   LITEAPI_KEY              مفتاح sandbox الآن، ثم مفتاح الإنتاج (يُرسل في X-API-Key).
//   LITEAPI_MARKUP_PERCENT   عمولة Flynoom % (افتراضيًا = HOTELBEDS_MARKUP_PERCENT أو 0).
//
// ⚠️ نرسل margin: 0 في كل طلب /hotels/rates حتى تصلنا أسعار الجملة الصافية
// (بدونه تُطبَّق العمولة الافتراضية في لوحة LiteAPI)، وعمولتنا تُضاف هنا فقط.
// سعر البيع لا يقل أبدًا عن SSP (الحد الأدنى المسموح علنًا).

import { round2, toNum, toUsdRaw } from './hotelbeds.ts';

export const LITEAPI_KEY = Deno.env.get('LITEAPI_KEY') ?? '';
export const LITEAPI_API = 'https://api.liteapi.travel/v3.0';
export const LITEAPI_BOOK = 'https://book.liteapi.travel/v3.0';

export const LITEAPI_MARKUP_PERCENT =
  Number(Deno.env.get('LITEAPI_MARKUP_PERCENT') ?? Deno.env.get('HOTELBEDS_MARKUP_PERCENT') ?? '0') || 0;

export async function liteapi(
  url: string,
  init: RequestInit = {},
  timeoutMs = 30000,
): Promise<{ status: number; data: any }> {
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

/// أول مبلغ في [{amount,currency}] أو {amount,currency}.
export function amountOf(v: any): number | null {
  if (Array.isArray(v)) return toNum(v[0]?.amount);
  return toNum(v?.amount);
}

/// سعر البيع = الجملة (margin: 0) + عمولتنا، ولا يقل أبدًا عن
/// suggestedSellingPrice (SSP): هو الحد الأدنى الذي يسمح الفندق بعرضه للعامة،
/// والبيع تحته في موقع عام = مخالفة سعرية (rate violation) حسب شروط LiteAPI.
/// فإذا كانت عمولتنا أقل من الفارق بين الجملة و SSP، نبيع بسعر SSP والفرق ربح لنا.
export function liteSellingPrice(net: number, suggested: number | null): number {
  let price = net * (1 + LITEAPI_MARKUP_PERCENT / 100);
  if (suggested != null && suggested > price) price = suggested;
  return round2(price);
}

/// تصنيف الرسوم (قاعدة FTC): الضرائب الحكومية يجوز عرضها منفصلة،
/// أما رسوم الفندق الإلزامية (resort/destination/facility fee) فتدخل في الإجمالي.
/// أي وصف غير واضح ("OTHER"، "Taxes and Fees") نعامله كرسم إلزامي (الأحوط).
const GOV_TAX_RE =
  /\b(city|county|state|municipal(ity)?|occupancy|tourism|tourist|lodging|sales|hotel)\s*_?-?\s*tax(es)?\b|^(citytax|countytax|statetax|tourismtax|occupancytax|vat|gst|hst|pst|municipality fee|tourism dirham.*|.*tourism dirham.*|tourism fee)$/i;

export function isGovernmentTax(description: string): boolean {
  const d = description.trim().toLowerCase();
  if (!d || d === 'other' || d === 'others' || d.includes('resort') || d.includes('destination') ||
    d.includes('facility') || d.includes('amenity') || d.includes('service')) {
    return false;
  }
  return GOV_TAX_RE.test(d);
}

export interface LiteAtHotelFee {
  type: string | null; // الوصف كما جاء من المورّد
  amount: number;
  currency: string;
  amountUsd: number;
  government: boolean; // ضريبة حكومية (تُعرض منفصلة) أم رسم إلزامي (يدخل الإجمالي)
}

/// الرسوم غير المشمولة (included=false) = يدفعها الضيف في الفندق (تأكيد LiteAPI).
export async function liteAtHotelFees(rates: any[]): Promise<{
  fees: LiteAtHotelFee[];
  totalUsd: number;
  mandatoryUsd: number;
  governmentUsd: number;
}> {
  const fees: LiteAtHotelFee[] = [];
  for (const r of rates) {
    const list = Array.isArray(r?.retailRate?.taxesAndFees) ? r.retailRate.taxesAndFees : [];
    for (const f of list) {
      if (f?.included !== false) continue;
      const amount = toNum(f.amount) ?? 0;
      const currency = String(f.currency ?? 'USD').toUpperCase();
      let amountUsd = 0;
      try {
        amountUsd = await toUsdRaw(amount, currency);
      } catch (_) {
        amountUsd = 0;
      }
      const type = f.description ? String(f.description) : null;
      fees.push({ type, amount, currency, amountUsd, government: isGovernmentTax(type ?? '') });
    }
  }
  const sum = (xs: LiteAtHotelFee[]) => round2(xs.reduce((s, f) => s + f.amountUsd, 0));
  return {
    fees,
    totalUsd: sum(fees),
    mandatoryUsd: sum(fees.filter((f) => !f.government)),
    governmentUsd: sum(fees.filter((f) => f.government)),
  };
}

/// "2026-12-09 20:00:00" (GMT) → "2026-12-09T20:00:00+00:00".
export function gmtToIso(s: unknown): string {
  const m = /^(\d{4}-\d{2}-\d{2})[ T](\d{2}:\d{2})(:\d{2})?/.exec(String(s ?? ''));
  return m ? `${m[1]}T${m[2]}${m[3] ?? ':00'}+00:00` : String(s ?? '');
}

/// سياسة الإلغاء بنفس شكل HotelBeds: [{amount, from}] — amount بسعر الجملة.
/// غير قابل للاسترداد بلا تفاصيل = رسوم كاملة من الآن.
export function liteCancellation(rate: any, net: number): { policies: { amount: number; from: string; timezone: string }[]; refundable: boolean } {
  const cp = rate?.cancellationPolicies ?? {};
  const refundable = cp.refundableTag === 'RFN';
  const policies = (Array.isArray(cp.cancelPolicyInfos) ? cp.cancelPolicyInfos : [])
    .map((p: any) => ({ amount: toNum(p.amount) ?? 0, from: gmtToIso(p.cancelTime), timezone: String(p.timezone ?? 'GMT') }))
    .sort((a: any, b: any) => a.from.localeCompare(b.from));
  if (!refundable && policies.length === 0) {
    policies.push({ amount: net, from: new Date().toISOString().slice(0, 19) + '+00:00', timezone: 'GMT' });
  }
  return { policies, refundable };
}

// ───────────────────────── الوجهات (المرحلة 2) ─────────────────────────
//
// الواجهة ما زالت تختار المدينة من جدولنا hotelbeds_destinations (الكود مثل QCA
// لمكة يبقى كما هو: فحص موسم الحج، المواقع المقدسة، تصفح الدول ... كلها تعتمد عليه).
// هنا نحوّل الكود إلى placeId في LiteAPI (/data/places) مرة واحدة فقط لكل مدينة،
// ونحفظه في عمود liteapi_place_id، فلا نكرر الطلب.

export interface LiteDestination {
  code: string | null;
  name: string;
  countryCode: string;
  placeId: string | null;
  placeName: string | null;
}

const destinationMemo = new Map<string, LiteDestination>();

/// "Orlando Area - Florida - FL" → "Orlando, Florida".
export function cleanDestinationName(name: string): string {
  return name
    .split(/\s+-\s+/)
    .map((p) => p.replace(/\bArea\b/i, '').trim())
    .filter((p) => p && !/^[A-Z]{2,3}$/.test(p))
    .join(', ');
}

function countryName(code: string): string {
  try {
    return new Intl.DisplayNames(['en'], { type: 'region' }).of(code) ?? code;
  } catch {
    return code;
  }
}

/// يبحث في LiteAPI عن مدينة (locality) ويختار أول نتيجة في نفس الدولة.
export async function findPlaceId(
  cityName: string,
  countryCode: string,
): Promise<{ placeId: string; displayName: string } | null> {
  const country = countryName(countryCode);
  const textQuery = `${cityName}, ${country}`;
  const url = `${LITEAPI_API}/data/places?` +
    new URLSearchParams({ textQuery, type: 'locality', language: 'en' }).toString();
  const r = await liteapi(url, { method: 'GET' }, 10000);
  const list: any[] = Array.isArray(r.data?.data) ? r.data.data : [];
  if (r.status !== 200 || list.length === 0) {
    console.log(`PLACES none for "${textQuery}" HTTP ${r.status}`);
    return null;
  }
  const c = country.toLowerCase();
  const inCountry = list.find((p) => String(p?.formattedAddress ?? '').toLowerCase().includes(c)) ??
    list.find((p) => String(p?.formattedAddress ?? '').toUpperCase().endsWith(countryCode));
  const best = inCountry ?? null; // مدينة في دولة أخرى = خطأ، الأفضل الرجوع إلى cityName
  if (!best?.placeId) {
    console.log(`PLACES no match in ${countryCode} for "${textQuery}": ${list.map((p) => p.formattedAddress).join(' | ')}`);
    return null;
  }
  return { placeId: String(best.placeId), displayName: String(best.displayName ?? cityName) };
}

/// كود وجهة (QCA) → اسم ودولة و placeId (من الجدول، أو يُحسب ويُحفظ أول مرة).
export async function resolveDestinationCode(
  admin: any,
  code: string,
): Promise<LiteDestination | null> {
  const key = code.trim().toUpperCase();
  if (!key) return null;
  const memo = destinationMemo.get(key);
  if (memo) return memo;

  const { data: row, error } = await admin
    .from('hotelbeds_destinations')
    .select('code, name, country_code, liteapi_place_id, liteapi_place_name')
    .eq('code', key)
    .maybeSingle();
  if (error) {
    console.log(`DEST lookup ${key} failed: ${error.message}`);
    return null;
  }
  if (!row) return null;

  const dest: LiteDestination = {
    code: key,
    name: cleanDestinationName(String(row.name ?? '')) || String(row.name ?? ''),
    countryCode: String(row.country_code ?? '').toUpperCase(),
    placeId: row.liteapi_place_id ?? null,
    placeName: row.liteapi_place_name ?? null,
  };

  if (!dest.placeId && dest.name && /^[A-Z]{2}$/.test(dest.countryCode)) {
    const found = await findPlaceId(dest.name, dest.countryCode);
    if (found) {
      dest.placeId = found.placeId;
      dest.placeName = found.displayName;
      const { error: upErr } = await admin
        .from('hotelbeds_destinations')
        .update({
          liteapi_place_id: found.placeId,
          liteapi_place_name: found.displayName,
          liteapi_checked_at: new Date().toISOString(),
        })
        .eq('code', key);
      if (upErr) console.log(`DEST save ${key} failed: ${upErr.message}`);
      console.log(`DEST ${key} "${dest.name}" → ${found.placeId} (${found.displayName})`);
    }
  }

  destinationMemo.set(key, dest);
  return dest;
}

// ───────────────────────── بيانات الفندق الأساسية (للفحوص عند الحجز) ─────────────────────────

export interface LiteHotelBasics {
  id: string;
  name: string | null;
  city: string | null;
  countryCode: string | null; // ISO-2 بأحرف كبيرة
  lat: number | null;
  lon: number | null;
  address: string | null;
}

const basicsMemo = new Map<string, { at: number; data: LiteHotelBasics }>();

/// الدولة والموقع والاسم من /data/hotel — مصدر موثوق للفحوص (لا نثق بما يرسله التطبيق).
/// null عند تعذّر الاستعلام.
export async function liteHotelBasics(hotelId: string): Promise<LiteHotelBasics | null> {
  const hit = basicsMemo.get(hotelId);
  if (hit && Date.now() - hit.at < 6 * 3600 * 1000) return hit.data;
  const r = await liteapi(`${LITEAPI_API}/data/hotel?${new URLSearchParams({ hotelId, language: 'en' })}`, { method: 'GET' }, 10000);
  const h = r.data?.data;
  if (r.status !== 200 || !h) {
    console.log(`LITE HOTEL BASICS ${hotelId}: HTTP ${r.status}`);
    return null;
  }
  const num = (v: unknown) => (v === null || v === undefined || v === '' ? null : Number.isFinite(Number(v)) ? Number(v) : null);
  const data: LiteHotelBasics = {
    id: hotelId,
    name: h.name ? String(h.name) : null,
    city: h.city ? String(h.city) : null,
    countryCode: h.country ? String(h.country).toUpperCase() : null,
    lat: num(h.location?.latitude ?? h.latitude),
    lon: num(h.location?.longitude ?? h.longitude),
    address: h.address ? String(h.address) : null,
  };
  basicsMemo.set(hotelId, { at: Date.now(), data });
  return data;
}

/// ملاحظات الفندق كنص عادي (من HTML).
export function remarksText(html: unknown): string | null {
  const t = String(html ?? '')
    .replace(/<br\s*\/?>/gi, '\n')
    .replace(/<[^>]+>/g, '')
    .replace(/&nbsp;/g, ' ')
    .replace(/&amp;/g, '&')
    .replace(/[ \t]+/g, ' ')
    .replace(/\n\s*\n+/g, '\n')
    .trim();
  return t || null;
}