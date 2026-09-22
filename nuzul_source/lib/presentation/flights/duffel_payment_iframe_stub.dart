import 'package:flutter/material.dart';

/// نسخة بديلة (Stub) تُستخدم فقط على المنصات غير الويب (أندرويد/iOS/
/// Windows) عشان الملف الرئيسي يقدر يستورد الملف الخاص بالويب بأمان
/// من غير ما يكسر البناء (compile) على باقي المنصات. الكود هنا
/// عمليًا مش بيتنفذ أبدًا لأن الصفحة الرئيسية بتستخدم WebViewWidget
/// مباشرة لما kIsWeb == false.
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
  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('صفحة الدفع عبر iframe متاحة فقط على نسخة الويب'),
    );
  }
}