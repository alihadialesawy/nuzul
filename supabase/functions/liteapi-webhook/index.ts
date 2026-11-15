// supabase/functions/liteapi-webhook/index.ts
//
// تنبيهات LiteAPI (Nuitee Connect → Workflows → Webhooks).
//
// الأمان: LiteAPI ترسل "Authentication Token" في ترويسة Authorization.
// نقارنه بالسر LITEAPI_WEBHOOK_TOKEN (مقبول مع "Bearer " أو بدونها)، ونرفض غيره.
// ⚠️ تُنشر بدون تحقق JWT (Supabase تتوقع في Authorization توكن تسجيل دخول):
//   supabase functions deploy liteapi-webhook --project-ref nomgbttkfzhgbmbyidpy --no-verify-jwt
//
// المبدأ: لا نغيّر مالًا تلقائيًا بناءً على تنبيه. نحفظ كل تنبيه، ونحدّث ما هو آمن
// (رقم تأكيد الفندق)، ونضع الحجز "قيد المراجعة" وننبّه المدير في كل ما يمس
// الحجز أو المال (إلغاء من خارج Flynoom، نقل الضيف، استرداد، تعويض، تعديل).
//
// الأحداث المقترح الاشتراك فيها:
//   booking.cancel, booking.cancel_error, booking.book_error,
//   booking.amendment, booking.amendment.relocation,
//   booking.rebook.rfn, booking.rebook.nrfn,
//   booking.book.hotelConfirmationNumber, booking.refund,
//   booking.compensation, booking.checkinInstruction
//
// الشكل الدقيق لرسالة LiteAPI غير موثّق عندنا بعد؛ القارئ هنا مرن (يبحث عن نوع
// الحدث ورقم الحجز في أكثر من مكان)، والرسالة تُحفظ كاملة لنراجعها ونضبط القارئ.

import { adminClient, corsHeaders } from '../_shared/hotelbeds.ts';
import { sendEmail } from '../_shared/email.ts';

const TOKEN = Deno.env.get('LITEAPI_WEBHOOK_TOKEN') ?? '';
const ADMIN_EMAIL = Deno.env.get('ADMIN_EMAIL') ?? 'ali@flynoom.com';

const json = (body: unknown, status = 200) =>
  new Response(JSON.stringify(body), { status, headers: { ...corsHeaders, 'Content-Type': 'application/json' } });

const esc = (v: unknown) => String(v ?? '').replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;');

/// مقارنة بزمن ثابت (لا تكشف طول التطابق).
function safeEqual(a: string, b: string): boolean {
  const x = new TextEncoder().encode(a);
  const y = new TextEncoder().encode(b);
  let diff = x.length ^ y.length;
  for (let i = 0; i < Math.max(x.length, y.length); i++) diff |= (x[i] ?? 0) ^ (y[i] ?? 0);
  return diff === 0;
}

async function sha256(text: string): Promise<string> {
  const buf = await crypto.subtle.digest('SHA-256', new TextEncoder().encode(text));
  return [...new Uint8Array(buf)].map((b) => b.toString(16).padStart(2, '0')).join('');
}

/// LiteAPI ترسل بعض الحقول نصًا يحوي JSON (مثل "request"). نفكّها لنبحث داخلها.
function unwrap(v: any, depth = 0): any {
  if (depth > 6) return v;
  if (typeof v === 'string') {
    const t = v.trim();
    if ((t.startsWith('{') && t.endsWith('}')) || (t.startsWith('[') && t.endsWith(']'))) {
      try {
        return unwrap(JSON.parse(t), depth + 1);
      } catch {
        return v;
      }
    }
    return v;
  }
  if (Array.isArray(v)) return v.map((x) => unwrap(x, depth + 1));
  if (v && typeof v === 'object') {
    const o: Record<string, any> = {};
    for (const [k, x] of Object.entries(v)) o[k] = unwrap(x, depth + 1);
    return o;
  }
  return v;
}

/// أول قيمة لأي من المفاتيح المعطاة، في أي عمق من الرسالة.
function findKey(obj: any, keys: string[], depth = 0): string | null {
  if (!obj || typeof obj !== 'object' || depth > 8) return null;
  const want = new Set(keys.map((k) => k.toLowerCase()));
  for (const [k, v] of Object.entries(obj)) {
    if (want.has(k.toLowerCase()) && v !== null && typeof v !== 'object' && String(v).trim() !== '') {
      return String(v).trim();
    }
  }
  for (const v of Object.values(obj)) {
    const r = findKey(v, keys, depth + 1);
    if (r) return r;
  }
  return null;
}

