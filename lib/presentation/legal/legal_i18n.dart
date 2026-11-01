import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';

/// ترجمات الصفحات القانونية إلى اللغات السبع غير العربية والإنجليزية.
///
/// النسخة الإنجليزية هي المعتمدة قانونيًا؛ كل ترجمة تُعرض معها ملاحظة
/// "ترجمة للتيسير" بلغة المستخدم، وزر لعرض النص الإنجليزي.
class LegalDoc {
  final String title;
  final String updated; // "آخر تحديث: ..." كاملة بلغة الصفحة
  final List<(String, String)> sections; // (العنوان، النص)
  final Map<String, String> extra; // نصوص إضافية خاصة بكل صفحة
  const LegalDoc({
    required this.title,
    required this.updated,
    required this.sections,
    this.extra = const {},
  });
}

/// لغة الصفحة القانونية: null للعربية والإنجليزية (لهما نص في الصفحة نفسها).
String? legalTranslatedLang(BuildContext context) {
  const langs = ['es', 'tr', 'id', 'hi', 'ur', 'fr', 'bn'];
  final code = Localizations.localeOf(context).languageCode;
  return langs.contains(code) ? code : null;
}

/// نصوص الواجهة المشتركة في الصفحات القانونية. الترتيب: es, tr, id, hi, ur, fr, bn.
const Map<String, List<String>> _ui = {
  'notice': [
    'Esta es una traducción para tu comodidad. Si hay alguna diferencia, prevalece la versión en inglés.',
    'Bu, kolaylık sağlamak için yapılmış bir çeviridir. Herhangi bir farklılık olması durumunda İngilizce metin geçerlidir.',
    'Ini adalah terjemahan untuk kemudahan Anda. Jika ada perbedaan, versi bahasa Inggris yang berlaku.',
    'यह आपकी सुविधा के लिए अनुवाद है। किसी भी अंतर की स्थिति में अंग्रेज़ी संस्करण मान्य होगा।',
    'یہ آپ کی سہولت کے لیے ترجمہ ہے۔ کسی بھی فرق کی صورت میں انگریزی نسخہ معتبر ہوگا۔',
    'Ceci est une traduction fournie pour votre commodité. En cas de différence, la version anglaise prévaut.',
    'এটি আপনার সুবিধার জন্য একটি অনুবাদ। কোনো পার্থক্য থাকলে ইংরেজি সংস্করণই প্রযোজ্য।',
  ],
  'show_en': ['Ver en inglés', 'İngilizcesini göster', 'Lihat versi Inggris', 'अंग्रेज़ी में देखें', 'انگریزی میں دیکھیں', 'Voir en anglais', 'ইংরেজিতে দেখুন'],
  'show_tr': ['Ver traducción', 'Çeviriyi göster', 'Lihat terjemahan', 'अनुवाद देखें', 'ترجمہ دیکھیں', 'Voir la traduction', 'অনুবাদ দেখুন'],
  'copy_email': ['Copiar correo', 'E-postayı kopyala', 'Salin email', 'ईमेल कॉपी करें', 'ای میل کاپی کریں', 'Copier l\'e-mail', 'ইমেইল কপি করুন'],
  'email_copied': ['Correo copiado', 'E-posta kopyalandı', 'Email disalin', 'ईमेल कॉपी हो गया', 'ای میل کاپی ہو گئی', 'E-mail copié', 'ইমেইল কপি হয়েছে'],
};

String legalUi(String lang, String key) {
  const order = ['es', 'tr', 'id', 'hi', 'ur', 'fr', 'bn'];
  return _ui[key]![order.indexOf(lang)];
}

/// ملاحظة "ترجمة للتيسير" + زر التبديل بين الترجمة والإنجليزية.
class LegalTranslationNotice extends StatelessWidget {
  final String lang;
  final bool showingEnglish;
  final VoidCallback onToggle;
  const LegalTranslationNotice({
    super.key,
    required this.lang,
    required this.showingEnglish,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 8,
        runSpacing: 4,
        children: [
          Text(
            legalUi(lang, 'notice'),
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 12, fontStyle: FontStyle.italic),
          ),
          TextButton.icon(
            style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
            onPressed: onToggle,
            icon: const Icon(Icons.translate, size: 16),
            label: Text(legalUi(lang, showingEnglish ? 'show_tr' : 'show_en')),
          ),
        ],
      ),
    );
  }
}