// supabase/functions/hotelbeds-resend-confirmation/index.ts
//
// يعيد إرسال بريد تأكيد الحجز (نفس الرسالة الأصلية: القسيمة كاملة) — للمدير فقط.
// الاستخدام: العميل يقول "لم يصلني إيميل التأكيد" → زر في مكتب الحجوزات.
//
// المدخلات: { bookingId, toEmail?, saveEmail? }
//   toEmail اختياري: إن لم يُرسل، يذهب البريد إلى holder_email المحفوظ في الحجز.
//   saveEmail=true: يحفظ toEmail بريدًا للحجز (لرسائل الإلغاء لاحقًا) ويسجّل
//   التغيير في booking_email_changes (القديم، الجديد، المدير، الوقت).
//
// النشر (تحتاج تسجيل الدخول، فلا تستخدم --no-verify-jwt):
//   supabase functions deploy hotelbeds-resend-confirmation --project-ref nomgbttkfzhgbmbyidpy

import { adminClient, corsHeaders, fail, getUser, ok } from '../_shared/hotelbeds.ts';
import { bookingConfirmationEmail, sendEmail } from '../_shared/email.ts';

const SUPABASE_URL = Deno.env.get('SUPABASE_URL') ?? '';
const SUPABASE_ANON_KEY = Deno.env.get('SUPABASE_ANON_KEY') ?? '';

/// هل صاحب الطلب مدير؟ public.is_admin() بتوكن المستخدم نفسه.
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

const EMAIL_RE = /^[^\s@]+@[^\s@]+\.[^\s@]{2,}$/;

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders });

  const admin = adminClient();
  try {
    const user = await getUser(req, admin);
    if (!user) return fail('unauthorized', 'Please sign in.');
    if (!(await isAdminRequest(req))) return fail('forbidden', 'Admins only.');

    const body = await req.json().catch(() => ({}));
    const bookingId = String(body.bookingId ?? '');
    const override = String(body.toEmail ?? '').trim();

    if (override && !EMAIL_RE.test(override)) {
      return fail('invalid_email', 'The email address is not valid.');
    }

    const { data: booking } = await admin
      .from('bookings')
      .select('*')
      .eq('id', bookingId)
      .maybeSingle();

    if (!booking || !['hotelbeds', 'liteapi'].includes(booking.supplier)) return fail('not_found', 'Booking not found.');
    if (booking.status !== 'confirmed') {
      return fail('invalid_state', 'Only confirmed bookings can have their confirmation resent.');
    }

    const to = override || booking.holder_email;
    if (!to) return fail('no_email', 'This booking has no email address. Enter one to send to.');

    // حفظ البريد المصحّح في الحجز + سجل تدقيق.
    const oldEmail = String(booking.holder_email ?? '');
    if (body.saveEmail === true && override && override.toLowerCase() !== oldEmail.toLowerCase()) {
      const { error: upErr } = await admin
        .from('bookings')
        .update({ holder_email: override, updated_at: new Date().toISOString() })
        .eq('id', bookingId);
      if (upErr) {
        console.log('EMAIL UPDATE FAILED', bookingId, upErr.message);
        return fail('update_failed', 'Could not save the new email address.');
      }
      const { error: logErr } = await admin.from('booking_email_changes').insert({
        booking_id: bookingId,
        old_email: oldEmail || null,
        new_email: override,
        changed_by: user.id,
      });
      if (logErr) console.log('EMAIL CHANGE LOG FAILED', bookingId, logErr.message);
      console.log(`EMAIL CHANGED ${booking.client_reference}: ${oldEmail} -> ${override} by_admin=${user.id}`);
    }

    const sent = await sendEmail(to, bookingConfirmationEmail(booking));
    console.log(
      `CONFIRMATION RESENT ${booking.client_reference} ref=${booking.supplier_reference} to=${to} ` +
        `by_admin=${user.id} sent=${sent}`,
    );
    if (!sent) return fail('email_failed', 'The email could not be sent. Check the function logs.');

    return ok({ status: 'sent', to });
  } catch (e) {
    console.log('hotelbeds-resend-confirmation error', String(e));
    return fail('server_error', 'Something went wrong. Please try again.');
  }
});
