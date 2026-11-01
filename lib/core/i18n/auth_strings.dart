/// ترجمة نصوص شاشات الدخول/التسجيل/استعادة كلمة السر إلى اللغات الست
/// التي لم تكن مترجمة (التركية، الإندونيسية، الهندية، الأردية، الفرنسية، البنغالية).
///
/// تُستخدم تلقائيًا من دالة _t3 في هذه الشاشات: إن كانت اللغة غير العربية
/// والإسبانية والإنجليزية، يُبحث عن النص الإنجليزي هنا. أي نص غير موجود
/// يظهر بالإنجليزية كما كان (لا يتعطل شيء).
///
/// النصوص التي فيها قيمة متغيّرة (مثل البريد) مكتوبة بـ {v}.
/// الترتيب: [tr, id, hi, ur, fr, bn].
class AuthStrings {
  AuthStrings._();

  static const _order = ['tr', 'id', 'hi', 'ur', 'fr', 'bn'];

  static String? lookup(String english, String languageCode) {
    final i = _order.indexOf(languageCode);
    if (i < 0) return null;

    final exact = _t[english];
    if (exact != null) return exact[i];

    // نصوص فيها قيمة متغيّرة: نطابق القالب ونضع القيمة في الترجمة.
    for (final entry in _t.entries) {
      if (!entry.key.contains('{v}')) continue;
      final parts = entry.key.split('{v}');
      final re = RegExp('^${RegExp.escape(parts[0])}(.+?)${RegExp.escape(parts[1])}\$');
      final m = re.firstMatch(english);
      if (m != null) return entry.value[i].replaceAll('{v}', m.group(1)!);
    }
    return null;
  }

