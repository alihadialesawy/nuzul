// supabase/functions/hotelbeds-book/index.ts
//
// الخطوة 2 من الحجز (بعد أن يُدخل العميل بطاقته ويُحجز المبلغ عليها):
//
// 1) يتحقق أن الحجز يخص المستخدم، وأن حالته awaiting_payment.
// 2) يتحقق من Stripe أن المبلغ محجوز فعلًا (requires_capture) وبنفس القيمة.
// 3) يقفل الحجز (processing) حتى لا يُنفَّذ مرتين.
// 4) يرسل Booking لـ HotelBeds (مهلة 60+ ثانية، شرط HotelBeds).
// 5) نجح → سحب المبلغ (capture) + حالة confirmed + رقم حجز HotelBeds.
//    رفضت HotelBeds → إلغاء حجز المبلغ (لا يُسحب شيء) + حالة failed.
//    مهلة/خطأ شبكة (حالة غير معروفة) → needs_attention، ولا نلغي المبلغ
//    تلقائيًا؛ يُراجَع يدويًا عبر clientReference (الحجز ربما تم عند HotelBeds).
//
// المدخلات: { bookingId, reviewAccepted }
//
// الموافقة: يسجّل في booking_consents أن العميل راجع السعر النهائي وسياسة
// الإلغاء ووافق عليهما قبل حجز المبلغ (الوقت، IP، المتصفح، المبلغ، السياسة).

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
import { bookingConfirmationEmail, sendEmail } from '../_shared/email.ts';

const stripe = new Stripe(Deno.env.get('STRIPE_SECRET_KEY') ?? '', {
  apiVersion: '2023-10-16',
  httpClient: Stripe.createFetchHttpClient(),
});

// HotelBeds تطلب ألا تقل مهلة الحجز عن 60 ثانية.
const BOOKING_TIMEOUT_MS = 65000;

// نسبة الزيادة المسموحة في السعر بين CheckRate والحجز (٪). بدونها ترفض
// HotelBeds الحجز عند أي فرق ولو سنتًا ("Price has changed"). هامش الصرف
// (FX_BUFFER_PERCENT) يغطي هذا الفرق. تُضبط من Secrets: HOTELBEDS_BOOKING_TOLERANCE.
/// عنوان IP الحقيقي للعميل (أول عنوان في x-forwarded-for).
function clientIp(req: Request): string | null {
  const fwd = req.headers.get('x-forwarded-for');
  if (fwd) return fwd.split(',')[0].trim() || null;
  return req.headers.get('cf-connecting-ip') ?? req.headers.get('x-real-ip') ?? null;
}

const REVIEW_CONSENT_TEXT =
  'Customer reviewed the final price, cancellation policy and hotel notes, and tapped "Agree and pay" before authorizing the card.';

const BOOKING_TOLERANCE = Number(Deno.env.get('HOTELBEDS_BOOKING_TOLERANCE') ?? '2') || 0;

/// الولايات التي لا نبيع لسكانها حتى نسجّل فيها كـ Seller of Travel.
/// ⚠️ عند التسجيل في ولاية: احذفها من هنا، ومن نص مربع الإقرار في
/// booking_page.dart، ومن البند 3 في شروط الخدمة.
const RESTRICTED_STATE_NAMES: Record<string, string> = {
  CA: 'California',
  FL: 'Florida',
  HI: 'Hawaii',
  WA: 'Washington',
};

/// ولاية الرمز البريدي الأمريكي (أول 3 أرقام) — للولايات المقيّدة فقط.
function restrictedStateFromZip(zip: string): string | null {
  const z = Number(zip.replace(/\D/g, '').slice(0, 3));
  if (!Number.isFinite(z) || zip.replace(/\D/g, '').length < 5) return null;
  if (z >= 900 && z <= 961) return 'CA';
  if (z >= 320 && z <= 349 && z !== 340) return 'FL'; // 340 = بريد عسكري (AA)
  if (z >= 967 && z <= 968) return 'HI';
  if (z >= 980 && z <= 994) return 'WA';
  return null;
}

/// الولاية الأمريكية من أول 3 أرقام في الرمز البريدي (للتحليلات فقط).
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

/// يرجع رمز الولاية المقيّدة من عنوان فاتورة البطاقة، أو null.
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

