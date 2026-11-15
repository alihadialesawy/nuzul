// supabase/functions/liteapi-prepare/index.ts
//
// المرحلة 4 من الانتقال إلى LiteAPI — الخطوة 1 من الحجز: تثبيت السعر وتجهيز الدفع.
// (مثل hotelbeds-prepare تمامًا، وبنفس شكل الطلب والرد، فلا تتغير صفحة الحجز.)
//
// 1) يتحقق من المستخدم (JWT)، وحد المحاولات، وبيانات صاحب الحجز، والموافقة على الشروط.
// 2) يقرأ دولة الفندق وموقعه من LiteAPI (/data/hotel) — لا نثق بما يرسله التطبيق:
//      • العقوبات الأمريكية والدول غير المتاحة (RU/BY/SY) ومناطق أوكرانيا.
//      • موسم الحج: فنادق مكة (بالموقع: ≤ 25 كم من الكعبة) خلال نافذة المنع.
// 3) prebook عند LiteAPI: يثبّت السعر ويُرجع prebookId والسعر النهائي وسياسة الإلغاء
//    والرسوم وملاحظات الفندق — تُعرض للزبون قبل الدفع.
// 4) يحسب المبلغ على السيرفر: سعر الجملة (margin 0) + عمولتنا، ولا يقل عن SSP.
// 5) سقف الأمان لسعر الليلة، ثم صف حجز awaiting_payment، ثم Stripe PaymentIntent
//    بـ capture_method=manual (المبلغ يُحجز فقط؛ السحب بعد تأكيد LiteAPI في liteapi-book).
//
// المدخلات: { rateKey (= offerId), hotelCode (= hotelId)، hotelName, hotelCity, hotelImage?, roomName?,
//            checkIn, checkOut, guests, expectedPrice?, expectedPriceUsd?,
//            holder: { firstName, lastName, email, phone },
//            consent: { acceptedTerms, confirmedResidency, termsVersion, privacyVersion, locale } }

import Stripe from 'npm:stripe@14.21.0';
import {
  adminClient,
  corsHeaders,
  fail,
  getUser,
  newClientReference,
  ok,
  round2,
  SAR_PER_USD,
  toNum,
  toUsdRaw,
} from '../_shared/hotelbeds.ts';
import {
  amountOf,
  LITEAPI_BOOK,
  LITEAPI_KEY,
  LITEAPI_MARKUP_PERCENT,
  liteapi,
  liteAtHotelFees,
  liteCancellation,
  liteHotelBasics,
  liteSellingPrice,
  remarksText,
} from '../_shared/liteapi.ts';
import { emailLocale, sendEmail } from '../_shared/email.ts';
import { lookupIpCountry } from '../_shared/fraud.ts';
import { isBlockedDestination, isBlockedUkraineLocation } from '../_shared/sanctions.ts';
import { HAJJ_SEASON_MESSAGE, hajjSeasonConflictAt } from '../_shared/hajj.ts';

const MAX_ATTEMPTS_PER_HOUR = Number(Deno.env.get('MAX_BOOKING_ATTEMPTS_PER_HOUR') ?? '5') || 5;
const MAX_NIGHTLY_USD = Number(Deno.env.get('MAX_NIGHTLY_USD') ?? '3000') || 3000;
const ADMIN_EMAIL = Deno.env.get('ADMIN_EMAIL') ?? 'ali@flynoom.com';

const stripe = new Stripe(Deno.env.get('STRIPE_SECRET_KEY') ?? '', {
  apiVersion: '2023-10-16',
  httpClient: Stripe.createFetchHttpClient(),
});

