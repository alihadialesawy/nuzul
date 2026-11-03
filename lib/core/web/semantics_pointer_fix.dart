/// إمكانية الوصول على الويب + تعايشها مع خانة بطاقة Stripe.
///
/// - startOnWeb(): يُستدعى مرة واحدة من main.dart، ويفعّل إمكانية الوصول
///   (Semantics) دائمًا على الويب، حتى تقرأ قارئات الشاشة الموقع.
/// - enable()/disable(): أثناء نافذة الدفع فقط، تجعل طبقة إمكانية الوصول
///   (`flt-semantics-host`) لا تعترض النقر فوق خانة Stripe (وسم <style> مؤقت).
///
/// ملاحظة: إيقاف الـ Semantics مؤقتًا لا يعمل على الويب (بعد تشغيلها تبقى
/// طبقتها). المشكلة الأساسية (سحب التركيز من الخانة) تُحل في
/// payment_service.dart بلف CardField بـ ExcludeSemantics + ExcludeFocus.
///
/// على Android/iOS لا تفعل شيئًا.
library;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/semantics.dart';

import 'semantics_pointer_fix_stub.dart'
if (dart.library.js_interop) 'semantics_pointer_fix_web.dart' as impl;

class SemanticsPointerFix {
  SemanticsPointerFix._();

  static SemanticsHandle? _handle;
  static int _depth = 0;

  /// يُستدعى مرة واحدة من main.dart.
  static void startOnWeb() {
    if (!kIsWeb) return;
    _handle ??= SemanticsBinding.instance.ensureSemantics();
  }

  /// قبل نافذة الدفع (يمكن استدعاؤه أكثر من مرة؛ يُعدّ المرات).
  static void enable() {
    if (!kIsWeb) return;
    _depth++;
    if (_depth == 1) impl.setSemanticsPointerPassthrough(true);
  }

  /// بعد إغلاق نافذة الدفع.
  static void disable() {
    if (!kIsWeb || _depth == 0) return;
    _depth--;
    if (_depth == 0) impl.setSemanticsPointerPassthrough(false);
  }
}