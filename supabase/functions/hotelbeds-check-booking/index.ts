// supabase/functions/hotelbeds-check-booking/index.ts
//
// "Check with HotelBeds" — للمدير فقط، من مكتب الحجوزات.
//
// لحجز حالته needs_attention (أو processing عالق): يسأل HotelBeds هل الحجز
// موجود فعلًا، ويقرأ حالة الدفع في Stripe، ثم يقترح إجراءً واحدًا:
//
//   capture_and_confirm : الحجز CONFIRMED عند HotelBeds والمبلغ محجوز
//                         → سحب المبلغ + confirmed + بريد التأكيد للعميل.
//   release_and_fail    : الحجز غير موجود (أو ملغى) عند HotelBeds والمبلغ محجوز
//                         → إلغاء حجز المبلغ + failed + بريد "لم يكتمل الحجز".
//   mark_confirmed      : مؤكد عند HotelBeds والمبلغ مسحوب مسبقًا → confirmed فقط.
//   mark_failed         : غير موجود والمبلغ ملغى مسبقًا في Stripe → failed فقط.
//   manual              : تعارض (مثلًا: مؤكد عند الفندق لكن المبلغ أُلغي) → يدوي.
//   wait                : HotelBeds لم ترد، أو الحجز حديث جدًا → حاول لاحقًا.
//
// المدخلات: { bookingId, mode: 'check' | 'apply', expectAction?, notifyGuest? }
//   check : يفحص فقط ولا يغيّر شيئًا.
//   apply : يعيد الفحص من جديد على السيرفر، ولا ينفّذ إلا إذا كان الإجراء
//           المحسوب = expectAction (ما رآه المدير وأكّده).
//
// النشر (تحتاج تسجيل الدخول، فلا تستخدم --no-verify-jwt):
//   supabase functions deploy hotelbeds-check-booking --project-ref nomgbttkfzhgbmbyidpy

import Stripe from 'npm:stripe@14.21.0';
import {
  adminClient,
  corsHeaders,
  fail,
  fetchHotelContact,
  fetchWithTimeout,
  getUser,
  HOTELBEDS_BASE_URL,
  hotelbedsHeaders,
  ok,
} from '../_shared/hotelbeds.ts';
import { bookingConfirmationEmail, bookingNotCompletedEmail, sendEmail } from '../_shared/email.ts';

const stripe = new Stripe(Deno.env.get('STRIPE_SECRET_KEY') ?? '', {
  apiVersion: '2023-10-16',
  httpClient: Stripe.createFetchHttpClient(),
});

const SUPABASE_URL = Deno.env.get('SUPABASE_URL') ?? '';
const SUPABASE_ANON_KEY = Deno.env.get('SUPABASE_ANON_KEY') ?? '';

/// لا نحكم بأن الحجز "غير موجود" قبل مرور هذه المدة على إنشائه:
/// قائمة الحجوزات عند HotelBeds قد تتأخر قليلًا في إظهار حجز جديد.
const MIN_AGE_FOR_NOT_FOUND_MS = 10 * 60 * 1000;
/// حجز processing أحدث من هذا قد يكون ما زال قيد التنفيذ في hotelbeds-book.
const PROCESSING_STALE_MS = 3 * 60 * 1000;

/// هل صاحب الطلب مدير؟ public.is_admin() بتوكن المستخدم نفسه.
async function isAdminRequest(req: Request): Promise<boolean> {
  const auth = req.headers.get('Authorization') ?? '';
  if (!auth || !SUPABASE_URL || !SUPABASE_ANON_KEY) return false;
  try {
    const res = await fetch(`${SUPABASE_URL}/rest/v1/rpc/is_admin`, {
      method: 'POST',
      headers: { apikey: SUPABASE_ANON_KEY, Authorization: auth, 'Content-Type': 'application/json' },
      body: '{}',
    });
    if (!res.ok) return false;
    return (await res.json()) === true;
  } catch {
    return false;
  }
}

function ymd(d: Date): string {
  return d.toISOString().slice(0, 10);
}

type HbLookup =
  | { kind: 'found'; reference: string; status: string; detail: any }
  | { kind: 'not_found' }
  | { kind: 'error'; message: string };

