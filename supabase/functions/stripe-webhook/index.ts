// supabase/functions/stripe-webhook/index.ts
//
// يستقبل أحداث Stripe. حاليًا: الاعتراضات على الدفع (charge.dispute.*).
// • يتحقق من توقيع Stripe (STRIPE_WEBHOOK_SECRET) — أي طلب بلا توقيع صحيح يُرفض.
// • يحفظ الاعتراض في جدول disputes ويربطه بالحجز (عبر payment_intent).
// • عند اعتراض جديد: بريد فوري للمدير، ويظهر أحمر في "مهام اليوم".
//
// الإعداد (مرة واحدة):
//   1) Stripe → Developers → Webhooks → Add endpoint
//      URL: https://nomgbttkfzhgbmbyidpy.supabase.co/functions/v1/stripe-webhook
//      Events: charge.dispute.created, charge.dispute.updated, charge.dispute.closed,
//              charge.dispute.funds_withdrawn, charge.dispute.funds_reinstated
//   2) انسخ Signing secret (whsec_...) ثم:
//      supabase secrets set STRIPE_WEBHOOK_SECRET=whsec_... --project-ref nomgbttkfzhgbmbyidpy
//   3) النشر — بدون التحقق من JWT (Stripe لا يرسل توكن Supabase):
//      supabase functions deploy stripe-webhook --no-verify-jwt --project-ref nomgbttkfzhgbmbyidpy

import Stripe from 'npm:stripe@14.21.0';
import { adminClient } from '../_shared/hotelbeds.ts';
import { sendEmail } from '../_shared/email.ts';
import { upsertDispute } from '../_shared/disputes.ts';

const stripe = new Stripe(Deno.env.get('STRIPE_SECRET_KEY') ?? '', {
  apiVersion: '2023-10-16',
  httpClient: Stripe.createFetchHttpClient(),
});
const cryptoProvider = Stripe.createSubtleCryptoProvider();
const WEBHOOK_SECRET = Deno.env.get('STRIPE_WEBHOOK_SECRET') ?? '';
const ADMIN_EMAIL = Deno.env.get('ADMIN_EMAIL') ?? 'ali@flynoom.com';

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
    console.log('WEBHOOK SIGNATURE INVALID', String(e));
    return new Response('invalid signature', { status: 400 });
  }

  try {
    if (event.type.startsWith('charge.dispute.')) {
      const d: any = event.data.object;
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