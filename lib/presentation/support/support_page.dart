import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../core/widgets/app_banner.dart';
import '../../core/widgets/app_footer.dart';

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

class _FaqItem {
  final String question;
  final String answer;
  const _FaqItem(this.question, this.answer);
}

/// شاشة دعم العملاء.
///
/// ⚠️ كل إجابة هنا وعد للعميل؛ لا تكتب إلا ما يعمل فعلًا الآن.
/// أُزيلت من النسخة السابقة: أسئلة الطيران والسيارات (مخفية)، "تنبيهات الأسعار"،
/// تصنيفات "More FAQ" التي لا تفتح شيئًا، زر "اتصل بنا" برقم وهمي،
/// وزر "دردشة" الذي كان يفتح البريد فقط.
/// عند إعادة الطيران: أضف تبويبًا بأسئلة طيران حقيقية.
class SupportPage extends StatefulWidget {
  const SupportPage({super.key});

  @override
  State<SupportPage> createState() => _SupportPageState();
}

class _SupportPageState extends State<SupportPage> {
  final _scrollController = ScrollController();
  final _faqSectionKey = GlobalKey();

  static const String _supportEmail = 'support@flynoom.com';

  /// رقم هاتف/واتساب الدعم. اتركه فارغًا ما دام لا يوجد رقم يرد عليه أحد؛
  /// زر "اتصل بنا" يظهر تلقائيًا عند كتابة رقم حقيقي هنا (مثل '+13135551234').
  static const String _supportPhone = '';

  /// رقم واتساب الدعم بالصيغة الدولية بدون + أو مسافات (يُستخدم في رابط wa.me).
  /// الرقم لا يُكتب في الصفحة؛ يظهر فقط لمن يضغط زر واتساب.
  /// لتغييره لاحقًا (مثلًا لرقم عمل منفصل) غيّر هذا السطر فقط.
  static const String _whatsAppNumber = '19784839704';

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _openEmail(BuildContext context) async {
    final uri = Uri(
      scheme: 'mailto',
      path: _supportEmail,
      query: 'subject=${Uri.encodeComponent('Flynoom support')}',
    );
    final launched = await launchUrl(uri);
    if (!launched && context.mounted) {
      _showLaunchError(context);
    }
  }

