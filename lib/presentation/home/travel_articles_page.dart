import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../core/widgets/app_banner.dart';
import '../../core/widgets/app_footer.dart';

class _Article {
  final IconData icon;
  final String titleEn;
  final String titleAr;
  final String bodyEn;
  final String bodyAr;
  const _Article({
    required this.icon,
    required this.titleEn,
    required this.titleAr,
    required this.bodyEn,
    required this.bodyAr,
  });
}

/// ترجمات الصفحة للغات السبع الأخرى.
/// ترتيب كل قائمة: [العنوان، الوصف، إخلاء المسؤولية، ثم (عنوان، نص) لكل مقال بنفس ترتيب _articles].
/// ⚠️ عند إضافة مقال جديد أضف عنوانه ونصه في آخر كل قائمة هنا، وإلا سيظهر بالإنجليزية.
const Map<String, List<String>> _i18n = {
  'es': [
    "Artículos de viaje",
    "Consejos prácticos que sirven en cada viaje, no solo noticias de temporada.",
    "Estos artículos son información general para ayudarte a planificar. No constituyen asesoramiento legal, médico ni financiero. Consulta siempre las normas vigentes en fuentes oficiales antes de viajar.",
    "Entender el precio total de una estancia de hotel",
    "La tarifa de la habitación es solo una parte de lo que pagas. Muchos destinos añaden impuestos por noche o por huésped, y algunos hoteles cobran cargos obligatorios, como una tarifa de resort o una tasa turística que se paga al hacer el check-in. Antes de pagar, revisa el desglose del precio: el total que pagas ahora y cualquier importe que el hotel cobrará a tu llegada. Flynoom te muestra ambos antes de confirmar la reserva, para que no haya sorpresas en la recepción.",
    "Cómo funcionan las políticas de cancelación de los hoteles",
    "Cada habitación tiene su propia política de cancelación, y dos habitaciones del mismo hotel pueden tener reglas distintas. «Cancelación gratuita» suele significar que puedes cancelar sin cargo hasta una fecha y hora concretas, a menudo según la hora local del hotel. Después de ese plazo, se puede cobrar parte o la totalidad del precio. Las tarifas no reembolsables suelen ser más baratas, pero solo convienen cuando tus planes son firmes. Lee siempre el plazo indicado en la habitación antes de reservar.",
    "Cómo elegir hotel para la Umrah",
    "La distancia al Haram importa más que casi cualquier otra cosa, sobre todo si viajas con familiares mayores o con niños: un trayecto corto a pie te ahorra energía para la adoración. Comprueba si la distancia indicada es a pie o en línea recta sobre el mapa. Reserva con antelación para Ramadán y las vacaciones escolares, cuando la demanda es máxima. Antes de viajar, confirma los requisitos vigentes de visado y del permiso de Umrah en los sitios web oficiales del gobierno saudí, ya que estas normas pueden cambiar.",
    "Cómo viajar ligero en cualquier viaje",
    "Elige una gama de colores neutros para que todas las prendas combinen entre sí, enrolla la ropa en lugar de doblarla para ahorrar espacio y lleva puesta en el avión la prenda más voluminosa (chaqueta, botas) en vez de guardarla en la maleta. Imagina un conjunto para cada día y luego quita una prenda: casi siempre llevas más de lo que necesitas.",
    "Cómo vencer el jet lag",
    "Empieza a ajustar tu horario de sueño unos días antes de volar, en la dirección de la zona horaria de tu destino. En el vuelo, pon el reloj en la hora del destino de inmediato e intenta dormir o mantenerte despierto según corresponda. Sal a la luz del día en cuanto aterrices: la luz natural es la forma más rápida de reajustar tu reloj biológico.",
    "Cómo manejar el dinero en el extranjero",
    "Avisa a tu banco antes de viajar para que un cargo en el extranjero no se marque como fraude. Lleva dos medios de pago de redes distintas por si uno es rechazado, y guarda un poco de efectivo en moneda local para los lugares que no aceptan tarjetas. Revisa la comisión por transacciones en el extranjero de tu tarjeta antes de salir: algunas no cobran nada y otras añaden un porcentaje a cada compra.",
    "Mantente conectado sin una factura enorme",
    "Una eSIM comprada antes de aterrizar suele ser más barata y sencilla que una tarjeta SIM física, y la mayoría de los teléfonos modernos la admiten. Descarga mapas sin conexión de tu destino antes de salir para no depender de los datos nada más llegar, y comprueba si tu alojamiento incluye wifi gratuito antes de darlo por hecho.",
  ],
  'tr': [
    "Seyahat yazıları",
    "Yalnızca mevsimlik haberler değil, her seyahatte işe yarayan pratik ipuçları.",
    "Bu yazılar planlamanıza yardımcı olacak genel bilgilerdir. Hukuki, tıbbi veya mali tavsiye niteliği taşımaz. Seyahat etmeden önce güncel kuralları her zaman resmî kaynaklardan kontrol edin.",
    "Otel konaklamasının toplam fiyatını anlamak",
    "Oda ücreti ödediğiniz tutarın yalnızca bir kısmıdır. Birçok destinasyon gece veya kişi başına vergi ekler; bazı oteller de girişte tahsil edilen tatil köyü ücreti veya şehir vergisi gibi zorunlu ücretler alır. Ödeme yapmadan önce fiyat dökümüne bakın: şimdi ödeyeceğiniz toplam tutar ve otelin varışınızda tahsil edeceği her tutar. Flynoom rezervasyonu onaylamadan önce ikisini de gösterir, böylece resepsiyonda sürprizle karşılaşmazsınız.",
    "Otel iptal politikaları nasıl işler",
    "Her odanın kendi iptal politikası vardır ve aynı oteldeki iki odanın kuralları farklı olabilir. “Ücretsiz iptal” genellikle belirli bir tarih ve saate kadar ücretsiz iptal edebileceğiniz anlamına gelir; bu süre çoğu zaman otelin yerel saatine göre hesaplanır. Bu süreden sonra fiyatın bir kısmı veya tamamı tahsil edilebilir. İade edilemez fiyatlar genellikle daha ucuzdur, ancak yalnızca planlarınız kesinse mantıklıdır. Rezervasyon yapmadan önce odada gösterilen son tarihi mutlaka okuyun.",
    "Umre için otel seçimi",
    "Harem’e uzaklık neredeyse her şeyden önemlidir, özellikle yaşlı aile üyeleri veya çocuklarla seyahat ediyorsanız: kısa bir yürüyüş ibadet için enerjinizi korur. Belirtilen mesafenin yürüme mesafesi mi yoksa haritada kuş uçuşu mu olduğunu kontrol edin. Talebin en yüksek olduğu Ramazan ve okul tatilleri için erken rezervasyon yapın. Seyahatten önce güncel vize ve Umre izni şartlarını Suudi hükümetinin resmî web sitelerinden teyit edin, çünkü bu kurallar değişebilir.",
    "Her seyahatte hafif bavulla yolculuk",
    "Her parçanın birbiriyle uyması için nötr bir renk paleti seçin, yer kazanmak için kıyafetleri katlamak yerine rulo yapın ve en hacimli parçanızı (mont, bot) bavula koymak yerine uçakta giyin. Her gün için bir kombin hayal edin, sonra bir parçayı çıkarın: neredeyse her zaman ihtiyacınızdan fazlasını hazırlamışsınızdır.",
    "Jet lag ile başa çıkmak",
    "Uçuştan birkaç gün önce uyku düzeninizi gideceğiniz yerin saat dilimine doğru kaydırmaya başlayın. Uçakta saatinizi hemen varış yerinin saatine ayarlayın ve ona göre uyumaya ya da uyanık kalmaya çalışın. İner inmez gün ışığına çıkın: doğal ışık biyolojik saatinizi yeniden ayarlamanın en hızlı yoludur.",
    "Yurt dışında para yönetimi",
    "Yurt dışındaki bir harcamanın dolandırıcılık olarak işaretlenmemesi için seyahatten önce bankanızı bilgilendirin. Biri reddedilirse diye farklı ağlardan iki ödeme yöntemi taşıyın ve kart kabul etmeyen yerler için biraz yerel para bulundurun. Yola çıkmadan önce kartınızın yurt dışı işlem ücretini kontrol edin: bazı kartlar hiç ücret almaz, bazıları her alışverişe bir yüzde ekler.",
    "Büyük bir fatura olmadan bağlantıda kalın",
    "İnmeden önce satın alınan bir eSIM genellikle fiziksel SIM karttan daha ucuz ve kolaydır; modern telefonların çoğu da bunu destekler. Varır varmaz mobil veriye bağımlı kalmamak için yola çıkmadan önce gideceğiniz yerin çevrimdışı haritalarını indirin ve konaklama yerinizin ücretsiz Wi-Fi sunduğunu varsaymadan önce kontrol edin.",
  ],
  'id': [
    "Artikel perjalanan",
    "Tips praktis yang berguna di setiap perjalanan, bukan sekadar berita musiman.",
    "Artikel ini adalah informasi umum untuk membantu Anda merencanakan perjalanan. Ini bukan nasihat hukum, medis, atau keuangan. Selalu periksa aturan terbaru dari sumber resmi sebelum bepergian.",
    "Memahami harga total menginap di hotel",
    "Tarif kamar hanyalah sebagian dari yang Anda bayar. Banyak destinasi menambahkan pajak per malam atau per tamu, dan beberapa hotel mengenakan biaya wajib seperti biaya resor atau pajak kota yang ditagih saat check-in. Sebelum membayar, lihat rincian harganya: total yang Anda bayar sekarang dan jumlah apa pun yang akan ditagih hotel saat Anda tiba. Flynoom menampilkan keduanya sebelum Anda mengonfirmasi pemesanan, jadi tidak ada kejutan di meja resepsionis.",
    "Cara kerja kebijakan pembatalan hotel",
    "Setiap kamar memiliki kebijakan pembatalannya sendiri, dan dua kamar di hotel yang sama bisa memiliki aturan berbeda. “Pembatalan gratis” biasanya berarti Anda dapat membatalkan tanpa biaya hingga tanggal dan jam tertentu, sering kali dihitung menurut waktu setempat hotel. Setelah batas waktu itu, sebagian atau seluruh harga dapat ditagih. Tarif yang tidak dapat dikembalikan sering lebih murah, tetapi hanya masuk akal jika rencana Anda sudah pasti. Selalu baca batas waktu yang ditampilkan pada kamar sebelum memesan.",
    "Memilih hotel untuk umrah",
    "Jarak ke Masjidil Haram lebih penting daripada hampir semua hal lain, terutama jika Anda bepergian bersama anggota keluarga lansia atau anak-anak: jalan kaki yang singkat menghemat tenaga untuk ibadah. Periksa apakah jarak yang tercantum adalah jarak berjalan kaki atau garis lurus di peta. Pesan lebih awal untuk Ramadan dan libur sekolah, saat permintaan paling tinggi. Sebelum berangkat, pastikan persyaratan visa dan izin umrah terbaru di situs web resmi pemerintah Arab Saudi, karena aturan ini dapat berubah.",
    "Cara berkemas ringan untuk perjalanan apa pun",
    "Pilih palet warna netral agar setiap pakaian bisa dipadupadankan, gulung pakaian alih-alih melipatnya untuk menghemat ruang, dan kenakan barang paling besar (jaket, sepatu bot) di pesawat alih-alih memasukkannya ke koper. Bayangkan satu setelan untuk setiap hari, lalu keluarkan satu barang: Anda hampir selalu membawa lebih dari yang dibutuhkan.",
    "Mengatasi jet lag",
    "Mulailah menggeser jadwal tidur beberapa hari sebelum terbang, ke arah zona waktu tujuan Anda. Di pesawat, segera atur jam Anda ke waktu tujuan dan cobalah tidur atau tetap terjaga sesuai waktu itu. Keluarlah ke cahaya siang segera setelah mendarat: cahaya alami adalah cara tercepat untuk mengatur ulang jam biologis Anda.",
    "Mengelola uang di luar negeri",
    "Beri tahu bank Anda sebelum bepergian agar transaksi di luar negeri tidak ditandai sebagai penipuan. Bawa dua metode pembayaran dari jaringan berbeda untuk berjaga-jaga jika salah satunya ditolak, dan simpan sedikit uang tunai dalam mata uang lokal untuk tempat yang tidak menerima kartu. Periksa biaya transaksi luar negeri kartu Anda sebelum berangkat: beberapa kartu tidak mengenakan biaya, yang lain menambahkan persentase pada setiap pembelian.",
    "Tetap terhubung tanpa tagihan besar",
    "eSIM yang dibeli sebelum mendarat biasanya lebih murah dan praktis daripada kartu SIM fisik, dan sebagian besar ponsel modern mendukungnya. Unduh peta offline tujuan Anda sebelum berangkat agar tidak bergantung pada data begitu tiba, dan pastikan akomodasi Anda menyediakan Wi-Fi gratis sebelum menganggapnya tersedia.",
  ],
  'hi': [
    "यात्रा लेख",
    "हर यात्रा में काम आने वाले व्यावहारिक सुझाव, सिर्फ़ मौसमी ख़बरें नहीं।",
    "ये लेख आपकी योजना में मदद के लिए सामान्य जानकारी हैं। ये कानूनी, चिकित्सा या वित्तीय सलाह नहीं हैं। यात्रा से पहले हमेशा आधिकारिक स्रोतों से मौजूदा नियम जाँच लें।",
    "होटल में ठहरने की पूरी कीमत समझें",
    "कमरे का किराया आपके भुगतान का केवल एक हिस्सा है। कई गंतव्य प्रति रात या प्रति अतिथि कर जोड़ते हैं, और कुछ होटल रिज़ॉर्ट शुल्क या सिटी टैक्स जैसे अनिवार्य शुल्क लेते हैं, जो चेक-इन पर वसूले जाते हैं। भुगतान से पहले कीमत का ब्योरा देखें: अभी चुकाई जाने वाली कुल राशि, और वह राशि जो होटल आपके पहुँचने पर लेगा। Flynoom बुकिंग की पुष्टि से पहले दोनों दिखाता है, ताकि रिसेप्शन पर कोई आश्चर्य न हो।",
    "होटल की रद्दीकरण नीतियाँ कैसे काम करती हैं",
    "हर कमरे की अपनी रद्दीकरण नीति होती है, और एक ही होटल के दो कमरों के नियम अलग हो सकते हैं। “निःशुल्क रद्दीकरण” का अर्थ आम तौर पर यह है कि आप एक तय तारीख और समय तक बिना शुल्क रद्द कर सकते हैं, जो अक्सर होटल के स्थानीय समय से गिना जाता है। उस समय-सीमा के बाद कीमत का कुछ हिस्सा या पूरी कीमत ली जा सकती है। नॉन-रिफ़ंडेबल रेट अक्सर सस्ते होते हैं, पर तभी ठीक हैं जब आपकी योजना पक्की हो। बुकिंग से पहले कमरे पर दिखाई गई समय-सीमा हमेशा पढ़ें।",
    "उमरा के लिए होटल चुनना",
    "हरम से दूरी लगभग हर चीज़ से ज़्यादा मायने रखती है, ख़ासकर अगर आप बुज़ुर्ग परिजनों या बच्चों के साथ यात्रा कर रहे हैं: कम पैदल दूरी इबादत के लिए आपकी ऊर्जा बचाती है। जाँचें कि बताई गई दूरी पैदल चलने की दूरी है या नक्शे पर सीधी रेखा। रमज़ान और स्कूल की छुट्टियों के लिए जल्दी बुकिंग करें, जब माँग सबसे ज़्यादा होती है। यात्रा से पहले सऊदी सरकार की आधिकारिक वेबसाइटों पर वीज़ा और उमरा परमिट की मौजूदा शर्तें पक्की कर लें, क्योंकि ये नियम बदल सकते हैं।",
    "किसी भी यात्रा में हल्का सामान कैसे ले जाएँ",
    "हल्के और मेल खाते रंग चुनें ताकि हर कपड़ा दूसरे के साथ जँचे, जगह बचाने के लिए कपड़ों को तह करने के बजाय रोल करें, और सबसे भारी चीज़ (जैकेट, जूते) बैग में रखने के बजाय विमान में पहनें। हर दिन के लिए एक पहनावा सोचें, फिर एक चीज़ हटा दें: आप लगभग हमेशा ज़रूरत से ज़्यादा सामान रख लेते हैं।",
    "जेट लैग से निपटना",
    "उड़ान से कुछ दिन पहले ही अपने सोने का समय गंतव्य के टाइम ज़ोन की दिशा में खिसकाना शुरू करें। विमान में तुरंत अपनी घड़ी गंतव्य के समय पर कर दें और उसी के हिसाब से सोने या जागने की कोशिश करें। उतरते ही दिन की रोशनी में बाहर निकलें: प्राकृतिक रोशनी आपकी जैविक घड़ी को दोबारा सेट करने का सबसे तेज़ तरीका है।",
    "विदेश में पैसों का प्रबंधन",
    "यात्रा से पहले अपने बैंक को सूचित करें ताकि विदेश में हुआ कोई भुगतान धोखाधड़ी न मान लिया जाए। अलग-अलग नेटवर्क के दो भुगतान साधन साथ रखें, ताकि एक अस्वीकार हो तो दूसरा काम आए, और उन जगहों के लिए थोड़ी स्थानीय नकदी रखें जहाँ कार्ड नहीं चलते। जाने से पहले अपने कार्ड का विदेशी लेनदेन शुल्क जाँच लें: कुछ कार्ड कोई शुल्क नहीं लेते, जबकि कुछ हर ख़रीद पर एक प्रतिशत जोड़ते हैं।",
    "भारी बिल के बिना जुड़े रहें",
    "पहुँचने से पहले ख़रीदा गया eSIM आम तौर पर फ़िज़िकल SIM कार्ड से सस्ता और आसान होता है, और ज़्यादातर आधुनिक फ़ोन इसे सपोर्ट करते हैं। जाने से पहले अपने गंतव्य के ऑफ़लाइन नक्शे डाउनलोड कर लें ताकि पहुँचते ही डेटा पर निर्भर न रहना पड़े, और यह मानने से पहले जाँच लें कि आपके ठहरने की जगह पर मुफ़्त Wi-Fi है।",
  ],
  'ur': [
    "سفری مضامین",
    "ہر سفر میں کام آنے والی عملی تجاویز، صرف موسمی خبریں نہیں۔",
    "یہ مضامین منصوبہ بندی میں مدد کے لیے عمومی معلومات ہیں۔ یہ قانونی، طبی یا مالی مشورہ نہیں ہیں۔ سفر سے پہلے ہمیشہ سرکاری ذرائع سے موجودہ قواعد کی تصدیق کریں۔",
    "ہوٹل میں قیام کی مکمل قیمت کو سمجھیں",
    "کمرے کا کرایہ آپ کی ادائیگی کا صرف ایک حصہ ہے۔ بہت سی منزلیں فی رات یا فی مہمان ٹیکس شامل کرتی ہیں، اور بعض ہوٹل لازمی فیسیں لیتے ہیں جیسے ریزورٹ فیس یا سٹی ٹیکس، جو چیک اِن پر وصول کیے جاتے ہیں۔ ادائیگی سے پہلے قیمت کی تفصیل دیکھیں: ابھی ادا کی جانے والی کل رقم، اور وہ رقم جو ہوٹل آپ کے پہنچنے پر وصول کرے گا۔ Flynoom بکنگ کی تصدیق سے پہلے دونوں دکھاتا ہے، تاکہ استقبالیہ پر کوئی حیرانی نہ ہو۔",
    "ہوٹل کی منسوخی کی پالیسیاں کیسے کام کرتی ہیں",
    "ہر کمرے کی اپنی منسوخی پالیسی ہوتی ہے، اور ایک ہی ہوٹل کے دو کمروں کے قواعد مختلف ہو سکتے ہیں۔ “مفت منسوخی” کا مطلب عموماً یہ ہے کہ آپ ایک مقررہ تاریخ اور وقت تک بغیر فیس منسوخ کر سکتے ہیں، جو اکثر ہوٹل کے مقامی وقت کے مطابق ہوتا ہے۔ اس آخری وقت کے بعد قیمت کا کچھ حصہ یا پوری قیمت وصول کی جا سکتی ہے۔ ناقابل واپسی ریٹس عموماً سستے ہوتے ہیں، لیکن صرف اسی وقت مناسب ہیں جب آپ کا منصوبہ پکا ہو۔ بکنگ سے پہلے کمرے پر دکھایا گیا آخری وقت ضرور پڑھیں۔",
    "عمرہ کے لیے ہوٹل کا انتخاب",
    "حرم سے فاصلہ تقریباً ہر چیز سے زیادہ اہم ہے، خاص طور پر اگر آپ بزرگ اہل خانہ یا بچوں کے ساتھ سفر کر رہے ہیں: کم پیدل فاصلہ عبادت کے لیے آپ کی توانائی بچاتا ہے۔ دیکھیں کہ بتایا گیا فاصلہ پیدل چلنے کا ہے یا نقشے پر سیدھی لکیر کا۔ رمضان اور اسکول کی چھٹیوں کے لیے جلد بکنگ کریں، جب مانگ سب سے زیادہ ہوتی ہے۔ سفر سے پہلے سعودی حکومت کی سرکاری ویب سائٹس پر ویزا اور عمرہ اجازت نامے کی موجودہ شرائط کی تصدیق کر لیں، کیونکہ یہ قواعد بدل سکتے ہیں۔",
    "کسی بھی سفر میں ہلکا سامان کیسے لے جائیں",
    "ہلکے اور ملتے جلتے رنگ چنیں تاکہ ہر کپڑا دوسرے کے ساتھ میل کھائے، جگہ بچانے کے لیے کپڑوں کو تہہ کرنے کے بجائے لپیٹیں، اور سب سے بھاری چیز (جیکٹ، بوٹ) بیگ میں رکھنے کے بجائے جہاز میں پہن لیں۔ ہر دن کے لیے ایک لباس کا تصور کریں، پھر ایک چیز نکال دیں: آپ تقریباً ہمیشہ ضرورت سے زیادہ سامان رکھ لیتے ہیں۔",
    "جیٹ لیگ پر قابو پانا",
    "پرواز سے چند دن پہلے ہی اپنے سونے کے اوقات کو منزل کے ٹائم زون کی سمت میں منتقل کرنا شروع کریں۔ جہاز میں فوراً اپنی گھڑی منزل کے وقت پر کر دیں اور اسی کے مطابق سونے یا جاگنے کی کوشش کریں۔ اترتے ہی دن کی روشنی میں باہر نکلیں: قدرتی روشنی آپ کی حیاتیاتی گھڑی کو دوبارہ ترتیب دینے کا سب سے تیز طریقہ ہے۔",
    "بیرون ملک پیسوں کا انتظام",
    "سفر سے پہلے اپنے بینک کو مطلع کریں تاکہ بیرون ملک کوئی ادائیگی دھوکہ دہی نہ سمجھی جائے۔ مختلف نیٹ ورکس کے دو ادائیگی کے ذرائع ساتھ رکھیں تاکہ ایک مسترد ہو تو دوسرا کام آئے، اور ان جگہوں کے لیے تھوڑی مقامی نقدی رکھیں جہاں کارڈ قبول نہیں ہوتے۔ جانے سے پہلے اپنے کارڈ کی غیر ملکی لین دین فیس چیک کریں: بعض کارڈ کوئی فیس نہیں لیتے، اور بعض ہر خریداری پر ایک فیصد شامل کرتے ہیں۔",
    "بھاری بل کے بغیر رابطے میں رہیں",
    "پہنچنے سے پہلے خریدا گیا eSIM عموماً عام SIM کارڈ سے سستا اور آسان ہوتا ہے، اور زیادہ تر جدید فون اسے سپورٹ کرتے ہیں۔ جانے سے پہلے اپنی منزل کے آف لائن نقشے ڈاؤن لوڈ کر لیں تاکہ پہنچتے ہی ڈیٹا پر انحصار نہ کرنا پڑے، اور یہ فرض کرنے سے پہلے تصدیق کر لیں کہ آپ کی رہائش میں مفت Wi-Fi موجود ہے۔",
  ],
  'fr': [
    "Articles de voyage",
    "Des conseils pratiques valables à chaque voyage, pas seulement des actualités saisonnières.",
    "Ces articles sont des informations générales pour vous aider à planifier. Ils ne constituent pas un avis juridique, médical ou financier. Vérifiez toujours les règles en vigueur auprès des sources officielles avant de partir.",
    "Comprendre le prix total d’un séjour à l’hôtel",
    "Le prix de la chambre n’est qu’une partie de ce que vous payez. De nombreuses destinations ajoutent des taxes par nuit ou par personne, et certains hôtels facturent des frais obligatoires, comme des frais de resort ou une taxe de séjour perçue à l’arrivée. Avant de payer, consultez le détail du prix : le total que vous payez maintenant et tout montant que l’hôtel percevra à votre arrivée. Flynoom affiche les deux avant que vous confirmiez la réservation, pour éviter toute surprise à la réception.",
    "Comment fonctionnent les conditions d’annulation des hôtels",
    "Chaque chambre a ses propres conditions d’annulation, et deux chambres d’un même hôtel peuvent avoir des règles différentes. « Annulation gratuite » signifie généralement que vous pouvez annuler sans frais jusqu’à une date et une heure précises, souvent selon l’heure locale de l’hôtel. Passé ce délai, une partie ou la totalité du prix peut être facturée. Les tarifs non remboursables sont souvent moins chers, mais ils ne conviennent que si vos projets sont certains. Lisez toujours le délai indiqué sur la chambre avant de réserver.",
    "Choisir un hôtel pour la Omra",
    "La distance jusqu’au Haram compte plus que presque tout le reste, surtout si vous voyagez avec des proches âgés ou des enfants : un court trajet à pied vous laisse plus d’énergie pour l’adoration. Vérifiez si la distance indiquée est une distance à pied ou à vol d’oiseau sur la carte. Réservez tôt pour le Ramadan et les vacances scolaires, quand la demande est la plus forte. Avant de partir, vérifiez les exigences actuelles en matière de visa et de permis de Omra sur les sites officiels du gouvernement saoudien, car ces règles peuvent changer.",
    "Voyager léger, quel que soit le voyage",
    "Choisissez une palette de couleurs neutres pour que toutes les pièces s’associent entre elles, roulez vos vêtements au lieu de les plier pour gagner de la place, et portez dans l’avion votre pièce la plus volumineuse (veste, bottes) au lieu de la mettre dans la valise. Imaginez une tenue pour chaque jour, puis retirez un article : vous en emportez presque toujours plus que nécessaire.",
    "Vaincre le décalage horaire",
    "Commencez à décaler vos heures de sommeil quelques jours avant le vol, dans le sens du fuseau horaire de votre destination. Dans l’avion, réglez immédiatement votre montre sur l’heure de destination et essayez de dormir ou de rester éveillé en conséquence. Sortez à la lumière du jour dès l’atterrissage : la lumière naturelle est le moyen le plus rapide de recaler votre horloge biologique.",
    "Gérer son argent à l’étranger",
    "Prévenez votre banque avant de partir pour qu’un paiement à l’étranger ne soit pas signalé comme une fraude. Emportez deux moyens de paiement de réseaux différents au cas où l’un serait refusé, et gardez un peu d’espèces en monnaie locale pour les endroits qui n’acceptent pas les cartes. Vérifiez les frais de transaction à l’étranger de votre carte avant de partir : certaines cartes ne facturent rien, d’autres ajoutent un pourcentage à chaque achat.",
    "Rester connecté sans facture salée",
    "Une eSIM achetée avant l’atterrissage est généralement moins chère et plus simple qu’une carte SIM physique, et la plupart des téléphones récents la prennent en charge. Téléchargez des cartes hors ligne de votre destination avant de partir pour ne pas dépendre des données dès l’arrivée, et vérifiez que votre hébergement inclut bien le Wi-Fi gratuit avant de le supposer.",
  ],
  'bn': [
    "ভ্রমণ নিবন্ধ",
    "প্রতিটি ভ্রমণে কাজে লাগে এমন ব্যবহারিক পরামর্শ, শুধু মৌসুমি খবর নয়।",
    "এই নিবন্ধগুলো পরিকল্পনায় সাহায্যের জন্য সাধারণ তথ্য। এগুলো আইনি, চিকিৎসা বা আর্থিক পরামর্শ নয়। ভ্রমণের আগে সর্বদা সরকারি উৎস থেকে বর্তমান নিয়ম যাচাই করুন।",
    "হোটেলে থাকার পূর্ণ মূল্য বুঝুন",
    "রুম ভাড়া আপনার মোট খরচের একটি অংশ মাত্র। অনেক গন্তব্যে প্রতি রাত বা প্রতি অতিথির জন্য কর যোগ হয়, আর কিছু হোটেল রিসোর্ট ফি বা সিটি ট্যাক্সের মতো বাধ্যতামূলক ফি নেয়, যা চেক-ইনের সময় আদায় করা হয়। অর্থ পরিশোধের আগে মূল্যের বিবরণ দেখুন: এখন আপনি মোট কত দিচ্ছেন, আর পৌঁছানোর পর হোটেল কত আদায় করবে। বুকিং নিশ্চিত করার আগে Flynoom দুটোই দেখায়, যাতে রিসেপশনে কোনো চমক না থাকে।",
    "হোটেলের বাতিলকরণ নীতি কীভাবে কাজ করে",
    "প্রতিটি রুমের নিজস্ব বাতিলকরণ নীতি থাকে, এবং একই হোটেলের দুটি রুমের নিয়ম আলাদা হতে পারে। “বিনামূল্যে বাতিল” সাধারণত বোঝায় যে আপনি একটি নির্দিষ্ট তারিখ ও সময় পর্যন্ত বিনা চার্জে বাতিল করতে পারবেন, যা প্রায়ই হোটেলের স্থানীয় সময় অনুযায়ী গণনা করা হয়। সেই সময়সীমার পরে মূল্যের কিছু অংশ বা পুরোটা কাটা হতে পারে। অফেরতযোগ্য রেট প্রায়ই সস্তা, কিন্তু তা কেবল তখনই উপযুক্ত যখন আপনার পরিকল্পনা নিশ্চিত। বুকিংয়ের আগে রুমে দেখানো সময়সীমা অবশ্যই পড়ুন।",
    "উমরাহর জন্য হোটেল বেছে নেওয়া",
    "হারাম থেকে দূরত্ব প্রায় সবকিছুর চেয়ে বেশি গুরুত্বপূর্ণ, বিশেষ করে বয়স্ক স্বজন বা শিশুদের নিয়ে ভ্রমণ করলে: অল্প হাঁটার পথ ইবাদতের জন্য আপনার শক্তি বাঁচায়। দেখুন উল্লেখিত দূরত্বটি হাঁটার দূরত্ব নাকি মানচিত্রে সরলরেখা। রমজান ও স্কুলের ছুটিতে চাহিদা সবচেয়ে বেশি থাকে, তাই আগেভাগে বুকিং করুন। ভ্রমণের আগে সৌদি সরকারের অফিসিয়াল ওয়েবসাইটে ভিসা ও উমরাহ অনুমতিপত্রের বর্তমান শর্তাবলি নিশ্চিত করুন, কারণ এসব নিয়ম বদলাতে পারে।",
    "যেকোনো ভ্রমণে হালকা লাগেজ নেওয়ার উপায়",
    "নিরপেক্ষ রঙের পোশাক বেছে নিন যাতে প্রতিটি অন্যটির সঙ্গে মানিয়ে যায়, জায়গা বাঁচাতে কাপড় ভাঁজ না করে গুটিয়ে রাখুন, আর সবচেয়ে ভারী জিনিসটি (জ্যাকেট, বুট) ব্যাগে না রেখে বিমানে পরে নিন। প্রতিদিনের জন্য একটি পোশাক কল্পনা করুন, তারপর একটি জিনিস বাদ দিন: আপনি প্রায় সবসময় প্রয়োজনের চেয়ে বেশি গুছিয়ে ফেলেন।",
    "জেট ল্যাগ কাটিয়ে ওঠা",
    "উড়ানের কয়েক দিন আগে থেকেই ঘুমের সময় গন্তব্যের টাইম জোনের দিকে সরাতে শুরু করুন। বিমানে উঠেই ঘড়ি গন্তব্যের সময়ে সেট করুন এবং সেই অনুযায়ী ঘুমানো বা জেগে থাকার চেষ্টা করুন। নামার পরপরই দিনের আলোয় বের হন: প্রাকৃতিক আলো আপনার শরীরের ঘড়ি পুনরায় ঠিক করার দ্রুততম উপায়।",
    "বিদেশে অর্থ ব্যবস্থাপনা",
    "ভ্রমণের আগে আপনার ব্যাংককে জানিয়ে রাখুন, যাতে বিদেশে কোনো লেনদেন প্রতারণা হিসেবে চিহ্নিত না হয়। ভিন্ন নেটওয়ার্কের দুটি পেমেন্ট পদ্ধতি সঙ্গে রাখুন, যাতে একটি প্রত্যাখ্যাত হলে অন্যটি কাজে লাগে, আর যেসব জায়গায় কার্ড চলে না সেখানের জন্য কিছু স্থানীয় নগদ টাকা রাখুন। যাওয়ার আগে আপনার কার্ডের বিদেশি লেনদেন ফি দেখে নিন: কিছু কার্ড কোনো ফি নেয় না, আবার কিছু প্রতিটি কেনাকাটায় একটি শতাংশ যোগ করে।",
    "বড় বিল ছাড়াই সংযুক্ত থাকুন",
    "পৌঁছানোর আগে কেনা eSIM সাধারণত সাধারণ SIM কার্ডের চেয়ে সস্তা ও সহজ, এবং বেশিরভাগ আধুনিক ফোন এটি সমর্থন করে। যাওয়ার আগে গন্তব্যের অফলাইন মানচিত্র ডাউনলোড করে নিন, যাতে পৌঁছেই ডেটার ওপর নির্ভর করতে না হয়, আর আপনার থাকার জায়গায় বিনামূল্যে Wi-Fi আছে কি না তা ধরে নেওয়ার আগে যাচাই করুন।",
  ],
};

