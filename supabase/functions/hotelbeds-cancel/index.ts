// supabase/functions/hotelbeds-cancel/index.ts
//
// إلغاء حجز HotelBeds مؤكد + استرداد المبلغ المستحق للعميل عبر Stripe.
//
// mode = 'quote'   → يعرض للعميل رسوم الإلغاء والمبلغ المسترد (بدون أي إلغاء).
//                    يتحقق أيضًا عبر SIMULATION أن HotelBeds تقبل الإلغاء.
// mode = 'confirm' → يلغي عند HotelBeds (CANCELLATION)، ثم يسترد المبلغ عبر Stripe.
//
// حساب الرسوم: من سياسة الإلغاء المحفوظة وقت الحجز (بعملة HotelBeds وعلى
// التكلفة الصافية). نسبة الخسارة = رسوم المورد ÷ التكلفة الصافية، وتُطبَّق
// نفس النسبة على ما دفعه العميل. قبل أول موعد رسوم → استرداد كامل.
//
// المدخلات: { bookingId, mode: 'quote' | 'confirm' }

import Stripe from 'npm:stripe@14.21.0';
import {
  adminClient,
  corsHeaders,
  fail,
  fetchWithTimeout,
  getUser,
  HOTELBEDS_BASE_URL,
  hotelbedsHeaders,
  ok,
  round2,
  toNum,
} from '../_shared/hotelbeds.ts';
import { cancellationEmail, sendEmail } from '../_shared/email.ts';

const stripe = new Stripe(Deno.env.get('STRIPE_SECRET_KEY') ?? '', {
  apiVersion: '2023-10-16',
  httpClient: Stripe.createFetchHttpClient(),
});

const CANCEL_TIMEOUT_MS = 65000;

/// رسوم الإلغاء على العميل الآن (USD) حسب السياسة المحفوظة.
function computeFee(booking: any, now = new Date()) {
  const charge = Number(booking.charge_amount) || 0;
  const net = Number(booking.supplier_net) || 0;
  const policies: any[] = Array.isArray(booking.cancellation_policies)
    ? booking.cancellation_policies
    : [];

  // أعلى رسوم سارية الآن (السياسات تراكمية: كل موعد يحدد المبلغ من بعده).
  let supplierFee = 0;
  for (const p of policies) {
    const from = new Date(p.from);
    if (!Number.isNaN(from.getTime()) && from <= now) {
      supplierFee = Math.max(supplierFee, toNum(p.amount) ?? 0);
    }
  }

  const ratio = net > 0 ? Math.min(1, Math.max(0, supplierFee / net)) : supplierFee > 0 ? 1 : 0;
  const fee = Math.min(charge, Math.ceil(charge * ratio * 100) / 100);
  const refund = round2(charge - fee);
  return { fee: round2(fee), refund, supplierFee };
}

