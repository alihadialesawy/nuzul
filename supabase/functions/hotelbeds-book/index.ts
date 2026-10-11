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
// المدخلات: { bookingId }

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
const BOOKING_TOLERANCE = Number(Deno.env.get('HOTELBEDS_BOOKING_TOLERANCE') ?? '2') || 0;

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
    const intent = await stripe.paymentIntents.retrieve(booking.payment_intent_id);
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

    // خطأ داخلي عند HotelBeds (5xx): لا نعرف يقينًا هل تم الحجز. لا نلغي
    // المبلغ المحجوز تلقائيًا؛ يُراجَع يدويًا عبر clientReference.
    if (hbRes.status >= 500) {
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