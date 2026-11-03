// نسخة الويب: تضيف/تحذف وسم <style> يجعل طبقة الـ Semantics لا تعترض النقر.
// تستخدم dart:js_interop (جزء من Dart نفسه) فلا تحتاج أي حزمة إضافية.
// ignore_for_file: invalid_runtime_check_with_js_interop_types

import 'dart:js_interop';
import 'dart:js_interop_unsafe';

const String _styleId = 'flynoom-semantics-pointer-fix';
const String _css =
    'flt-semantics-host, flt-semantics-host * { pointer-events: none !important; }';

void setSemanticsPointerPassthrough(bool on) {
  try {
    final document = globalContext['document'] as JSObject;
    final existing = document.callMethod<JSAny?>('getElementById'.toJS, _styleId.toJS);

    if (on) {
      if (existing != null) return;
      final style = document.callMethod<JSObject>('createElement'.toJS, 'style'.toJS);
      style['id'] = _styleId.toJS;
      style['textContent'] = _css.toJS;
      final head = document['head'] as JSObject;
      head.callMethod<JSAny?>('appendChild'.toJS, style);
    } else {
      if (existing == null) return;
      (existing as JSObject).callMethod<JSAny?>('remove'.toJS);
    }
  } catch (_) {
    // لا نوقف الدفع أبدًا بسبب هذا الإصلاح.
  }
}