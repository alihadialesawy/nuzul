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

/// "Flynoom متاح للمقيمين في الولايات المتحدة فقط" — يظهر مع الإفصاح في النتائج
/// وصفحة الفندق وصفحة الحجز، حتى يعرف الزائر من خارج أمريكا قبل أن يختار فندقًا
/// (لا عند الدفع فقط). الخادم يفرضه أيضًا (رمز بريدي أمريكي، hotelbeds-book).
/// (الاسم تاريخي) شرط الإقامة: الولايات المتحدة والعراق.
String usResidentsOnlyText(BuildContext c) => _pick(c, const {
      'ar': 'الحجز عبر Flynoom متاح للمقيمين في الولايات المتحدة والعراق، ببطاقة عنوان فاتورتها أمريكي أو بطاقة صادرة في العراق. ويمكنك الحجز لنزلاء من أي بلد.',
      'en': 'Booking on Flynoom is available to residents of the United States and Iraq, with a card that has a U.S. billing address or a card issued in Iraq. You can book for guests from any country.',
      'es': 'Las reservas en Flynoom están disponibles para residentes de EE. UU. e Irak, con una tarjeta con dirección de facturación en EE. UU. o una tarjeta emitida en Irak. Puedes reservar para huéspedes de cualquier país.',
      'tr': 'Flynoom üzerinden rezervasyon ABD\'de ve Irak\'ta ikamet edenlere açıktır; ABD fatura adresli bir kart veya Irak\'ta düzenlenmiş bir kart gerekir. Her ülkeden misafir için rezervasyon yapabilirsiniz.',
      'id': 'Pemesanan di Flynoom tersedia bagi penduduk AS dan Irak, dengan kartu beralamat penagihan di AS atau kartu yang diterbitkan di Irak. Anda dapat memesan untuk tamu dari negara mana pun.',
      'hi': 'Flynoom पर बुकिंग अमेरिका और इराक के निवासियों के लिए उपलब्ध है, ऐसे कार्ड से जिसका बिलिंग पता अमेरिका का हो या जो इराक में जारी हुआ हो। आप किसी भी देश के मेहमानों के लिए बुकिंग कर सकते हैं।',
      'ur': 'Flynoom پر بکنگ امریکہ اور عراق کے رہائشیوں کے لیے دستیاب ہے، ایسے کارڈ سے جس کا بلنگ ایڈریس امریکہ کا ہو یا جو عراق میں جاری ہوا ہو۔ آپ کسی بھی ملک کے مہمانوں کے لیے بکنگ کر سکتے ہیں۔',
      'fr': 'La réservation sur Flynoom est ouverte aux résidents des États-Unis et de l\'Irak, avec une carte dont l\'adresse de facturation est aux États-Unis ou une carte émise en Irak. Vous pouvez réserver pour des voyageurs de n\'importe quel pays.',
      'bn': 'Flynoom-এ বুকিং মার্কিন যুক্তরাষ্ট্র ও ইরাকের বাসিন্দাদের জন্য, এমন কার্ডে যার বিলিং ঠিকানা মার্কিন যুক্তরাষ্ট্রে অথবা যা ইরাকে ইস্যু করা। আপনি যেকোনো দেশের অতিথির জন্য বুকিং করতে পারেন।',
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
///
/// شرط الأهلية (أمريكا والعراق والولايات الممنوعة) لا يظهر في الواجهة: هو في شروط
/// الخدمة (البند 3)، والموافقة عليها في صفحة الحجز تشمله، والسيرفر يفرضه عند الدفع.
class IndependentServiceNotice extends StatelessWidget {
  /// أظهر بيانات البائع أيضًا (صفحة الحجز ونافذة المراجعة).
  final bool showSeller;

  /// أظهر سطر الأهلية (غير مستخدم حاليًا؛ متروك للحاجة).
  final bool showEligibility;
  final EdgeInsetsGeometry padding;

  const IndependentServiceNotice({
    super.key,
    this.showSeller = false,
    this.showEligibility = false,
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
                if (showEligibility) ...[
                  const SizedBox(height: 2),
                  Text(
                    usResidentsOnlyText(context),
                    style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w600),
                  ),
                ],
                if (showSeller) ...[
                  const SizedBox(height: 2),
                  // Text لا SelectableText: على الويب يتحول SelectableText إلى textarea
                  // معطّل بلا اسم (Lighthouse: "Form elements do not have associated labels").
                  Text(sellerDetailsText(context), style: TextStyle(fontSize: 12, color: color)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
