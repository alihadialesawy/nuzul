// supabase/functions/_shared/email.ts
//
// رسائل البريد للعميل عبر Resend: تأكيد الحجز (مع القسيمة كاملة) وتأكيد الإلغاء
// وعدم إتمام الحجز — بلغة الزبون (عمود bookings.locale، 9 لغات؛ الافتراضي الإنجليزية).
// البريد لا يوقف الحجز أبدًا: أي فشل يُسجَّل في الـ Logs فقط.
//
// ما يبقى بالإنجليزية عمدًا: أسماء الفنادق والغرف والوجبات وملاحظات الفندق
// (تأتي من HotelBeds كذلك)، وسطر "Payable through HOTELBEDS..." (نص يطلبه المورّد).
//
// Secrets المطلوبة:
//   RESEND_API_KEY  (موجود)
//   EMAIL_FROM      اختياري، الافتراضي: "Flynoom <bookings@flynoom.com>"
//   EMAIL_REPLY_TO  اختياري، الافتراضي: ali@flynoom.com
//
// ⚠️ لا يعمل الإرسال من @flynoom.com قبل أن تصبح حالة النطاق Verified في Resend.

const RESEND_API_KEY = Deno.env.get('RESEND_API_KEY') ?? '';
const EMAIL_FROM = Deno.env.get('EMAIL_FROM') ?? 'Flynoom <bookings@flynoom.com>';
const EMAIL_REPLY_TO = Deno.env.get('EMAIL_REPLY_TO') ?? 'ali@flynoom.com';

/// شعار البريد (FLY كحلي + NOOM برتقالي) مستضاف على الموقع نفسه بعد النشر.
/// Flutter Web يضع الأصول تحت assets/assets/. لو لم تُحمَّل الصورة
/// (بعض برامج البريد تحجب الصور) يظهر نص alt "FLYNOOM" بنفس التنسيق.
const LOGO_URL = Deno.env.get('EMAIL_LOGO_URL') ??
  'https://flynoom.com/assets/assets/images/logo_flynoom_dark.png';

export const EMAIL_LANGS = ['en', 'ar', 'es', 'tr', 'id', 'hi', 'ur', 'fr', 'bn'] as const;
export type EmailLang = typeof EMAIL_LANGS[number];

/// "ar_SA" / "AR" / null → لغة مدعومة أو 'en'.
export function emailLocale(v: unknown): EmailLang {
  const c = String(v ?? '').trim().toLowerCase().slice(0, 2);
  return (EMAIL_LANGS as readonly string[]).includes(c) ? (c as EmailLang) : 'en';
}

const RTL = new Set<EmailLang>(['ar', 'ur']);

