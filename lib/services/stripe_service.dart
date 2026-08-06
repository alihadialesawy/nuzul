import 'package:flutter_stripe/flutter_stripe.dart';

/// نقطة وصول موحدة لإعدادات Stripe عبر التطبيق
class StripeService {
  StripeService._();

  /// استدعِ هذا مرة وحدة بملف main.dart قبل runApp()، بعد SupabaseService.initialize()
  static Future<void> initialize() async {
    Stripe.publishableKey = publishableKey;
    await Stripe.instance.applySettings();
  }

  // TODO: استبدل هذا بمفتاحك الفعلي من Stripe Dashboard
  // (Developers > API keys > Publishable key)
  // ابدأ بمفتاح test mode (يبدأ بـ pk_test_...) قبل الإطلاق الفعلي
  static const String publishableKey = 'PASTE_YOUR_STRIPE_PUBLISHABLE_KEY_HERE';
}