import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../utils/result.dart';
import '../utils/error_translator.dart';

/// يتعامل مع عملية الدفع الكاملة. على الموبايل يستخدم PaymentSheet الجاهزة
/// من Stripe، وعلى الويب يستخدم CardField + confirmPayment لأن PaymentSheet
/// غير مدعومة رسميًا على الويب حتى الآن.
class PaymentService {
  final SupabaseClient _client = Supabase.instance.client;

  Future<Result<bool>> pay({
    required double amount,
    String currency = 'sar',
    BuildContext? context,
  }) async {
    try {
      final response = await _client.functions.invoke(
        'create-payment-intent',
        body: {'amount': amount, 'currency': currency},
      );

      if (response.status != 200) {
        final error = (response.data is Map) ? response.data['error'] : null;
        return Failure(error?.toString() ?? 'تعذر بدء عملية الدفع');
      }

      final data = response.data is String
          ? jsonDecode(response.data)
          : response.data;
      final clientSecret = data['clientSecret'] as String?;

      if (clientSecret == null) {
        return const Failure('تعذر بدء عملية الدفع، حاول مرة أخرى');
      }

      // على الويب: PaymentSheet غير مدعومة، نستخدم نافذة CardField مخصصة
      if (kIsWeb) {
        if (context == null) {
          return const Failure('تعذر فتح نافذة الدفع');
        }
        return _payOnWeb(context, clientSecret);
      }

      // على الموبايل: نفس المسار المستخدم فعليًا (PaymentSheet)
      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: clientSecret,
          merchantDisplayName: 'نزل - Nuzul',
          style: ThemeMode.light,
        ),
      );

      await Stripe.instance.presentPaymentSheet();

      return const Success(true);
    } on StripeException catch (e) {
      final message = e.error.localizedMessage ?? 'تم إلغاء عملية الدفع';
      return Failure(message);
    } catch (e) {
      return Failure(ErrorTranslator.translate(e));
    }
  }

  Future<Result<bool>> _payOnWeb(BuildContext context, String clientSecret) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => _WebCardPaymentDialog(clientSecret: clientSecret),
    );

    if (result == true) {
      return const Success(true);
    }
    return const Failure('تم إلغاء عملية الدفع');
  }
}

class _WebCardPaymentDialog extends StatefulWidget {
  final String clientSecret;
  const _WebCardPaymentDialog({required this.clientSecret});

  @override
  State<_WebCardPaymentDialog> createState() => _WebCardPaymentDialogState();
}

class _WebCardPaymentDialogState extends State<_WebCardPaymentDialog> {
  bool _isProcessing = false;
  String? _errorMessage;
  CardFieldInputDetails? _card;

  Future<void> _submit() async {
    if (_card == null || !_card!.complete) {
      setState(() => _errorMessage = 'من فضلك أدخل بيانات البطاقة كاملة');
      return;
    }

    setState(() {
      _isProcessing = true;
      _errorMessage = null;
    });

    try {
      await Stripe.instance.confirmPayment(
        paymentIntentClientSecret: widget.clientSecret,
        data: const PaymentMethodParams.card(
          paymentMethodData: PaymentMethodData(),
        ),
      );
      if (mounted) Navigator.of(context).pop(true);
    } on StripeException catch (e) {
      setState(() {
        _isProcessing = false;
        _errorMessage = e.error.localizedMessage ?? 'فشلت عملية الدفع';
      });
    } catch (e) {
      setState(() {
        _isProcessing = false;
        _errorMessage = 'حدث خطأ أثناء الدفع، حاول مرة أخرى';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('إتمام الدفع'),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CardField(
              onCardChanged: (card) {
                setState(() => _card = card);
              },
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 12),
              Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isProcessing ? null : () => Navigator.of(context).pop(false),
          child: const Text('إلغاء'),
        ),
        ElevatedButton(
          onPressed: _isProcessing ? null : _submit,
          child: _isProcessing
              ? const SizedBox(
            height: 18,
            width: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
              : const Text('ادفع'),
        ),
      ],
    );
  }
}