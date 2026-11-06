// supabase/functions/_shared/fraud.ts
//
// بوابة الاحتيال: تُستدعى في hotelbeds-book بعد أن يوافق البنك على حجز المبلغ
// (requires_capture) وقبل أن نحجز الغرفة عند HotelBeds.
//
// الفكرة: المبلغ مجمّد فقط ولم يُسحب. إن بدت الدفعة مشبوهة نلغي التجميد،
// فلا يُسحب مال، ولا ندفع للفندق، ولا يوجد ما يُنازَع عليه.
//
// القواعد (عدّلها هنا فقط):
//   رفض مباشر (مهما كان):
//     • بطاقة صادرة من دولة خاضعة لعقوبات أمريكية شاملة (sanctions.ts).
//     • فشل فحص CVC.
//     • تقييم Radar = highest.
//     • تجاوز عدد البطاقات المختلفة للحساب خلال 24 ساعة (MAX_CARDS_PER_DAY).
//   رفض ما لم يمر الدفع بـ 3D Secure:
//     • تقييم Radar = elevated (يُشترط هنا تحقق كامل authenticated).
//     • فشل فحص الرمز البريدي (AVS).
//     • اجتماع SOFT_SIGNALS_TO_REJECT إشارات أو أكثر من الإشارات "الخفيفة":
//       اختلاف دولة البطاقة عن دولة IP، وصول خلال 48 ساعة، مبلغ كبير، بطاقة مسبقة الدفع.
//
// ⚠️ لا نخبر العميل بسبب الرفض أبدًا (حتى لا يتعلم المحتال كيف يتجاوز القواعد).

import { BLOCKED_COUNTRY_CODES } from './sanctions.ts';

export const HIGH_AMOUNT_USD = Number(Deno.env.get('FRAUD_HIGH_AMOUNT_USD') ?? '500') || 500;
export const LAST_MINUTE_HOURS = 48;
export const SOFT_SIGNALS_TO_REJECT = 3;
export const MAX_CARDS_PER_DAY = 3;

const IPINFO_TOKEN = Deno.env.get('IPINFO_TOKEN') ?? '';

export interface RiskInput {
  /** الـ Charge الخاص بالتفويض (intent.latest_charge بعد expand). */
  charge: any;
  amountUsd: number;
  /** YYYY-MM-DD */
  checkIn: string;
  ipCountry: string | null;
  /** عدد البطاقات المختلفة التي جرّبها الحساب خلال 24 ساعة (بدون هذه). */
  otherCardsLast24h: number;
  /** هل هذه البطاقة جديدة على الحساب خلال 24 ساعة؟ */
  isNewCard: boolean;
  now?: Date;
}

export interface RiskDecision {
  allow: boolean;
  /** أسباب الرفض (فارغة عند القبول). */
  reasons: string[];
  /** الإشارات الخفيفة التي ظهرت (للمراجعة في لوحة الإدارة). */
  signals: string[];
  riskLevel: string | null;
  riskScore: number | null;
  threeDS: string | null;
  cardCountry: string | null;
  cvcCheck: string | null;
  postalCheck: string | null;
  funding: string | null;
  /** هل نعلّم الإلغاء عند Stripe كـ fraudulent (لتحسين Radar). */
  markFraudulent: boolean;
}

export function evaluateRisk(i: RiskInput): RiskDecision {
  const ch = i.charge ?? {};
  const card = ch.payment_method_details?.card ?? {};
  const riskLevel: string | null = ch.outcome?.risk_level ?? null;
  const riskScore: number | null = typeof ch.outcome?.risk_score === 'number' ? ch.outcome.risk_score : null;
  const threeDS: string | null = card.three_d_secure?.result ?? null;
  const authenticated = threeDS === 'authenticated';
  // attempt_acknowledged: البطاقة غير مسجّلة في 3DS لكن البنك سجّل المحاولة،
  // وغالبًا تنتقل المسؤولية معها أيضًا.
  const has3ds = authenticated || threeDS === 'attempt_acknowledged';
  const cardCountry: string | null = card.country ? String(card.country).toUpperCase() : null;
  const cvcCheck: string | null = card.checks?.cvc_check ?? null;
  const postalCheck: string | null = card.checks?.address_postal_code_check ?? null;
  const funding: string | null = card.funding ?? null;

  const reasons: string[] = [];
  const signals: string[] = [];

  // ───── رفض مباشر ─────
  if (cardCountry && BLOCKED_COUNTRY_CODES.has(cardCountry)) reasons.push(`sanctioned_card_country:${cardCountry}`);
  if (cvcCheck === 'fail') reasons.push('cvc_fail');
  if (riskLevel === 'highest') reasons.push('radar_highest');
  if (i.isNewCard && i.otherCardsLast24h >= MAX_CARDS_PER_DAY) {
    reasons.push(`too_many_cards:${i.otherCardsLast24h + 1}`);
  }

  // ───── رفض ما لم يوجد 3D Secure ─────
  if (riskLevel === 'elevated' && !authenticated) reasons.push('radar_elevated_no_3ds');
  if (postalCheck === 'fail' && !has3ds) reasons.push('postal_fail_no_3ds');

  // ───── إشارات خفيفة ─────
  if (i.ipCountry && cardCountry && i.ipCountry !== cardCountry) {
    signals.push(`ip_card_mismatch:${i.ipCountry}/${cardCountry}`);
  }
  const now = i.now ?? new Date();
  const checkInMs = Date.parse(`${i.checkIn}T00:00:00Z`);
  if (!Number.isNaN(checkInMs) && checkInMs - now.getTime() <= LAST_MINUTE_HOURS * 3600 * 1000) {
    signals.push('last_minute');
  }
  if (i.amountUsd > HIGH_AMOUNT_USD) signals.push(`high_amount:${i.amountUsd}`);
  if (funding === 'prepaid') signals.push('prepaid_card');

  if (signals.length >= SOFT_SIGNALS_TO_REJECT && !has3ds) {
    reasons.push(`soft_signals:${signals.length}`);
  }

  return {
    allow: reasons.length === 0,
    reasons,
    signals,
    riskLevel,
    riskScore,
    threeDS,
    cardCountry,
    cvcCheck,
    postalCheck,
    funding,
    markFraudulent: reasons.some((r) => r.startsWith('radar_') || r === 'cvc_fail' || r.startsWith('sanctioned_')),
  };
}

/// دولة عنوان IP عبر IPinfo Lite (إن وُضع IPINFO_TOKEN). null عند أي فشل —
/// غياب دولة IP يعني فقط غياب إشارة واحدة، لا يوقف الحجز.
export async function lookupIpCountry(ip: string | null): Promise<string | null> {
  if (!IPINFO_TOKEN || !ip) return null;
  try {
    const ctrl = new AbortController();
    const t = setTimeout(() => ctrl.abort(), 2500);
    const res = await fetch(`https://api.ipinfo.io/lite/${encodeURIComponent(ip)}?token=${IPINFO_TOKEN}`, {
      signal: ctrl.signal,
    });
    clearTimeout(t);
    if (!res.ok) return null;
    const d = await res.json();
    if (d?.bogon) return null;
    const c = String(d?.country_code ?? d?.country ?? '').toUpperCase();
    return /^[A-Z]{2}$/.test(c) ? c : null;
  } catch {
    return null;
  }
}

/// رسالة الرفض للعميل: بدون ذكر السبب.
export const PAYMENT_DECLINED_MESSAGE =
  "We couldn't complete the payment with this card. No money has been taken — if you see a pending " +
  'amount, your bank will release it automatically, usually within a few days. ' +
  'Please try a different card or contact support@flynoom.com.';