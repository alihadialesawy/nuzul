// supabase/functions/liteapi-book/index.ts
//
// المرحلة 5 من الانتقال إلى LiteAPI — الخطوة 2 من الحجز (بعد أن يُدخل الزبون بطاقته
// ويُحجز المبلغ عليها). نفس منطق hotelbeds-book تمامًا، والمورّد LiteAPI:
//
// 1) الحجز يخص المستخدم، حالته awaiting_payment، ومورّده liteapi.
// 2) Stripe: المبلغ محجوز فعلًا (requires_capture) وبنفس القيمة.
// 3) الولايات المقيّدة + المقيمون في أمريكا فقط (عنوان فاتورة أمريكي).
// 4) بوابة الاحتيال (_shared/fraud.ts) — قبل أي تكلفة علينا.
// 5) قفل الحجز (processing) حتى لا يُنفَّذ مرتين.
// 6) POST /rates/book عند LiteAPI بـ prebookId، والدفع ببطاقة FLYNOOM المسجّلة
//    في حساب LiteAPI (ACC_CREDIT_CARD). clientReference = مفتاح منع التكرار عند LiteAPI.
// 7) CONFIRMED → سحب المبلغ من الزبون + confirmed + إيميل التأكيد بلغته.
//    رفض صريح (4xx) → إلغاء حجز المبلغ + failed.
//    مهلة / 5xx / حالة غير CONFIRMED → needs_attention (لا سحب ولا إلغاء تلقائي).
//
// الأسرار:
//   LITEAPI_PAYMENT_METHOD  افتراضيًا ACC_CREDIT_CARD.
//
// المدخلات: { bookingId, reviewAccepted }

import Stripe from 'npm:stripe@14.21.0';
import { adminClient, corsHeaders, fail, getUser, ok } from '../_shared/hotelbeds.ts';
import { LITEAPI_BOOK, LITEAPI_KEY, liteapi, liteHotelBasics } from '../_shared/liteapi.ts';
import { bookingConfirmationEmail, sendEmail } from '../_shared/email.ts';
import { evaluateRisk, lookupIpCountry, PAYMENT_DECLINED_MESSAGE } from '../_shared/fraud.ts';
import { notEligibleMessage } from '../_shared/eligibility.ts';

const stripe = new Stripe(Deno.env.get('STRIPE_SECRET_KEY') ?? '', {
  apiVersion: '2023-10-16',
  httpClient: Stripe.createFetchHttpClient(),
});

const PAYMENT_METHOD = Deno.env.get('LITEAPI_PAYMENT_METHOD') ?? 'ACC_CREDIT_CARD';
const BOOKING_TIMEOUT_MS = 90000;
const ADMIN_EMAIL = Deno.env.get('ADMIN_EMAIL') ?? 'ali@flynoom.com';

function clientIp(req: Request): string | null {
  const fwd = req.headers.get('x-forwarded-for');
  if (fwd) return fwd.split(',')[0].trim() || null;
  return req.headers.get('cf-connecting-ip') ?? req.headers.get('x-real-ip') ?? null;
}

const REVIEW_CONSENT_TEXT =
  'Customer reviewed the final price, cancellation policy and hotel notes, and tapped "Agree and pay" before authorizing the card.';

// ───── الولايات المقيّدة والمقيمون في أمريكا (نفس hotelbeds-book حرفيًا) ─────

const RESTRICTED_STATE_NAMES: Record<string, string> = {
  CA: 'California',
  FL: 'Florida',
  HI: 'Hawaii',
  IA: 'Iowa',
  MD: 'Maryland',
  WA: 'Washington',
};

function restrictedStateFromZip(zip: string): string | null {
  const z = Number(zip.replace(/\D/g, '').slice(0, 3));
  if (!Number.isFinite(z) || zip.replace(/\D/g, '').length < 5) return null;
  if (z >= 900 && z <= 961) return 'CA';
  if (z >= 320 && z <= 349 && z !== 340) return 'FL';
  if (z >= 967 && z <= 968) return 'HI';
  if (z >= 500 && z <= 528) return 'IA';
  if (z >= 206 && z <= 219) return 'MD';
  if (z >= 980 && z <= 994) return 'WA';
  return null;
}

