// supabase/functions/_shared/disputes.ts
//
// حفظ اعتراض Stripe (Dispute) في جدول disputes وربطه بالحجز.
// يستخدمه stripe-webhook (لحظة وصول الاعتراض) و disputes-sync (مزامنة يدوية).

import type { SupabaseClient } from 'jsr:@supabase/supabase-js@2';

/// يحفظ/يحدّث الاعتراض. يرجع الحجز المرتبط (أو null) وهل هو جديد.
export async function upsertDispute(
  admin: SupabaseClient,
  d: any,
): Promise<{ booking: any | null; isNew: boolean }> {
  const pi = typeof d.payment_intent === 'string' ? d.payment_intent : d.payment_intent?.id ?? null;
  const charge = typeof d.charge === 'string' ? d.charge : d.charge?.id ?? null;

  let booking: any = null;
  if (pi) {
    const { data } = await admin
      .from('bookings')
      .select('id, client_reference, hotel_name, holder_first_name, holder_last_name, holder_email')
      .eq('payment_intent_id', pi)
      .maybeSingle();
    booking = data ?? null;
  }

  const { data: existing } = await admin.from('disputes').select('id').eq('id', d.id).maybeSingle();

  const dueUnix = d?.evidence_details?.due_by;
  const row = {
    id: d.id,
    payment_intent_id: pi,
    charge_id: charge,
    booking_id: booking?.id ?? null,
    client_reference: booking?.client_reference ?? null,
    amount: typeof d.amount === 'number' ? d.amount / 100 : null,
    currency: d.currency ?? null,
    reason: d.reason ?? null,
    status: d.status ?? null,
    evidence_due_by: dueUnix ? new Date(dueUnix * 1000).toISOString() : null,
    livemode: d.livemode === true,
    created_at: d.created ? new Date(d.created * 1000).toISOString() : new Date().toISOString(),
    updated_at: new Date().toISOString(),
    raw: d,
  };

  const { error } = await admin.from('disputes').upsert(row, { onConflict: 'id' });
  if (error) console.log('DISPUTE UPSERT FAILED', d.id, error.message);
  return { booking, isNew: !existing };
}