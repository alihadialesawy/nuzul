import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';

class _InfoSection {
  final String titleEn;
  final String titleAr;
  final String bodyEn;
  final String bodyAr;
  const _InfoSection({
    required this.titleEn,
    required this.titleAr,
    required this.bodyEn,
    required this.bodyAr,
  });
}

const String _e = 'support@flynoom.com';

/// ترجمات الصفحة للغات السبع الأخرى.
/// ترتيب كل قائمة: [عنوان الشريط، العنوان الرئيسي، المقدمة، ثم (عنوان، نص) لكل قسم بنفس ترتيب _sections].
/// ⚠️ أي تعديل على معنى قسم في _sections (الإنجليزي/العربي) يجب أن يُنقل هنا أيضًا،
/// لأن كل جملة في هذه الصفحة وعد للعميل.
const Map<String, List<String>> _i18n = {
  'es': [
    "Cómo trabajamos",
    "Cómo funciona Flynoom",
    "Queremos que sepas exactamente qué estás pagando, a quién le compras, cómo ganamos dinero y cómo te mostramos los resultados.",
    "Somos una agencia de viajes, no un hotel",
    "Flynoom es operado por FLYNOOM LLC, una agencia de viajes en línea con sede en Michigan. No somos dueños de ningún hotel. Vendemos habitaciones de hotel suministradas por terceros a través de nuestro socio HOTELBEDS, una de las mayores redes de suministro hotelero del mundo. El hotel es quien presta la estancia.",
    "Precios y disponibilidad en tiempo real",
    "Cada vez que buscas, solicitamos a nuestro proveedor las habitaciones y tarifas actuales. Antes de que pagues, volvemos a comprobar la tarifa exacta. Si el precio ha cambiado, te mostramos el nuevo precio antes de cobrarte y tú decides si continúas.",
    "Precios con todo incluido, sin cargos ocultos",
    "Los precios se muestran en dólares estadounidenses. El precio total incluye todo lo que debes pagar por la estancia. Algunos hoteles cobran cargos obligatorios en el establecimiento, como tarifas de resort o impuestos locales; los incluimos en el total y los indicamos como «Pago en el hotel», para que veas el costo completo antes de reservar. No añadimos ningún cargo de reserva aparte.",
    "Cómo ganamos dinero",
    "Nuestro proveedor nos vende las habitaciones a precio mayorista. El precio que ves incluye nuestro margen sobre ese precio mayorista, junto con el costo del procesamiento de pagos. Ese margen es la forma en que Flynoom gana dinero. No te cobramos ningún cargo de servicio adicional al pagar.",
    "Cómo se ordenan los resultados",
    "Los hoteles no pueden pagar a Flynoom para aparecer más arriba en tus resultados de búsqueda, y no mostramos anuncios patrocinados ni de pago. Los resultados se basan en tu destino, tus fechas y el número de huéspedes, y en las habitaciones que nuestro proveedor tiene disponibles para tu búsqueda.",
    "Categoría de estrellas e información del hotel",
    "La categoría de estrellas que se muestra para cada hotel es su categoría oficial según nuestro proveedor. No es una puntuación de opiniones de huéspedes. Las fotos, descripciones y servicios del hotel también provienen de nuestro proveedor y del hotel. Actualmente no publicamos opiniones de huéspedes.",
    "Pago seguro: solo se te cobra tras la confirmación",
    "Los pagos los procesa Stripe, y Flynoom nunca guarda el número de tu tarjeta. Al reservar, hacemos una retención temporal en tu tarjeta. Solo cobramos el pago después de que el hotel confirma tu reserva. Si la reserva no se puede confirmar, liberamos la retención y no se te cobra nada.",
    "Después de reservar",
    "Recibes un correo de confirmación con tu bono y tu referencia de reserva, y la reserva aparece en «Mis reservas». Allí puedes ver el bono y cancelar en línea las reservas que lo permitan. Antes de confirmar una cancelación, te mostramos el cargo y el reembolso exactos. Los reembolsos se hacen a tu tarjeta, normalmente en un plazo de 5 a 10 días hábiles.",
    "Ayuda cuando la necesites",
    "Si tienes una pregunta o un problema con una reserva, escríbenos a $_e con tu referencia de reserva. Procuramos responder en un plazo de dos días hábiles y gestionaremos el asunto con el hotel en tu nombre. Si algo va mal durante tu estancia, avisa también al hotel de inmediato.",
  ],
  'tr': [
    "Nasıl çalışıyoruz",
    "Flynoom nasıl çalışır",
    "Neye ödeme yaptığınızı, kimden satın aldığınızı, nasıl para kazandığımızı ve sonuçları size nasıl gösterdiğimizi tam olarak bilmenizi istiyoruz.",
    "Biz bir seyahat acentesiyiz, otel değil",
    "Flynoom, Michigan merkezli bir çevrim içi seyahat acentesi olan FLYNOOM LLC tarafından işletilir. Hiçbir otelin sahibi değiliz. Dünyanın en büyük otel tedarik ağlarından biri olan iş ortağımız HOTELBEDS aracılığıyla başkalarının sağladığı otel odalarını satıyoruz. Konaklamanın kendisini otel sağlar.",
    "Anlık fiyatlar ve müsaitlik",
    "Her aramanızda tedarikçimizden güncel odaları ve fiyatları talep ederiz. Ödeme yapmadan önce tam fiyatı yeniden kontrol ederiz. Fiyat değiştiyse, sizden ücret alınmadan önce yeni fiyatı gösteririz ve devam edip etmeyeceğinize siz karar verirsiniz.",
    "Her şey dahil fiyatlar, gizli ücret yok",
    "Fiyatlar ABD doları cinsinden gösterilir. Toplam fiyat, konaklama için ödemeniz gereken her şeyi içerir. Bazı oteller tesiste ödenen tatil köyü ücreti veya yerel vergiler gibi zorunlu ücretler alır; bunları toplama dahil eder ve “Otelde ödenecek” olarak listeleriz, böylece rezervasyondan önce tam maliyeti görürsünüz. Ayrı bir rezervasyon ücreti eklemeyiz.",
    "Nasıl para kazanıyoruz",
    "Tedarikçimiz odaları bize toptan fiyatla satar. Gördüğünüz fiyat, bu toptan fiyatın üzerine eklenen kâr payımızı ve ödeme işleme maliyetini içerir. Flynoom bu kâr payıyla para kazanır. Ödeme sırasında sizden ek hizmet ücreti almayız.",
    "Sonuçlar nasıl sıralanır",
    "Oteller, arama sonuçlarınızda daha üstte görünmek için Flynoom’a ödeme yapamaz ve sponsorlu ya da ücretli ilan göstermeyiz. Sonuçlar; varış yerinize, tarihlerinize ve misafir sayısına, ayrıca tedarikçimizin aramanız için müsait odalarına göre belirlenir.",
    "Yıldız sınıfı ve otel bilgileri",
    "Her otel için gösterilen yıldız sınıfı, tedarikçimizin bildirdiği resmî kategorisidir. Misafir değerlendirme puanı değildir. Otel fotoğrafları, açıklamaları ve olanakları da tedarikçimizden ve otelden gelir. Şu anda misafir yorumları yayınlamıyoruz.",
    "Güvenli ödeme: yalnızca onaydan sonra ücret alınır",
    "Ödemeler Stripe tarafından işlenir ve Flynoom kart numaranızı asla saklamaz. Rezervasyon yaptığınızda kartınıza geçici bir provizyon koyarız. Ödemeyi yalnızca otel rezervasyonunuzu onayladıktan sonra tahsil ederiz. Rezervasyon onaylanamazsa provizyonu kaldırırız ve sizden ücret alınmaz.",
    "Rezervasyondan sonra",
    "Belgeniz ve rezervasyon numaranızla birlikte bir onay e-postası alırsınız ve rezervasyonunuz “Rezervasyonlarım” bölümünde görünür. Belgenizi orada görüntüleyebilir ve uygun rezervasyonları çevrim içi iptal edebilirsiniz. Bir iptali onaylamadan önce size tam ücreti ve iade tutarını gösteririz. İadeler kartınıza yapılır ve genellikle 5 ila 10 iş günü içinde görünür.",
    "İhtiyacınız olduğunda yardım",
    "Bir rezervasyonla ilgili sorunuz veya sorununuz varsa, rezervasyon numaranızla birlikte $_e adresine yazın. İki iş günü içinde yanıt vermeyi hedefliyoruz ve sizin adınıza otelle ilgileneceğiz. Konaklamanız sırasında bir sorun olursa, oteli de hemen bilgilendirin.",
  ],
  'id': [
    "Cara kami bekerja",
    "Cara kerja Flynoom",
    "Kami ingin Anda tahu persis apa yang Anda bayar, dari siapa Anda membeli, bagaimana kami menghasilkan uang, dan bagaimana kami menampilkan hasil pencarian.",
    "Kami agen perjalanan, bukan hotel",
    "Flynoom dioperasikan oleh FLYNOOM LLC, agen perjalanan online yang berbasis di Michigan. Kami tidak memiliki hotel apa pun. Kami menjual kamar hotel yang disediakan pihak lain melalui mitra kami HOTELBEDS, salah satu jaringan pasokan hotel terbesar di dunia. Hotel yang menyediakan masa menginap itu sendiri.",
    "Harga dan ketersediaan langsung",
    "Setiap kali Anda mencari, kami meminta kamar dan tarif terkini dari pemasok kami. Sebelum Anda membayar, kami memeriksa ulang tarif yang tepat. Jika harga berubah, kami menampilkan harga baru sebelum Anda ditagih, dan Anda yang memutuskan untuk melanjutkan atau tidak.",
    "Harga sudah termasuk semuanya, tanpa biaya tersembunyi",
    "Harga ditampilkan dalam dolar AS. Harga total mencakup semua yang harus Anda bayar untuk masa menginap. Beberapa hotel mengenakan biaya wajib di properti, seperti biaya resor atau pajak lokal; kami memasukkannya ke dalam total dan mencantumkannya sebagai “Dibayar di hotel”, sehingga Anda melihat biaya lengkap sebelum memesan. Kami tidak menambahkan biaya pemesanan terpisah.",
    "Cara kami menghasilkan uang",
    "Pemasok kami menjual kamar kepada kami dengan harga grosir. Harga yang Anda lihat mencakup margin kami di atas harga grosir tersebut, beserta biaya pemrosesan pembayaran. Margin itulah sumber pendapatan Flynoom. Kami tidak mengenakan biaya layanan tambahan apa pun saat Anda membayar.",
    "Cara hasil diurutkan",
    "Hotel tidak dapat membayar Flynoom untuk tampil lebih tinggi dalam hasil pencarian Anda, dan kami tidak menampilkan listing bersponsor atau berbayar. Hasil didasarkan pada tujuan, tanggal, dan jumlah tamu Anda, serta kamar yang tersedia dari pemasok kami untuk pencarian Anda.",
    "Peringkat bintang dan informasi hotel",
    "Peringkat bintang yang ditampilkan untuk setiap hotel adalah kategori resminya sebagaimana diberikan oleh pemasok kami. Ini bukan skor ulasan tamu. Foto, deskripsi, dan fasilitas hotel juga berasal dari pemasok kami dan hotel. Saat ini kami tidak menerbitkan ulasan tamu.",
    "Pembayaran aman: Anda hanya ditagih setelah konfirmasi",
    "Pembayaran diproses oleh Stripe, dan Flynoom tidak pernah menyimpan nomor kartu Anda. Saat Anda memesan, kami melakukan penahanan sementara pada kartu Anda. Kami menarik pembayaran hanya setelah hotel mengonfirmasi pemesanan Anda. Jika pemesanan tidak dapat dikonfirmasi, kami melepaskan penahanan dan Anda tidak ditagih.",
    "Setelah Anda memesan",
    "Anda menerima email konfirmasi berisi voucher dan kode pemesanan, dan pemesanan Anda muncul di “Pesanan Saya”. Di sana Anda dapat melihat voucher dan membatalkan pemesanan yang memenuhi syarat secara online. Sebelum Anda mengonfirmasi pembatalan, kami menampilkan biaya dan jumlah pengembalian dana yang tepat. Dana dikembalikan ke kartu Anda, biasanya dalam 5 hingga 10 hari kerja.",
    "Bantuan saat Anda membutuhkannya",
    "Jika Anda memiliki pertanyaan atau masalah dengan pemesanan, kirim email ke $_e dengan menyertakan kode pemesanan Anda. Kami berupaya membalas dalam dua hari kerja dan akan menangani masalah tersebut dengan hotel atas nama Anda. Jika ada masalah selama menginap, segera beri tahu hotel juga.",
  ],
  'hi': [
    "हम कैसे काम करते हैं",
    "Flynoom कैसे काम करता है",
    "हम चाहते हैं कि आप ठीक-ठीक जानें कि आप किस चीज़ का भुगतान कर रहे हैं, किससे ख़रीद रहे हैं, हम पैसे कैसे कमाते हैं, और हम आपको नतीजे कैसे दिखाते हैं।",
    "हम ट्रैवल एजेंसी हैं, होटल नहीं",
    "Flynoom का संचालन FLYNOOM LLC करती है, जो मिशिगन स्थित एक ऑनलाइन ट्रैवल एजेंसी है। हम किसी होटल के मालिक नहीं हैं। हम अपने साझेदार HOTELBEDS के माध्यम से दूसरों द्वारा उपलब्ध कराए गए होटल कमरे बेचते हैं, जो दुनिया के सबसे बड़े होटल आपूर्ति नेटवर्क में से एक है। ठहराव स्वयं होटल प्रदान करता है।",
    "लाइव कीमतें और उपलब्धता",
    "हर बार जब आप खोजते हैं, हम अपने आपूर्तिकर्ता से मौजूदा कमरे और रेट माँगते हैं। भुगतान से पहले हम सटीक रेट दोबारा जाँचते हैं। अगर कीमत बदल गई हो, तो आपसे शुल्क लेने से पहले हम नई कीमत दिखाते हैं, और आगे बढ़ना है या नहीं, यह आप तय करते हैं।",
    "सब कुछ शामिल कीमतें, कोई छिपा शुल्क नहीं",
    "कीमतें अमेरिकी डॉलर में दिखाई जाती हैं। कुल कीमत में ठहराव के लिए आपको चुकाई जाने वाली हर चीज़ शामिल है। कुछ होटल वहीं पर अनिवार्य शुल्क लेते हैं, जैसे रिज़ॉर्ट शुल्क या स्थानीय कर; हम इन्हें कुल में शामिल करते हैं और “होटल में देय” के रूप में दिखाते हैं, ताकि बुकिंग से पहले आप पूरी लागत देख सकें। हम अलग से कोई बुकिंग शुल्क नहीं जोड़ते।",
    "हम पैसे कैसे कमाते हैं",
    "हमारा आपूर्तिकर्ता हमें कमरे थोक कीमत पर बेचता है। आप जो कीमत देखते हैं उसमें उस थोक कीमत के ऊपर हमारा मार्जिन और भुगतान प्रोसेसिंग की लागत शामिल है। यही मार्जिन Flynoom की कमाई है। भुगतान के समय हम आपसे कोई अतिरिक्त सेवा शुल्क नहीं लेते।",
    "नतीजे किस क्रम में दिखते हैं",
    "होटल आपके खोज नतीजों में ऊपर दिखने के लिए Flynoom को भुगतान नहीं कर सकते, और हम प्रायोजित या सशुल्क लिस्टिंग नहीं दिखाते। नतीजे आपके गंतव्य, तारीखों और मेहमानों की संख्या पर, और आपकी खोज के लिए हमारे आपूर्तिकर्ता के पास उपलब्ध कमरों पर आधारित होते हैं।",
    "स्टार रेटिंग और होटल की जानकारी",
    "हर होटल के लिए दिखाई गई स्टार रेटिंग उसकी आधिकारिक श्रेणी है, जैसा हमारा आपूर्तिकर्ता बताता है। यह मेहमानों की समीक्षा का स्कोर नहीं है। होटल की तस्वीरें, विवरण और सुविधाएँ भी हमारे आपूर्तिकर्ता और होटल से आती हैं। फ़िलहाल हम मेहमानों की समीक्षाएँ प्रकाशित नहीं करते।",
    "सुरक्षित भुगतान: पुष्टि के बाद ही शुल्क",
    "भुगतान Stripe द्वारा संसाधित किए जाते हैं, और Flynoom कभी आपका कार्ड नंबर संग्रहीत नहीं करता। बुकिंग करते समय हम आपके कार्ड पर अस्थायी होल्ड लगाते हैं। होटल द्वारा आपकी बुकिंग की पुष्टि के बाद ही हम भुगतान लेते हैं। अगर बुकिंग की पुष्टि नहीं हो पाती, तो हम होल्ड हटा देते हैं और आपसे कोई शुल्क नहीं लिया जाता।",
    "बुकिंग के बाद",
    "आपको वाउचर और बुकिंग संदर्भ के साथ एक पुष्टि ईमेल मिलता है, और आपकी बुकिंग “मेरी बुकिंग” में दिखाई देती है। वहाँ आप वाउचर देख सकते हैं और पात्र बुकिंग ऑनलाइन रद्द कर सकते हैं। रद्दीकरण की पुष्टि से पहले हम आपको सटीक शुल्क और रिफ़ंड दिखाते हैं। रिफ़ंड आपके कार्ड पर आम तौर पर 5 से 10 कार्यदिवसों में वापस आता है।",
    "ज़रूरत पड़ने पर मदद",
    "अगर किसी बुकिंग को लेकर आपका कोई सवाल या समस्या है, तो अपने बुकिंग संदर्भ के साथ हमें $_e पर ईमेल करें। हम दो कार्यदिवसों में जवाब देने की कोशिश करते हैं और आपकी ओर से होटल से बात करेंगे। ठहराव के दौरान कुछ गलत हो, तो होटल को भी तुरंत बताएँ।",
  ],
  'ur': [
    "ہم کیسے کام کرتے ہیں",
    "Flynoom کیسے کام کرتا ہے",
    "ہم چاہتے ہیں کہ آپ ٹھیک ٹھیک جانیں کہ آپ کس چیز کی ادائیگی کر رہے ہیں، کس سے خرید رہے ہیں، ہم پیسے کیسے کماتے ہیں، اور ہم آپ کو نتائج کیسے دکھاتے ہیں۔",
    "ہم ٹریول ایجنسی ہیں، ہوٹل نہیں",
    "Flynoom کو FLYNOOM LLC چلاتی ہے، جو مشی گن میں قائم ایک آن لائن ٹریول ایجنسی ہے۔ ہم کسی ہوٹل کے مالک نہیں ہیں۔ ہم اپنے پارٹنر HOTELBEDS کے ذریعے دوسروں کے فراہم کردہ ہوٹل کمرے فروخت کرتے ہیں، جو دنیا کے سب سے بڑے ہوٹل سپلائی نیٹ ورکس میں سے ایک ہے۔ قیام خود ہوٹل فراہم کرتا ہے۔",
    "براہ راست قیمتیں اور دستیابی",
    "ہر بار جب آپ تلاش کرتے ہیں، ہم اپنے سپلائر سے موجودہ کمرے اور ریٹس طلب کرتے ہیں۔ ادائیگی سے پہلے ہم درست ریٹ دوبارہ چیک کرتے ہیں۔ اگر قیمت بدل گئی ہو تو رقم وصول کرنے سے پہلے ہم آپ کو نئی قیمت دکھاتے ہیں، اور آگے بڑھنے کا فیصلہ آپ کرتے ہیں۔",
    "سب کچھ شامل قیمتیں، کوئی پوشیدہ فیس نہیں",
    "قیمتیں امریکی ڈالر میں دکھائی جاتی ہیں۔ کل قیمت میں قیام کے لیے آپ کی ادا کی جانے والی ہر چیز شامل ہے۔ بعض ہوٹل وہیں لازمی فیسیں لیتے ہیں، جیسے ریزورٹ فیس یا مقامی ٹیکس؛ ہم انہیں کل میں شامل کرتے ہیں اور “ہوٹل میں قابل ادائیگی” کے طور پر دکھاتے ہیں، تاکہ بکنگ سے پہلے آپ پوری لاگت دیکھ سکیں۔ ہم کوئی الگ بکنگ فیس شامل نہیں کرتے۔",
    "ہم پیسے کیسے کماتے ہیں",
    "ہمارا سپلائر ہمیں کمرے ہول سیل قیمت پر فروخت کرتا ہے۔ آپ جو قیمت دیکھتے ہیں اس میں اس ہول سیل قیمت کے اوپر ہمارا مارجن اور ادائیگی کی پروسیسنگ کی لاگت شامل ہے۔ یہی مارجن Flynoom کی آمدنی ہے۔ ادائیگی کے وقت ہم آپ سے کوئی اضافی سروس فیس نہیں لیتے۔",
    "نتائج کس ترتیب سے دکھائے جاتے ہیں",
    "ہوٹل آپ کے تلاش کے نتائج میں اوپر آنے کے لیے Flynoom کو ادائیگی نہیں کر سکتے، اور ہم سپانسرڈ یا معاوضہ والی لسٹنگز نہیں دکھاتے۔ نتائج آپ کی منزل، تاریخوں اور مہمانوں کی تعداد پر، اور آپ کی تلاش کے لیے ہمارے سپلائر کے پاس دستیاب کمروں پر مبنی ہوتے ہیں۔",
    "اسٹار ریٹنگ اور ہوٹل کی معلومات",
    "ہر ہوٹل کے لیے دکھائی گئی اسٹار ریٹنگ اس کی سرکاری کیٹیگری ہے جیسا کہ ہمارا سپلائر فراہم کرتا ہے۔ یہ مہمانوں کے جائزوں کا اسکور نہیں ہے۔ ہوٹل کی تصاویر، تفصیلات اور سہولیات بھی ہمارے سپلائر اور ہوٹل سے آتی ہیں۔ فی الحال ہم مہمانوں کے جائزے شائع نہیں کرتے۔",
    "محفوظ ادائیگی: تصدیق کے بعد ہی رقم وصول کی جاتی ہے",
    "ادائیگیاں Stripe کے ذریعے پروسیس ہوتی ہیں، اور Flynoom کبھی آپ کا کارڈ نمبر محفوظ نہیں کرتا۔ بکنگ کرتے وقت ہم آپ کے کارڈ پر عارضی ہولڈ لگاتے ہیں۔ ہوٹل کی جانب سے آپ کی بکنگ کی تصدیق کے بعد ہی ہم ادائیگی وصول کرتے ہیں۔ اگر بکنگ کی تصدیق نہ ہو سکے تو ہم ہولڈ ختم کر دیتے ہیں اور آپ سے کوئی رقم نہیں لی جاتی۔",
    "بکنگ کے بعد",
    "آپ کو واؤچر اور بکنگ ریفرنس کے ساتھ تصدیقی ای میل ملتی ہے، اور آپ کی بکنگ “میری بکنگز” میں ظاہر ہوتی ہے۔ وہاں آپ واؤچر دیکھ سکتے ہیں اور اہل بکنگز آن لائن منسوخ کر سکتے ہیں۔ منسوخی کی تصدیق سے پہلے ہم آپ کو درست فیس اور واپسی کی رقم دکھاتے ہیں۔ رقم آپ کے کارڈ پر عموماً 5 سے 10 کاروباری دنوں میں واپس آتی ہے۔",
    "جب ضرورت ہو، مدد حاضر",
    "اگر کسی بکنگ کے بارے میں آپ کا کوئی سوال یا مسئلہ ہو تو اپنے بکنگ ریفرنس کے ساتھ ہمیں $_e پر ای میل کریں۔ ہم دو کاروباری دنوں میں جواب دینے کی کوشش کرتے ہیں اور آپ کی جانب سے ہوٹل سے رابطہ کریں گے۔ اگر قیام کے دوران کوئی مسئلہ ہو تو ہوٹل کو بھی فوراً بتائیں۔",
  ],
  'fr': [
    "Comment nous travaillons",
    "Comment fonctionne Flynoom",
    "Nous voulons que vous sachiez exactement ce que vous payez, auprès de qui vous achetez, comment nous gagnons de l’argent et comment nous vous présentons les résultats.",
    "Nous sommes une agence de voyages, pas un hôtel",
    "Flynoom est exploité par FLYNOOM LLC, une agence de voyages en ligne basée dans le Michigan. Nous ne possédons aucun hôtel. Nous vendons des chambres d’hôtel fournies par des tiers via notre partenaire HOTELBEDS, l’un des plus grands réseaux de distribution hôtelière au monde. C’est l’hôtel qui fournit le séjour lui-même.",
    "Prix et disponibilités en temps réel",
    "À chaque recherche, nous demandons à notre fournisseur les chambres et tarifs actuels. Avant que vous payiez, nous vérifions à nouveau le tarif exact. Si le prix a changé, nous vous montrons le nouveau prix avant tout débit, et vous décidez de continuer ou non.",
    "Prix tout compris, sans frais cachés",
    "Les prix sont affichés en dollars américains. Le prix total comprend tout ce que vous devez payer pour le séjour. Certains hôtels facturent des frais obligatoires sur place, comme des frais de resort ou des taxes locales ; nous les incluons dans le total et les indiquons comme « À payer à l’hôtel », pour que vous voyiez le coût complet avant de réserver. Nous n’ajoutons aucuns frais de réservation séparés.",
    "Comment nous gagnons de l’argent",
    "Notre fournisseur nous vend les chambres à un prix de gros. Le prix que vous voyez comprend notre marge sur ce prix de gros, ainsi que le coût du traitement des paiements. Cette marge est la façon dont Flynoom gagne de l’argent. Nous ne vous facturons aucuns frais de service supplémentaires au moment du paiement.",
    "Comment les résultats sont classés",
    "Les hôtels ne peuvent pas payer Flynoom pour apparaître plus haut dans vos résultats de recherche, et nous n’affichons pas d’annonces sponsorisées ou payantes. Les résultats dépendent de votre destination, de vos dates et du nombre de voyageurs, ainsi que des chambres que notre fournisseur a de disponibles pour votre recherche.",
    "Classement par étoiles et informations sur l’hôtel",
    "Le classement par étoiles affiché pour chaque hôtel est sa catégorie officielle telle que fournie par notre fournisseur. Ce n’est pas une note d’avis clients. Les photos, descriptions et équipements des hôtels proviennent également de notre fournisseur et de l’hôtel. Nous ne publions pas d’avis clients pour le moment.",
    "Paiement sécurisé : vous n’êtes débité qu’après confirmation",
    "Les paiements sont traités par Stripe, et Flynoom ne conserve jamais votre numéro de carte. Lorsque vous réservez, nous plaçons une autorisation temporaire sur votre carte. Nous ne prélevons le paiement qu’après la confirmation de votre réservation par l’hôtel. Si la réservation ne peut pas être confirmée, nous levons l’autorisation et vous n’êtes pas débité.",
    "Après votre réservation",
    "Vous recevez un e-mail de confirmation avec votre bon et votre référence de réservation, et votre réservation apparaît dans « Mes réservations ». Vous pouvez y consulter le bon et annuler en ligne les réservations éligibles. Avant de confirmer une annulation, nous vous indiquons les frais et le remboursement exacts. Les remboursements sont versés sur votre carte, généralement sous 5 à 10 jours ouvrés.",
    "De l’aide quand vous en avez besoin",
    "Si vous avez une question ou un problème concernant une réservation, écrivez-nous à $_e en indiquant votre référence de réservation. Nous nous efforçons de répondre sous deux jours ouvrés et nous traiterons la question avec l’hôtel en votre nom. Si quelque chose ne va pas pendant votre séjour, prévenez aussi l’hôtel immédiatement.",
  ],
  'bn': [
    "আমরা কীভাবে কাজ করি",
    "Flynoom কীভাবে কাজ করে",
    "আমরা চাই আপনি ঠিক জানুন আপনি কীসের জন্য অর্থ দিচ্ছেন, কার কাছ থেকে কিনছেন, আমরা কীভাবে আয় করি এবং আপনাকে ফলাফল কীভাবে দেখাই।",
    "আমরা ট্রাভেল এজেন্সি, হোটেল নই",
    "Flynoom পরিচালনা করে FLYNOOM LLC, মিশিগানভিত্তিক একটি অনলাইন ট্রাভেল এজেন্সি। আমরা কোনো হোটেলের মালিক নই। আমাদের অংশীদার HOTELBEDS-এর মাধ্যমে আমরা অন্যদের সরবরাহ করা হোটেল রুম বিক্রি করি, যা বিশ্বের অন্যতম বৃহৎ হোটেল সরবরাহ নেটওয়ার্ক। থাকার ব্যবস্থা হোটেল নিজেই প্রদান করে।",
    "লাইভ মূল্য ও প্রাপ্যতা",
    "আপনি যতবার অনুসন্ধান করেন, আমরা আমাদের সরবরাহকারীর কাছ থেকে বর্তমান রুম ও রেট চেয়ে নিই। অর্থ পরিশোধের আগে আমরা সঠিক রেট আবার যাচাই করি। মূল্য বদলে গেলে আপনাকে চার্জ করার আগে নতুন মূল্য দেখাই, এবং এগোবেন কি না তা আপনিই ঠিক করেন।",
    "সবকিছু অন্তর্ভুক্ত মূল্য, কোনো লুকানো ফি নেই",
    "মূল্য মার্কিন ডলারে দেখানো হয়। মোট মূল্যে থাকার জন্য আপনাকে যা কিছু দিতে হবে সবই অন্তর্ভুক্ত। কিছু হোটেল সেখানে বাধ্যতামূলক ফি নেয়, যেমন রিসোর্ট ফি বা স্থানীয় কর; আমরা সেগুলো মোট মূল্যে অন্তর্ভুক্ত করি এবং “হোটেলে পরিশোধযোগ্য” হিসেবে দেখাই, যাতে বুকিংয়ের আগে আপনি পূর্ণ খরচ দেখতে পান। আমরা আলাদা কোনো বুকিং ফি যোগ করি না।",
    "আমরা কীভাবে আয় করি",
    "আমাদের সরবরাহকারী আমাদের কাছে পাইকারি মূল্যে রুম বিক্রি করে। আপনি যে মূল্য দেখেন তাতে সেই পাইকারি মূল্যের ওপর আমাদের মার্জিন এবং পেমেন্ট প্রক্রিয়াকরণের খরচ অন্তর্ভুক্ত। এই মার্জিনই Flynoom-এর আয়। অর্থ পরিশোধের সময় আমরা আপনার কাছ থেকে কোনো অতিরিক্ত সার্ভিস ফি নিই না।",
    "ফলাফল কীভাবে সাজানো হয়",
    "হোটেলগুলো আপনার অনুসন্ধানের ফলাফলে ওপরে দেখানোর জন্য Flynoom-কে অর্থ দিতে পারে না, এবং আমরা স্পনসর্ড বা পেইড লিস্টিং দেখাই না। ফলাফল নির্ভর করে আপনার গন্তব্য, তারিখ ও অতিথির সংখ্যার ওপর, এবং আপনার অনুসন্ধানের জন্য আমাদের সরবরাহকারীর কাছে উপলব্ধ রুমের ওপর।",
    "স্টার রেটিং ও হোটেলের তথ্য",
    "প্রতিটি হোটেলের জন্য দেখানো স্টার রেটিং হলো আমাদের সরবরাহকারীর দেওয়া তার অফিসিয়াল শ্রেণি। এটি অতিথিদের রিভিউ স্কোর নয়। হোটেলের ছবি, বিবরণ ও সুবিধাও আমাদের সরবরাহকারী ও হোটেল থেকে আসে। বর্তমানে আমরা অতিথিদের রিভিউ প্রকাশ করি না।",
    "নিরাপদ পেমেন্ট: নিশ্চিতকরণের পরেই চার্জ",
    "পেমেন্ট প্রক্রিয়া করে Stripe, এবং Flynoom কখনো আপনার কার্ড নম্বর সংরক্ষণ করে না। বুকিংয়ের সময় আমরা আপনার কার্ডে একটি সাময়িক হোল্ড রাখি। হোটেল আপনার বুকিং নিশ্চিত করার পরেই আমরা অর্থ নিই। বুকিং নিশ্চিত করা না গেলে আমরা হোল্ড তুলে নিই এবং আপনাকে চার্জ করা হয় না।",
    "বুকিংয়ের পরে",
    "আপনি ভাউচার ও বুকিং রেফারেন্সসহ একটি নিশ্চিতকরণ ইমেইল পান, এবং আপনার বুকিং “আমার বুকিং”-এ দেখা যায়। সেখানে আপনি ভাউচার দেখতে এবং যোগ্য বুকিং অনলাইনে বাতিল করতে পারেন। বাতিল নিশ্চিত করার আগে আমরা সঠিক ফি ও ফেরতের পরিমাণ দেখাই। অর্থ আপনার কার্ডে ফেরত যায়, সাধারণত 5 থেকে 10 কার্যদিবসের মধ্যে।",
    "প্রয়োজনে সাহায্য",
    "কোনো বুকিং নিয়ে প্রশ্ন বা সমস্যা থাকলে আপনার বুকিং রেফারেন্সসহ $_e-এ আমাদের ইমেইল করুন। আমরা দুই কার্যদিবসের মধ্যে উত্তর দেওয়ার চেষ্টা করি এবং আপনার পক্ষে হোটেলের সঙ্গে যোগাযোগ করব। থাকার সময় কোনো সমস্যা হলে হোটেলকেও সঙ্গে সঙ্গে জানান।",
  ],
};