/// مقالات سفر عملية دائمة الصلاحية (ليست أخبارًا تفقد قيمتها بسرعة).
/// المحتوى بالإنجليزية والعربية الفصحى، واللغات السبع الأخرى في _i18n أعلاه.
///
/// ⚠️ قواعد المحتوى هنا:
/// - لا أسعار ولا رسوم تأشيرات ولا قواعد دخول محددة: تتغير ولا نتابعها.
///   نحيل القارئ دائمًا للمصدر الرسمي.
/// - لا أسماء علامات تجارية لفنادق أو شركات أو منافسين.
/// - لا وعود بخصومات أو خدمات غير موجودة فعلًا في المنصة.
/// - النصوص مكتوبة خصيصًا لـ Flynoom؛ لا تنسخ مقالات من مواقع أخرى.
class TravelArticlesPage extends StatelessWidget {
  const TravelArticlesPage({super.key});

  static const List<_Article> _articles = [
    // ───── مقالات تخص حجز الفنادق (تشرح ما يراه العميل في Flynoom) ─────
    _Article(
      icon: Icons.receipt_long_outlined,
      titleEn: 'Understanding the full price of a hotel stay',
      titleAr: 'فهم السعر الكامل لإقامتك الفندقية',
      bodyEn:
      'The room rate is only part of what you pay. Many destinations add taxes per night or per guest, and some hotels charge mandatory fees such as a resort fee or a city tax that is collected at check-in. Before you pay, look at the price breakdown: the total you pay now, and any amount the hotel will collect when you arrive. Flynoom shows both before you confirm a booking, so there are no surprises at the front desk.',
      bodyAr:
      'سعر الغرفة جزء فقط مما تدفعه. فكثير من الوجهات تضيف ضرائب عن كل ليلة أو عن كل نزيل، وبعض الفنادق تفرض رسومًا إلزامية مثل رسوم المنتجع أو ضريبة المدينة التي تُحصَّل عند الوصول. قبل الدفع، راجع تفاصيل السعر: المبلغ الذي تدفعه الآن، وأي مبلغ سيحصّله الفندق عند وصولك. يعرض لك Flynoom الأمرين قبل تأكيد الحجز، فلا تفاجأ بشيء في مكتب الاستقبال.',
    ),
    _Article(
      icon: Icons.event_busy_outlined,
      titleEn: 'How hotel cancellation policies work',
      titleAr: 'كيف تعمل سياسات إلغاء الحجز في الفنادق',
      bodyEn:
      'Each room comes with its own cancellation policy, and two rooms in the same hotel can have different rules. "Free cancellation" usually means you can cancel without charge until a specific date and time, often counted in the hotel\'s local time zone. After that deadline, part or all of the price may be charged. Non-refundable rates are often cheaper, but they make sense only when your plans are firm. Always read the deadline shown on the room before you book.',
      bodyAr:
      'لكل غرفة سياسة إلغاء خاصة بها، وقد تختلف القواعد بين غرفتين في الفندق نفسه. وعبارة "إلغاء مجاني" تعني عادةً أنك تستطيع الإلغاء دون رسوم حتى تاريخ ووقت محددين، يُحسبان غالبًا بالتوقيت المحلي للفندق. وبعد هذا الموعد قد يُخصم جزء من السعر أو كله. أما الأسعار غير القابلة للاسترداد فتكون أرخص في الغالب، لكنها مناسبة فقط عندما تكون خطتك مؤكدة. اقرأ دائمًا الموعد النهائي المعروض على الغرفة قبل الحجز.',
    ),
    _Article(
      icon: Icons.mosque_outlined,
      titleEn: 'Choosing a hotel for Umrah',
      titleAr: 'اختيار الفندق المناسب لرحلة العمرة',
      bodyEn:
      'Distance to the Haram matters more than almost anything else, especially if you are traveling with elderly family members or children: a short walk saves energy for worship. Check whether the distance listed is walking distance or a straight line on the map. Book early for Ramadan and school holidays, when demand is highest. Before you travel, confirm the current visa and Umrah permit requirements on the official Saudi government websites, as these rules can change.',
      bodyAr:
      'المسافة إلى الحرم أهم من أي شيء آخر تقريبًا، خاصةً إن كنت مسافرًا مع كبار السن أو الأطفال، فالمشي القصير يوفّر جهدك للعبادة. تأكد هل المسافة المذكورة مسافة مشي فعلية أم خط مستقيم على الخريطة. واحجز مبكرًا في رمضان والعطلات المدرسية، حين يكون الطلب في ذروته. وقبل السفر، تأكد من شروط التأشيرة وتصريح العمرة الحالية من المواقع الرسمية للحكومة السعودية، لأن هذه القواعد قد تتغير.',
    ),

    // ───── نصائح سفر عامة ─────
    _Article(
      icon: Icons.luggage_outlined,
      titleEn: 'How to pack light for any trip',
      titleAr: 'كيف تسافر بحقيبة خفيفة في أي رحلة',
      bodyEn:
      'Pick a neutral color scheme so every piece mixes and matches, roll clothes instead of folding to save space, and wear your bulkiest item (jacket, boots) on the plane instead of packing it. Pack one outfit at a time in your head for each day, then remove one item — you almost always packed more than you need.',
      bodyAr:
      'اختر ألوانًا متناسقة حتى تتماشى كل قطعة مع البقية، ولُفّ الملابس بدل طيّها لتوفير المساحة، وارتدِ أثقل قطعة لديك، كالمعطف أو الحذاء الشتوي، في الطائرة بدل وضعها في الحقيبة. تخيّل ملابس كل يوم على حدة، ثم استبعد قطعة واحدة، فغالبًا ستجد أنك جهّزت أكثر مما تحتاج.',
    ),
    _Article(
      icon: Icons.schedule_outlined,
      titleEn: 'Beating jet lag',
      titleAr: 'التغلب على اضطراب الرحلات الطويلة',
      bodyEn:
      'Start shifting your sleep schedule a few days before you fly, in the direction of your destination\'s time zone. On the flight, set your watch to the destination time immediately and try to sleep or stay awake accordingly. Get outside in daylight as soon as you land — natural light is the fastest way to reset your body clock.',
      bodyAr:
      'ابدأ بتعديل مواعيد نومك قبل السفر بأيام، باتجاه توقيت وجهتك. وفي الطائرة اضبط ساعتك على توقيت الوجهة فورًا، وحاول أن تنام أو تبقى مستيقظًا وفقًا له. واخرج إلى ضوء النهار فور وصولك، فالضوء الطبيعي أسرع وسيلة لضبط ساعتك البيولوجية.',
    ),
    _Article(
      icon: Icons.credit_card_outlined,
      titleEn: 'Managing money abroad',
      titleAr: 'إدارة أموالك أثناء السفر',
      bodyEn:
      'Notify your bank before you travel so a foreign charge doesn\'t get flagged as fraud. Carry two payment methods from different networks in case one is declined, and keep a small amount of local cash for places that don\'t take cards. Check your card\'s foreign transaction fee before you go — some cards charge nothing, others add a percentage to every purchase.',
      bodyAr:
      'أبلغ بنكك قبل السفر حتى لا تُعدّ أي عملية دفع من الخارج محاولة احتيال. واحمل وسيلتي دفع من شبكتين مختلفتين احتياطًا إن رُفضت إحداهما، واحتفظ بمبلغ نقدي صغير بالعملة المحلية للأماكن التي لا تقبل البطاقات. وتحقق من رسوم المعاملات الأجنبية على بطاقتك قبل السفر، فبعض البطاقات لا تفرض رسومًا، وبعضها يضيف نسبة على كل عملية شراء.',
    ),
    _Article(
      icon: Icons.wifi_outlined,
      titleEn: 'Staying connected without a huge bill',
      titleAr: 'ابقَ متصلًا دون فاتورة كبيرة',
      bodyEn:
      'An eSIM bought before you land is usually cheaper and easier than a physical SIM card, and most modern phones support it. Download offline maps of your destination before you go so you\'re not relying on data the moment you land, and check whether your accommodation includes free Wi-Fi before assuming it does.',
      bodyAr:
      'شراء شريحة إلكترونية (eSIM) قبل الوصول أرخص وأسهل غالبًا من الشريحة العادية، وتدعمها معظم الهواتف الحديثة. ونزّل خرائط وجهتك للاستخدام دون إنترنت قبل السفر حتى لا تعتمد على البيانات فور وصولك، وتأكد أن مكان إقامتك يوفر شبكة Wi-Fi مجانية قبل أن تفترض ذلك.',
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
      appBar: const AppBanner(),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSizes.lg),
          children: [
            Text(
              pick(0, 'Travel articles', 'مقالات سفر'),
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppSizes.md),
            Text(
              pick(
                1,
                'Practical tips that hold up trip after trip, not just seasonal news.',
                'نصائح عملية تفيدك في كل رحلة، وليست أخبارًا موسمية.',
              ),
              style: const TextStyle(fontSize: 15, color: AppColors.textSecondary, height: 1.5),
            ),
            const SizedBox(height: AppSizes.xl),
            for (var i = 0; i < _articles.length; i++) ...[
              Container(
                padding: const EdgeInsets.all(AppSizes.md),
                margin: const EdgeInsets.only(bottom: AppSizes.md),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.divider),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(_articles[i].icon, color: AppColors.primary, size: 24),
                        const SizedBox(width: AppSizes.sm),
                        Expanded(
                          child: Text(
                            pick(3 + i * 2, _articles[i].titleEn, _articles[i].titleAr),
                            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSizes.sm),
                    Text(
                      pick(4 + i * 2, _articles[i].bodyEn, _articles[i].bodyAr),
                      style: const TextStyle(fontSize: 14, height: 1.6, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: AppSizes.sm),
            // إخلاء مسؤولية: المقالات معلومات عامة وليست نصيحة مهنية.
            Text(
              pick(
                2,
                'These articles are general information to help you plan. They are not legal, medical, or financial advice. Always check current rules with official sources before you travel.',
                'هذه المقالات معلومات عامة للمساعدة في التخطيط، وليست نصيحة قانونية أو طبية أو مالية. تحقق دائمًا من القواعد الحالية من المصادر الرسمية قبل السفر.',
              ),
              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.5),
            ),
            const SizedBox(height: AppSizes.lg),
            const AppFooter(),
          ],
        ),
      ),
    );
  }
}