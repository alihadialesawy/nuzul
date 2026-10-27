// supabase/functions/hotelbeds-prepare/index.ts
//
// الخطوة 1 من الحجز: تثبيت السعر وتجهيز الدفع.
//
// 1) يتحقق من المستخدم (JWT) ومن بيانات صاحب الحجز.
// 2) CheckRate عند HotelBeds: يؤكد السعر الحالي، ويرجع ملاحظات السعر
//    (rate comments) وسياسة الإلغاء — يجب عرضها للعميل قبل الدفع (شرط HotelBeds).
//    (CheckRate إلزامي لـ RECHECK، واختياري لـ BOOKABLE؛ نستخدمه دائمًا
//    لأنه يضمن السعر النهائي وملاحظاته قبل أخذ أي مال من العميل.)
// 3) يحسب المبلغ على السيرفر (لا نثق بأي مبلغ من التطبيق) ويحوّله لـ USD.
// 4) ينشئ صف حجز بحالة awaiting_payment.
// 5) ينشئ Stripe PaymentIntent بالدولار مع capture_method=manual:
//    المبلغ يُحجز على البطاقة فقط، ولا يُسحب إلا بعد تأكيد HotelBeds (في hotelbeds-book).
//
// المدخلات: { rateKey, hotelCode, hotelName, hotelCity, hotelImage?, roomName?,
//            checkIn: 'YYYY-MM-DD', checkOut: 'YYYY-MM-DD', guests,
//            expectedPrice?, holder: { firstName, lastName, email, phone },
//            consent: { acceptedTerms, confirmedResidency, termsVersion, privacyVersion, locale } }
//
// الموافقة: يرفض الحجز إن لم يوافق العميل على الشروط ويؤكد ولاية الإقامة،
// ويسجّل الموافقة في booking_consents (الوقت، نسخة الشروط، IP، المتصفح)،
// ويضع نسخة الشروط في بيانات Stripe — دليل عند أي اعتراض على الدفع.

import Stripe from 'npm:stripe@14.21.0';
import {
  adminClient,
  atHotelFees,
  corsHeaders,
  fail,
  fetchWithTimeout,
  FX_BUFFER_PERCENT,
  getUser,
  HOTELBEDS_BASE_URL,
  hotelbedsHeaders,
  MARKUP_PERCENT,
  newClientReference,
  ok,
  round2,
  SAR_PER_USD,
  sellingPrice,
  toNum,
  toUsd,
  toUsdRaw,
} from '../_shared/hotelbeds.ts';
import { sendEmail } from '../_shared/email.ts';

const stripe = new Stripe(Deno.env.get('STRIPE_SECRET_KEY') ?? '', {
  apiVersion: '2023-10-16',
  httpClient: Stripe.createFetchHttpClient(),
});

const DATE_RE = /^\d{4}-\d{2}-\d{2}$/;

/// سقف أمان لسعر الليلة (بالدولار، للحجز كله). أي سعر أعلى يُوقف الحجز قبل
/// الدفع ويُرسل تنبيهًا للمدير، حتى لا يُحجز على بطاقة العميل مبلغ شاذ
/// (خطأ بيانات من المورد أو خطأ تحويل عملة). يمكن تغييره بـ Secret:
///   supabase secrets set MAX_NIGHTLY_USD=5000 --project-ref ...
const MAX_NIGHTLY_USD = Number(Deno.env.get('MAX_NIGHTLY_USD') ?? '3000') || 3000;
const ADMIN_EMAIL = Deno.env.get('ADMIN_EMAIL') ?? 'ali@flynoom.com';

const h = (v: unknown) => String(v ?? '').replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;');

function nightsBetween(checkIn: string, checkOut: string): number {
  const a = Date.parse(checkIn);
  const b = Date.parse(checkOut);
  return Number.isFinite(a) && Number.isFinite(b) ? Math.max(1, Math.round((b - a) / 86400000)) : 1;
}
/// النص الإنجليزي لمربعي الموافقة كما يظهران في صفحة الحجز (يُحفظ مع كل موافقة).
/// ⚠️ إذا غيّرت نص المربعين في booking_page.dart فغيّره هنا أيضًا.
const TERMS_CONSENT_TEXT =
  'I have read and agree to the Terms of Service, including the binding arbitration agreement and class action waiver, and the Privacy Notice.';
