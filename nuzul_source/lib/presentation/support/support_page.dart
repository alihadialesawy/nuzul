import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../core/widgets/app_banner.dart';
import '../../core/widgets/app_footer.dart';

/// يختار النص المناسب حسب اللغة الحالية (عربي/إنجليزي/إسباني/تركي/إندونيسي/هندي/أوردو/فرنسي/بنغالي).
String _t3(
    BuildContext context, {
      required String ar,
      required String en,
      required String es,
      required String tr,
      required String id,
      required String hi,
      required String ur,
      required String fr,
      required String bn,
    }) {
  switch (Localizations.localeOf(context).languageCode) {
    case 'ar':
      return ar;
    case 'es':
      return es;
    case 'tr':
      return tr;
    case 'id':
      return id;
    case 'hi':
      return hi;
    case 'ur':
      return ur;
    case 'fr':
      return fr;
    case 'bn':
      return bn;
    default:
      return en;
  }
}

class _FaqItem {
  final String question;
  final String answer;
  const _FaqItem(this.question, this.answer);
}

/// شاشة دعم العملاء: هيدر + تبويبات فئات + أسئلة شائعة قابلة للطي + كلمات
/// دلالية سريعة + شريط وصول سريع (شات/اتصال/طوارئ) تحت.
class SupportPage extends StatefulWidget {
  const SupportPage({super.key});

  @override
  State<SupportPage> createState() => _SupportPageState();
}

class _SupportPageState extends State<SupportPage> {
  String _activeCategory = 'flights';

