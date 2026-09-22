import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// المفتاح اللي بيتخزن بيه اختيار المستخدم اليدوي للغة في
/// shared_preferences، عشان يفضل ثابت بين مرات فتح التطبيق ومايترجعش
/// للغة الجهاز تلقائيًا لو المستخدم غيّرها بنفسه قبل كده.
const String _localePrefsKey = 'user_selected_locale';

/// يدير اللغة الحالية للتطبيق (عربي/إنجليزي/إسباني/تركي/إندونيسي/هندي/أوردو/فرنسي/بنغالي) ويسمح باختيار أي منها.
///
/// منطق اختيار اللغة الابتدائية عند أول فتح للتطبيق:
/// 1. لو المستخدم سبق واختار لغة يدويًا (مخزّنة بـ shared_preferences)،
///    نستخدمها هي — الاختيار اليدوي دايمًا له الأولوية.
/// 2. غير كده، نقرا لغة نظام الجهاز (device locale). لو مدعومة عندنا،
///    نبدأ بيها تلقائيًا.
/// 3. لو لغة الجهاز مش مدعومة، نرجع للإنجليزي كافتراضي.
class LocaleNotifier extends StateNotifier<Locale> {
  LocaleNotifier() : super(_resolveInitialLocale()) {
    _loadSavedLocale();
  }

  /// اللغات المدعومة حاليًا في التطبيق
  static const supportedLocales = [
    Locale('ar'),
    Locale('en'),
    Locale('es'),
    Locale('tr'),
    Locale('id'),
    Locale('hi'),
    Locale('ur'),
    Locale('fr'),
    Locale('bn'),
  ];

  /// يحدد اللغة الابتدائية (قبل ما نقدر نقرا shared_preferences بشكل
  /// غير متزامن) من لغة نظام الجهاز، كافتراضي مؤقت سريع. الاختيار
  /// المحفوظ الفعلي (لو موجود) بيتحمّل بعد كده في _loadSavedLocale
  /// وبيحل محل ده لو مختلف.
  static Locale _resolveInitialLocale() {
    final deviceLocale = ui.PlatformDispatcher.instance.locale;
    final match = supportedLocales.firstWhere(
          (l) => l.languageCode == deviceLocale.languageCode,
      orElse: () => const Locale('en'),
    );
    return match;
  }

  /// يحمّل اختيار المستخدم اليدوي المحفوظ (لو موجود) ويطبّقه. بيتنادى
  /// مرة واحدة بس عند إنشاء الـ notifier.
  Future<void> _loadSavedLocale() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedCode = prefs.getString(_localePrefsKey);
      if (savedCode == null) return;

      final saved = supportedLocales.firstWhere(
            (l) => l.languageCode == savedCode,
        orElse: () => state,
      );
      if (saved.languageCode != state.languageCode) {
        state = saved;
      }
    } catch (_) {
      // لو فشلت القراءة لأي سبب، نكمل باللغة اللي اتحددت من الجهاز —
      // مفيش داعي نوقف التطبيق أو نظهر خطأ عشان تفضيل لغة بسيط.
    }
  }

  /// يحدد اللغة مباشرة (يُستخدم مع قائمة اختيار اللغة في شريط التطبيق)
  /// وبيحفظها كاختيار يدوي دائم — مش هيترجع للغة الجهاز تلقائيًا بعد
  /// كده حتى لو المستخدم قفل وفتح التطبيق تاني.
  void setLocale(Locale locale) {
    state = locale;
    _saveLocale(locale);
  }

  /// يدور بين اللغات بالترتيب، لو حابب تستخدم زر toggle بسيط بدل قائمة
  void cycle() {
    final currentIndex =
    supportedLocales.indexWhere((l) => l.languageCode == state.languageCode);
    final nextIndex = (currentIndex + 1) % supportedLocales.length;
    setLocale(supportedLocales[nextIndex]);
  }

  Future<void> _saveLocale(Locale locale) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_localePrefsKey, locale.languageCode);
    } catch (_) {
      // فشل الحفظ (نادر) مش لازم يوقف تغيير اللغة نفسها في الجلسة
      // الحالية — بس مش هيفضل محفوظ للمرة الجاية.
    }
  }
}

final localeProvider = StateNotifierProvider<LocaleNotifier, Locale>((ref) {
  return LocaleNotifier();
});