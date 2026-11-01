import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';

/// ترجمات الصفحة للغات السبع الأخرى.
/// الترتيب: [عنوان الشريط، العنوان الرئيسي، المقدمة، عنوان "مهتم بالانضمام؟"، النص، زر التواصل].
const Map<String, List<String>> _i18n = {
  'es': [
    'Empleo',
    'Empleo en Flynoom',
    'Flynoom todavía está en una etapa muy temprana: un equipo pequeño que construye una plataforma de viajes desde cero. Ahora mismo no tenemos vacantes formales, pero eso cambiará a medida que la plataforma crezca.',
    '¿Te interesa unirte?',
    'Si tienes experiencia que creas que puede ayudar a Flynoom (desarrollo, diseño, atención al cliente o cualquier otra área), puedes escribirnos desde nuestra página de Atención al cliente y contarnos tu interés. Guardaremos tu mensaje y te contactaremos cuando se abra un puesto adecuado para ti.',
    'Contáctanos',
  ],
  'tr': [
    'Kariyer',
    'Flynoom’da kariyer',
    'Flynoom henüz çok erken aşamada: sıfırdan bir seyahat platformu kuran küçük bir ekibiz. Şu anda resmî açık pozisyonumuz yok, ancak platform büyüdükçe bu değişecek.',
    'Bize katılmak ister misiniz?',
    'Flynoom’a katkı sağlayabileceğini düşündüğünüz bir deneyiminiz varsa (yazılım geliştirme, tasarım, müşteri desteği veya başka bir alan), Müşteri Hizmetleri sayfamız üzerinden bize ulaşıp ilginizi belirtebilirsiniz. Mesajınızı saklayacak ve size uygun bir pozisyon açıldığında dönüş yapacağız.',
    'Bize ulaşın',
  ],
  'id': [
    'Karier',
    'Karier di Flynoom',
    'Flynoom masih di tahap sangat awal: tim kecil yang membangun platform perjalanan dari nol. Saat ini kami belum memiliki lowongan resmi, tetapi hal itu akan berubah seiring berkembangnya platform.',
    'Tertarik bergabung?',
    'Jika Anda memiliki pengalaman yang menurut Anda dapat membantu Flynoom (pengembangan, desain, layanan pelanggan, atau bidang lainnya), Anda dapat menghubungi kami melalui halaman Layanan Pelanggan dan menyampaikan minat Anda. Kami akan menyimpan pesan Anda dan menghubungi Anda saat ada posisi yang sesuai.',
    'Hubungi kami',
  ],
  'hi': [
    'करियर',
    'Flynoom में करियर',
    'Flynoom अभी बहुत शुरुआती दौर में है: एक छोटी टीम जो शुरू से एक ट्रैवल प्लेटफ़ॉर्म बना रही है। फ़िलहाल हमारे पास कोई औपचारिक रिक्त पद नहीं है, लेकिन प्लेटफ़ॉर्म के बढ़ने के साथ यह बदलेगा।',
    'हमसे जुड़ना चाहते हैं?',
    'अगर आपके पास ऐसा अनुभव है जो आपको लगता है कि Flynoom के काम आ सकता है (डेवलपमेंट, डिज़ाइन, ग्राहक सहायता या कोई और क्षेत्र), तो आप हमारे ग्राहक सेवा पेज के ज़रिए हमसे संपर्क करके अपनी रुचि बता सकते हैं। हम आपका संदेश सहेज कर रखेंगे और आपके लिए उपयुक्त पद खुलते ही आपसे संपर्क करेंगे।',
    'हमसे संपर्क करें',
  ],
  'ur': [
    'ملازمتیں',
    'Flynoom میں ملازمتیں',
    'Flynoom ابھی بہت ابتدائی مرحلے میں ہے: ایک چھوٹی ٹیم جو شروع سے ایک سفری پلیٹ فارم بنا رہی ہے۔ فی الحال ہمارے پاس کوئی باضابطہ خالی آسامی نہیں ہے، لیکن پلیٹ فارم کے بڑھنے کے ساتھ یہ بدل جائے گا۔',
    'ہمارے ساتھ شامل ہونا چاہتے ہیں؟',
    'اگر آپ کے پاس ایسا تجربہ ہے جو آپ کے خیال میں Flynoom کے کام آ سکتا ہے (ڈیولپمنٹ، ڈیزائن، کسٹمر سپورٹ یا کوئی اور شعبہ)، تو آپ ہمارے کسٹمر سروس صفحے کے ذریعے ہم سے رابطہ کر کے اپنی دلچسپی بتا سکتے ہیں۔ ہم آپ کا پیغام محفوظ رکھیں گے اور آپ کے لیے موزوں آسامی کھلتے ہی آپ سے رابطہ کریں گے۔',
    'ہم سے رابطہ کریں',
  ],
  'fr': [
    'Carrières',
    'Carrières chez Flynoom',
    'Flynoom n’en est qu’à ses débuts : une petite équipe qui construit une plateforme de voyage à partir de zéro. Nous n’avons pas de postes ouverts pour le moment, mais cela changera à mesure que la plateforme se développera.',
    'Envie de nous rejoindre ?',
    'Si vous avez une expérience qui pourrait aider Flynoom (développement, design, service client ou tout autre domaine), vous pouvez nous écrire via notre page Service client pour nous faire part de votre intérêt. Nous conserverons votre message et vous recontacterons dès qu’un poste adapté s’ouvrira.',
    'Nous contacter',
  ],
  'bn': [
    'ক্যারিয়ার',
    'Flynoom-এ ক্যারিয়ার',
    'Flynoom এখনও একেবারে প্রাথমিক পর্যায়ে: একটি ছোট দল শূন্য থেকে একটি ভ্রমণ প্ল্যাটফর্ম তৈরি করছে। এই মুহূর্তে আমাদের কোনো আনুষ্ঠানিক শূন্যপদ নেই, তবে প্ল্যাটফর্ম বড় হওয়ার সঙ্গে সঙ্গে তা বদলাবে।',
    'আমাদের সঙ্গে যোগ দিতে চান?',
    'আপনার যদি এমন অভিজ্ঞতা থাকে যা Flynoom-এর কাজে আসতে পারে বলে মনে করেন (ডেভেলপমেন্ট, ডিজাইন, গ্রাহক সহায়তা বা অন্য কোনো ক্ষেত্র), তাহলে আমাদের গ্রাহক সেবা পৃষ্ঠার মাধ্যমে যোগাযোগ করে আপনার আগ্রহের কথা জানাতে পারেন। আমরা আপনার বার্তা সংরক্ষণ করব এবং উপযুক্ত পদ খুললেই আপনার সঙ্গে যোগাযোগ করব।',
    'যোগাযোগ করুন',
  ],
};

