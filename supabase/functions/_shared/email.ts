// supabase/functions/_shared/email.ts
//
// رسائل البريد للعميل عبر Resend: تأكيد الحجز (مع القسيمة كاملة) وتأكيد الإلغاء.
// البريد لا يوقف الحجز أبدًا: أي فشل يُسجَّل في الـ Logs فقط.
//
// Secrets المطلوبة:
//   RESEND_API_KEY  (موجود)
//   EMAIL_FROM      اختياري، الافتراضي: "Flynoom <bookings@flynoom.com>"
//   EMAIL_REPLY_TO  اختياري، الافتراضي: ali@flynoom.com
//
// ⚠️ لا يعمل الإرسال من @flynoom.com قبل أن تصبح حالة النطاق Verified في Resend.

const RESEND_API_KEY = Deno.env.get('RESEND_API_KEY') ?? '';
const EMAIL_FROM = Deno.env.get('EMAIL_FROM') ?? 'Flynoom <bookings@flynoom.com>';
const EMAIL_REPLY_TO = Deno.env.get('EMAIL_REPLY_TO') ?? 'ali@flynoom.com';

function esc(v: unknown): string {
  return String(v ?? '')
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;');
}

function titleCase(s: string): string {
  return s.toLowerCase().replace(/(^|\s)(\S)/g, (_m, sp, c) => sp + c.toUpperCase());
}

function usd(n: unknown): string {
  const v = Number(n);
  return Number.isFinite(v) ? `$${v.toFixed(2)}` : '—';
}

/// "2026-11-10" → "Tue, Nov 10, 2026" (بدون تحويل منطقة زمنية).
function usDate(d: unknown): string {
  const m = /^(\d{4})-(\d{2})-(\d{2})/.exec(String(d ?? ''));
  if (!m) return esc(d);
  const dt = new Date(Date.UTC(+m[1], +m[2] - 1, +m[3]));
  return dt.toLocaleDateString('en-US', {
    weekday: 'short', month: 'short', day: 'numeric', year: 'numeric', timeZone: 'UTC',
  });
}

/// "2026-11-08T23:59:00-05:00" → "Nov 8, 2026 23:59" كما هو بتوقيت الفندق.
function hotelLocal(s: unknown): string {
  const m = /^(\d{4})-(\d{2})-(\d{2})T(\d{2}):(\d{2})/.exec(String(s ?? ''));
  if (!m) return esc(s);
  const dt = new Date(Date.UTC(+m[1], +m[2] - 1, +m[3]));
  const day = dt.toLocaleDateString('en-US', { month: 'short', day: 'numeric', year: 'numeric', timeZone: 'UTC' });
  return `${day} ${m[4]}:${m[5]}`;
}

function nights(b: any): number {
  const a = Date.parse(String(b.check_in).slice(0, 10));
  const c = Date.parse(String(b.check_out).slice(0, 10));
  return Number.isFinite(a) && Number.isFinite(c) ? Math.max(1, Math.round((c - a) / 86400000)) : 1;
}

function row(label: string, value: string): string {
  return `<tr><td style="padding:4px 12px 4px 0;color:#6b7280;white-space:nowrap;vertical-align:top">${label}</td>` +
    `<td style="padding:4px 0;font-weight:600">${value}</td></tr>`;
}

function section(title: string, body: string): string {
  return `<div style="margin-top:20px"><div style="font-size:12px;letter-spacing:1px;font-weight:700;color:#6b7280;text-transform:uppercase;margin-bottom:6px">${title}</div>${body}</div>`;
}

