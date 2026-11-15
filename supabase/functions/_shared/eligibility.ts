// supabase/functions/_shared/eligibility.ts
//
// رسالة لطيفة بلغة الزبون عندما لا نستطيع قبول البطاقة لأسباب الأهلية
// (ولاية لا نبيع فيها، أو بطاقة من خارج أمريكا والعراق). لا نذكر السبب
// ولا نقول "أنت غير مؤهل": شروط الأهلية مذكورة في شروط الخدمة (البند 3).

const MSG: Record<string, string> = {
  en: "Sorry, we can't complete this booking with this card at the moment. You have not been charged. Please contact us at support@flynoom.com and we'll be happy to help.",
  ar: 'عذرًا، لا نستطيع إتمام هذا الحجز بهذه البطاقة حاليًا. لم يُسحب أي مبلغ. تواصل معنا على support@flynoom.com ويسعدنا مساعدتك.',
  es: 'Lo sentimos, por ahora no podemos completar esta reserva con esta tarjeta. No se te ha cobrado nada. Escríbenos a support@flynoom.com y te ayudaremos con gusto.',
  tr: 'Üzgünüz, bu rezervasyonu şu anda bu kartla tamamlayamıyoruz. Sizden ücret alınmadı. Lütfen support@flynoom.com adresinden bize ulaşın, yardımcı olmaktan memnuniyet duyarız.',
  id: 'Maaf, saat ini kami tidak dapat menyelesaikan pemesanan ini dengan kartu ini. Anda tidak dikenai biaya. Silakan hubungi kami di support@flynoom.com dan kami siap membantu.',
  hi: 'क्षमा करें, हम अभी इस कार्ड से यह बुकिंग पूरी नहीं कर सकते। आपसे कोई शुल्क नहीं लिया गया है। कृपया support@flynoom.com पर हमसे संपर्क करें, हमें मदद करके खुशी होगी।',
  ur: 'معذرت، ہم فی الحال اس کارڈ سے یہ بکنگ مکمل نہیں کر سکتے۔ آپ سے کوئی رقم نہیں لی گئی۔ براہِ کرم support@flynoom.com پر ہم سے رابطہ کریں، ہمیں مدد کر کے خوشی ہوگی۔',
  fr: "Désolés, nous ne pouvons pas finaliser cette réservation avec cette carte pour le moment. Aucun montant n'a été débité. Écrivez-nous à support@flynoom.com, nous serons ravis de vous aider.",
  bn: 'দুঃখিত, এই মুহূর্তে এই কার্ড দিয়ে বুকিংটি সম্পন্ন করা যাচ্ছে না। আপনার কাছ থেকে কোনো অর্থ নেওয়া হয়নি। support@flynoom.com-এ আমাদের সাথে যোগাযোগ করুন, আমরা সানন্দে সাহায্য করব।',
};

export function notEligibleMessage(locale: unknown): string {
  const l = String(locale ?? 'en').toLowerCase().slice(0, 2);
  return MSG[l] ?? MSG.en;
}
