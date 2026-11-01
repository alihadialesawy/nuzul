import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show Supabase;

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../core/widgets/app_banner.dart';
import '../../core/widgets/loading_view.dart';
import '../../core/widgets/error_view.dart';
import '../../data/models/community_post_model.dart';
import '../../data/models/community_comment_model.dart';
import 'controllers/community_controller.dart';

/// نفس نمط الترجمة المستخدم في باقي صفحات المشروع (_t3، 9 لغات).
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

/// نصوص ضوابط المحتوى باللغات التسع. الترتيب: [en, ar, es, tr, id, hi, ur, fr, bn].
const Map<String, List<String>> _strings = {
  'report': ['Report', 'إبلاغ', 'Denunciar', 'Şikâyet et', 'Laporkan', 'रिपोर्ट करें', 'رپورٹ کریں', 'Signaler', 'রিপোর্ট করুন'],
  'block': ['Block user', 'حظر المستخدم', 'Bloquear usuario', 'Kullanıcıyı engelle', 'Blokir pengguna', 'उपयोगकर्ता को ब्लॉक करें', 'صارف کو بلاک کریں', 'Bloquer l\'utilisateur', 'ব্যবহারকারীকে ব্লক করুন'],
  'delete': ['Delete post', 'حذف المنشور', 'Eliminar publicación', 'Gönderiyi sil', 'Hapus postingan', 'पोस्ट हटाएं', 'پوسٹ حذف کریں', 'Supprimer la publication', 'পোস্ট মুছুন'],
  'report_title': ['Report content', 'الإبلاغ عن محتوى', 'Denunciar contenido', 'İçeriği şikâyet et', 'Laporkan konten', 'सामग्री की रिपोर्ट करें', 'مواد کی رپورٹ کریں', 'Signaler le contenu', 'কনটেন্ট রিপোর্ট করুন'],
  'report_why': ['Why are you reporting this?', 'لماذا تبلّغ عن هذا المحتوى؟', '¿Por qué lo denuncias?', 'Bunu neden şikâyet ediyorsunuz?', 'Mengapa Anda melaporkan ini?', 'आप इसकी रिपोर्ट क्यों कर रहे हैं?', 'آپ اس کی رپورٹ کیوں کر رہے ہیں؟', 'Pourquoi signalez-vous ce contenu ?', 'কেন রিপোর্ট করছেন?'],
  'r_spam': ['Spam or advertising', 'رسائل مزعجة أو إعلانات', 'Spam o publicidad', 'Spam veya reklam', 'Spam atau iklan', 'स्पैम या विज्ञापन', 'اسپام یا اشتہار', 'Spam ou publicité', 'স্প্যাম বা বিজ্ঞাপন'],
  'r_harassment': ['Harassment or hate', 'تحرّش أو كراهية', 'Acoso u odio', 'Taciz veya nefret', 'Pelecehan atau kebencian', 'उत्पीड़न या नफ़रत', 'ہراسانی یا نفرت', 'Harcèlement ou haine', 'হয়রানি বা বিদ্বেষ'],
  'r_sexual': ['Sexual content or nudity', 'محتوى جنسي أو عُري', 'Contenido sexual o desnudos', 'Cinsel içerik veya çıplaklık', 'Konten seksual atau ketelanjangan', 'यौन सामग्री या नग्नता', 'جنسی مواد یا عریانی', 'Contenu sexuel ou nudité', 'যৌন কনটেন্ট বা নগ্নতা'],
  'r_violence': ['Violence or dangerous content', 'عنف أو محتوى خطير', 'Violencia o contenido peligroso', 'Şiddet veya tehlikeli içerik', 'Kekerasan atau konten berbahaya', 'हिंसा या खतरनाक सामग्री', 'تشدد یا خطرناک مواد', 'Violence ou contenu dangereux', 'সহিংসতা বা বিপজ্জনক কনটেন্ট'],
  'r_scam': ['Scam or false information', 'احتيال أو معلومات كاذبة', 'Estafa o información falsa', 'Dolandırıcılık veya yanlış bilgi', 'Penipuan atau informasi palsu', 'धोखाधड़ी या गलत जानकारी', 'دھوکہ یا غلط معلومات', 'Arnaque ou fausse information', 'প্রতারণা বা মিথ্যা তথ্য'],
  'r_other': ['Something else', 'سبب آخر', 'Otro motivo', 'Başka bir şey', 'Lainnya', 'कुछ और', 'کچھ اور', 'Autre chose', 'অন্য কিছু'],
  'details': ['Details (optional)', 'تفاصيل (اختياري)', 'Detalles (opcional)', 'Ayrıntılar (isteğe bağlı)', 'Detail (opsional)', 'विवरण (वैकल्पिक)', 'تفصیلات (اختیاری)', 'Détails (facultatif)', 'বিস্তারিত (ঐচ্ছিক)'],
  'cancel': ['Cancel', 'إلغاء', 'Cancelar', 'Vazgeç', 'Batal', 'रद्द करें', 'منسوخ کریں', 'Annuler', 'বাতিল'],
  'send_report': ['Send report', 'إرسال البلاغ', 'Enviar denuncia', 'Şikâyeti gönder', 'Kirim laporan', 'रिपोर्ट भेजें', 'رپورٹ بھیجیں', 'Envoyer le signalement', 'রিপোর্ট পাঠান'],
  'reported_ok': [
    'Thank you. We review reports within 24 hours. This content is now hidden for you.',
    'شكرًا لك. نراجع البلاغات خلال 24 ساعة، وأُخفي هذا المحتوى عنك.',
    'Gracias. Revisamos las denuncias en 24 horas. Este contenido ya está oculto para ti.',
    'Teşekkürler. Şikâyetleri 24 saat içinde inceliyoruz. Bu içerik artık size gösterilmiyor.',
    'Terima kasih. Kami meninjau laporan dalam 24 jam. Konten ini kini disembunyikan untuk Anda.',
    'धन्यवाद। हम 24 घंटे में रिपोर्ट की समीक्षा करते हैं। यह सामग्री अब आपसे छिपा दी गई है।',
    'شکریہ۔ ہم 24 گھنٹوں میں رپورٹس کا جائزہ لیتے ہیں۔ یہ مواد اب آپ سے چھپا دیا گیا ہے۔',
    'Merci. Nous examinons les signalements sous 24 heures. Ce contenu est désormais masqué pour vous.',
    'ধন্যবাদ। আমরা 24 ঘণ্টার মধ্যে রিপোর্ট পর্যালোচনা করি। এই কনটেন্ট এখন আপনার কাছে লুকানো।',
  ],
  'report_own': ['You can\'t report your own content.', 'لا يمكنك الإبلاغ عن محتواك.', 'No puedes denunciar tu propio contenido.', 'Kendi içeriğinizi şikâyet edemezsiniz.', 'Anda tidak bisa melaporkan konten sendiri.', 'आप अपनी सामग्री की रिपोर्ट नहीं कर सकते।', 'آپ اپنے مواد کی رپورٹ نہیں کر سکتے۔', 'Vous ne pouvez pas signaler votre propre contenu.', 'নিজের কনটেন্ট রিপোর্ট করা যায় না।'],
  'block_title': ['Block this user?', 'حظر هذا المستخدم؟', '¿Bloquear a este usuario?', 'Bu kullanıcı engellensin mi?', 'Blokir pengguna ini?', 'इस उपयोगकर्ता को ब्लॉक करें?', 'اس صارف کو بلاک کریں؟', 'Bloquer cet utilisateur ?', 'এই ব্যবহারকারীকে ব্লক করবেন?'],
  'block_body': [
    'You will no longer see their posts or comments. They will not be notified.',
    'لن ترى منشوراته أو تعليقاته بعد الآن، ولن يصله أي إشعار بذلك.',
    'Ya no verás sus publicaciones ni comentarios. No se le notificará.',
    'Artık gönderilerini veya yorumlarını görmeyeceksiniz. Kendisine bildirilmez.',
    'Anda tidak akan lagi melihat postingan atau komentarnya. Ia tidak akan diberi tahu.',
    'अब आपको उनकी पोस्ट या टिप्पणियाँ नहीं दिखेंगी। उन्हें इसकी सूचना नहीं दी जाएगी।',
    'آپ کو اب ان کی پوسٹس یا تبصرے نظر نہیں آئیں گے۔ انہیں اطلاع نہیں دی جائے گی۔',
    'Vous ne verrez plus ses publications ni ses commentaires. Il ne sera pas prévenu.',
    'আপনি আর তার পোস্ট বা মন্তব্য দেখবেন না। তাকে জানানো হবে না।',
  ],
  'block_btn': ['Block', 'حظر', 'Bloquear', 'Engelle', 'Blokir', 'ब्लॉक करें', 'بلاک کریں', 'Bloquer', 'ব্লক করুন'],
  'blocked_ok': ['User blocked.', 'تم حظر المستخدم.', 'Usuario bloqueado.', 'Kullanıcı engellendi.', 'Pengguna diblokir.', 'उपयोगकर्ता ब्लॉक किया गया।', 'صارف بلاک کر دیا گیا۔', 'Utilisateur bloqué.', 'ব্যবহারকারী ব্লক করা হয়েছে।'],
  'delete_title': ['Delete this post?', 'حذف هذا المنشور؟', '¿Eliminar esta publicación?', 'Bu gönderi silinsin mi?', 'Hapus postingan ini?', 'यह पोस्ट हटाएं?', 'یہ پوسٹ حذف کریں؟', 'Supprimer cette publication ?', 'এই পোস্টটি মুছবেন?'],
  'delete_btn': ['Delete', 'حذف', 'Eliminar', 'Sil', 'Hapus', 'हटाएं', 'حذف کریں', 'Supprimer', 'মুছুন'],
  'deleted_ok': ['Post deleted.', 'تم حذف المنشور.', 'Publicación eliminada.', 'Gönderi silindi.', 'Postingan dihapus.', 'पोस्ट हटा दी गई।', 'پوسٹ حذف ہو گئی۔', 'Publication supprimée.', 'পোস্ট মুছে ফেলা হয়েছে।'],
  'rules_title': ['Community rules', 'قواعد المجتمع', 'Normas de la comunidad', 'Topluluk kuralları', 'Aturan komunitas', 'समुदाय के नियम', 'کمیونٹی کے قواعد', 'Règles de la communauté', 'কমিউনিটির নিয়ম'],
  'rules_body': [
    'To keep the community safe, do not post:\n• hateful, harassing or threatening content\n• sexual content or nudity\n• violence or dangerous acts\n• spam, ads or scams\n• other people\'s private information\n\nWe review reports within 24 hours, remove content that breaks these rules, and may suspend accounts. By continuing, you agree to these rules and to our Terms of Service.',
    'حفاظًا على المجتمع، لا تنشر:\n• محتوى فيه كراهية أو تحرّش أو تهديد\n• محتوى جنسيًا أو عُريًا\n• عنفًا أو أفعالًا خطيرة\n• رسائل مزعجة أو إعلانات أو احتيالًا\n• معلومات خاصة بأشخاص آخرين\n\nنراجع البلاغات خلال 24 ساعة، ونحذف ما يخالف هذه القواعد، وقد نوقف الحسابات المخالفة. بالمتابعة توافق على هذه القواعد وعلى شروط الاستخدام.',
    'Para mantener la comunidad segura, no publiques:\n• contenido de odio, acoso o amenazas\n• contenido sexual o desnudos\n• violencia o actos peligrosos\n• spam, anuncios o estafas\n• información privada de otras personas\n\nRevisamos las denuncias en 24 horas, eliminamos el contenido que incumple estas normas y podemos suspender cuentas. Al continuar, aceptas estas normas y nuestros Términos de servicio.',
    'Topluluğu güvende tutmak için şunları paylaşmayın:\n• nefret, taciz veya tehdit içeren içerik\n• cinsel içerik veya çıplaklık\n• şiddet veya tehlikeli davranışlar\n• spam, reklam veya dolandırıcılık\n• başkalarının özel bilgileri\n\nŞikâyetleri 24 saat içinde inceler, kurallara aykırı içeriği kaldırır ve hesapları askıya alabiliriz. Devam ederek bu kuralları ve Hizmet Şartlarımızı kabul edersiniz.',
    'Agar komunitas tetap aman, jangan memposting:\n• konten kebencian, pelecehan, atau ancaman\n• konten seksual atau ketelanjangan\n• kekerasan atau tindakan berbahaya\n• spam, iklan, atau penipuan\n• informasi pribadi orang lain\n\nKami meninjau laporan dalam 24 jam, menghapus konten yang melanggar aturan, dan dapat menangguhkan akun. Dengan melanjutkan, Anda menyetujui aturan ini dan Ketentuan Layanan kami.',
    'समुदाय को सुरक्षित रखने के लिए यह पोस्ट न करें:\n• नफ़रत, उत्पीड़न या धमकी वाली सामग्री\n• यौन सामग्री या नग्नता\n• हिंसा या खतरनाक काम\n• स्पैम, विज्ञापन या धोखाधड़ी\n• दूसरों की निजी जानकारी\n\nहम 24 घंटे में रिपोर्ट की समीक्षा करते हैं, नियम तोड़ने वाली सामग्री हटाते हैं और खाते निलंबित कर सकते हैं। जारी रखकर आप इन नियमों और हमारी सेवा की शर्तों से सहमत होते हैं।',
    'کمیونٹی کو محفوظ رکھنے کے لیے یہ پوسٹ نہ کریں:\n• نفرت، ہراسانی یا دھمکی والا مواد\n• جنسی مواد یا عریانی\n• تشدد یا خطرناک حرکات\n• اسپام، اشتہارات یا دھوکہ\n• دوسروں کی نجی معلومات\n\nہم 24 گھنٹوں میں رپورٹس کا جائزہ لیتے ہیں، قواعد توڑنے والا مواد ہٹاتے ہیں اور اکاؤنٹ معطل کر سکتے ہیں۔ جاری رکھ کر آپ ان قواعد اور ہماری سروس کی شرائط سے اتفاق کرتے ہیں۔',
    'Pour que la communauté reste sûre, ne publiez pas :\n• de contenu haineux, harcelant ou menaçant\n• de contenu sexuel ou de nudité\n• de violence ou d\'actes dangereux\n• de spam, de publicité ou d\'arnaques\n• d\'informations privées sur d\'autres personnes\n\nNous examinons les signalements sous 24 heures, retirons les contenus contraires à ces règles et pouvons suspendre des comptes. En continuant, vous acceptez ces règles et nos Conditions d\'utilisation.',
    'কমিউনিটি নিরাপদ রাখতে যা পোস্ট করবেন না:\n• বিদ্বেষ, হয়রানি বা হুমকিমূলক কনটেন্ট\n• যৌন কনটেন্ট বা নগ্নতা\n• সহিংসতা বা বিপজ্জনক কাজ\n• স্প্যাম, বিজ্ঞাপন বা প্রতারণা\n• অন্যের ব্যক্তিগত তথ্য\n\nআমরা 24 ঘণ্টার মধ্যে রিপোর্ট পর্যালোচনা করি, নিয়ম ভঙ্গকারী কনটেন্ট সরাই এবং অ্যাকাউন্ট স্থগিত করতে পারি। চালিয়ে গেলে আপনি এই নিয়ম ও আমাদের পরিষেবার শর্তাবলিতে সম্মত হন।',
  ],
  'rules_agree': ['I agree', 'أوافق', 'Acepto', 'Kabul ediyorum', 'Saya setuju', 'मैं सहमत हूँ', 'میں متفق ہوں', 'J\'accepte', 'আমি সম্মত'],
  'banned': [
    'Your account can\'t post in the community. Contact support@flynoom.com.',
    'حسابك موقوف عن النشر في المجتمع. تواصل معنا على support@flynoom.com.',
    'Tu cuenta no puede publicar en la comunidad. Escríbenos a support@flynoom.com.',
    'Hesabınız toplulukta paylaşım yapamaz. support@flynoom.com adresine yazın.',
    'Akun Anda tidak dapat memposting di komunitas. Hubungi support@flynoom.com.',
    'आपका खाता समुदाय में पोस्ट नहीं कर सकता। support@flynoom.com पर संपर्क करें।',
    'آپ کا اکاؤنٹ کمیونٹی میں پوسٹ نہیں کر سکتا۔ support@flynoom.com پر رابطہ کریں۔',
    'Votre compte ne peut pas publier dans la communauté. Écrivez à support@flynoom.com.',
    'আপনার অ্যাকাউন্ট কমিউনিটিতে পোস্ট করতে পারবে না। support@flynoom.com-এ যোগাযোগ করুন।',
  ],
  'sign_in': ['Please sign in first.', 'سجّل الدخول أولًا.', 'Inicia sesión primero.', 'Lütfen önce giriş yapın.', 'Silakan masuk terlebih dahulu.', 'कृपया पहले साइन इन करें।', 'براہِ کرم پہلے سائن ان کریں۔', 'Veuillez d\'abord vous connecter.', 'অনুগ্রহ করে আগে সাইন ইন করুন।'],
  'error': ['Something went wrong. Please try again.', 'حدث خطأ. حاول مرة أخرى.', 'Algo salió mal. Inténtalo de nuevo.', 'Bir sorun oluştu. Lütfen tekrar deneyin.', 'Terjadi kesalahan. Silakan coba lagi.', 'कुछ गलत हो गया। कृपया फिर से कोशिश करें।', 'کچھ غلط ہو گیا۔ دوبارہ کوشش کریں۔', 'Une erreur s\'est produite. Veuillez réessayer.', 'কিছু ভুল হয়েছে। আবার চেষ্টা করুন।'],
  'more': ['More options', 'خيارات أخرى', 'Más opciones', 'Diğer seçenekler', 'Opsi lainnya', 'और विकल्प', 'مزید اختیارات', 'Plus d\'options', 'আরও বিকল্প'],
};