// الترتيب: en, ar, es, tr, id, hi, ur, fr, bn
type Row9 = [string, string, string, string, string, string, string, string, string];
const T: Record<string, Row9> = {
  confirmedHeading: ['Your booking is confirmed', 'تم تأكيد حجزك', 'Tu reserva está confirmada', 'Rezervasyonunuz onaylandı', 'Pemesanan Anda telah dikonfirmasi', 'आपकी बुकिंग की पुष्टि हो गई है', 'آپ کی بکنگ کی تصدیق ہو گئی ہے', 'Votre réservation est confirmée', 'আপনার বুকিং নিশ্চিত হয়েছে'],
  confirmedIntro: [
    'Hi {name}, thank you for booking with Flynoom. Please show this email (or your booking reference) at check-in.',
    'مرحبًا {name}، شكرًا لحجزك عبر Flynoom. يُرجى إبراز هذا البريد (أو رقم الحجز) عند تسجيل الوصول.',
    'Hola {name}, gracias por reservar con Flynoom. Muestra este correo (o tu número de reserva) al registrarte en el hotel.',
    'Merhaba {name}, Flynoom ile rezervasyon yaptığınız için teşekkürler. Lütfen girişte bu e-postayı (veya rezervasyon numaranızı) gösterin.',
    'Halo {name}, terima kasih telah memesan melalui Flynoom. Tunjukkan email ini (atau nomor pemesanan Anda) saat check-in.',
    'नमस्ते {name}, Flynoom से बुकिंग करने के लिए धन्यवाद। चेक-इन के समय यह ईमेल (या अपना बुकिंग नंबर) दिखाएँ।',
    'محترم {name}، Flynoom کے ذریعے بکنگ کا شکریہ۔ چیک اِن کے وقت یہ ای میل (یا اپنا بکنگ نمبر) دکھائیں۔',
    'Bonjour {name}, merci d’avoir réservé avec Flynoom. Présentez cet e-mail (ou votre numéro de réservation) à l’enregistrement.',
    'হ্যালো {name}, Flynoom-এর মাধ্যমে বুকিং করার জন্য ধন্যবাদ। চেক-ইনের সময় এই ইমেইল (বা আপনার বুকিং নম্বর) দেখান।',
  ],
  booking: ['Booking', 'الحجز', 'Reserva', 'Rezervasyon', 'Pemesanan', 'बुकिंग', 'بکنگ', 'Réservation', 'বুকিং'],
  hotelConfCode: ['Hotel confirmation number', 'رقم التأكيد لدى الفندق', 'Número de confirmación del hotel', 'Otel onay numarası', 'Nomor konfirmasi hotel', 'होटल पुष्टि नंबर', 'ہوٹل کی تصدیقی نمبر', 'Numéro de confirmation de l’hôtel', 'হোটেলের নিশ্চিতকরণ নম্বর'],
  bookingRef: ['Booking reference', 'رقم الحجز', 'Número de reserva', 'Rezervasyon numarası', 'Nomor pemesanan', 'बुकिंग नंबर', 'بکنگ نمبر', 'Numéro de réservation', 'বুকিং নম্বর'],
  flynoomRef: ['Flynoom reference', 'مرجع Flynoom', 'Referencia de Flynoom', 'Flynoom referansı', 'Referensi Flynoom', 'Flynoom संदर्भ', 'Flynoom حوالہ', 'Référence Flynoom', 'Flynoom রেফারেন্স'],
  amountPaid: ['Amount paid', 'المبلغ المدفوع', 'Importe pagado', 'Ödenen tutar', 'Jumlah dibayar', 'भुगतान की गई राशि', 'ادا شدہ رقم', 'Montant payé', 'পরিশোধিত অর্থ'],
  hotel: ['Hotel', 'الفندق', 'Hotel', 'Otel', 'Hotel', 'होटल', 'ہوٹل', 'Hôtel', 'হোটেল'],
  phone: ['Phone', 'الهاتف', 'Teléfono', 'Telefon', 'Telepon', 'फ़ोन', 'فون', 'Téléphone', 'ফোন'],
  stay: ['Stay', 'الإقامة', 'Estancia', 'Konaklama', 'Menginap', 'ठहराव', 'قیام', 'Séjour', 'অবস্থান'],
  checkIn: ['Check-in', 'الوصول', 'Entrada', 'Giriş', 'Check-in', 'चेक-इन', 'چیک اِن', 'Arrivée', 'চেক-ইন'],
  checkOut: ['Check-out', 'المغادرة', 'Salida', 'Çıkış', 'Check-out', 'चेक-आउट', 'چیک آؤٹ', 'Départ', 'চেক-আউট'],
  nights: ['Nights', 'عدد الليالي', 'Noches', 'Gece', 'Malam', 'रातें', 'راتیں', 'Nuits', 'রাত'],
  leadGuest: ['Lead guest', 'النزيل الرئيسي', 'Huésped principal', 'Ana misafir', 'Tamu utama', 'मुख्य अतिथि', 'مرکزی مہمان', 'Voyageur principal', 'প্রধান অতিথি'],
  rooms: ['Rooms', 'الغرف', 'Habitaciones', 'Odalar', 'Kamar', 'कमरे', 'کمرے', 'Chambres', 'রুম'],
  board: ['Board', 'الوجبات', 'Régimen', 'Pansiyon', 'Paket makan', 'भोजन', 'کھانا', 'Pension', 'খাবার'],
  guestsPerRoom: ['Guests per room', 'النزلاء في كل غرفة', 'Huéspedes por habitación', 'Oda başına misafir', 'Tamu per kamar', 'प्रति कमरा अतिथि', 'فی کمرہ مہمان', 'Voyageurs par chambre', 'প্রতি রুমে অতিথি'],
  adults: ['Adults', 'البالغون', 'Adultos', 'Yetişkin', 'Dewasa', 'वयस्क', 'بالغ', 'Adultes', 'প্রাপ্তবয়স্ক'],
  children: ['Children', 'الأطفال', 'Niños', 'Çocuk', 'Anak', 'बच्चे', 'بچے', 'Enfants', 'শিশু'],
  ages: ['ages', 'الأعمار', 'edades', 'yaşlar', 'usia', 'आयु', 'عمریں', 'âges', 'বয়স'],
  payAtHotel: ['Payable at the hotel', 'يُدفع في الفندق', 'A pagar en el hotel', 'Otelde ödenecek', 'Dibayar di hotel', 'होटल में देय', 'ہوٹل میں قابلِ ادائیگی', 'À payer à l’hôtel', 'হোটেলে পরিশোধযোগ্য'],
  mandatoryNote: [
    'Mandatory fees not included in the amount paid online.',
    'رسوم إلزامية غير مشمولة في المبلغ المدفوع عبر الإنترنت.',
    'Cargos obligatorios no incluidos en el importe pagado en línea.',
    'Çevrimiçi ödenen tutara dahil olmayan zorunlu ücretler.',
    'Biaya wajib yang tidak termasuk dalam jumlah yang dibayar online.',
    'अनिवार्य शुल्क जो ऑनलाइन भुगतान की गई राशि में शामिल नहीं हैं।',
    'لازمی فیسیں جو آن لائن ادا کی گئی رقم میں شامل نہیں ہیں۔',
    'Frais obligatoires non inclus dans le montant payé en ligne.',
    'অনলাইনে পরিশোধিত অর্থে অন্তর্ভুক্ত নয় এমন বাধ্যতামূলক ফি।',
  ],
  fee: ['Fee', 'رسوم', 'Cargo', 'Ücret', 'Biaya', 'शुल्क', 'فیس', 'Frais', 'ফি'],
  cancelPolicy: ['Cancellation policy', 'سياسة الإلغاء', 'Política de cancelación', 'İptal politikası', 'Kebijakan pembatalan', 'रद्दीकरण नीति', 'منسوخی کی پالیسی', 'Politique d’annulation', 'বাতিল নীতি'],
  freeCancel: ['Free cancellation.', 'إلغاء مجاني.', 'Cancelación gratuita.', 'Ücretsiz iptal.', 'Pembatalan gratis.', 'मुफ़्त रद्दीकरण।', 'مفت منسوخی۔', 'Annulation gratuite.', 'বিনামূল্যে বাতিল।'],
  freeUntil: [
    'Free cancellation until <b>{t}</b> (hotel local time).',
    'إلغاء مجاني حتى <b>{t}</b> (بتوقيت الفندق).',
    'Cancelación gratuita hasta el <b>{t}</b> (hora local del hotel).',
    '<b>{t}</b> tarihine kadar ücretsiz iptal (otelin yerel saati).',
    'Pembatalan gratis hingga <b>{t}</b> (waktu setempat hotel).',
    '<b>{t}</b> तक मुफ़्त रद्दीकरण (होटल का स्थानीय समय)।',
    '<b>{t}</b> تک مفت منسوخی (ہوٹل کا مقامی وقت)۔',
    'Annulation gratuite jusqu’au <b>{t}</b> (heure locale de l’hôtel).',
    '<b>{t}</b> পর্যন্ত বিনামূল্যে বাতিল (হোটেলের স্থানীয় সময়)।',
  ],
  noFree: [
    'No free cancellation: a cancellation fee applies if you cancel now.',
    'لا يوجد إلغاء مجاني: تُطبَّق رسوم إلغاء إذا ألغيت الآن.',
    'Sin cancelación gratuita: se aplica un cargo si cancelas ahora.',
    'Ücretsiz iptal yok: şimdi iptal ederseniz iptal ücreti uygulanır.',
    'Tidak ada pembatalan gratis: biaya pembatalan berlaku jika Anda membatalkan sekarang.',
    'मुफ़्त रद्दीकरण नहीं: अभी रद्द करने पर रद्दीकरण शुल्क लगेगा।',
    'مفت منسوخی نہیں: ابھی منسوخ کرنے پر منسوخی فیس لاگو ہوگی۔',
    'Pas d’annulation gratuite : des frais s’appliquent si vous annulez maintenant.',
    'বিনামূল্যে বাতিল নেই: এখন বাতিল করলে বাতিল ফি প্রযোজ্য।',
  ],
  feeFrom: [
    'From {t} (hotel local time): cancellation fee {fee}',
    'من {t} (بتوقيت الفندق): رسوم الإلغاء {fee}',
    'Desde el {t} (hora local del hotel): cargo de cancelación {fee}',
    '{t} itibarıyla (otelin yerel saati): iptal ücreti {fee}',
    'Mulai {t} (waktu setempat hotel): biaya pembatalan {fee}',
    '{t} से (होटल का स्थानीय समय): रद्दीकरण शुल्क {fee}',
    '{t} سے (ہوٹل کا مقامی وقت): منسوخی فیس {fee}',
    'À partir du {t} (heure locale de l’hôtel) : frais d’annulation {fee}',
    '{t} থেকে (হোটেলের স্থানীয় সময়): বাতিল ফি {fee}',
  ],
  importantInfo: ['Important information', 'معلومات مهمة من الفندق', 'Información importante', 'Önemli bilgiler', 'Informasi penting', 'महत्वपूर्ण जानकारी', 'اہم معلومات', 'Informations importantes', 'গুরুত্বপূর্ণ তথ্য'],
  subjConfirmed: [
    'Booking confirmed: {hotel} · {date} (Ref {ref})',
    'تم تأكيد الحجز: {hotel} · {date} (رقم {ref})',
    'Reserva confirmada: {hotel} · {date} (Ref. {ref})',
    'Rezervasyon onaylandı: {hotel} · {date} (Ref {ref})',
    'Pemesanan dikonfirmasi: {hotel} · {date} (Ref {ref})',
    'बुकिंग की पुष्टि: {hotel} · {date} (संदर्भ {ref})',
    'بکنگ کی تصدیق: {hotel} · {date} (حوالہ {ref})',
    'Réservation confirmée : {hotel} · {date} (Réf. {ref})',
    'বুকিং নিশ্চিত: {hotel} · {date} (রেফ {ref})',
  ],
  cancelledSection: ['Cancelled booking', 'الحجز الملغى', 'Reserva cancelada', 'İptal edilen rezervasyon', 'Pemesanan yang dibatalkan', 'रद्द की गई बुकिंग', 'منسوخ شدہ بکنگ', 'Réservation annulée', 'বাতিল বুকিং'],
  dates: ['Dates', 'التواريخ', 'Fechas', 'Tarihler', 'Tanggal', 'तारीखें', 'تاریخیں', 'Dates', 'তারিখ'],
  cancelRef: ['Cancellation reference', 'رقم الإلغاء', 'Referencia de cancelación', 'İptal referansı', 'Referensi pembatalan', 'रद्दीकरण संदर्भ', 'منسوخی کا حوالہ', 'Référence d’annulation', 'বাতিল রেফারেন্স'],
  cancelFee: ['Cancellation fee', 'رسوم الإلغاء', 'Cargo de cancelación', 'İptal ücreti', 'Biaya pembatalan', 'रद्दीकरण शुल्क', 'منسوخی فیس', 'Frais d’annulation', 'বাতিল ফি'],
  refund: ['Refund', 'المبلغ المسترد', 'Reembolso', 'İade', 'Pengembalian dana', 'धनवापसी', 'رقم کی واپسی', 'Remboursement', 'ফেরত'],
  refundNote: [
    'Your refund has been issued to the card you paid with. It usually appears within 5–10 business days, depending on your bank.',
    'أُعيد المبلغ إلى البطاقة التي دفعت بها، ويظهر عادةً خلال 5–10 أيام عمل حسب بنكك.',
    'El reembolso se ha emitido a la tarjeta con la que pagaste. Suele aparecer en 5–10 días hábiles, según tu banco.',
    'İadeniz ödeme yaptığınız karta gönderildi. Bankanıza bağlı olarak genellikle 5–10 iş günü içinde görünür.',
    'Pengembalian dana telah dikirim ke kartu yang Anda gunakan. Biasanya muncul dalam 5–10 hari kerja, tergantung bank Anda.',
    'धनवापसी उसी कार्ड पर भेज दी गई है जिससे आपने भुगतान किया था। आपके बैंक के अनुसार यह आमतौर पर 5–10 कार्यदिवसों में दिखती है।',
    'رقم اسی کارڈ پر واپس بھیج دی گئی ہے جس سے آپ نے ادائیگی کی تھی۔ آپ کے بینک کے مطابق یہ عموماً 5–10 کاروباری دنوں میں نظر آتی ہے۔',
    'Le remboursement a été émis sur la carte utilisée pour le paiement. Il apparaît généralement sous 5 à 10 jours ouvrés, selon votre banque.',
    'যে কার্ডে পরিশোধ করেছিলেন সেখানে ফেরত পাঠানো হয়েছে। ব্যাংকভেদে সাধারণত 5–10 কার্যদিবসে দেখা যায়।',
  ],
  subjCancelled: [
    'Booking cancelled: {hotel} (Ref {ref})',
    'تم إلغاء الحجز: {hotel} (رقم {ref})',
    'Reserva cancelada: {hotel} (Ref. {ref})',
    'Rezervasyon iptal edildi: {hotel} (Ref {ref})',
    'Pemesanan dibatalkan: {hotel} (Ref {ref})',
    'बुकिंग रद्द: {hotel} (संदर्भ {ref})',
    'بکنگ منسوخ: {hotel} (حوالہ {ref})',
    'Réservation annulée : {hotel} (Réf. {ref})',
    'বুকিং বাতিল: {hotel} (রেফ {ref})',
  ],
  cancelledHeading: ['Your booking has been cancelled', 'تم إلغاء حجزك', 'Tu reserva ha sido cancelada', 'Rezervasyonunuz iptal edildi', 'Pemesanan Anda telah dibatalkan', 'आपकी बुकिंग रद्द कर दी गई है', 'آپ کی بکنگ منسوخ کر دی گئی ہے', 'Votre réservation a été annulée', 'আপনার বুকিং বাতিল করা হয়েছে'],
  cancelIntroUser: [
    'Hi {name}, your booking has been cancelled as requested.',
    'مرحبًا {name}، تم إلغاء حجزك بناءً على طلبك.',
    'Hola {name}, tu reserva se ha cancelado según lo solicitado.',
    'Merhaba {name}, rezervasyonunuz talebiniz üzerine iptal edildi.',
    'Halo {name}, pemesanan Anda telah dibatalkan sesuai permintaan.',
    'नमस्ते {name}, आपके अनुरोध पर आपकी बुकिंग रद्द कर दी गई है।',
    'محترم {name}، آپ کی درخواست پر آپ کی بکنگ منسوخ کر دی گئی ہے۔',
    'Bonjour {name}, votre réservation a été annulée comme demandé.',
    'হ্যালো {name}, আপনার অনুরোধ অনুযায়ী বুকিং বাতিল করা হয়েছে।',
  ],
  cancelIntroFlynoom: [
    "Hi {name}, we were unable to keep this booking, so it has been cancelled and your payment refunded in full. If you didn't expect this or still need a room, please contact support@flynoom.com.",
    'مرحبًا {name}، لم نتمكن من الإبقاء على هذا الحجز، فأُلغي وأُعيد إليك المبلغ كاملًا. إذا لم تكن تتوقع ذلك أو ما زلت تحتاج غرفة، فتواصل معنا على support@flynoom.com.',
    'Hola {name}, no pudimos mantener esta reserva, así que se ha cancelado y te hemos reembolsado el importe completo. Si no lo esperabas o aún necesitas una habitación, escribe a support@flynoom.com.',
    'Merhaba {name}, bu rezervasyonu sürdüremedik; bu nedenle iptal edildi ve ödemenizin tamamı iade edildi. Bunu beklemiyorsanız veya hâlâ odaya ihtiyacınız varsa support@flynoom.com adresine yazın.',
    'Halo {name}, kami tidak dapat mempertahankan pemesanan ini, sehingga pemesanan dibatalkan dan pembayaran Anda dikembalikan penuh. Jika Anda tidak mengharapkan ini atau masih membutuhkan kamar, hubungi support@flynoom.com.',
    'नमस्ते {name}, हम यह बुकिंग बनाए नहीं रख सके, इसलिए इसे रद्द कर दिया गया है और आपका पूरा भुगतान वापस कर दिया गया है। यदि आपको इसकी उम्मीद नहीं थी या अब भी कमरा चाहिए, तो support@flynoom.com पर संपर्क करें।',
    'محترم {name}، ہم یہ بکنگ برقرار نہیں رکھ سکے، اس لیے اسے منسوخ کر کے آپ کی پوری رقم واپس کر دی گئی ہے۔ اگر آپ کو اس کی توقع نہیں تھی یا اب بھی کمرہ چاہیے تو support@flynoom.com سے رابطہ کریں۔',
    'Bonjour {name}, nous n’avons pas pu maintenir cette réservation : elle a été annulée et votre paiement intégralement remboursé. Si vous ne vous y attendiez pas ou avez toujours besoin d’une chambre, écrivez à support@flynoom.com.',
    'হ্যালো {name}, আমরা এই বুকিংটি বহাল রাখতে পারিনি, তাই এটি বাতিল করে আপনার পুরো অর্থ ফেরত দেওয়া হয়েছে। এটি প্রত্যাশিত না হলে বা এখনো রুম প্রয়োজন হলে support@flynoom.com-এ যোগাযোগ করুন।',
  ],
  attemptSection: ['Booking attempt', 'محاولة الحجز', 'Intento de reserva', 'Rezervasyon denemesi', 'Percobaan pemesanan', 'बुकिंग का प्रयास', 'بکنگ کی کوشش', 'Tentative de réservation', 'বুকিংয়ের চেষ্টা'],
  amountHeld: ['Amount held', 'المبلغ المحجوز', 'Importe retenido', 'Bloke edilen tutar', 'Jumlah yang ditahan', 'रोकी गई राशि', 'روکی گئی رقم', 'Montant bloqué', 'আটকে রাখা অর্থ'],
  notCharged: [
    '<b>You have not been charged.</b> The temporary hold on your card has been released. Depending on your bank, it can take a few business days to disappear from your statement.',
    '<b>لم يُسحب منك أي مبلغ.</b> أُلغي التجميد المؤقت على بطاقتك، وقد يستغرق اختفاؤه من كشف الحساب بضعة أيام عمل حسب بنكك.',
    '<b>No se te ha cobrado nada.</b> La retención temporal en tu tarjeta se ha liberado. Según tu banco, puede tardar unos días hábiles en desaparecer de tu extracto.',
    '<b>Sizden ücret alınmadı.</b> Kartınızdaki geçici bloke kaldırıldı. Bankanıza bağlı olarak hesap özetinizden kalkması birkaç iş günü sürebilir.',
    '<b>Anda tidak dikenakan biaya.</b> Penahanan sementara pada kartu Anda telah dilepas. Tergantung bank Anda, perlu beberapa hari kerja hingga hilang dari laporan rekening.',
    '<b>आपसे कोई शुल्क नहीं लिया गया है।</b> आपके कार्ड पर अस्थायी रोक हटा दी गई है। आपके बैंक के अनुसार इसे स्टेटमेंट से हटने में कुछ कार्यदिवस लग सकते हैं।',
    '<b>آپ سے کوئی رقم نہیں لی گئی۔</b> آپ کے کارڈ پر عارضی روک ختم کر دی گئی ہے۔ آپ کے بینک کے مطابق اسے اسٹیٹمنٹ سے ہٹنے میں چند کاروباری دن لگ سکتے ہیں۔',
    '<b>Aucun montant ne vous a été débité.</b> Le blocage temporaire sur votre carte a été levé. Selon votre banque, il peut mettre quelques jours ouvrés à disparaître de votre relevé.',
    '<b>আপনার কাছ থেকে কোনো অর্থ কাটা হয়নি।</b> আপনার কার্ডের সাময়িক হোল্ড তুলে নেওয়া হয়েছে। ব্যাংকভেদে স্টেটমেন্ট থেকে সরতে কয়েক কার্যদিবস লাগতে পারে।',
  ],
  sorry: [
    "We're sorry for the inconvenience. You're welcome to search again on {link} and choose another room or hotel.",
    'نعتذر عن الإزعاج. يمكنك البحث من جديد على {link} واختيار غرفة أو فندق آخر.',
    'Lamentamos las molestias. Puedes buscar de nuevo en {link} y elegir otra habitación u hotel.',
    'Yaşanan aksaklık için özür dileriz. {link} üzerinden yeniden arama yapıp başka bir oda veya otel seçebilirsiniz.',
    'Mohon maaf atas ketidaknyamanannya. Silakan cari lagi di {link} dan pilih kamar atau hotel lain.',
    'असुविधा के लिए खेद है। आप {link} पर फिर से खोज करके कोई दूसरा कमरा या होटल चुन सकते हैं।',
    'زحمت کے لیے معذرت۔ آپ {link} پر دوبارہ تلاش کر کے کوئی اور کمرہ یا ہوٹل منتخب کر سکتے ہیں۔',
    'Nous sommes désolés pour la gêne occasionnée. Vous pouvez relancer une recherche sur {link} et choisir une autre chambre ou un autre hôtel.',
    'অসুবিধার জন্য দুঃখিত। আপনি {link}-এ আবার খুঁজে অন্য রুম বা হোটেল বেছে নিতে পারেন।',
  ],
  subjNotCompleted: [
    'Booking not completed: {hotel} (Ref {ref})',
    'لم يكتمل الحجز: {hotel} (مرجع {ref})',
    'Reserva no completada: {hotel} (Ref. {ref})',
    'Rezervasyon tamamlanamadı: {hotel} (Ref {ref})',
    'Pemesanan tidak selesai: {hotel} (Ref {ref})',
    'बुकिंग पूरी नहीं हुई: {hotel} (संदर्भ {ref})',
    'بکنگ مکمل نہیں ہوئی: {hotel} (حوالہ {ref})',
    'Réservation non finalisée : {hotel} (Réf. {ref})',
    'বুকিং সম্পন্ন হয়নি: {hotel} (রেফ {ref})',
  ],
  notCompletedHeading: ['Your booking could not be completed', 'تعذّر إتمام حجزك', 'No se pudo completar tu reserva', 'Rezervasyonunuz tamamlanamadı', 'Pemesanan Anda tidak dapat diselesaikan', 'आपकी बुकिंग पूरी नहीं हो सकी', 'آپ کی بکنگ مکمل نہیں ہو سکی', 'Votre réservation n’a pas pu être finalisée', 'আপনার বুকিং সম্পন্ন করা যায়নি'],
  notCompletedIntro: [
    'Hi {name}, unfortunately the hotel could not confirm your booking.',
    'مرحبًا {name}، للأسف لم يتمكن الفندق من تأكيد حجزك.',
    'Hola {name}, lamentablemente el hotel no pudo confirmar tu reserva.',
    'Merhaba {name}, maalesef otel rezervasyonunuzu onaylayamadı.',
    'Halo {name}, sayangnya hotel tidak dapat mengonfirmasi pemesanan Anda.',
    'नमस्ते {name}, दुर्भाग्य से होटल आपकी बुकिंग की पुष्टि नहीं कर सका।',
    'محترم {name}، افسوس کہ ہوٹل آپ کی بکنگ کی تصدیق نہیں کر سکا۔',
    'Bonjour {name}, malheureusement l’hôtel n’a pas pu confirmer votre réservation.',
    'হ্যালো {name}, দুঃখজনকভাবে হোটেল আপনার বুকিং নিশ্চিত করতে পারেনি।',
  ],
  // ── إيميل الترحيب (welcome-email) ──
  welcomeSubject: ['Welcome to Flynoom', 'أهلًا بك في Flynoom', 'Te damos la bienvenida a Flynoom', 'Flynoom’a hoş geldiniz', 'Selamat datang di Flynoom', 'Flynoom में आपका स्वागत है', 'Flynoom میں خوش آمدید', 'Bienvenue sur Flynoom', 'Flynoom-এ স্বাগতম'],
  welcomeHeading: ['Welcome to Flynoom!', 'أهلًا وسهلًا بك في Flynoom!', '¡Te damos la bienvenida a Flynoom!', 'Flynoom’a hoş geldiniz!', 'Selamat datang di Flynoom!', 'Flynoom में आपका स्वागत है!', 'Flynoom میں خوش آمدید!', 'Bienvenue sur Flynoom !', 'Flynoom-এ স্বাগতম!'],
  hiName: ['Hi {name},', 'مرحبًا {name}،', 'Hola {name}:', 'Merhaba {name},', 'Halo {name},', 'नमस्ते {name},', 'محترم {name}،', 'Bonjour {name},', 'হ্যালো {name},'],
  hiPlain: ['Hello,', 'مرحبًا،', 'Hola:', 'Merhaba,', 'Halo,', 'नमस्ते,', 'السلام علیکم،', 'Bonjour,', 'হ্যালো,'],
  welcomeIntro: [
    'Thank you for creating your Flynoom account. We’re glad to have you with us! Here is what you can do on Flynoom, in your language:',
    'شكرًا لإنشائك حسابًا في Flynoom، يسعدنا انضمامك إلينا! هذا ما تستطيع فعله على Flynoom، بلغتك:',
    'Gracias por crear tu cuenta en Flynoom. ¡Nos alegra tenerte con nosotros! Esto es lo que puedes hacer en Flynoom, en tu idioma:',
    'Flynoom hesabınızı oluşturduğunuz için teşekkürler. Aramızda olmanıza çok sevindik! Flynoom’da kendi dilinizde yapabilecekleriniz:',
    'Terima kasih telah membuat akun Flynoom. Kami senang Anda bergabung! Inilah yang dapat Anda lakukan di Flynoom, dalam bahasa Anda:',
    'Flynoom खाता बनाने के लिए धन्यवाद। आपको हमारे साथ पाकर हमें खुशी है! Flynoom पर आप अपनी भाषा में यह सब कर सकते हैं:',
    'Flynoom اکاؤنٹ بنانے کا شکریہ۔ آپ کو اپنے ساتھ پا کر ہمیں خوشی ہے! Flynoom پر آپ اپنی زبان میں یہ سب کر سکتے ہیں:',
    'Merci d’avoir créé votre compte Flynoom. Nous sommes ravis de vous compter parmi nous ! Voici ce que vous pouvez faire sur Flynoom, dans votre langue :',
    'Flynoom অ্যাকাউন্ট খোলার জন্য ধন্যবাদ। আপনাকে আমাদের সাথে পেয়ে আমরা আনন্দিত! Flynoom-এ আপনার ভাষায় যা করতে পারবেন:',
  ],
  wHotels: [
    'Book hotels in the U.S. and around the world, and see the full price before you pay.',
    'احجز فنادق في أمريكا وحول العالم، وشاهد السعر الكامل قبل الدفع.',
    'Reserva hoteles en EE. UU. y en todo el mundo, y ve el precio total antes de pagar.',
    'ABD’de ve dünyanın her yerinde otel rezervasyonu yapın, ödemeden önce toplam fiyatı görün.',
    'Pesan hotel di AS dan di seluruh dunia, dan lihat harga lengkap sebelum membayar.',
    'अमेरिका और दुनिया भर में होटल बुक करें, और भुगतान से पहले पूरी कीमत देखें।',
    'امریکہ اور دنیا بھر میں ہوٹل بک کریں، اور ادائیگی سے پہلے پوری قیمت دیکھیں۔',
    'Réservez des hôtels aux États-Unis et dans le monde entier, et voyez le prix total avant de payer.',
    'যুক্তরাষ্ট্রে ও সারা বিশ্বে হোটেল বুক করুন, আর পরিশোধের আগে পুরো দাম দেখুন।',
  ],
  wUmrah: [
    'Umrah: hotels in Makkah and Madinah, sorted by distance from the Haram.',
    'العمرة: فنادق في مكة المكرمة والمدينة المنورة، مرتبة حسب المسافة من الحرم.',
    'Umrah: hoteles en La Meca y Medina, ordenados por distancia al Haram.',
    'Umre: Mekke ve Medine’de, Harem’e uzaklığa göre sıralanmış oteller.',
    'Umrah: hotel di Makkah dan Madinah, diurutkan berdasarkan jarak dari Masjidil Haram.',
    'उमरा: मक्का और मदीना के होटल, हरम से दूरी के अनुसार क्रम में।',
    'عمرہ: مکہ مکرمہ اور مدینہ منورہ کے ہوٹل، حرم سے فاصلے کے لحاظ سے ترتیب میں۔',
    'Omra : hôtels à La Mecque et à Médine, classés selon la distance au Haram.',
    'উমরাহ: মক্কা ও মদিনার হোটেল, হারাম থেকে দূরত্ব অনুযায়ী সাজানো।',
  ],
  wGroups: [
    'Group stays: traveling with family or a group (5+ rooms)? Request a quote in one step.',
    'إقامات المجموعات: مسافر مع العائلة أو مجموعة (5 غرف فأكثر)؟ اطلب عرض سعر بخطوة واحدة.',
    'Estancias en grupo: ¿viajas en familia o en grupo (5+ habitaciones)? Pide un presupuesto en un paso.',
    'Grup konaklamaları: Ailenizle veya grupla mı seyahat ediyorsunuz (5+ oda)? Tek adımda fiyat teklifi isteyin.',
    'Menginap rombongan: bepergian bersama keluarga atau rombongan (5+ kamar)? Minta penawaran dalam satu langkah.',
    'ग्रुप स्टे: परिवार या समूह के साथ यात्रा (5+ कमरे)? एक ही कदम में कोटेशन मांगें।',
    'گروپ قیام: خاندان یا گروپ کے ساتھ سفر (5 یا زیادہ کمرے)؟ ایک قدم میں قیمت کی پیشکش منگوائیں۔',
    'Séjours de groupe : vous voyagez en famille ou en groupe (5 chambres ou plus) ? Demandez un devis en une étape.',
    'গ্রুপ স্টে: পরিবার বা দলের সাথে ভ্রমণ (৫+ রুম)? এক ধাপে কোটেশন চান।',
  ],
  wPay: [
    'Secure payment: the amount is only held on your card, and charged once the hotel confirms your booking.',
    'دفع آمن: يُحجز المبلغ على بطاقتك فقط، ولا يُسحب إلا بعد أن يؤكد الفندق حجزك.',
    'Pago seguro: el importe solo se retiene en tu tarjeta y se cobra cuando el hotel confirma tu reserva.',
    'Güvenli ödeme: tutar yalnızca kartınızda bloke edilir ve otel rezervasyonunuzu onayladığında tahsil edilir.',
    'Pembayaran aman: jumlahnya hanya ditahan di kartu Anda, dan ditagih setelah hotel mengonfirmasi pemesanan.',
    'सुरक्षित भुगतान: राशि केवल आपके कार्ड पर रोकी जाती है, और होटल की पुष्टि के बाद ही ली जाती है।',
    'محفوظ ادائیگی: رقم صرف آپ کے کارڈ پر روکی جاتی ہے، اور ہوٹل کی تصدیق کے بعد ہی لی جاتی ہے۔',
    'Paiement sécurisé : le montant est seulement bloqué sur votre carte, et débité une fois que l’hôtel confirme la réservation.',
    'নিরাপদ পেমেন্ট: অর্থ শুধু আপনার কার্ডে আটকে রাখা হয়, আর হোটেল বুকিং নিশ্চিত করলে তবেই কাটা হয়।',
  ],
  wCta: ['Find your hotel', 'ابحث عن فندقك', 'Encuentra tu hotel', 'Otelinizi bulun', 'Temukan hotel Anda', 'अपना होटल खोजें', 'اپنا ہوٹل تلاش کریں', 'Trouvez votre hôtel', 'আপনার হোটেল খুঁজুন'],
  wWish: [
    'We wish you wonderful stays and happy travels!',
    'نتمنى لك إقامات ممتعة ورحلات سعيدة!',
    '¡Te deseamos estancias maravillosas y buenos viajes!',
    'Size harika konaklamalar ve keyifli yolculuklar dileriz!',
    'Semoga menginap Anda menyenangkan dan perjalanan Anda lancar!',
    'हम आपको शानदार ठहराव और सुखद यात्राओं की शुभकामनाएँ देते हैं!',
    'ہم آپ کے لیے خوشگوار قیام اور اچھے سفر کی دعا کرتے ہیں!',
    'Nous vous souhaitons d’excellents séjours et de bons voyages !',
    'আপনার প্রতিটি অবস্থান ও ভ্রমণ আনন্দময় হোক!',
  ],
  wTeam: ['The Flynoom team', 'فريق Flynoom', 'El equipo de Flynoom', 'Flynoom ekibi', 'Tim Flynoom', 'Flynoom टीम', 'Flynoom ٹیم', 'L’équipe Flynoom', 'Flynoom টিম'],
  wUsOnly: [
    'Bookings on Flynoom are available to residents of the United States and Iraq. You can book for guests from any country.',
    'الحجز عبر Flynoom متاح للمقيمين في الولايات المتحدة والعراق، ويمكنك الحجز لنزلاء من أي بلد.',
    'Las reservas en Flynoom están disponibles para residentes de EE. UU. e Irak. Puedes reservar para huéspedes de cualquier país.',
    'Flynoom’da rezervasyon ABD’de ve Irak’ta ikamet edenlere açıktır. Her ülkeden misafir için rezervasyon yapabilirsiniz.',
    'Pemesanan di Flynoom tersedia bagi penduduk AS dan Irak. Anda dapat memesan untuk tamu dari negara mana pun.',
    'Flynoom पर बुकिंग अमेरिका और इराक के निवासियों के लिए उपलब्ध है। आप किसी भी देश के मेहमानों के लिए बुकिंग कर सकते हैं।',
    'Flynoom پر بکنگ امریکہ اور عراق کے رہائشیوں کے لیے دستیاب ہے۔ آپ کسی بھی ملک کے مہمانوں کے لیے بکنگ کر سکتے ہیں۔',
    'Les réservations sur Flynoom sont ouvertes aux résidents des États-Unis et de l’Irak. Vous pouvez réserver pour des voyageurs de n’importe quel pays.',
    'Flynoom-এ বুকিং মার্কিন যুক্তরাষ্ট্র ও ইরাকের বাসিন্দাদের জন্য। আপনি যেকোনো দেশের অতিথির জন্য বুকিং করতে পারেন।',
  ],
  wOneTime: [
    'This is a one-time welcome message because you created a Flynoom account. We don’t send marketing emails unless you choose to receive them.',
    'هذه رسالة ترحيب لمرة واحدة لأنك أنشأت حسابًا في Flynoom. لا نرسل رسائل تسويقية إلا إذا اخترت استلامها.',
    'Este es un mensaje de bienvenida único porque creaste una cuenta en Flynoom. No enviamos correos de marketing a menos que elijas recibirlos.',
    'Bu, bir Flynoom hesabı oluşturduğunuz için gönderilen tek seferlik bir hoş geldin mesajıdır. Siz istemedikçe pazarlama e-postası göndermeyiz.',
    'Ini adalah pesan sambutan satu kali karena Anda membuat akun Flynoom. Kami tidak mengirim email pemasaran kecuali Anda memilih untuk menerimanya.',
    'यह एक बार का स्वागत संदेश है क्योंकि आपने Flynoom खाता बनाया है। आपके चुने बिना हम मार्केटिंग ईमेल नहीं भेजते।',
    'یہ ایک بار کا خوش آمدید پیغام ہے کیونکہ آپ نے Flynoom اکاؤنٹ بنایا ہے۔ آپ کی مرضی کے بغیر ہم مارکیٹنگ ای میلز نہیں بھیجتے۔',
    'Ceci est un message de bienvenue unique, car vous avez créé un compte Flynoom. Nous n’envoyons pas d’e-mails marketing sans votre accord.',
    'আপনি Flynoom অ্যাকাউন্ট খুলেছেন বলে এটি একবারের স্বাগত বার্তা। আপনি না চাইলে আমরা মার্কেটিং ইমেইল পাঠাই না।',
  ],
  footer: [
    'Questions? Reply to this email.',
    'لديك سؤال؟ رُدّ على هذا البريد.',
    '¿Preguntas? Responde a este correo.',
    'Sorunuz mu var? Bu e-postayı yanıtlayın.',
    'Ada pertanyaan? Balas email ini.',
    'कोई सवाल? इस ईमेल का जवाब दें।',
    'کوئی سوال؟ اس ای میل کا جواب دیں۔',
    'Des questions ? Répondez à cet e-mail.',
    'প্রশ্ন আছে? এই ইমেইলের উত্তর দিন।',
  ],
};