class CareersPage extends StatelessWidget {
  const CareersPage({super.key});

  @override
  Widget build(BuildContext context) {
    final lang = Localizations.localeOf(context).languageCode;
    final isArabic = lang == 'ar';
    final tr = _i18n[lang];

    // نص مترجم من _i18n إن وُجد، وإلا العربية أو الإنجليزية.
    String pick(int i, String en, String ar) =>
        (tr != null && i < tr.length) ? tr[i] : (isArabic ? ar : en);

    return Scaffold(
      appBar: AppBar(
        title: Text(pick(0, 'Careers', 'الوظائف')),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSizes.md),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  pick(1, 'Careers at Flynoom', 'الوظائف في Flynoom'),
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: AppSizes.md),
                Text(
                  pick(
                    2,
                    "Flynoom is still very early — a small team building a travel platform from the ground up. We don't have formal open positions right now, but that will change as the platform grows.",
                    'ما زالت Flynoom في مراحلها الأولى، فنحن فريق صغير يبني منصة سفر من الصفر. لا توجد وظائف شاغرة رسميًا حاليًا، لكن هذا سيتغيّر مع نمو المنصة.',
                  ),
                  style: const TextStyle(fontSize: 14, height: 1.6, color: AppColors.textSecondary),
                ),
                const SizedBox(height: AppSizes.lg),
                Text(
                  pick(3, 'Interested in joining us?', 'هل تودّ الانضمام إلينا؟'),
                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 6),
                Text(
                  pick(
                    4,
                    "If you have experience you think could help Flynoom (development, design, customer support, or anything else), you can reach out through our Customer Service page and let us know — we'll keep your note on file and get back to you when a role opens up.",
                    'إن كانت لديك خبرة تعتقد أنها قد تفيد Flynoom (في التطوير أو التصميم أو دعم العملاء أو أي مجال آخر)، فيمكنك التواصل معنا عبر صفحة خدمة العملاء وإخبارنا باهتمامك، وسنحتفظ برسالتك ونعود إليك عند توفر فرصة تناسبك.',
                  ),
                  style: const TextStyle(fontSize: 14, height: 1.6, color: AppColors.textSecondary),
                ),
                const SizedBox(height: AppSizes.lg),
                OutlinedButton(
                  onPressed: () => context.push(AppRoutes.support),
                  child: Text(pick(5, 'Contact us', 'تواصل معنا')),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}