/// نوع الحدث: أي قيمة نصية بشكل "booking.xxx" في الرسالة (أيًّا كان اسم مفتاحها).
function findEventType(obj: any, depth = 0): string | null {
  if (depth > 8 || obj === null || obj === undefined) return null;
  if (typeof obj === 'string') return /^(booking|flight|experience)\.[A-Za-z0-9_.]+$/.test(obj.trim()) ? obj.trim() : null;
  if (typeof obj !== 'object') return null;
  for (const v of Object.values(obj)) {
    const r = findEventType(v, depth + 1);
    if (r) return r;
  }
  return null;
}

/// أول قيمة نصية غير فارغة من عدة مسارات محتملة في الرسالة.
function pick(obj: any, paths: string[]): string | null {
  for (const p of paths) {
    let v: any = obj;
    for (const k of p.split('.')) v = v?.[k];
    if (v !== undefined && v !== null && String(v).trim() !== '') return String(v).trim();
  }
  return null;
}

const ALERT_TITLES: Record<string, string> = {
  'booking.cancel': 'Booking cancelled at LiteAPI',
  'booking.cancel_error': 'Cancellation failed at LiteAPI',
  'booking.book_error': 'Booking failed at LiteAPI',
  'booking.amendment': 'Booking amended',
  'booking.amendment.relocation': 'GUEST RELOCATED to another hotel',
  'booking.rebook.rfn': 'Booking rebooked (refundable)',
  'booking.rebook.nrfn': 'Booking rebooked (non-refundable)',
  'booking.refund': 'Refund issued by LiteAPI',
  'booking.compensation': 'Compensation issued by LiteAPI',
  'booking.checkinInstruction': 'Check-in instructions available',
};

/// أحداث تعني أن الحجز تغيّر خارج Flynoom: يصبح "قيد المراجعة" حتى يراجعه المدير.
const NEEDS_REVIEW = new Set([
  'booking.amendment.relocation',
  'booking.rebook.rfn',
  'booking.rebook.nrfn',
]);

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders });
  if (req.method !== 'POST') return json({ error: 'method not allowed' }, 405);

  // ───── التحقق من المرسل ─────
  if (!TOKEN) {
    console.log('LITEAPI WEBHOOK: LITEAPI_WEBHOOK_TOKEN is not set — rejecting');
    return json({ error: 'not configured' }, 503);
  }
  const auth = (req.headers.get('authorization') ?? '').replace(/^Bearer\s+/i, '').trim();
  if (!safeEqual(auth, TOKEN)) {
    console.log('LITEAPI WEBHOOK: bad token');
    return json({ error: 'unauthorized' }, 401);
  }

  const raw = await req.text();
  let body: any = null;
  try {
    body = raw ? JSON.parse(raw) : null;
  } catch {
    body = { raw: raw.slice(0, 5000) };
  }

  const admin = adminClient();
  const doc = unwrap(body);
  const eventType = pick(doc, ['event', 'type', 'eventType', 'event_type', 'data.event', 'data.type'])
      ?.match(/^(booking|flight|experience)\./)
    ? pick(doc, ['event', 'type', 'eventType', 'event_type', 'data.event', 'data.type'])!
    : findEventType(doc) ?? 'unknown';
  const supplierRef = findKey(doc, ['bookingId', 'booking_id']);
  const clientRef = findKey(doc, ['clientReference', 'client_reference']);

  // ───── منع التكرار (إعادة الإرسال) ─────
  const bodyHash = await sha256(raw);
  const { data: inserted, error: insErr } = await admin
    .from('liteapi_webhook_events')
    .insert({
      event_type: eventType,
      supplier_ref: supplierRef,
      client_reference: clientRef,
      body_hash: bodyHash,
      payload: doc,
      action: 'received',
    })
    .select('id')
    .maybeSingle();
  if (insErr) {
    if (insErr.code === '23505') {
      console.log(`LITEAPI WEBHOOK duplicate ${eventType} ref=${supplierRef ?? '-'}`);
      return json({ ok: true, duplicate: true });
    }
    // الجدول غير موجود أو خطأ آخر: نكمل (لا نريد أن تعيد LiteAPI المحاولة إلى ما لا نهاية).
    console.log('LITEAPI WEBHOOK log failed', insErr.message);
  }
  const eventId = inserted?.id ?? null;
  const setAction = async (action: string, bookingId?: string | null) => {
    if (!eventId) return;
    await admin.from('liteapi_webhook_events').update({ action, booking_id: bookingId ?? null }).eq('id', eventId);
  };

  // ───── الحجز المعني ─────
  let booking: any = null;
  if (supplierRef) {
    const { data } = await admin.from('bookings').select('*').eq('supplier', 'liteapi')
      .eq('supplier_reference', supplierRef).maybeSingle();
    booking = data;
  }
  if (!booking && clientRef) {
    const { data } = await admin.from('bookings').select('*').eq('client_reference', clientRef).maybeSingle();
    booking = data;
  }

  console.log(
    `LITEAPI WEBHOOK ${eventType} ref=${supplierRef ?? '-'} client=${clientRef ?? '-'} ` +
      `booking=${booking?.client_reference ?? 'not found'} status=${booking?.status ?? '-'}`,
  );

  try {
    // رقم تأكيد الفندق: تحديث آمن مباشر.
    if (eventType === 'booking.book.hotelConfirmationNumber') {
      const code = findKey(doc, ['hotelConfirmationCode', 'hotelConfirmationNumber', 'hotel_confirmation_code']);
      if (booking && code) {
        await admin.from('bookings').update({ hotel_confirmation_code: code, updated_at: new Date().toISOString() })
          .eq('id', booking.id);
        await setAction('hotel_conf_saved', booking.id);
      } else {
        await setAction(booking ? 'hotel_conf_missing' : 'booking_not_found', booking?.id);
      }
      return json({ ok: true });
    }

    // إلغاء: إن كان الإلغاء منّا (liteapi-cancel) فالحجز ملغى أو قيد المعالجة — لا شيء.
    // وإن كان الحجز ما زال "مؤكدًا" عندنا، فقد أُلغي من خارج Flynoom (الفندق أو LiteAPI
    // أو من لوحة Connect): قيد المراجعة + تنبيه. الاسترداد قرار المدير من Booking Desk.
    if (eventType === 'booking.cancel') {
      if (booking && booking.status === 'confirmed') {
        await admin.from('bookings').update({
          status: 'needs_attention',
          failure_reason: 'cancelled outside Flynoom (LiteAPI webhook) — review refund',
          updated_at: new Date().toISOString(),
        }).eq('id', booking.id);
        await alertAdmin(eventType, booking, supplierRef, clientRef, body, true);
        await setAction('needs_attention', booking.id);
      } else {
        await setAction(booking ? `ignored_status_${booking.status}` : 'booking_not_found', booking?.id);
      }
      return json({ ok: true });
    }

    // أحداث تغيّر الحجز خارج Flynoom.
    if (NEEDS_REVIEW.has(eventType) && booking && booking.status === 'confirmed') {
      await admin.from('bookings').update({
        status: 'needs_attention',
        failure_reason: `${eventType} (LiteAPI webhook) — review and inform the guest`,
        updated_at: new Date().toISOString(),
      }).eq('id', booking.id);
      await alertAdmin(eventType, booking, supplierRef, clientRef, body, true);
      await setAction('needs_attention', booking.id);
      return json({ ok: true });
    }

    // باقي الأحداث المهمة: تنبيه فقط.
    if (ALERT_TITLES[eventType]) {
      await alertAdmin(eventType, booking, supplierRef, clientRef, body, false);
      await setAction('admin_alerted', booking?.id);
      return json({ ok: true });
    }

    await setAction('logged', booking?.id);
    return json({ ok: true });
  } catch (e) {
    console.log('LITEAPI WEBHOOK handler error', String(e));
    await setAction(`error: ${String(e)}`.slice(0, 200), booking?.id);
    // 200 حتى لا تعيد LiteAPI الإرسال؛ الرسالة محفوظة في السجل.
    return json({ ok: true, handled: false });
  }
});