/// النص المترجم مع استبدال {متغيرات} (القيم تُمرَّر جاهزة/مُهرَّبة).
function tr(lang: EmailLang, key: keyof typeof T, vars: Record<string, string> = {}): string {
  const row = T[key];
  let s = row[EMAIL_LANGS.indexOf(lang)] ?? row[0];
  for (const [k, v] of Object.entries(vars)) s = s.split(`{${k}}`).join(v);
  return s;
}

function langOf(b: any): EmailLang {
  return emailLocale(b?.locale);
}

function esc(v: unknown): string {
  return String(v ?? '')
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;');
}

function titleCase(s: string): string {
  return s.toLowerCase().replace(/(^|\s)(\S)/g, (_m, sp, c) => sp + c.toUpperCase());
}

function usd(n: unknown): string {
  const v = Number(n);
  return Number.isFinite(v) ? `$${v.toFixed(2)}` : '—';
}

/// أرقام لاتينية دائمًا (حتى في العربية والبنغالية)، لتطابق أرقام الحجز والمبالغ.
function intlLocale(lang: EmailLang): string {
  return `${lang === 'en' ? 'en-US' : lang}-u-nu-latn`;
}

/// "2026-11-10" → "Tue, Nov 10, 2026" بلغة الزبون (بدون تحويل منطقة زمنية).
function localDate(d: unknown, lang: EmailLang): string {
  const m = /^(\d{4})-(\d{2})-(\d{2})/.exec(String(d ?? ''));
  if (!m) return esc(d);
  const dt = new Date(Date.UTC(+m[1], +m[2] - 1, +m[3]));
  try {
    return dt.toLocaleDateString(intlLocale(lang), {
      weekday: 'short', month: 'short', day: 'numeric', year: 'numeric', timeZone: 'UTC',
    });
  } catch {
    return dt.toLocaleDateString('en-US', {
      weekday: 'short', month: 'short', day: 'numeric', year: 'numeric', timeZone: 'UTC',
    });
  }
}

