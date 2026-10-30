import 'dart:math';
import 'dart:ui' show PlatformDispatcher;

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// يسجّل فتح الموقع/التطبيق (مرة لكل جلسة) وتسجيل الدخول، لشاشة التحليلات.
///
/// يرسل فقط: معرّف زائر عشوائي (لا يكشف هوية)، والمنصة (web/android/ios)،
/// ولغة الجهاز. الموقع التقريبي (دولة/ولاية/مدينة) تحدده دالة track-visit
/// من عنوان IP على السيرفر، ولا يُخزَّن عنوان IP نفسه.
///
/// لا يعمل في وضع التطوير (flutter run) حتى لا تختلط تجاربك بزيارات الناس.
class VisitTracker {
  VisitTracker._();

  static bool _started = false;
  static DateTime? _lastLogin;
  static const _key = 'fly_visitor_id';

  static void start() {
    if (_started || kDebugMode) return;
    _started = true;
    _send('visit');
    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      if (data.event != AuthChangeEvent.signedIn) return;
      final now = DateTime.now();
      // signedIn قد يتكرر في نفس الجلسة؛ نكتفي بمرة كل 30 دقيقة.
      if (_lastLogin != null && now.difference(_lastLogin!) < const Duration(minutes: 30)) return;
      _lastLogin = now;
      _send('login');
    });
  }

  static String get _platform {
    if (kIsWeb) return 'web';
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'android';
      case TargetPlatform.iOS:
        return 'ios';
      default:
        return 'other';
    }
  }

  static Future<String> _visitorId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(_key);
      if (saved != null && saved.length >= 8) return saved;
      final r = Random.secure();
      final id = List.generate(16, (_) => r.nextInt(256).toRadixString(16).padLeft(2, '0')).join();
      await prefs.setString(_key, id);
      return id;
    } catch (_) {
      // التخزين غير متاح (وضع خاص في المتصفح مثلًا): معرّف لهذه الجلسة فقط.
      final r = Random.secure();
      return List.generate(16, (_) => r.nextInt(256).toRadixString(16).padLeft(2, '0')).join();
    }
  }

  static Future<void> _send(String event) async {
    try {
      await Supabase.instance.client.functions.invoke('track-visit', body: {
        'visitorId': await _visitorId(),
        'event': event,
        'platform': _platform,
        'lang': PlatformDispatcher.instance.locale.languageCode,
      });
    } catch (_) {
      // التحليلات لا تُوقف التطبيق أبدًا.
    }
  }
}