async function alertAdmin(
  eventType: string,
  booking: any,
  supplierRef: string | null,
  clientRef: string | null,
  body: unknown,
  markedForReview: boolean,
) {
  const title = ALERT_TITLES[eventType] ?? eventType;
  const ref = booking?.client_reference ?? clientRef ?? supplierRef ?? 'unknown booking';
  await sendEmail(ADMIN_EMAIL, {
    subject: `LiteAPI: ${title} — ${ref}`,
    html: `<p><b>${esc(title)}</b> (${esc(eventType)})</p>
<ul>
<li>Flynoom reference: ${esc(booking?.client_reference ?? clientRef ?? '-')}</li>
<li>LiteAPI booking: ${esc(supplierRef ?? booking?.supplier_reference ?? '-')}</li>
<li>Hotel: ${esc(booking?.hotel_name ?? '-')} · ${esc(booking?.check_in ?? '')} → ${esc(booking?.check_out ?? '')}</li>
<li>Guest: ${esc(booking?.holder_first_name ?? '')} ${esc(booking?.holder_last_name ?? '')} &lt;${esc(booking?.holder_email ?? '')}&gt;</li>
<li>Amount paid: $${esc(booking?.charge_amount ?? '-')}</li>
</ul>
${markedForReview ? '<p><b>The booking is now "needs attention" in Booking Desk.</b> No money was moved automatically. Check the booking in the LiteAPI dashboard, then refund or contact the guest.</p>' : ''}
${booking ? '' : '<p>No matching Flynoom booking was found.</p>'}
<pre style="font-size:11px;white-space:pre-wrap">${esc(JSON.stringify(body, null, 2)).slice(0, 6000)}</pre>`,
  }).catch(() => false);
}