/// "2026-11-08T23:59:00-05:00" → "Nov 8, 2026 23:59" كما هو بتوقيت الفندق، بلغة الزبون.
function hotelLocal(s: unknown, lang: EmailLang): string {
  const m = /^(\d{4})-(\d{2})-(\d{2})T(\d{2}):(\d{2})/.exec(String(s ?? ''));
  if (!m) return esc(s);
  const dt = new Date(Date.UTC(+m[1], +m[2] - 1, +m[3]));
  let day: string;
  try {
    day = dt.toLocaleDateString(intlLocale(lang), { month: 'short', day: 'numeric', year: 'numeric', timeZone: 'UTC' });
  } catch {
    day = dt.toLocaleDateString('en-US', { month: 'short', day: 'numeric', year: 'numeric', timeZone: 'UTC' });
  }
  return `${day} ${m[4]}:${m[5]}`;
}

function nights(b: any): number {
  const a = Date.parse(String(b.check_in).slice(0, 10));
  const c = Date.parse(String(b.check_out).slice(0, 10));
  return Number.isFinite(a) && Number.isFinite(c) ? Math.max(1, Math.round((c - a) / 86400000)) : 1;
}

function row(label: string, value: string): string {
  return `<tr><td style="padding:4px 12px;color:#6b7280;white-space:nowrap;vertical-align:top">${label}</td>` +
    `<td style="padding:4px 0;font-weight:600">${value}</td></tr>`;
}