  Future<void> _openWhatsApp(BuildContext context) async {
    final message = _t3(
      context,
      ar: 'مرحبًا Flynoom، رقم حجزي (إن وُجد): ',
      en: 'Hello Flynoom, my booking reference (if any): ',
      es: 'Hola Flynoom, mi referencia de reserva (si la tengo): ',
      tr: 'Merhaba Flynoom, rezervasyon numaram (varsa): ',
      id: 'Halo Flynoom, kode pemesanan saya (jika ada): ',
      hi: 'नमस्ते Flynoom, मेरा बुकिंग नंबर (यदि हो): ',
      ur: 'السلام علیکم Flynoom، میرا بکنگ نمبر (اگر ہو): ',
      fr: 'Bonjour Flynoom, ma référence de réservation (le cas échéant) : ',
      bn: 'হ্যালো Flynoom, আমার বুকিং নম্বর (যদি থাকে): ',
    );
    final uri = Uri.parse('https://wa.me/$_whatsAppNumber?text=${Uri.encodeComponent(message)}');
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication, webOnlyWindowName: '_blank');
    if (!launched && context.mounted) {
      _showLaunchError(context);
    }
  }

  Future<void> _openPhone(BuildContext context) async {
    final uri = Uri(scheme: 'tel', path: _supportPhone);
    final launched = await launchUrl(uri);
    if (!launched && context.mounted) {
      _showLaunchError(context);
    }
  }

  void _showLaunchError(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_t3(
          context,
          ar: 'تعذّر فتح التطبيق. راسلنا على $_supportEmail',
          en: 'Could not open the app. Email us at $_supportEmail',
          es: 'No se pudo abrir la aplicación. Escríbenos a $_supportEmail',
          tr: 'Uygulama açılamadı. Bize $_supportEmail adresinden yazın',
          id: 'Tidak dapat membuka aplikasi. Email kami di $_supportEmail',
          hi: 'ऐप नहीं खुल सका। हमें $_supportEmail पर ईमेल करें',
          ur: 'ایپ نہیں کھل سکی۔ ہمیں $_supportEmail پر ای میل کریں',
          fr: 'Impossible d\'ouvrir l\'application. Écrivez-nous à $_supportEmail',
          bn: 'অ্যাপ খোলা যায়নি। আমাদের $_supportEmail-এ ইমেইল করুন',
        )),
      ),
    );
  }

  void _scrollToFaq() {
    final context = _faqSectionKey.currentContext;
    if (context != null) {
      Scrollable.ensureVisible(
        context,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    }
  }

  /// "مشكلة في الفندق؟" — بدل "مساعدة طارئة" التي كانت توحي بخدمة فورية 24/7.
  void _showHotelProblemDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(_t3(
          dialogContext,
          ar: 'مشكلة في الفندق؟',
          en: 'Problem at the hotel?',
          es: '¿Un problema en el hotel?',
          tr: 'Otelde bir sorun mu var?',
          id: 'Ada masalah di hotel?',
          hi: 'होटल में कोई समस्या?',
          ur: 'ہوٹل میں کوئی مسئلہ؟',
          fr: 'Un problème à l\'hôtel ?',
          bn: 'হোটেলে কোনো সমস্যা?',
        )),
        content: Text(
          _t3(
            dialogContext,
            ar: '١. إن كنت في خطر، اتصل أولًا بخدمات الطوارئ المحلية.\n\n'
                '٢. لمشكلة في الغرفة أو تسجيل الوصول، تواصل مع الفندق مباشرة؛ رقمه مكتوب في بريد تأكيد الحجز، ومعه رقم الحجز الذي يطلبه الفندق.\n\n'
                '٣. ثم راسلنا عبر واتساب أو البريد برقم الحجز ووصف المشكلة، وسنتابع مع الفندق.',
            en: '1. If you are in danger, call local emergency services first.\n\n'
                '2. For a problem with your room or check-in, contact the hotel directly. Its phone number is in your confirmation email, together with the booking reference the hotel will ask for.\n\n'
                '3. Then message us on WhatsApp or by email with your booking reference and what happened, and we will follow up with the hotel.',
            es: '1. Si estás en peligro, llama primero a los servicios de emergencia locales.\n\n'
                '2. Si hay un problema con tu habitación o el check-in, contacta directamente con el hotel. Su teléfono está en tu correo de confirmación, junto con la referencia de reserva que te pedirá el hotel.\n\n'
                '3. Después, escríbenos con tu referencia de reserva y lo ocurrido, y haremos el seguimiento con el hotel.',
            tr: '1. Tehlikedeyseniz önce yerel acil servisleri arayın.\n\n'
                '2. Odanız veya girişinizle ilgili bir sorun için doğrudan otelle iletişime geçin. Otelin telefonu, otelin isteyeceği rezervasyon numarasıyla birlikte onay e-postanızda yer alır.\n\n'
                '3. Ardından rezervasyon numaranızı ve yaşananları bize e-postayla gönderin, otelle biz takip edelim.',
            id: '1. Jika Anda dalam bahaya, hubungi dulu layanan darurat setempat.\n\n'
                '2. Untuk masalah kamar atau check-in, hubungi hotel langsung. Nomor teleponnya ada di email konfirmasi Anda, bersama kode pemesanan yang akan diminta hotel.\n\n'
                '3. Lalu email kami kode pemesanan dan apa yang terjadi, dan kami akan menindaklanjuti dengan hotel.',
            hi: '1. अगर आप खतरे में हैं, तो पहले स्थानीय आपातकालीन सेवाओं को कॉल करें।\n\n'
                '2. कमरे या चेक-इन की समस्या के लिए सीधे होटल से संपर्क करें। उसका फ़ोन नंबर आपके पुष्टि ईमेल में है, साथ में वह बुकिंग नंबर भी जो होटल मांगेगा।\n\n'
                '3. फिर हमें अपना बुकिंग नंबर और समस्या ईमेल करें, हम होटल से बात करेंगे।',
            ur: '1. اگر آپ خطرے میں ہیں تو پہلے مقامی ہنگامی خدمات کو کال کریں۔\n\n'
                '2. کمرے یا چیک اِن کے مسئلے کے لیے براہ راست ہوٹل سے رابطہ کریں۔ اس کا فون نمبر آپ کی تصدیقی ای میل میں ہے، ساتھ وہ بکنگ نمبر بھی جو ہوٹل مانگے گا۔\n\n'
                '3. پھر ہمیں اپنا بکنگ نمبر اور مسئلہ ای میل کریں، ہم ہوٹل سے بات کریں گے۔',
            fr: '1. Si vous êtes en danger, appelez d\'abord les services d\'urgence locaux.\n\n'
                '2. Pour un problème de chambre ou d\'arrivée, contactez directement l\'hôtel. Son numéro figure dans votre e-mail de confirmation, avec la référence de réservation que l\'hôtel vous demandera.\n\n'
                '3. Ensuite, envoyez-nous votre référence de réservation et ce qui s\'est passé, et nous assurerons le suivi avec l\'hôtel.',
            bn: '১. আপনি বিপদে থাকলে প্রথমে স্থানীয় জরুরি সেবায় কল করুন।\n\n'
                '২. রুম বা চেক-ইনের সমস্যার জন্য সরাসরি হোটেলের সাথে যোগাযোগ করুন। হোটেলের ফোন নম্বর আপনার নিশ্চিতকরণ ইমেইলে আছে, সাথে সেই বুকিং নম্বরও যা হোটেল চাইবে।\n\n'
                '৩. তারপর আমাদের বুকিং নম্বর ও সমস্যাটি ইমেইল করুন, আমরা হোটেলের সাথে কথা বলব।',
          ),
          style: const TextStyle(height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(_t3(
              dialogContext,
              ar: 'إغلاق',
              en: 'Close',
              es: 'Cerrar',
              tr: 'Kapat',
              id: 'Tutup',
              hi: 'बंद करें',
              ur: 'بند کریں',
              fr: 'Fermer',
              bn: 'বন্ধ করুন',
            )),
          ),
          if (_whatsAppNumber.isNotEmpty)
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                _openWhatsApp(context);
              },
              child: Text(_t3(
                dialogContext,
                ar: 'واتساب',
                en: 'WhatsApp',
                es: 'WhatsApp',
                tr: 'WhatsApp',
                id: 'WhatsApp',
                hi: 'WhatsApp',
                ur: 'واٹس ایپ',
                fr: 'WhatsApp',
                bn: 'WhatsApp',
              )),
            ),
          FilledButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              _openEmail(context);
            },
            child: Text(_t3(
              dialogContext,
              ar: 'راسلنا',
              en: 'Email us',
              es: 'Escríbenos',
              tr: 'Bize yazın',
              id: 'Email kami',
              hi: 'हमें ईमेल करें',
              ur: 'ہمیں ای میل کریں',
              fr: 'Écrivez-nous',
              bn: 'আমাদের ইমেইল করুন',
            )),
          ),
        ],
      ),
    );
  }

  /// أسئلة الفنادق — كلها مطابقة لطريقة عمل الحجز الحالية (HotelBeds + Stripe).
  List<_FaqItem> _hotelFaqs(BuildContext context) {
    return [
      _FaqItem(
        _t3(context,
            ar: 'كيف أحجز غرفة؟',
            en: 'How do I book a room?',
            es: '¿Cómo reservo una habitación?',
            tr: 'Nasıl oda ayırtırım?',
            id: 'Bagaimana cara memesan kamar?',
            hi: 'मैं कमरा कैसे बुक करूं?',
            ur: 'میں کمرہ کیسے بک کروں؟',
            fr: 'Comment réserver une chambre ?',
            bn: 'আমি কীভাবে রুম বুক করব?'),
        _t3(context,
            ar: 'من تبويب "الإقامة" أو "العمرة" اختر المدينة والتواريخ وعدد الضيوف ثم ابحث. اختر الفندق والغرفة، وراجع السعر النهائي وسياسة الإلغاء، ثم ادفع بالبطاقة.',
            en: 'In the Stays or Umrah tab, choose the city, dates and guests, then search. Pick a hotel and room, review the final price and cancellation policy, then pay by card.',
            es: 'En la pestaña Alojamientos o Umrah, elige ciudad, fechas y huéspedes y busca. Elige hotel y habitación, revisa el precio final y la política de cancelación y paga con tarjeta.',
            tr: 'Konaklama veya Umre sekmesinde şehri, tarihleri ve misafirleri seçip arayın. Otel ve odayı seçin, nihai fiyatı ve iptal politikasını inceleyin, ardından kartla ödeyin.',
            id: 'Di tab Menginap atau Umrah, pilih kota, tanggal, dan tamu, lalu cari. Pilih hotel dan kamar, periksa harga akhir dan kebijakan pembatalan, lalu bayar dengan kartu.',
            hi: '"ठहरना" या "उमरा" टैब में शहर, तारीखें और मेहमान चुनकर खोजें। होटल और कमरा चुनें, अंतिम कीमत और रद्दीकरण नीति देखें, फिर कार्ड से भुगतान करें।',
            ur: 'قیام یا عمرہ کے ٹیب میں شہر، تاریخیں اور مہمان منتخب کر کے تلاش کریں۔ ہوٹل اور کمرہ منتخب کریں، حتمی قیمت اور منسوخی پالیسی دیکھیں، پھر کارڈ سے ادائیگی کریں۔',
            fr: 'Dans l\'onglet Séjours ou Omra, choisissez la ville, les dates et les voyageurs, puis recherchez. Choisissez un hôtel et une chambre, vérifiez le prix final et la politique d\'annulation, puis payez par carte.',
            bn: '"থাকার ব্যবস্থা" বা "উমরাহ" ট্যাবে শহর, তারিখ ও অতিথি বেছে খুঁজুন। হোটেল ও রুম বেছে নিন, চূড়ান্ত মূল্য ও বাতিল নীতি দেখুন, তারপর কার্ডে পেমেন্ট করুন।'),
      ),
      _FaqItem(
        _t3(context,
            ar: 'متى يُسحب المبلغ من بطاقتي؟',
            en: 'When is my card charged?',
            es: '¿Cuándo se cobra mi tarjeta?',
            tr: 'Kartımdan ne zaman ödeme alınır?',
            id: 'Kapan kartu saya ditagih?',
            hi: 'मेरे कार्ड से पैसे कब कटते हैं?',
            ur: 'میرے کارڈ سے رقم کب کٹتی ہے؟',
            fr: 'Quand ma carte est-elle débitée ?',
            bn: 'আমার কার্ড থেকে কখন টাকা কাটা হয়?'),
        _t3(context,
            ar: 'عند الحجز يُحجز المبلغ على بطاقتك فقط، ولا يُسحب إلا بعد أن يؤكد الفندق حجزك. إن لم يُؤكَّد الحجز يُلغى الحجز المؤقت، وقد يستغرق ظهور ذلك في كشف حسابك بضعة أيام حسب البنك.',
            en: 'When you book, the amount is only held on your card. It is charged only after the hotel confirms your booking. If the booking is not confirmed, the hold is released; your bank may take a few days to show this.',
            es: 'Al reservar, el importe solo se retiene en tu tarjeta y se cobra únicamente cuando el hotel confirma la reserva. Si no se confirma, la retención se libera; tu banco puede tardar unos días en reflejarlo.',
            tr: 'Rezervasyon yaptığınızda tutar yalnızca kartınızda bloke edilir ve otel rezervasyonu onayladıktan sonra tahsil edilir. Onaylanmazsa bloke kaldırılır; bankanızın bunu göstermesi birkaç gün sürebilir.',
            id: 'Saat memesan, dana hanya ditahan di kartu Anda dan baru ditagih setelah hotel mengonfirmasi. Jika tidak terkonfirmasi, penahanan dilepas; bank Anda mungkin perlu beberapa hari untuk menampilkannya.',
            hi: 'बुकिंग के समय राशि केवल आपके कार्ड पर रोकी जाती है, और होटल की पुष्टि के बाद ही काटी जाती है। पुष्टि न होने पर रोक हटा दी जाती है; बैंक में दिखने में कुछ दिन लग सकते हैं।',
            ur: 'بکنگ کے وقت رقم صرف آپ کے کارڈ پر روکی جاتی ہے، اور ہوٹل کی تصدیق کے بعد ہی وصول کی جاتی ہے۔ تصدیق نہ ہونے پر روک ختم کر دی جاتی ہے؛ بینک میں ظاہر ہونے میں چند دن لگ سکتے ہیں۔',
            fr: 'Lors de la réservation, le montant est seulement bloqué sur votre carte et n\'est débité qu\'après la confirmation de l\'hôtel. Sans confirmation, le blocage est levé ; votre banque peut mettre quelques jours à l\'afficher.',
            bn: 'বুকিংয়ের সময় অর্থ শুধু আপনার কার্ডে আটকে রাখা হয়, এবং হোটেল নিশ্চিত করার পরেই কাটা হয়। নিশ্চিত না হলে আটকানো অর্থ ছেড়ে দেওয়া হয়; ব্যাংকে দেখাতে কয়েক দিন লাগতে পারে।'),
      ),
      _FaqItem(
        _t3(context,
            ar: 'كيف ألغي حجزي؟ وكم أسترد؟',
            en: 'How do I cancel, and how much is refunded?',
            es: '¿Cómo cancelo y cuánto se reembolsa?',
            tr: 'Nasıl iptal ederim ve ne kadar iade alırım?',
            id: 'Bagaimana cara membatalkan, dan berapa yang dikembalikan?',
            hi: 'मैं कैसे रद्द करूं, और कितना वापस मिलेगा?',
            ur: 'میں کیسے منسوخ کروں، اور کتنا واپس ملے گا؟',
            fr: 'Comment annuler, et combien est remboursé ?',
            bn: 'কীভাবে বাতিল করব, আর কত ফেরত পাব?'),
        _t3(context,
            ar: 'من صفحة "حجوزاتي" اضغط "إلغاء"، وسترى المبلغ المسترد ورسوم الإلغاء قبل التأكيد. المبلغ يعتمد على سياسة الإلغاء التي ظهرت لك قبل الدفع (بتوقيت الفندق المحلي). الأسعار غير القابلة للاسترداد لا يُسترد منها شيء.',
            en: 'In "My Bookings", tap "Cancel". You will see the refund and any cancellation fee before you confirm. The amount follows the cancellation policy shown before you paid (in the hotel\'s local time). Non-refundable rates are not refunded.',
            es: 'En "Mis reservas", pulsa "Cancelar". Verás el reembolso y la penalización antes de confirmar. El importe sigue la política de cancelación mostrada antes de pagar (hora local del hotel). Las tarifas no reembolsables no se reembolsan.',
            tr: '"Rezervasyonlarım" sayfasında "İptal"e dokunun. Onaylamadan önce iade tutarını ve iptal ücretini görürsünüz. Tutar, ödeme öncesi gösterilen iptal politikasına (otelin yerel saati) göre belirlenir. İade edilemez fiyatlar iade edilmez.',
            id: 'Di "Pesanan Saya", ketuk "Batalkan". Anda akan melihat jumlah pengembalian dan biaya pembatalan sebelum mengonfirmasi. Jumlahnya mengikuti kebijakan pembatalan yang ditampilkan sebelum membayar (waktu lokal hotel). Tarif yang tidak dapat dikembalikan tidak dikembalikan.',
            hi: '"मेरी बुकिंग" में "रद्द करें" दबाएं। पुष्टि से पहले आपको वापसी राशि और रद्दीकरण शुल्क दिखेगा। राशि भुगतान से पहले दिखाई गई रद्दीकरण नीति (होटल के स्थानीय समय) के अनुसार होती है। नॉन-रिफ़ंडेबल दरों पर कोई वापसी नहीं होती।',
            ur: '"میری بکنگز" میں "منسوخ کریں" دبائیں۔ تصدیق سے پہلے آپ کو واپسی کی رقم اور منسوخی فیس نظر آئے گی۔ رقم ادائیگی سے پہلے دکھائی گئی منسوخی پالیسی (ہوٹل کے مقامی وقت) کے مطابق ہوتی ہے۔ ناقابلِ واپسی نرخوں پر کوئی رقم واپس نہیں ہوتی۔',
            fr: 'Dans « Mes réservations », touchez « Annuler ». Le remboursement et les frais d\'annulation s\'affichent avant de confirmer. Le montant suit la politique d\'annulation affichée avant le paiement (heure locale de l\'hôtel). Les tarifs non remboursables ne sont pas remboursés.',
            bn: '"আমার বুকিং"-এ "বাতিল" চাপুন। নিশ্চিত করার আগে ফেরতের পরিমাণ ও বাতিল ফি দেখবেন। পরিমাণ নির্ভর করে পেমেন্টের আগে দেখানো বাতিল নীতির ওপর (হোটেলের স্থানীয় সময়)। নন-রিফান্ডেবল রেটে কোনো ফেরত নেই।'),
      ),
      _FaqItem(
        _t3(context,
            ar: 'هل توجد رسوم أدفعها في الفندق؟',
            en: 'Are there fees to pay at the hotel?',
            es: '¿Hay cargos que pagar en el hotel?',
            tr: 'Otelde ödenecek ücretler var mı?',
            id: 'Apakah ada biaya yang dibayar di hotel?',
            hi: 'क्या होटल में कोई शुल्क देना होता है?',
            ur: 'کیا ہوٹل میں کوئی فیس ادا کرنی ہوتی ہے؟',
            fr: 'Y a-t-il des frais à payer à l\'hôtel ?',
            bn: 'হোটেলে কি কোনো ফি দিতে হয়?'),
        _t3(context,
            ar: 'بعض الفنادق تفرض رسومًا محلية تُدفع عند الوصول، مثل ضريبة المدينة. إن وُجدت تظهر لك قبل الدفع، ومكتوبة في بريد التأكيد.',
            en: 'Some hotels charge local fees paid on arrival, such as a city tax. If there are any, they are shown before you pay and listed in your confirmation email.',
            es: 'Algunos hoteles cobran cargos locales al llegar, como una tasa municipal. Si los hay, se muestran antes de pagar y aparecen en tu correo de confirmación.',
            tr: 'Bazı oteller varışta ödenen yerel ücretler alır (ör. şehir vergisi). Varsa ödemeden önce gösterilir ve onay e-postanızda yer alır.',
            id: 'Beberapa hotel mengenakan biaya lokal yang dibayar saat tiba, seperti pajak kota. Jika ada, biaya itu ditampilkan sebelum membayar dan tercantum di email konfirmasi.',
            hi: 'कुछ होटल पहुंचने पर स्थानीय शुल्क लेते हैं, जैसे शहर कर। अगर कोई हो, तो भुगतान से पहले दिखाया जाता है और पुष्टि ईमेल में लिखा होता है।',
            ur: 'کچھ ہوٹل آمد پر مقامی فیس لیتے ہیں، جیسے شہر کا ٹیکس۔ اگر کوئی ہو تو ادائیگی سے پہلے دکھائی جاتی ہے اور تصدیقی ای میل میں درج ہوتی ہے۔',
            fr: 'Certains hôtels facturent des frais locaux à l\'arrivée, comme une taxe de séjour. Le cas échéant, ils sont indiqués avant le paiement et dans votre e-mail de confirmation.',
            bn: 'কিছু হোটেল পৌঁছানোর সময় স্থানীয় ফি নেয়, যেমন সিটি ট্যাক্স। থাকলে তা পেমেন্টের আগে দেখানো হয় এবং নিশ্চিতকরণ ইমেইলে লেখা থাকে।'),
      ),
      _FaqItem(
        _t3(context,
            ar: 'لم يصلني بريد التأكيد',
            en: 'I did not receive my confirmation email',
            es: 'No recibí el correo de confirmación',
            tr: 'Onay e-postam gelmedi',
            id: 'Saya tidak menerima email konfirmasi',
            hi: 'मुझे पुष्टि ईमेल नहीं मिला',
            ur: 'مجھے تصدیقی ای میل نہیں ملی',
            fr: 'Je n\'ai pas reçu l\'e-mail de confirmation',
            bn: 'আমি নিশ্চিতকরণ ইমেইল পাইনি'),
        _t3(context,
            ar: 'تحقّق من مجلد الرسائل غير المرغوبة (Spam). حجزك وحالته ظاهران دائمًا في "حجوزاتي". إن لم تجده هناك، راسلنا برقم الحجز أو بالبريد الذي حجزت به.',
            en: 'Check your spam folder. Your booking and its status are always shown in "My Bookings". If you cannot find it there, email us with your booking reference or the email you booked with.',
            es: 'Revisa la carpeta de spam. Tu reserva y su estado siempre aparecen en "Mis reservas". Si no la encuentras, escríbenos con la referencia o el correo con el que reservaste.',
            tr: 'Spam klasörünüzü kontrol edin. Rezervasyonunuz ve durumu her zaman "Rezervasyonlarım"da görünür. Bulamazsanız rezervasyon numaranız veya kullandığınız e-postayla bize yazın.',
            id: 'Periksa folder spam. Pemesanan dan statusnya selalu tampil di "Pesanan Saya". Jika tidak ada, email kami dengan kode pemesanan atau email yang Anda gunakan.',
            hi: 'स्पैम फ़ोल्डर देखें। आपकी बुकिंग और उसकी स्थिति हमेशा "मेरी बुकिंग" में दिखती है। वहाँ न मिले तो बुकिंग नंबर या बुकिंग वाले ईमेल के साथ हमें लिखें।',
            ur: 'اسپام فولڈر دیکھیں۔ آپ کی بکنگ اور اس کی حالت ہمیشہ "میری بکنگز" میں نظر آتی ہے۔ وہاں نہ ملے تو بکنگ نمبر یا بکنگ والی ای میل کے ساتھ ہمیں لکھیں۔',
            fr: 'Vérifiez vos spams. Votre réservation et son statut apparaissent toujours dans « Mes réservations ». Si vous ne la trouvez pas, écrivez-nous avec la référence ou l\'e-mail utilisé.',
            bn: 'স্প্যাম ফোল্ডার দেখুন। আপনার বুকিং ও তার অবস্থা সবসময় "আমার বুকিং"-এ দেখা যায়। সেখানে না পেলে বুকিং নম্বর বা যে ইমেইলে বুক করেছেন তা দিয়ে আমাদের লিখুন।'),
      ),
      _FaqItem(
        _t3(context,
            ar: 'هل يمكنني تغيير التواريخ أو أسماء الضيوف؟',
            en: 'Can I change the dates or guest names?',
            es: '¿Puedo cambiar las fechas o los nombres?',
            tr: 'Tarihleri veya misafir adlarını değiştirebilir miyim?',
            id: 'Bisakah saya mengubah tanggal atau nama tamu?',
            hi: 'क्या मैं तारीखें या मेहमानों के नाम बदल सकता हूँ?',
            ur: 'کیا میں تاریخیں یا مہمانوں کے نام بدل سکتا ہوں؟',
            fr: 'Puis-je modifier les dates ou les noms ?',
            bn: 'আমি কি তারিখ বা অতিথির নাম বদলাতে পারি?'),
        _t3(context,
            ar: 'التعديل غير متاح من الموقع حاليًا. راسلنا برقم الحجز والتعديل المطلوب، وسنسأل الفندق؛ بعض التعديلات قد لا تكون ممكنة. ويمكنك أيضًا الإلغاء وفق سياسة الإلغاء ثم الحجز من جديد.',
            en: 'Changes cannot be made online yet. Email us your booking reference and the change you need, and we will ask the hotel; some changes may not be possible. You can also cancel under the cancellation policy and book again.',
            es: 'Aún no se pueden hacer cambios en línea. Escríbenos con la referencia y el cambio que necesitas y consultaremos al hotel; algunos cambios pueden no ser posibles. También puedes cancelar según la política y reservar de nuevo.',
            tr: 'Değişiklikler henüz çevrim içi yapılamıyor. Rezervasyon numaranızı ve istediğiniz değişikliği bize yazın, otele soralım; bazı değişiklikler mümkün olmayabilir. İptal politikasına göre iptal edip yeniden de rezervasyon yapabilirsiniz.',
            id: 'Perubahan belum bisa dilakukan secara online. Email kami kode pemesanan dan perubahan yang diperlukan, kami akan menanyakan ke hotel; beberapa perubahan mungkin tidak bisa. Anda juga bisa membatalkan sesuai kebijakan lalu memesan lagi.',
            hi: 'बदलाव अभी ऑनलाइन नहीं हो सकते। बुकिंग नंबर और ज़रूरी बदलाव हमें ईमेल करें, हम होटल से पूछेंगे; कुछ बदलाव संभव नहीं हो सकते। आप रद्दीकरण नीति के अनुसार रद्द करके फिर से बुक भी कर सकते हैं।',
            ur: 'تبدیلیاں ابھی آن لائن نہیں ہو سکتیں۔ بکنگ نمبر اور مطلوبہ تبدیلی ہمیں ای میل کریں، ہم ہوٹل سے پوچھیں گے؛ کچھ تبدیلیاں ممکن نہیں ہو سکتیں۔ آپ منسوخی پالیسی کے مطابق منسوخ کر کے دوبارہ بک بھی کر سکتے ہیں۔',
            fr: 'Les modifications ne sont pas encore possibles en ligne. Envoyez-nous votre référence et la modification souhaitée, nous interrogerons l\'hôtel ; certaines modifications peuvent être impossibles. Vous pouvez aussi annuler selon la politique et réserver à nouveau.',
            bn: 'পরিবর্তন এখনও অনলাইনে করা যায় না। বুকিং নম্বর ও প্রয়োজনীয় পরিবর্তন আমাদের ইমেইল করুন, আমরা হোটেলকে জিজ্ঞেস করব; কিছু পরিবর্তন সম্ভব নাও হতে পারে। বাতিল নীতি অনুযায়ী বাতিল করে আবার বুকও করতে পারেন।'),
      ),
      _FaqItem(
        _t3(context,
            ar: 'ما طرق الدفع المتاحة؟',
            en: 'Which payment methods do you accept?',
            es: '¿Qué métodos de pago aceptan?',
            tr: 'Hangi ödeme yöntemlerini kabul ediyorsunuz?',
            id: 'Metode pembayaran apa yang diterima?',
            hi: 'आप कौन से भुगतान तरीके स्वीकार करते हैं?',
            ur: 'آپ کون سے ادائیگی کے طریقے قبول کرتے ہیں؟',
            fr: 'Quels moyens de paiement acceptez-vous ?',
            bn: 'আপনারা কোন পেমেন্ট পদ্ধতি গ্রহণ করেন?'),
        _t3(context,
            ar: 'بطاقات الائتمان والخصم، بالدولار الأمريكي. تتم معالجة الدفع بأمان عبر Stripe، ولا نحتفظ برقم بطاقتك.',
            en: 'Credit and debit cards, in U.S. dollars. Payments are processed securely by Stripe, and we do not store your card number.',
            es: 'Tarjetas de crédito y débito, en dólares estadounidenses. Stripe procesa los pagos de forma segura y no guardamos el número de tu tarjeta.',
            tr: 'ABD doları cinsinden kredi ve banka kartları. Ödemeler Stripe tarafından güvenle işlenir ve kart numaranızı saklamayız.',
            id: 'Kartu kredit dan debit, dalam dolar AS. Pembayaran diproses dengan aman oleh Stripe, dan kami tidak menyimpan nomor kartu Anda.',
            hi: 'अमेरिकी डॉलर में क्रेडिट और डेबिट कार्ड। भुगतान Stripe द्वारा सुरक्षित रूप से प्रोसेस होते हैं, और हम आपका कार्ड नंबर संग्रहीत नहीं करते।',
            ur: 'امریکی ڈالر میں کریڈٹ اور ڈیبٹ کارڈ۔ ادائیگیاں Stripe کے ذریعے محفوظ طریقے سے ہوتی ہیں، اور ہم آپ کا کارڈ نمبر محفوظ نہیں کرتے۔',
            fr: 'Cartes de crédit et de débit, en dollars américains. Les paiements sont traités de façon sécurisée par Stripe et nous ne conservons pas votre numéro de carte.',
            bn: 'মার্কিন ডলারে ক্রেডিট ও ডেবিট কার্ড। পেমেন্ট Stripe নিরাপদে প্রক্রিয়া করে, এবং আমরা আপনার কার্ড নম্বর সংরক্ষণ করি না।'),
      ),
      _FaqItem(
        _t3(context,
            ar: 'أريد حجز 5 غرف أو أكثر',
            en: 'I need 5 or more rooms',
            es: 'Necesito 5 o más habitaciones',
            tr: '5 veya daha fazla odaya ihtiyacım var',
            id: 'Saya butuh 5 kamar atau lebih',
            hi: 'मुझे 5 या अधिक कमरे चाहिए',
            ur: 'مجھے 5 یا زیادہ کمرے چاہئیں',
            fr: 'J\'ai besoin de 5 chambres ou plus',
            bn: 'আমার ৫ বা তার বেশি রুম দরকার'),
        _t3(context,
            ar: 'استخدم تبويب "Group stays" وأرسل طلبك، وسنرسل لك عرض سعر بالبريد. الطلب لا يُلزمك بشيء ولا يُسحب أي مبلغ.',
            en: 'Use the "Group stays" tab to send a request, and we will email you a quote. The request is free and nothing is charged.',
            es: 'Usa la pestaña "Group stays" para enviar una solicitud y te enviaremos un presupuesto por correo. Es gratis y no se cobra nada.',
            tr: '"Group stays" sekmesinden talep gönderin, size e-postayla teklif gönderelim. Talep ücretsizdir ve ödeme alınmaz.',
            id: 'Gunakan tab "Group stays" untuk mengirim permintaan, dan kami akan mengirim penawaran lewat email. Gratis dan tidak ada tagihan.',
            hi: '"Group stays" टैब से अनुरोध भेजें, हम ईमेल से कोटेशन भेजेंगे। अनुरोध मुफ़्त है और कोई शुल्क नहीं लगता।',
            ur: '"Group stays" ٹیب سے درخواست بھیجیں، ہم ای میل پر قیمت بھیجیں گے۔ درخواست مفت ہے اور کوئی رقم نہیں کٹتی۔',
            fr: 'Utilisez l\'onglet « Group stays » pour envoyer une demande, et nous vous enverrons un devis par e-mail. C\'est gratuit et rien n\'est débité.',
            bn: '"Group stays" ট্যাব থেকে অনুরোধ পাঠান, আমরা ইমেইলে মূল্য পাঠাব। অনুরোধ বিনামূল্যে, কোনো টাকা কাটা হয় না।'),
      ),
      _FaqItem(
        _t3(context,
            ar: 'هل يشمل حجز فندق العمرة التأشيرة؟',
            en: 'Does an Umrah hotel booking include a visa?',
            es: '¿La reserva de hotel para la Umrah incluye visado?',
            tr: 'Umre otel rezervasyonu vizeyi kapsar mı?',
            id: 'Apakah pemesanan hotel umrah termasuk visa?',
            hi: 'क्या उमरा होटल बुकिंग में वीज़ा शामिल है?',
            ur: 'کیا عمرہ ہوٹل بکنگ میں ویزا شامل ہے؟',
            fr: 'La réservation d\'hôtel pour la Omra inclut-elle un visa ?',
            bn: 'উমরাহ হোটেল বুকিংয়ে কি ভিসা অন্তর্ভুক্ত?'),
        _t3(context,
            ar: 'لا. الحجز للفندق فقط. التأشيرة وتصاريح العمرة (نسك) مسؤوليتك؛ في تبويب "العمرة" روابط للمواقع السعودية الرسمية.',
            en: 'No. The booking is for the hotel only. The visa and Umrah permits (Nusuk) are your responsibility; the Umrah tab has links to the official Saudi websites.',
            es: 'No. La reserva es solo del hotel. El visado y los permisos de Umrah (Nusuk) son tu responsabilidad; la pestaña Umrah tiene enlaces a los sitios oficiales saudíes.',
            tr: 'Hayır. Rezervasyon yalnızca oteli kapsar. Vize ve Umre izinleri (Nusuk) sizin sorumluluğunuzdadır; Umre sekmesinde resmi Suudi sitelerinin bağlantıları var.',
            id: 'Tidak. Pemesanan hanya untuk hotel. Visa dan izin umrah (Nusuk) menjadi tanggung jawab Anda; tab Umrah berisi tautan ke situs resmi Saudi.',
            hi: 'नहीं। बुकिंग केवल होटल की है। वीज़ा और उमरा परमिट (नुसुक) आपकी ज़िम्मेदारी है; "उमरा" टैब में आधिकारिक सऊदी वेबसाइटों के लिंक हैं।',
            ur: 'نہیں۔ بکنگ صرف ہوٹل کی ہے۔ ویزا اور عمرہ اجازت نامے (نسک) آپ کی ذمہ داری ہیں؛ عمرہ ٹیب میں سرکاری سعودی ویب سائٹس کے لنکس ہیں۔',
            fr: 'Non. La réservation concerne uniquement l\'hôtel. Le visa et les permis de Omra (Nusuk) sont à votre charge ; l\'onglet Omra contient des liens vers les sites officiels saoudiens.',
            bn: 'না। বুকিং শুধু হোটেলের জন্য। ভিসা ও উমরাহ পারমিট (নুসুক) আপনার দায়িত্ব; "উমরাহ" ট্যাবে সৌদি সরকারি ওয়েবসাইটের লিংক আছে।'),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final faqs = _hotelFaqs(context);

    return Scaffold(
      appBar: const AppBanner(),
      body: SafeArea(
        child: ListView(
          controller: _scrollController,
          padding: EdgeInsets.zero,
          children: [
            // هيدر "دعم العملاء" + طريقة التواصل الحقيقية
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSizes.lg),
              color: AppColors.primaryDark,
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        RichText(
                          text: TextSpan(
                            style: const TextStyle(fontSize: 30, fontWeight: FontWeight.bold, color: Colors.white),
                            children: [
                              TextSpan(
                                text: _t3(
                                  context,
                                  ar: 'دعم العملاء',
                                  en: 'Customer support',
                                  es: 'Atención al cliente',
                                  tr: 'Müşteri desteği',
                                  id: 'Dukungan pelanggan',
                                  hi: 'ग्राहक सहायता',
                                  ur: 'کسٹمر سپورٹ',
                                  fr: 'Assistance client',
                                  bn: 'গ্রাহক সহায়তা',
                                ),
                              ),
                              const TextSpan(text: ' .', style: TextStyle(color: Colors.amber)),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _t3(
                            context,
                            ar: 'فريق حقيقي يرد بالعربية والإنجليزية عبر واتساب أو على $_supportEmail',
                            en: 'Real people reply in Arabic and English on WhatsApp or at $_supportEmail',
                            es: 'Personas reales responden en árabe e inglés por WhatsApp o en $_supportEmail',
                            tr: 'Gerçek kişiler WhatsApp\'tan veya $_supportEmail adresinden Arapça ve İngilizce yanıt verir',
                            id: 'Orang sungguhan membalas dalam bahasa Arab dan Inggris lewat WhatsApp atau di $_supportEmail',
                            hi: 'असली लोग WhatsApp पर या $_supportEmail पर अरबी और अंग्रेज़ी में जवाब देते हैं',
                            ur: 'حقیقی لوگ واٹس ایپ پر یا $_supportEmail پر عربی اور انگریزی میں جواب دیتے ہیں',
                            fr: 'De vraies personnes répondent en arabe et en anglais sur WhatsApp ou à $_supportEmail',
                            bn: 'সত্যিকারের মানুষ WhatsApp-এ বা $_supportEmail-এ আরবি ও ইংরেজিতে উত্তর দেন',
                          ),
                          style: const TextStyle(color: Colors.white70, fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.support_agent, size: 64, color: Colors.white70),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSizes.lg),
              child: Column(
                key: _faqSectionKey,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _t3(
                          context,
                          ar: 'الأسئلة الشائعة: الفنادق',
                          en: 'Frequently asked questions: hotels',
                          es: 'Preguntas frecuentes: hoteles',
                          tr: 'Sık sorulan sorular: oteller',
                          id: 'Pertanyaan umum: hotel',
                          hi: 'अक्सर पूछे जाने वाले प्रश्न: होटल',
                          ur: 'اکثر پوچھے جانے والے سوالات: ہوٹلز',
                          fr: 'Questions fréquentes : hôtels',
                          bn: 'প্রায়শই জিজ্ঞাসিত প্রশ্ন: হোটেল',
                        ),
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSizes.md),
                  // كروت الأسئلة الشائعة (عمودان على الشاشات الواسعة)
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final isWide = constraints.maxWidth > 700;
                      if (!isWide) {
                        return Column(
                          children: faqs.map((f) => _FaqTile(item: f)).toList(),
                        );
                      }
                      final rows = <Widget>[];
                      for (var i = 0; i < faqs.length; i += 2) {
                        final second = i + 1 < faqs.length ? faqs[i + 1] : null;
                        rows.add(
                          IntrinsicHeight(
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Expanded(child: _FaqTile(item: faqs[i])),
                                const SizedBox(width: AppSizes.md),
                                Expanded(
                                  child: second != null ? _FaqTile(item: second) : const SizedBox.shrink(),
                                ),
                              ],
                            ),
                          ),
                        );
                        rows.add(const SizedBox(height: AppSizes.sm));
                      }
                      return Column(children: rows);
                    },
                  ),
                  const SizedBox(height: AppSizes.sm),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        _t3(
                          context,
                          ar: 'تبحث عن حجزك؟',
                          en: 'Looking for your booking?',
                          es: '¿Buscas tu reserva?',
                          tr: 'Rezervasyonunuzu mu arıyorsunuz?',
                          id: 'Mencari pemesanan Anda?',
                          hi: 'अपनी बुकिंग ढूंढ रहे हैं?',
                          ur: 'اپنی بکنگ تلاش کر رہے ہیں؟',
                          fr: 'Vous cherchez votre réservation ?',
                          bn: 'আপনার বুকিং খুঁজছেন?',
                        ),
                        style: const TextStyle(color: AppColors.textSecondary),
                      ),
                      TextButton.icon(
                        onPressed: () => context.push(AppRoutes.myBookings),
                        icon: const Icon(Icons.luggage_outlined, size: 18),
                        label: Text(_t3(
                          context,
                          ar: 'حجوزاتي',
                          en: 'My Bookings',
                          es: 'Mis reservas',
                          tr: 'Rezervasyonlarım',
                          id: 'Pesanan Saya',
                          hi: 'मेरी बुकिंग',
                          ur: 'میری بکنگز',
                          fr: 'Mes réservations',
                          bn: 'আমার বুকিং',
                        )),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            // شريط الوصول السريع: وسائل تواصل حقيقية فقط
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_whatsAppNumber.isNotEmpty) ...[
                    Expanded(
                      child: _QuickAccessButton(
                        icon: Icons.chat_outlined,
                        label: _t3(
                          context,
                          ar: 'واتساب',
                          en: 'WhatsApp',
                          es: 'WhatsApp',
                          tr: 'WhatsApp',
                          id: 'WhatsApp',
                          hi: 'WhatsApp',
                          ur: 'واٹس ایپ',
                          fr: 'WhatsApp',
                          bn: 'WhatsApp',
                        ),
                        onTap: () => _openWhatsApp(context),
                      ),
                    ),
                    const VerticalDivider(width: 1),
                  ],
                  Expanded(
                    child: _QuickAccessButton(
                      icon: Icons.email_outlined,
                      label: _t3(
                        context,
                        ar: 'راسلنا',
                        en: 'Email us',
                        es: 'Escríbenos',
                        tr: 'Bize yazın',
                        id: 'Email kami',
                        hi: 'हमें ईमेल करें',
                        ur: 'ہمیں ای میل کریں',
                        fr: 'Écrivez-nous',
                        bn: 'আমাদের ইমেইল করুন',
                      ),
                      onTap: () => _openEmail(context),
                    ),
                  ),
                  if (_supportPhone.isNotEmpty) ...[
                    const VerticalDivider(width: 1),
                    Expanded(
                      child: _QuickAccessButton(
                        icon: Icons.call_outlined,
                        label: _t3(
                          context,
                          ar: 'اتصل بنا',
                          en: 'Call us',
                          es: 'Llámanos',
                          tr: 'Bizi arayın',
                          id: 'Hubungi kami',
                          hi: 'हमें कॉल करें',
                          ur: 'ہمیں کال کریں',
                          fr: 'Appelez-nous',
                          bn: 'আমাদের কল করুন',
                        ),
                        onTap: () => _openPhone(context),
                      ),
                    ),
                  ],
                  const VerticalDivider(width: 1),
                  Expanded(
                    child: _QuickAccessButton(
                      icon: Icons.info_outline,
                      label: _t3(
                        context,
                        ar: 'الأسئلة الشائعة',
                        en: 'FAQ',
                        es: 'Preguntas frecuentes',
                        tr: 'SSS',
                        id: 'FAQ',
                        hi: 'सामान्य प्रश्न',
                        ur: 'عام سوالات',
                        fr: 'FAQ',
                        bn: 'প্রশ্নোত্তর',
                      ),
                      onTap: _scrollToFaq,
                    ),
                  ),
                  const VerticalDivider(width: 1),
                  Expanded(
                    child: _QuickAccessButton(
                      icon: Icons.hotel_outlined,
                      label: _t3(
                        context,
                        ar: 'مشكلة في الفندق؟',
                        en: 'Problem at the hotel?',
                        es: '¿Problema en el hotel?',
                        tr: 'Otelde sorun mu var?',
                        id: 'Masalah di hotel?',
                        hi: 'होटल में समस्या?',
                        ur: 'ہوٹل میں مسئلہ؟',
                        fr: 'Problème à l\'hôtel ?',
                        bn: 'হোটেলে সমস্যা?',
                      ),
                      onTap: () => _showHotelProblemDialog(context),
                    ),
                  ),
                ],
              ),
            ),
            const AppFooter(),
          ],
        ),
      ),
    );
  }
}

class _FaqTile extends StatefulWidget {
  final _FaqItem item;
  const _FaqTile({required this.item});

  @override
  State<_FaqTile> createState() => _FaqTileState();
}

class _FaqTileState extends State<_FaqTile> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSizes.sm),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => setState(() => _expanded = !_expanded),
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.item.question,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                  Icon(_expanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down),
                ],
              ),
              if (_expanded) ...[
                const SizedBox(height: 8),
                Text(
                  widget.item.answer,
                  style: const TextStyle(color: AppColors.textSecondary, height: 1.4),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickAccessButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickAccessButton({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSizes.md),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: AppColors.primary),
            const SizedBox(height: 6),
            Text(label, style: const TextStyle(fontSize: 13), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}