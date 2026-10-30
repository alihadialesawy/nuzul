// supabase/functions/disputes-sync/index.ts
//
// مزامنة يدوية للاعتراضات من Stripe (زر "مزامنة" في شاشة الاعتراضات) — للمدير فقط.
// احتياط إن فات الـ webhook حدثًا، أو لجلب اعتراضات قديمة.
//
// النشر:
//   supabase functions deploy disputes-sync --project-ref nomgbttkfzhgbmbyidpy

import Stripe from 'npm:stripe@14.21.0';
import { adminClient, corsHeaders, fail, getUser, ok } from '../_shared/hotelbeds.ts';
import { upsertDispute } from '../_shared/disputes.ts';

const stripe = new Stripe(Deno.env.get('STRIPE_SECRET_KEY') ?? '', {
  apiVersion: '2023-10-16',
  httpClient: Stripe.createFetchHttpClient(),
});

const SUPABASE_URL = Deno.env.get('SUPABASE_URL') ?? '';
const SUPABASE_ANON_KEY = Deno.env.get('SUPABASE_ANON_KEY') ?? '';

async function isAdminRequest(req: Request): Promise<boolean> {
  const auth = req.headers.get('Authorization') ?? '';
  if (!auth || !SUPABASE_URL || !SUPABASE_ANON_KEY) return false;
  try {
    const res = await fetch(`${SUPABASE_URL}/rest/v1/rpc/is_admin`, {
      method: 'POST',
      headers: { apikey: SUPABASE_ANON_KEY, Authorization: auth, 'Content-Type': 'application/json' },
      body: '{}',
    });
    return res.ok && (await res.json()) === true;
  } catch {
    return false;
  }
}

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders });
  const admin = adminClient();
  try {
    const user = await getUser(req, admin);
    if (!user) return fail('unauthorized', 'Please sign in.');
    if (!(await isAdminRequest(req))) return fail('forbidden', 'Admins only.');

    let count = 0;
    let startingAfter: string | undefined;
    for (let page = 0; page < 5; page++) {
      const list = await stripe.disputes.list({ limit: 100, starting_after: startingAfter });
      for (const d of list.data) {
        await upsertDispute(admin, d);
        count++;
      }
      if (!list.has_more || list.data.length === 0) break;
      startingAfter = list.data[list.data.length - 1].id;
    }
    console.log(`DISPUTES SYNCED ${count} by_admin=${user.id}`);
    return ok({ synced: count });
  } catch (e) {
    console.log('disputes-sync error', String(e));
    return fail('server_error', 'Could not sync disputes from Stripe.');
  }
});