function section(title: string, body: string): string {
  return `<div style="margin-top:20px"><div style="font-size:12px;letter-spacing:1px;font-weight:700;color:#6b7280;text-transform:uppercase;margin-bottom:6px">${title}</div>${body}</div>`;
}

/// قيمة لاتينية (مرجع، مبلغ، بريد) داخل نص من اليمين لليسار: نعزلها حتى لا تنقلب.
function ltr(v: string): string {
  return `<span dir="ltr" style="unicode-bidi:isolate">${v}</span>`;
}

function layout(lang: EmailLang, heading: string, intro: string, content: string): string {
  const rtl = RTL.has(lang);
  const dir = rtl ? 'rtl' : 'ltr';
  const align = rtl ? 'right' : 'left';
  return `<!doctype html><html lang="${lang}" dir="${dir}"><body style="margin:0;background:#f3f4f6;font-family:Arial,Helvetica,sans-serif;color:#111827">
<div dir="${dir}" style="max-width:640px;margin:0 auto;padding:24px 12px;text-align:${align}">
<div style="background:#ffffff;border-radius:10px;padding:28px">
<img src="${LOGO_URL}" alt="FLYNOOM" width="180" height="40" style="display:block;border:0;outline:none;height:auto;max-width:180px;font-size:24px;font-weight:900;letter-spacing:2px;color:#0b3a6b">
<h1 style="font-size:20px;margin:16px 0 6px">${heading}</h1>
<p style="margin:0 0 8px;color:#374151">${intro}</p>
${content}
</div>
<p style="font-size:12px;color:#9ca3af;text-align:center;margin-top:16px">FLYNOOM LLC · flynoom.com · ${tr(lang, 'footer')}</p>
</div></body></html>`;
}