/// كيف نعمل — شرح شفاف لطريقة عمل Flynoom وكيف تربح وكيف ترتّب النتائج.
///
/// ⚠️ كل جملة هنا وعد للعميل، ويجب أن تبقى مطابقة للنظام:
///   • "How we make money": السعر يشمل هامشنا (HOTELBEDS_MARKUP_PERCENT). لا رسوم حجز منفصلة.
///   • "How results are ordered": لا يوجد ترتيب مدفوع. إن أضفت يومًا "Sponsored"
///     أو ترتيبًا مقابل عمولة أعلى، يجب تعديل هذا القسم ووضع علامة واضحة على النتائج.
///   • "Ratings": نعرض تصنيف النجوم الرسمي من المزوّد فقط، لا تقييمات نزلاء.
/// الترجمات السبع الأخرى في _i18n أعلاه؛ أي تعديل هنا يجب أن يُنقل إليها.
class HowWeWorkPage extends StatelessWidget {
  const HowWeWorkPage({super.key});

  static const String _contactEmail = _e;

  static const List<_InfoSection> _sections = [
    _InfoSection(
      titleEn: 'We are a travel agency, not a hotel',
      titleAr: 'نحن وكالة سفر، لسنا فندقًا',
      bodyEn:
      'Flynoom is operated by FLYNOOM LLC, an online travel agency based in Michigan. We do not own any hotels. We sell hotel rooms supplied by others through our partner HOTELBEDS, one of the world\'s largest hotel supply networks. The hotel provides the stay itself.',
      bodyAr:
      'تدير Flynoom شركةُ FLYNOOM LLC، وهي وكالة سفر إلكترونية مقرها ميشيغان. لا نمتلك أي فنادق، بل نبيع غرفًا فندقية تقدمها جهات أخرى عبر شريكنا HOTELBEDS، إحدى أكبر شبكات توريد الفنادق في العالم. والفندق هو من يقدّم الإقامة نفسها.',
    ),
    _InfoSection(
      titleEn: 'Live prices and availability',
      titleAr: 'أسعار وتوفر لحظي',
      bodyEn:
      'Each time you search, we request current rooms and rates from our supplier. Before you pay, we check the exact rate again. If the price has changed, we show you the new price before you are charged, and you decide whether to continue.',
      bodyAr:
      'في كل عملية بحث نطلب من المزوّد الغرف والأسعار الحالية. وقبل أن تدفع، نتحقق من السعر نفسه مرة أخرى؛ فإن تغيّر نعرض عليك السعر الجديد قبل أي خصم، ولك أن تقرر المتابعة أو لا.',
    ),
    _InfoSection(
      titleEn: 'All-in prices, no hidden fees',
      titleAr: 'أسعار شاملة دون رسوم خفية',
      bodyEn:
      'Prices are shown in U.S. dollars. The total price includes everything you must pay for the stay. Some hotels charge mandatory fees at the property, such as resort fees or local taxes; we include them in the total and list them as "Payable at the hotel", so you see the full cost before you book. We do not add a separate booking fee.',
      bodyAr:
      'تُعرض الأسعار بالدولار الأمريكي. السعر الإجمالي يشمل كل ما يجب عليك دفعه مقابل الإقامة. بعض الفنادق تفرض رسومًا إلزامية تُدفع في الفندق، مثل رسوم المنتجع أو الضرائب المحلية؛ ونحن ندرجها في الإجمالي ونذكرها تحت "تُدفع في الفندق"، لترى التكلفة الكاملة قبل الحجز. ولا نضيف رسوم حجز منفصلة.',
    ),
    _InfoSection(
      titleEn: 'How we make money',
      titleAr: 'كيف نربح',
      bodyEn:
      'Our supplier sells us rooms at a wholesale price. The price you see includes our margin on top of that wholesale price, along with the cost of payment processing. That margin is how Flynoom earns money. We do not charge you any extra service fee at checkout.',
      bodyAr:
      'يبيعنا المزوّد الغرف بسعر الجملة، والسعر الذي تراه يشمل هامشنا فوق سعر الجملة إلى جانب تكلفة معالجة الدفع. هذا الهامش هو مصدر ربح Flynoom، ولا نفرض عليك أي رسوم خدمة إضافية عند الدفع.',
    ),
    _InfoSection(
      titleEn: 'How results are ordered',
      titleAr: 'كيف نرتّب النتائج',
      bodyEn:
      'Hotels cannot pay Flynoom to appear higher in your search results, and we do not show sponsored or paid listings. Results are based on your destination, dates, and number of guests, and on the rooms our supplier has available for your search.',
      bodyAr:
      'لا تستطيع الفنادق الدفع لـ Flynoom لتظهر في مرتبة أعلى في نتائج بحثك، ولا نعرض نتائج مموّلة أو مدفوعة. تعتمد النتائج على وجهتك وتواريخك وعدد النزلاء، وعلى الغرف المتاحة لدى المزوّد لبحثك.',
    ),
    _InfoSection(
      titleEn: 'Star ratings and hotel information',
      titleAr: 'تصنيف النجوم ومعلومات الفندق',
      bodyEn:
      'The star rating shown for each hotel is its official category as provided by our supplier. It is not a guest review score. Hotel photos, descriptions, and amenities also come from our supplier and the hotel. We do not currently publish guest reviews.',
      bodyAr:
      'تصنيف النجوم المعروض لكل فندق هو فئته الرسمية كما يقدّمها المزوّد، وليس درجة تقييم من النزلاء. كما أن صور الفنادق وأوصافها ومرافقها مصدرها المزوّد والفندق. ولا ننشر حاليًا تقييمات النزلاء.',
    ),
    _InfoSection(
      titleEn: 'Secure payment: you are charged only after confirmation',
      titleAr: 'دفع آمن: لا يُخصم المبلغ إلا بعد التأكيد',
      bodyEn:
      'Payments are processed by Stripe, and Flynoom never stores your card number. When you book, we place a temporary hold on your card. We take the payment only after the hotel confirms your booking. If the booking cannot be confirmed, we release the hold and you are not charged.',
      bodyAr:
      'تُعالَج المدفوعات عبر Stripe، ولا تخزّن Flynoom رقم بطاقتك أبدًا. عند الحجز نضع حجزًا مؤقتًا للمبلغ على بطاقتك، ولا نسحب المبلغ إلا بعد أن يؤكد الفندق حجزك. وإن تعذّر تأكيد الحجز، نُلغي الحجز المؤقت ولا يُخصم منك شيء.',
    ),
    _InfoSection(
      titleEn: 'After you book',
      titleAr: 'بعد الحجز',
      bodyEn:
      'You receive a confirmation email with your voucher and booking reference, and your booking appears in "My Bookings". You can view the voucher there and cancel eligible bookings online. Before you confirm a cancellation, we show you the exact fee and refund. Refunds go back to your card, usually within 5 to 10 business days.',
      bodyAr:
      'تصلك رسالة تأكيد على بريدك مع القسيمة ورقم الحجز، ويظهر حجزك في "حجوزاتي"، حيث يمكنك عرض القسيمة وإلغاء الحجوزات المؤهلة عبر الإنترنت. وقبل أن تؤكد الإلغاء، نعرض لك الرسوم والمبلغ المسترد بالضبط. ويُرد المبلغ إلى بطاقتك عادةً خلال 5 إلى 10 أيام عمل.',
    ),
    _InfoSection(
      titleEn: 'Help when you need it',
      titleAr: 'مساعدة عندما تحتاجها',
      bodyEn:
      'If you have a question or a problem with a booking, email us at $_contactEmail with your booking reference. We aim to reply within two business days and will work with the hotel on your behalf. If something is wrong during your stay, please also tell the hotel right away.',
      bodyAr:
      'إذا كان لديك سؤال أو مشكلة في حجز، فراسلنا على $_contactEmail مع رقم الحجز. نسعى للرد خلال يومَي عمل، وسنتابع الأمر مع الفندق نيابة عنك. وإذا حدثت مشكلة أثناء إقامتك، فأبلغ الفندق فورًا أيضًا.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final lang = Localizations.localeOf(context).languageCode;
    final isArabic = lang == 'ar';
    final tr = _i18n[lang];

    // نص مترجم من _i18n إن وُجد، وإلا العربية أو الإنجليزية.
    String pick(int i, String en, String ar) =>
        (tr != null && i < tr.length) ? tr[i] : (isArabic ? ar : en);

    return Scaffold(
      appBar: AppBar(
        title: Text(pick(0, 'How We Work', 'كيف نعمل')),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSizes.md),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Semantics(
                  header: true,
                  child: Text(
                    pick(1, 'How Flynoom works', 'كيف تعمل Flynoom'),
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: AppSizes.md),
                Text(
                  pick(
                    2,
                    'We want you to know exactly what you are paying for, who you are buying from, how we make money, and how we show you results.',
                    'نريدك أن تعرف بالضبط ما الذي تدفع مقابله، وممن تشتري، وكيف نربح، وكيف نعرض لك النتائج.',
                  ),
                  style: const TextStyle(fontSize: 14, height: 1.6, color: AppColors.textSecondary),
                ),
                const SizedBox(height: AppSizes.lg),
                for (var i = 0; i < _sections.length; i++) ...[
                  Semantics(
                    header: true,
                    child: Text(
                      pick(3 + i * 2, _sections[i].titleEn, _sections[i].titleAr),
                      style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
                    ),
                  ),
                  const SizedBox(height: 6),
                  SelectableText(
                    pick(4 + i * 2, _sections[i].bodyEn, _sections[i].bodyAr),
                    style: const TextStyle(fontSize: 14, height: 1.6, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: AppSizes.lg),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}