/// رسائل HotelBeds التي تعني أن الحجز لم يتم يقينًا، حتى لو جاءت برمز 5xx.
const PRICE_CHANGED_PATTERN = /price has changed|price difference exceeds/i;
const DEFINITE_REJECT_PATTERN =
  /price has changed|price difference exceeds|no availability|not available|insufficient allotment|allotment exceeded/i;

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders });

  const admin = adminClient();
  let bookingId = '';

  const setStatus = (fields: Record<string, unknown>) =>
    admin
      .from('bookings')
      .update({ ...fields, updated_at: new Date().toISOString() })
      .eq('id', bookingId);

  try {
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

    // تكرار الطلب بعد النجاح: نرجع نفس النتيجة.
    if (booking.status === 'confirmed') {
      return ok({
        status: 'confirmed',
        reference: booking.supplier_reference,
        clientReference: booking.client_reference,
      });
    }
    if (booking.status !== 'awaiting_payment' || !booking.payment_intent_id) {
      return fail('invalid_state', 'This booking can no longer be completed.', { status: booking.status });
    }

    // ───── التحقق من الدفع ─────
    const intent = await stripe.paymentIntents.retrieve(booking.payment_intent_id, {
      expand: ['payment_method'],
    });
    const expectedCents = Math.round(Number(booking.charge_amount) * 100);
    if (
      intent.metadata?.booking_id !== bookingId ||
      intent.currency !== 'usd' ||
      intent.amount !== expectedCents
    ) {
      console.log('Payment mismatch', bookingId, intent.id);
      return fail('payment_mismatch', 'Payment does not match this booking.');
    }
    if (intent.status !== 'requires_capture') {
      return fail('payment_incomplete', 'Your card was not authorized. Please try again.', {
        paymentStatus: intent.status,
      });
    }

    // ───── منع سكان الولايات غير المسجّل فيها (Seller of Travel) ─────
    // نعتمد على الرمز البريدي لعنوان فاتورة البطاقة: يجمعه Stripe على الويب
    // والموبايل، ويتحقق منه بنك العميل، فهو أقوى من إقرار العميل وحده.
    const restricted = restrictedStateFromIntent(intent);
    if (restricted) {
      console.log(`RESTRICTED STATE ${booking.client_reference}: ${restricted}`);
      try {
        await stripe.paymentIntents.cancel(intent.id);
      } catch (e) {
        console.log('Cancel intent failed', String(e));
      }
      await setStatus({ status: 'failed', failure_reason: `restricted_state:${restricted}` });
      return fail(
        'state_not_supported',
        `We can't accept bookings from residents of ${RESTRICTED_STATE_NAMES[restricted]} yet. ` +
          'Your card has not been charged.',
      );
    }

    // ───── نوع البطاقة وآخر 4 أرقام (للتحقق من هوية العميل عند الاتصال) ─────
    // Stripe لا يعطي رقم البطاقة كاملًا أبدًا؛ هذه البيانات آمنة للتخزين.
    const pmObj: any = typeof intent.payment_method === 'object' ? intent.payment_method : null;
    const card = pmObj?.card;
    if (card?.last4) {
      const { error: cardErr } = await admin
        .from('bookings')
        .update({ card_brand: card.brand ?? null, card_last4: card.last4 })
        .eq('id', bookingId);
      console.log(
        cardErr
          ? `CARD SAVE FAILED ${booking.client_reference}: ${cardErr.message}`
          : `CARD SAVED ${booking.client_reference}: ${card.brand} ${card.last4}`,
      );
    } else {
      console.log(
        `CARD INFO MISSING ${booking.client_reference}: payment_method=` +
          (pmObj ? `object type=${pmObj.type}` : String(intent.payment_method)),
      );
    }

    // ───── موقع العميل من عنوان فاتورة البطاقة (للتحليلات) ─────
    // نحفظ الدولة والولاية وأول 3 أرقام فقط من الرمز البريدي.
    {
      const addr = pmObj?.billing_details?.address ?? {};
      const country = String(addr.country ?? card?.country ?? '').toUpperCase() || null;
      const zip = String(addr.postal_code ?? '').replace(/\D/g, '');
      const state =
        String(addr.state ?? '').toUpperCase() ||
        (country === 'US' || !country ? usStateFromZip(zip) : null) ||
        null;
      const { error: billErr } = await admin
        .from('bookings')
        .update({
          billing_country: country,
          billing_state: state,
          billing_postal3: zip.length >= 3 ? zip.slice(0, 3) : null,
        })
        .eq('id', bookingId);
      if (billErr) console.log(`BILLING SAVE FAILED ${booking.client_reference}: ${billErr.message}`);
    }

    // ───── تسجيل موافقة المراجعة النهائية ─────
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
    if (!locked || locked.length === 0) {
      return fail('invalid_state', 'This booking is already being processed.');
    }

    // ───── Booking عند HotelBeds ─────
    const bookingRQ = {
      holder: { name: booking.holder_first_name, surname: booking.holder_last_name },
      rooms: [{ rateKey: booking.rate_key }],
      clientReference: booking.client_reference,
      remark: '',
      tolerance: BOOKING_TOLERANCE,
    };

    let hbRes: Response;
    try {
      hbRes = await fetchWithTimeout(
        `${HOTELBEDS_BASE_URL}/hotel-api/1.0/bookings`,
        { method: 'POST', headers: await hotelbedsHeaders(), body: JSON.stringify(bookingRQ) },
        BOOKING_TIMEOUT_MS,
      );
    } catch (e) {
      // حالة غير معروفة: ربما تم الحجز عند HotelBeds. لا نلغي المبلغ تلقائيًا.
      console.log(`BOOKING UNKNOWN ${booking.client_reference}:`, String(e));
      await setStatus({ status: 'needs_attention', failure_reason: `timeout/network: ${String(e)}` });
      return ok({ status: 'pending', clientReference: booking.client_reference });
    }

    const hbData = await hbRes.json().catch(() => ({}));
    const hb = hbData?.booking;

    // رفض صريح تعيده HotelBeds أحيانًا برمز 5xx (مثل "Price has changed"):
    // الحجز لم يتم يقينًا، فنعامله كرفض عادي (إلغاء حجز المبلغ + failed)
    // بدل needs_attention.
    const hbErrorMsg = String(hbData?.error?.message ?? '');
    const definiteReject = DEFINITE_REJECT_PATTERN.test(hbErrorMsg);
    const priceChanged = PRICE_CHANGED_PATTERN.test(hbErrorMsg);

    // خطأ داخلي عند HotelBeds (5xx): لا نعرف يقينًا هل تم الحجز. لا نلغي
    // المبلغ المحجوز تلقائيًا؛ يُراجَع يدويًا عبر clientReference.
    if (hbRes.status >= 500 && !definiteReject) {
      const reason = hbData?.error?.message ?? `HTTP ${hbRes.status}`;
      console.log(`BOOKING UNKNOWN ${booking.client_reference}: supplier ${reason}`);
      await setStatus({
        status: 'needs_attention',
        failure_reason: `supplier ${hbRes.status}: ${reason}`,
        supplier_response: hbData,
      });
      return ok({ status: 'pending', clientReference: booking.client_reference });
    }

    if (!hbRes.ok || !hb?.reference || hb.status !== 'CONFIRMED') {
      // رفض صريح من HotelBeds → إلغاء حجز المبلغ، العميل لا يدفع شيئًا.
      const reason = hbData?.error?.message ?? `HTTP ${hbRes.status} status=${hb?.status ?? 'none'}`;
      console.log(`BOOKING FAILED ${booking.client_reference}: ${reason}`);
      try {
        await stripe.paymentIntents.cancel(intent.id);
      } catch (e) {
        console.log('Cancel intent failed', String(e));
      }
      await setStatus({ status: 'failed', failure_reason: reason, supplier_response: hbData });
      if (priceChanged) {
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

    // ───── نجح الحجز → سحب المبلغ ─────
    const supplierFields = {
      supplier_reference: hb.reference,
      supplier_name: hb.hotel?.supplier?.name ?? null,
      supplier_vat: hb.hotel?.supplier?.vatNumber ?? null,
      supplier_response: hbData,
    };

    try {
      await stripe.paymentIntents.capture(intent.id);
    } catch (e) {
      // الحجز مؤكد عند الفندق لكن السحب فشل → مراجعة يدوية فورية.
      console.log(`CAPTURE FAILED ${booking.client_reference} ref=${hb.reference}:`, String(e));
      await setStatus({ status: 'needs_attention', failure_reason: `capture failed: ${String(e)}`, ...supplierFields });
      return ok({ status: 'pending', clientReference: booking.client_reference });
    }

    // عنوان الفندق وهاتفه للقسيمة (لا يوقف الحجز لو فشل).
    const contact = await fetchHotelContact(String(booking.hotel_code ?? hb.hotel?.code ?? ''));

    await setStatus({
      status: 'confirmed',
      failure_reason: null,
      hotel_address: contact.address,
      hotel_phone: contact.phone,
      ...supplierFields,
    });
    console.log(`BOOKING CONFIRMED ${booking.client_reference} ref=${hb.reference}`);

    // بريد التأكيد مع القسيمة (فشله لا يؤثر على الحجز).
    const { data: confirmed } = await admin.from('bookings').select('*').eq('id', bookingId).maybeSingle();
    if (confirmed) {
      await sendEmail(confirmed.holder_email, bookingConfirmationEmail(confirmed));
    }

    return ok({
      status: 'confirmed',
      reference: hb.reference,
      clientReference: booking.client_reference,
    });
  } catch (e) {
    console.log('hotelbeds-book error', String(e));
    if (bookingId) {
      await setStatus({ status: 'needs_attention', failure_reason: `server error: ${String(e)}` })
        .eq('status', 'processing');
    }
    return fail('server_error', 'Something went wrong. We will review your booking and contact you.');
  }
});