function layout(heading: string, intro: string, content: string): string {
  return `<!doctype html><html><body style="margin:0;background:#f3f4f6;font-family:Arial,Helvetica,sans-serif;color:#111827">
<div style="max-width:640px;margin:0 auto;padding:24px 12px">
<div style="background:#ffffff;border-radius:10px;padding:28px">
<div style="font-size:24px;font-weight:900;letter-spacing:2px;color:#0b3a6b">FLYNOOM</div>
<h1 style="font-size:20px;margin:16px 0 6px">${heading}</h1>
<p style="margin:0 0 8px;color:#374151">${intro}</p>
${content}
</div>
<p style="font-size:12px;color:#9ca3af;text-align:center;margin-top:16px">FLYNOOM LLC · flynoom.com · Questions? Reply to this email.</p>
</div></body></html>`;
}

function roomsHtml(b: any): string {
  const rooms: any[] = b?.supplier_response?.booking?.hotel?.rooms ?? [];
  if (rooms.length === 0) {
    return `<div>${esc(titleCase(String(b.room_name ?? '')))}${b.board_name ? ` · ${esc(titleCase(b.board_name))}` : ''}</div>`;
  }
  return rooms.map((r) => {
    const rate = r?.rates?.[0] ?? {};
    const paxes: any[] = r?.paxes ?? [];
    const ages = paxes.filter((p) => p?.type === 'CH').map((p) => p?.age).filter((a) => a != null);
    const adults = rate.adults ?? paxes.filter((p) => p?.type === 'AD').length;
    const children = rate.children ?? ages.length;
    return `<div style="margin-bottom:8px">
<div style="font-weight:600">${esc(rate.rooms ?? 1)} × ${esc(titleCase(String(r.name ?? '')))}</div>
${rate.boardName ? `<div>Board: ${esc(titleCase(rate.boardName))}</div>` : ''}
<div>Guests per room: ${esc(adults)} adult${adults == 1 ? '' : 's'}${children > 0 ? `, ${esc(children)} child${children == 1 ? '' : 'ren'}` : ''}${ages.length ? ` (ages ${esc(ages.join(', '))})` : ''}</div>
</div>`;
  }).join('');
}

function cancellationHtml(b: any): string {
  const policies: any[] = Array.isArray(b.cancellation_policies) ? [...b.cancellation_policies] : [];
  if (policies.length === 0) return '<div>Free cancellation.</div>';
  policies.sort((x, y) => String(x.from).localeCompare(String(y.from)));
  const now = Date.now();
  const first = policies[0];
  const firstTime = Date.parse(first.from);
  let html = '';
  if (Number.isFinite(firstTime) && firstTime > now) {
    html += `<div>Free cancellation until <b>${hotelLocal(first.from)}</b> (hotel local time).</div>`;
  }
  for (const p of policies) {
    const fee = p.customerFee ?? p.amountUsd;
    html += `<div style="color:#374151">From ${hotelLocal(p.from)}: cancellation fee ${usd(fee)}</div>`;
  }
  return html;
}

function payAtHotelHtml(b: any): string {
  const fees: any[] = Array.isArray(b.pay_at_hotel_fees) ? b.pay_at_hotel_fees : [];
  if (fees.length === 0) return '';
  const lines = fees.map((f) =>
    `<div>${esc(titleCase(String(f.type ?? 'Fee')))}: ${esc(Number(f.amount ?? 0).toFixed(2))} ${esc(f.currency ?? '')}</div>`
  ).join('');
  return section('Payable at the hotel',
    `${lines}<div style="font-size:12px;color:#6b7280">Mandatory fees not included in the amount paid online.</div>`);
}

