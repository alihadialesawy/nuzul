import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../providers/currency_provider.dart';

/// علم مبسّط (مرسوم بالكود) لكل عملة، عشان يظهر بشكل موحد على كل
/// المنصات (بما فيها Windows اللي مش بيعرض إيموجي الأعلام صح).
class CurrencyFlag extends StatelessWidget {
  final AppCurrency currency;
  final double width;
  final double height;

  const CurrencyFlag({
    super.key,
    required this.currency,
    this.width = 22,
    this.height = 15,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(2),
        // حد أبيض خفيف حوالين كل علم، عشان علم السعودية (الأخضر الغامق)
        // يفضل واضح ومتميّز حتى فوق خلفية خضرا (زي هيدر التطبيق).
        border: Border.all(color: Colors.white, width: 1),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(1),
        child: CustomPaint(
          size: Size(width, height),
          painter: _FlagPainter(currency),
        ),
      ),
    );
  }
}

class _FlagPainter extends CustomPainter {
  final AppCurrency currency;
  _FlagPainter(this.currency);

  @override
  void paint(Canvas canvas, Size size) {
    switch (currency) {
      case AppCurrency.sar:
        _paintSaudi(canvas, size);
        break;
      case AppCurrency.usd:
        _paintUs(canvas, size);
        break;
      case AppCurrency.eur:
        _paintEu(canvas, size);
        break;
      case AppCurrency.gbp:
        _paintUk(canvas, size);
        break;
      case AppCurrency.cad:
        _paintCanada(canvas, size);
        break;
      case AppCurrency.try_:
        _paintTurkey(canvas, size);
        break;
      case AppCurrency.aed:
        _paintUae(canvas, size);
        break;
      case AppCurrency.idr:
        _paintIndonesia(canvas, size);
        break;
      case AppCurrency.jpy:
        _paintJapan(canvas, size);
        break;
      case AppCurrency.mxn:
        _paintMexico(canvas, size);
        break;
      case AppCurrency.pkr:
        _paintPakistan(canvas, size);
        break;
      case AppCurrency.inr:
        _paintIndia(canvas, size);
        break;
      case AppCurrency.cop:
        _paintColombia(canvas, size);
        break;
    }
  }

  void _paintSaudi(Canvas canvas, Size size) {
    final bg = Paint()..color = const Color(0xFF006C35);
    canvas.drawRect(Offset.zero & size, bg);
    // خط أبيض بسيط يرمز للنص/السيف في العلم الأصلي
    final line = Paint()
      ..color = Colors.white
      ..strokeWidth = size.height * 0.08;
    canvas.drawLine(
      Offset(size.width * 0.15, size.height * 0.7),
      Offset(size.width * 0.85, size.height * 0.7),
      line,
    );
  }

