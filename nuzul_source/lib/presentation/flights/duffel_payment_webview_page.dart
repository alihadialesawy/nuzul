import 'dart:convert';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../core/widgets/app_banner.dart';
import 'duffel_payment_iframe_stub.dart'
if (dart.library.html) 'duffel_payment_iframe_web.dart';

/// نتيجة نجاح جمع بيانات البطاقة وجلسة 3D Secure، بترجع من الصفحة
/// لـ Flutter (عبر JavaScript Channel على الموبايل، أو محاكاة نفس
/// الواجهة عبر postMessage على الويب). لازم تُستخدم بعدها مباشرة في
/// نفس الـ createOrder (بيانات البطاقة المؤقتة (cardId) بتنتهي
/// صلاحيتها خلال 25 دقيقة عند Duffel).
class DuffelCardCollectionResult {
  final String? cardId;
  final String? threeDSecureSessionId;
  final String? errorMessage;

  const DuffelCardCollectionResult({
    this.cardId,
    this.threeDSecureSessionId,
    this.errorMessage,
  });

  bool get isSuccess =>
      errorMessage == null && cardId != null && threeDSecureSessionId != null;
}

/// صفحة تجمع بيانات بطاقة العميل + تأكيد 3D Secure عن طريق تحميل
/// فورم Duffel الرسمي (DuffelCardForm، عبر React micro-app مبني
/// مسبقًا) -- جوّه WebView على أندرويد/iOS، وجوّه iframe على الويب
/// (webview_flutter مالوش دعم لمنصة الويب) -- بدل ما بيانات البطاقة
/// الخام تمرّ على سيرفرنا أبدًا.
///
/// المتطلبات (لازم تتوفر قبل ما الصفحة دي تشتغل):
/// 1. assets/payment/duffel_payment.html + assets/payment/bundle.js
///    (bundle.js ناتج بناء مشروع duffel-payment-webview/ المنفصل).
/// 2. clientKey جاي من Edge Function جديدة
///    (duffel-create-component-client-key)، مش من payment intent.
class DuffelPaymentWebViewPage extends StatefulWidget {
  final String clientKey;
  final String offerId;
  final String offerCurrency;
  final double offerAmount;

  const DuffelPaymentWebViewPage({
    super.key,
    required this.clientKey,
    required this.offerId,
    required this.offerCurrency,
    required this.offerAmount,
  });

  @override
  State<DuffelPaymentWebViewPage> createState() => _DuffelPaymentWebViewPageState();
}

class _DuffelPaymentWebViewPageState extends State<DuffelPaymentWebViewPage> {
  WebViewController? _controller;
  bool _isPageReady = false;

  @override
  void initState() {
    super.initState();
    if (!kIsWeb) {
      _initNativeController();
    }
  }

  void _initNativeController() {
    final controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..addJavaScriptChannel(
        'FlutterChannel',
        onMessageReceived: (m) => _handleRawMessage(m.message),
      )
      ..addJavaScriptChannel(
        'ConsoleLog',
        onMessageReceived: (message) => debugPrint('DEBUG WebView JS console: ${message.message}'),
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (_) {
            // نلتقط أي أخطاء JavaScript حصلت جوّا الصفحة (زي فشل تحميل
            // سكريبت React أو خطأ داخل DuffelCardForm) ونبعتها لـ
            // Flutter Console عشان نقدر نشخّصها -- من غير كده مفيش
            // رؤية على أي حاجة بتحصل جوّا WebView.
            _controller!.runJavaScript('''
              window.onerror = function(msg, url, line, col, error) {
                if (window.ConsoleLog) {
                  window.ConsoleLog.postMessage("JS ERROR: " + msg + " at " + url + ":" + line);
                }
              };
              var _origLog = console.log;
              console.log = function() {
                if (window.ConsoleLog) {
                  window.ConsoleLog.postMessage("console.log: " + Array.from(arguments).join(" "));
                }
                _origLog.apply(console, arguments);
              };
              var _origErr = console.error;
              console.error = function() {
                if (window.ConsoleLog) {
                  window.ConsoleLog.postMessage("console.error: " + Array.from(arguments).join(" "));
                }
                _origErr.apply(console, arguments);
              };
            ''');

            final payload = jsonEncode({
              'clientKey': widget.clientKey,
              'offerId': widget.offerId,
              'offerCurrency': widget.offerCurrency,
              'offerAmount': widget.offerAmount.toStringAsFixed(2),
              'offerServices': <dynamic>[],
            });
            // ملحوظة: payload هنا Map متحوّل لـ JSON String، وبنبعته
            // تاني كـ JSON String Literal جوّا الأمر (jsonEncode
            // مزدوج) عشان initDuffelPayment يستقبله زي string واحد
            // ويعمله JSON.parse بنفسه.
            _controller!.runJavaScript('window.initDuffelPayment(${jsonEncode(payload)});');
          },
        ),
      )
      ..loadFlutterAsset('assets/payment/duffel_payment.html');

    setState(() => _controller = controller);
  }

  void _handleRawMessage(String raw) {
    try {
      final data = jsonDecode(raw) as Map<String, dynamic>;
      final type = data['type'] as String?;

      switch (type) {
        case 'ready':
          if (mounted) setState(() => _isPageReady = true);
          break;
        case 'success':
          Navigator.of(context).pop(
            DuffelCardCollectionResult(
              cardId: data['cardId'] as String?,
              threeDSecureSessionId: data['threeDSecureSessionId'] as String?,
            ),
          );
          break;
        case 'error':
          Navigator.of(context).pop(
            DuffelCardCollectionResult(
              errorMessage: data['message'] as String? ?? 'حدث خطأ أثناء معالجة البطاقة',
            ),
          );
          break;
      }
    } catch (e) {
      debugPrint('DEBUG DuffelPaymentWebView message parse error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AppBanner(bannerHeight: 80),
      body: Column(
        children: [
          const Padding(
            padding: EdgeInsets.all(AppSizes.md),
            child: Text(
              'أدخل بيانات البطاقة لإتمام الدفع',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              textAlign: TextAlign.center,
            ),
          ),
          if (!_isPageReady)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: AppSizes.lg),
              child: Center(child: CircularProgressIndicator()),
            ),
          Expanded(
            child: kIsWeb
                ? DuffelPaymentIframeView(
              clientKey: widget.clientKey,
              offerId: widget.offerId,
              offerCurrency: widget.offerCurrency,
              offerAmount: widget.offerAmount,
              onMessage: _handleRawMessage,
            )
                : (_controller == null
                ? const Center(child: CircularProgressIndicator())
                : WebViewWidget(controller: _controller!)),
          ),
        ],
      ),
    );
  }
}