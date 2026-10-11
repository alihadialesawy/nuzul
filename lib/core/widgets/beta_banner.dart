// lib/core/widgets/beta_banner.dart
//
// شريط "مرحلة تجريبية" يظهر أعلى كل صفحات الموقع (Web فقط).
// - الغرض: إبقاء flynoom.com حيًا وكاملًا (مهم لتحقق Apple/D&B)،
//   مع توضيح أن الحجوزات الحقيقية غير متاحة بعد.
// - النص مترجم داخليًا للغات التسع حسب لغة الواجهة الحالية، فلا يحتاج
//   مفاتيح .arb جديدة.
// - يُركَّب مرة واحدة في builder الخاص بـ MaterialApp، فيظهر في كل الصفحات.
// - عند الانتقال للحجز الحقيقي: احذف سطر BetaBanner من builder فقط.

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class BetaBanner extends StatelessWidget {
  const BetaBanner({super.key});

  static const Map<String, String> _texts = {
    'ar': 'Flynoom في مرحلة تجريبية، والحجوزات ستُتاح قريبًا.',
    'en': 'Flynoom is in beta. Bookings will open soon.',
    'es': 'Flynoom está en fase beta. Las reservas estarán disponibles pronto.',
    'fr': 'Flynoom est en version bêta. Les réservations ouvriront bientôt.',
    'tr': 'Flynoom beta aşamasındadır. Rezervasyonlar yakında açılacak.',
    'id': 'Flynoom sedang dalam tahap beta. Pemesanan akan segera dibuka.',
    'hi': 'Flynoom बीटा चरण में है। बुकिंग जल्द ही शुरू होगी।',
    'ur': 'Flynoom بیٹا مرحلے میں ہے۔ بکنگ جلد شروع ہوگی۔',
    'bn': 'Flynoom বিটা পর্যায়ে আছে। বুকিং শীঘ্রই চালু হবে।',
  };

  @override
  Widget build(BuildContext context) {
    // الشريط للموقع فقط، لا يظهر في تطبيقات Android/iOS.
    if (!kIsWeb) return const SizedBox.shrink();

    final lang = Localizations.maybeLocaleOf(context)?.languageCode ?? 'en';
    final text = _texts[lang] ?? _texts['en']!;

    return Material(
      color: const Color(0xFFF7931E), // برتقالي الهوية
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.info_outline, size: 16, color: Colors.white),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  text,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}