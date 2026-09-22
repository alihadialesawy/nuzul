import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../search/controllers/search_controller.dart';

/// يختار النص المناسب حسب اللغة الحالية (عربي/إنجليزي/إسباني/تركي/إندونيسي/هندي/أوردو/فرنسي/بنغالي).
String _t3(
    BuildContext context, {
      required String ar,
      required String en,
      required String es,
      required String tr,
      required String id,
      required String hi,
      required String ur,
      required String fr,
      required String bn,
    }) {
  switch (Localizations.localeOf(context).languageCode) {
    case 'ar':
      return ar;
    case 'es':
      return es;
    case 'tr':
      return tr;
    case 'id':
      return id;
    case 'hi':
      return hi;
    case 'ur':
      return ur;
    case 'fr':
      return fr;
    case 'bn':
      return bn;
    default:
      return en;
  }
}

/// شاشة تعريفية بمساعد الذكاء الاصطناعي بتاع Safr-AI، ومعاها فورم
/// "تتبّع سعر رحلتك" اللي بيبعت طلب فعلي لجدول price_watches بـ Supabase
/// (الفحص اليومي والإشعار بالإيميل بيتم من خلال Edge Function منفصلة).
class AiTravelPage extends ConsumerStatefulWidget {
  const AiTravelPage({super.key});

  @override
  ConsumerState<AiTravelPage> createState() => _AiTravelPageState();
}

