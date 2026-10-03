import 'dart:async';

import 'package:flutter/material.dart';

/// ويدجت صغير بيتحرك في المساحة الضيقة أسفل شريط التنقل الجانبي --
/// أيقونة بتعمل نبض هادئ (تكبير/تصغير) مع نص قصير تحتها بيتغيّر كل 3
/// ثواني (تلاشي/ظهور). الضغط عليه (لو onTap مبعوت) بيوديك لمكان معيّن
/// (زي صفحة العروض).
///
/// لو [messages] مش مبعوتة، النصوص الافتراضية (عروض / خصم 30% / جديد)
/// بتتعرض بلغة الواجهة الحالية بدل ما تكون عربي ثابت.
class SidebarPromoFlash extends StatefulWidget {
  final List<String>? messages;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const SidebarPromoFlash({
    super.key,
    this.messages,
    this.icon = Icons.local_offer,
    this.color = const Color(0xFFFF6B35),
    this.onTap,
  });

  /// عدد الرسائل الافتراضية (نفس الطول في كل اللغات).
  static const int _defaultMessageCount = 3;

  static List<String> _defaultMessages(String languageCode) {
    return switch (languageCode) {
      'ar' => const ['عروض', 'خصم 30%', 'جديد'],
      'es' => const ['Ofertas', '30% DTO', 'Nuevo'],
      'tr' => const ['Fırsatlar', '%30 İndirim', 'Yeni'],
      'id' => const ['Promo', 'Diskon 30%', 'Baru'],
      'hi' => const ['ऑफ़र', '30% छूट', 'नया'],
      'ur' => const ['آفرز', '30% رعایت', 'نیا'],
      'fr' => const ['Offres', '-30 %', 'Nouveau'],
      'bn' => const ['অফার', '৩০% ছাড়', 'নতুন'],
      _ => const ['Deals', '30% OFF', 'New'],
    };
  }

  @override
  State<SidebarPromoFlash> createState() => _SidebarPromoFlashState();
}

class _SidebarPromoFlashState extends State<SidebarPromoFlash>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  Timer? _textTimer;
  int _messageIndex = 0;

  int get _messageCount =>
      widget.messages?.length ?? SidebarPromoFlash._defaultMessageCount;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);

    if (_messageCount > 1) {
      _textTimer = Timer.periodic(const Duration(seconds: 3), (_) {
        if (!mounted) return;
        setState(() => _messageIndex = (_messageIndex + 1) % _messageCount);
      });
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _textTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final languageCode = Localizations.localeOf(context).languageCode;
    final messages =
        widget.messages ?? SidebarPromoFlash._defaultMessages(languageCode);
    final text =
    messages.isEmpty ? '' : messages[_messageIndex % messages.length];

    return InkWell(
      onTap: widget.onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ScaleTransition(
              scale: Tween<double>(begin: 0.85, end: 1.05).animate(
                CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
              ),
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: widget.color.withOpacity(0.15),
                ),
                child: Icon(widget.icon, color: widget.color, size: 18),
              ),
            ),
            const SizedBox(height: 6),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 400),
              child: Text(
                text,
                key: ValueKey(_messageIndex),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: widget.color,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}