String _c(BuildContext context, String key) {
  const langs = ['en', 'ar', 'es', 'tr', 'id', 'hi', 'ur', 'fr', 'bn'];
  final i = langs.indexOf(Localizations.localeOf(context).languageCode);
  final v = _strings[key]!;
  return v[i < 0 ? 0 : i];
}

void _snack(BuildContext context, String text) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
}

/// رفض الكتابة من قاعدة البيانات (سياسة الإيقاف) → رسالة "حسابك موقوف".
bool _isBanError(String message) =>
    message.contains('row-level security') || message.contains('42501');

/// قبل النشر أو التعليق: تسجيل الدخول، الإيقاف، والموافقة على قواعد المجتمع.
/// ترجع true إن جاز المتابعة.
Future<bool> _ensureCanPost(BuildContext context, WidgetRef ref) async {
  if (Supabase.instance.client.auth.currentUser == null) {
    _snack(context, _c(context, 'sign_in'));
    return false;
  }
  final repo = ref.read(communityRepositoryProvider);
  if (await repo.isBannedFromCommunity()) {
    if (context.mounted) _snack(context, _c(context, 'banned'));
    return false;
  }
  if (await repo.hasAcceptedCommunityTerms()) return true;
  if (!context.mounted) return false;

  final agreed = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(_c(ctx, 'rules_title')),
      content: SingleChildScrollView(child: Text(_c(ctx, 'rules_body'), style: const TextStyle(height: 1.5))),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(_c(ctx, 'cancel'))),
        FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(_c(ctx, 'rules_agree'))),
      ],
    ),
  );
  if (agreed != true) return false;
  final result = await repo.acceptCommunityTerms();
  var ok = false;
  result.when(success: (_) => ok = true, failure: (_) => ok = false);
  if (!ok && context.mounted) _snack(context, _c(context, 'error'));
  return ok;
}

