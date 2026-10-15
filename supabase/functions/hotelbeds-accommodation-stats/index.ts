// supabase/functions/hotelbeds-accommodation-stats/index.ts
// أداة داخلية (قراءة فقط): تحصي أنواع العقارات في HotelBeds لكل وجهة.
// الحماية: الترويسة x-stats-key يجب أن تساوي الـ Secret المسمّى STATS_KEY.

import {
  corsHeaders,
  fail,
  fetchWithTimeout,
  HOTELBEDS_BASE_URL,
  hotelbedsHeaders,
  ok,
} from '../_shared/hotelbeds.ts';

const STATS_KEY = Deno.env.get('STATS_KEY') ?? '';
const PAGE_SIZE = 1000;
const MAX_PAGES = 10;
const DEFAULT_DESTINATIONS = ['NYC', 'MIA', 'ORL', 'LVS', 'LAX'];

async function accommodationTypes(): Promise<Record<string, string>> {
  const map: Record<string, string> = {};
  try {
    const res = await fetchWithTimeout(
      `${HOTELBEDS_BASE_URL}/hotel-content-api/1.0/types/accommodations` +
        `?fields=all&language=ENG&from=1&to=1000&useSecondaryLanguage=false`,
      { headers: await hotelbedsHeaders() },
      30000,
    );
    const data = await res.json().catch(() => ({}));
    for (const a of data?.accommodations ?? []) {
      const desc = a?.typeDescription ?? a?.typeMultiDescription?.content ?? '';
      if (a?.code) map[String(a.code)] = String(desc);
    }
  } catch (e) {
    console.log('types/accommodations failed', String(e));
  }
  return map;
}

async function countDestination(code: string) {
  const counts: Record<string, number> = {};
  let total = 0;
  let fetched = 0;
  let error: string | null = null;
  for (let page = 0; page < MAX_PAGES; page++) {
    const from = page * PAGE_SIZE + 1;
    const to = from + PAGE_SIZE - 1;
    try {
      const res = await fetchWithTimeout(
        `${HOTELBEDS_BASE_URL}/hotel-content-api/1.0/hotels` +
          `?destinationCode=${encodeURIComponent(code)}` +
          `&fields=code,accommodationTypeCode&language=ENG` +
          `&from=${from}&to=${to}&useSecondaryLanguage=false`,
        { headers: await hotelbedsHeaders() },
        45000,
      );
      const data = await res.json().catch(() => ({}));
      if (!res.ok) {
        error = data?.error?.message ?? `HTTP ${res.status}`;
        break;
      }
      total = Number(data?.total ?? total) || total;
      const hotels: any[] = data?.hotels ?? [];
      for (const h of hotels) {
        const t = String(h?.accommodationTypeCode ?? 'UNKNOWN');
        counts[t] = (counts[t] ?? 0) + 1;
      }
      fetched += hotels.length;
      if (hotels.length < PAGE_SIZE || fetched >= total) break;
    } catch (e) {
      error = String(e);
      break;
    }
  }
  return { destination: code, total, fetched, counts, error };
}

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders });
  if (!STATS_KEY || req.headers.get('x-stats-key') !== STATS_KEY) {
    return fail('unauthorized', 'Missing or invalid x-stats-key.');
  }
  try {
    const body = await req.json().catch(() => ({}));
    const destinations: string[] = Array.isArray(body?.destinations) && body.destinations.length
      ? body.destinations.map((d: unknown) => String(d).toUpperCase()).slice(0, 20)
      : DEFAULT_DESTINATIONS;

    const types = await accommodationTypes();
    const results = [];
    const overall: Record<string, number> = {};
    for (const d of destinations) {
      const r = await countDestination(d);
      for (const [k, v] of Object.entries(r.counts)) overall[k] = (overall[k] ?? 0) + v;
      results.push({
        destination: r.destination,
        total: r.total,
        fetched: r.fetched,
        error: r.error,
        byType: Object.entries(r.counts)
          .sort((a, b) => b[1] - a[1])
          .map(([code, count]) => ({ code, description: types[code] ?? '', count })),
      });
    }
    const overallByType = Object.entries(overall)
      .sort((a, b) => b[1] - a[1])
      .map(([code, count]) => ({ code, description: types[code] ?? '', count }));

    console.log('ACCOMMODATION STATS', JSON.stringify(overallByType));
    return ok({ destinations: results, overallByType, allTypes: types });
  } catch (e) {
    console.log('hotelbeds-accommodation-stats error', String(e));
    return fail('server_error', String(e));
  }
});
