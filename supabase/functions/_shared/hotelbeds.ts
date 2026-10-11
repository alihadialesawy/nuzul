// supabase/functions/_shared/hotelbeds.ts
//
// أدوات مشتركة بين دوال حجز HotelBeds (hotelbeds-prepare و hotelbeds-book).
// مجلد _shared لا يُنشر كدالة مستقلة؛ Supabase يضمّه داخل كل دالة تستورده.

import { createClient, SupabaseClient } from 'jsr:@supabase/supabase-js@2';

export const HOTELBEDS_API_KEY = Deno.env.get('HOTELBEDS_API_KEY')!;
export const HOTELBEDS_SECRET = Deno.env.get('HOTELBEDS_SECRET')!;
// بيئة الاختبار. عند الإنتاج: https://api.hotelbeds.com (غيّرها هنا وفي hotelbeds-search).
export const HOTELBEDS_BASE_URL = 'https://api.test.hotelbeds.com';

const SUPABASE_URL = Deno.env.get('SUPABASE_URL')!;
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;

/// ⚠️ نفس معادلة hotelbeds-search: الربح على الأسعار غير الإلزامية.
export const MARKUP_PERCENT = Number(Deno.env.get('HOTELBEDS_MARKUP_PERCENT') ?? '0') || 0;

/// هامش أمان على سعر الصرف لو عملة HotelBeds ليست USD (افتراضيًا 2%).
export const FX_BUFFER_PERCENT = Number(Deno.env.get('FX_BUFFER_PERCENT') ?? '2') || 0;

/// لعرض المبلغ بالريال في صفحات التطبيق القديمة (PriceText يتوقع SAR).
export const SAR_PER_USD = 3.75;

export const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

/// كل الردود 200 مع ok=true/false، حتى يقرأ التطبيق رسالة الخطأ بسهولة
/// (بعض إصدارات supabase_flutter ترمي استثناء على أي رد غير 2xx).
export function ok(body: Record<string, unknown>): Response {
  return new Response(JSON.stringify({ ok: true, ...body }), {
    headers: { ...corsHeaders, 'Content-Type': 'application/json' },
  });
}

export function fail(code: string, error: string, extra: Record<string, unknown> = {}): Response {
  return new Response(JSON.stringify({ ok: false, code, error, ...extra }), {
    headers: { ...corsHeaders, 'Content-Type': 'application/json' },
  });
}

export function adminClient(): SupabaseClient {
  return createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);
}

/// المستخدم صاحب الطلب من الـ JWT (null لو غير مسجّل).
export async function getUser(req: Request, admin: SupabaseClient) {
  const token = (req.headers.get('Authorization') ?? '').replace(/^Bearer\s+/i, '');
  if (!token) return null;
  const { data, error } = await admin.auth.getUser(token);
  if (error) return null;
  return data.user ?? null;
}

export async function computeSignature(): Promise<string> {
  const timestamp = Math.floor(Date.now() / 1000);
  const raw = `${HOTELBEDS_API_KEY}${HOTELBEDS_SECRET}${timestamp}`;
  const hash = await crypto.subtle.digest('SHA-256', new TextEncoder().encode(raw));
  return Array.from(new Uint8Array(hash)).map((b) => b.toString(16).padStart(2, '0')).join('');
}

export async function hotelbedsHeaders(): Promise<Record<string, string>> {
  return {
    'Api-key': HOTELBEDS_API_KEY,
    'X-Signature': await computeSignature(),
    'Accept': 'application/json',
    'Accept-Encoding': 'gzip',
    'Content-Type': 'application/json',
  };
}

export function round2(n: number): number {
  return Math.round(n * 100) / 100;
}

export function toNum(v: unknown): number | null {
  if (v === null || v === undefined || v === '') return null;
  const n = Number(v);
  return Number.isFinite(n) ? n : null;
}

/// سعر البيع بعملة HotelBeds (نفس منطق البحث).
export function sellingPrice(net: number, sellingRate: number | null, hotelMandatory: boolean): number {
  if (hotelMandatory && sellingRate !== null) return round2(sellingRate);
  return round2(net * (1 + MARKUP_PERCENT / 100));
}

// ───────── تحويل العملة إلى USD (مع هامش أمان) ─────────

let fxCache: { at: number; rates: Record<string, number> } | null = null;

/// كم وحدة من العملة مقابل 1 USD.
async function unitsPerUsd(currency: string): Promise<number> {
  const cur = currency.toUpperCase();
  if (cur === 'USD') return 1;
  if (!fxCache || Date.now() - fxCache.at > 60 * 60 * 1000) {
    const res = await fetch('https://open.er-api.com/v6/latest/USD');
    const data = await res.json();
    if (!res.ok || !data?.rates) throw new Error('FX rates unavailable');
    fxCache = { at: Date.now(), rates: data.rates };
  }
  const rate = Number(fxCache.rates[cur]);
  if (!Number.isFinite(rate) || rate <= 0) throw new Error(`No FX rate for ${cur}`);
  return rate;
}