/// نافذة الإبلاغ: سبب + تفاصيل اختيارية. ترجع (reason, details) أو null.
Future<(String, String?)?> _askReportReason(BuildContext context) {
  return showDialog<(String, String?)>(
    context: context,
    builder: (_) => const _ReportDialog(),
  );
}

class _ReportDialog extends StatefulWidget {
  const _ReportDialog();

  @override
  State<_ReportDialog> createState() => _ReportDialogState();
}

class _ReportDialogState extends State<_ReportDialog> {
  static const _reasons = ['spam', 'harassment', 'sexual', 'violence', 'scam', 'other'];
  String? _reason;
  final _details = TextEditingController();

  @override
  void dispose() {
    _details.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_c(context, 'report_title')),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(_c(context, 'report_why'), style: const TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              for (final r in _reasons)
                RadioListTile<String>(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  value: r,
                  groupValue: _reason,
                  onChanged: (v) => setState(() => _reason = v),
                  title: Text(_c(context, 'r_$r')),
                ),
              TextField(
                controller: _details,
                maxLines: 3,
                maxLength: 500,
                decoration: InputDecoration(labelText: _c(context, 'details')),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(_c(context, 'cancel'))),
        FilledButton(
          onPressed: _reason == null
              ? null
              : () => Navigator.pop(context, (_reason!, _details.text.trim().isEmpty ? null : _details.text.trim())),
          child: Text(_c(context, 'send_report')),
        ),
      ],
    );
  }
}

