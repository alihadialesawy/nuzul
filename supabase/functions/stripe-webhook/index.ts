// supabase/functions/stripe-webhook/index.ts
//
// يستقبل أحداث Stripe:
//   • الاعتراضات على الدفع (charge.dispute.*).
//   • إنذار الاحتيال المبكر (radar.early_fraud_warning.created): بنك العميل
//     أبلغ أن العملية احتيالية، والنزاع غالبًا قادم. إن لم تبدأ الإقامة وكان
//     الإلغاء مجانيًا الآن → نلغي عند HotelBeds ونعيد المبلغ كاملًا تلقائيًا
//     (نتجنب النزاع ورسومه). غير ذلك → بريد للمدير ليقرر.
// • يتحقق من توقيع Stripe (STRIPE_WEBHOOK_SECRET) — أي طلب بلا توقيع صحيح يُرفض.
// • يحفظ الاعتراض في جدول disputes ويربطه بالحجز (عبر payment_intent).
// • عند اعتراض جديد: بريد فوري للمدير، ويظهر أحمر في "مهام اليوم".
//
// الإعداد (مرة واحدة):
//   1) Stripe → Developers → Webhooks → Add endpoint
//      URL: https://nomgbttkfzhgbmbyidpy.supabase.co/functions/v1/stripe-webhook
//      Events: charge.dispute.created, charge.dispute.updated, charge.dispute.closed,
//              charge.dispute.funds_withdrawn, charge.dispute.funds_reinstated,
//              radar.early_fraud_warning.created
//   2) انسخ Signing secret (whsec_...) ثم:
//      supabase secrets set STRIPE_WEBHOOK_SECRET=whsec_... --project-ref nomgbttkfzhgbmbyidpy
//   3) النشر — بدون التحقق من JWT (Stripe لا يرسل توكن Supabase):
//      supabase functions deploy stripe-webhook --no-verify-jwt --project-ref nomgbttkfzhgbmbyidpy

import Stripe from 'npm:stripe@14.21.0';
import {
  adminClient,
  fetchWithTimeout,
  HOTELBEDS_BASE_URL,
  hotelbedsHeaders,
  round2,
  toNum,
} from '../_shared/hotelbeds.ts';
import { sendEmail } from '../_shared/email.ts';
import { upsertDispute } from '../_shared/disputes.ts';

const stripe = new Stripe(Deno.env.get('STRIPE_SECRET_KEY') ?? '', {
  apiVersion: '2023-10-16',
  httpClient: Stripe.createFetchHttpClient(),
});
const cryptoProvider = Stripe.createSubtleCryptoProvider();
const WEBHOOK_SECRET = (Deno.env.get('STRIPE_WEBHOOK_SECRET') ?? '').trim();
const ADMIN_EMAIL = Deno.env.get('ADMIN_EMAIL') ?? 'ali@flynoom.com';

/// رسوم المورد السارية الآن حسب سياسة الإلغاء المحفوظة (بعملة HotelBeds).
function supplierFeeNow(booking: any, now = new Date()): number {
  const policies: any[] = Array.isArray(booking.cancellation_policies) ? booking.cancellation_policies : [];
  let fee = 0;
  for (const p of policies) {
    const from = new Date(p.from);
    if (!Number.isNaN(from.getTime()) && from <= now) fee = Math.max(fee, toNum(p.amount) ?? 0);
  }
  return fee;
}