function roomsHtml(b: any, lang: EmailLang): string {
  const rooms: any[] = b?.supplier_response?.booking?.hotel?.rooms ?? [];
  if (rooms.length === 0) {
    return `<div>${esc(titleCase(String(b.room_name ?? '')))}${b.board_name ? ` · ${esc(titleCase(b.board_name))}` : ''}</div>`;
  }
  return rooms.map((r) => {
    const rate = r?.rates?.[0] ?? {};
    const paxes: any[] = r?.paxes ?? [];
    const ages = paxes.filter((p) => p?.type === 'CH').map((p) => p?.age).filter((a) => a != null);
    const adults = rate.adults ?? paxes.filter((p) => p?.type === 'AD').length;
    const children = rate.children ?? ages.length;
    const guests = `${tr(lang, 'adults')}: ${esc(adults)}` +
      (children > 0 ? `, ${tr(lang, 'children')}: ${esc(children)}` : '') +
      (ages.length ? ` (${tr(lang, 'ages')} ${esc(ages.join(', '))})` : '');
    return `<div style="margin-bottom:8px">
<div style="font-weight:600">${esc(rate.rooms ?? 1)} × ${esc(titleCase(String(r.name ?? '')))}</div>
${rate.boardName ? `<div>${tr(lang, 'board')}: ${esc(titleCase(rate.boardName))}</div>` : ''}
<div>${tr(lang, 'guestsPerRoom')}: ${guests}</div>
</div>`;
  }).join('');
}

