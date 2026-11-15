// supabase/functions/liteapi-cancel/index.ts
//
// المرحلة 6 من الانتقال إلى LiteAPI: إلغاء حجز LiteAPI مؤكد + استرداد المبلغ المستحق
// للزبون عبر Stripe. نفس منطق hotelbeds-cancel وبنفس شكل الطلب والرد.
//
// mode = 'quote'   → رسوم الإلغاء والمبلغ المسترد (بدون إلغاء). يتأكد من LiteAPI
//                    (GET /bookings/{id}) أن الحجز ما زال مؤكدًا.
// mode = 'confirm' → PUT /bookings/{id} عند LiteAPI، ثم الاسترداد عبر Stripe.
//
// حساب الرسوم: من سياسة الإلغاء المحفوظة وقت الحجز (prepare): نسبة رسوم المورّد
// من الجملة × ما دفعه الزبون. قبل أول موعد رسوم → استرداد كامل.
// إن أعاد LiteAPI رسومًا أعلى مما في السياسة المحفوظة نسجّلها وننبّه المدير
// (الزبون يُعامل حسب السياسة التي رآها ووافق عليها).
//
// من يستطيع الإلغاء: صاحب الحجز، أو المدير (public.is_admin()) نيابة عنه.
//
// المدخلات: { bookingId, mode: 'quote' | 'confirm' }

import Stripe from 'npm:stripe@14.21.0';
import { adminClient, corsHeaders, fail, getUser, ok, round2, toNum } from '../_shared/hotelbeds.ts';
import { LITEAPI_BOOK, liteapi } from '../_shared/liteapi.ts';
import { cancellationEmail, sendEmail } from '../_shared/email.ts';

const stripe = new Stripe(Deno.env.get('STRIPE_SECRET_KEY') ?? '', {
  apiVersion: '2023-10-16',
  httpClient: Stripe.createFetchHttpClient(),
});

const SUPABASE_URL = Deno.env.get('SUPABASE_URL') ?? '';
const SUPABASE_ANON_KEY = Deno.env.get('SUPABASE_ANON_KEY') ?? '';
const ADMIN_EMAIL = Deno.env.get('ADMIN_EMAIL') ?? 'ali@flynoom.com';

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