  void _paintUs(Canvas canvas, Size size) {
    final stripeHeight = size.height / 7;
    for (int i = 0; i < 7; i++) {
      final paint = Paint()..color = i.isEven ? const Color(0xFFB22234) : Colors.white;
      canvas.drawRect(
        Rect.fromLTWH(0, stripeHeight * i, size.width, stripeHeight),
        paint,
      );
    }
    final canton = Paint()..color = const Color(0xFF3C3B6E);
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width * 0.45, stripeHeight * 4),
      canton,
    );
  }

  void _paintEu(Canvas canvas, Size size) {
    final bg = Paint()..color = const Color(0xFF003399);
    canvas.drawRect(Offset.zero & size, bg);

    final star = Paint()..color = const Color(0xFFFFCC00);
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.height * 0.32;
    const starCount = 10;
    for (int i = 0; i < starCount; i++) {
      final angle = (2 * math.pi * i) / starCount;
      final dx = center.dx + radius * 0.85 * math.cos(angle);
      final dy = center.dy + radius * 0.85 * math.sin(angle);
      canvas.drawCircle(Offset(dx, dy), size.height * 0.05, star);
    }
  }

  void _paintUk(Canvas canvas, Size size) {
    final bg = Paint()..color = const Color(0xFF012169);
    canvas.drawRect(Offset.zero & size, bg);

    final whiteThick = Paint()
      ..color = Colors.white
      ..strokeWidth = size.height * 0.28;
    final redThin = Paint()
      ..color = const Color(0xFFC8102E)
      ..strokeWidth = size.height * 0.14;

    // الخطوط القطرية (أبيض ثم أحمر فوقه)
    canvas.drawLine(Offset.zero, Offset(size.width, size.height), whiteThick);
    canvas.drawLine(Offset(size.width, 0), Offset(0, size.height), whiteThick);
    canvas.drawLine(Offset.zero, Offset(size.width, size.height), redThin);
    canvas.drawLine(Offset(size.width, 0), Offset(0, size.height), redThin);

    // الصليب الأبيض ثم الأحمر فوقه
    final whiteCross = Paint()
      ..color = Colors.white
      ..strokeWidth = size.height * 0.36;
    final redCross = Paint()
      ..color = const Color(0xFFC8102E)
      ..strokeWidth = size.height * 0.18;

    canvas.drawLine(
      Offset(size.width / 2, 0),
      Offset(size.width / 2, size.height),
      whiteCross,
    );
    canvas.drawLine(
      Offset(0, size.height / 2),
      Offset(size.width, size.height / 2),
      whiteCross,
    );
    canvas.drawLine(
      Offset(size.width / 2, 0),
      Offset(size.width / 2, size.height),
      redCross,
    );
    canvas.drawLine(
      Offset(0, size.height / 2),
      Offset(size.width, size.height / 2),
      redCross,
    );
  }

  void _paintCanada(Canvas canvas, Size size) {
    final white = Paint()..color = Colors.white;
    final red = Paint()..color = const Color(0xFFFF0000);
    canvas.drawRect(Offset.zero & size, white);
    final bandWidth = size.width * 0.28;
    canvas.drawRect(Rect.fromLTWH(0, 0, bandWidth, size.height), red);
    canvas.drawRect(
      Rect.fromLTWH(size.width - bandWidth, 0, bandWidth, size.height),
      red,
    );
    // ورقة قيقب مبسّطة (دائرة صغيرة حمراء في المنتصف)
    canvas.drawCircle(
      Offset(size.width / 2, size.height / 2),
      size.height * 0.22,
      red,
    );
  }

  void _paintTurkey(Canvas canvas, Size size) {
    final red = Paint()..color = const Color(0xFFE30A17);
    canvas.drawRect(Offset.zero & size, red);

    final white = Paint()..color = Colors.white;
    final center = Offset(size.width * 0.42, size.height / 2);
    final crescentRadius = size.height * 0.34;
    canvas.drawCircle(center, crescentRadius, white);
    canvas.drawCircle(
      Offset(center.dx + crescentRadius * 0.4, center.dy),
      crescentRadius * 0.82,
      red,
    );
    canvas.drawCircle(
      Offset(size.width * 0.62, size.height / 2),
      size.height * 0.08,
      white,
    );
  }

  void _paintUae(Canvas canvas, Size size) {
    final stripeHeight = size.height / 3;
    final green = Paint()..color = const Color(0xFF00732F);
    final white = Paint()..color = Colors.white;
    final black = Paint()..color = Colors.black;
    final red = Paint()..color = const Color(0xFFFF0000);

    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, stripeHeight), green);
    canvas.drawRect(
      Rect.fromLTWH(0, stripeHeight, size.width, stripeHeight),
      white,
    );
    canvas.drawRect(
      Rect.fromLTWH(0, stripeHeight * 2, size.width, stripeHeight),
      black,
    );

    final hoistWidth = size.width * 0.25;
    canvas.drawRect(Rect.fromLTWH(0, 0, hoistWidth, size.height), red);
  }

  void _paintIndonesia(Canvas canvas, Size size) {
    final red = Paint()..color = const Color(0xFFCE1126);
    final white = Paint()..color = Colors.white;
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height / 2),
      red,
    );
    canvas.drawRect(
      Rect.fromLTWH(0, size.height / 2, size.width, size.height / 2),
      white,
    );
  }

  void _paintJapan(Canvas canvas, Size size) {
    final white = Paint()..color = Colors.white;
    canvas.drawRect(Offset.zero & size, white);
    final red = Paint()..color = const Color(0xFFBC002D);
    canvas.drawCircle(
      Offset(size.width / 2, size.height / 2),
      size.height * 0.32,
      red,
    );
  }

  void _paintMexico(Canvas canvas, Size size) {
    final bandWidth = size.width / 3;
    final green = Paint()..color = const Color(0xFF006847);
    final white = Paint()..color = Colors.white;
    final red = Paint()..color = const Color(0xFFCE1126);

    canvas.drawRect(Rect.fromLTWH(0, 0, bandWidth, size.height), green);
    canvas.drawRect(
      Rect.fromLTWH(bandWidth, 0, bandWidth, size.height),
      white,
    );
    canvas.drawRect(
      Rect.fromLTWH(bandWidth * 2, 0, bandWidth, size.height),
      red,
    );
    // شعار مبسّط في المنتصف (دائرة بنية صغيرة بدل النسر والصبار)
    final emblem = Paint()..color = const Color(0xFF8B5A2B);
    canvas.drawCircle(
      Offset(size.width / 2, size.height / 2),
      size.height * 0.14,
      emblem,
    );
  }

  void _paintPakistan(Canvas canvas, Size size) {
    final green = Paint()..color = const Color(0xFF01411C);
    final white = Paint()..color = Colors.white;
    canvas.drawRect(Offset.zero & size, green);

    final hoistWidth = size.width * 0.22;
    canvas.drawRect(Rect.fromLTWH(0, 0, hoistWidth, size.height), white);

    final center = Offset(size.width * 0.62, size.height / 2);
    final crescentRadius = size.height * 0.3;
    canvas.drawCircle(center, crescentRadius, white);
    canvas.drawCircle(
      Offset(center.dx + crescentRadius * 0.4, center.dy),
      crescentRadius * 0.8,
      green,
    );
    canvas.drawCircle(
      Offset(size.width * 0.82, size.height * 0.35),
      size.height * 0.07,
      white,
    );
  }

  void _paintIndia(Canvas canvas, Size size) {
    final stripeHeight = size.height / 3;
    final saffron = Paint()..color = const Color(0xFFFF9933);
    final white = Paint()..color = Colors.white;
    final green = Paint()..color = const Color(0xFF138808);
    final navy = Paint()..color = const Color(0xFF000080);

    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, stripeHeight), saffron);
    canvas.drawRect(
      Rect.fromLTWH(0, stripeHeight, size.width, stripeHeight),
      white,
    );
    canvas.drawRect(
      Rect.fromLTWH(0, stripeHeight * 2, size.width, stripeHeight),
      green,
    );
    // عجلة أشوكا مبسّطة (دائرة كحلية صغيرة في المنتصف)
    canvas.drawCircle(
      Offset(size.width / 2, size.height / 2),
      size.height * 0.11,
      navy,
    );
  }

  void _paintColombia(Canvas canvas, Size size) {
    final yellow = Paint()..color = const Color(0xFFFCD116);
    final blue = Paint()..color = const Color(0xFF003893);
    final red = Paint()..color = const Color(0xFFCE1126);

    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height / 2),
      yellow,
    );
    canvas.drawRect(
      Rect.fromLTWH(0, size.height / 2, size.width, size.height / 4),
      blue,
    );
    canvas.drawRect(
      Rect.fromLTWH(0, size.height * 0.75, size.width, size.height / 4),
      red,
    );
  }

  @override
  bool shouldRepaint(covariant _FlagPainter oldDelegate) =>
      oldDelegate.currency != currency;
}