function cancellationHtml(b: any, lang: EmailLang): string {
  const policies: any[] = Array.isArray(b.cancellation_policies) ? [...b.cancellation_policies] : [];
  if (policies.length === 0) return `<div>${tr(lang, 'freeCancel')}</div>`;
  policies.sort((x, y) => String(x.from).localeCompare(String(y.from)));
  const now = Date.now();
  const first = policies[0];
  const firstTime = Date.parse(first.from);
  let html = '';
  if (Number.isFinite(firstTime) && firstTime > now) {
    html += `<div>${tr(lang, 'freeUntil', { t: hotelLocal(first.from, lang) })}</div>`;
  } else if (Number.isFinite(firstTime)) {
    // الموعد الأول للرسوم مرّ بالفعل: لا يوجد إلغاء مجاني الآن. نقولها صراحة
    // بدل عرض تاريخ قد يفهمه العميل في أمريكا كموعد ما زال قادمًا.
    html += `<div style="color:#b91c1c;font-weight:700">${tr(lang, 'noFree')}</div>`;
  }
  for (const p of policies) {
    const fee = p.customerFee ?? p.amountUsd;
    html += `<div style="color:#374151">${tr(lang, 'feeFrom', { t: hotelLocal(p.from, lang), fee: ltr(usd(fee)) })}</div>`;
  }
  return html;
}

function payAtHotelHtml(b: any, lang: EmailLang): string {
  const fees: any[] = Array.isArray(b.pay_at_hotel_fees) ? b.pay_at_hotel_fees : [];
  if (fees.length === 0) return '';
  const lines = fees.map((f) =>
    // نوع الرسم يأتي بالإنجليزية من HotelBeds (مثل Tourism Dirham)، فنعزل السطر كله LTR.
    `<div>${f.type
      ? ltr(`${esc(titleCase(String(f.type)))}: ${esc(Number(f.amount ?? 0).toFixed(2))} ${esc(f.currency ?? '')}`)
      : `${tr(lang, 'fee')}: ${ltr(`${esc(Number(f.amount ?? 0).toFixed(2))} ${esc(f.currency ?? '')}`)}`}</div>`
  ).join('');
  return section(tr(lang, 'payAtHotel'),
    `${lines}<div style="font-size:12px;color:#6b7280">${tr(lang, 'mandatoryNote')}</div>`);
}

/// حجز HotelBeds (أو حجز قديم بلا مورّد مسجّل).
function isHotelBedsBooking(b: any): boolean {
  return !b?.supplier || b.supplier === 'hotelbeds';
}

export function bookingConfirmationEmail(b: any): { subject: string; html: string } {
  const lang = langOf(b);
  const comments = String(b.rate_comments ?? '').trim();
  const content =
    section(tr(lang, 'booking'), `<table style="border-collapse:collapse">
${row(tr(lang, 'bookingRef'), `<span style="font-size:18px">${ltr(esc(b.supplier_reference))}</span>`)}
${row(tr(lang, 'flynoomRef'), ltr(esc(b.client_reference)))}
${b.hotel_confirmation_code ? row(tr(lang, 'hotelConfCode'), ltr(esc(b.hotel_confirmation_code))) : ''}
${row(tr(lang, 'amountPaid'), ltr(`${usd(b.charge_amount)} USD`))}
</table>`) +
    section(tr(lang, 'hotel'), `<div style="font-size:17px;font-weight:700">${esc(b.hotel_name)}</div>
<div>${esc(b.hotel_address ?? b.hotel_city ?? '')}</div>
${b.hotel_phone ? `<div>${tr(lang, 'phone')}: ${ltr(esc(b.hotel_phone))}</div>` : ''}`) +
    section(tr(lang, 'stay'), `<table style="border-collapse:collapse">
${row(tr(lang, 'checkIn'), localDate(b.check_in, lang))}
${row(tr(lang, 'checkOut'), localDate(b.check_out, lang))}
${row(tr(lang, 'nights'), String(nights(b)))}
${row(tr(lang, 'leadGuest'), esc([b.holder_first_name, b.holder_last_name].filter(Boolean).join(' ')))}
</table>`) +
    section(tr(lang, 'rooms'), roomsHtml(b, lang)) +
    payAtHotelHtml(b, lang) +
    section(tr(lang, 'cancelPolicy'), cancellationHtml(b, lang)) +
    (comments
      ? section(tr(lang, 'importantInfo'),
        `<div dir="ltr" style="font-size:13px;color:#374151;white-space:pre-line;text-align:left">${esc(comments)}</div>`)
      : '') +
    // نص يطلبه HotelBeds على كل قسيمة (بالإنجليزية). لا يظهر لحجوزات LiteAPI.
    (isHotelBedsBooking(b)
      ? `<hr style="border:none;border-top:1px solid #e5e7eb;margin:24px 0">
<p dir="ltr" style="font-size:12px;color:#6b7280;margin:0;text-align:left">Payable through ${esc(b.supplier_name ?? 'HOTELBEDS')}, acting as agent for the service operating company, details of which can be provided upon request. VAT: ${esc(b.supplier_vat ?? '—')} Reference: ${esc(b.supplier_reference)}</p>`
      : '');

  return {
    subject: tr(lang, 'subjConfirmed', {
      hotel: String(b.hotel_name ?? ''),
      date: localDate(b.check_in, lang),
      ref: String(b.supplier_reference ?? ''),
    }),
    html: layout(
      lang,
      tr(lang, 'confirmedHeading'),
      tr(lang, 'confirmedIntro', { name: esc(b.holder_first_name ?? '') }),
      content,
    ),
  };
}

