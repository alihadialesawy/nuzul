// supabase/functions/group-request-notify/index.ts
//
// يرسل لك بريدًا فور وصول طلب جديد في جدول group_stay_requests.
// يستدعيه Database Webhook في Supabase عند كل INSERT على الجدول.
//
// Secrets المطلوبة:
//   RESEND_API_KEY   (موجود)
//   WEBHOOK_KEY      كلمة سرية تضعها أيضًا في رأس الـ Webhook (x-webhook-key)
//   ADMIN_EMAIL      اختياري، الافتراضي: ali@flynoom.com
//   EMAIL_FROM       اختياري، الافتراضي: "Flynoom <bookings@flynoom.com>"
//
// النشر:
//   supabase functions deploy group-request-notify --project-ref nomgbttkfzhgbmbyidpy --no-verify-jwt
//
// ملاحظات:
//   • البريد يذهب إليك أنت فقط، لا إلى العميل؛ لأن أي زائر يستطيع كتابة
//     أي بريد في النموذج، ولا نريد أن يُستغل نطاقنا لإرسال رسائل لأشخاص لم يطلبوها.
//   • Reply-To = بريد العميل، فتضغط "رد" وتراسله مباشرة.

const RESEND_API_KEY = Deno.env.get('RESEND_API_KEY') ?? '';
const WEBHOOK_KEY = Deno.env.get('WEBHOOK_KEY') ?? '';
const ADMIN_EMAIL = Deno.env.get('ADMIN_EMAIL') ?? 'ali@flynoom.com';
const EMAIL_FROM = Deno.env.get('EMAIL_FROM') ?? 'Flynoom <bookings@flynoom.com>';

const OCCASIONS: Record<string, string> = {
  umrah: 'Umrah / عمرة',
  wedding: 'Wedding / زفاف',
  event: 'Event / فعالية',
  family: 'Family / عائلة',
  other: 'Other / أخرى',
};

function esc(v: unknown): string {
  return String(v ?? '')
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;');
}

function nights(a: string, b: string): number {
  const x = Date.parse(a);
  const y = Date.parse(b);
  return Number.isFinite(x) && Number.isFinite(y) ? Math.max(1, Math.round((y - x) / 86400000)) : 0;
}

function row(label: string, value: string): string {
  return `<tr><td style="padding:5px 14px 5px 0;color:#6b7280;white-space:nowrap;vertical-align:top">${label}</td>` +
    `<td style="padding:5px 0;font-weight:600">${value}</td></tr>`;
}

function buildEmail(r: any): { subject: string; html: string } {
  const n = nights(r.check_in, r.check_out);
  const roomNights = n * Number(r.rooms ?? 0);
  const email = esc(r.contact_email);
  const phone = esc(r.contact_phone);
  const waPhone = String(r.contact_phone ?? '').replace(/[^\d]/g, '');

  const html = `<!doctype html><html><body style="margin:0;background:#f3f4f6;font-family:Arial,Helvetica,sans-serif;color:#111827">
<div style="max-width:640px;margin:0 auto;padding:24px 12px">
<div style="background:#ffffff;border-radius:10px;padding:28px">
<div style="font-size:22px;font-weight:900;letter-spacing:2px;color:#0b3a6b">FLYNOOM · GROUPS</div>
<h1 style="font-size:19px;margin:14px 0 4px">New group stay request</h1>
<p style="margin:0 0 14px;color:#374151">${esc(r.rooms)} rooms · ${n} nights · ${roomNights} room-nights</p>
<table style="border-collapse:collapse">
${row('Destination', esc(r.destination))}
${row('Check-in', esc(r.check_in))}
${row('Check-out', esc(r.check_out))}
${row('Rooms', esc(r.rooms))}
${row('Guests', esc(r.guests))}
${row('Occasion', esc(OCCASIONS[r.occasion] ?? r.occasion))}
${row('Name', esc(r.contact_name))}
${row('Email', `<a href="mailto:${email}">${email}</a>`)}
${row('Phone', `${phone}${waPhone ? ` · <a href="https://wa.me/${waPhone}">WhatsApp</a>` : ''}`)}
${row('Language', esc(r.language ?? '—'))}
${row('Signed-in user', r.user_id ? 'Yes' : 'No (guest)')}
${row('Received', esc(r.created_at))}
</table>
${r.notes ? `<div style="margin-top:16px;padding:12px;background:#f9fafb;border-radius:8px;white-space:pre-line">${esc(r.notes)}</div>` : ''}
<hr style="border:none;border-top:1px solid #e5e7eb;margin:22px 0">
<p style="font-size:13px;color:#6b7280;margin:0">
Request ID: ${esc(r.id)}<br>
Reply to this email to answer the customer directly. Then set the status to <b>quoted</b> in Supabase → group_stay_requests.
</p>
</div></div></body></html>`;

  return {
    subject: `Group request: ${r.rooms} rooms · ${r.destination} · ${r.check_in}`,
    html,
  };
}

Deno.serve(async (req) => {
  if (req.method !== 'POST') return new Response('Method not allowed', { status: 405 });

  // التحقق من أن الطلب جاء من الـ Webhook الخاص بنا.
  if (!WEBHOOK_KEY || req.headers.get('x-webhook-key') !== WEBHOOK_KEY) {
    return new Response('Unauthorized', { status: 401 });
  }

  let payload: any;
  try {
    payload = await req.json();
  } catch {
    return new Response('Bad JSON', { status: 400 });
  }

  if (payload?.type !== 'INSERT' || payload?.table !== 'group_stay_requests' || !payload?.record) {
    return new Response('Ignored', { status: 200 });
  }

  if (!RESEND_API_KEY) {
    console.log('GROUP NOTIFY SKIPPED: no RESEND_API_KEY');
    return new Response('No email key', { status: 200 });
  }

  const r = payload.record;
  const msg = buildEmail(r);

  try {
    const res = await fetch('https://api.resend.com/emails', {
      method: 'POST',
      headers: { 'Authorization': `Bearer ${RESEND_API_KEY}`, 'Content-Type': 'application/json' },
      body: JSON.stringify({
        from: EMAIL_FROM,
        to: [ADMIN_EMAIL],
        reply_to: r.contact_email ? [String(r.contact_email)] : undefined,
        subject: msg.subject,
        html: msg.html,
      }),
    });
    if (!res.ok) {
      console.log('GROUP NOTIFY FAILED', res.status, await res.text().catch(() => ''));
      return new Response('Email failed', { status: 200 });
    }
    console.log('GROUP NOTIFY SENT', r.id);
    return new Response('OK', { status: 200 });
  } catch (e) {
    console.log('GROUP NOTIFY ERROR', String(e));
    return new Response('Email error', { status: 200 });
  }
});