/// تفاصيل حجز برقم HotelBeds.
async function hbDetail(reference: string): Promise<{ ok: boolean; status: number; data: any }> {
  try {
    const res = await fetchWithTimeout(
      `${HOTELBEDS_BASE_URL}/hotel-api/1.0/bookings/${encodeURIComponent(reference)}?language=ENG`,
      { method: 'GET', headers: await hotelbedsHeaders() },
      30000,
    );
    const data = await res.json().catch(() => ({}));
    return { ok: res.ok, status: res.status, data };
  } catch (e) {
    return { ok: false, status: 0, data: { error: { message: String(e) } } };
  }
}

/// قائمة حجوزات HotelBeds حسب تاريخ الإنشاء، والبحث فيها عن clientReference.
async function hbFindByClientReference(clientReference: string, createdAt: Date): Promise<HbLookup> {
  const start = new Date(createdAt.getTime() - 86400000);
  const endCandidate = new Date(createdAt.getTime() + 86400000);
  const today = new Date();
  const ranges = [
    [ymd(start), ymd(endCandidate)],
    [ymd(start), ymd(endCandidate < today ? endCandidate : today)],
  ];
  const wanted = clientReference.toUpperCase();
  let lastError = '';

  for (const [s, e] of ranges) {
    let from = 1;
    let rangeFailed = false;
    for (let page = 0; page < 10; page++) {
      const to = from + 99;
      const qs = new URLSearchParams({
        start: s,
        end: e,
        filterType: 'CREATION',
        status: 'ALL',
        from: String(from),
        to: String(to),
        clientReference,
      });
      let res: Response;
      try {
        res = await fetchWithTimeout(
          `${HOTELBEDS_BASE_URL}/hotel-api/1.0/bookings?${qs}`,
          { method: 'GET', headers: await hotelbedsHeaders() },
          30000,
        );
      } catch (err) {
        return { kind: 'error', message: `HotelBeds did not respond: ${String(err)}` };
      }
      const data = await res.json().catch(() => ({}));
      if (!res.ok) {
        lastError = `HotelBeds list HTTP ${res.status}: ${data?.error?.message ?? ''}`;
        console.log('BOOKING LIST FAILED', s, e, lastError);
        rangeFailed = true;
        break;
      }
      const container = data?.bookings ?? {};
      const list: any[] = Array.isArray(container) ? container : (container.bookings ?? []);
      const match = list.find((b) => String(b?.clientReference ?? '').toUpperCase() === wanted);
      if (match?.reference) {
        const detail = await hbDetail(String(match.reference));
        const booking = detail.ok ? detail.data?.booking : null;
        return {
          kind: 'found',
          reference: String(match.reference),
          status: String(booking?.status ?? match.status ?? 'UNKNOWN').toUpperCase(),
          detail: detail.ok ? detail.data : { booking: match },
        };
      }
      const total = Number(container.total ?? list.length);
      if (list.length < 100 || to >= total) return { kind: 'not_found' };
      from = to + 1;
    }
    if (!rangeFailed) return { kind: 'not_found' };
  }
  return { kind: 'error', message: lastError || 'HotelBeds booking list failed.' };
}

type Action =
  | 'capture_and_confirm'
  | 'release_and_fail'
  | 'mark_confirmed'
  | 'mark_failed'
  | 'manual'
  | 'wait';

interface Assessment {
  action: Action;
  finding: 'confirmed' | 'cancelled_at_supplier' | 'not_found' | 'unknown';
  hbReference: string | null;
  hbStatus: string | null;
  paymentStatus: string | null;
  message: string;
  detail: any;
}