export function bookingConfirmationEmail(b: any): { subject: string; html: string } {
  const comments = String(b.rate_comments ?? '').trim();
  const content =
    section('Booking', `<table style="border-collapse:collapse">
${row('Booking reference', `<span style="font-size:18px">${esc(b.supplier_reference)}</span>`)}
${row('Flynoom reference', esc(b.client_reference))}
${row('Amount paid', `${usd(b.charge_amount)} USD`)}
</table>`) +
    section('Hotel', `<div style="font-size:17px;font-weight:700">${esc(b.hotel_name)}</div>
<div>${esc(b.hotel_address ?? b.hotel_city ?? '')}</div>
${b.hotel_phone ? `<div>Phone: ${esc(b.hotel_phone)}</div>` : ''}`) +
    section('Stay', `<table style="border-collapse:collapse">
${row('Check-in', usDate(b.check_in))}
${row('Check-out', usDate(b.check_out))}
${row('Nights', String(nights(b)))}
${row('Lead guest', esc([b.holder_first_name, b.holder_last_name].filter(Boolean).join(' ')))}
</table>`) +
    section('Rooms', roomsHtml(b)) +
    payAtHotelHtml(b) +
    section('Cancellation policy', cancellationHtml(b)) +
    (comments ? section('Important information', `<div style="font-size:13px;color:#374151;white-space:pre-line">${esc(comments)}</div>`) : '') +
    `<hr style="border:none;border-top:1px solid #e5e7eb;margin:24px 0">
<p style="font-size:12px;color:#6b7280;margin:0">Payable through ${esc(b.supplier_name ?? 'HOTELBEDS')}, acting as agent for the service operating company, details of which can be provided upon request. VAT: ${esc(b.supplier_vat ?? '—')} Reference: ${esc(b.supplier_reference)}</p>`;

  return {
    subject: `Booking confirmed: ${b.hotel_name} · ${usDate(b.check_in)} (Ref ${b.supplier_reference})`,
    html: layout(
      'Your booking is confirmed',
      `Hi ${esc(b.holder_first_name ?? '')}, thank you for booking with Flynoom. Please show this email (or your booking reference) at check-in.`,
      content,
    ),
  };
}

export function cancellationEmail(b: any, fee: number, refund: number): { subject: string; html: string } {
  const content =
    section('Cancelled booking', `<table style="border-collapse:collapse">
${row('Hotel', esc(b.hotel_name))}
${row('Dates', `${usDate(b.check_in)} – ${usDate(b.check_out)}`)}
${row('Booking reference', esc(b.supplier_reference))}
${b.cancellation_reference ? row('Cancellation reference', esc(b.cancellation_reference)) : ''}
${row('Amount paid', `${usd(b.charge_amount)} USD`)}
${row('Cancellation fee', `${usd(fee)} USD`)}
${row('Refund', `${usd(refund)} USD`)}
</table>`) +
    (refund > 0
      ? `<p style="color:#374151">Your refund has been issued to the card you paid with. It usually appears within 5–10 business days, depending on your bank.</p>`
      : '');

  return {
    subject: `Booking cancelled: ${b.hotel_name} (Ref ${b.supplier_reference})`,
    html: layout(
      'Your booking has been cancelled',
      `Hi ${esc(b.holder_first_name ?? '')}, your booking has been cancelled as requested.`,
      content,
    ),
  };
}

/// يرسل البريد. لا يرمي أخطاء أبدًا (يرجع true/false).
export async function sendEmail(to: string | null | undefined, msg: { subject: string; html: string }): Promise<boolean> {
  if (!to || !RESEND_API_KEY) {
    console.log('EMAIL SKIPPED', !to ? 'no recipient' : 'no RESEND_API_KEY');
    return false;
  }
  try {
    const res = await fetch('https://api.resend.com/emails', {
      method: 'POST',
      headers: { 'Authorization': `Bearer ${RESEND_API_KEY}`, 'Content-Type': 'application/json' },
      body: JSON.stringify({
        from: EMAIL_FROM,
        to: [to],
        reply_to: EMAIL_REPLY_TO,
        subject: msg.subject,
        html: msg.html,
      }),
    });
    if (!res.ok) {
      console.log('EMAIL FAILED', res.status, await res.text().catch(() => ''));
      return false;
    }
    console.log('EMAIL SENT', to, msg.subject);
    return true;
  } catch (e) {
    console.log('EMAIL ERROR', String(e));
    return false;
  }
}