class _AiTravelPageState extends ConsumerState<AiTravelPage> {
  final _formKey = GlobalKey<FormState>();
  final _originController = TextEditingController();
  final _destinationController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _targetPriceController = TextEditingController();
  DateTime? _travelDate;
  bool _nonstopOnly = false;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _originController.dispose();
    _destinationController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _targetPriceController.dispose();
    super.dispose();
  }

  Future<void> _pickTravelDate() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
      initialDate: _travelDate ?? now.add(const Duration(days: 7)),
    );
    if (date != null) setState(() => _travelDate = date);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_travelDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _t3(context, ar: 'اختر تاريخ السفر', en: 'Pick a travel date', es: 'Elige una fecha de viaje', tr: 'Bir seyahat tarihi seçin', id: 'Pilih tanggal perjalanan',
                hi: 'यात्रा की तारीख चुनें',
                ur: 'سفر کی تاریخ منتخب کریں',
                fr: 'Choisissez une date de voyage',
                bn: 'একটি ভ্রমণের তারিখ বেছে নিন'),
          ),
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final repo = ref.read(priceWatchRepositoryProvider);
    final result = await repo.submitPriceWatch(
      email: _emailController.text,
      phone: _phoneController.text,
      originCity: _originController.text,
      destinationCity: _destinationController.text,
      travelDate: _travelDate!,
      // أسعار الرحلات في الجدول مخزّنة بالريال السعودي (SAR) كعملة أساسية
      // (نفس اتفاقية باقي التطبيق)، فبنحوّل السعر المطلوب من دولار لريال
      // بنفس السعر الثابت المستخدم في تحويل العملات (3.75 ريال للدولار)
      // قبل ما نخزّنه، عشان المقارنة في الخلفية تفضل صحيحة.
      targetPrice: double.parse(_targetPriceController.text) * 3.75,
      nonstopOnly: _nonstopOnly,
    );

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    result.when(
      success: (_) {
        _originController.clear();
        _destinationController.clear();
        _emailController.clear();
        _phoneController.clear();
        _targetPriceController.clear();
        setState(() {
          _travelDate = null;
          _nonstopOnly = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _t3(
                context,
                ar: 'تم! سنرسل إليك بريدًا إلكترونيًا بمجرد إيجاد هذا السعر',
                en: "Got it! We'll email you as soon as we find that price",
                es: '¡Listo! Te avisaremos por correo cuando encontremos ese precio',
                tr: 'Tamamdır! Bu fiyatı bulur bulmaz size e-posta göndereceğiz',
                id: 'Siap! Kami akan mengirim email begitu kami menemukan harga itu',
                hi: 'समझ गए! जैसे ही हमें वह कीमत मिलेगी, हम आपको ईमेल करेंगे',
                ur: 'سمجھ گئے! جیسے ہی ہمیں وہ قیمت ملے گی، ہم آپ کو ای میل کریں گے',
                fr: 'Compris ! Nous vous enverrons un e-mail dès que nous trouverons ce prix',
                bn: 'বুঝেছি! সেই মূল্য খুঁজে পেলেই আমরা আপনাকে ইমেইল করব',
              ),
            ),
          ),
        );
      },
      failure: (message) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: AppSizes.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: AppSizes.md),
              // بانر صورة الذكاء الاصطناعي أعلى الشاشة
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.asset(
                  'assets/images/ai_banner.jpg',
                  width: double.infinity,
                  height: 220,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    width: double.infinity,
                    height: 220,
                    color: Colors.white.withOpacity(0.08),
                  ),
                ),
              ),
              const SizedBox(height: AppSizes.lg),
              RichText(
                text: TextSpan(
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    height: 1.2,
                  ),
                  children: [
                    TextSpan(
                      text: _t3(
                        context,
                        ar: 'مساعد السفر الذكي بكل خدماته في مكان واحد',
                        en: 'Your all-in-one AI travel app',
                        es: 'Tu app de viajes con IA, todo en uno',
                        tr: 'Hepsi bir arada yapay zeka seyahat uygulamanız',
                        id: 'Aplikasi perjalanan AI serba lengkap Anda',
                        hi: 'आपका ऑल-इन-वन AI यात्रा ऐप',
                        ur: 'آپ کی آل ان ون AI سفری ایپ',
                        fr: 'Votre application de voyage IA tout-en-un',
                        bn: 'আপনার অল-ইন-ওয়ান AI ভ্রমণ অ্যাপ',
                      ),
                    ),
                    const TextSpan(
                      text: '.',
                      style: TextStyle(color: Colors.amber),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSizes.sm),
              Text(
                _t3(
                  context,
                  ar: 'يساعدك مساعد Safr-AI الذكي على إيجاد أفضل عروض الفنادق والطيران والسيارات في ثوانٍ',
                  en: 'Our AI assistant finds the best hotel, flight, and car deals for you in seconds',
                  es: 'Nuestro asistente de IA encuentra las mejores ofertas de hoteles, vuelos y coches en segundos',
                  tr: 'Yapay zeka asistanımız saniyeler içinde en iyi otel, uçuş ve araç fırsatlarını sizin için bulur',
                  id: 'Asisten AI kami menemukan penawaran hotel, penerbangan, dan mobil terbaik untuk Anda dalam hitungan detik',
                  hi: 'हमारा AI सहायक सेकंडों में आपके लिए सबसे अच्छे होटल, उड़ान और कार ऑफ़र ढूंढता है',
                  ur: 'ہمارا AI معاون سیکنڈوں میں آپ کے لیے بہترین ہوٹل، پرواز، اور کار کے سودے تلاش کرتا ہے',
                  fr: 'Notre assistant IA trouve les meilleures offres d\'hôtels, de vols et de voitures pour vous en quelques secondes',
                  bn: 'আমাদের AI সহায়ক সেকেন্ডের মধ্যে আপনার জন্য সেরা হোটেল, ফ্লাইট ও গাড়ির অফার খুঁজে বের করে',
                ),
                style: const TextStyle(fontSize: 15, color: Colors.white70),
              ),
              const SizedBox(height: AppSizes.xl),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSizes.lg),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 96,
                      height: 96,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.qr_code_2, size: 72, color: Colors.black87),
                    ),
                    const SizedBox(width: AppSizes.lg),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _t3(
                              context,
                              ar: 'حمّل تطبيق Safr-AI',
                              en: 'Get the Safr-AI app',
                              es: 'Descarga la app de Safr-AI',
                              tr: "Safr-AI uygulamasını edinin",
                              id: 'Dapatkan aplikasi Safr-AI',
                              hi: 'Safr-AI ऐप प्राप्त करें',
                              ur: 'Safr-AI ایپ حاصل کریں',
                              fr: 'Téléchargez l\'application Safr-AI',
                              bn: 'Safr-AI অ্যাপ পান',
                            ),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                          const SizedBox(height: AppSizes.sm),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              _StoreBadge(
                                icon: Icons.apple,
                                topLabel: _t3(context, ar: 'حمّل من', en: 'Download on the', es: 'Disponible en', tr: 'İndirin', id: 'Unduh di',
                                    hi: 'यहाँ से डाउनलोड करें',
                                    ur: 'یہاں سے ڈاؤن لوڈ کریں',
                                    fr: 'Téléchargez sur',
                                    bn: 'ডাউনলোড করুন'),
                                bottomLabel: 'App Store',
                              ),
                              _StoreBadge(
                                icon: Icons.shop,
                                topLabel: _t3(context, ar: 'احصل عليه من', en: 'GET IT ON', es: 'Disponible en', tr: 'ŞUNDAN EDİNİN', id: 'DAPATKAN DI',
                                    hi: 'यहाँ से पाएं',
                                    ur: 'یہاں سے حاصل کریں',
                                    fr: 'DISPONIBLE SUR',
                                    bn: 'পেতে ভিজিট করুন'),
                                bottomLabel: 'Google Play',
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSizes.xl),
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: _FeatureCard(
                        icon: Icons.chat_bubble_outline,
                        color: const Color(0xFF6C5CE7),
                        title: _t3(context, ar: 'محادثة ذكية', en: 'AI chat assistant', es: 'Chat con IA', tr: 'Yapay zeka sohbet asistanı', id: 'Asisten chat AI',
                            hi: 'AI चैट सहायक',
                            ur: 'AI چیٹ معاون',
                            fr: 'Assistant de chat IA',
                            bn: 'AI চ্যাট সহায়ক'),
                        description: _t3(
                          context,
                          ar: 'اسأل مساعد Safr-AI بالعربية أو الإنجليزية عن أي رحلة، وسيردّ عليك فورًا باقتراحات مخصصة',
                          en: 'Ask the Safr-AI assistant about any trip and get instant, tailored suggestions back',
                          es: 'Pregunta a Safr-AI sobre tu viaje y recibe sugerencias personalizadas al instante',
                          tr: 'Safr-AI asistanına herhangi bir seyahat hakkında sorun, anında size özel önerilerle yanıt versin',
                          id: 'Tanya asisten Safr-AI tentang perjalanan apa pun dan dapatkan saran khusus secara instan',
                          hi: 'किसी भी यात्रा के बारे में Safr-AI सहायक से पूछें और तुरंत, आपके अनुसार सुझाव पाएं',
                          ur: 'کسی بھی سفر کے بارے میں Safr-AI معاون سے پوچھیں اور فوری، آپ کے مطابق تجاویز حاصل کریں',
                          fr: 'Posez toutes vos questions de voyage à l\'assistant Safr-AI et obtenez des suggestions instantanées et personnalisées',
                          bn: 'যেকোনো ভ্রমণ সম্পর্কে Safr-AI সহায়ককে জিজ্ঞাসা করুন এবং তাৎক্ষণিক, উপযোগী পরামর্শ পান',
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSizes.sm),
                    Expanded(
                      child: _FeatureCard(
                        icon: Icons.trending_down,
                        color: const Color(0xFFE17055),
                        title: _t3(context, ar: 'تتبّع الأسعار', en: 'Price tracking', es: 'Seguimiento de precios', tr: 'Fiyat takibi', id: 'Pelacakan harga',
                            hi: 'मूल्य ट्रैकिंग',
                            ur: 'قیمت ٹریکنگ',
                            fr: 'Suivi des prix',
                            bn: 'মূল্য ট্র্যাকিং'),
                        description: _t3(
                          context,
                          ar: 'يراقب الذكاء الاصطناعي سعر رحلتك يوميًا ويرسل إليك بريدًا إلكترونيًا تلقائيًا بمجرد وصول السعر إلى الحد الذي حددته',
                          en: 'Our AI checks your flight price daily and emails you automatically the moment it hits your target',
                          es: 'Nuestra IA revisa el precio de tu vuelo a diario y te avisa por correo al alcanzar tu meta',
                          tr: 'Yapay zekamız uçuş fiyatınızı her gün kontrol eder ve hedef fiyata ulaştığı an otomatik olarak size e-posta gönderir',
                          id: 'AI kami memeriksa harga penerbangan Anda setiap hari dan otomatis mengirim email saat mencapai harga target Anda',
                          hi: 'हमारा AI हर दिन आपकी उड़ान की कीमत जांचता है और जैसे ही यह आपके लक्ष्य तक पहुंचती है, स्वतः आपको ईमेल करता है',
                          ur: 'ہمارا AI روزانہ آپ کی پرواز کی قیمت چیک کرتا ہے اور جیسے ہی یہ آپ کے ہدف تک پہنچتی ہے خود بخود آپ کو ای میل کرتا ہے',
                          fr: 'Notre IA vérifie quotidiennement le prix de votre vol et vous envoie automatiquement un e-mail dès qu\'il atteint votre objectif',
                          bn: 'আমাদের AI প্রতিদিন আপনার ফ্লাইটের মূল্য পরীক্ষা করে এবং লক্ষ্য মূল্যে পৌঁছালেই স্বয়ংক্রিয়ভাবে ইমেইল পাঠায়',
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSizes.sm),
                    Expanded(
                      child: _FeatureCard(
                        icon: Icons.recommend_outlined,
                        color: const Color(0xFF0984E3),
                        title: _t3(context, ar: 'توصيات مخصصة', en: 'Personalized picks', es: 'Recomendaciones a tu medida', tr: 'Kişiye özel öneriler', id: 'Rekomendasi khusus',
                            hi: 'व्यक्तिगत सुझाव',
                            ur: 'ذاتی نوعیت کی تجاویز',
                            fr: 'Suggestions personnalisées',
                            bn: 'ব্যক্তিগতকৃত পছন্দ'),
                        description: _t3(
                          context,
                          ar: 'كلما استخدمت Safr-AI أكثر، أصبحت الاقتراحات أدق وأقرب إلى ذوقك وميزانيتك',
                          en: 'The more you use Safr-AI, the sharper its suggestions get for your taste and budget',
                          es: 'Cuanto más usas Safr-AI, más precisas son sus sugerencias según tu gusto y presupuesto',
                          tr: 'Safr-AI\'yi ne kadar çok kullanırsanız, önerileri zevkinize ve bütçenize o kadar uygun hale gelir',
                          id: 'Semakin sering Anda menggunakan Safr-AI, sarannya semakin tajam sesuai selera dan anggaran Anda',
                          hi: 'जितना अधिक आप Safr-AI का उपयोग करेंगे, यह आपकी पसंद और बजट के अनुसार उतने ही बेहतर सुझाव देगा',
                          ur: 'جتنا زیادہ آپ Safr-AI استعمال کریں گے، یہ آپ کے ذوق اور بجٹ کے مطابق اتنی ہی بہتر تجاویز دے گا',
                          fr: 'Plus vous utilisez Safr-AI, plus ses suggestions s\'affinent selon vos goûts et votre budget',
                          bn: 'আপনি যত বেশি Safr-AI ব্যবহার করবেন, আপনার রুচি ও বাজেট অনুযায়ী এর পরামর্শ তত নিখুঁত হবে',
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSizes.sm),
                    Expanded(
                      child: _FeatureCard(
                        icon: Icons.access_time,
                        color: const Color(0xFF00B894),
                        title: _t3(context, ar: 'متاح ٢٤/٧', en: 'Available 24/7', es: 'Disponible 24/7', tr: '7/24 hizmetinizde', id: 'Tersedia 24/7',
                            hi: '24/7 उपलब्ध',
                            ur: '24/7 دستیاب',
                            fr: 'Disponible 24h/24 et 7j/7',
                            bn: '২৪/৭ উপলব্ধ'),
                        description: _t3(
                          context,
                          ar: 'يعمل مساعد الذكاء الاصطناعي على مدار الساعة، جاهز لتخطيط رحلتك في أي وقت دون انتظار',
                          en: 'The AI assistant works around the clock, ready to plan your trip anytime with no waiting',
                          es: 'El asistente de IA trabaja sin parar, listo para planear tu viaje a cualquier hora',
                          tr: 'Yapay zeka asistanı kesintisiz çalışır, beklemeden istediğiniz saatte seyahatinizi planlamaya hazırdır',
                          id: 'Asisten AI bekerja sepanjang waktu, siap merencanakan perjalanan Anda kapan saja tanpa menunggu',
                          hi: 'AI सहायक चौबीसों घंटे काम करता है, बिना इंतज़ार किए कभी भी आपकी यात्रा की योजना बनाने के लिए तैयार',
                          ur: 'AI معاون چوبیس گھنٹے کام کرتا ہے، بغیر انتظار کیے کسی بھی وقت آپ کے سفر کی منصوبہ بندی کے لیے تیار',
                          fr: 'L\'assistant IA fonctionne 24h/24, prêt à planifier votre voyage à tout moment sans attente',
                          bn: 'AI সহায়ক দিনরাত কাজ করে, অপেক্ষা ছাড়াই যেকোনো সময় আপনার ভ্রমণ পরিকল্পনা করতে প্রস্তুত',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSizes.xl),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSizes.lg),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _t3(
                          context,
                          ar: 'تتبّع سعر رحلتك',
                          en: 'Track your flight price',
                          es: 'Sigue el precio de tu vuelo',
                          tr: 'Uçuş fiyatınızı takip edin',
                          id: 'Lacak harga penerbangan Anda',
                          hi: 'अपनी उड़ान की कीमत ट्रैक करें',
                          ur: 'اپنی پرواز کی قیمت ٹریک کریں',
                          fr: 'Suivez le prix de votre vol',
                          bn: 'আপনার ফ্লাইটের মূল্য ট্র্যাক করুন',
                        ),
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _t3(
                          context,
                          ar: 'حدّد رحلتك والسعر الذي ترغب في الوصول إليه، وسيبحث مساعدنا الذكي يوميًا ويرسل إليك بريدًا إلكترونيًا بمجرد إيجاده',
                          en: "Tell us your trip and target price, and our AI will search daily and email you as soon as it's found",
                          es: 'Dinos tu viaje y precio deseado, y nuestra IA buscará a diario y te avisará por correo',
                          tr: 'Seyahatinizi ve hedef fiyatınızı belirtin, yapay zekamız her gün arasın ve bulur bulmaz size e-posta göndersin',
                          id: 'Beri tahu kami perjalanan dan harga target Anda, AI kami akan mencari setiap hari dan mengirim email begitu ditemukan',
                          hi: 'हमें अपनी यात्रा और लक्ष्य कीमत बताएं, हमारा AI रोज़ाना खोजेगा और मिलते ही आपको ईमेल करेगा',
                          ur: 'ہمیں اپنا سفر اور ہدف قیمت بتائیں، ہمارا AI روزانہ تلاش کرے گا اور ملتے ہی آپ کو ای میل کرے گا',
                          fr: 'Indiquez-nous votre voyage et votre prix cible, notre IA recherchera quotidiennement et vous enverra un e-mail dès qu\'elle le trouve',
                          bn: 'আমাদের আপনার ভ্রমণ ও লক্ষ্য মূল্য জানান, আমাদের AI প্রতিদিন খুঁজবে এবং পাওয়ার সাথে সাথেই আপনাকে ইমেইল করবে',
                        ),
                        style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: AppSizes.md),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _originController,
                              decoration: InputDecoration(
                                labelText: _t3(context, ar: 'من', en: 'From', es: 'Desde', tr: 'Nereden', id: 'Dari',
                                    hi: 'कहाँ से',
                                    ur: 'کہاں سے',
                                    fr: 'De',
                                    bn: 'থেকে'),
                                prefixIcon: const Icon(Icons.flight_takeoff, size: 18),
                              ),
                              validator: (v) => (v == null || v.trim().isEmpty)
                                  ? _t3(context, ar: 'مطلوب', en: 'Required', es: 'Requerido', tr: 'Zorunlu', id: 'Wajib diisi',
                                  hi: 'आवश्यक',
                                  ur: 'ضروری',
                                  fr: 'Obligatoire',
                                  bn: 'আবশ্যক')
                                  : null,
                            ),
                          ),
                          const SizedBox(width: AppSizes.sm),
                          Expanded(
                            child: TextFormField(
                              controller: _destinationController,
                              decoration: InputDecoration(
                                labelText: _t3(context, ar: 'إلى', en: 'To', es: 'Hasta', tr: 'Nereye', id: 'Ke',
                                    hi: 'कहाँ तक',
                                    ur: 'کہاں تک',
                                    fr: 'À',
                                    bn: 'পর্যন্ত'),
                                prefixIcon: const Icon(Icons.flight_land, size: 18),
                              ),
                              validator: (v) => (v == null || v.trim().isEmpty)
                                  ? _t3(context, ar: 'مطلوب', en: 'Required', es: 'Requerido', tr: 'Zorunlu', id: 'Wajib diisi',
                                  hi: 'आवश्यक',
                                  ur: 'ضروری',
                                  fr: 'Obligatoire',
                                  bn: 'আবশ্যক')
                                  : null,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSizes.sm),
                      GestureDetector(
                        onTap: _pickTravelDate,
                        child: InputDecorator(
                          decoration: InputDecoration(
                            labelText: _t3(context, ar: 'تاريخ السفر', en: 'Travel date', es: 'Fecha de viaje', tr: 'Seyahat tarihi', id: 'Tanggal perjalanan',
                                hi: 'यात्रा की तारीख',
                                ur: 'سفر کی تاریخ',
                                fr: 'Date de voyage',
                                bn: 'ভ্রমণের তারিখ'),
                            prefixIcon: const Icon(Icons.calendar_today_outlined, size: 18),
                          ),
                          child: Text(
                            _travelDate == null
                                ? _t3(context, ar: 'اختر تاريخ', en: 'Select a date', es: 'Elige una fecha', tr: 'Bir tarih seçin', id: 'Pilih tanggal',
                                hi: 'एक तारीख चुनें',
                                ur: 'ایک تاریخ منتخب کریں',
                                fr: 'Choisir une date',
                                bn: 'একটি তারিখ নির্বাচন করুন')
                                : '${_travelDate!.year}-${_travelDate!.month.toString().padLeft(2, '0')}-${_travelDate!.day.toString().padLeft(2, '0')}',
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSizes.sm),
                      TextFormField(
                        controller: _targetPriceController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: _t3(context, ar: 'السعر المطلوب (USD)', en: 'Target price (USD)', es: 'Precio deseado (USD)', tr: 'Hedef fiyat (USD)', id: 'Harga target (USD)',
                              hi: 'लक्ष्य कीमत (USD)',
                              ur: 'ہدف قیمت (USD)',
                              fr: 'Prix cible (USD)',
                              bn: 'লক্ষ্য মূল্য (USD)'),
                          prefixIcon: const Icon(Icons.sell_outlined, size: 18),
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return _t3(context, ar: 'مطلوب', en: 'Required', es: 'Requerido', tr: 'Zorunlu', id: 'Wajib diisi',
                                hi: 'आवश्यक',
                                ur: 'ضروری',
                                fr: 'Obligatoire',
                                bn: 'আবশ্যক');
                          }
                          if (double.tryParse(v) == null) {
                            return _t3(context, ar: 'رقم غير صحيح', en: 'Invalid number', es: 'Número inválido', tr: 'Geçersiz sayı', id: 'Angka tidak valid',
                                hi: 'अमान्य संख्या',
                                ur: 'غلط نمبر',
                                fr: 'Nombre invalide',
                                bn: 'অবৈধ সংখ্যা');
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 4),
                      GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => setState(() => _nonstopOnly = !_nonstopOnly),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Checkbox(
                              value: _nonstopOnly,
                              onChanged: (v) => setState(() => _nonstopOnly = v ?? false),
                            ),
                            Text(
                              _t3(context, ar: 'بدون توقف فقط', en: 'Nonstop only', es: 'Solo sin escalas', tr: 'Sadece aktarmasız', id: 'Hanya tanpa transit',
                                  hi: 'केवल बिना रुके',
                                  ur: 'صرف بلا رکاوٹ',
                                  fr: 'Sans escale uniquement',
                                  bn: 'শুধুমাত্র সরাসরি'),
                              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSizes.sm),
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          labelText: _t3(context, ar: 'بريدك الإلكتروني', en: 'Your email', es: 'Tu correo electrónico', tr: 'E-posta adresiniz', id: 'Email Anda',
                              hi: 'आपका ईमेल',
                              ur: 'آپ کا ای میل',
                              fr: 'Votre e-mail',
                              bn: 'আপনার ইমেইল'),
                          prefixIcon: const Icon(Icons.email_outlined, size: 18),
                        ),
                        validator: (v) {
                          if (v == null || !v.contains('@')) {
                            return _t3(context, ar: 'بريد إلكتروني غير صحيح', en: 'Invalid email', es: 'Correo inválido', tr: 'Geçersiz e-posta', id: 'Email tidak valid',
                                hi: 'अमान्य ईमेल',
                                ur: 'غلط ای میل',
                                fr: 'E-mail invalide',
                                bn: 'অবৈধ ইমেইল');
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: AppSizes.sm),
                      TextFormField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        decoration: InputDecoration(
                          labelText: _t3(
                            context,
                            ar: 'رقم الجوال (اختياري — لإشعار SMS)',
                            en: 'Phone number (optional — for SMS alert)',
                            es: 'Teléfono (opcional — para alerta SMS)',
                            tr: 'Telefon numarası (isteğe bağlı — SMS bildirimi için)',
                            id: 'Nomor telepon (opsional — untuk peringatan SMS)',
                            hi: 'फ़ोन नंबर (वैकल्पिक — SMS अलर्ट के लिए)',
                            ur: 'فون نمبر (اختیاری — SMS الرٹ کے لیے)',
                            fr: 'Numéro de téléphone (facultatif — pour alerte SMS)',
                            bn: 'ফোন নম্বর (ঐচ্ছিক — SMS সতর্কতার জন্য)',
                          ),
                          hintText: '+9665xxxxxxxx',
                          prefixIcon: const Icon(Icons.sms_outlined, size: 18),
                        ),
                      ),
                      const SizedBox(height: AppSizes.md),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isSubmitting ? null : _submit,
                          child: _isSubmitting
                              ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                              : Text(
                            _t3(context, ar: 'ابدأ التتبّع', en: 'Start tracking', es: 'Empezar a seguir', tr: 'Takibi başlat', id: 'Mulai lacak',
                                hi: 'ट्रैकिंग शुरू करें',
                                ur: 'ٹریکنگ شروع کریں',
                                fr: 'Démarrer le suivi',
                                bn: 'ট্র্যাকিং শুরু করুন'),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSizes.xl),
            ],
          ),
        ),
      ),
    );
  }
}

class _StoreBadge extends StatelessWidget {
  final IconData icon;
  final String topLabel;
  final String bottomLabel;

  const _StoreBadge({
    required this.icon,
    required this.topLabel,
    required this.bottomLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 30),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(topLabel, style: const TextStyle(color: Colors.white70, fontSize: 11)),
              Text(
                bottomLabel,
                style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String description;

  const _FeatureCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          const SizedBox(height: 10),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: color),
          ),
          const SizedBox(height: 5),
          Text(
            description,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.35),
          ),
        ],
      ),
    );
  }
}