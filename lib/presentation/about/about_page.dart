import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../core/widgets/app_banner.dart';
import '../../core/widgets/app_footer.dart';

/// يختار النص المناسب حسب اللغة الحالية (عربي/إنجليزي/إسباني).
String _t3(
    BuildContext context, {
      required String ar,
      required String en,
      required String es,
    }) {
  switch (Localizations.localeOf(context).languageCode) {
    case 'ar':
      return ar;
    case 'es':
      return es;
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
      label: _t3(context, ar: 'فندق شريك', en: 'Partner hotels', es: 'Hoteles asociados'),
      ),
      (
      value: '3',
      label: _t3(context, ar: 'لغات مدعومة', en: 'Languages supported', es: 'Idiomas admitidos'),
      ),
      (
      value: '24/7',
      label: _t3(context, ar: 'دعم متواصل', en: 'Ongoing support', es: 'Soporte continuo'),
      ),
    ];

    return Scaffold(
      appBar: const AppBanner(),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSizes.lg),
          children: [
            Text(
              _t3(context, ar: 'عن Safr-AI', en: 'About Safr-AI', es: 'Sobre Safr-AI'),
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppSizes.md),
            Text(
              _t3(
                context,
                ar: 'Safr-AI منصة سفر عربية بتساعدك تحجز فنادق ورحلات طيران وسيارات في مكان واحد، '
                    'بمساعدة مساعد ذكاء اصطناعي بيرشّحلك أفضل الخيارات ويتابع أسعار رحلاتك نيابة عنك.',
                en: 'Safr-AI is a travel platform that lets you book hotels, flights, and cars all in one '
                    'place, with an AI assistant that recommends the best options and tracks your flight prices for you.',
                es: 'Safr-AI es una plataforma de viajes que te permite reservar hoteles, vuelos y coches en '
                    'un solo lugar, con un asistente de IA que recomienda las mejores opciones y sigue los precios de tus vuelos.',
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
              _t3(context, ar: 'رسالتنا', en: 'Our mission', es: 'Nuestra misión'),
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppSizes.sm),
            Text(
              _t3(
                context,
                ar: 'بنسهّل رحلة التخطيط للسفر من أولها لآخرها للمسافر العربي، بأسعار شفافة وبدون رسوم '
                    'مخفية، ودعم متاح على مدار الساعة.',
                en: "We're simplifying the entire trip-planning journey with transparent pricing, no hidden "
                    'fees, and round-the-clock support.',
                es: 'Simplificamos todo el proceso de planificación de viajes con precios transparentes, sin '
                    'cargos ocultos y soporte las 24 horas.',
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