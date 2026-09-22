// الملف ده بيتفعّل بس لما البناء يكون لمنصة الويب (عن طريق الـ
// conditional import في duffel_payment_webview_page.dart). dart:html
// و dart:js_util متاحين هنا وبس، عشان كده منفصلين في ملف لوحده.
//
// ملحوظة معمارية مهمة: على الموبايل (أندرويد/iOS)، addJavaScriptChannel
// بيتسجّل قبل ما الصفحة تتحمّل أصلاً، فـ bundle.js بيلاقي
// window.FlutterChannel موجود من أول لحظة ينفّذ فيها. على الويب، مفيش
// طريقة نسجّل بيها property على contentWindow قبل التنقل (navigation)
// لأن كل تنقل same-origin بيولّد Window/global object جديد تمامًا
// وبيمسح أي حاجة اتسجلت قبله. الحل: نجيب نص duffel_payment.html بنفسنا
// (fetch) ونحقن سكريبت الـ channels قبل سطر تحميل bundle.js نصيًا، وبعد
// كده نحمّل النسخة المعدّلة في الذاكرة عن طريق iframe.srcdoc -- كده
// ترتيب التنفيذ يبقى مطابق للموبايل بالظبط. الملف الأصلي على القرص
// (assets/payment/duffel_payment.html) نفسه مش بيتلمس خالص.

import 'dart:async';
import 'dart:convert';
import 'dart:html' as html;
import 'dart:js_util' as js_util;
import 'dart:ui_web' as ui_web;

import 'package:flutter/material.dart';

class DuffelPaymentIframeView extends StatefulWidget {
  final String clientKey;
  final String offerId;
  final String offerCurrency;
  final double offerAmount;
  final void Function(String rawMessage) onMessage;

  const DuffelPaymentIframeView({
    super.key,
    required this.clientKey,
    required this.offerId,
    required this.offerCurrency,
    required this.offerAmount,
    required this.onMessage,
  });

  @override
  State<DuffelPaymentIframeView> createState() => _DuffelPaymentIframeViewState();
}

class _DuffelPaymentIframeViewState extends State<DuffelPaymentIframeView> {
  // المسار الحقيقي (لو مختلف عندك بعد تشخيص Network tab غيّره هنا فقط).
  static const String _htmlAssetPath = 'assets/assets/payment/duffel_payment.html';
  static const String _htmlAssetDir = 'assets/assets/payment/';

  // معرّف فريد لكل مرة تُفتح فيها صفحة الدفع، عشان تسجيل view factory
  // ميتعارضش لو المستخدم فتح الصفحة تاني في نفس الجلسة.
  late final String _viewType;
  late final html.IFrameElement _iframe;
  Timer? _readyPollTimer;
  bool _initialized = false;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _viewType = 'duffel-payment-iframe-${DateTime.now().microsecondsSinceEpoch}';

    _iframe = html.IFrameElement()
      ..style.border = 'none'
      ..style.width = '100%'
      ..style.height = '100%';

    ui_web.platformViewRegistry.registerViewFactory(_viewType, (int viewId) => _iframe);

