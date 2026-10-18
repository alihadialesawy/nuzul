// supabase/functions/hotelbeds-image-proxy/index.ts
//
// بروكسي بسيط لصور HotelBeds: بيجيب الصورة من photos.hotelbeds.com
// ويمررها للمتصفح مع ترويسات CORS صحيحة، لأن سيرفر HotelBeds نفسه
// مش بيسمح بتحميل صوره من نطاق مختلف (Cross-Origin) مباشرة.
//
// ملاحظة: المقاسات الكبيرة (xl / xxl / original) ترفض الطلبات التي لا تبدو
// كمتصفح (ترجع 403)، لذلك نرسل ترويسات متصفح عادية. وإن رُفض المقاس الكبير
// رغم ذلك، نجرب تلقائيًا مقاس bigger لنفس الصورة بدل إرجاع خطأ.

import { serve } from 'https://deno.land/std@0.168.0/http/server.ts';

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

const BROWSER_HEADERS: HeadersInit = {
  'User-Agent':
    'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/130.0 Safari/537.36',
  'Accept': 'image/avif,image/webp,image/apng,image/*,*/*;q=0.8',
  'Accept-Language': 'en-US,en;q=0.9',
};

const SIZE_RE = /\/giata\/(?:small|medium|standard|bigger|xl|xxl|original)\//;

/// نفس الصورة بمقاس bigger (أو null إن كان الرابط bigger أصلًا).
function biggerFallback(url: string): string | null {
  if (url.includes('/giata/bigger/')) return null;
  if (SIZE_RE.test(url)) return url.replace(SIZE_RE, '/giata/bigger/');
  return url.replace('/giata/', '/giata/bigger/');
}

function jsonError(message: string, status: number) {
  return new Response(JSON.stringify({ error: message }), {
    status,
    headers: { ...corsHeaders, 'Content-Type': 'application/json' },
  });
}

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  const url = new URL(req.url).searchParams.get('url');

  // أمان: نسمح بس بتمرير روابط من نطاق HotelBeds الرسمي للصور،
  // عشان محدش يستغل الدالة دي كـ "بروكسي مفتوح" لأي موقع تاني.
  if (!url || !url.startsWith('https://photos.hotelbeds.com/')) {
    return jsonError('Invalid or missing url', 400);
  }

  try {
    let imageResponse = await fetch(url, { headers: BROWSER_HEADERS });

    if (!imageResponse.ok) {
      const fallback = biggerFallback(url);
      console.log('IMAGE FETCH FAILED', imageResponse.status, url, fallback ? '→ trying bigger' : '');
      if (fallback) {
        imageResponse = await fetch(fallback, { headers: BROWSER_HEADERS });
      }
    }

    if (!imageResponse.ok) {
      return jsonError('Failed to fetch image', imageResponse.status);
    }

    const contentType = imageResponse.headers.get('Content-Type') ?? 'image/jpeg';
    if (!contentType.startsWith('image/')) {
      return jsonError('Not an image', 502);
    }
    const imageBytes = await imageResponse.arrayBuffer();

    return new Response(imageBytes, {
      headers: {
        ...corsHeaders,
        'Content-Type': contentType,
        'Cache-Control': 'public, max-age=86400',
      },
    });
  } catch (e) {
    return jsonError(String(e), 500);
  }
});
