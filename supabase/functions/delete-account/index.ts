// supabase/functions/delete-account/index.ts
//
// حذف حساب المستخدم من داخل التطبيق (شرط Apple 5.1.1(v) وGoogle Play).
//
// ما يحدث:
//  1) يتحقق من المستخدم (JWT) ومن كلمة التأكيد "DELETE".
//  2) يرفض إن كان لديه حجز قائم (مؤكد لم تنتهِ إقامته، أو قيد المعالجة)،
//     ويطلب إلغاءه أولًا — حتى لا يضيع حجز مدفوع بلا صاحب حساب.
//  3) يحذف البيانات الشخصية غير المالية:
//     المسافرون المحفوظون (جوازات)، المفضلة، تنبيهات الأسعار، منشورات
//     وتعليقات وإعجابات المجتمع، ويمسح الاسم والهاتف من الملف الشخصي.
//  4) يحتفظ بسجلات الحجز والدفع (bookings, flight_bookings, duffel_bookings,
//     car_bookings) كما يشترط القانون (إشعار الخصوصية، البند 5)، ويفك ربط
//     طلبات المجموعات بالحساب.
//  5) يحذف المستخدم من Supabase Auth حذفًا "ناعمًا" (soft delete): لا يمكنه
//     الدخول بعد ذلك، وتُزال هويته من auth، ولا تُحذف سجلات الحجز المرتبطة.
//  6) يسجّل العملية في account_deletions، ويرسل بريد تأكيد للعميل وتنبيهًا للمدير.
//
// النشر (يحتاج تسجيل الدخول، فلا تستخدم --no-verify-jwt):
//   supabase functions deploy delete-account --project-ref nomgbttkfzhgbmbyidpy

import { adminClient, corsHeaders, fail, getUser, ok } from '../_shared/hotelbeds.ts';
import { sendEmail } from '../_shared/email.ts';

const ADMIN_EMAIL = Deno.env.get('ADMIN_EMAIL') ?? 'ali@flynoom.com';

/// جداول بيانات شخصية تُحذف صفوفها بالكامل (العمود user_id).
const DELETE_TABLES = [
  'travelers',
  'favorites',
  'price_watches',
  'community_post_likes',
  'community_post_comments',
  'community_posts',
];

/// جداول نحتفظ بها لكن نفك ربطها بالحساب (user_id → null).
const UNLINK_TABLES = ['group_stay_requests'];

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders });

  const admin = adminClient();
  try {
    const user = await getUser(req, admin);
    if (!user) return fail('unauthorized', 'Please sign in.');

    const body = await req.json().catch(() => ({}));
    if (String(body.confirm ?? '').trim().toUpperCase() !== 'DELETE') {
      return fail('confirm_required', 'Type DELETE to confirm.');
    }

    const email = user.email ?? null;
    const today = new Date().toISOString().slice(0, 10);

    // ───── حجوزات قائمة؟ ─────
    const { data: active } = await admin
      .from('bookings')
      .select('id, status, check_out, client_reference, hotel_name')
      .eq('user_id', user.id)
      .or(`and(status.eq.confirmed,check_out.gte.${today}),status.in.(processing,needs_attention)`);

    if (active && active.length > 0) {
      await admin.from('account_deletions').insert({
        user_id: user.id,
        email,
        status: 'blocked',
        details: { reason: 'active_bookings', bookings: active.map((b) => b.id) },
      });
      return fail(
        'active_bookings',
        'You have an upcoming or in-progress booking. Please cancel it, or wait until your stay ends, before deleting your account.',
        { bookings: active.map((b) => ({ ref: b.client_reference, hotel: b.hotel_name })) },
      );
    }

    const { data: logRow } = await admin
      .from('account_deletions')
      .insert({ user_id: user.id, email, status: 'requested' })
      .select('id')
      .single();

    const results: Record<string, string> = {};

    // ───── حذف البيانات الشخصية ─────
    for (const table of DELETE_TABLES) {
      const { error } = await admin.from(table).delete().eq('user_id', user.id);
      results[table] = error ? `error: ${error.message}` : 'deleted';
    }
    for (const table of UNLINK_TABLES) {
      const { error } = await admin.from(table).update({ user_id: null }).eq('user_id', user.id);
      results[table] = error ? `error: ${error.message}` : 'unlinked';
    }
    {
      // ⚠️ لا نحذف صف profiles: جدول bookings مرتبط به (لوحة الإدارة تقرأ
      // bookings → profiles)، وقد يكون الربط ON DELETE CASCADE فيمسح سجلات
      // الحجز المالية. لذلك نمسح البيانات الشخصية من الصف بدل حذفه.
      const { error } = await admin
        .from('profiles')
        .update({ display_name: 'Deleted user', full_name: null, phone: null })
        .eq('id', user.id);
      results['profiles'] = error ? `error: ${error.message}` : 'anonymized';
    }

    // ───── حذف المستخدم من Auth (soft delete) ─────
    const { error: authError } = await admin.auth.admin.deleteUser(user.id, true);
    if (authError) {
      console.log('DELETE ACCOUNT auth failed', user.id, authError.message);
      if (logRow) {
        await admin.from('account_deletions').update({
          status: 'failed',
          details: { ...results, auth: authError.message },
        }).eq('id', logRow.id);
      }
      await sendEmail(ADMIN_EMAIL, {
        subject: `Account deletion FAILED — needs manual action (${email ?? user.id})`,
        html: `<p>Auth deletion failed for user ${user.id} (${email ?? 'no email'}): ${authError.message}</p>
<pre>${JSON.stringify(results, null, 2)}</pre>`,
      }).catch(() => false);
      return fail(
        'deletion_pending',
        'We received your request but could not finish it automatically. Our team will complete it within 30 days and email you.',
      );
    }

    if (logRow) {
      await admin.from('account_deletions').update({
        status: 'completed',
        completed_at: new Date().toISOString(),
        details: results,
      }).eq('id', logRow.id);
    }

    console.log('ACCOUNT DELETED', user.id, JSON.stringify(results));

    if (email) {
      await sendEmail(email, {
        subject: 'Your Flynoom account has been deleted',
        html: `<!doctype html><html><body style="font-family:Arial,Helvetica,sans-serif;color:#111827">
<div style="max-width:560px;margin:0 auto;padding:24px">
<div style="font-size:22px;font-weight:900;letter-spacing:2px;color:#0b3a6b">FLYNOOM</div>
<h2>Your account has been deleted</h2>
<p>As you requested, we deleted your Flynoom account and the personal data linked to it (saved travelers, favorites, price alerts, and community posts).</p>
<p>As explained in our Privacy Notice, we keep booking and payment records for as long as the law requires (generally up to seven years), and then delete them.</p>
<p>If you did not request this, reply to this email right away.</p>
<p style="color:#6b7280;font-size:12px">FLYNOOM LLC · flynoom.com</p>
</div></body></html>`,
      }).catch(() => false);
    }
    await sendEmail(ADMIN_EMAIL, {
      subject: `Account deleted: ${email ?? user.id}`,
      html: `<p>User ${user.id} (${email ?? 'no email'}) deleted their account from the app.</p>
<pre>${JSON.stringify(results, null, 2)}</pre>`,
    }).catch(() => false);

    return ok({ status: 'deleted' });
  } catch (e) {
    console.log('delete-account error', String(e));
    return fail('server_error', 'Something went wrong. Please try again or email support@flynoom.com.');
  }
});