/// إبلاغ عن منشور أو تعليق (مع رسائل النتيجة).
Future<bool> _report(BuildContext context, WidgetRef ref, {String? postId, String? commentId}) async {
  if (Supabase.instance.client.auth.currentUser == null) {
    _snack(context, _c(context, 'sign_in'));
    return false;
  }
  final answer = await _askReportReason(context);
  if (answer == null || !context.mounted) return false;
  final result = await ref.read(communityRepositoryProvider).reportContent(
    postId: postId,
    commentId: commentId,
    reason: answer.$1,
    details: answer.$2,
  );
  if (!context.mounted) return false;
  var ok = false;
  result.when(
    success: (_) {
      ok = true;
      _snack(context, _c(context, 'reported_ok'));
    },
    failure: (m) => _snack(context, _c(context, m.contains('own_content') ? 'report_own' : 'error')),
  );
  return ok;
}

/// حظر كاتب منشور أو تعليق (بعد التأكيد).
Future<bool> _block(BuildContext context, WidgetRef ref, {String? postId, String? commentId}) async {
  if (Supabase.instance.client.auth.currentUser == null) {
    _snack(context, _c(context, 'sign_in'));
    return false;
  }
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(_c(ctx, 'block_title')),
      content: Text(_c(ctx, 'block_body')),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(_c(ctx, 'cancel'))),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: AppColors.error),
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(_c(ctx, 'block_btn')),
        ),
      ],
    ),
  );
  if (confirmed != true || !context.mounted) return false;
  final result = await ref.read(communityRepositoryProvider).blockAuthor(postId: postId, commentId: commentId);
  if (!context.mounted) return false;
  var ok = false;
  result.when(
    success: (_) {
      ok = true;
      _snack(context, _c(context, 'blocked_ok'));
    },
    failure: (_) => _snack(context, _c(context, 'error')),
  );
  return ok;
}