  static const Map<String, List<String>> _t = {
    // ── تسجيل الدخول ──
    "Your account isn't activated yet. Open the confirmation email and tap the link, then sign in.": [
      'Hesabınız henüz etkinleştirilmedi. Onay e-postasını açıp bağlantıya dokunun, ardından giriş yapın.',
      'Akun Anda belum aktif. Buka email konfirmasi dan ketuk tautannya, lalu masuk.',
      'आपका खाता अभी सक्रिय नहीं है। पुष्टि ईमेल खोलकर लिंक पर टैप करें, फिर साइन इन करें।',
      'آپ کا اکاؤنٹ ابھی فعال نہیں ہوا۔ تصدیقی ای میل کھول کر لنک پر ٹیپ کریں، پھر سائن ان کریں۔',
      'Votre compte n\'est pas encore activé. Ouvrez l\'e-mail de confirmation et touchez le lien, puis connectez-vous.',
      'আপনার অ্যাকাউন্ট এখনও সক্রিয় হয়নি। নিশ্চিতকরণ ইমেইল খুলে লিঙ্কে ট্যাপ করুন, তারপর সাইন ইন করুন।',
    ],
    'We sent the confirmation link again to {v}. Check your spam folder too.': [
      'Onay bağlantısını {v} adresine yeniden gönderdik. Spam klasörünüzü de kontrol edin.',
      'Kami telah mengirim ulang tautan konfirmasi ke {v}. Periksa juga folder spam.',
      'हमने पुष्टि लिंक {v} पर फिर से भेजा है। अपना स्पैम फ़ोल्डर भी देखें।',
      'ہم نے تصدیقی لنک دوبارہ {v} پر بھیج دیا ہے۔ اپنا اسپام فولڈر بھی دیکھیں۔',
      'Nous avons renvoyé le lien de confirmation à {v}. Vérifiez aussi vos spams.',
      'আমরা নিশ্চিতকরণ লিঙ্কটি আবার {v}-এ পাঠিয়েছি। স্প্যাম ফোল্ডারও দেখুন।',
    ],
    'We sent the confirmation link again to {v}': [
      'Onay bağlantısını {v} adresine yeniden gönderdik',
      'Kami telah mengirim ulang tautan konfirmasi ke {v}',
      'हमने पुष्टि लिंक {v} पर फिर से भेजा है',
      'ہم نے تصدیقی لنک دوبارہ {v} پر بھیج دیا ہے',
      'Nous avons renvoyé le lien de confirmation à {v}',
      'আমরা নিশ্চিতকরণ লিঙ্কটি আবার {v}-এ পাঠিয়েছি',
    ],
    'Could not send right now. Please wait a minute and try again.': [
      'Şu anda gönderilemedi. Lütfen bir dakika bekleyip tekrar deneyin.',
      'Tidak dapat mengirim sekarang. Tunggu sebentar lalu coba lagi.',
      'अभी भेजा नहीं जा सका। कृपया एक मिनट रुककर फिर कोशिश करें।',
      'ابھی نہیں بھیجا جا سکا۔ براہِ کرم ایک منٹ انتظار کر کے دوبارہ کوشش کریں۔',
      'Envoi impossible pour le moment. Patientez une minute et réessayez.',
      'এখন পাঠানো যায়নি। অনুগ্রহ করে এক মিনিট অপেক্ষা করে আবার চেষ্টা করুন।',
    ],
    'Too many requests. Please wait a minute and try again.': [
      'Çok fazla istek. Lütfen bir dakika bekleyip tekrar deneyin.',
      'Terlalu banyak permintaan. Tunggu sebentar lalu coba lagi.',
      'बहुत अधिक अनुरोध। कृपया एक मिनट रुककर फिर कोशिश करें।',
      'بہت زیادہ درخواستیں۔ براہِ کرم ایک منٹ انتظار کر کے دوبارہ کوشش کریں۔',
      'Trop de demandes. Patientez une minute et réessayez.',
      'অনেক বেশি অনুরোধ। অনুগ্রহ করে এক মিনিট অপেক্ষা করে আবার চেষ্টা করুন।',
    ],
    'Check your email': [
      'E-postanızı kontrol edin',
      'Periksa email Anda',
      'अपना ईमेल देखें',
      'اپنی ای میل دیکھیں',
      'Consultez vos e-mails',
      'আপনার ইমেইল দেখুন',
    ],
    "If an account exists for {v}, you'll receive an email with a link to set a new password. Open the link on this same device and browser. Check your spam folder too.": [
      '{v} için bir hesap varsa, yeni şifre belirleme bağlantısı içeren bir e-posta alacaksınız. Bağlantıyı aynı cihaz ve tarayıcıda açın. Spam klasörünüzü de kontrol edin.',
      'Jika ada akun untuk {v}, Anda akan menerima email berisi tautan untuk membuat kata sandi baru. Buka tautan di perangkat dan browser yang sama. Periksa juga folder spam.',
      'अगर {v} के लिए कोई खाता है, तो आपको नया पासवर्ड बनाने के लिंक वाला ईमेल मिलेगा। लिंक इसी डिवाइस और ब्राउज़र में खोलें। अपना स्पैम फ़ोल्डर भी देखें।',
      'اگر {v} کا کوئی اکاؤنٹ موجود ہے تو آپ کو نیا پاس ورڈ بنانے کے لنک والی ای میل ملے گی۔ لنک اسی ڈیوائس اور براؤزر میں کھولیں۔ اپنا اسپام فولڈر بھی دیکھیں۔',
      'Si un compte existe pour {v}, vous recevrez un e-mail avec un lien pour créer un nouveau mot de passe. Ouvrez le lien sur le même appareil et le même navigateur. Vérifiez aussi vos spams.',
      '{v}-এর জন্য অ্যাকাউন্ট থাকলে নতুন পাসওয়ার্ড সেট করার লিঙ্কসহ একটি ইমেইল পাবেন। একই ডিভাইস ও ব্রাউজারে লিঙ্কটি খুলুন। স্প্যাম ফোল্ডারও দেখুন।',
    ],
    'Could not open Google sign-in. Please try again.': [
      'Google ile giriş açılamadı. Lütfen tekrar deneyin.',
      'Tidak dapat membuka masuk dengan Google. Silakan coba lagi.',
      'Google साइन-इन नहीं खुल सका। कृपया फिर कोशिश करें।',
      'Google سائن ان نہیں کھل سکا۔ براہِ کرم دوبارہ کوشش کریں۔',
      'Impossible d\'ouvrir la connexion Google. Veuillez réessayer.',
      'Google সাইন-ইন খোলা যায়নি। আবার চেষ্টা করুন।',
    ],
    'Sign in/register': [
      'Giriş yap/kaydol',
      'Masuk/daftar',
      'साइन इन/रजिस्टर करें',
      'سائن ان/رجسٹر کریں',
      'Connexion/inscription',
      'সাইন ইন/নিবন্ধন',
    ],
    'Faster booking with saved details': [
      'Kayıtlı bilgilerle daha hızlı rezervasyon',
      'Pemesanan lebih cepat dengan data tersimpan',
      'सहेजी गई जानकारी से तेज़ बुकिंग',
      'محفوظ تفصیلات کے ساتھ تیز بکنگ',
      'Réservation plus rapide grâce à vos informations enregistrées',
      'সংরক্ষিত তথ্যে দ্রুত বুকিং',
    ],
    'Manage bookings with ease': [
      'Rezervasyonlarınızı kolayca yönetin',
      'Kelola pemesanan dengan mudah',
      'बुकिंग आसानी से संभालें',
      'بکنگز آسانی سے سنبھالیں',
      'Gérez vos réservations facilement',
      'সহজে বুকিং পরিচালনা করুন',
    ],
    'Please enter an email address': [
      'E-posta adresinizi girin',
      'Masukkan alamat email',
      'ईमेल पता दर्ज करें',
      'ای میل پتہ درج کریں',
      'Saisissez une adresse e-mail',
      'ইমেইল ঠিকানা লিখুন',
    ],
    'Forgot password?': [
      'Şifrenizi mi unuttunuz?',
      'Lupa kata sandi?',
      'पासवर्ड भूल गए?',
      'پاس ورڈ بھول گئے؟',
      'Mot de passe oublié ?',
      'পাসওয়ার্ড ভুলে গেছেন?',
    ],
    'Resend confirmation link': [
      'Onay bağlantısını yeniden gönder',
      'Kirim ulang tautan konfirmasi',
      'पुष्टि लिंक फिर से भेजें',
      'تصدیقی لنک دوبارہ بھیجیں',
      'Renvoyer le lien de confirmation',
      'নিশ্চিতকরণ লিঙ্ক আবার পাঠান',
    ],
    'Continue with email': [
      'E-posta ile devam et',
      'Lanjutkan dengan email',
      'ईमेल से जारी रखें',
      'ای میل کے ساتھ جاری رکھیں',
      'Continuer avec l\'e-mail',
      'ইমেইল দিয়ে চালিয়ে যান',
    ],
    'or': ['veya', 'atau', 'या', 'یا', 'ou', 'অথবা'],
    'Continue with Google': [
      'Google ile devam et',
      'Lanjutkan dengan Google',
      'Google से जारी रखें',
      'Google کے ساتھ جاری رکھیں',
      'Continuer avec Google',
      'Google দিয়ে চালিয়ে যান',
    ],
    'By continuing with Google, you agree to our': [
      'Google ile devam ederek şunları kabul etmiş olursunuz:',
      'Dengan melanjutkan dengan Google, Anda menyetujui',
      'Google से जारी रखकर आप हमारी इनसे सहमत होते हैं:',
      'Google کے ساتھ جاری رکھ کر آپ ہماری ان سے اتفاق کرتے ہیں:',
      'En continuant avec Google, vous acceptez nos',
      'Google দিয়ে চালিয়ে গেলে আপনি আমাদের সম্মত হচ্ছেন',
    ],
    'Terms of Service': [
      'Hizmet Şartları',
      'Ketentuan Layanan',
      'सेवा की शर्तें',
      'سروس کی شرائط',
      'Conditions d\'utilisation',
      'পরিষেবার শর্তাবলি',
    ],
    'and acknowledge our': [
      've şunu okuduğunuzu onaylarsınız:',
      'dan mengakui',
      'और स्वीकार करते हैं हमारी',
      'اور تسلیم کرتے ہیں ہمارا',
      'et reconnaissez notre',
      'এবং স্বীকার করছেন আমাদের',
    ],
    'Privacy Notice': [
      'Gizlilik Bildirimi',
      'Pemberitahuan Privasi',
      'गोपनीयता सूचना',
      'رازداری کا نوٹس',
      'Avis de confidentialité',
      'গোপনীয়তা বিজ্ঞপ্তি',
    ],
    'Reset your password': [
      'Şifrenizi sıfırlayın',
      'Atur ulang kata sandi',
      'अपना पासवर्ड रीसेट करें',
      'اپنا پاس ورڈ ری سیٹ کریں',
      'Réinitialiser votre mot de passe',
      'পাসওয়ার্ড রিসেট করুন',
    ],
    "Enter your email and we'll send you a link to set a new password.": [
      'E-postanızı girin; size yeni şifre belirleme bağlantısı gönderelim.',
      'Masukkan email Anda dan kami akan mengirim tautan untuk membuat kata sandi baru.',
      'अपना ईमेल दर्ज करें, हम नया पासवर्ड बनाने का लिंक भेजेंगे।',
      'اپنی ای میل درج کریں، ہم نیا پاس ورڈ بنانے کا لنک بھیجیں گے۔',
      'Saisissez votre e-mail et nous vous enverrons un lien pour créer un nouveau mot de passe.',
      'আপনার ইমেইল লিখুন, আমরা নতুন পাসওয়ার্ড সেট করার লিঙ্ক পাঠাব।',
    ],
    'Back': ['Geri', 'Kembali', 'वापस', 'واپس', 'Retour', 'ফিরে যান'],
    'Send link': ['Bağlantıyı gönder', 'Kirim tautan', 'लिंक भेजें', 'لنک بھیجیں', 'Envoyer le lien', 'লিঙ্ক পাঠান'],

    // ── التسجيل ──
    'We sent a confirmation link to {v}. Open the email and tap the link to activate your account, then sign in.': [
      '{v} adresine bir onay bağlantısı gönderdik. Hesabınızı etkinleştirmek için e-postayı açıp bağlantıya dokunun, ardından giriş yapın.',
      'Kami mengirim tautan konfirmasi ke {v}. Buka email dan ketuk tautannya untuk mengaktifkan akun, lalu masuk.',
      'हमने {v} पर पुष्टि लिंक भेजा है। खाता सक्रिय करने के लिए ईमेल खोलकर लिंक पर टैप करें, फिर साइन इन करें।',
      'ہم نے {v} پر تصدیقی لنک بھیجا ہے۔ اکاؤنٹ فعال کرنے کے لیے ای میل کھول کر لنک پر ٹیپ کریں، پھر سائن ان کریں۔',
      'Nous avons envoyé un lien de confirmation à {v}. Ouvrez l\'e-mail et touchez le lien pour activer votre compte, puis connectez-vous.',
      'আমরা {v}-এ একটি নিশ্চিতকরণ লিঙ্ক পাঠিয়েছি। অ্যাকাউন্ট সক্রিয় করতে ইমেইল খুলে লিঙ্কে ট্যাপ করুন, তারপর সাইন ইন করুন।',
    ],
    "Didn't get it? Check your spam folder, or send it again.": [
      'Gelmedi mi? Spam klasörünüzü kontrol edin veya yeniden gönderin.',
      'Belum menerima? Periksa folder spam, atau kirim ulang.',
      'नहीं मिला? स्पैम फ़ोल्डर देखें या फिर से भेजें।',
      'نہیں ملی؟ اسپام فولڈر دیکھیں یا دوبارہ بھیجیں۔',
      'Vous ne l\'avez pas reçu ? Vérifiez vos spams ou renvoyez-le.',
      'পাননি? স্প্যাম ফোল্ডার দেখুন বা আবার পাঠান।',
    ],
    'Go to sign in': [
      'Girişe git',
      'Ke halaman masuk',
      'साइन इन पर जाएँ',
      'سائن ان پر جائیں',
      'Aller à la connexion',
      'সাইন ইনে যান',
    ],

    // ── تعيين كلمة سر جديدة ──
    'Your password has been changed. You are now signed in.': [
      'Şifreniz değiştirildi. Artık giriş yaptınız.',
      'Kata sandi Anda telah diubah. Anda sekarang sudah masuk.',
      'आपका पासवर्ड बदल दिया गया है। अब आप साइन इन हैं।',
      'آپ کا پاس ورڈ تبدیل ہو گیا ہے۔ اب آپ سائن ان ہیں۔',
      'Votre mot de passe a été modifié. Vous êtes maintenant connecté.',
      'আপনার পাসওয়ার্ড পরিবর্তন হয়েছে। আপনি এখন সাইন ইন করা আছেন।',
    ],
    'Your new password must be different from your old one.': [
      'Yeni şifreniz eskisinden farklı olmalıdır.',
      'Kata sandi baru harus berbeda dari yang lama.',
      'नया पासवर्ड पुराने से अलग होना चाहिए।',
      'نیا پاس ورڈ پرانے سے مختلف ہونا چاہیے۔',
      'Le nouveau mot de passe doit être différent de l\'ancien.',
      'নতুন পাসওয়ার্ড পুরোনোটির থেকে আলাদা হতে হবে।',
    ],
    'Could not save your password. Please try again.': [
      'Şifreniz kaydedilemedi. Lütfen tekrar deneyin.',
      'Tidak dapat menyimpan kata sandi. Silakan coba lagi.',
      'आपका पासवर्ड सहेजा नहीं जा सका। कृपया फिर कोशिश करें।',
      'آپ کا پاس ورڈ محفوظ نہیں ہو سکا۔ براہِ کرم دوبارہ کوشش کریں۔',
      'Impossible d\'enregistrer votre mot de passe. Veuillez réessayer.',
      'আপনার পাসওয়ার্ড সংরক্ষণ করা যায়নি। আবার চেষ্টা করুন।',
    ],
    'This link is invalid or has expired': [
      'Bu bağlantı geçersiz veya süresi dolmuş',
      'Tautan ini tidak valid atau sudah kedaluwarsa',
      'यह लिंक अमान्य है या समाप्त हो गया है',
      'یہ لنک غلط ہے یا اس کی میعاد ختم ہو گئی ہے',
      'Ce lien est invalide ou a expiré',
      'এই লিঙ্কটি অবৈধ বা মেয়াদোত্তীর্ণ',
    ],
    'Request a new link from the sign-in page, and open it on the same device and browser you requested it from.': [
      'Giriş sayfasından yeni bir bağlantı isteyin ve istediğiniz cihaz ile tarayıcıda açın.',
      'Minta tautan baru dari halaman masuk, lalu buka di perangkat dan browser yang sama saat memintanya.',
      'साइन-इन पेज से नया लिंक मांगें, और उसे उसी डिवाइस और ब्राउज़र में खोलें जहाँ से मांगा था।',
      'سائن ان صفحے سے نیا لنک منگوائیں، اور اسے اسی ڈیوائس اور براؤزر میں کھولیں جہاں سے منگوایا تھا۔',
      'Demandez un nouveau lien depuis la page de connexion et ouvrez-le sur le même appareil et le même navigateur.',
      'সাইন-ইন পেজ থেকে নতুন লিঙ্ক চান, এবং যে ডিভাইস ও ব্রাউজার থেকে চেয়েছেন সেখানেই খুলুন।',
    ],
    'Set a new password': [
      'Yeni şifre belirleyin',
      'Buat kata sandi baru',
      'नया पासवर्ड सेट करें',
      'نیا پاس ورڈ سیٹ کریں',
      'Définir un nouveau mot de passe',
      'নতুন পাসওয়ার্ড সেট করুন',
    ],
    'New password': ['Yeni şifre', 'Kata sandi baru', 'नया पासवर्ड', 'نیا پاس ورڈ', 'Nouveau mot de passe', 'নতুন পাসওয়ার্ড'],
    'Confirm password': ['Şifreyi onayla', 'Konfirmasi kata sandi', 'पासवर्ड की पुष्टि करें', 'پاس ورڈ کی تصدیق کریں', 'Confirmer le mot de passe', 'পাসওয়ার্ড নিশ্চিত করুন'],
    'Passwords do not match': ['Şifreler eşleşmiyor', 'Kata sandi tidak cocok', 'पासवर्ड मेल नहीं खाते', 'پاس ورڈ مماثل نہیں ہیں', 'Les mots de passe ne correspondent pas', 'পাসওয়ার্ড মিলছে না'],
    'Save password': ['Şifreyi kaydet', 'Simpan kata sandi', 'पासवर्ड सहेजें', 'پاس ورڈ محفوظ کریں', 'Enregistrer le mot de passe', 'পাসওয়ার্ড সংরক্ষণ করুন'],
  };
}