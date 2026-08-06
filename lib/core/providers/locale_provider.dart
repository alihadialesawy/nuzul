import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// يدير اللغة الحالية للتطبيق (عربي/إنجليزي/إسباني) ويسمح باختيار أي منها
class LocaleNotifier extends StateNotifier<Locale> {
  LocaleNotifier() : super(const Locale('en'));

  /// اللغات المدعومة حاليًا في التطبيق
  static const supportedLocales = [
    Locale('ar'),
    Locale('en'),
    Locale('es'),
  ];

  /// يحدد اللغة مباشرة (يُستخدم مع قائمة اختيار اللغة في شريط التطبيق)
  void setLocale(Locale locale) {
    state = locale;
  }

  /// يدور بين اللغات الثلاث بالترتيب، لو حابب تستخدم زر toggle بسيط بدل قائمة
  void cycle() {
    final currentIndex =
    supportedLocales.indexWhere((l) => l.languageCode == state.languageCode);
    final nextIndex = (currentIndex + 1) % supportedLocales.length;
    state = supportedLocales[nextIndex];
  }
}

final localeProvider = StateNotifierProvider<LocaleNotifier, Locale>((ref) {
  return LocaleNotifier();
});