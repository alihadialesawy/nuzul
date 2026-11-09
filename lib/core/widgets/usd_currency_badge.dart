import 'package:flutter/material.dart';

/// علامة ثابتة "🇺🇸 USD" (غير قابلة للضغط) تحل محل زر اختيار العملة ما دام
/// kCurrencySelectorEnabled = false: Flynoom للمقيمين في الولايات المتحدة،
/// والأسعار والدفع بالدولار دائمًا. تطمئن الزائر من أول نظرة.
///
/// قارئ الشاشة يقرؤها "Prices in US dollars" (بلغة الزائر)، لا "button"،
/// لأنها لا تفعل شيئًا عند الضغط.
class UsdCurrencyBadge extends StatelessWidget {
  /// شكل الفوتر (خلفية فاتحة) بدل شكل الشريط العلوي (فوق صورة داكنة).
  final bool footerStyle;
  const UsdCurrencyBadge({super.key, this.footerStyle = false});

  static String _label(BuildContext context) {
    const m = {
      'ar': 'الأسعار بالدولار الأمريكي',
      'en': 'Prices in US dollars',
      'es': 'Precios en dólares estadounidenses',
      'tr': 'Fiyatlar ABD doları cinsindendir',
      'id': 'Harga dalam dolar AS',
      'hi': 'कीमतें अमेरिकी डॉलर में',
      'ur': 'قیمتیں امریکی ڈالر میں',
      'fr': 'Prix en dollars américains',
      'bn': 'দাম মার্কিন ডলারে',
    };
    return m[Localizations.localeOf(context).languageCode] ?? m['en']!;
  }

  @override
  Widget build(BuildContext context) {
    final label = _label(context);
    final textColor = footerStyle ? Colors.black87 : Colors.white;

    final content = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text('🇺🇸', style: TextStyle(fontSize: 14)),
        const SizedBox(width: 4),
        Text(
          'USD',
          style: TextStyle(
            color: textColor,
            fontSize: footerStyle ? 15 : 11,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );

    return Semantics(
      label: label,
      excludeSemantics: true,
      child: Tooltip(
        message: label,
        child: footerStyle
            ? Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.black12),
          ),
          child: content,
        )
            : Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: content,
        ),
      ),
    );
  }
}