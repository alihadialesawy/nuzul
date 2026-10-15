import 'package:flutter/material.dart';

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

/// صفحة "عن Flynoom".
///
/// ⚠️ كل رقم أو ادعاء هنا يجب أن يكون صحيحًا (FTC تعتبر الادعاءات التسويقية
/// غير الصحيحة خداعًا). أُزيلت من النسخة السابقة: "76+ فندق شريك"، "دعم 24/7"،
/// حجز السيارات، ومساعد AI يتابع الأسعار — لأنها غير مطابقة للخدمة الحالية.
/// عند إطلاق ميزة جديدة فعليًا، أضفها هنا.
class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    final stats = [
      (
      value: '1,800+',
      label: _t3(context,
          ar: 'وجهة داخل أمريكا',
          en: 'U.S. destinations',
          es: 'Destinos en EE. UU.',
          tr: 'ABD destinasyonu',
          id: 'Destinasi di AS',
          hi: 'अमेरिकी गंतव्य',
          ur: 'امریکی مقامات',
          fr: 'Destinations aux États-Unis',
          bn: 'মার্কিন গন্তব্য'),
      ),
      (
      value: '9',
      label: _t3(context,
          ar: 'لغات مدعومة',
          en: 'Languages supported',
          es: 'Idiomas admitidos',
          tr: 'Desteklenen dil',
          id: 'Bahasa yang didukung',
          hi: 'समर्थित भाषाएं',
          ur: 'معاون زبانیں',
          fr: 'Langues prises en charge',
          bn: 'সমর্থিত ভাষা'),
      ),
      (
      value: 'USD',
      label: _t3(context,
          ar: 'أسعار شاملة بالدولار',
          en: 'All-in prices in U.S. dollars',
          es: 'Precios totales en dólares',
          tr: 'ABD doları ile her şey dahil fiyatlar',
          id: 'Harga total dalam dolar AS',
          hi: 'अमेरिकी डॉलर में कुल कीमतें',
          ur: 'امریکی ڈالر میں مکمل قیمتیں',
          fr: 'Prix tout compris en dollars US',
          bn: 'মার্কিন ডলারে সব-মিলিয়ে দাম'),
      ),
    ];

    Widget heading(String text) => Text(
      text,
      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
    );

    Widget body(String text) => Text(
      text,
      style: const TextStyle(fontSize: 15, color: AppColors.textSecondary, height: 1.5),
    );

    return Scaffold(
      appBar: const AppBanner(),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSizes.lg),
          children: [
            Text(
              _t3(context,
                  ar: 'عن Flynoom',
                  en: 'About Flynoom',
                  es: 'Sobre Flynoom',
                  tr: 'Flynoom Hakkında',
                  id: 'Tentang Flynoom',
                  hi: 'Flynoom के बारे में',
                  ur: 'Flynoom کے بارے میں',
                  fr: 'À propos de Flynoom',
                  bn: 'Flynoom সম্পর্কে'),
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppSizes.md),
            body(_t3(
              context,
              ar: 'Flynoom وكالة سفر إلكترونية مقرها ولاية ميشيغان. نساعدك على البحث عن فنادق وحجزها في أنحاء الولايات المتحدة '
                  'وفي وجهات يحبها مسافرونا، منها مكة المكرمة والمدينة المنورة وإسطنبول ودبي. الأسعار معروضة بالدولار الأمريكي، وأي رسوم يحصّلها الفندق عند الوصول نعرضها لك قبل الدفع.',
              en: 'Flynoom is an online travel agency based in Michigan. We help you find and book hotels across the United States '
                  'and in popular destinations abroad, including Makkah, Madinah, Istanbul, and Dubai. Prices are shown in U.S. dollars, and any fees the hotel collects at check-in are shown before you pay.',
              es: 'Flynoom es una agencia de viajes en línea con sede en Michigan. Te ayudamos a encontrar y reservar hoteles en todo Estados Unidos '
                  'y en destinos populares del extranjero, como La Meca, Medina, Estambul y Dubái. Los precios se muestran en dólares estadounidenses, y cualquier cargo que el hotel cobre al llegar se muestra antes de pagar.',
              tr: 'Flynoom, Michigan merkezli bir çevrim içi seyahat acentesidir. Amerika Birleşik Devletleri genelinde ve Mekke, Medine, İstanbul ve Dubai gibi popüler yurt dışı destinasyonlarda '
                  'otel bulmanıza ve rezervasyon yapmanıza yardımcı oluyoruz. Fiyatlar ABD doları cinsinden gösterilir ve otelin girişte tahsil ettiği ücretler ödeme yapmadan önce gösterilir.',
              id: 'Flynoom adalah agen perjalanan online yang berbasis di Michigan. Kami membantu Anda menemukan dan memesan hotel di seluruh Amerika Serikat '
                  'dan di destinasi populer luar negeri, termasuk Makkah, Madinah, Istanbul, dan Dubai. Harga ditampilkan dalam dolar AS, dan biaya apa pun yang ditagih hotel saat check-in ditampilkan sebelum Anda membayar.',
              hi: 'Flynoom मिशिगन स्थित एक ऑनलाइन ट्रैवल एजेंसी है। हम पूरे संयुक्त राज्य अमेरिका में और विदेश के लोकप्रिय गंतव्यों, जैसे मक्का, मदीना, इस्तांबुल और दुबई में '
                  'होटल खोजने और बुक करने में आपकी मदद करते हैं। कीमतें अमेरिकी डॉलर में दिखाई जाती हैं, और होटल चेक-इन पर जो भी शुल्क लेता है वह भुगतान से पहले दिखाया जाता है।',
              ur: 'Flynoom مشی گن میں قائم ایک آن لائن ٹریول ایجنسی ہے۔ ہم پورے امریکہ میں اور بیرونِ ملک مقبول مقامات، جیسے مکہ، مدینہ، استنبول اور دبئی میں '
                  'ہوٹل تلاش کرنے اور بک کرنے میں آپ کی مدد کرتے ہیں۔ قیمتیں امریکی ڈالر میں دکھائی جاتی ہیں، اور ہوٹل چیک اِن پر جو بھی فیس لیتا ہے وہ ادائیگی سے پہلے دکھائی جاتی ہے۔',
              fr: 'Flynoom est une agence de voyage en ligne basée au Michigan. Nous vous aidons à trouver et réserver des hôtels partout aux États-Unis '
                  'et dans des destinations prisées à l\'étranger, dont La Mecque, Médine, Istanbul et Dubaï. Les prix sont affichés en dollars américains, et les frais perçus par l\'hôtel à l\'arrivée sont indiqués avant le paiement.',
              bn: 'Flynoom মিশিগান-ভিত্তিক একটি অনলাইন ট্রাভেল এজেন্সি। আমরা আপনাকে যুক্তরাষ্ট্র জুড়ে এবং বিদেশের জনপ্রিয় গন্তব্য, যেমন মক্কা, মদিনা, ইস্তাম্বুল ও দুবাইয়ে '
                  'হোটেল খুঁজে বুক করতে সাহায্য করি। দাম মার্কিন ডলারে দেখানো হয়, এবং চেক-ইনের সময় হোটেল যে ফি নেয় তা পেমেন্টের আগেই দেখানো হয়।',
            )),
            const SizedBox(height: AppSizes.xl),
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (var i = 0; i < stats.length; i++) ...[
                    if (i > 0) const SizedBox(width: AppSizes.sm),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(AppSizes.md),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          border: Border.all(color: AppColors.divider),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            Text(
                              stats[i].value,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              stats[i].label,
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: AppSizes.xl),
            heading(_t3(context,
                ar: 'رسالتنا',
                en: 'Our mission',
                es: 'Nuestra misión',
                tr: 'Misyonumuz',
                id: 'Misi Kami',
                hi: 'हमारा उद्देश्य',
                ur: 'ہمارا مشن',
                fr: 'Notre mission',
                bn: 'আমাদের লক্ষ্য')),
            const SizedBox(height: AppSizes.sm),
            body(_t3(
              context,
              ar: 'نريد أن يكون التخطيط للسفر بسيطًا وصادقًا: أسعار شاملة وواضحة دون رسوم خفية، وشروط إلغاء واضحة قبل الدفع، '
                  'وأشخاص حقيقيون يساعدونك عبر البريد الإلكتروني عندما تحتاجنا.',
              en: 'We want planning a trip to be simple and honest: clear all-in prices with no hidden fees, clear cancellation terms before you pay, '
                  'and real people who help you by email when you need us.',
              es: 'Queremos que planificar un viaje sea simple y honesto: precios totales claros sin cargos ocultos, condiciones de cancelación claras antes de pagar '
                  'y personas reales que te ayudan por correo electrónico cuando nos necesites.',
              tr: 'Seyahat planlamanın basit ve dürüst olmasını istiyoruz: gizli ücret olmadan net, her şey dahil fiyatlar, ödeme öncesinde net iptal koşulları '
                  've ihtiyaç duyduğunuzda size e-posta ile yardım eden gerçek insanlar.',
              id: 'Kami ingin merencanakan perjalanan menjadi sederhana dan jujur: harga total yang jelas tanpa biaya tersembunyi, ketentuan pembatalan yang jelas sebelum Anda membayar, '
                  'dan orang sungguhan yang membantu Anda melalui email saat Anda membutuhkan kami.',
              hi: 'हम चाहते हैं कि यात्रा की योजना बनाना सरल और ईमानदार हो: बिना छुपे शुल्क के स्पष्ट कुल कीमतें, भुगतान से पहले स्पष्ट रद्दीकरण शर्तें, '
                  'और असली लोग जो ज़रूरत पड़ने पर ईमेल के ज़रिए आपकी मदद करते हैं।',
              ur: 'ہم چاہتے ہیں کہ سفر کی منصوبہ بندی سادہ اور دیانت دار ہو: بغیر چھپی فیس کے واضح مکمل قیمتیں، ادائیگی سے پہلے منسوخی کی واضح شرائط، '
                  'اور حقیقی لوگ جو ضرورت پڑنے پر ای میل کے ذریعے آپ کی مدد کرتے ہیں۔',
              fr: 'Nous voulons que la préparation d\'un voyage soit simple et honnête : des prix tout compris clairs sans frais cachés, des conditions d\'annulation claires avant de payer, '
                  'et de vraies personnes qui vous aident par e-mail quand vous en avez besoin.',
              bn: 'আমরা চাই ভ্রমণ পরিকল্পনা সহজ ও সৎ হোক: কোনো লুকানো ফি ছাড়া স্পষ্ট সব-মিলিয়ে দাম, পেমেন্টের আগে স্পষ্ট বাতিলকরণের শর্ত, '
                  'এবং প্রয়োজনে ইমেলের মাধ্যমে আপনাকে সাহায্য করার জন্য সত্যিকারের মানুষ।',
            )),
            const SizedBox(height: AppSizes.xl),
            heading(_t3(context,
                ar: 'من نحن',
                en: 'Who we are',
                es: 'Quiénes somos',
                tr: 'Biz kimiz',
                id: 'Siapa kami',
                hi: 'हम कौन हैं',
                ur: 'ہم کون ہیں',
                fr: 'Qui sommes-nous',
                bn: 'আমরা কারা')),
            const SizedBox(height: AppSizes.sm),
            body(_t3(
              context,
              ar: 'تدير Flynoom شركةُ FLYNOOM LLC، وهي شركة مستقلة مسجلة في ولاية ميشيغان. نحصل على الغرف الفندقية عبر شريكنا HOTELBEDS، '
                  'وتُعالَج المدفوعات بأمان عبر Stripe، فلا نخزّن رقم بطاقتك أبدًا.',
              en: 'Flynoom is operated by FLYNOOM LLC, an independent company registered in Michigan. Hotel rooms are supplied through our partner HOTELBEDS, '
                  'and payments are processed securely by Stripe, so we never store your card number.',
              es: 'Flynoom es operado por FLYNOOM LLC, una empresa independiente registrada en Michigan. Las habitaciones de hotel se obtienen a través de nuestro socio HOTELBEDS, '
                  'y los pagos se procesan de forma segura con Stripe, por lo que nunca guardamos el número de tu tarjeta.',
              tr: 'Flynoom, Michigan\'da kayıtlı bağımsız bir şirket olan FLYNOOM LLC tarafından işletilmektedir. Otel odaları iş ortağımız HOTELBEDS aracılığıyla sağlanır '
                  've ödemeler Stripe tarafından güvenle işlenir; bu nedenle kart numaranızı asla saklamayız.',
              id: 'Flynoom dioperasikan oleh FLYNOOM LLC, perusahaan independen yang terdaftar di Michigan. Kamar hotel disediakan melalui mitra kami HOTELBEDS, '
                  'dan pembayaran diproses dengan aman oleh Stripe, sehingga kami tidak pernah menyimpan nomor kartu Anda.',
              hi: 'Flynoom का संचालन FLYNOOM LLC करती है, जो मिशिगन में पंजीकृत एक स्वतंत्र कंपनी है। होटल के कमरे हमारे साझेदार HOTELBEDS के माध्यम से मिलते हैं, '
                  'और भुगतान Stripe द्वारा सुरक्षित रूप से संसाधित होते हैं, इसलिए हम आपका कार्ड नंबर कभी संग्रहीत नहीं करते।',
              ur: 'Flynoom کو FLYNOOM LLC چلاتی ہے، جو مشی گن میں رجسٹرڈ ایک آزاد کمپنی ہے۔ ہوٹل کے کمرے ہمارے پارٹنر HOTELBEDS کے ذریعے فراہم کیے جاتے ہیں، '
                  'اور ادائیگیاں Stripe کے ذریعے محفوظ طریقے سے پروسیس ہوتی ہیں، اس لیے ہم آپ کا کارڈ نمبر کبھی محفوظ نہیں کرتے۔',
              fr: 'Flynoom est exploité par FLYNOOM LLC, une société indépendante enregistrée au Michigan. Les chambres d\'hôtel sont fournies par notre partenaire HOTELBEDS, '
                  'et les paiements sont traités en toute sécurité par Stripe : nous ne conservons jamais votre numéro de carte.',
              bn: 'Flynoom পরিচালনা করে FLYNOOM LLC, মিশিগানে নিবন্ধিত একটি স্বাধীন কোম্পানি। হোটেলের রুম আমাদের অংশীদার HOTELBEDS-এর মাধ্যমে সরবরাহ করা হয়, '
                  'এবং পেমেন্ট Stripe নিরাপদে প্রক্রিয়া করে, তাই আমরা কখনো আপনার কার্ড নম্বর সংরক্ষণ করি না।',
            )),
            const SizedBox(height: AppSizes.xl),
            const AppFooter(),
          ],
        ),
      ),
    );
  }
}