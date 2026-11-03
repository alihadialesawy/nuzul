import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/web/semantics_pointer_fix.dart';
import 'services/supabase_service.dart';
import 'services/stripe_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // إمكانية الوصول (ADA / WCAG): Flutter Web يرسم الصفحة على canvas، وقارئات
  // الشاشة (NVDA / JAWS / VoiceOver) لا ترى شيئًا إلا إذا فُعّلت شجرة
  // الـ Semantics. افتراضيًا لا تعمل إلا بعد ضغط زر مخفي "Enable accessibility"،
  // فنفعّلها دائمًا على الويب. على Android/iOS تعمل تلقائيًا مع TalkBack/VoiceOver.
  //
  // ⚠️ الـ Semantics تسحب التركيز من خانة بطاقة Stripe (iframe)، فصفحة الحجز
  // توقفها مؤقتًا أثناء نافذة الدفع فقط (lib/core/web/semantics_pointer_fix.dart).
  // لا تحذف هذا السطر لحل مشكلة الدفع.
  SemanticsPointerFix.startOnWeb();

  try {
    await SupabaseService.initialize();

    if (kIsWeb ||
        defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS) {
      try {
        await StripeService.initialize();
      } catch (e) {
        debugPrint('Stripe initialization failed: $e');
      }
    }

    runApp(
      const ProviderScope(
        child: NuzulApp(),
      ),
    );
  } catch (e, stackTrace) {
    debugPrint('FATAL STARTUP ERROR: $e');
    debugPrint('STACK TRACE: $stackTrace');
    runApp(_StartupErrorApp(error: e, stackTrace: stackTrace));
  }
}

/// شاشة تظهر إذا فشل تشغيل التطبيق (مثلًا تعذّر الاتصال بـ Supabase).
/// في وضع التطوير تعرض تفاصيل الخطأ للتشخيص؛ أما للعملاء (release) فتعرض
/// رسالة مهذبة فقط، لأن تفاصيل الخطأ وstack trace قد تكشف معلومات داخلية.
class _StartupErrorApp extends StatelessWidget {
  final Object error;
  final StackTrace stackTrace;
  const _StartupErrorApp({required this.error, required this.stackTrace});

  @override
  Widget build(BuildContext context) {
    if (kDebugMode) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          backgroundColor: Colors.red[900],
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'STARTUP ERROR',
                    style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  SelectableText(
                    error.toString(),
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                  ),
                  const SizedBox(height: 16),
                  SelectableText(
                    stackTrace.toString(),
                    style: const TextStyle(color: Colors.white70, fontSize: 10),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return MaterialApp(
      title: 'Flynoom',
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.cloud_off_outlined, size: 56, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text(
                    'Flynoom is temporarily unavailable',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Please refresh the page or try again in a few minutes.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, color: Colors.black54),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Flynoom غير متاح مؤقتًا. يُرجى تحديث الصفحة أو المحاولة بعد دقائق.',
                    textAlign: TextAlign.center,
                    textDirection: TextDirection.rtl,
                    style: TextStyle(fontSize: 14, color: Colors.black54),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'support@flynoom.com',
                    style: TextStyle(fontSize: 13, color: Colors.black45),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}