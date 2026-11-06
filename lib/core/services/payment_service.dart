import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../utils/result.dart';
import '../utils/error_translator.dart';

/// نص نافذة الدفع على الويب حسب لغة التطبيق (اللغات التسع).
String _pt(BuildContext context, String key) {
  const t = <String, List<String>>{
    // ar, en, es, tr, id, hi, ur, fr, bn
    'title': ['إتمام الدفع', 'Complete payment', 'Completar el pago', 'Ödemeyi tamamla', 'Selesaikan pembayaran', 'भुगतान पूरा करें', 'ادائیگی مکمل کریں', 'Finaliser le paiement', 'পেমেন্ট সম্পন্ন করুন'],
    'pay': ['ادفع', 'Pay', 'Pagar', 'Öde', 'Bayar', 'भुगतान करें', 'ادائیگی کریں', 'Payer', 'পেমেন্ট করুন'],
    'cancel': ['إلغاء', 'Cancel', 'Cancelar', 'Vazgeç', 'Batal', 'रद्द करें', 'منسوخ کریں', 'Annuler', 'বাতিল'],
    'incomplete': ['يُرجى إدخال بيانات البطاقة كاملة.', 'Please enter your full card details.', 'Introduce los datos completos de tu tarjeta.', 'Lütfen kart bilgilerinizi eksiksiz girin.', 'Harap masukkan detail kartu Anda dengan lengkap.', 'कृपया अपने कार्ड का पूरा विवरण दर्ज करें।', 'براہ کرم اپنے کارڈ کی مکمل تفصیلات درج کریں۔', 'Veuillez saisir toutes les informations de votre carte.', 'অনুগ্রহ করে কার্ডের সম্পূর্ণ তথ্য দিন।'],
    'failed': ['فشلت عملية الدفع.', 'Payment failed.', 'El pago no se pudo completar.', 'Ödeme başarısız oldu.', 'Pembayaran gagal.', 'भुगतान विफल रहा।', 'ادائیگی ناکام ہو گئی۔', 'Le paiement a échoué.', 'পেমেন্ট ব্যর্থ হয়েছে।'],
    'error': ['حدث خطأ أثناء الدفع، حاول مرة أخرى.', 'Something went wrong during payment. Please try again.', 'Ocurrió un error durante el pago. Inténtalo de nuevo.', 'Ödeme sırasında bir hata oluştu. Lütfen tekrar deneyin.', 'Terjadi kesalahan saat pembayaran. Silakan coba lagi.', 'भुगतान के दौरान कुछ गलत हो गया। कृपया फिर से प्रयास करें।', 'ادائیگی کے دوران کچھ غلط ہو گیا۔ براہ کرم دوبارہ کوشش کریں۔', 'Une erreur est survenue pendant le paiement. Veuillez réessayer.', 'পেমেন্টের সময় সমস্যা হয়েছে। আবার চেষ্টা করুন।'],
    // رفض من البنك أو من Radar (لا نذكر السبب، ونطمئن أنه لم يُسحب شيء).
    'declined': ["لم يقبل البنك هذه البطاقة، ولم يُسحب أي مبلغ. جرّب بطاقة أخرى.", "Your bank didn't accept this card. No money was taken. Please try a different card.", "Tu banco no aceptó esta tarjeta. No se ha cobrado nada. Prueba con otra tarjeta.", "Bankanız bu kartı kabul etmedi. Hiçbir ücret alınmadı. Lütfen başka bir kart deneyin.", "Bank Anda tidak menerima kartu ini. Tidak ada dana yang ditarik. Silakan coba kartu lain.", "आपके बैंक ने यह कार्ड स्वीकार नहीं किया। कोई राशि नहीं ली गई। कृपया दूसरा कार्ड आज़माएँ।", "آپ کے بینک نے یہ کارڈ قبول نہیں کیا۔ کوئی رقم نہیں لی گئی۔ براہ کرم دوسرا کارڈ آزمائیں۔", "Votre banque n'a pas accepté cette carte. Aucun montant n'a été débité. Veuillez essayer une autre carte.", "আপনার ব্যাংক এই কার্ডটি গ্রহণ করেনি। কোনো টাকা কাটা হয়নি। অনুগ্রহ করে অন্য কার্ড চেষ্টা করুন।"],
    // أغلق الزبون نافذة التحقق (3D Secure) أو فشل فيها.
    'authCancelled': ["لم تكتمل خطوة التحقق من البنك. حاول مرة أخرى.", "Bank verification was not completed. Please try again.", "No se completó la verificación del banco. Inténtalo de nuevo.", "Banka doğrulaması tamamlanmadı. Lütfen tekrar deneyin.", "Verifikasi bank tidak selesai. Silakan coba lagi.", "बैंक सत्यापन पूरा नहीं हुआ। कृपया फिर से प्रयास करें।", "بینک کی تصدیق مکمل نہیں ہوئی۔ براہ کرم دوبارہ کوشش کریں۔", "La vérification bancaire n'a pas été effectuée. Veuillez réessayer.", "ব্যাংক যাচাই সম্পন্ন হয়নি। আবার চেষ্টা করুন।"],
  };
  const order = ['ar', 'en', 'es', 'tr', 'id', 'hi', 'ur', 'fr', 'bn'];
  final i = order.indexOf(Localizations.localeOf(context).languageCode);
  return t[key]![i < 0 ? 1 : i];
}

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

      return confirmWithClientSecret(clientSecret: clientSecret, context: context);
    } catch (e) {
      return Failure(ErrorTranslator.translate(e));
    }
  }

  /// يعرض نافذة البطاقة ويؤكد PaymentIntent أنشأه السيرفر مسبقًا.
  ///
  /// تُستخدم لحجوزات HotelBeds: hotelbeds-prepare ينشئ الـ PaymentIntent
  /// بالمبلغ المحسوب على السيرفر وبـ capture_method=manual، فيُحجز المبلغ
  /// على البطاقة فقط، ولا يُسحب إلا بعد تأكيد الفندق (hotelbeds-book).
  Future<Result<bool>> confirmWithClientSecret({
    required String clientSecret,
    BuildContext? context,
  }) async {
    try {
      // على الويب: PaymentSheet غير مدعومة، نستخدم نافذة CardField مخصصة
      if (kIsWeb) {
        if (context == null) {
          return const Failure('تعذر فتح نافذة الدفع');
        }
        return _payOnWeb(context, clientSecret);
      }

      // على الموبايل: PaymentSheet
      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: clientSecret,
          // يجب أن يطابق اسم الشركة الذي يراه العميل في كشف حسابه.
          merchantDisplayName: 'Flynoom',
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
      setState(() => _errorMessage = _pt(context, 'incomplete'));
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
      // رسالة واضحة بلغة الزبون بدل نص Stripe الإنجليزي.
      final cancelled = e.error.code == FailureCode.Canceled;
      setState(() {
        _isProcessing = false;
        _errorMessage = _pt(context, cancelled ? 'authCancelled' : 'declined');
      });
    } catch (e) {
      // على الويب قد يصل رفض البطاقة كخطأ عام (ليس StripeException).
      final msg = e.toString().toLowerCase();
      final declined = msg.contains('declin') || msg.contains('blocked') || msg.contains('card_error');
      final authFail = msg.contains('authenticat') || msg.contains('3d secure');
      setState(() {
        _isProcessing = false;
        _errorMessage = _pt(context, declined ? 'declined' : authFail ? 'authCancelled' : 'error');
      });
      debugPrint('Web card payment error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_pt(context, 'title')),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ⚠️ إمكانية الوصول على الويب (main.dart) تسحب التركيز من خانة Stripe
            // (iframe) فلا يمكن الكتابة فيها. ExcludeSemantics + ExcludeFocus
            // يُبعدان الخانة عن إدارة Flutter للتركيز وعن طبقة قارئ الشاشة،
            // فيبقى التركيز داخلها. الخانة نفسها HTML من Stripe يقرؤه قارئ الشاشة
            // مباشرة. لا تحذفهما.
            ExcludeSemantics(
              child: ExcludeFocus(
                child: CardField(
                  // الرمز البريدي إلزامي: نعرف منه ولاية البطاقة (منع الولايات غير
                  // المسجّل فيها في hotelbeds-book) ويتحقق منه بنك العميل.
                  enablePostalCode: true,
                  onCardChanged: (card) {
                    setState(() => _card = card);
                  },
                ),
              ),
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
          child: Text(_pt(context, 'cancel')),
        ),
        ElevatedButton(
          onPressed: _isProcessing ? null : _submit,
          child: _isProcessing
              ? const SizedBox(
            height: 18,
            width: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
              : Text(_pt(context, 'pay')),
        ),
      ],
    );
  }
}