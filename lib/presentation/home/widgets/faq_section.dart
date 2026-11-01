import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';

/// نص بلغة المستخدم. ترتيب القائمة: [en, ar, es, tr, id, hi, ur, fr, bn].
String _pick(BuildContext context, List<String> v) {
  const langs = ['en', 'ar', 'es', 'tr', 'id', 'hi', 'ur', 'fr', 'bn'];
  final i = langs.indexOf(Localizations.localeOf(context).languageCode);
  return v[i < 0 ? 0 : i];
}

class _FaqItem {
  final List<String> question;
  final List<String> answer;
  const _FaqItem(this.question, this.answer);
}

/// ⚠️ كل إجابة هنا وعد للعميل؛ يجب أن تطابق طريقة عمل الحجز الحالية
/// (HotelBeds + Stripe، الويب والتطبيق). الإجابات المفصّلة في صفحة الدعم.
const List<_FaqItem> _faqItems = [
  _FaqItem(
    [
      'How do I book a room?',
      'كيف أحجز غرفة؟',
      '¿Cómo reservo una habitación?',
      'Nasıl oda ayırtırım?',
      'Bagaimana cara memesan kamar?',
      'मैं कमरा कैसे बुक करूं?',
      'میں کمرہ کیسے بک کروں؟',
      'Comment réserver une chambre ?',
      'আমি কীভাবে রুম বুক করব?',
    ],
    [
      'Search for a city and dates, choose a hotel and room, review the final price and cancellation policy, then pay by card.',
      'ابحث عن مدينة واختر التواريخ، ثم اختر الفندق والغرفة، وراجع السعر النهائي وسياسة الإلغاء، ثم ادفع بالبطاقة.',
      'Busca una ciudad y fechas, elige hotel y habitación, revisa el precio final y la política de cancelación, y paga con tarjeta.',
      'Bir şehir ve tarih arayın, otel ve odayı seçin, nihai fiyatı ve iptal politikasını inceleyin, ardından kartla ödeyin.',
      'Cari kota dan tanggal, pilih hotel dan kamar, periksa harga akhir dan kebijakan pembatalan, lalu bayar dengan kartu.',
      'शहर और तारीखें खोजें, होटल और कमरा चुनें, अंतिम कीमत और रद्दीकरण नीति देखें, फिर कार्ड से भुगतान करें।',
      'شہر اور تاریخیں تلاش کریں، ہوٹل اور کمرہ منتخب کریں، حتمی قیمت اور منسوخی پالیسی دیکھیں، پھر کارڈ سے ادائیگی کریں۔',
      'Recherchez une ville et des dates, choisissez un hôtel et une chambre, vérifiez le prix final et la politique d\'annulation, puis payez par carte.',
      'শহর ও তারিখ খুঁজুন, হোটেল ও রুম বেছে নিন, চূড়ান্ত মূল্য ও বাতিল নীতি দেখুন, তারপর কার্ডে পেমেন্ট করুন।',
    ],
  ),
  _FaqItem(
    [
      'Can I cancel my booking?',
      'هل يمكنني إلغاء حجزي؟',
      '¿Puedo cancelar mi reserva?',
      'Rezervasyonumu iptal edebilir miyim?',
      'Bisakah saya membatalkan pemesanan?',
      'क्या मैं अपनी बुकिंग रद्द कर सकता हूँ?',
      'کیا میں اپنی بکنگ منسوخ کر سکتا ہوں؟',
      'Puis-je annuler ma réservation ?',
      'আমি কি আমার বুকিং বাতিল করতে পারি?',
    ],
    [
      'Yes, from "My Bookings". You will see the refund and any cancellation fee before you confirm. The amount follows the cancellation policy shown before you paid; non-refundable rates are not refunded.',
      'نعم، من صفحة "حجوزاتي". سترى المبلغ المسترد ورسوم الإلغاء قبل التأكيد. يعتمد المبلغ على سياسة الإلغاء التي ظهرت لك قبل الدفع، والأسعار غير القابلة للاسترداد لا يُسترد منها شيء.',
      'Sí, desde "Mis reservas". Verás el reembolso y la penalización antes de confirmar. El importe sigue la política de cancelación mostrada antes de pagar; las tarifas no reembolsables no se reembolsan.',
      'Evet, "Rezervasyonlarım" sayfasından. Onaylamadan önce iade tutarını ve iptal ücretini görürsünüz. Tutar, ödeme öncesi gösterilen iptal politikasına göre belirlenir; iade edilemez fiyatlar iade edilmez.',
      'Ya, dari "Pesanan Saya". Anda akan melihat jumlah pengembalian dan biaya pembatalan sebelum mengonfirmasi. Jumlahnya mengikuti kebijakan pembatalan yang ditampilkan sebelum membayar; tarif yang tidak dapat dikembalikan tidak dikembalikan.',
      'हाँ, "मेरी बुकिंग" से। पुष्टि से पहले आपको वापसी राशि और रद्दीकरण शुल्क दिखेगा। राशि भुगतान से पहले दिखाई गई रद्दीकरण नीति के अनुसार होती है; नॉन-रिफ़ंडेबल दरों पर कोई वापसी नहीं होती।',
      'جی ہاں، "میری بکنگز" سے۔ تصدیق سے پہلے آپ کو واپسی کی رقم اور منسوخی فیس نظر آئے گی۔ رقم ادائیگی سے پہلے دکھائی گئی منسوخی پالیسی کے مطابق ہوتی ہے؛ ناقابلِ واپسی نرخوں پر کوئی رقم واپس نہیں ہوتی۔',
      'Oui, depuis « Mes réservations ». Le remboursement et les frais d\'annulation s\'affichent avant de confirmer. Le montant suit la politique d\'annulation affichée avant le paiement ; les tarifs non remboursables ne sont pas remboursés.',
      'হ্যাঁ, "আমার বুকিং" থেকে। নিশ্চিত করার আগে ফেরতের পরিমাণ ও বাতিল ফি দেখবেন। পরিমাণ পেমেন্টের আগে দেখানো বাতিল নীতির ওপর নির্ভর করে; নন-রিফান্ডেবল রেটে কোনো ফেরত নেই।',
    ],
  ),
  _FaqItem(
    [
      'What payment methods are supported?',
      'ما طرق الدفع المتاحة؟',
      '¿Qué métodos de pago aceptan?',
      'Hangi ödeme yöntemleri destekleniyor?',
      'Metode pembayaran apa yang didukung?',
      'कौन से भुगतान तरीके समर्थित हैं?',
      'کون سے ادائیگی کے طریقے دستیاب ہیں؟',
      'Quels moyens de paiement sont acceptés ?',
      'কোন পেমেন্ট পদ্ধতি সমর্থিত?',
    ],
    [
      'Credit and debit cards, in U.S. dollars, on the website and the app. Payments are processed securely by Stripe, and we do not store your card number.',
      'بطاقات الائتمان والخصم بالدولار الأمريكي، على الموقع والتطبيق. تتم معالجة الدفع بأمان عبر Stripe، ولا نحتفظ برقم بطاقتك.',
      'Tarjetas de crédito y débito, en dólares estadounidenses, en la web y en la app. Stripe procesa los pagos de forma segura y no guardamos el número de tu tarjeta.',
      'Web sitesinde ve uygulamada, ABD doları cinsinden kredi ve banka kartları. Ödemeler Stripe tarafından güvenle işlenir ve kart numaranızı saklamayız.',
      'Kartu kredit dan debit, dalam dolar AS, di situs web dan aplikasi. Pembayaran diproses dengan aman oleh Stripe, dan kami tidak menyimpan nomor kartu Anda.',
      'वेबसाइट और ऐप पर, अमेरिकी डॉलर में क्रेडिट और डेबिट कार्ड। भुगतान Stripe द्वारा सुरक्षित रूप से प्रोसेस होते हैं, और हम आपका कार्ड नंबर संग्रहीत नहीं करते।',
      'ویب سائٹ اور ایپ پر، امریکی ڈالر میں کریڈٹ اور ڈیبٹ کارڈ۔ ادائیگیاں Stripe کے ذریعے محفوظ طریقے سے ہوتی ہیں، اور ہم آپ کا کارڈ نمبر محفوظ نہیں کرتے۔',
      'Cartes de crédit et de débit, en dollars américains, sur le site et l\'application. Les paiements sont traités de façon sécurisée par Stripe et nous ne conservons pas votre numéro de carte.',
      'ওয়েবসাইট ও অ্যাপে মার্কিন ডলারে ক্রেডিট ও ডেবিট কার্ড। পেমেন্ট Stripe নিরাপদে প্রক্রিয়া করে, এবং আমরা আপনার কার্ড নম্বর সংরক্ষণ করি না।',
    ],
  ),
  _FaqItem(
    [
      'Do I need an account to search for hotels?',
      'هل أحتاج إلى حساب للبحث عن الفنادق؟',
      '¿Necesito una cuenta para buscar hoteles?',
      'Otel aramak için hesap gerekli mi?',
      'Apakah saya perlu akun untuk mencari hotel?',
      'क्या होटल खोजने के लिए खाता ज़रूरी है?',
      'کیا ہوٹل تلاش کرنے کے لیے اکاؤنٹ ضروری ہے؟',
      'Ai-je besoin d\'un compte pour rechercher des hôtels ?',
      'হোটেল খুঁজতে কি অ্যাকাউন্ট লাগবে?',
    ],
    [
      'No. You can browse and search freely as a guest. An account is only needed when you book, so you can manage your booking later.',
      'لا، يمكنك التصفح والبحث بحرية كضيف. الحساب مطلوب فقط عند الحجز، حتى تتمكن من إدارة حجزك لاحقًا.',
      'No. Puedes explorar y buscar libremente como invitado. Solo necesitas una cuenta al reservar, para poder gestionar tu reserva después.',
      'Hayır. Misafir olarak serbestçe göz atıp arama yapabilirsiniz. Hesap yalnızca rezervasyon yaparken gerekir; böylece rezervasyonunuzu daha sonra yönetebilirsiniz.',
      'Tidak. Anda bisa menjelajah dan mencari dengan bebas sebagai tamu. Akun hanya diperlukan saat memesan, agar Anda bisa mengelola pemesanan nanti.',
      'नहीं। आप मेहमान के रूप में खुलकर ब्राउज़ और खोज कर सकते हैं। खाता केवल बुकिंग के समय चाहिए, ताकि आप बाद में अपनी बुकिंग संभाल सकें।',
      'نہیں۔ آپ مہمان کے طور پر آزادی سے براؤز اور تلاش کر سکتے ہیں۔ اکاؤنٹ صرف بکنگ کے وقت درکار ہے، تاکہ آپ بعد میں اپنی بکنگ سنبھال سکیں۔',
      'Non. Vous pouvez parcourir et rechercher librement en tant qu\'invité. Un compte n\'est nécessaire que pour réserver, afin de gérer votre réservation ensuite.',
      'না। আপনি অতিথি হিসেবে স্বাধীনভাবে ব্রাউজ ও খুঁজতে পারেন। শুধু বুকিংয়ের সময় অ্যাকাউন্ট লাগে, যাতে পরে বুকিং পরিচালনা করতে পারেন।',
    ],
  ),
];