export async function toUsd(amount: number, currency: string): Promise<number> {
  const cur = currency.toUpperCase();
  if (cur === 'USD') return round2(amount);
  const rate = await unitsPerUsd(cur);
  // نقرّب للأعلى للسنت حتى لا نخسر فرق التحويل.
  return Math.ceil((amount / rate) * (1 + FX_BUFFER_PERCENT / 100) * 100) / 100;
}

/// تحويل بدون هامش (للعرض التقديري فقط، مثل الرسوم التي تُدفع في الفندق).
export async function toUsdRaw(amount: number, currency: string): Promise<number> {
  const cur = currency.toUpperCase();
  if (cur === 'USD') return round2(amount);
  return round2(amount / (await unitsPerUsd(cur)));
}

export interface AtHotelFee {
  type: string | null;
  amount: number; // بالعملة المحلية التي يطلبها الفندق
  currency: string;
  amountUsd: number; // تقدير بالدولار
}

/// الضرائب/الرسوم الإلزامية غير المشمولة في السعر، والتي تُدفع في الفندق
/// (مثل resort fee وضرائب المدينة). من rate.taxes حيث included = false.
///
/// ⚠️ قاعدة FTC الأمريكية للرسوم (منذ مايو 2025) تُلزم بإدخال الرسوم
/// الإلزامية (مثل resort fee) في السعر الإجمالي المعروض.
export async function atHotelFees(rate: any): Promise<{ fees: AtHotelFee[]; totalUsd: number }> {
  const fees: AtHotelFee[] = [];
  for (const t of rate?.taxes?.taxes ?? []) {
    if (t?.included === true) continue;
    const amount = toNum(t.amount);
    const currency = String(t.currency ?? '').toUpperCase();
    const clientAmount = toNum(t.clientAmount);
    const clientCurrency = String(t.clientCurrency ?? '').toUpperCase();
    let amountUsd = 0;
    try {
      if (amount !== null && currency) amountUsd = await toUsdRaw(amount, currency);
      else if (clientAmount !== null && clientCurrency) amountUsd = await toUsdRaw(clientAmount, clientCurrency);
    } catch (_) {
      amountUsd = 0;
    }
    fees.push({
      type: t.type ?? null,
      amount: amount ?? clientAmount ?? 0,
      currency: currency || clientCurrency,
      amountUsd,
    });
  }
  return { fees, totalUsd: round2(fees.reduce((s, f) => s + f.amountUsd, 0)) };
}

/// مرجع قصير نرسله لـ HotelBeds (clientReference، حد أقصى 20 حرفًا).
export function newClientReference(): string {
  const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
  const bytes = crypto.getRandomValues(new Uint8Array(10));
  return 'FLY' + Array.from(bytes, (b) => chars[b % chars.length]).join('');
}

/// fetch مع مهلة.
export async function fetchWithTimeout(url: string, init: RequestInit, ms: number): Promise<Response> {
  const controller = new AbortController();
  const timer = setTimeout(() => controller.abort(), ms);
  try {
    return await fetch(url, { ...init, signal: controller.signal });
  } finally {
    clearTimeout(timer);
  }
}

/// عنوان الفندق وهاتفه من Content API (للقسيمة). يرجع null عند الفشل.
export async function fetchHotelContact(
  code: string,
): Promise<{ address: string | null; phone: string | null }> {
  try {
    const res = await fetchWithTimeout(
      `${HOTELBEDS_BASE_URL}/hotel-content-api/1.0/hotels/${encodeURIComponent(code)}/details` +
        `?language=ENG&useSecondaryLanguage=false`,
      { method: 'GET', headers: await hotelbedsHeaders() },
      8000,
    );
    if (!res.ok) return { address: null, phone: null };
    const h = (await res.json())?.hotel;
    const address = [
      h?.address?.content,
      h?.city?.content,
      h?.stateCode,
      h?.postalCode,
      h?.countryCode,
    ]
      .filter((s) => typeof s === 'string' && s.trim())
      .map((s: string) => s.trim())
      .join(', ');
    const phones: any[] = h?.phones ?? [];
    const phone =
      phones.find((p) => p?.phoneType === 'PHONEBOOKING')?.phoneNumber ??
      phones.find((p) => p?.phoneType === 'PHONEHOTEL')?.phoneNumber ??
      phones[0]?.phoneNumber ??
      null;
    return { address: address || null, phone };
  } catch (_) {
    return { address: null, phone: null };
  }
}