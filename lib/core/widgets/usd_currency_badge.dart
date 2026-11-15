import 'package:flutter/material.dart';

/// علامة ثابتة "علم أمريكا + USD" (غير قابلة للضغط) تحل محل زر اختيار العملة
/// ما دام kCurrencySelectorEnabled = false: Flynoom للمقيمين في الولايات المتحدة،
/// والأسعار والدفع بالدولار دائمًا. تطمئن الزائر من أول نظرة.
///
/// العلم مرسوم بالكود (CustomPaint) وليس إيموجي 🇺🇸، لأن Windows لا يعرض
/// إيموجي الأعلام ويُظهر بدلًا منها الحرفين "US" (في تطبيق Windows وفي
/// Chrome/Edge على Windows).
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
    final flagHeight = footerStyle ? 13.0 : 10.0;

    final content = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        UsFlag(height: flagHeight),
        const SizedBox(width: 5),
        Text(
          'USD',
          maxLines: 1,
          softWrap: false,
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

/// علم الولايات المتحدة مرسوم (13 خطًا + المربع الأزرق مع نقاط النجوم)،
/// يظهر بنفس الشكل على الويب وWindows وAndroid وiOS.
class UsFlag extends StatelessWidget {
  final double height;
  const UsFlag({super.key, this.height = 10});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(1.5),
      child: SizedBox(
        width: height * 1.9, // النسبة الرسمية 10:19
        height: height,
        child: const CustomPaint(painter: _UsFlagPainter()),
      ),
    );
  }
}

class _UsFlagPainter extends CustomPainter {
  const _UsFlagPainter();

  static const _red = Color(0xFFB22234);
  static const _blue = Color(0xFF3C3B6E);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final stripe = h / 13;

    // خلفية بيضاء + 7 خطوط حمراء.
    canvas.drawRect(Offset.zero & size, Paint()..color = Colors.white);
    final red = Paint()..color = _red;
    for (var i = 0; i < 13; i += 2) {
      canvas.drawRect(Rect.fromLTWH(0, i * stripe, w, stripe), red);
    }

    // المربع الأزرق: 7 خطوط ارتفاعًا و 2/5 العرض.
    final cantonW = w * 0.4;
    final cantonH = stripe * 7;
    canvas.drawRect(Rect.fromLTWH(0, 0, cantonW, cantonH), Paint()..color = _blue);

    // النجوم: نقاط بيضاء صغيرة (5 × 4) — تفاصيل النجمة لا تُرى بهذا الحجم.
    final star = Paint()..color = Colors.white;
    const cols = 5, rows = 4;
    final r = (cantonH / rows) * 0.18;
    for (var y = 0; y < rows; y++) {
      for (var x = 0; x < cols; x++) {
        final cx = cantonW * (x + 0.5) / cols;
        final cy = cantonH * (y + 0.5) / rows;
        canvas.drawCircle(Offset(cx, cy), r, star);
      }
    }

    // إطار رفيع حتى لا يذوب الأبيض في الخلفيات الفاتحة.
    canvas.drawRect(
      (Offset.zero & size).deflate(0.25),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.5
        ..color = Colors.black26,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}