import 'package:flutter/material.dart';

/// إفصاح "خدمة حجز مستقلة" + بيانات البائع.
///
/// مطلوب قانونيًا:
///   • إلينوي SB 2013 (من 1 يناير 2027): مواقع الحجز التابعة لطرف ثالث يجب أن
///     تصرّح بوضوح أنها غير تابعة للفندق — أولًا في نتائج البحث، وقبل طلب أي
///     بيانات شخصية، وليس مخفيًا في الشروط.
///   • ماساتشوستس 940 CMR 15: اسم البائع وعنوانه الفعلي وهاتفه كتابيًا قبل الدفع.
///
/// ⚠️ لا تحذف هذا الإفصاح من نتائج البحث أو صفحة الفندق أو صفحة الحجز أو
/// نافذة المراجعة قبل الدفع. أي تغيير في العنوان/الهاتف يُحدَّث هنا فقط.
const String kSellerName = 'FLYNOOM LLC';
const String kSellerAddress = '31345 Six Mile Road, Livonia, MI 48152, USA';
const String kSellerPhone = '+1 978-483-9704';
const String kSellerEmail = 'support@flynoom.com';

String _pick(BuildContext c, Map<String, String> m) =>
    m[Localizations.localeOf(c).languageCode] ?? m['en']!;

/// "Flynoom خدمة حجز مستقلة وغير تابعة للفنادق المعروضة..."
String independentServiceText(BuildContext c) => _pick(c, const {
  'ar': 'Flynoom خدمة حجز مستقلة وغير تابعة للفنادق المعروضة. أنت تحجز عبر Flynoom، لا مع الفندق مباشرة.',
  'en': 'Flynoom is an independent booking service and is not affiliated with the hotels shown. You are booking through Flynoom, not directly with the hotel.',
  'es': 'Flynoom es un servicio de reservas independiente y no está afiliado a los hoteles mostrados. Reservas a través de Flynoom, no directamente con el hotel.',
  'tr': 'Flynoom bağımsız bir rezervasyon hizmetidir ve gösterilen otellerle bağlantılı değildir. Rezervasyonu doğrudan otelle değil, Flynoom üzerinden yapıyorsunuz.',
  'id': 'Flynoom adalah layanan pemesanan independen dan tidak berafiliasi dengan hotel yang ditampilkan. Anda memesan melalui Flynoom, bukan langsung dengan hotel.',
  'hi': 'Flynoom एक स्वतंत्र बुकिंग सेवा है और दिखाए गए होटलों से संबद्ध नहीं है। आप सीधे होटल से नहीं, बल्कि Flynoom के माध्यम से बुकिंग कर रहे हैं।',
  'ur': 'Flynoom ایک آزاد بکنگ سروس ہے اور دکھائے گئے ہوٹلوں سے وابستہ نہیں ہے۔ آپ براہ راست ہوٹل سے نہیں بلکہ Flynoom کے ذریعے بکنگ کر رہے ہیں۔',
  'fr': 'Flynoom est un service de réservation indépendant, non affilié aux hôtels affichés. Vous réservez via Flynoom, et non directement auprès de l\'hôtel.',
  'bn': 'Flynoom একটি স্বাধীন বুকিং সেবা এবং দেখানো হোটেলগুলোর সাথে সম্পর্কিত নয়। আপনি সরাসরি হোটেলের সাথে নয়, Flynoom-এর মাধ্যমে বুকিং করছেন।',
});

/// "البائع: FLYNOOM LLC · العنوان · الهاتف · البريد"
String sellerDetailsText(BuildContext c) {
  final label = _pick(c, const {
    'ar': 'البائع',
    'en': 'Seller',
    'es': 'Vendedor',
    'tr': 'Satıcı',
    'id': 'Penjual',
    'hi': 'विक्रेता',
    'ur': 'فروخت کنندہ',
    'fr': 'Vendeur',
    'bn': 'বিক্রেতা',
  });
  return '$label: $kSellerName · $kSellerAddress · $kSellerPhone · $kSellerEmail';
}

/// سطر صغير واضح (ليس مخفيًا) يُستخدم في النتائج والصفحات.
class IndependentServiceNotice extends StatelessWidget {
  /// أظهر بيانات البائع أيضًا (صفحة الحجز ونافذة المراجعة).
  final bool showSeller;
  final EdgeInsetsGeometry padding;

  const IndependentServiceNotice({
    super.key,
    this.showSeller = false,
    this.padding = const EdgeInsets.symmetric(vertical: 6),
  });

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7);
    return Padding(
      padding: padding,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, size: 16, color: color),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(independentServiceText(context), style: TextStyle(fontSize: 12, color: color)),
                if (showSeller) ...[
                  const SizedBox(height: 2),
                  SelectableText(sellerDetailsText(context), style: TextStyle(fontSize: 12, color: color)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}