const RESIDENCY_CONSENT_TEXT =
  'I confirm that I am not a resident of California, Florida, Hawaii, or Washington.';

/// عنوان IP الحقيقي للعميل (أول عنوان في x-forwarded-for).
function clientIp(req: Request): string | null {
  const fwd = req.headers.get('x-forwarded-for');
  if (fwd) return fwd.split(',')[0].trim() || null;
  return req.headers.get('cf-connecting-ip') ?? req.headers.get('x-real-ip') ?? null;
}

function shortText(v: unknown, max: number): string | null {
  const t = typeof v === 'string' ? v.trim() : '';
  return t ? t.slice(0, max) : null;
}

const NAME_RE = /^[\p{L}][\p{L}\s'.-]{0,49}$/u;
const EMAIL_RE = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;

/// "ali hadi" → "Ali Hadi" (يبقى باقي الحروف كما هي: "McDonald" لا يتغير).
function capitalizeName(s: string): string {
  return s.replace(/(^|[\s'-])(\p{Ll})/gu, (_m, sep, ch) => sep + ch.toUpperCase());
}

function clean(v: unknown): string {
  return typeof v === 'string' ? v.trim().replace(/\s+/g, ' ') : '';
}

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders });

  try {
    const admin = adminClient();
    const user = await getUser(req, admin);
    if (!user) return fail('unauthorized', 'Please sign in to book.');

    const body = await req.json();
    const rateKey = clean(body.rateKey);
    const hotelCode = clean(String(body.hotelCode ?? ''));
    const checkIn = clean(body.checkIn);
    const checkOut = clean(body.checkOut);
    const guests = Math.max(1, Number(body.guests) || 1);
    const holder = body.holder ?? {};
    const firstName = capitalizeName(clean(holder.firstName));
    const lastName = capitalizeName(clean(holder.lastName));
    const email = clean(holder.email).toLowerCase();
    const phone = clean(holder.phone);

    if (!rateKey || !hotelCode || !DATE_RE.test(checkIn) || !DATE_RE.test(checkOut)) {
      return fail('bad_request', 'Missing or invalid booking data.');
    }
    if (!NAME_RE.test(firstName) || !NAME_RE.test(lastName)) {
      return fail('invalid_holder', 'Please enter a valid first and last name (letters only).');
    }
    if (!EMAIL_RE.test(email)) return fail('invalid_holder', 'Please enter a valid email.');
    if (phone.replace(/\D/g, '').length < 7) return fail('invalid_holder', 'Please enter a valid phone number.');

    // ───── الموافقة على الشروط ─────
    const consent = body.consent ?? {};
    if (consent.acceptedTerms !== true || consent.confirmedResidency !== true) {
      return fail(
        'consent_required',
        'Please accept the terms and confirm your state of residence to continue.',
      );
    }
    const termsVersion = shortText(consent.termsVersion, 20) ?? 'unknown';
    const privacyVersion = shortText(consent.privacyVersion, 20) ?? 'unknown';

    // ───── CheckRate ─────
    let checkRes: Response;
    try {
      checkRes = await fetchWithTimeout(
        `${HOTELBEDS_BASE_URL}/hotel-api/1.0/checkrates`,
        {
          method: 'POST',
          headers: await hotelbedsHeaders(),
          body: JSON.stringify({ rooms: [{ rateKey }] }),
        },
        30000,
      );
    } catch (_) {
      return fail('supplier_timeout', 'The hotel did not respond. Please try again.');
    }

    const checkData = await checkRes.json().catch(() => ({}));
    if (!checkRes.ok) {
      console.log('CheckRate failed', checkRes.status, JSON.stringify(checkData));
      return fail(
        'rate_unavailable',
        'This rate is no longer available. Please go back and choose another room.',
      );
    }

    const hotel = checkData?.hotel;
    const room = hotel?.rooms?.[0];
    const rate = room?.rates?.[0];
    if (!hotel || !rate?.rateKey) {
      return fail('rate_unavailable', 'This rate is no longer available. Please choose another room.');
    }
    if (rate.paymentType === 'AT_HOTEL') {
      return fail('unsupported_rate', 'This rate cannot be booked online yet.');
    }

    const supplierCurrency: string = String(hotel.currency ?? 'USD').toUpperCase();
    const net = toNum(rate.net) ?? 0;
    const sellingRate = toNum(rate.sellingRate);
    const hotelMandatory = rate.hotelMandatory === true;
    const price = sellingPrice(net, sellingRate, hotelMandatory);
    if (price <= 0) return fail('rate_unavailable', 'Invalid price for this rate.');

    // ───── المبلغ بالدولار ─────
    // لو سعر المورد لم يتغير منذ البحث، نلتزم بالسعر الذي رآه العميل
    // (expectedPriceUsd)، بشرط ألا يقل عن التحويل الفعلي بدون هامش
    // (حماية من التلاعب ومن خسارة فرق الصرف). غير ذلك نحسب سعرًا جديدًا
    // ونُعلم العميل أن السعر تغيّر.
    const expected = toNum(body.expectedPrice); // بعملة HotelBeds
    const expectedUsd = toNum(body.expectedPriceUsd);
    const supplierUnchanged = expected !== null && Math.abs(expected - price) <= 0.01;
    const freshUsd = await toUsd(price, supplierCurrency);
    const floorUsd = await toUsdRaw(price, supplierCurrency);

    let chargeUsd = freshUsd;
    if (supplierUnchanged && expectedUsd !== null && expectedUsd >= floorUsd) {
      chargeUsd = round2(expectedUsd);
    }
    const priceChanged =
      expectedUsd !== null ? Math.abs(chargeUsd - expectedUsd) > 0.009 : (expected !== null && !supplierUnchanged);

    const amountCents = Math.round(chargeUsd * 100);
    if (amountCents < 50) return fail('rate_unavailable', 'Invalid price for this rate.');

    // ───── سقف الأمان ─────
    // قبل إنشاء أي حجز أو PaymentIntent: سعر شاذ = لا دفع، ومراجعة يدوية.
    const nights = nightsBetween(checkIn, checkOut);
    const nightlyUsd = round2(chargeUsd / nights);
    if (nightlyUsd > MAX_NIGHTLY_USD) {
      console.log(
        `PRICE GUARD BLOCKED hotel=${hotelCode} nightly=${nightlyUsd} USD total=${chargeUsd} USD ` +
          `net=${net} ${supplierCurrency} price=${price} user=${user.id}`,
      );
      await sendEmail(ADMIN_EMAIL, {
        subject: `Price guard: $${nightlyUsd}/night blocked (hotel ${hotelCode})`,
        html: `<p>A booking attempt was blocked before payment because the nightly price exceeded the safety limit ($${MAX_NIGHTLY_USD}).</p>
<ul>
<li>Hotel: ${h(hotel.name)} (code ${hotelCode})</li>
<li>Room: ${h(room.name)} · ${h(rate.boardName)}</li>
<li>Dates: ${checkIn} → ${checkOut} (${nights} nights), guests: ${guests}</li>
<li>Supplier price: ${price} ${supplierCurrency} (net ${net})</li>
<li>Converted: $${chargeUsd} total · $${nightlyUsd}/night</li>
<li>Customer: ${firstName} ${lastName} &lt;${email}&gt;</li>
</ul>
<p>Check the price with HotelBeds before contacting the customer. No card was charged or held.</p>`,
      }).catch(() => false);
      return fail(
        'price_review',
        'We could not confirm this price automatically. Nothing was charged. Our team will review it and contact you shortly.',
      );
    }

    // الرسوم الإلزامية التي تُدفع في الفندق (تُعرض للعميل قبل الدفع وفي القسيمة).
    const atHotel = await atHotelFees(rate);

    // رسوم الإلغاء على العميل لكل موعد — نفس معادلة hotelbeds-cancel بالضبط:
    // نسبة رسوم المورد من التكلفة الصافية × ما يدفعه العميل.
    const customerFeeFor = (supplierAmount: number) => {
      const ratio = net > 0 ? Math.min(1, Math.max(0, supplierAmount / net)) : 1;
      return Math.min(chargeUsd, Math.ceil(chargeUsd * ratio * 100) / 100);
    };

    const policies = await Promise.all(
      (rate.cancellationPolicies ?? []).map(async (p: any) => {
        const amount = toNum(p.amount) ?? 0;
        return {
          amount,
          amountUsd: await toUsd(amount, supplierCurrency),
          customerFee: customerFeeFor(amount), // ما يُخصم من العميل (USD)
          from: p.from, // بتوقيت الفندق (مع الـ offset)
        };
      }),
    );

    const rateComments: string | null =
      typeof rate.rateComments === 'string' && rate.rateComments.trim()
        ? rate.rateComments.trim()
        : null;

    // ───── صف الحجز ─────
    const clientReference = newClientReference();
    const { data: booking, error: insertError } = await admin
      .from('bookings')
      .insert({
        user_id: user.id,
        hotel_id: `hb_${hotelCode}`,
        room_id: room.code ?? null,
        check_in: checkIn,
        check_out: checkOut,
        guests,
        total_price: round2(chargeUsd * SAR_PER_USD), // للعرض في التطبيق (SAR)
        status: 'awaiting_payment',
        hotel_name: clean(body.hotelName) || hotel.name || null,
        hotel_city: clean(body.hotelCity) || hotel.destinationName || null,
        hotel_images: body.hotelImage ? [String(body.hotelImage)] : null,
        supplier: 'hotelbeds',
        hotel_code: hotelCode,
        room_name: room.name ?? clean(body.roomName) ?? null,
        board_name: rate.boardName ?? null,
        rate_key: rate.rateKey,
        rate_type: rate.rateType ?? null,
        supplier_currency: supplierCurrency,
        supplier_net: net,
        // التكلفة بالدولار بدون هامش الصرف — لحساب الربح في لوحة الإحصاءات.
        supplier_net_usd: await toUsdRaw(net, supplierCurrency),
        // الإعدادات المطبقة على هذا الحجز (للإحصاءات والمراجعة لاحقًا).
        markup_pct: hotelMandatory ? null : MARKUP_PERCENT,
        fx_buffer_pct: supplierCurrency === 'USD' ? 0 : FX_BUFFER_PERCENT,
        supplier_selling_rate: sellingRate,
        hotel_mandatory: hotelMandatory,
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
      })
      .select('id')
      .single();

    if (insertError || !booking) {
      console.log('Insert booking failed', insertError);
      return fail('server_error', 'Could not start the booking. Please try again.');
    }

    // ───── تسجيل الموافقة ─────
    // لا نوقف الحجز إن فشل التسجيل (نسجّل الخطأ فقط)، حتى لا يخسر العميل الغرفة.
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
      receipt_email: email,
      description: `Flynoom hotel booking ${clientReference}`,
      metadata: {
        booking_id: booking.id,
        client_reference: clientReference,
        user_id: user.id,
        supplier: 'hotelbeds',
        terms_version: termsVersion,
        privacy_version: privacyVersion,
      },
    });

    await admin
      .from('bookings')
      .update({ payment_intent_id: intent.id, updated_at: new Date().toISOString() })
      .eq('id', booking.id);

    console.log(
      `Prepared ${clientReference} booking=${booking.id} rateType=${rate.rateType} ` +
        `net=${net} ${supplierCurrency} price=${price} charge=${chargeUsd} USD`,
    );

    return ok({
      bookingId: booking.id,
      clientReference,
      clientSecret: intent.client_secret,
      chargeAmount: chargeUsd,
      chargeCurrency: 'USD',
      supplierCurrency,
      supplierPrice: price,
      priceChanged,
      roomName: room.name ?? null,
      boardName: rate.boardName ?? null,
      rateClass: rate.rateClass ?? null,
      rateComments,
      cancellationPolicies: policies,
      payAtHotelUsd: atHotel.totalUsd,
      atHotelFees: atHotel.fees,
      totalUsd: round2(chargeUsd + atHotel.totalUsd),
    });
  } catch (e) {
    console.log('hotelbeds-prepare error', String(e));
    return fail('server_error', 'Something went wrong. Please try again.');
  }
});