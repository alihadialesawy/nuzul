// supabase/functions/welcome-email/index.ts
//
// إيميل ترحيب واحد لكل حساب جديد، بلغة الزبون.
// يستدعيه التطبيق بعد تسجيل الدخول (app.dart)، والدالة تقرر وحدها هل ترسل:
//   • المستخدم مسجّل الدخول (JWT) وبريده مؤكَّد.
//   • الحساب جديد (أُنشئ خلال WELCOME_MAX_AGE_DAYS، افتراضيًا 7 أيام) —
//     حتى لا يصل ترحيب للحسابات القديمة عند أول دخول بعد نشر الميزة.
//   • لم يُرسَل له ترحيب من قبل (جدول welcome_emails، المفتاح user_id).
//
// ⚠️ هذا إيميل علاقة بالخدمة (طلب الزبون إنشاء حساب)، لا تسويق: لا عروض ولا
// خصومات فيه. أي عروض لاحقًا تحتاج موافقة صريحة (إشعار الخصوصية، البند 2).
//
// الطلب: POST { locale: "ar" }   (مع Authorization: Bearer <JWT>)
// الرد:  { ok, sent: true|false, reason? }

import { serve } from 'https://deno.land/std@0.168.0/http/server.ts';
import { adminClient, corsHeaders, fail, getUser, ok } from '../_shared/hotelbeds.ts';
import { emailLocale, sendEmail, welcomeEmail } from '../_shared/email.ts';

const MAX_AGE_DAYS = Number(Deno.env.get('WELCOME_MAX_AGE_DAYS') ?? '7') || 7;

function firstName(user: any): string {
  const m = user?.user_metadata ?? {};
  const raw = String(m.first_name ?? m.given_name ?? m.full_name ?? m.name ?? '').trim();
  return raw.split(/\s+/)[0] ?? '';
}

serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders });
  try {
    const admin = adminClient();
    const user = await getUser(req, admin);
    if (!user) return fail('unauthorized', 'Sign in required.');

    if (!user.email || !user.email_confirmed_at) return ok({ sent: false, reason: 'email_not_confirmed' });

    const createdMs = Date.parse(String(user.created_at ?? ''));
    if (!Number.isFinite(createdMs) || Date.now() - createdMs > MAX_AGE_DAYS * 86400000) {
      return ok({ sent: false, reason: 'not_new' });
    }

    const body = await req.json().catch(() => ({}));
    const locale = emailLocale(body?.locale);

    // نحجز السطر أولًا (المفتاح user_id يمنع التكرار حتى مع طلبين متزامنين).
    const { error: insertError } = await admin
      .from('welcome_emails')
      .insert({ user_id: user.id, email: user.email, locale, sent: false });
    if (insertError) {
      if (insertError.code === '23505') return ok({ sent: false, reason: 'already_sent' });
      console.log('WELCOME insert failed', insertError.message);
      return fail('server_error', 'Could not send right now.');
    }

    const sent = await sendEmail(user.email, welcomeEmail(locale, firstName(user)));
    await admin.from('welcome_emails').update({ sent, sent_at: new Date().toISOString() }).eq('user_id', user.id);
    console.log(`WELCOME ${sent ? 'SENT' : 'FAILED'} ${user.id} ${locale}`);
    return ok({ sent });
  } catch (e) {
    console.log('welcome-email error', String(e));
    return fail('server_error', 'Could not send right now.');
  }
});