const ZIP3_STATES: Array<[number, number, string]> = [
  [5, 5, 'NY'], [6, 7, 'PR'], [8, 8, 'VI'], [9, 9, 'PR'], [10, 27, 'MA'], [28, 29, 'RI'],
  [30, 38, 'NH'], [39, 49, 'ME'], [50, 54, 'VT'], [55, 55, 'MA'], [56, 59, 'VT'], [60, 69, 'CT'],
  [70, 89, 'NJ'], [100, 149, 'NY'], [150, 196, 'PA'], [197, 199, 'DE'], [200, 200, 'DC'],
  [201, 201, 'VA'], [202, 205, 'DC'], [206, 219, 'MD'], [220, 246, 'VA'], [247, 268, 'WV'],
  [270, 289, 'NC'], [290, 299, 'SC'], [300, 319, 'GA'], [320, 339, 'FL'], [341, 349, 'FL'],
  [350, 369, 'AL'], [370, 385, 'TN'], [386, 397, 'MS'], [398, 399, 'GA'], [400, 427, 'KY'],
  [430, 459, 'OH'], [460, 479, 'IN'], [480, 499, 'MI'], [500, 528, 'IA'], [530, 549, 'WI'],
  [550, 567, 'MN'], [569, 569, 'DC'], [570, 577, 'SD'], [580, 588, 'ND'], [590, 599, 'MT'],
  [600, 629, 'IL'], [630, 658, 'MO'], [660, 679, 'KS'], [680, 693, 'NE'], [700, 714, 'LA'],
  [716, 729, 'AR'], [730, 749, 'OK'], [750, 799, 'TX'], [800, 816, 'CO'], [820, 831, 'WY'],
  [832, 838, 'ID'], [840, 847, 'UT'], [850, 865, 'AZ'], [870, 884, 'NM'], [885, 885, 'TX'],
  [889, 898, 'NV'], [900, 961, 'CA'], [967, 968, 'HI'], [969, 969, 'GU'], [970, 979, 'OR'],
  [980, 994, 'WA'], [995, 999, 'AK'],
];

function usStateFromZip(zip: string): string | null {
  if (zip.length < 5) return null;
  const z = Number(zip.slice(0, 3));
  for (const [a, b, st] of ZIP3_STATES) if (z >= a && z <= b) return st;
  return null;
}

function restrictedStateFromIntent(intent: any): string | null {
  const pm = intent?.payment_method;
  if (!pm || typeof pm !== 'object') return null;
  const addr = pm.billing_details?.address ?? {};
  const country = String(addr.country ?? pm.card?.country ?? '').toUpperCase();
  if (country && country !== 'US') return null;
  const state = String(addr.state ?? '').toUpperCase();
  if (state && RESTRICTED_STATE_NAMES[state]) return state;
  const zip = String(addr.postal_code ?? '');
  return zip ? restrictedStateFromZip(zip) : null;
}

const REQUIRE_US_BILLING = (Deno.env.get('REQUIRE_US_BILLING') ?? 'true').toLowerCase() !== 'false';

/// المقيمون في العراق (بطاقة صادرة في العراق). يُوقف بالسر IRAQ_ENABLED=false.
const IRAQ_ENABLED = (Deno.env.get('IRAQ_ENABLED') ?? 'true').toLowerCase() !== 'false';
/// سقف أول حجز لعميل من العراق (USD).
const IRAQ_FIRST_BOOKING_MAX_USD = Number(Deno.env.get('IRAQ_FIRST_BOOKING_MAX_USD') ?? '1500') || 1500;

function nonUsBillingReason(intent: any): string | null {
  const pm = intent?.payment_method;
  if (!pm || typeof pm !== 'object') return null;
  const addr = pm.billing_details?.address ?? {};
  const country = String(addr.country ?? '').toUpperCase();
  if (country && country !== 'US') return `billing_country:${country}`;
  const zip = String(addr.postal_code ?? '').trim();
  if (!zip) return 'billing_zip_missing';
  const digits = zip.replace(/-/g, '');
  if (!/^\d{5}(\d{4})?$/.test(digits)) return 'billing_zip_not_us';
  const z3 = Number(digits.slice(0, 3));
  const military = (z3 >= 90 && z3 <= 98) || z3 === 340 || (z3 >= 962 && z3 <= 966);
  if (!military && !usStateFromZip(digits.slice(0, 5))) return 'billing_zip_not_us';
  return null;
}