/// قسم "أسئلة شائعة" في الصفحة الرئيسية — محتوى ثابت باللغات التسع.
class FaqSection extends StatelessWidget {
  const FaqSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSizes.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSizes.md),
            child: Text(
              _pick(context, const [
                'Frequently Asked Questions',
                'أسئلة شائعة',
                'Preguntas frecuentes',
                'Sık sorulan sorular',
                'Pertanyaan umum',
                'अक्सर पूछे जाने वाले प्रश्न',
                'اکثر پوچھے جانے والے سوالات',
                'Questions fréquentes',
                'প্রায়শই জিজ্ঞাসিত প্রশ্ন',
              ]),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ),
          const SizedBox(height: AppSizes.sm),
          ..._faqItems.map((item) {
            return ExpansionTile(
              title: Text(
                _pick(context, item.question),
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              ),
              tilePadding: const EdgeInsets.symmetric(horizontal: AppSizes.md),
              childrenPadding: const EdgeInsetsDirectional.only(
                start: AppSizes.md,
                end: AppSizes.md,
                bottom: AppSizes.sm,
              ),
              expandedCrossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _pick(context, item.answer),
                  style: const TextStyle(color: AppColors.textSecondary, height: 1.4),
                ),
              ],
            );
          }),
        ],
      ),
    );
  }
}