  void _comingSoon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_t3(
          context,
          ar: 'قريبًا',
          en: 'Coming soon',
          es: 'Próximamente',
          tr: 'Yakında',
          id: 'Segera hadir',
          hi: 'जल्द आ रहा है',
          ur: 'جلد آ رہا ہے',
          fr: 'Bientôt disponible',
          bn: 'শীঘ্রই আসছে',
        )),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  List<_FaqItem> _faqsFor(BuildContext context, String category) {
    switch (category) {
      case 'hotels':
        return [
          _FaqItem(
            _t3(
              context,
              ar: 'كيف أحجز غرفة؟',
              en: 'How do I book a room?',
              es: '¿Cómo reservo una habitación?',
              tr: 'Nasıl oda ayırtırım?',
              id: 'Bagaimana cara memesan kamar?',
              hi: 'मैं कमरा कैसे बुक करूं?',
              ur: 'میں کمرہ کیسے بک کروں؟',
              fr: 'Comment réserver une chambre ?',
              bn: 'আমি কীভাবে একটি রুম বুক করব?',
            ),
            _t3(
              context,
              ar: 'ادخل إلى تبويب "الإقامة"، واختر المدينة والتواريخ وعدد الضيوف، ثم ابدأ البحث. بعد اختيار الفندق ونوع الغرفة، أكمل بيانات الحجز والدفع.',
              en: 'Go to the Stays tab, choose your city, dates, and guest count, then search. After picking a hotel and room type, complete your booking and payment.',
              es: 'Ve a la pestaña Alojamientos, elige ciudad, fechas y huéspedes, y busca. Luego elige hotel y tipo de habitación para completar la reserva.',
              tr: 'Konaklama sekmesine gidin, şehir, tarih ve misafir sayısını seçip arama yapın. Otel ve oda türünü seçtikten sonra rezervasyon ve ödemeyi tamamlayın.',
              id: 'Buka tab Menginap, pilih kota, tanggal, dan jumlah tamu, lalu cari. Setelah memilih hotel dan tipe kamar, selesaikan pemesanan dan pembayaran.',
              hi: '"ठहरना" टैब पर जाएं, अपना शहर, तारीखें और मेहमानों की संख्या चुनें, फिर खोजें। होटल और कमरे का प्रकार चुनने के बाद बुकिंग और भुगतान पूरा करें।',
              ur: 'قیام کے ٹیب پر جائیں، اپنا شہر، تاریخیں اور مہمانوں کی تعداد منتخب کریں، پھر تلاش کریں۔ ہوٹل اور کمرے کی قسم منتخب کرنے کے بعد اپنی بکنگ اور ادائیگی مکمل کریں۔',
              fr: 'Allez dans l\'onglet Séjours, choisissez votre ville, vos dates et le nombre de voyageurs, puis recherchez. Après avoir choisi un hôtel et un type de chambre, finalisez votre réservation et votre paiement.',
              bn: 'থাকার ব্যবস্থা ট্যাবে যান, আপনার শহর, তারিখ ও অতিথি সংখ্যা নির্বাচন করুন, তারপর অনুসন্ধান করুন। হোটেল ও রুমের ধরন বেছে নেওয়ার পর আপনার বুকিং ও পেমেন্ট সম্পূর্ণ করুন।',
            ),
          ),
          _FaqItem(
            _t3(
              context,
              ar: 'هل يمكنني إلغاء حجزي؟',
              en: 'Can I cancel my booking?',
              es: '¿Puedo cancelar mi reserva?',
              tr: 'Rezervasyonumu iptal edebilir miyim?',
              id: 'Bisakah saya membatalkan pesanan saya?',
              hi: 'क्या मैं अपनी बुकिंग रद्द कर सकता हूं?',
              ur: 'کیا میں اپنی بکنگ منسوخ کر سکتا ہوں؟',
              fr: 'Puis-je annuler ma réservation ?',
              bn: 'আমি কি আমার বুকিং বাতিল করতে পারি?',
            ),
            _t3(
              context,
              ar: 'نعم، من صفحة "حجوزاتي" يمكنك إلغاء أي حجز لا يزال في حالة "قيد الانتظار" أو "مؤكد"، وفقًا لسياسة الإلغاء الخاصة بالفندق.',
              en: 'Yes, from "My Bookings" you can cancel any pending or confirmed booking, subject to the hotel\'s cancellation policy.',
              es: 'Sí, desde "Mis reservas" puedes cancelar cualquier reserva pendiente o confirmada, según la política del hotel.',
              tr: 'Evet, "Rezervasyonlarım" sayfasından, otelin iptal politikasına bağlı olarak bekleyen veya onaylanmış herhangi bir rezervasyonu iptal edebilirsiniz.',
              id: 'Ya, dari "Pesanan Saya" Anda bisa membatalkan pesanan yang menunggu atau dikonfirmasi, sesuai kebijakan pembatalan hotel.',
              hi: 'हाँ, "मेरी बुकिंग" से आप किसी भी लंबित या पुष्ट बुकिंग को रद्द कर सकते हैं, होटल की रद्दीकरण नीति के अनुसार।',
              ur: 'جی ہاں، "میری بکنگز" سے آپ کوئی بھی زیر التوا یا تصدیق شدہ بکنگ منسوخ کر سکتے ہیں، ہوٹل کی منسوخی پالیسی کے مطابق۔',
              fr: 'Oui, depuis « Mes réservations », vous pouvez annuler toute réservation en attente ou confirmée, selon la politique d\'annulation de l\'hôtel.',
              bn: 'হ্যাঁ, "আমার বুকিং" থেকে আপনি যেকোনো অপেক্ষমাণ বা নিশ্চিত বুকিং বাতিল করতে পারেন, হোটেলের বাতিলকরণ নীতি সাপেক্ষে।',
            ),
          ),
          _FaqItem(
            _t3(
              context,
              ar: 'ما طرق الدفع المتاحة؟',
              en: 'What payment methods are supported?',
              es: '¿Qué métodos de pago se admiten?',
              tr: 'Hangi ödeme yöntemleri destekleniyor?',
              id: 'Metode pembayaran apa saja yang didukung?',
              hi: 'कौन से भुगतान तरीके समर्थित हैं?',
              ur: 'کون سے ادائیگی کے طریقے قابل استعمال ہیں؟',
              fr: 'Quels sont les moyens de paiement acceptés ?',
              bn: 'কোন কোন পেমেন্ট পদ্ধতি সমর্থিত?',
            ),
            _t3(
              context,
              ar: 'ندعم الدفع عبر البطاقات الائتمانية على الأجهزة المدعومة. في بعض الأنظمة، يُسجَّل الحجز بحالة "قيد الانتظار" إلى أن يكتمل الدفع.',
              en: 'We support credit card payments on supported devices. On some platforms, bookings are registered as "pending" until payment is completed elsewhere.',
              es: 'Aceptamos pagos con tarjeta en dispositivos compatibles. En algunas plataformas, la reserva queda "pendiente" hasta completar el pago.',
              tr: 'Desteklenen cihazlarda kredi kartı ödemelerini destekliyoruz. Bazı platformlarda, ödeme başka bir yerde tamamlanana kadar rezervasyon "beklemede" olarak kaydedilir.',
              id: 'Kami mendukung pembayaran kartu kredit di perangkat yang didukung. Di beberapa platform, pesanan terdaftar sebagai "menunggu" hingga pembayaran selesai di tempat lain.',
              hi: 'हम समर्थित डिवाइस पर क्रेडिट कार्ड भुगतान स्वीकार करते हैं। कुछ प्लेटफ़ॉर्म पर, भुगतान पूरा होने तक बुकिंग "लंबित" के रूप में दर्ज होती है।',
              ur: 'ہم قابل استعمال ڈیوائسز پر کریڈٹ کارڈ ادائیگیوں کو سپورٹ کرتے ہیں۔ کچھ پلیٹ فارمز پر، بکنگ اس وقت تک "زیر التوا" رجسٹر رہتی ہے جب تک ادائیگی کہیں اور مکمل نہ ہو۔',
              fr: 'Nous acceptons les paiements par carte de crédit sur les appareils compatibles. Sur certaines plateformes, les réservations sont enregistrées comme « en attente » jusqu\'à ce que le paiement soit finalisé ailleurs.',
              bn: 'আমরা সমর্থিত ডিভাইসে ক্রেডিট কার্ড পেমেন্ট সমর্থন করি। কিছু প্ল্যাটফর্মে, পেমেন্ট অন্য কোথাও সম্পন্ন না হওয়া পর্যন্ত বুকিং "অপেক্ষমাণ" হিসেবে নিবন্ধিত থাকে।',
            ),
          ),
          _FaqItem(
            _t3(
              context,
              ar: 'هل أحتاج حسابًا للبحث عن الفنادق؟',
              en: 'Do I need an account to search for hotels?',
              es: '¿Necesito una cuenta para buscar hoteles?',
              tr: 'Otel aramak için hesaba ihtiyacım var mı?',
              id: 'Apakah saya perlu akun untuk mencari hotel?',
              hi: 'क्या होटल खोजने के लिए मुझे खाता चाहिए?',
              ur: 'کیا ہوٹل تلاش کرنے کے لیے مجھے اکاؤنٹ چاہیے؟',
              fr: 'Ai-je besoin d\'un compte pour rechercher des hôtels ?',
              bn: 'হোটেল খুঁজতে কি আমার অ্যাকাউন্ট দরকার?',
            ),
            _t3(
              context,
              ar: 'لا، يمكنك البحث وتصفح النتائج دون تسجيل الدخول. تسجيل الدخول مطلوب فقط عند تأكيد الحجز.',
              en: 'No, you can search and browse results without signing in. An account is only required when confirming a booking.',
              es: 'No, puedes buscar y explorar resultados sin iniciar sesión. Solo se requiere cuenta al confirmar una reserva.',
              tr: 'Hayır, oturum açmadan arama yapıp sonuçlara göz atabilirsiniz. Hesap yalnızca rezervasyonu onaylarken gereklidir.',
              id: 'Tidak, Anda bisa mencari dan menjelajahi hasil tanpa masuk. Akun hanya diperlukan saat mengonfirmasi pemesanan.',
              hi: 'नहीं, आप बिना साइन इन किए खोज सकते हैं और परिणाम देख सकते हैं। बुकिंग की पुष्टि करते समय ही खाता आवश्यक है।',
              ur: 'نہیں، آپ سائن ان کیے بغیر تلاش اور نتائج دیکھ سکتے ہیں۔ بکنگ کی تصدیق کرتے وقت ہی اکاؤنٹ درکار ہوتا ہے۔',
              fr: 'Non, vous pouvez rechercher et consulter les résultats sans vous connecter. Un compte n\'est requis que pour confirmer une réservation.',
              bn: 'না, সাইন ইন না করেই আপনি অনুসন্ধান ও ফলাফল দেখতে পারেন। বুকিং নিশ্চিত করার সময়ই কেবল অ্যাকাউন্ট প্রয়োজন।',
            ),
          ),
        ];
      case 'carRentals':
        return [
          _FaqItem(
            _t3(
              context,
              ar: 'كيف أستأجر سيارة؟',
              en: 'How do I rent a car?',
              es: '¿Cómo alquilo un coche?',
              tr: 'Nasıl araç kiralarım?',
              id: 'Bagaimana cara menyewa mobil?',
              hi: 'मैं कार कैसे किराए पर लूं?',
              ur: 'میں کار کیسے کرایہ پر لوں؟',
              fr: 'Comment louer une voiture ?',
              bn: 'আমি কীভাবে গাড়ি ভাড়া নেব?',
            ),
            _t3(
              context,
              ar: 'من تبويب "تأجير السيارات"، أدخل مدينة الاستلام والتواريخ، وابحث عن السيارات المتاحة.',
              en: 'From the Car rental tab, enter the pickup city and dates, then search available cars.',
              es: 'Desde la pestaña de alquiler, indica ciudad de recogida y fechas, y busca coches disponibles.',
              tr: 'Araç kiralama sekmesinden alış şehrini ve tarihlerini girip uygun araçları arayın.',
              id: 'Dari tab Sewa mobil, masukkan kota pengambilan dan tanggal, lalu cari mobil yang tersedia.',
              hi: '"कार किराए पर लें" टैब से, पिकअप शहर और तारीखें दर्ज करें, फिर उपलब्ध कारें खोजें।',
              ur: 'کار کرایہ کے ٹیب سے، پک اپ شہر اور تاریخیں درج کریں، پھر دستیاب کاریں تلاش کریں۔',
              fr: 'Depuis l\'onglet Location de voiture, saisissez la ville de prise en charge et les dates, puis recherchez les voitures disponibles.',
              bn: 'গাড়ি ভাড়া ট্যাব থেকে, পিকআপ শহর ও তারিখ লিখুন, তারপর উপলব্ধ গাড়ি খুঁজুন।',
            ),
          ),
          _FaqItem(
            _t3(
              context,
              ar: 'هل يمكنني تسليم السيارة في مكان مختلف؟',
              en: 'Can I drop off at a different location?',
              es: '¿Puedo devolver en otro lugar?',
              tr: 'Farklı bir yere teslim edebilir miyim?',
              id: 'Bisakah saya mengembalikan di lokasi berbeda?',
              hi: 'क्या मैं अलग जगह पर कार लौटा सकता हूं?',
              ur: 'کیا میں مختلف مقام پر کار واپس کر سکتا ہوں؟',
              fr: 'Puis-je restituer la voiture à un autre endroit ?',
              bn: 'আমি কি ভিন্ন স্থানে গাড়ি ফেরত দিতে পারি?',
            ),
            _t3(
              context,
              ar: 'نعم، فعّل خيار "مكان تسليم مختلف" في نموذج البحث وأدخل المكان الذي ترغب في التسليم فيه.',
              en: 'Yes, enable "Different drop-off location" in the search form and enter your preferred drop-off spot.',
              es: 'Sí, activa "Lugar de devolución diferente" en el formulario e indica el lugar deseado.',
              tr: 'Evet, arama formunda "Farklı bir teslim noktası" seçeneğini etkinleştirip tercih ettiğiniz teslim yerini girin.',
              id: 'Ya, aktifkan "Lokasi pengembalian berbeda" di formulir pencarian dan masukkan lokasi pengembalian pilihan Anda.',
              hi: 'हाँ, खोज फॉर्म में "अलग लोकेशन पर लौटाएं" चालू करें और अपनी पसंदीदा जगह दर्ज करें।',
              ur: 'جی ہاں، تلاش کے فارم میں "مختلف ڈراپ آف مقام" فعال کریں اور اپنی پسندیدہ ڈراپ آف جگہ درج کریں۔',
              fr: 'Oui, activez « Lieu de restitution différent » dans le formulaire de recherche et indiquez l\'emplacement de votre choix.',
              bn: 'হ্যাঁ, অনুসন্ধান ফর্মে "ভিন্ন ড্রপ-অফ স্থান" সক্রিয় করুন এবং আপনার পছন্দের ড্রপ-অফ স্থান লিখুন।',
            ),
          ),
        ];
      case 'flightHotel':
        return [
          _FaqItem(
            _t3(
              context,
              ar: 'هل حجز طيران + فندق أرخص؟',
              en: 'Is booking flight + hotel cheaper?',
              es: '¿Reservar vuelo + hotel es más barato?',
              tr: 'Uçuş + otel rezervasyonu daha mı ucuz?',
              id: 'Apakah memesan penerbangan + hotel lebih murah?',
              hi: 'क्या उड़ान + होटल एक साथ बुक करना सस्ता है?',
              ur: 'کیا پرواز + ہوٹل ایک ساتھ بک کرنا سستا ہے؟',
              fr: 'Réserver vol + hôtel est-il moins cher ?',
              bn: 'ফ্লাইট + হোটেল একসাথে বুক করা কি সস্তা?',
            ),
            _t3(
              context,
              ar: 'يعرض بحث "طيران + فندق" حاليًا نتائج الفنادق المتاحة، وسيتم تفعيل بحث الطيران المرتبط قريبًا مع عروض حصرية للحجز المشترك.',
              en: 'The Flight+Hotel search shows available hotel results now; the linked flight search with bundled deals is coming soon.',
              es: 'La búsqueda combinada muestra hoteles disponibles ahora; los vuelos vinculados llegarán pronto con ofertas exclusivas.',
              tr: 'Uçuş+Otel araması şu anda uygun otel sonuçlarını gösteriyor; paket fırsatlarıyla bağlantılı uçuş araması yakında geliyor.',
              id: 'Pencarian Penerbangan+Hotel saat ini menampilkan hasil hotel yang tersedia; pencarian penerbangan terkait dengan penawaran paket segera hadir.',
              hi: '"उड़ान + होटल" खोज अभी उपलब्ध होटल परिणाम दिखाती है; जुड़े हुए ऑफ़र के साथ उड़ान खोज जल्द आ रही है।',
              ur: 'پرواز+ہوٹل تلاش اس وقت دستیاب ہوٹل نتائج دکھاتی ہے؛ بنڈل آفرز کے ساتھ منسلک پرواز تلاش جلد آ رہی ہے۔',
              fr: 'La recherche Vol+Hôtel affiche actuellement les hôtels disponibles ; la recherche de vol associée avec des offres groupées arrive bientôt.',
              bn: 'ফ্লাইট+হোটেল অনুসন্ধান এখন উপলব্ধ হোটেলের ফলাফল দেখায়; বান্ডেল অফারসহ সংযুক্ত ফ্লাইট অনুসন্ধান শীঘ্রই আসছে।',
            ),
          ),
        ];
      case 'flights':
      default:
        return [
          _FaqItem(
            _t3(
              context,
              ar: 'هل توجد عروض على تذاكر الطيران؟',
              en: 'Are there any flight ticket promotions going on?',
              es: '¿Hay promociones en vuelos?',
              tr: 'Uçak bileti kampanyaları var mı?',
              id: 'Apakah ada promo tiket penerbangan?',
              hi: 'क्या फ़्लाइट टिकट पर कोई ऑफ़र चल रहा है?',
              ur: 'کیا فلائٹ ٹکٹ پر کوئی پروموشن چل رہا ہے؟',
              fr: 'Y a-t-il des promotions en cours sur les billets d\'avion ?',
              bn: 'ফ্লাইট টিকিটে কি কোনো প্রমোশন চলছে?',
            ),
            _t3(
              context,
              ar: 'تتغيّر العروض باستمرار حسب الوجهة والتاريخ. استخدم ميزة "تنبيهات الأسعار" لنرسل إليك بريدًا إلكترونيًا بمجرد إيجاد السعر الذي ترغب في الوصول إليه.',
              en: 'Promotions change often by destination and date. Use "Price alerts" so we can email you as soon as we find your target price.',
              es: 'Las promociones cambian según destino y fecha. Usa "Alertas de precio" para recibir un correo al encontrar tu precio deseado.',
              tr: 'Kampanyalar varış noktası ve tarihe göre sık sık değişir. Hedef fiyatınızı bulur bulmaz size e-posta gönderebilmemiz için "Fiyat uyarıları" özelliğini kullanın.',
              id: 'Promo sering berubah tergantung tujuan dan tanggal. Gunakan "Peringatan harga" agar kami bisa mengirim email begitu menemukan harga target Anda.',
              hi: 'ऑफ़र गंतव्य और तारीख के अनुसार अक्सर बदलते रहते हैं। "मूल्य अलर्ट" का उपयोग करें ताकि आपकी लक्ष्य कीमत मिलते ही हम आपको ईमेल कर सकें।',
              ur: 'پروموشنز منزل اور تاریخ کے مطابق اکثر تبدیل ہوتی ہیں۔ "قیمت الرٹس" استعمال کریں تاکہ آپ کی ہدف قیمت ملتے ہی ہم آپ کو ای میل کر سکیں۔',
              fr: 'Les promotions changent souvent selon la destination et la date. Utilisez « Alertes de prix » pour recevoir un e-mail dès que nous trouvons votre prix cible.',
              bn: 'গন্তব্য ও তারিখ অনুযায়ী প্রমোশন প্রায়ই পরিবর্তিত হয়। "মূল্য সতর্কতা" ব্যবহার করুন যাতে আপনার লক্ষ্য মূল্য পেলেই আমরা আপনাকে ইমেইল করতে পারি।',
            ),
          ),
          _FaqItem(
            _t3(
              context,
              ar: 'كيف أغيّر تذكرتي؟',
              en: 'How do I change my ticket?',
              es: '¿Cómo cambio mi boleto?',
              tr: 'Biletimi nasıl değiştiririm?',
              id: 'Bagaimana cara mengubah tiket saya?',
              hi: 'मैं अपना टिकट कैसे बदलूं?',
              ur: 'میں اپنا ٹکٹ کیسے تبدیل کروں؟',
              fr: 'Comment modifier mon billet ?',
              bn: 'আমি কীভাবে আমার টিকিট পরিবর্তন করব?',
            ),
            _t3(
              context,
              ar: 'سيتم تفعيل تعديل التذاكر بعد الحجز قريبًا. إلى أن تصبح هذه الخدمة متاحة، تواصل مع الدعم عبر الدردشة أو الاتصال أدناه.',
              en: 'Post-booking ticket changes are coming soon. Until then, contact support via chat or call below.',
              es: 'Los cambios de boleto llegarán pronto. Mientras tanto, contacta soporte por chat o llamada abajo.',
              tr: 'Rezervasyon sonrası bilet değişiklikleri yakında geliyor. O zamana kadar aşağıdaki sohbet veya arama seçeneğiyle destek ekibine ulaşın.',
              id: 'Perubahan tiket setelah pemesanan segera hadir. Sementara itu, hubungi dukungan melalui chat atau telepon di bawah.',
              hi: 'बुकिंग के बाद टिकट बदलने की सुविधा जल्द आ रही है। तब तक, नीचे दिए गए चैट या कॉल के ज़रिए सहायता से संपर्क करें।',
              ur: 'بکنگ کے بعد ٹکٹ تبدیلی جلد آ رہی ہے۔ اس وقت تک، نیچے دیے گئے چیٹ یا کال کے ذریعے سپورٹ سے رابطہ کریں۔',
              fr: 'La modification des billets après réservation arrive bientôt. En attendant, contactez l\'assistance par chat ou par téléphone ci-dessous.',
              bn: 'বুকিং-পরবর্তী টিকিট পরিবর্তন শীঘ্রই আসছে। ততক্ষণ, নিচের চ্যাট বা কলের মাধ্যমে সহায়তার সাথে যোগাযোগ করুন।',
            ),
          ),
          _FaqItem(
            _t3(
              context,
              ar: 'كيف ألغي تذكرة الطيران؟',
              en: 'How can I cancel my flight ticket?',
              es: '¿Cómo cancelo mi boleto de vuelo?',
              tr: 'Uçak biletimi nasıl iptal ederim?',
              id: 'Bagaimana cara membatalkan tiket penerbangan saya?',
              hi: 'मैं अपना फ़्लाइट टिकट कैसे रद्द करूं?',
              ur: 'میں اپنی فلائٹ ٹکٹ کیسے منسوخ کروں؟',
              fr: 'Comment annuler mon billet d\'avion ?',
              bn: 'আমি কীভাবে আমার ফ্লাইট টিকিট বাতিল করব?',
            ),
            _t3(
              context,
              ar: 'سيتم تفعيل إلغاء تذاكر الطيران قريبًا. أما حجوزات الفنادق، فيمكنك إلغاؤها فعليًا من صفحة "حجوزاتي".',
              en: 'Flight ticket cancellation is coming soon. Hotel bookings can already be cancelled from "My Bookings".',
              es: 'La cancelación de vuelos llegará pronto. Las reservas de hotel ya se pueden cancelar desde "Mis reservas".',
              tr: 'Uçak bileti iptali yakında geliyor. Otel rezervasyonlarını zaten "Rezervasyonlarım" sayfasından iptal edebilirsiniz.',
              id: 'Pembatalan tiket penerbangan segera hadir. Pesanan hotel sudah bisa dibatalkan dari "Pesanan Saya".',
              hi: 'फ़्लाइट टिकट रद्द करने की सुविधा जल्द आ रही है। होटल बुकिंग को अभी "मेरी बुकिंग" से रद्द किया जा सकता है।',
              ur: 'فلائٹ ٹکٹ منسوخی جلد آ رہی ہے۔ ہوٹل بکنگز پہلے سے "میری بکنگز" سے منسوخ کی جا سکتی ہیں۔',
              fr: 'L\'annulation des billets d\'avion arrive bientôt. Les réservations d\'hôtel peuvent déjà être annulées depuis « Mes réservations ».',
              bn: 'ফ্লাইট টিকিট বাতিলকরণ শীঘ্রই আসছে। হোটেল বুকিং ইতিমধ্যে "আমার বুকিং" থেকে বাতিল করা যায়।',
            ),
          ),
          _FaqItem(
            _t3(
              context,
              ar: 'لديك سؤال مختلف؟ تواصل معنا الآن',
              en: 'Have a different question? Chat with us now.',
              es: '¿Tienes otra pregunta? Chatea con nosotros.',
              tr: 'Farklı bir sorunuz mu var? Şimdi bizimle sohbet edin.',
              id: 'Ada pertanyaan lain? Chat dengan kami sekarang.',
              hi: 'कोई और सवाल है? अभी हमसे चैट करें।',
              ur: 'کوئی اور سوال ہے؟ ابھی ہم سے چیٹ کریں۔',
              fr: 'Une autre question ? Chattez avec nous dès maintenant.',
              bn: 'অন্য কোনো প্রশ্ন আছে? এখনই আমাদের সাথে চ্যাট করুন।',
            ),
            _t3(
              context,
              ar: 'استخدم زر "Chat" أدناه للتواصل مع فريق الدعم مباشرة.',
              en: 'Use the "Chat" button below to reach our support team directly.',
              es: 'Usa el botón "Chat" abajo para contactar directamente con soporte.',
              tr: 'Destek ekibimize doğrudan ulaşmak için aşağıdaki "Sohbet" düğmesini kullanın.',
              id: 'Gunakan tombol "Chat" di bawah untuk menghubungi tim dukungan kami langsung.',
              hi: 'सीधे हमारी सहायता टीम तक पहुंचने के लिए नीचे दिए गए "चैट" बटन का उपयोग करें।',
              ur: 'براہ راست ہماری سپورٹ ٹیم تک پہنچنے کے لیے نیچے دیا گیا "چیٹ" بٹن استعمال کریں۔',
              fr: 'Utilisez le bouton « Chat » ci-dessous pour contacter directement notre équipe d\'assistance.',
              bn: 'সরাসরি আমাদের সহায়তা দলের সাথে যোগাযোগ করতে নিচের "চ্যাট" বোতাম ব্যবহার করুন।',
            ),
          ),
        ];
    }
  }

  List<String> _tagsFor(String category) {
    switch (category) {
      case 'hotels':
        return ['Hot Topics', 'Booking & Price', 'Cancellation', 'Room Info', 'Payment'];
      case 'carRentals':
        return ['Hot Topics', 'Pickup & Return', 'Pricing', 'Insurance', 'License Requirements'];
      case 'flightHotel':
        return ['Hot Topics', 'Bundled Deals', 'Combined Cancellation'];
      case 'flights':
      default:
        return ['Hot Topics', 'Booking & Price', 'Ticketing & Payment', 'Booking Query', 'Passenger Information-related'];
    }
  }

  String _categoryLabel(BuildContext context, String category) {
    switch (category) {
      case 'hotels':
        return _t3(
          context,
          ar: 'الفنادق',
          en: 'Hotels',
          es: 'Hoteles',
          tr: 'Oteller',
          id: 'Hotel',
          hi: 'होटल',
          ur: 'ہوٹلز',
          fr: 'Hôtels',
          bn: 'হোটেল',
        );
      case 'carRentals':
        return _t3(
          context,
          ar: 'تأجير السيارات',
          en: 'Car Rentals',
          es: 'Alquiler de coches',
          tr: 'Araç kiralama',
          id: 'Sewa mobil',
          hi: 'कार किराए पर लें',
          ur: 'کار کرایہ پر لیں',
          fr: 'Location de voitures',
          bn: 'গাড়ি ভাড়া',
        );
      case 'flightHotel':
        return _t3(
          context,
          ar: 'الفنادق والطيران',
          en: 'Hotels & Homes',
          es: 'Hoteles y vuelos',
          tr: 'Oteller ve Uçuşlar',
          id: 'Hotel dan Penerbangan',
          hi: 'होटल और उड़ानें',
          ur: 'ہوٹلز اور گھر',
          fr: 'Hôtels et vols',
          bn: 'হোটেল ও ফ্লাইট',
        );
      case 'flights':
      default:
        return _t3(
          context,
          ar: 'الطيران',
          en: 'Flights',
          es: 'Vuelos',
          tr: 'Uçuşlar',
          id: 'Penerbangan',
          hi: 'उड़ानें',
          ur: 'پروازیں',
          fr: 'Vols',
          bn: 'ফ্লাইট',
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final categories = ['hotels', 'flights', 'flightHotel', 'carRentals'];
    final faqs = _faqsFor(context, _activeCategory);
    final tags = _tagsFor(_activeCategory);

    return Scaffold(
      appBar: const AppBanner(),
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            // هيدر بعنوان "Customer support"
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSizes.lg),
              color: AppColors.primaryDark,
              child: Row(
                children: [
                  Expanded(
                    child: RichText(
                      text: TextSpan(
                        style: const TextStyle(fontSize: 30, fontWeight: FontWeight.bold, color: Colors.white),
                        children: [
                          TextSpan(
                            text: _t3(
                              context,
                              ar: 'دعم العملاء',
                              en: 'Customer support',
                              es: 'Atención al cliente',
                              tr: 'Müşteri desteği',
                              id: 'Dukungan pelanggan',
                              hi: 'ग्राहक सहायता',
                              ur: 'کسٹمر سپورٹ',
                              fr: 'Assistance client',
                              bn: 'গ্রাহক সহায়তা',
                            ),
                          ),
                          const TextSpan(text: ' .', style: TextStyle(color: Colors.amber)),
                        ],
                      ),
                    ),
                  ),
                  const Icon(Icons.support_agent, size: 64, color: Colors.white70),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSizes.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _t3(
                          context,
                          ar: 'دردشة الخدمة',
                          en: 'Service chat',
                          es: 'Chat de servicio',
                          tr: 'Hizmet sohbeti',
                          id: 'Obrolan layanan',
                          hi: 'सेवा चैट',
                          ur: 'سروس چیٹ',
                          fr: 'Chat de service',
                          bn: 'সেবা চ্যাট',
                        ),
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSizes.md),
                  // تبويبات الفئات
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: categories.map((cat) {
                        final isActive = cat == _activeCategory;
                        return Padding(
                          padding: const EdgeInsetsDirectional.only(end: AppSizes.sm),
                          child: GestureDetector(
                            onTap: () => setState(() => _activeCategory = cat),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              decoration: BoxDecoration(
                                color: isActive ? AppColors.primaryDark : Colors.transparent,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: AppColors.divider),
                              ),
                              child: Text(
                                _categoryLabel(context, cat),
                                style: TextStyle(
                                  color: isActive ? Colors.white : AppColors.textPrimary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: AppSizes.md),
                  // كروت الأسئلة الشائعة (2 عمود)
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final isWide = constraints.maxWidth > 700;
                      if (!isWide) {
                        return Column(
                          children: faqs.map((f) => _FaqTile(item: f)).toList(),
                        );
                      }
                      final rows = <Widget>[];
                      for (var i = 0; i < faqs.length; i += 2) {
                        final second = i + 1 < faqs.length ? faqs[i + 1] : null;
                        rows.add(
                          IntrinsicHeight(
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Expanded(child: _FaqTile(item: faqs[i])),
                                const SizedBox(width: AppSizes.md),
                                Expanded(
                                  child: second != null ? _FaqTile(item: second) : const SizedBox.shrink(),
                                ),
                              ],
                            ),
                          ),
                        );
                        rows.add(const SizedBox(height: AppSizes.sm));
                      }
                      return Column(children: rows);
                    },
                  ),
                  const SizedBox(height: AppSizes.lg),
                  Text(
                    _t3(
                      context,
                      ar: 'المزيد من أسئلة ${_categoryLabel(context, _activeCategory)}',
                      en: 'More ${_categoryLabel(context, _activeCategory)} FAQ',
                      es: 'Más preguntas de ${_categoryLabel(context, _activeCategory)}',
                      tr: 'Daha fazla ${_categoryLabel(context, _activeCategory)} SSS',
                      id: 'Lebih banyak FAQ ${_categoryLabel(context, _activeCategory)}',
                      hi: 'अधिक ${_categoryLabel(context, _activeCategory)} सवाल-जवाब',
                      ur: 'مزید ${_categoryLabel(context, _activeCategory)} سوالات',
                      fr: 'Plus de FAQ ${_categoryLabel(context, _activeCategory)}',
                      bn: 'আরও ${_categoryLabel(context, _activeCategory)} প্রশ্নোত্তর',
                    ),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: AppSizes.sm),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ...tags.map(
                            (tag) => Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: AppColors.background,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(tag, style: const TextStyle(fontSize: 13)),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Text('...'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            // شريط الوصول السريع تحت
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: _QuickAccessButton(
                      icon: Icons.headset_mic_outlined,
                      label: _t3(
                        context,
                        ar: 'دردشة',
                        en: 'Chat',
                        es: 'Chat',
                        tr: 'Sohbet',
                        id: 'Chat',
                        hi: 'चैट',
                        ur: 'چیٹ',
                        fr: 'Chat',
                        bn: 'চ্যাট',
                      ),
                      onTap: () => _comingSoon(context),
                    ),
                  ),
                  const VerticalDivider(width: 1),
                  Expanded(
                    child: _QuickAccessButton(
                      icon: Icons.call_outlined,
                      label: _t3(
                        context,
                        ar: 'اتصل بنا',
                        en: 'Call us',
                        es: 'Llámanos',
                        tr: 'Bizi arayın',
                        id: 'Hubungi kami',
                        hi: 'हमें कॉल करें',
                        ur: 'ہمیں کال کریں',
                        fr: 'Appelez-nous',
                        bn: 'আমাদের কল করুন',
                      ),
                      onTap: () => _comingSoon(context),
                    ),
                  ),
                  const VerticalDivider(width: 1),
                  Expanded(
                    child: _QuickAccessButton(
                      icon: Icons.info_outline,
                      label: 'FAQ',
                      onTap: () => _comingSoon(context),
                    ),
                  ),
                  const VerticalDivider(width: 1),
                  Expanded(
                    child: _QuickAccessButton(
                      icon: Icons.sos_outlined,
                      label: _t3(
                        context,
                        ar: 'مساعدة طارئة',
                        en: 'Emergency assistance',
                        es: 'Asistencia de emergencia',
                        tr: 'Acil yardım',
                        id: 'Bantuan darurat',
                        hi: 'आपातकालीन सहायता',
                        ur: 'ہنگامی امداد',
                        fr: 'Assistance d\'urgence',
                        bn: 'জরুরি সহায়তা',
                      ),
                      onTap: () => _comingSoon(context),
                    ),
                  ),
                ],
              ),
            ),
            const AppFooter(),
          ],
        ),
      ),
    );
  }
}

class _FaqTile extends StatefulWidget {
  final _FaqItem item;
  const _FaqTile({required this.item});

  @override
  State<_FaqTile> createState() => _FaqTileState();
}

class _FaqTileState extends State<_FaqTile> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSizes.sm),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => setState(() => _expanded = !_expanded),
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.item.question,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                  Icon(_expanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down),
                ],
              ),
              if (_expanded) ...[
                const SizedBox(height: 8),
                Text(
                  widget.item.answer,
                  style: const TextStyle(color: AppColors.textSecondary, height: 1.4),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickAccessButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickAccessButton({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSizes.md),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: AppColors.primary),
            const SizedBox(height: 6),
            Text(label, style: const TextStyle(fontSize: 13), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}