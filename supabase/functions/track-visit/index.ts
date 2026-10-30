// supabase/functions/track-visit/index.ts
//
// يسجّل زيارة (فتح الموقع/التطبيق) مع الموقع التقريبي للزائر:
// الدولة، والولاية/المقاطعة، والمدينة — من عنوان IP.
// لا نخزّن عنوان IP نفسه، ولا أي شيء يكشف هوية الزائر.
//
// يُستدعى من التطبيق مرة لكل جلسة، ومرة عند تسجيل الدخول (لربط الزيارة بالحساب).
//
// المدخلات: { visitorId, event: 'visit' | 'login', platform, lang }
//
// تحديد الموقع:
//   1) من ترويسات الشبكة إن وُجدت (cf-ipcountry ...) — الدولة فقط.
//   2) من ipinfo.io إن وُضع Secret اسمه IPINFO_TOKEN:
//        supabase secrets set IPINFO_TOKEN=xxxxxxxx --project-ref nomgbttkfzhgbmbyidpy
//      • الخطة المجانية (IPinfo Lite): الدولة فقط — نستخدم api.ipinfo.io/lite.
//      • خطة مدفوعة فيها المدينة: أضف أيضًا IPINFO_CITY=1 فنستخدم ipinfo.io/{ip}/json
//        ونحفظ الولاية والمدينة.
//
// النشر (يُستدعى بمفتاح anon أو بتوكن المستخدم):
//   supabase functions deploy track-visit --project-ref nomgbttkfzhgbmbyidpy

import { adminClient, corsHeaders, getUser } from '../_shared/hotelbeds.ts';

const IPINFO_TOKEN = Deno.env.get('IPINFO_TOKEN') ?? '';
const IPINFO_CITY = (Deno.env.get('IPINFO_CITY') ?? '') === '1';

function reply(status = 204): Response {
  return new Response(null, { status, headers: corsHeaders });
}

function clientIp(req: Request): string | null {
  const fwd = req.headers.get('x-forwarded-for');
  if (fwd) return fwd.split(',')[0].trim() || null;
  return req.headers.get('cf-connecting-ip') ?? req.headers.get('x-real-ip') ?? null;
}

function clean(v: unknown, max: number): string | null {
  const t = typeof v === 'string' ? v.trim() : '';
  return t ? t.slice(0, max) : null;
}

async function lookup(req: Request): Promise<{ country: string | null; region: string | null; city: string | null }> {
  const headerCountry =
    clean(req.headers.get('cf-ipcountry'), 2) ??
    clean(req.headers.get('x-country-code'), 2) ??
    null;
  const fallback = {
    country: headerCountry && headerCountry !== 'XX' ? headerCountry.toUpperCase() : null,
    region: null,
    city: null,
  };

  const ip = clientIp(req);
  if (!IPINFO_TOKEN || !ip) return fallback;

  try {
    const ctrl = new AbortController();
    const t = setTimeout(() => ctrl.abort(), 2500);
    const url = IPINFO_CITY
      ? `https://ipinfo.io/${encodeURIComponent(ip)}/json?token=${IPINFO_TOKEN}`
      : `https://api.ipinfo.io/lite/${encodeURIComponent(ip)}?token=${IPINFO_TOKEN}`;
    const res = await fetch(url, { signal: ctrl.signal });
    clearTimeout(t);
    if (!res.ok) {
      console.log('IPINFO FAILED', res.status);
      return fallback;
    }
    const d = await res.json();
    if (d?.bogon) return fallback; // عنوان داخلي/محلي
    return {
      // Lite: country_code ؛ الخطط الأخرى: country
      country: (clean(d?.country_code, 2) ?? clean(d?.country, 2))?.toUpperCase() ?? fallback.country,
      region: IPINFO_CITY ? clean(d?.region, 80) : null,
      city: IPINFO_CITY ? clean(d?.city, 80) : null,
    };
  } catch {
    return fallback;
  }
}

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders });
  if (req.method !== 'POST') return reply(405);

  try {
    const body = await req.json().catch(() => ({}));
    const visitorId = clean(body.visitorId, 64);
    if (!visitorId || visitorId.length < 8) return reply(400);

    const event = body.event === 'login' ? 'login' : 'visit';
    const platform = ['web', 'android', 'ios'].includes(body.platform) ? body.platform : 'other';

    const admin = adminClient();
    const user = await getUser(req, admin).catch(() => null);
    const geo = await lookup(req);

    const { error } = await admin.from('app_visits').insert({
      visitor_id: visitorId,
      user_id: user?.id ?? null,
      event,
      platform,
      country: geo.country,
      region: geo.region,
      city: geo.city,
      lang: clean(body.lang, 10),
    });
    if (error) console.log('VISIT INSERT FAILED', error.message);
    return reply(204);
  } catch (e) {
    console.log('track-visit error', String(e));
    return reply(204); // لا نُزعج التطبيق بأخطاء التحليلات
  }
});