class CommunityPage extends ConsumerWidget {
  const CommunityPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feedAsync = ref.watch(communityFeedProvider);

    return Scaffold(
      appBar: AppBanner(
        tabsBar: Text(
          _t3(context,
              ar: 'المجتمع', en: 'Community', es: 'Comunidad', tr: 'Topluluk',
              id: 'Komunitas', hi: 'समुदाय', ur: 'کمیونٹی', fr: 'Communauté', bn: 'কমিউনিটি'),
          style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
        ),
        bannerHeight: 160,
      ),
      // LayoutBuilder عشان نحدد عرض أقصى لمحتوى الفييد على الشاشات العريضة
      // (ويب/سطح المكتب). من غيره، الكروت بتمتد لعرض الشاشة كله وارتفاع
      // الصورة الثابت (220) بيبقى نسبة ضيقة جدًا مقارنة بالعرض، فيحصل قص
      // شديد للصورة (crop) بيخفي جزء كبير منها بدل ما يعرضها بشكل طبيعي.
      body: LayoutBuilder(
        builder: (context, constraints) {
          const maxContentWidth = 600.0;
          final isWide = constraints.maxWidth > maxContentWidth;

          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(communityFeedProvider),
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: isWide ? maxContentWidth : double.infinity,
                ),
                child: feedAsync.when(
                  loading: () => LoadingView(
                    message: _t3(context,
                        ar: 'يحمّل المنشورات...', en: 'Loading posts...', es: 'Cargando publicaciones...', tr: 'Gönderiler yükleniyor...',
                        id: 'Memuat postingan...', hi: 'पोस्ट लोड हो रही हैं...', ur: 'پوسٹس لوڈ ہو رہی ہیں...', fr: 'Chargement des publications...', bn: 'পোস্ট লোড হচ্ছে...'),
                  ),
                  error: (error, _) => ErrorView(
                    message: _t3(context,
                        ar: 'تعذر تحميل المجتمع', en: 'Could not load community', es: 'No se pudo cargar la comunidad', tr: 'Topluluk yüklenemedi',
                        id: 'Gagal memuat komunitas', hi: 'समुदाय लोड नहीं हो सका', ur: 'کمیونٹی لوڈ نہیں ہو سکی', fr: 'Impossible de charger la communauté', bn: 'কমিউনিটি লোড করা যায়নি'),
                    onRetry: () => ref.invalidate(communityFeedProvider),
                  ),
                  data: (posts) {
                    if (posts.isEmpty) {
                      return LayoutBuilder(
                        builder: (context, innerConstraints) => SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          child: ConstrainedBox(
                            constraints: BoxConstraints(minHeight: innerConstraints.maxHeight),
                            child: Center(
                              child: Text(
                                _t3(context,
                                    ar: 'لا توجد منشورات بعد. شارك أول رحلة!', en: 'No posts yet. Share your first trip!',
                                    es: 'Aún no hay publicaciones. ¡Comparte tu primer viaje!', tr: 'Henüz gönderi yok. İlk seyahatini paylaş!',
                                    id: 'Belum ada postingan. Bagikan perjalanan pertama Anda!', hi: 'अभी तक कोई पोस्ट नहीं। अपनी पहली यात्रा साझा करें!',
                                    ur: 'ابھی تک کوئی پوسٹ نہیں۔ اپنا پہلا سفر شیئر کریں!', fr: 'Aucune publication pour le moment. Partagez votre premier voyage !',
                                    bn: 'এখনও কোনো পোস্ট নেই। আপনার প্রথম ভ্রমণ শেয়ার করুন!'),
                                style: const TextStyle(color: AppColors.textSecondary),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                        ),
                      );
                    }
                    return ListView.separated(
                      padding: const EdgeInsets.all(AppSizes.md),
                      physics: const AlwaysScrollableScrollPhysics(),
                      itemCount: posts.length,
                      separatorBuilder: (_, __) => const SizedBox(height: AppSizes.md),
                      itemBuilder: (context, index) => _PostCard(post: posts[index]),
                    );
                  },
                ),
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openCreatePostSheet(context, ref),
        icon: const Icon(Icons.add_a_photo_outlined),
        label: Text(_t3(context,
            ar: 'شارك رحلتك', en: 'Share a trip', es: 'Comparte un viaje', tr: 'Seyahatini paylaş',
            id: 'Bagikan perjalanan', hi: 'यात्रा साझा करें', ur: 'سفر شیئر کریں', fr: 'Partager un voyage', bn: 'ভ্রমণ শেয়ার করুন')),
      ),
    );
  }

  Future<void> _openCreatePostSheet(BuildContext context, WidgetRef ref) async {
    if (!await _ensureCanPost(context, ref)) return;
    if (!context.mounted) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => const _CreatePostSheet(),
    );
  }
}

class _PostCard extends ConsumerWidget {
  final CommunityPostModel post;
  const _PostCard({required this.post});

