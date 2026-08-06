import 'package:flutter/material.dart';

/// ألوان التطبيق الموحدة — Safr-AI
class AppColors {
  AppColors._();

  // اللون الأساسي — أزرق كحلي غامق بدل الأخضر، عشان يتناسق مع ألوان
  // صورة البانر (سماء/بحر زرقاء) ونفس هوية التصميم في Figma
  static const Color primary = Color(0xFF14355E);
  static const Color primaryDark = Color(0xFF0B2340);
  static const Color primaryLight = Color(0xFF3D6FB4);

  // تدرّج الهيدر/شريط التبويبات — لونين حقيقيين بدل الاعتماد على شفافية
  // (الشفافية كانت بتدّي إحساس "باهت"؛ اللونين دول مشبّعين بالكامل)
  static const Color gradientStart = Color(0xFF1E4A80);
  static const Color gradientEnd = Color(0xFF0B2340);

  // ألوان شريط التبويبات حسب التبويب المفعّل
  static const Color staysLight = Color(0xFF5FD98A); // أخضر فاتح - الإقامة
  static const Color staysLightEnd = Color(0xFF2FAE63);

  static const Color skyBlue = Color(0xFF4FA8E8); // أزرق سماء - الطيران
  static const Color cloudBlue = Color(0xFFBFE0F5); // أزرق مبيّض يشبه الغيوم

  static const Color slateGrey = Color(0xFF6B7684); // رصاصي - تأجير السيارات
  static const Color slateGreyDark = Color(0xFF4A525C);

  static const Color secondary = Color(0xFFE8B923); // ذهبي أدفى - لمسة فخامة الحجوزات

  // ألوان مساعدة (accents) موحّدة — نفس الدرجات المستخدمة في كروت
  // المميزات (Trust/Feature cards) عشان تبقى مصدر واحد بدل تكرارها
  static const Color accentPurple = Color(0xFF6C5CE7);
  static const Color accentOrange = Color(0xFFE67E22);
  static const Color accentBlue = Color(0xFF0984E3);
  static const Color accentTeal = Color(0xFF00B894);
  static const Color accentAmber = Color(0xFFF39C12);
  static const Color accentCoral = Color(0xFFE17055);

  static const Color background = Color(0xFFF6F8F7);
  static const Color surface = Colors.white;

  // نصوص بتباين أعلى شوية عشان إحساس أوضح وأحدّ
  static const Color textPrimary = Color(0xFF111827);
  static const Color textSecondary = Color(0xFF5A6472);
  static const Color textHint = Color(0xFF9CA3AF);

  static const Color error = Color(0xFFD32F2F);
  static const Color success = Color(0xFF2E7D32);
  static const Color warning = Color(0xFFED6C02);

  static const Color divider = Color(0xFFE4E7EB);
  static const Color shimmerBase = Color(0xFFE0E0E0);
  static const Color shimmerHighlight = Color(0xFFF5F5F5);
}