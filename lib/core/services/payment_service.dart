import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../utils/result.dart';
import '../utils/error_translator.dart';

/// يتعامل مع عملية الدفع الكاملة: يطلب من Supabase Edge Function إنشاء
/// Payment Intent، ثم يفتح واجهة إدخال بيانات البطاقة من Stripe مباشرة.
class PaymentService {
  final SupabaseClient _client = Supabase.instance.client;

  /// ينفّذ عملية دفع كاملة لمبلغ معيّن، ويرجع true لو نجح الدفع فعليًا
  Future<Result<bool>> pay({
    required double amount,
    String currency = 'sar',
  }) async {
    try {
      // 1. اطلب من Edge Function إنشاء Payment Intent بأمان من جهة السيرفر
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

      // 2. جهّز واجهة الدفع (Payment Sheet) من Stripe
      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: clientSecret,
          merchantDisplayName: 'نزل - Nuzul',
          style: ThemeMode.light,
        ),
      );

      // 3. اعرض واجهة الدفع فعليًا للمستخدم
      await Stripe.instance.presentPaymentSheet();

      // لو ما انرمى استثناء، معناه الدفع نجح
      return const Success(true);
    } on StripeException catch (e) {
      // المستخدم ألغى الدفع أو رفضت البطاقة
      final message = e.error.localizedMessage ?? 'تم إلغاء عملية الدفع';
      return Failure(message);
    } catch (e) {
      return Failure(ErrorTranslator.translate(e));
    }
  }
}