/// opts.byFlynoom: الإلغاء تم من طرفنا (مثل تنبيه من البنك) لا بطلب الضيف — نص محايد
/// لا يذكر الاحتيال، ويدعو للتواصل مع الدعم.
export function cancellationEmail(
  b: any,
  fee: number,
  refund: number,
  opts: { byFlynoom?: boolean } = {},
): { subject: string; html: string } {
  const lang = langOf(b);
  const content =
    section(tr(lang, 'cancelledSection'), `<table style="border-collapse:collapse">
${row(tr(lang, 'hotel'), esc(b.hotel_name))}
${row(tr(lang, 'dates'), `${localDate(b.check_in, lang)} – ${localDate(b.check_out, lang)}`)}
${row(tr(lang, 'bookingRef'), ltr(esc(b.supplier_reference)))}
${b.cancellation_reference ? row(tr(lang, 'cancelRef'), ltr(esc(b.cancellation_reference))) : ''}
${row(tr(lang, 'amountPaid'), ltr(`${usd(b.charge_amount)} USD`))}
${row(tr(lang, 'cancelFee'), ltr(`${usd(fee)} USD`))}
${row(tr(lang, 'refund'), ltr(`${usd(refund)} USD`))}
</table>`) +
    (refund > 0 ? `<p style="color:#374151">${tr(lang, 'refundNote')}</p>` : '');

  const name = esc(b.holder_first_name ?? '');
  return {
    subject: tr(lang, 'subjCancelled', {
      hotel: String(b.hotel_name ?? ''),
      ref: String(b.supplier_reference ?? ''),
    }),
    html: layout(
      lang,
      tr(lang, 'cancelledHeading'),
      opts.byFlynoom ? tr(lang, 'cancelIntroFlynoom', { name }) : tr(lang, 'cancelIntroUser', { name }),
      content,
    ),
  };
}

/// الحجز لم يتم عند الفندق بعد أن كان "قيد المراجعة": المبلغ المحجوز أُلغي ولم يُسحب.
export function bookingNotCompletedEmail(b: any): { subject: string; html: string } {
  const lang = langOf(b);
  const link = `<a href="https://flynoom.com" style="color:#0b3a6b">flynoom.com</a>`;
  const content =
    section(tr(lang, 'attemptSection'), `<table style="border-collapse:collapse">
${row(tr(lang, 'hotel'), esc(b.hotel_name))}
${row(tr(lang, 'dates'), `${localDate(b.check_in, lang)} – ${localDate(b.check_out, lang)}`)}
${row(tr(lang, 'flynoomRef'), ltr(esc(b.client_reference)))}
${row(tr(lang, 'amountHeld'), ltr(`${usd(b.charge_amount)} USD`))}
</table>`) +
    `<p style="color:#374151">${tr(lang, 'notCharged')}</p>
<p style="color:#374151">${tr(lang, 'sorry', { link })}</p>`;

  return {
    subject: tr(lang, 'subjNotCompleted', {
      hotel: String(b.hotel_name ?? ''),
      ref: String(b.client_reference ?? ''),
    }),
    html: layout(
      lang,
      tr(lang, 'notCompletedHeading'),
      tr(lang, 'notCompletedIntro', { name: esc(b.holder_first_name ?? '') }),
      content,
    ),
  };
}

/// إيميل الترحيب لحساب جديد (دالة welcome-email). بلا عروض أو خصومات: رسالة علاقة بالخدمة.
export function welcomeEmail(locale: unknown, firstName: string): { subject: string; html: string } {
  const lang = emailLocale(locale);
  const name = esc(String(firstName ?? '').trim());
  const greeting = name ? tr(lang, 'hiName', { name }) : tr(lang, 'hiPlain');
  const item = (icon: string, text: string) =>
    `<tr><td style="padding:6px 10px;vertical-align:top;font-size:18px">${icon}</td><td style="padding:6px 0;color:#374151">${text}</td></tr>`;
  const content =
    `<table style="border-collapse:collapse;margin-top:12px">
${item('🏨', tr(lang, 'wHotels'))}
${item('🕋', tr(lang, 'wUmrah'))}
${item('👨‍👩‍👧‍👦', tr(lang, 'wGroups'))}
${item('🔒', tr(lang, 'wPay'))}
</table>
<p style="margin:24px 0">
<a href="https://flynoom.com" style="display:inline-block;background:#0D47A1;color:#ffffff;text-decoration:none;font-weight:700;padding:12px 22px;border-radius:8px">${tr(lang, 'wCta')}</a>
</p>
<p style="margin:0 0 4px;font-weight:700">${tr(lang, 'wWish')}</p>
<p style="margin:0 0 16px;color:#374151">${tr(lang, 'wTeam')}</p>
<p style="font-size:12px;color:#6b7280;margin:0 0 6px">${tr(lang, 'wUsOnly')}</p>
<p style="font-size:12px;color:#9ca3af;margin:0">${tr(lang, 'wOneTime')}</p>`;

  return {
    subject: tr(lang, 'welcomeSubject'),
    html: layout(lang, tr(lang, 'welcomeHeading'), `${greeting} ${tr(lang, 'welcomeIntro')}`, content),
  };
}

/// يرسل البريد. لا يرمي أخطاء أبدًا (يرجع true/false).
export async function sendEmail(to: string | null | undefined, msg: { subject: string; html: string }): Promise<boolean> {
  if (!to || !RESEND_API_KEY) {
    console.log('EMAIL SKIPPED', !to ? 'no recipient' : 'no RESEND_API_KEY');
    return false;
  }
  try {
    const res = await fetch('https://api.resend.com/emails', {
      method: 'POST',
      headers: { 'Authorization': `Bearer ${RESEND_API_KEY}`, 'Content-Type': 'application/json' },
      body: JSON.stringify({
        from: EMAIL_FROM,
        to: [to],
        reply_to: EMAIL_REPLY_TO,
        subject: msg.subject,
        html: msg.html,
      }),
    });
    if (!res.ok) {
      console.log('EMAIL FAILED', res.status, await res.text().catch(() => ''));
      return false;
    }
    console.log('EMAIL SENT', to, msg.subject);
    return true;
  } catch (e) {
    console.log('EMAIL ERROR', String(e));
    return false;
  }
}
