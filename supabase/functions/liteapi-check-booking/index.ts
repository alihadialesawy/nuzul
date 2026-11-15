// supabase/functions/liteapi-check-booking/index.ts
//
// "Check with LiteAPI" — للمدير فقط، من مكتب الحجوزات (المرحلة 6 من الانتقال إلى LiteAPI).
// نفس hotelbeds-check-booking تمامًا (نفس الإجراءات ونفس شكل الرد)، والمورّد LiteAPI:
// يسأل LiteAPI عن الحجز (برقمه، أو برقم Flynoom = clientReference)، ويقرأ حالة الدفع
// في Stripe، ثم يقترح إجراءً واحدًا:
//   capture_and_confirm / release_and_fail / mark_confirmed / mark_failed / manual / wait
//
// المدخلات: { bookingId, mode: 'check' | 'apply', expectAction?, notifyGuest? }
//
// النشر (تحتاج تسجيل الدخول):
//   supabase functions deploy liteapi-check-booking --project-ref nomgbttkfzhgbmbyidpy

import Stripe from 'npm:stripe@14.21.0';
import { adminClient, corsHeaders, fail, getUser, ok } from '../_shared/hotelbeds.ts';
import { LITEAPI_BOOK, liteapi, liteHotelBasics } from '../_shared/liteapi.ts';
import { bookingConfirmationEmail, bookingNotCompletedEmail, sendEmail } from '../_shared/email.ts';

const stripe = new Stripe(Deno.env.get('STRIPE_SECRET_KEY') ?? '', {
  apiVersion: '2023-10-16',
  httpClient: Stripe.createFetchHttpClient(),
});

const SUPABASE_URL = Deno.env.get('SUPABASE_URL') ?? '';
const SUPABASE_ANON_KEY = Deno.env.get('SUPABASE_ANON_KEY') ?? '';

/// لا نحكم بأن الحجز "غير موجود" قبل مرور هذه المدة على إنشائه.
const MIN_AGE_FOR_NOT_FOUND_MS = 10 * 60 * 1000;
/// حجز processing أحدث من هذا قد يكون ما زال قيد التنفيذ في liteapi-book.
const PROCESSING_STALE_MS = 3 * 60 * 1000;

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

type HbLookup =
  | { kind: 'found'; reference: string; status: string; detail: any }
  | { kind: 'not_found' }
  | { kind: 'error'; message: string };

/// حجز LiteAPI برقمه.
async function liteDetail(reference: string): Promise<HbLookup> {
  try {
    const r = await liteapi(`${LITEAPI_BOOK}/bookings/${encodeURIComponent(reference)}`, { method: 'GET' }, 30000);
    const d = r.data?.data;
    if (r.status === 200 && d) {
      return { kind: 'found', reference, status: String(d.status ?? 'UNKNOWN').toUpperCase(), detail: r.data };
    }
    if (r.status === 404) return { kind: 'not_found' };
    return { kind: 'error', message: `LiteAPI HTTP ${r.status}: ${JSON.stringify(r.data?.error ?? r.data).slice(0, 200)}` };
  } catch (e) {
    return { kind: 'error', message: `LiteAPI did not respond: ${String(e)}` };
  }
}

/// البحث برقم Flynoom (clientReference) — عندما لم يصلنا رقم حجز LiteAPI (مهلة/خطأ).
async function liteFindByClientReference(clientReference: string): Promise<HbLookup> {
  try {
    const r = await liteapi(
      `${LITEAPI_BOOK}/bookings?${new URLSearchParams({ clientReference })}`,
      { method: 'GET' },
      30000,
    );
    if (r.status === 404) return { kind: 'not_found' };
    if (r.status !== 200) {
      return { kind: 'error', message: `LiteAPI list HTTP ${r.status}: ${JSON.stringify(r.data?.error ?? r.data).slice(0, 200)}` };
    }
    const list: any[] = Array.isArray(r.data?.data) ? r.data.data : [];
    const wanted = clientReference.toUpperCase();
    const match = list.find((b) => String(b?.clientReference ?? '').toUpperCase() === wanted);
    if (!match?.bookingId) return { kind: 'not_found' };
    return liteDetail(String(match.bookingId));
  } catch (e) {
    return { kind: 'error', message: `LiteAPI did not respond: ${String(e)}` };
  }
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

  // ───── LiteAPI ─────
  const lookup: HbLookup = booking.supplier_reference
    ? await liteDetail(String(booking.supplier_reference))
    : await liteFindByClientReference(String(booking.client_reference));

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
      message: `Could not reach LiteAPI (${lookup.message}). Nothing was changed. Try again in a few minutes.`,
    };
  }

  if (lookup.kind === 'found' && lookup.status === 'CONFIRMED') {
    if (held) {
      return { ...base, action: 'capture_and_confirm', finding: 'confirmed',
        message: `LiteAPI has this booking CONFIRMED (ref ${lookup.reference}). The card is still on hold. ` +
          'Applying will capture the payment, mark it confirmed, and email the guest their confirmation.' };
    }
    if (captured) {
      return { ...base, action: 'mark_confirmed', finding: 'confirmed',
        message: `LiteAPI has this booking CONFIRMED (ref ${lookup.reference}) and the payment was already captured. ` +
          'Applying will mark it confirmed and email the guest their confirmation.' };
    }
    return { ...base, action: 'manual', finding: 'confirmed',
      message: `CONFLICT: LiteAPI has this booking CONFIRMED (ref ${lookup.reference}), but the payment is "${paymentStatus ?? 'unknown'}" — ` +
        'we cannot collect it. Contact the guest, or cancel it in the LiteAPI dashboard before the free-cancellation deadline.' };
  }

  // غير موجود أو ملغى عند LiteAPI.
  const finding = lookup.kind === 'found' ? 'cancelled_at_supplier' : 'not_found';
  const what = lookup.kind === 'found'
    ? `LiteAPI shows this booking as ${lookup.status} (ref ${lookup.reference})`
    : 'LiteAPI has no booking with this Flynoom reference';

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
    if (!booking || booking.supplier !== 'liteapi') return fail('not_found', 'Booking not found.');

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
          return fail('capture_failed', `LiteAPI confirmed it, but capturing the payment failed: ${String(e)}`);
        }
      }
      const d = a.detail?.data ?? {};
      const basics = await liteHotelBasics(String(booking.hotel_code ?? '')).catch(() => null);
      const address = basics
        ? [basics.address, basics.city, basics.countryCode].filter((s) => s && String(s).trim()).join(', ') || null
        : null;
      await setFields({
        status: 'confirmed',
        failure_reason: null,
        supplier_reference: a.hbReference,
        supplier_name: d.supplierBookingName ?? d.supplier ?? booking.supplier_name ?? null,
        hotel_confirmation_code: d.hotelConfirmationCode ?? booking.hotel_confirmation_code ?? null,
        supplier_response: a.detail ?? booking.supplier_response,
        hotel_address: address ?? booking.hotel_address ?? null,
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
      ? `checked: ${a.hbStatus} at LiteAPI (ref ${a.hbReference}); payment released`
      : 'checked: not found at LiteAPI; payment released';
    await setFields({ status: 'failed', failure_reason: reason });
    let emailed = false;
    if (notifyGuest) emailed = await sendEmail(booking.holder_email, bookingNotCompletedEmail(booking));
    console.log(`CHECK FAILED-CLOSED ${booking.client_reference} emailed=${emailed}`);
    return ok({ ...summary, result: 'failed', emailed });
  } catch (e) {
    console.log('liteapi-check-booking error', String(e));
    return fail('server_error', 'Something went wrong. Please try again.');
  }
});