/// إنذار الاحتيال المبكر. يرجع ما تم فعله (للسجل والبريد).
async function handleEarlyFraudWarning(efw: any): Promise<{ action: string; booking: any | null }> {
  const admin = adminClient();
  const piId = typeof efw.payment_intent === 'string' ? efw.payment_intent : efw.payment_intent?.id;
  if (!piId) return { action: 'no_payment_intent', booking: null };

  const { data: booking } = await admin.from('bookings').select('*').eq('payment_intent_id', piId).maybeSingle();
  if (!booking) return { action: 'booking_not_found', booking: null };
  if (booking.status === 'cancelled') return { action: 'already_cancelled', booking };
  if (booking.status !== 'confirmed' || !booking.supplier_reference) {
    return { action: `manual_status_${booking.status}`, booking };
  }

  const today = new Date().toISOString().slice(0, 10);
  const notStarted = String(booking.check_in ?? '') > today;
  if (!notStarted) return { action: 'manual_stay_started', booking };
  if (supplierFeeNow(booking) > 0) return { action: 'manual_cancellation_fee_applies', booking };

  // قفل (حتى لا يتزامن مع إلغاء من العميل أو إعادة إرسال Stripe للحدث).
  const { data: locked } = await admin
    .from('bookings')
    .update({ status: 'processing', updated_at: new Date().toISOString() })
    .eq('id', booking.id)
    .eq('status', 'confirmed')
    .select('id');
  if (!locked || locked.length === 0) return { action: 'busy', booking };

  let hbData: any = {};
  let hbOk = false;
  try {
    const res = await fetchWithTimeout(
      `${HOTELBEDS_BASE_URL}/hotel-api/1.0/bookings/${encodeURIComponent(booking.supplier_reference)}` +
        `?cancellationFlag=CANCELLATION&language=ENG`,
      { method: 'DELETE', headers: await hotelbedsHeaders() },
      65000,
    );
    hbData = await res.json().catch(() => ({}));
    hbOk = res.ok && hbData?.booking?.status === 'CANCELLED';
  } catch (e) {
    await admin.from('bookings').update({
      status: 'needs_attention',
      failure_reason: `EFW cancel timeout/network: ${String(e)}`,
      updated_at: new Date().toISOString(),
    }).eq('id', booking.id);
    return { action: 'cancel_unknown_needs_attention', booking };
  }

  if (!hbOk) {
    await admin.from('bookings').update({ status: 'confirmed', updated_at: new Date().toISOString() }).eq('id', booking.id);
    console.log('EFW CANCEL FAILED', booking.supplier_reference, JSON.stringify(hbData));
    return { action: 'manual_hotel_cancel_failed', booking };
  }

  const charge = round2(Number(booking.charge_amount) || 0);
  let refundId: string | null = null;
  let refundError: string | null = null;
  try {
    // reason=fraudulent: يضيف البطاقة لقوائم الحظر في Radar ويحسّن تقييمه.
    const r = await stripe.refunds.create({
      payment_intent: piId,
      reason: 'fraudulent',
      metadata: { booking_id: booking.id, client_reference: booking.client_reference ?? '', source: 'early_fraud_warning' },
    });
    refundId = r.id;
  } catch (e) {
    refundError = String(e);
  }

  await admin.from('bookings').update({
    status: refundError ? 'needs_attention' : 'cancelled',
    cancelled_at: new Date().toISOString(),
    cancellation_reference: hbData?.booking?.cancellationReference ?? null,
    cancellation_fee: 0,
    refund_amount: refundError ? 0 : charge,
    refund_id: refundId,
    failure_reason: refundError ? `EFW refund failed: ${refundError}` : 'early_fraud_warning',
    updated_at: new Date().toISOString(),
  }).eq('id', booking.id);

  return { action: refundError ? 'hotel_cancelled_refund_failed' : 'auto_cancelled_refunded', booking };
}

const h = (v: unknown) => String(v ?? '').replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;');