async function assess(booking: any): Promise<Assessment> {
  // ───── Stripe ─────
  let paymentStatus: string | null = null;
  if (booking.payment_intent_id) {
    try {
      const intent = await stripe.paymentIntents.retrieve(booking.payment_intent_id);
      paymentStatus = intent.status;
    } catch (e) {
      console.log('Stripe retrieve failed', String(e));
    }
  }
  const held = paymentStatus === 'requires_capture';
  const captured = paymentStatus === 'succeeded';
  const released = paymentStatus === 'canceled';

  // ───── HotelBeds ─────
  let lookup: HbLookup;
  if (booking.supplier_reference) {
    const d = await hbDetail(String(booking.supplier_reference));
    if (d.ok && d.data?.booking) {
      lookup = {
        kind: 'found',
        reference: String(booking.supplier_reference),
        status: String(d.data.booking.status ?? 'UNKNOWN').toUpperCase(),
        detail: d.data,
      };
    } else if (d.status === 404) {
      lookup = { kind: 'not_found' };
    } else {
      lookup = { kind: 'error', message: `HotelBeds detail HTTP ${d.status}: ${d.data?.error?.message ?? ''}` };
    }
  } else {
    lookup = await hbFindByClientReference(String(booking.client_reference), new Date(booking.created_at));
  }

  const base = {
    hbReference: lookup.kind === 'found' ? lookup.reference : null,
    hbStatus: lookup.kind === 'found' ? lookup.status : null,
    paymentStatus,
    detail: lookup.kind === 'found' ? lookup.detail : null,
  };

  if (lookup.kind === 'error') {
    return {
      ...base,
      action: 'wait',
      finding: 'unknown',
      message: `Could not reach HotelBeds (${lookup.message}). Nothing was changed. Try again in a few minutes.`,
    };
  }

  if (lookup.kind === 'found' && lookup.status === 'CONFIRMED') {
    if (held) {
      return { ...base, action: 'capture_and_confirm', finding: 'confirmed',
        message: `HotelBeds has this booking CONFIRMED (ref ${lookup.reference}). The card is still on hold. ` +
          'Applying will capture the payment, mark it confirmed, and email the guest their confirmation.' };
    }
    if (captured) {
      return { ...base, action: 'mark_confirmed', finding: 'confirmed',
        message: `HotelBeds has this booking CONFIRMED (ref ${lookup.reference}) and the payment was already captured. ` +
          'Applying will mark it confirmed and email the guest their confirmation.' };
    }
    return { ...base, action: 'manual', finding: 'confirmed',
      message: `CONFLICT: HotelBeds has this booking CONFIRMED (ref ${lookup.reference}), but the payment is "${paymentStatus ?? 'unknown'}" — ` +
        'we cannot collect it. Contact the guest, or cancel it at HotelBeds before the free-cancellation deadline.' };
  }

  // غير موجود أو ملغى عند HotelBeds.
  const finding = lookup.kind === 'found' ? 'cancelled_at_supplier' : 'not_found';
  const what = lookup.kind === 'found'
    ? `HotelBeds shows this booking as ${lookup.status} (ref ${lookup.reference})`
    : 'HotelBeds has no booking with this Flynoom reference';

  const ageMs = Date.now() - new Date(booking.created_at).getTime();
  if (lookup.kind === 'not_found' && ageMs < MIN_AGE_FOR_NOT_FOUND_MS) {
    return { ...base, action: 'wait', finding,
      message: `${what} yet, but the booking is only ${Math.round(ageMs / 60000)} min old. ` +
        'Wait at least 10 minutes and check again before releasing the payment.' };
  }
  if (held) {
    return { ...base, action: 'release_and_fail', finding,
      message: `${what}. The card is still on hold. Applying will release the hold (the guest is not charged), ` +
        'mark it failed, and email the guest that the booking could not be completed.' };
  }
  if (released) {
    return { ...base, action: 'mark_failed', finding,
      message: `${what}, and the card hold was already released in Stripe. Applying will mark it failed.` };
  }
  return { ...base, action: 'manual', finding,
    message: `CONFLICT: ${what}, but the payment is "${paymentStatus ?? 'unknown'}". ` +
      (captured ? 'The guest was charged with no hotel booking — refund them in Stripe.' : 'Check Stripe manually.') };
}

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders });

  const admin = adminClient();
  try {
    const user = await getUser(req, admin);
    if (!user) return fail('unauthorized', 'Please sign in.');
    if (!(await isAdminRequest(req))) return fail('forbidden', 'Admins only.');

    const body = await req.json().catch(() => ({}));
    const bookingId = String(body.bookingId ?? '');
    const mode = body.mode === 'apply' ? 'apply' : 'check';
    const notifyGuest = body.notifyGuest !== false;

    const { data: booking } = await admin.from('bookings').select('*').eq('id', bookingId).maybeSingle();
    if (!booking || booking.supplier !== 'hotelbeds') return fail('not_found', 'Booking not found.');

    if (!['needs_attention', 'processing'].includes(booking.status)) {
      return fail('invalid_state', `This booking is "${booking.status}" — nothing to check.`);
    }
    if (booking.status === 'processing') {
      const age = Date.now() - new Date(booking.updated_at ?? booking.created_at).getTime();
      if (age < PROCESSING_STALE_MS) {
        return fail('still_processing', 'This booking is still being processed. Try again in a few minutes.');
      }
    }

    const a = await assess(booking);
    console.log(
      `CHECK ${booking.client_reference} mode=${mode} action=${a.action} finding=${a.finding} ` +
        `hb=${a.hbReference ?? '-'}/${a.hbStatus ?? '-'} payment=${a.paymentStatus ?? '-'} by_admin=${user.id}`,
    );

    const summary = {
      action: a.action,
      finding: a.finding,
      hbReference: a.hbReference,
      hbStatus: a.hbStatus,
      paymentStatus: a.paymentStatus,
      message: a.message,
    };

    if (mode === 'check') return ok(summary);

    // ───── apply ─────
    if (String(body.expectAction ?? '') !== a.action) {
      return fail('changed', 'The situation changed since you checked. Please check again.', { check: summary });
    }
    if (a.action === 'manual' || a.action === 'wait') {
      return fail('not_applicable', a.message, { check: summary });
    }

    // قفل: لا يُنفَّذ مرتين لو ضغط المدير مرتين.
    const { data: locked } = await admin
      .from('bookings')
      .update({ status: 'processing', updated_at: new Date().toISOString() })
      .eq('id', bookingId)
      .eq('status', booking.status)
      .select('id');
    if (!locked || locked.length === 0) return fail('changed', 'Booking changed meanwhile. Refresh and check again.');

    const setFields = (fields: Record<string, unknown>) =>
      admin.from('bookings').update({ ...fields, resolved_by: user.id, updated_at: new Date().toISOString() }).eq('id', bookingId);

    if (a.action === 'capture_and_confirm' || a.action === 'mark_confirmed') {
      if (a.action === 'capture_and_confirm') {
        try {
          await stripe.paymentIntents.capture(booking.payment_intent_id);
        } catch (e) {
          console.log(`CHECK CAPTURE FAILED ${booking.client_reference}:`, String(e));
          await setFields({ status: 'needs_attention', failure_reason: `capture failed after check: ${String(e)}` });
          return fail('capture_failed', `HotelBeds confirmed it, but capturing the payment failed: ${String(e)}`);
        }
      }
      const hb = a.detail?.booking ?? {};
      const contact = await fetchHotelContact(String(booking.hotel_code ?? hb.hotel?.code ?? ''));
      await setFields({
        status: 'confirmed',
        failure_reason: null,
        supplier_reference: a.hbReference,
        supplier_name: hb.hotel?.supplier?.name ?? booking.supplier_name ?? null,
        supplier_vat: hb.hotel?.supplier?.vatNumber ?? booking.supplier_vat ?? null,
        supplier_response: a.detail ?? booking.supplier_response,
        hotel_address: contact.address ?? booking.hotel_address ?? null,
        hotel_phone: contact.phone ?? booking.hotel_phone ?? null,
      });
      let emailed = false;
      if (notifyGuest) {
        const { data: fresh } = await admin.from('bookings').select('*').eq('id', bookingId).maybeSingle();
        if (fresh) emailed = await sendEmail(fresh.holder_email, bookingConfirmationEmail(fresh));
      }
      console.log(`CHECK CONFIRMED ${booking.client_reference} ref=${a.hbReference} emailed=${emailed}`);
      return ok({ ...summary, result: 'confirmed', emailed });
    }

    // release_and_fail / mark_failed
    if (a.action === 'release_and_fail') {
      try {
        await stripe.paymentIntents.cancel(booking.payment_intent_id);
      } catch (e) {
        console.log(`CHECK RELEASE FAILED ${booking.client_reference}:`, String(e));
        await setFields({ status: 'needs_attention', failure_reason: `release failed after check: ${String(e)}` });
        return fail('release_failed', `Could not release the card hold in Stripe: ${String(e)}`);
      }
    }
    const reason = a.finding === 'cancelled_at_supplier'
      ? `checked: ${a.hbStatus} at HotelBeds (ref ${a.hbReference}); payment released`
      : 'checked: not found at HotelBeds; payment released';
    await setFields({ status: 'failed', failure_reason: reason });
    let emailed = false;
    if (notifyGuest) emailed = await sendEmail(booking.holder_email, bookingNotCompletedEmail(booking));
    console.log(`CHECK FAILED-CLOSED ${booking.client_reference} emailed=${emailed}`);
    return ok({ ...summary, result: 'failed', emailed });
  } catch (e) {
    console.log('hotelbeds-check-booking error', String(e));
    return fail('server_error', 'Something went wrong. Please try again.');
  }
});