async function hotelbedsCancel(reference: string, flag: 'SIMULATION' | 'CANCELLATION') {
  const res = await fetchWithTimeout(
    `${HOTELBEDS_BASE_URL}/hotel-api/1.0/bookings/${encodeURIComponent(reference)}` +
      `?cancellationFlag=${flag}&language=ENG`,
    { method: 'DELETE', headers: await hotelbedsHeaders() },
    CANCEL_TIMEOUT_MS,
  );
  const data = await res.json().catch(() => ({}));
  return { res, data };
}

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders });

  const admin = adminClient();
  try {
    const user = await getUser(req, admin);
    if (!user) return fail('unauthorized', 'Please sign in.');

    const body = await req.json();
    const bookingId = String(body.bookingId ?? '');
    const mode = body.mode === 'confirm' ? 'confirm' : 'quote';

    const { data: booking } = await admin
      .from('bookings')
      .select('*')
      .eq('id', bookingId)
      .eq('user_id', user.id)
      .maybeSingle();

    if (!booking || booking.supplier !== 'hotelbeds') return fail('not_found', 'Booking not found.');
    if (booking.status === 'cancelled') {
      return ok({ status: 'cancelled', refund: Number(booking.refund_amount) || 0 });
    }
    if (booking.status !== 'confirmed' || !booking.supplier_reference) {
      return fail('invalid_state', 'This booking cannot be cancelled online. Please contact support.');
    }

    const { fee, refund, supplierFee } = computeFee(booking);

    // ───── عرض الرسوم فقط ─────
    if (mode === 'quote') {
      const sim = await hotelbedsCancel(booking.supplier_reference, 'SIMULATION').catch(() => null);
      if (!sim || !sim.res.ok) {
        console.log('Cancel SIMULATION failed', booking.supplier_reference, JSON.stringify(sim?.data ?? {}));
        return fail('not_cancellable', 'This booking cannot be cancelled online. Please contact support.');
      }
      return ok({
        status: 'quote',
        chargeAmount: Number(booking.charge_amount),
        fee,
        refund,
        currency: 'USD',
      });
    }

    // ───── الإلغاء الفعلي ─────
    const { data: locked } = await admin
      .from('bookings')
      .update({ status: 'processing', updated_at: new Date().toISOString() })
      .eq('id', bookingId)
      .eq('status', 'confirmed')
      .select('id');
    if (!locked || locked.length === 0) return fail('invalid_state', 'This booking is already being processed.');

    let cancel;
    try {
      cancel = await hotelbedsCancel(booking.supplier_reference, 'CANCELLATION');
    } catch (e) {
      // حالة غير معروفة → مراجعة يدوية.
      await admin.from('bookings').update({
        status: 'needs_attention',
        failure_reason: `cancel timeout/network: ${String(e)}`,
        updated_at: new Date().toISOString(),
      }).eq('id', bookingId);
      return fail('cancel_pending', 'We could not confirm the cancellation yet. We will review it and contact you.');
    }

    const hb = cancel.data?.booking;
    if (!cancel.res.ok || hb?.status !== 'CANCELLED') {
      console.log('CANCEL FAILED', booking.supplier_reference, JSON.stringify(cancel.data));
      await admin.from('bookings').update({
        status: 'confirmed', // لم يُلغَ — نعيده كما كان
        updated_at: new Date().toISOString(),
      }).eq('id', bookingId);
      return fail('cancel_failed', 'The hotel could not cancel this booking. Please contact support.');
    }

    // ───── الاسترداد ─────
    let refundId: string | null = null;
    let refundError: string | null = null;
    if (refund > 0 && booking.payment_intent_id) {
      try {
        const r = await stripe.refunds.create({
          payment_intent: booking.payment_intent_id,
          amount: Math.round(refund * 100),
          metadata: { booking_id: bookingId, client_reference: booking.client_reference ?? '' },
        });
        refundId = r.id;
      } catch (e) {
        refundError = String(e);
        console.log('REFUND FAILED', bookingId, refundError);
      }
    }

    await admin.from('bookings').update({
      status: refundError ? 'needs_attention' : 'cancelled',
      cancelled_at: new Date().toISOString(),
      cancellation_reference: hb.cancellationReference ?? null,
      cancellation_fee: fee,
      refund_amount: refundError ? 0 : refund,
      refund_id: refundId,
      failure_reason: refundError ? `refund failed: ${refundError}` : null,
      updated_at: new Date().toISOString(),
    }).eq('id', bookingId);

    console.log(
      `BOOKING CANCELLED ${booking.client_reference} ref=${booking.supplier_reference} ` +
        `supplierFee=${supplierFee} fee=${fee} refund=${refund} USD`,
    );

    // بريد تأكيد الإلغاء (فشله لا يؤثر على الإلغاء).
    if (!refundError) {
      await sendEmail(
        booking.holder_email,
        cancellationEmail({ ...booking, cancellation_reference: hb.cancellationReference ?? null }, fee, refund),
      );
    }

    return ok({
      status: refundError ? 'refund_pending' : 'cancelled',
      cancellationReference: hb.cancellationReference ?? null,
      fee,
      refund,
      currency: 'USD',
    });
  } catch (e) {
    console.log('hotelbeds-cancel error', String(e));
    return fail('server_error', 'Something went wrong. Please try again.');
  }
});