  void _openComments(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => _CommentsSheet(postId: post.id),
    );
  }

  Future<void> _onMenu(BuildContext context, WidgetRef ref, String action) async {
    switch (action) {
      case 'report':
        if (await _report(context, ref, postId: post.id)) ref.invalidate(communityFeedProvider);
        break;
      case 'block':
        if (await _block(context, ref, postId: post.id)) ref.invalidate(communityFeedProvider);
        break;
      case 'delete':
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text(_c(ctx, 'delete_title')),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(_c(ctx, 'cancel'))),
              FilledButton(
                style: FilledButton.styleFrom(backgroundColor: AppColors.error),
                onPressed: () => Navigator.pop(ctx, true),
                child: Text(_c(ctx, 'delete_btn')),
              ),
            ],
          ),
        );
        if (confirmed != true || !context.mounted) return;
        final result = await ref.read(communityRepositoryProvider).deletePost(post.id);
        if (!context.mounted) return;
        result.when(
          success: (_) {
            _snack(context, _c(context, 'deleted_ok'));
            ref.invalidate(communityFeedProvider);
          },
          failure: (_) => _snack(context, _c(context, 'error')),
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final String? authorId = post.userId;
    final me = Supabase.instance.client.auth.currentUser?.id;
    final isMine = me != null && authorId != null && authorId.isNotEmpty && authorId == me;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.divider),
        borderRadius: BorderRadius.circular(16),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSizes.md),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundImage: post.authorAvatarUrl != null
                      ? NetworkImage(post.authorAvatarUrl!)
                      : null,
                  child: post.authorAvatarUrl == null
                      ? const Icon(Icons.person)
                      : null,
                ),
                const SizedBox(width: AppSizes.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        post.authorDisplayName ??
                            _t3(context,
                                ar: 'مسافر', en: 'Traveler', es: 'Viajero', tr: 'Gezgin',
                                id: 'Wisatawan', hi: 'यात्री', ur: 'مسافر', fr: 'Voyageur', bn: 'ভ্রমণকারী'),
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      if (post.destinationCity != null)
                        Text(
                          post.destinationCity!,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                    ],
                  ),
                ),
                if (post.isVerifiedTrip)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.verified, size: 14, color: AppColors.primary),
                        const SizedBox(width: 4),
                        Text(
                          _t3(context,
                              ar: 'رحلة موثّقة', en: 'Verified Trip', es: 'Viaje verificado', tr: 'Doğrulanmış seyahat',
                              id: 'Perjalanan terverifikasi', hi: 'सत्यापित यात्रा', ur: 'تصدیق شدہ سفر', fr: 'Voyage vérifié', bn: 'যাচাইকৃত ভ্রমণ'),
                          style: const TextStyle(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                // قائمة ⋮: إبلاغ/حظر لمنشورات الآخرين، وحذف لمنشوراتي.
                PopupMenuButton<String>(
                  tooltip: _c(context, 'more'),
                  icon: const Icon(Icons.more_vert, color: AppColors.textSecondary),
                  onSelected: (a) => _onMenu(context, ref, a),
                  itemBuilder: (ctx) => isMine
                      ? [
                    PopupMenuItem(
                      value: 'delete',
                      child: ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.delete_outline, color: AppColors.error),
                        title: Text(_c(ctx, 'delete')),
                      ),
                    ),
                  ]
                      : [
                    PopupMenuItem(
                      value: 'report',
                      child: ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.flag_outlined),
                        title: Text(_c(ctx, 'report')),
                      ),
                    ),
                    PopupMenuItem(
                      value: 'block',
                      child: ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.block, color: AppColors.error),
                        title: Text(_c(ctx, 'block')),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (post.imageUrls.isNotEmpty)
            AspectRatio(
              // 4:3 عشان نضمن نسبة عرض/ارتفاع طبيعية ومعقولة لأي صورة سفر
              // عادية، بدل ارتفاع ثابت بالبكسل كان بيعمل قص شديد على
              // الشاشات العريضة (راجع كومنت الـ LayoutBuilder في CommunityPage).
              aspectRatio: 4 / 3,
              child: PageView.builder(
                itemCount: post.imageUrls.length,
                itemBuilder: (context, i) => Image.network(
                  post.imageUrls[i],
                  fit: BoxFit.cover,
                  width: double.infinity,
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(AppSizes.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (post.rating != null) _RatingStars(rating: post.rating!),
                if (post.rating != null) const SizedBox(height: 6),
                Text(post.caption),
                const SizedBox(height: AppSizes.sm),
                Row(
                  children: [
                    _LikeButton(post: post),
                    const SizedBox(width: AppSizes.md),
                    InkWell(
                      onTap: () => _openComments(context),
                      child: Row(
                        children: [
                          const Icon(Icons.mode_comment_outlined, size: 18, color: AppColors.textSecondary),
                          const SizedBox(width: 4),
                          Text('${post.commentsCount}', style: const TextStyle(color: AppColors.textSecondary)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RatingStars extends StatelessWidget {
  final int rating;
  const _RatingStars({required this.rating});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(
        5,
            (i) => Icon(
          i < rating ? Icons.star : Icons.star_border,
          size: 16,
          color: Colors.amber,
        ),
      ),
    );
  }
}

class _LikeButton extends ConsumerStatefulWidget {
  final CommunityPostModel post;
  const _LikeButton({required this.post});

  @override
  ConsumerState<_LikeButton> createState() => _LikeButtonState();
}

class _LikeButtonState extends ConsumerState<_LikeButton> {
  late bool _liked = widget.post.likedByMe;
  late int _count = widget.post.likesCount;
  bool _busy = false;

  Future<void> _toggle() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _liked = !_liked;
      _count += _liked ? 1 : -1;
    });
    final repo = ref.read(communityRepositoryProvider);
    final result = await repo.toggleLike(widget.post.id, !_liked);
    result.when(
      success: (_) {},
      failure: (_) {
        if (mounted) {
          setState(() {
            _liked = !_liked;
            _count += _liked ? 1 : -1;
          });
        }
      },
    );
    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: _toggle,
      child: Row(
        children: [
          Icon(
            _liked ? Icons.favorite : Icons.favorite_border,
            size: 18,
            color: _liked ? Colors.red : AppColors.textSecondary,
          ),
          const SizedBox(width: 4),
          Text('$_count', style: const TextStyle(color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}

/// شاشة سفلية (bottom sheet) تعرض تعليقات منشور معيّن + حقل إضافة
/// تعليق جديد. بتتفتح لما تدوس على أيقونة/عداد التعليقات تحت أي
/// منشور (سواء فيه صور ولا لأ).
class _CommentsSheet extends ConsumerStatefulWidget {
  final String postId;
  const _CommentsSheet({required this.postId});

  @override
  ConsumerState<_CommentsSheet> createState() => _CommentsSheetState();
}

class _CommentsSheetState extends ConsumerState<_CommentsSheet> {
  final _controller = TextEditingController();
  List<CommunityCommentModel>? _comments;
  bool _loading = true;
  bool _sending = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadComments();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadComments() async {
    final repo = ref.read(communityRepositoryProvider);
    final result = await repo.fetchComments(widget.postId);
    if (!mounted) return;
    result.when(
      success: (comments) => setState(() {
        _comments = comments;
        _loading = false;
      }),
      failure: (message) => setState(() {
        _error = message;
        _loading = false;
      }),
    );
  }

  Future<void> _submitComment() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _sending) return;
    if (!await _ensureCanPost(context, ref)) return;
    if (!mounted) return;

    setState(() => _sending = true);
    final repo = ref.read(communityRepositoryProvider);
    final result = await repo.addComment(postId: widget.postId, content: text);
    if (!mounted) return;

    result.when(
      success: (comment) {
        setState(() {
          _comments = [...?_comments, comment];
          _controller.clear();
          _sending = false;
        });
      },
      failure: (message) {
        setState(() => _sending = false);
        _snack(context, _c(context, _isBanError(message) ? 'banned' : 'error'));
      },
    );
  }

  /// كاتب التعليق (إن كان النموذج يحوي userId). عند الغياب يظهر الخيار للجميع
  /// والخادم يرفض الإبلاغ عن محتوى الشخص نفسه.
  bool _isMine(CommunityCommentModel c) {
    final me = Supabase.instance.client.auth.currentUser?.id;
    if (me == null) return false;
    try {
      return (c as dynamic).userId == me;
    } catch (_) {
      return false;
    }
  }

  Future<void> _onCommentMenu(CommunityCommentModel c, String action) async {
    final done = action == 'report'
        ? await _report(context, ref, commentId: c.id)
        : await _block(context, ref, commentId: c.id);
    if (done && mounted) {
      // إخفاء التعليق فورًا؛ وعند الحظر تُخفى كل تعليقات الكاتب في التحميل التالي.
      setState(() => _comments = _comments?.where((x) => x.id != c.id).toList());
      if (action == 'block') {
        ref.invalidate(communityFeedProvider);
        _loadComments();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) {
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(AppSizes.md),
                child: Text(
                  _t3(context,
                      ar: 'التعليقات', en: 'Comments', es: 'Comentarios', tr: 'Yorumlar',
                      id: 'Komentar', hi: 'टिप्पणियाँ', ur: 'تبصرے', fr: 'Commentaires', bn: 'মন্তব্য'),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : _error != null
                    ? Center(child: Text(_error!))
                    : (_comments == null || _comments!.isEmpty)
                    ? Center(
                  child: Text(
                    _t3(context,
                        ar: 'لا توجد تعليقات بعد. كن أول من يعلّق!', en: 'No comments yet. Be the first!',
                        es: 'Aún no hay comentarios. ¡Sé el primero!', tr: 'Henüz yorum yok. İlk sen ol!',
                        id: 'Belum ada komentar. Jadilah yang pertama!', hi: 'अभी तक कोई टिप्पणी नहीं। पहले आप बनें!',
                        ur: 'ابھی تک کوئی تبصرہ نہیں۔ پہلے آپ بنیں!', fr: 'Aucun commentaire pour le moment. Soyez le premier !',
                        bn: 'এখনও কোনো মন্তব্য নেই। প্রথম হন!'),
                    style: const TextStyle(color: AppColors.textSecondary),
                    textAlign: TextAlign.center,
                  ),
                )
                    : ListView.builder(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: AppSizes.md),
                  itemCount: _comments!.length,
                  itemBuilder: (context, index) {
                    final c = _comments![index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CircleAvatar(
                            radius: 16,
                            backgroundImage: c.authorAvatarUrl != null
                                ? NetworkImage(c.authorAvatarUrl!)
                                : null,
                            child: c.authorAvatarUrl == null
                                ? const Icon(Icons.person, size: 16)
                                : null,
                          ),
                          const SizedBox(width: AppSizes.sm),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  c.authorDisplayName ??
                                      _t3(context,
                                          ar: 'مسافر', en: 'Traveler', es: 'Viajero', tr: 'Gezgin',
                                          id: 'Wisatawan', hi: 'यात्री', ur: 'مسافر', fr: 'Voyageur', bn: 'ভ্রমণকারী'),
                                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                                ),
                                const SizedBox(height: 2),
                                Text(c.content, style: const TextStyle(fontSize: 14)),
                              ],
                            ),
                          ),
                          if (!_isMine(c))
                            PopupMenuButton<String>(
                              tooltip: _c(context, 'more'),
                              iconSize: 18,
                              icon: const Icon(Icons.more_vert, size: 18, color: AppColors.textHint),
                              onSelected: (a) => _onCommentMenu(c, a),
                              itemBuilder: (ctx) => [
                                PopupMenuItem(value: 'report', child: Text(_c(ctx, 'report'))),
                                PopupMenuItem(value: 'block', child: Text(_c(ctx, 'block'))),
                              ],
                            ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.all(AppSizes.sm),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        decoration: InputDecoration(
                          hintText: _t3(context,
                              ar: 'اكتب تعليقًا...', en: 'Write a comment...', es: 'Escribe un comentario...', tr: 'Bir yorum yaz...',
                              id: 'Tulis komentar...', hi: 'एक टिप्पणी लिखें...', ur: 'تبصرہ لکھیں...', fr: 'Écrire un commentaire...', bn: 'একটি মন্তব্য লিখুন...'),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(24)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          isDense: true,
                        ),
                        onSubmitted: (_) => _submitComment(),
                      ),
                    ),
                    const SizedBox(width: AppSizes.sm),
                    _sending
                        ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                        : IconButton(
                      onPressed: _submitComment,
                      icon: const Icon(Icons.send, color: AppColors.primary),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _CreatePostSheet extends ConsumerStatefulWidget {
  const _CreatePostSheet();

  @override
  ConsumerState<_CreatePostSheet> createState() => _CreatePostSheetState();
}

class _CreatePostSheetState extends ConsumerState<_CreatePostSheet> {
  final _captionController = TextEditingController();
  final _cityController = TextEditingController();
  /// الصور كبايتات (تعمل على الويب والموبايل؛ dart:io File لا يعمل على الويب).
  final List<Uint8List> _images = [];
  int? _rating;
  bool _submitting = false;

  Future<void> _pickImages() async {
    final picker = ImagePicker();
    final picked = await picker.pickMultiImage(imageQuality: 80);
    if (picked.isEmpty) return;
    final room = 5 - _images.length;
    final bytes = <Uint8List>[];
    for (final x in picked.take(room)) {
      bytes.add(await x.readAsBytes());
    }
    if (mounted) setState(() => _images.addAll(bytes));
  }

  Future<void> _submit() async {
    if (_captionController.text.trim().isEmpty) return;
    setState(() => _submitting = true);

    final repo = ref.read(communityRepositoryProvider);

    List<String> imageUrls = [];
    if (_images.isNotEmpty) {
      final uploadResult = await repo.uploadImages(_images);
      imageUrls = uploadResult.when(
        success: (urls) => urls,
        failure: (_) => <String>[],
      );
    }

    final post = CommunityPostModel(
      id: '',
      userId: '',
      caption: _captionController.text.trim(),
      destinationCity: _cityController.text.trim().isEmpty ? null : _cityController.text.trim(),
      rating: _rating,
      imageUrls: imageUrls,
      createdAt: DateTime.now(),
      // TODO: اربط bookingType/bookingId هنا لو المستخدم اختار حجز فعلي
      // من My Bookings بدل منشور عام — ده اللي بيفعّل شارة Verified Trip.
    );

    final result = await repo.createPost(post);
    if (!mounted) return;

    result.when(
      success: (_) {
        ref.invalidate(communityFeedProvider);
        Navigator.of(context).pop();
      },
      failure: (message) {
        _snack(context, _c(context, _isBanError(message) ? 'banned' : 'error'));
      },
    );
    if (mounted) setState(() => _submitting = false);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: AppSizes.lg,
        right: AppSizes.lg,
        top: AppSizes.lg,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSizes.lg,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              _t3(context,
                  ar: 'شارك رحلتك', en: 'Share a trip', es: 'Comparte un viaje', tr: 'Seyahatini paylaş',
                  id: 'Bagikan perjalanan', hi: 'यात्रा साझा करें', ur: 'سفر شیئر کریں', fr: 'Partager un voyage', bn: 'ভ্রমণ শেয়ার করুন'),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: AppSizes.md),
            SizedBox(
              height: 90,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  ..._images.map(
                        (bytes) => Padding(
                      padding: const EdgeInsetsDirectional.only(end: 8),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.memory(bytes, width: 90, height: 90, fit: BoxFit.cover),
                      ),
                    ),
                  ),
                  if (_images.length < 5)
                    InkWell(
                      onTap: _pickImages,
                      child: Container(
                        width: 90,
                        height: 90,
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.divider),
                        ),
                        child: const Icon(Icons.add_photo_alternate_outlined),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: AppSizes.md),
            TextField(
              controller: _cityController,
              decoration: InputDecoration(
                labelText: _t3(context,
                    ar: 'الوجهة (اختياري)', en: 'Destination (optional)', es: 'Destino (opcional)', tr: 'Varış noktası (isteğe bağlı)',
                    id: 'Tujuan (opsional)', hi: 'गंतव्य (वैकल्पिक)', ur: 'منزل (اختیاری)', fr: 'Destination (facultatif)', bn: 'গন্তব্য (ঐচ্ছিক)'),
              ),
            ),
            const SizedBox(height: AppSizes.sm),
            TextField(
              controller: _captionController,
              maxLines: 4,
              decoration: InputDecoration(
                labelText: _t3(context,
                    ar: 'احكِ عن رحلتك', en: 'Tell us about your trip', es: 'Cuéntanos sobre tu viaje', tr: 'Seyahatinden bahset',
                    id: 'Ceritakan tentang perjalanan Anda', hi: 'अपनी यात्रा के बारे में बताएं', ur: 'اپنے سفر کے بارے میں بتائیں', fr: 'Parlez-nous de votre voyage', bn: 'আপনার ভ্রমণ সম্পর্কে বলুন'),
              ),
            ),
            const SizedBox(height: AppSizes.sm),
            Row(
              children: List.generate(
                5,
                    (i) => IconButton(
                  onPressed: () => setState(() => _rating = i + 1),
                  icon: Icon(
                    (_rating ?? 0) > i ? Icons.star : Icons.star_border,
                    color: Colors.amber,
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSizes.md),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _submitting ? null : _submit,
                child: _submitting
                    ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
                    : Text(_t3(context,
                    ar: 'نشر', en: 'Post', es: 'Publicar', tr: 'Paylaş',
                    id: 'Posting', hi: 'पोस्ट करें', ur: 'پوسٹ کریں', fr: 'Publier', bn: 'পোস্ট করুন')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}