/// رسوم الإلغاء على الزبون الآن (USD) حسب السياسة المحفوظة (نفس hotelbeds-cancel).
function computeFee(booking: any, now = new Date()) {
  const charge = Number(booking.charge_amount) || 0;
  const net = Number(booking.supplier_net) || 0;
  const policies: any[] = Array.isArray(booking.cancellation_policies) ? booking.cancellation_policies : [];
  let supplierFee = 0;
  for (const p of policies) {
    const from = new Date(p.from);
    if (!Number.isNaN(from.getTime()) && from <= now) supplierFee = Math.max(supplierFee, toNum(p.amount) ?? 0);
  }
  const ratio = net > 0 ? Math.min(1, Math.max(0, supplierFee / net)) : supplierFee > 0 ? 1 : 0;
  const fee = Math.min(charge, Math.ceil(charge * ratio * 100) / 100);
  return { fee: round2(fee), refund: round2(charge - fee), supplierFee };
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
    const actingAsAdmin = await isAdminRequest(req);

    let q = admin.from('bookings').select('*').eq('id', bookingId);
    if (!actingAsAdmin) q = q.eq('user_id', user.id);
    const { data: booking } = await q.maybeSingle();

    if (!booking || booking.supplier !== 'liteapi') return fail('not_found', 'Booking not found.');
    if (booking.status === 'cancelled') {
      return ok({ status: 'cancelled', refund: Number(booking.refund_amount) || 0 });
    }
    if (booking.status !== 'confirmed' || !booking.supplier_reference) {
      return fail('invalid_state', 'This booking cannot be cancelled online. Please contact support.');
    }

    const ref = String(booking.supplier_reference);
    const { fee, refund, supplierFee } = computeFee(booking);

    // ───── عرض الرسوم فقط ─────
    if (mode === 'quote') {
      const r = await liteapi(`${LITEAPI_BOOK}/bookings/${encodeURIComponent(ref)}`, { method: 'GET' }, 20000)
        .catch(() => null);
      const st = String(r?.data?.data?.status ?? '').toUpperCase();
      if (!r || r.status !== 200 || (st && st !== 'CONFIRMED')) {
        console.log(`CANCEL QUOTE ${booking.client_reference}: HTTP ${r?.status ?? '-'} status=${st || '-'}`);
        return fail('not_cancellable', 'This booking cannot be cancelled online. Please contact support.');
      }
      return ok({ status: 'quote', chargeAmount: Number(booking.charge_amount), fee, refund, currency: 'USD' });
    }

    // ───── الإلغاء الفعلي ─────
    const { data: locked } = await admin
      .from('bookings')
      .update({ status: 'processing', updated_at: new Date().toISOString() })
      .eq('id', bookingId)
      .eq('status', 'confirmed')
      .select('id');
    if (!locked || locked.length === 0) return fail('invalid_state', 'This booking is already being processed.');

    let c: { status: number; data: any };
    try {
      c = await liteapi(`${LITEAPI_BOOK}/bookings/${encodeURIComponent(ref)}`, { method: 'PUT' }, 60000);
    } catch (e) {
      await admin.from('bookings').update({
        status: 'needs_attention',
        failure_reason: `liteapi cancel timeout/network: ${String(e)}`,
        updated_at: new Date().toISOString(),
      }).eq('id', bookingId);
      return fail('cancel_pending', 'We could not confirm the cancellation yet. We will review it and contact you.');
    }

    const d = c.data?.data ?? {};
    const cancelled = c.status === 200 && /CANCEL/i.test(String(d.status ?? ''));
    console.log(
      `LITE CANCEL ${booking.client_reference} ref=${ref} HTTP ${c.status} status=${d.status ?? '-'} ` +
        `supplierFee=${d.cancellation_fee ?? '-'} supplierRefund=${d.refund_amount ?? '-'}`,
    );
    if (!cancelled) {
      await admin.from('bookings').update({ status: 'confirmed', updated_at: new Date().toISOString() }).eq('id', bookingId);
      return fail('cancel_failed', 'The hotel could not cancel this booking. Please contact support.');
    }

    // رسوم المورّد الفعلية أعلى من السياسة المحفوظة → تنبيه للمدير (الزبون لا يتأثر).
    const actualSupplierFee = toNum(d.cancellation_fee);
    if (actualSupplierFee != null && actualSupplierFee > supplierFee + 0.5) {
      await sendEmail(ADMIN_EMAIL, {
        subject: `Cancellation fee mismatch: ${booking.client_reference}`,
        html: `<p>LiteAPI charged a cancellation fee of $${actualSupplierFee} on booking ${ref} (${booking.client_reference}), ` +
          `but the saved policy gave $${supplierFee}. The customer was refunded according to the saved policy ($${refund}).</p>`,
      }).catch(() => false);
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

    const cancellationReference = d.cancellationId ?? d.cancellation_id ?? null;
    await admin.from('bookings').update({
      status: refundError ? 'needs_attention' : 'cancelled',
      cancelled_at: new Date().toISOString(),
      cancellation_reference: cancellationReference,
      cancellation_fee: fee,
      refund_amount: refundError ? 0 : refund,
      refund_id: refundId,
      failure_reason: refundError ? `refund failed: ${refundError}` : null,
      cancelled_by: user.id,
      updated_at: new Date().toISOString(),
    }).eq('id', bookingId);

    console.log(
      `BOOKING CANCELLED ${booking.client_reference} liteapi=${ref} fee=${fee} refund=${refund} USD` +
        (actingAsAdmin && booking.user_id !== user.id ? ` BY_ADMIN=${user.id}` : ''),
    );

    if (!refundError) {
      await sendEmail(
        booking.holder_email,
        cancellationEmail({ ...booking, cancellation_reference: cancellationReference }, fee, refund),
      );
    }

    return ok({
      status: refundError ? 'refund_pending' : 'cancelled',
      cancellationReference,
      fee,
      refund,
      currency: 'USD',
    });
  } catch (e) {
    console.log('liteapi-cancel error', String(e));
    return fail('server_error', 'Something went wrong. Please try again.');
  }
});