const DATE_RE = /^\d{4}-\d{2}-\d{2}$/;
const NAME_RE = /^[\p{L}][\p{L}\s'.-]{0,49}$/u;
const EMAIL_RE = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;

/// النص الإنجليزي لمربعي الموافقة كما يظهران في صفحة الحجز (يُحفظ مع كل موافقة).
/// ⚠️ إذا غيّرت نص المربعين في booking_page.dart فغيّره هنا وفي hotelbeds-prepare.
const TERMS_CONSENT_TEXT =
  'I have read and agree to the Terms of Service, including the binding arbitration agreement and class action waiver, and the Privacy Notice.';
const RESIDENCY_CONSENT_TEXT =
  '(Eligibility under Terms of Service section 3 accepted as part of the Terms; no separate residency checkbox.)';

const h = (v: unknown) => String(v ?? '').replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;');

function nightsBetween(checkIn: string, checkOut: string): number {
  const a = Date.parse(checkIn);
  const b = Date.parse(checkOut);
  return Number.isFinite(a) && Number.isFinite(b) ? Math.max(1, Math.round((b - a) / 86400000)) : 1;
}

function clientIp(req: Request): string | null {
  const fwd = req.headers.get('x-forwarded-for');
  if (fwd) return fwd.split(',')[0].trim() || null;
  return req.headers.get('cf-connecting-ip') ?? req.headers.get('x-real-ip') ?? null;
}

function shortText(v: unknown, max: number): string | null {
  const t = typeof v === 'string' ? v.trim() : '';
  return t ? t.slice(0, max) : null;
}

function capitalizeName(s: string): string {
  return s.replace(/(^|[\s'-])(\p{Ll})/gu, (_m, sep, ch) => sep + ch.toUpperCase());
}

function clean(v: unknown): string {
  return typeof v === 'string' ? v.trim().replace(/\s+/g, ' ') : '';
}

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders });
  if (!LITEAPI_KEY) return fail('config', 'Booking is not available right now.');

  try {
    const admin = adminClient();
    const user = await getUser(req, admin);
    if (!user) return fail('unauthorized', 'Please sign in to book.');

    // ───── حد محاولات الدفع (نفس قاعدة hotelbeds-prepare) ─────
    {
      const since = new Date(Date.now() - 3600 * 1000).toISOString();
      const { count } = await admin
        .from('bookings')
        .select('id', { count: 'exact', head: true })
        .eq('user_id', user.id)
        .gte('created_at', since)
        .or('status.eq.awaiting_payment,failure_reason.like.risk_rejected*');
      if ((count ?? 0) >= MAX_ATTEMPTS_PER_HOUR) {
        console.log(`RATE LIMITED user=${user.id} attempts=${count}`);
        return fail(
          'too_many_attempts',
          'Too many booking attempts. Please wait an hour and try again, or contact support@flynoom.com.',
        );
      }
    }

    const body = await req.json();
    const offerId = clean(body.rateKey);
    const hotelCode = clean(String(body.hotelCode ?? '')).replace(/^hb_/, '');
    const checkIn = clean(body.checkIn);
    const checkOut = clean(body.checkOut);
    const guests = Math.max(1, Number(body.guests) || 1);
    const holder = body.holder ?? {};
    const firstName = capitalizeName(clean(holder.firstName));
    const lastName = capitalizeName(clean(holder.lastName));
    const email = clean(holder.email).toLowerCase();
    const phone = clean(holder.phone);

    if (!offerId || !/^[A-Za-z0-9_-]{2,40}$/.test(hotelCode) || !DATE_RE.test(checkIn) || !DATE_RE.test(checkOut)) {
      return fail('bad_request', 'Missing or invalid booking data.');
    }
    if (!NAME_RE.test(firstName) || !NAME_RE.test(lastName)) {
      return fail('invalid_holder', 'Please enter a valid first and last name (letters only).');
    }
    if (!EMAIL_RE.test(email)) return fail('invalid_holder', 'Please enter a valid email.');
    if (phone.replace(/\D/g, '').length < 7) return fail('invalid_holder', 'Please enter a valid phone number.');

    // ───── الموافقة على الشروط ─────
    const consent = body.consent ?? {};
    // شرط الأهلية (البند 3 من الشروط) جزء من الموافقة على الشروط؛ لا مربع إقامة منفصل.
    if (consent.acceptedTerms !== true) {
      return fail('consent_required', 'Please accept the Terms of Service to continue.');
    }
    const termsVersion = shortText(consent.termsVersion, 20) ?? 'unknown';
    const privacyVersion = shortText(consent.privacyVersion, 20) ?? 'unknown';

    // ───── الفندق: الدولة والموقع من LiteAPI ─────
    const basics = await liteHotelBasics(hotelCode);
    if (!basics) {
      return fail('supplier_timeout', 'The hotel did not respond. Please try again.');
    }

    // العقوبات الأمريكية + الدول غير المتاحة + مناطق أوكرانيا.
    // fail-closed: دولة غير معروفة = لا حجز (LiteAPI يعطي الدولة لكل فندق عادةً).
    if (!basics.countryCode) {
      console.log(`SANCTIONS: country unknown for liteapi hotel ${hotelCode} — blocked`);
      return fail('destination_not_available', 'This destination is not available on Flynoom.');
    }
    if (
      isBlockedDestination(basics.countryCode, '') ||
      (basics.countryCode === 'UA' && isBlockedUkraineLocation(basics.lat, basics.lon))
    ) {
      console.log(`SANCTIONS BLOCKED liteapi hotel=${hotelCode} country=${basics.countryCode}`);
      return fail('destination_not_available', 'This destination is not available on Flynoom.');
    }

    // موسم الحج.
    {
      const hajj = hajjSeasonConflictAt(
        { lat: basics.lat, lon: basics.lon, countryCode: basics.countryCode, city: basics.city },
        checkIn,
        checkOut,
      );
      if (hajj) {
        console.log(`HAJJ SEASON BLOCKED liteapi hotel=${hotelCode} ${checkIn}→${checkOut} window=${hajj.from}..${hajj.to}`);
        return fail('hajj_season', HAJJ_SEASON_MESSAGE);
      }
    }

    // ───── prebook: تثبيت السعر ─────
    const started = Date.now();
    let pb: { status: number; data: any };
    try {
      pb = await liteapi(`${LITEAPI_BOOK}/rates/prebook`, {
        method: 'POST',
        body: JSON.stringify({ offerId, usePaymentSdk: false }),
      }, 30000);
    } catch (_) {
      return fail('supplier_timeout', 'The hotel did not respond. Please try again.');
    }
    const ms = Date.now() - started;
    const d = pb.data?.data ?? null;
    if (pb.status !== 200 || !d?.prebookId) {
      console.log(`PREBOOK failed HTTP ${pb.status} in ${ms}ms`, JSON.stringify(pb.data).slice(0, 500));
      return fail('rate_unavailable', 'This rate is no longer available. Please go back and choose another room.');
    }
    if (d.hotelId && String(d.hotelId) !== hotelCode) {
      console.log(`PREBOOK hotel mismatch: offer for ${d.hotelId}, request for ${hotelCode}`);
      return fail('rate_unavailable', 'This rate is no longer available. Please choose another room.');
    }

    const rates: any[] = (Array.isArray(d.roomTypes) ? d.roomTypes : []).flatMap((rt: any) =>
      Array.isArray(rt?.rates) ? rt.rates : []
    );
    const rate0 = rates[0] ?? {};

    // ───── السعر ─────
    const supplierCurrency = String(d.currency ?? 'USD').toUpperCase();
    const netRaw = toNum(d.price) ?? amountOf(d.offerRetailRate) ?? 0;
    const sspRaw = toNum(d.suggestedSellingPrice) ?? amountOf(d.suggestedSellingPrice);
    const net = supplierCurrency === 'USD' ? netRaw : await toUsdRaw(netRaw, supplierCurrency);
    const ssp = sspRaw == null ? null : supplierCurrency === 'USD' ? sspRaw : await toUsdRaw(sspRaw, supplierCurrency);
    if (!(net > 0)) return fail('rate_unavailable', 'Invalid price for this rate.');

    // نلتزم بالسعر الذي رآه الزبون إن لم يتغير سعر المورّد (فرق سنتات من التقريب)،
    // بشرط ألا يقل عن الحد الأدنى المسموح (الجملة و SSP).
    const freshUsd = liteSellingPrice(net, ssp);
    const expectedUsd = toNum(body.expectedPriceUsd);
    const floor = Math.max(net, ssp ?? 0);
    let chargeUsd = freshUsd;
    if (expectedUsd !== null && Math.abs(expectedUsd - freshUsd) <= 0.05 && expectedUsd >= floor) {
      chargeUsd = round2(expectedUsd);
    }
    const priceChanged = expectedUsd !== null && Math.abs(chargeUsd - expectedUsd) > 0.009;

    const amountCents = Math.round(chargeUsd * 100);
    if (amountCents < 50) return fail('rate_unavailable', 'Invalid price for this rate.');

    // ───── سقف الأمان ─────
    const nights = nightsBetween(checkIn, checkOut);
    const nightlyUsd = round2(chargeUsd / nights);
    const roomName = clean(String(rate0.name ?? '')) || clean(body.roomName) || null;
    const boardName = clean(String(rate0.boardName ?? '')) || null;
    if (nightlyUsd > MAX_NIGHTLY_USD) {
      console.log(`PRICE GUARD BLOCKED liteapi hotel=${hotelCode} nightly=${nightlyUsd} total=${chargeUsd} net=${net} user=${user.id}`);
      await sendEmail(ADMIN_EMAIL, {
        subject: `Price guard: $${nightlyUsd}/night blocked (LiteAPI hotel ${hotelCode})`,
        html: `<p>A booking attempt was blocked before payment because the nightly price exceeded the safety limit ($${MAX_NIGHTLY_USD}).</p>
<ul>
<li>Hotel: ${h(basics.name)} (LiteAPI ${hotelCode})</li>
<li>Room: ${h(roomName)} · ${h(boardName)}</li>
<li>Dates: ${checkIn} → ${checkOut} (${nights} nights), guests: ${guests}</li>
<li>Net: $${net} · SSP: ${ssp ?? '-'} · Charge: $${chargeUsd} ($${nightlyUsd}/night)</li>
<li>Customer: ${h(firstName)} ${h(lastName)} &lt;${h(email)}&gt;</li>
</ul>
<p>No card was charged or held.</p>`,
      }).catch(() => false);
      return fail(
        'price_review',
        'We could not confirm this price automatically. Nothing was charged. Our team will review it and contact you shortly.',
      );
    }

    // ───── الرسوم في الفندق، وسياسة الإلغاء، وملاحظات الفندق ─────
    const atHotel = await liteAtHotelFees(rates);
    const cancel = liteCancellation(rate0, net);
    // رسوم الإلغاء على الزبون = نسبة رسوم المورّد من الجملة × ما يدفعه الزبون (مثل hotelbeds-cancel).
    const customerFeeFor = (supplierAmount: number) => {
      const ratio = net > 0 ? Math.min(1, Math.max(0, supplierAmount / net)) : 1;
      return Math.min(chargeUsd, Math.ceil(chargeUsd * ratio * 100) / 100);
    };
    const policies = cancel.policies.map((p) => ({
      amount: p.amount,
      amountUsd: p.amount,
      customerFee: customerFeeFor(p.amount),
      from: p.from, // GMT
    }));
    const rateComments = remarksText(rate0.remarks ?? rate0?.cancellationPolicies?.hotelRemarks);

    // ───── صف الحجز ─────
    const clientReference = newClientReference();
    const { data: booking, error: insertError } = await admin
      .from('bookings')
      .insert({
        user_id: user.id,
        hotel_id: `hb_${hotelCode}`,
        room_id: null,
        check_in: checkIn,
        check_out: checkOut,
        guests,
        total_price: round2(chargeUsd * SAR_PER_USD),
        status: 'awaiting_payment',
        hotel_name: basics.name || clean(body.hotelName) || null,
        hotel_city: basics.city || clean(body.hotelCity) || null,
        hotel_images: body.hotelImage ? [String(body.hotelImage)] : null,
        supplier: 'liteapi',
        hotel_code: hotelCode,
        room_name: roomName,
        board_name: boardName,
        rate_key: String(d.prebookId), // liteapi-book يحجز بـ prebookId
        rate_type: cancel.refundable ? 'RFN' : 'NRFN',
        supplier_currency: 'USD',
        supplier_net: net,
        supplier_net_usd: net,
        markup_pct: LITEAPI_MARKUP_PERCENT,
        fx_buffer_pct: 0,
        supplier_selling_rate: ssp,
        hotel_mandatory: false,
        charge_currency: 'USD',
        charge_amount: chargeUsd,
        client_reference: clientReference,
        holder_first_name: firstName,
        holder_last_name: lastName,
        holder_email: email,
        holder_phone: phone,
        rate_comments: rateComments,
        cancellation_policies: policies,
        pay_at_hotel_usd: atHotel.totalUsd,
        pay_at_hotel_fees: atHotel.fees,
        locale: emailLocale(consent.locale),
        supplier_response: {
          stage: 'prebook',
          offerId,
          prebookId: d.prebookId,
          price: netRaw,
          currency: supplierCurrency,
          suggestedSellingPrice: sspRaw,
          priceDifferencePercent: d.priceDifferencePercent ?? null,
          paymentTypes: rate0.paymentTypes ?? d.paymentTypes ?? null,
          refundableTag: rate0?.cancellationPolicies?.refundableTag ?? null,
          // رقم كل غرفة (occupancyNumber) — liteapi-book يرسل ضيفًا لكل غرفة.
          occupancyNumbers: rates.map((r: any, i: number) => Number(r?.occupancyNumber) || i + 1),
        },
      })
      .select('id')
      .single();

    if (insertError || !booking) {
      console.log('Insert booking failed', insertError);
      return fail('server_error', 'Could not start the booking. Please try again.');
    }

    // ───── تسجيل الموافقة ─────
    {
      const { error: consentError } = await admin.from('booking_consents').insert({
        booking_id: booking.id,
        user_id: user.id,
        kind: 'checkout_terms',
        terms_version: termsVersion,
        privacy_version: privacyVersion,
        accepted_terms: true,
        confirmed_residency: true,
        consent_text: `${TERMS_CONSENT_TEXT}\n${RESIDENCY_CONSENT_TEXT}`,
        locale: shortText(consent.locale, 10),
        amount_usd: chargeUsd,
        ip: clientIp(req),
        user_agent: shortText(req.headers.get('user-agent'), 500),
      });
      if (consentError) console.log('CONSENT LOG FAILED', booking.id, consentError.message);
    }

    // ───── Stripe: حجز المبلغ فقط (manual capture) ─────
    const intent = await stripe.paymentIntents.create({
      amount: amountCents,
      currency: 'usd',
      capture_method: 'manual',
      payment_method_types: ['card'],
      payment_method_options: { card: { request_three_d_secure: 'any' } },
      receipt_email: email,
      description: `Flynoom hotel booking ${clientReference}`,
      metadata: {
        booking_id: booking.id,
        client_reference: clientReference,
        user_id: user.id,
        supplier: 'liteapi',
        terms_version: termsVersion,
        privacy_version: privacyVersion,
      },
    });

    await admin
      .from('bookings')
      .update({ payment_intent_id: intent.id, updated_at: new Date().toISOString() })
      .eq('id', booking.id);

    console.log(
      `Prepared ${clientReference} booking=${booking.id} liteapi hotel=${hotelCode} prebook=${d.prebookId} ` +
        `in ${ms}ms net=${net} ssp=${ssp ?? '-'} charge=${chargeUsd} USD priceChanged=${priceChanged}`,
    );

    // بلد الزائر (من عنوان IP): نافذة البطاقة على الويب تخفي خانة الرمز البريدي
    // لمن يحجز من العراق (العناوين العراقية بلا رموز بريدية عمليًا).
    const visitorCountry = await lookupIpCountry(clientIp(req)).catch(() => null);

    return ok({
      visitorCountry,
      bookingId: booking.id,
      clientReference,
      clientSecret: intent.client_secret,
      chargeAmount: chargeUsd,
      chargeCurrency: 'USD',
      supplier: 'liteapi',
      supplierCurrency: 'USD',
      supplierPrice: net,
      priceChanged,
      roomName,
      boardName,
      rateClass: cancel.refundable ? 'NOR' : 'NRF',
      rateComments,
      cancellationPolicies: policies,
      payAtHotelUsd: atHotel.totalUsd,
      atHotelFees: atHotel.fees,
      totalUsd: round2(chargeUsd + atHotel.totalUsd),
    });
  } catch (e) {
    console.log('liteapi-prepare error', String(e));
    return fail('server_error', 'Something went wrong. Please try again.');
  }
});