/// رسائل LiteAPI التي تعني أن الحجز لم يتم يقينًا.
const PRICE_CHANGED_PATTERN = /price.*(changed|increase)|rate.*changed/i;

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders });

  const admin = adminClient();
  let bookingId = '';

  const setStatus = (fields: Record<string, unknown>) =>
    admin
      .from('bookings')
      .update({ ...fields, updated_at: new Date().toISOString() })
      .eq('id', bookingId);

  const cancelIntent = async (id: string) => {
    try {
      await stripe.paymentIntents.cancel(id);
    } catch (e) {
      console.log('Cancel intent failed', String(e));
    }
  };

  try {
    if (!LITEAPI_KEY) return fail('config', 'Booking is not available right now.');
    const user = await getUser(req, admin);
    if (!user) return fail('unauthorized', 'Please sign in.');

    const body = await req.json();
    bookingId = String(body.bookingId ?? '');
    if (!bookingId) return fail('bad_request', 'Missing booking.');

    const { data: booking } = await admin
      .from('bookings')
      .select('*')
      .eq('id', bookingId)
      .eq('user_id', user.id)
      .maybeSingle();

    if (!booking) return fail('not_found', 'Booking not found.');
    if (booking.supplier !== 'liteapi') return fail('bad_request', 'Wrong booking service.');

    if (booking.status === 'confirmed') {
      return ok({ status: 'confirmed', reference: booking.supplier_reference, clientReference: booking.client_reference });
    }
    if (booking.status !== 'awaiting_payment' || !booking.payment_intent_id) {
      return fail('invalid_state', 'This booking can no longer be completed.', { status: booking.status });
    }

    // ───── التحقق من الدفع ─────
    const intent = await stripe.paymentIntents.retrieve(booking.payment_intent_id, {
      expand: ['payment_method', 'latest_charge'],
    });
    const expectedCents = Math.round(Number(booking.charge_amount) * 100);
    if (intent.metadata?.booking_id !== bookingId || intent.currency !== 'usd' || intent.amount !== expectedCents) {
      console.log('Payment mismatch', bookingId, intent.id);
      return fail('payment_mismatch', 'Payment does not match this booking.');
    }
    if (intent.status !== 'requires_capture') {
      return fail('payment_incomplete', 'Your card was not authorized. Please try again.', { paymentStatus: intent.status });
    }

    // ───── الولايات المقيّدة ─────
    const restricted = restrictedStateFromIntent(intent);
    if (restricted) {
      console.log(`RESTRICTED STATE ${booking.client_reference}: ${restricted}`);
      await cancelIntent(intent.id);
      await setStatus({ status: 'failed', failure_reason: `restricted_state:${restricted}` });
      return fail('state_not_supported', notEligibleMessage(booking.locale));
    }

    // ───── المقيمون في أمريكا أو العراق فقط ─────
    // العراق: بطاقة صادرة في العراق (card.country = IQ)، وعنوان الفاتورة (إن أُدخلت دولته) في العراق.
    const pmEarly: any = typeof intent.payment_method === 'object' ? intent.payment_method : null;
    const cardCountryEarly = String(pmEarly?.card?.country ?? '').toUpperCase();
    const billingCountryEarly = String(pmEarly?.billing_details?.address?.country ?? '').toUpperCase();
    const iraqResident = IRAQ_ENABLED && cardCountryEarly === 'IQ' && (!billingCountryEarly || billingCountryEarly === 'IQ');

    if (REQUIRE_US_BILLING && !iraqResident) {
      const nonUs = nonUsBillingReason(intent);
      if (nonUs) {
        console.log(`NON-US BILLING ${booking.client_reference}: ${nonUs}`);
        await cancelIntent(intent.id);
        await setStatus({ status: 'failed', failure_reason: `non_us_billing:${nonUs}` });
        return fail('us_residents_only', notEligibleMessage(booking.locale));
      }
    }

    // ───── العراق: سقف لأول حجز ─────
    // الاسترداد البنكي (chargeback) على البطاقات الأجنبية أصعب في الاعتراض عليه،
    // فأول حجز لعميل من العراق محدود بمبلغ، وبعد أول حجز مكتمل يُرفع السقف.
    if (iraqResident) {
      const { count: done } = await admin
        .from('bookings')
        .select('id', { count: 'exact', head: true })
        .eq('user_id', user.id)
        .eq('status', 'confirmed')
        .neq('id', bookingId);
      const amount = Number(booking.charge_amount) || 0;
      if ((done ?? 0) === 0 && amount > IRAQ_FIRST_BOOKING_MAX_USD) {
        console.log(`IRAQ FIRST-BOOKING CAP ${booking.client_reference}: $${amount} > $${IRAQ_FIRST_BOOKING_MAX_USD}`);
        await cancelIntent(intent.id);
        await setStatus({ status: 'failed', failure_reason: `iraq_first_booking_cap:${amount}` });
        return fail(
          'first_booking_limit',
          `For your first booking with a card issued in Iraq, the maximum is $${IRAQ_FIRST_BOOKING_MAX_USD}. ` +
            'Your card has not been charged. Please choose fewer nights or rooms, or contact support@flynoom.com.',
        );
      }
    }

    // ───── البطاقة وعنوان الفاتورة (للتحقق من الهوية والتحليلات) ─────
    const pmObj: any = typeof intent.payment_method === 'object' ? intent.payment_method : null;
    const card = pmObj?.card;
    {
      const addr = pmObj?.billing_details?.address ?? {};
      const country = String(addr.country ?? card?.country ?? '').toUpperCase() || null;
      const zip = String(addr.postal_code ?? '').replace(/\D/g, '');
      const state = String(addr.state ?? '').toUpperCase() || (country === 'US' || !country ? usStateFromZip(zip) : null) || null;
      const { error } = await admin
        .from('bookings')
        .update({
          card_brand: card?.brand ?? null,
          card_last4: card?.last4 ?? null,
          billing_country: country,
          billing_state: state,
          billing_postal3: zip.length >= 3 ? zip.slice(0, 3) : null,
        })
        .eq('id', bookingId);
      if (error) console.log(`CARD/BILLING SAVE FAILED ${booking.client_reference}: ${error.message}`);
    }

    // ───── بوابة الاحتيال ─────
    {
      const charge: any = typeof intent.latest_charge === 'object' ? intent.latest_charge : null;
      const ip = clientIp(req);
      const ipCountry = await lookupIpCountry(ip);
      const since = new Date(Date.now() - 24 * 3600 * 1000).toISOString();
      const { data: recent } = await admin
        .from('bookings')
        .select('card_brand, card_last4')
        .eq('user_id', user.id)
        .neq('id', bookingId)
        .gte('created_at', since)
        .not('card_last4', 'is', null);
      const thisCard = card?.last4 ? `${card.brand ?? ''}-${card.last4}` : null;
      const otherCards = new Set(
        (recent ?? []).map((r: any) => `${r.card_brand ?? ''}-${r.card_last4}`).filter((k: string) => k !== thisCard),
      );
      const seenBefore = (recent ?? []).some((r: any) => `${r.card_brand ?? ''}-${r.card_last4}` === thisCard);

      const decision = evaluateRisk({
        charge,
        amountUsd: Number(booking.charge_amount) || 0,
        checkIn: String(booking.check_in ?? ''),
        ipCountry,
        otherCardsLast24h: otherCards.size,
        isNewCard: !seenBefore,
      });

      const { error: riskLogErr } = await admin.from('payment_risk_events').insert({
        booking_id: bookingId,
        user_id: user.id,
        payment_intent_id: intent.id,
        decision: decision.allow ? 'allow' : 'reject',
        reasons: decision.reasons,
        signals: decision.signals,
        risk_level: decision.riskLevel,
        risk_score: decision.riskScore,
        three_ds: decision.threeDS,
        card_country: decision.cardCountry,
        ip_country: ipCountry,
        cvc_check: decision.cvcCheck,
        postal_check: decision.postalCheck,
        card_funding: decision.funding,
        amount_usd: Number(booking.charge_amount) || 0,
        ip,
      });
      if (riskLogErr) console.log('RISK LOG FAILED', bookingId, riskLogErr.message);

      if (!decision.allow) {
        console.log(`RISK REJECTED ${booking.client_reference}: ${decision.reasons.join(',')} signals=${decision.signals.join(',')}`);
        await cancelIntent(intent.id); // بدون 'fraudulent' عمدًا (انظر hotelbeds-book)
        await setStatus({ status: 'failed', failure_reason: `risk_rejected:${decision.reasons.join(',')}` });
        return fail('payment_declined', PAYMENT_DECLINED_MESSAGE);
      }
      console.log(`RISK OK ${booking.client_reference}: radar=${decision.riskLevel} 3ds=${decision.threeDS}`);
    }

    // ───── موافقة المراجعة النهائية ─────
    if (body.reviewAccepted === true) {
      const { error: consentError } = await admin.from('booking_consents').insert({
        booking_id: bookingId,
        user_id: user.id,
        kind: 'final_review',
        consent_text: REVIEW_CONSENT_TEXT,
        amount_usd: Number(booking.charge_amount),
        cancellation_policies: booking.cancellation_policies ?? null,
        ip: clientIp(req),
        user_agent: (req.headers.get('user-agent') ?? '').slice(0, 500) || null,
      });
      if (consentError) console.log('CONSENT LOG FAILED', bookingId, consentError.message);
    }

    // ───── قفل الحجز ─────
    const { data: locked } = await admin
      .from('bookings')
      .update({ status: 'processing', updated_at: new Date().toISOString() })
      .eq('id', bookingId)
      .eq('status', 'awaiting_payment')
      .select('id');
    if (!locked || locked.length === 0) return fail('invalid_state', 'This booking is already being processed.');

    // ───── الحجز عند LiteAPI ─────
    const prebookInfo = (booking.supplier_response ?? {}) as Record<string, any>;
    const occupancies: number[] = Array.isArray(prebookInfo.occupancyNumbers) && prebookInfo.occupancyNumbers.length
      ? prebookInfo.occupancyNumbers
      : [1];
    const person = {
      firstName: booking.holder_first_name,
      lastName: booking.holder_last_name,
      email: booking.holder_email,
      phone: booking.holder_phone,
    };
    const bookRQ = {
      prebookId: booking.rate_key,
      clientReference: booking.client_reference, // مفتاح منع التكرار عند LiteAPI
      holder: person,
      guests: occupancies.map((n) => ({ occupancyNumber: n, ...person, remarks: '' })),
      payment: { method: PAYMENT_METHOD },
      metadata: {
        ip: clientIp(req) ?? undefined,
        country: iraqResident ? 'IQ' : 'US',
        language: String(booking.locale ?? 'en'),
        platform: 'flynoom',
        user_agent: (req.headers.get('user-agent') ?? '').slice(0, 300) || undefined,
      },
    };

    let r: { status: number; data: any };
    const started = Date.now();
    try {
      r = await liteapi(`${LITEAPI_BOOK}/rates/book`, { method: 'POST', body: JSON.stringify(bookRQ) }, BOOKING_TIMEOUT_MS);
    } catch (e) {
      // حالة غير معروفة: ربما تم الحجز عند LiteAPI. لا نلغي المبلغ تلقائيًا.
      console.log(`BOOKING UNKNOWN ${booking.client_reference}: ${String(e)}`);
      await setStatus({ status: 'needs_attention', failure_reason: `liteapi timeout/network: ${String(e)}` });
      return ok({ status: 'pending', clientReference: booking.client_reference });
    }
    const ms = Date.now() - started;
    const d = r.data?.data ?? null;
    const errMsg = String(r.data?.error?.message ?? r.data?.error?.description ?? r.data?.message ?? '');
    const errCode = r.data?.error?.code ?? null;
    console.log(
      `LITE BOOK ${booking.client_reference} HTTP ${r.status} in ${ms}ms status=${d?.status ?? '-'} ` +
        `bookingId=${d?.bookingId ?? '-'} err=${errCode ?? '-'} ${errMsg.slice(0, 200)}`,
    );

    // خطأ داخلي عند LiteAPI (5xx) أو رد بلا حالة واضحة: لا نعرف يقينًا → مراجعة يدوية.
    if (r.status >= 500 || (r.status === 200 && !d?.bookingId)) {
      await setStatus({
        status: 'needs_attention',
        failure_reason: `liteapi ${r.status}: ${errMsg || 'no booking id'}`.slice(0, 500),
        supplier_response: r.data,
      });
      await sendEmail(ADMIN_EMAIL, {
        subject: `Needs attention: LiteAPI booking ${booking.client_reference}`,
        html: `<p>LiteAPI returned HTTP ${r.status} for booking ${booking.client_reference}. The card is authorized but NOT captured. Check the booking in the LiteAPI dashboard by client reference, then confirm or release it in Booking Desk.</p>`,
      }).catch(() => false);
      return ok({ status: 'pending', clientReference: booking.client_reference });
    }

    // رفض صريح (4xx): الحجز لم يتم → إلغاء حجز المبلغ.
    if (r.status !== 200 || !d) {
      await cancelIntent(intent.id);
      await setStatus({
        status: 'failed',
        failure_reason: `liteapi ${r.status} ${errCode ?? ''}: ${errMsg}`.slice(0, 500),
        supplier_response: r.data,
      });
      if (PRICE_CHANGED_PATTERN.test(errMsg)) {
        return fail(
          'price_changed',
          'The hotel changed the price of this room while you were booking. Your card has not been charged. ' +
            'Please go back and select the room again to see the current price.',
        );
      }
      return fail(
        'booking_failed',
        'This room is no longer available for your dates. Your card has not been charged. ' +
          'Please go back and choose another room or hotel.',
      );
    }

    const supplierFields = {
      supplier_reference: String(d.bookingId),
      supplier_name: d.supplierBookingName ?? d.supplier ?? null,
      supplier_vat: null,
      hotel_confirmation_code: d.hotelConfirmationCode ?? null,
      supplier_response: r.data,
    };

    // حالة غير مؤكدة (مثل PENDING): الحجز موجود عند LiteAPI لكنه لم يتأكد بعد.
    if (String(d.status ?? '').toUpperCase() !== 'CONFIRMED') {
      await setStatus({ status: 'needs_attention', failure_reason: `liteapi status ${d.status}`, ...supplierFields });
      await sendEmail(ADMIN_EMAIL, {
        subject: `Needs attention: LiteAPI booking ${booking.client_reference} is ${d.status}`,
        html: `<p>LiteAPI booking ${d.bookingId} (${booking.client_reference}) returned status ${d.status}. The card is authorized but NOT captured.</p>`,
      }).catch(() => false);
      return ok({ status: 'pending', clientReference: booking.client_reference });
    }

    // ───── نجح الحجز → سحب المبلغ ─────
    try {
      await stripe.paymentIntents.capture(intent.id);
    } catch (e) {
      console.log(`CAPTURE FAILED ${booking.client_reference} ref=${d.bookingId}:`, String(e));
      await setStatus({ status: 'needs_attention', failure_reason: `capture failed: ${String(e)}`, ...supplierFields });
      return ok({ status: 'pending', clientReference: booking.client_reference });
    }

    // عنوان الفندق للقسيمة (لا يوقف الحجز لو فشل).
    const basics = await liteHotelBasics(String(booking.hotel_code ?? '')).catch(() => null);
    const address = basics
      ? [basics.address, basics.city, basics.countryCode].filter((s) => s && String(s).trim()).join(', ') || null
      : null;

    let { error: confirmErr } = await setStatus({
      status: 'confirmed',
      failure_reason: null,
      hotel_address: address,
      ...supplierFields,
    });
    if (confirmErr && /hotel_confirmation_code/.test(confirmErr.message)) {
      // العمود لم يُضف بعد (bookings_add_liteapi.sql): نحفظ بدونه.
      const { hotel_confirmation_code: _omit, ...rest } = supplierFields;
      ({ error: confirmErr } = await setStatus({ status: 'confirmed', failure_reason: null, hotel_address: address, ...rest }));
    }
    if (confirmErr) console.log(`CONFIRM SAVE FAILED ${booking.client_reference}: ${confirmErr.message}`);
    console.log(`BOOKING CONFIRMED ${booking.client_reference} liteapi=${d.bookingId} hotelConf=${d.hotelConfirmationCode ?? '-'}`);

    const { data: confirmed } = await admin.from('bookings').select('*').eq('id', bookingId).maybeSingle();
    if (confirmed) await sendEmail(confirmed.holder_email, bookingConfirmationEmail(confirmed));

    return ok({ status: 'confirmed', reference: String(d.bookingId), clientReference: booking.client_reference });
  } catch (e) {
    console.log('liteapi-book error', String(e));
    if (bookingId) {
      await setStatus({ status: 'needs_attention', failure_reason: `server error: ${String(e)}` }).eq('status', 'processing');
    }
    return fail('server_error', 'Something went wrong. We will review your booking and contact you.');
  }
});
