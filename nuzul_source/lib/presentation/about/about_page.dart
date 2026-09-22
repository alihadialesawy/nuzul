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

/// صفحة تعريفية بسيطة عن Safr-AI (قصة المنصة، رسالتها، وأرقامها الأساسية).
class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    final stats = [
      (
      value: '76+',
      label: _t3(context, ar: 'فندق شريك', en: 'Partner hotels', es: 'Hoteles asociados', tr: 'Ortak otel', id: 'Hotel mitra',
          hi: 'साझेदार होटल',
          ur: 'پارٹنر ہوٹلز',
          fr: 'Hôtels partenaires',
          bn: 'অংশীদার হোটেল'),
      ),
      (
      value: '9',
      label: _t3(context, ar: 'لغات مدعومة', en: 'Languages supported', es: 'Idiomas admitidos', tr: 'Desteklenen dil', id: 'Bahasa yang didukung',
          hi: 'समर्थित भाषाएं',
          ur: 'معاون زبانیں',
          fr: 'Langues prises en charge',
          bn: 'সমর্থিত ভাষা'),
      ),
      (
      value: '24/7',
      label: _t3(context, ar: 'دعم متواصل', en: 'Ongoing support', es: 'Soporte continuo', tr: 'Kesintisiz destek', id: 'Dukungan berkelanjutan',
          hi: 'निरंतर सहायता',
          ur: 'مسلسل معاونت',
          fr: 'Assistance continue',
          bn: 'অবিরাম সহায়তা'),
      ),
    ];

    return Scaffold(
      appBar: const AppBanner(),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSizes.lg),
          children: [
            Text(
              _t3(context, ar: 'عن Safr-AI', en: 'About Safr-AI', es: 'Sobre Safr-AI', tr: 'Safr-AI Hakkında', id: 'Tentang Safr-AI',
                  hi: 'Safr-AI के बारे में',
                  ur: 'Safr-AI کے بارے میں',
                  fr: 'À propos de Safr-AI',
                  bn: 'Safr-AI সম্পর্কে'),
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppSizes.md),
            Text(
              _t3(
                context,
                ar: 'Safr-AI منصة سفر تساعدك على حجز الفنادق ورحلات الطيران والسيارات في مكان واحد، '
                    'بمساعدة مساعد ذكاء اصطناعي يرشّح لك أفضل الخيارات ويتابع أسعار رحلاتك نيابة عنك.',
                en: 'Safr-AI is a travel platform that lets you book hotels, flights, and cars all in one '
                    'place, with an AI assistant that recommends the best options and tracks your flight prices for you.',
                es: 'Safr-AI es una plataforma de viajes que te permite reservar hoteles, vuelos y coches en '
                    'un solo lugar, con un asistente de IA que recomienda las mejores opciones y sigue los precios de tus vuelos.',
                tr: 'Safr-AI, otel, uçuş ve araç rezervasyonlarını tek bir yerden yapmanızı sağlayan bir '
                    'seyahat platformudur; yapay zeka asistanı size en iyi seçenekleri önerir ve uçuş fiyatlarınızı sizin adınıza takip eder.',
                id: 'Safr-AI adalah platform perjalanan yang memungkinkan Anda memesan hotel, penerbangan, '
                    'dan mobil di satu tempat, dengan asisten AI yang merekomendasikan pilihan terbaik dan melacak harga penerbangan Anda.',
                hi: 'Safr-AI एक यात्रा प्लेटफ़ॉर्म है जो आपको एक ही जगह पर होटल, उड़ानें और कारें बुक करने '
                    'की सुविधा देता है, साथ ही एक AI सहायक जो सर्वोत्तम विकल्प सुझाता है और आपकी उड़ान की कीमतों पर नज़र रखता है।',
                ur: 'Safr-AI ایک سفری پلیٹ فارم ہے جو آپ کو ایک ہی جگہ ہوٹل، پروازیں، اور کاریں بک کرنے '
                    'کی سہولت دیتا ہے، ساتھ ہی ایک AI معاون جو بہترین اختیارات تجویز کرتا ہے اور آپ کی جانب سے پرواز کی قیمتوں پر نظر رکھتا ہے۔',
                fr: 'Safr-AI est une plateforme de voyage qui vous permet de réserver hôtels, vols et '
                    'voitures en un seul endroit, avec un assistant IA qui recommande les meilleures options et suit les prix de vos vols pour vous.',
                bn: 'Safr-AI একটি ভ্রমণ প্ল্যাটফর্ম যা আপনাকে এক জায়গায় হোটেল, ফ্লাইট এবং গাড়ি বুক করতে '
                    'সাহায্য করে, একটি AI সহায়কের সাথে যা সেরা বিকল্প সুপারিশ করে এবং আপনার পক্ষে ফ্লাইটের মূল্য ট্র্যাক করে।',
              ),
              style: const TextStyle(fontSize: 15, color: AppColors.textSecondary, height: 1.5),
            ),
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
            Text(
              _t3(context, ar: 'رسالتنا', en: 'Our mission', es: 'Nuestra misión', tr: 'Misyonumuz', id: 'Misi Kami',
                  hi: 'हमारा उद्देश्य',
                  ur: 'ہمارا مشن',
                  fr: 'Notre mission',
                  bn: 'আমাদের লক্ষ্য'),
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppSizes.sm),
            Text(
              _t3(
                context,
                ar: 'نسهّل رحلة التخطيط للسفر من بدايتها إلى نهايتها، بأسعار شفافة دون رسوم خفية، '
                    'ودعم متاح على مدار الساعة.',
                en: "We're simplifying the entire trip-planning journey with transparent pricing, no hidden "
                    'fees, and round-the-clock support.',
                es: 'Simplificamos todo el proceso de planificación de viajes con precios transparentes, sin '
                    'cargos ocultos y soporte las 24 horas.',
                tr: 'Şeffaf fiyatlandırma, gizli ücret olmadan ve kesintisiz destekle tüm seyahat planlama '
                    'sürecini basitleştiriyoruz.',
                id: 'Kami menyederhanakan seluruh perjalanan perencanaan perjalanan dengan harga transparan, '
                    'tanpa biaya tersembunyi, dan dukungan sepanjang waktu.',
                hi: 'हम पारदर्शी मूल्य निर्धारण, बिना किसी छुपे शुल्क के, और चौबीसों घंटे सहायता के साथ '
                    'यात्रा योजना की पूरी प्रक्रिया को आसान बना रहे हैं।',
                ur: 'ہم شفاف قیمتوں، بغیر کسی چھپی ہوئی فیس کے، اور چوبیس گھنٹے معاونت کے ساتھ سفری '
                    'منصوبہ بندی کے پورے سفر کو آسان بنا رہے ہیں۔',
                fr: 'Nous simplifions tout le parcours de planification de voyage avec des prix transparents, '
                    'sans frais cachés, et une assistance disponible 24h/24 et 7j/7.',
                bn: 'আমরা স্বচ্ছ মূল্য, কোনো লুকানো ফি ছাড়াই, এবং সার্বক্ষণিক সহায়তার মাধ্যমে সম্পূর্ণ '
                    'ভ্রমণ পরিকল্পনার যাত্রাকে সহজ করে তুলছি।',
              ),
              style: const TextStyle(fontSize: 15, color: AppColors.textSecondary, height: 1.5),
            ),
            const SizedBox(height: AppSizes.xl),
            const AppFooter(),
          ],
        ),
      ),
    );
  }
}