Deno.serve(async (req) => {
  if (req.method !== 'POST') return new Response('method not allowed', { status: 405 });
  if (!WEBHOOK_SECRET) {
    console.log('STRIPE_WEBHOOK_SECRET is not set');
    return new Response('not configured', { status: 500 });
  }

  const signature = req.headers.get('stripe-signature') ?? '';
  const body = await req.text();

  let event: Stripe.Event;
  try {
    event = await stripe.webhooks.constructEventAsync(body, signature, WEBHOOK_SECRET, undefined, cryptoProvider);
  } catch (e) {
    console.log('WEBHOOK SIGNATURE INVALID', String(e), 'secret prefix:', WEBHOOK_SECRET.slice(0, 10), 'len:', WEBHOOK_SECRET.length);
    return new Response('invalid signature', { status: 400 });
  }

  try {
    if (event.type === 'radar.early_fraud_warning.created') {
      const efw: any = event.data.object;
      const { action, booking } = await handleEarlyFraudWarning(efw);
      console.log(`EFW ${efw.id} type=${efw.fraud_type} action=${action} booking=${booking?.client_reference ?? '-'}`);

      const admin = adminClient();
      await admin.from('payment_risk_events').insert({
        booking_id: booking?.id ?? null,
        user_id: booking?.user_id ?? null,
        payment_intent_id: typeof efw.payment_intent === 'string' ? efw.payment_intent : null,
        decision: 'early_fraud_warning',
        reasons: [action, `fraud_type:${efw.fraud_type ?? ''}`],
        amount_usd: booking ? Number(booking.charge_amount) || 0 : null,
      }).then(({ error }) => error && console.log('EFW LOG FAILED', error.message));

      const auto = action === 'auto_cancelled_refunded';
      await sendEmail(ADMIN_EMAIL, {
        subject: `${auto ? '🛡️' : '⚠️'} Early fraud warning (${booking?.client_reference ?? 'unknown booking'}) — ${auto ? 'auto-cancelled & refunded' : 'ACTION NEEDED'}`,
        html: `<p>The card issuer reported this payment as fraud (${h(efw.fraud_type)}). A dispute usually follows.</p>
<ul>
<li>Booking: ${h(booking?.client_reference ?? '—')} · ${h(booking?.hotel_name ?? '')} · ${h(booking?.check_in ?? '')} → ${h(booking?.check_out ?? '')}</li>
<li>Amount: $${h(booking?.charge_amount ?? '—')}</li>
<li>Guest: ${h([booking?.holder_first_name, booking?.holder_last_name].filter(Boolean).join(' '))} &lt;${h(booking?.holder_email ?? '')}&gt;</li>
<li>What we did: <b>${h(action)}</b></li>
</ul>
${auto
  ? '<p>The hotel booking was cancelled free of charge and the full amount was refunded. No further action is needed.</p>'
  : '<p><b>Decide now:</b> if the stay has not started, cancel it from Flynoom Admin and refund to avoid the dispute and its fee. If the guest already checked in or the booking cannot be refunded, keep the evidence ready for the dispute.</p>'}`,
      }).catch(() => false);
    } else if (event.type.startsWith('charge.dispute.')) {
      // نجلب الحالة الحالية من Stripe بدل الاعتماد على نسخة الحدث: Stripe يعيد
      // إرسال الأحداث القديمة الفاشلة لاحقًا، فقد تصل نسخة قديمة (needs_response)
      // بعد نسخة أحدث (under_review) فتعيد الحالة إلى الخلف.
      const evObj: any = event.data.object;
      let d: any = evObj;
      try {
        d = await stripe.disputes.retrieve(evObj.id);
      } catch (e) {
        console.log('DISPUTE RETRIEVE FAILED, using event payload', evObj.id, String(e));
      }
      const admin = adminClient();
      const { booking, isNew } = await upsertDispute(admin, d);
      console.log(`DISPUTE ${event.type} ${d.id} status=${d.status} booking=${booking?.client_reference ?? '-'}`);

      if (event.type === 'charge.dispute.created' || isNew) {
        const due = d?.evidence_details?.due_by ? new Date(d.evidence_details.due_by * 1000).toUTCString() : '—';
        const link = `https://dashboard.stripe.com/${d.livemode ? '' : 'test/'}disputes/${d.id}`;
        await sendEmail(ADMIN_EMAIL, {
          subject: `⚠️ Payment dispute: $${((d.amount ?? 0) / 100).toFixed(2)} (${booking?.client_reference ?? 'unknown booking'})`,
          html: `<p>A customer disputed a payment with their bank. <b>Respond with evidence before the deadline</b> or the amount is lost.</p>
<ul>
<li>Amount: $${((d.amount ?? 0) / 100).toFixed(2)} ${h(String(d.currency ?? '').toUpperCase())}</li>
<li>Reason: ${h(d.reason)}</li>
<li>Evidence due by: ${h(due)}</li>
<li>Booking: ${h(booking?.client_reference ?? '—')} · ${h(booking?.hotel_name ?? '')}</li>
<li>Guest: ${h([booking?.holder_first_name, booking?.holder_last_name].filter(Boolean).join(' '))} &lt;${h(booking?.holder_email ?? '')}&gt;</li>
</ul>
<p>Open Flynoom Admin → Disputes to download the evidence PDF, then submit it in Stripe: <a href="${link}">${link}</a></p>`,
        }).catch(() => false);
      }
    }
  } catch (e) {
    // نرد 200 حتى لا يعيد Stripe الإرسال إلى ما لا نهاية، ونسجل الخطأ.
    console.log('WEBHOOK HANDLER ERROR', event.type, String(e));
  }

  return new Response(JSON.stringify({ received: true }), {
    status: 200,
    headers: { 'Content-Type': 'application/json' },
  });
});