    _loadModifiedHtml();
  }

  Future<void> _loadModifiedHtml() async {
    try {
      final rawHtml = await html.HttpRequest.getString(_htmlAssetPath);

      // سكريبت التمهيد: بيسجّل window.FlutterChannel و window.ConsoleLog
      // (بنفس شكل الاستدعاء اللي bundle.js بيتوقعه: .postMessage(msg))،
      // وبيعمل override لـ console.log/console.error/window.onerror --
      // بالظبط زي اللي بيحصل على الموبايل، لكن هنا قبل تحميل bundle.js
      // مش بعده. كمان بيشغّل تشخيص ذاتي تلقائي (بيبعت حالة
      // initDuffelPayment/readyState/title كل نص ثانية لمدة 10 ثواني)
      // عشان تظهر في نافذة تشغيل Flutter من غير أي تدخل يدوي في
      // DevTools.
      final bootstrapScript = '''
<base href="$_htmlAssetDir">
<script>
(function() {
  window.FlutterChannel = { postMessage: function(msg) { parent.postMessage({__duffelChannel: "FlutterChannel", msg: msg}, "*"); } };
  window.ConsoleLog = { postMessage: function(msg) { parent.postMessage({__duffelChannel: "ConsoleLog", msg: msg}, "*"); } };
  window.onerror = function(msg, url, line, col, error) {
    window.ConsoleLog.postMessage("JS ERROR: " + msg + " at " + url + ":" + line);
  };
  var _origLog = console.log;
  console.log = function() {
    window.ConsoleLog.postMessage("console.log: " + Array.from(arguments).join(" "));
    _origLog.apply(console, arguments);
  };
  var _origErr = console.error;
  console.error = function() {
    window.ConsoleLog.postMessage("console.error: " + Array.from(arguments).join(" "));
    _origErr.apply(console, arguments);
  };

  // تشخيص ذاتي تلقائي: بيبعت حالة الصفحة كل نص ثانية لمدة 10 ثواني.
  var _diagCount = 0;
  var _diagTimer = setInterval(function() {
    _diagCount++;
    window.ConsoleLog.postMessage(
      "DIAG #" + _diagCount +
      " | initDuffelPayment=" + (typeof window.initDuffelPayment) +
      " | readyState=" + document.readyState +
      " | title=" + document.title
    );
    if (_diagCount >= 20) {
      clearInterval(_diagTimer);
      window.ConsoleLog.postMessage("DIAG DONE (10s elapsed)");
    }
  }, 500);
})();
</script>
''';

      String modifiedHtml;
      final headIndex = rawHtml.toLowerCase().indexOf('<head>');
      if (headIndex != -1) {
        final insertAt = headIndex + '<head>'.length;
        modifiedHtml = rawHtml.substring(0, insertAt) + bootstrapScript + rawHtml.substring(insertAt);
      } else {
        // لا يوجد وسم <head> (نادر) -- نحطه في أول الملف كخيار احتياطي.
        modifiedHtml = bootstrapScript + rawHtml;
      }

      // بما إننا بنستخدم postMessage (كروس-فريم) بدل الوصول المباشر
      // لـ contentWindow، لازم نسمع على رسايل الـ window الرئيسي.
      html.window.onMessage.listen(_handleWindowMessage);

      _iframe.srcdoc = modifiedHtml;
      _iframe.onLoad.first.then((_) => _onIframeLoaded());
    } catch (e) {
      setState(() => _loadError = 'فشل تحميل صفحة الدفع: $e');
      widget.onMessage(jsonEncode({
        'type': 'error',
        'message': 'فشل تحميل صفحة الدفع (fetch): $e',
      }));
    }
  }

  void _handleWindowMessage(html.MessageEvent event) {
    final data = event.data;
    if (data is Map && data['__duffelChannel'] != null) {
      final channel = data['__duffelChannel'] as String;
      final msg = data['msg'] as String? ?? '';
      if (channel == 'FlutterChannel') {
        widget.onMessage(msg);
      } else if (channel == 'ConsoleLog') {
        debugPrint('DEBUG WebView(web) JS console: $msg');
      }
    }
  }

  void _onIframeLoaded() {
    final rawContentWindow = _iframe.contentWindow;
    if (rawContentWindow == null) {
      widget.onMessage(jsonEncode({
        'type': 'error',
        'message': 'تعذر الوصول لمحتوى صفحة الدفع (contentWindow فاضي)',
      }));
      return;
    }
    final contentWindow = rawContentWindow as html.Window;

    // bundle.js بيتنفذ async جوّا الـ iframe وممكن ياخد وقت أطول من
    // onLoad بتاع مستند الـ HTML نفسه (خصوصًا أول مرة/بدون كاش) --
    // فبدل ما ننادي initDuffelPayment فورًا، بنستنى (polling) لحد ما
    // الدالة تظهر فعليًا على contentWindow.
    const pollInterval = Duration(milliseconds: 100);
    const timeout = Duration(seconds: 10);
    final deadline = DateTime.now().add(timeout);

    _readyPollTimer = Timer.periodic(pollInterval, (timer) {
      final ready = js_util.hasProperty(contentWindow, 'initDuffelPayment');
      if (ready) {
        timer.cancel();
        _callInitDuffelPayment(contentWindow);
        return;
      }
      if (DateTime.now().isAfter(deadline)) {
        timer.cancel();
        widget.onMessage(jsonEncode({
          'type': 'error',
          'message': 'انتهت مهلة انتظار تحميل صفحة الدفع (initDuffelPayment لم يظهر خلال 10 ثواني)',
        }));
      }
    });
  }

  void _callInitDuffelPayment(html.WindowBase contentWindow) {
    final payload = jsonEncode({
      'clientKey': widget.clientKey,
      'offerId': widget.offerId,
      'offerCurrency': widget.offerCurrency,
      'offerAmount': widget.offerAmount.toStringAsFixed(2),
      'offerServices': <dynamic>[],
    });

    try {
      js_util.callMethod(contentWindow, 'initDuffelPayment', [payload]);
      if (mounted) setState(() => _initialized = true);
    } catch (e) {
      widget.onMessage(jsonEncode({
        'type': 'error',
        'message': 'فشل استدعاء initDuffelPayment: $e',
      }));
    }
  }

  @override
  void dispose() {
    _readyPollTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loadError != null) {
      return Center(child: Text(_loadError!, textAlign: TextAlign.center));
    }
    return Stack(
      children: [
        HtmlElementView(viewType: _viewType),
        if (!_initialized)
          const Positioned(
            top: 16,
            left: 0,
            right: 0,
            child: Center(child: CircularProgressIndicator()),
          ),
      ],
    );
  }
}