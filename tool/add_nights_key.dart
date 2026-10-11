// tool/add_nights_key.dart
//
// يضيف مفتاح الترجمة "nightsCount" إلى ملفات .arb التسعة في lib/localization
// مباشرة بعد قوس الفتح { مع الحفاظ على تنسيق الملفات كما هو.
// - app_ar.arb هو ملف القالب (template-arb-file)، فيأخذ سطر @nightsCount أيضًا.
// - إن كان المفتاح موجودًا مسبقًا في ملف ما، يتخطاه (آمن لو شغّلته مرتين).
// - يكتب الملفات بترميز UTF-8 بدون BOM.
//
// التشغيل من جذر المشروع:
//   dart run tool/add_nights_key.dart
//   flutter gen-l10n

import 'dart:io';

const arbDir = 'lib/localization';

const translations = <String, String>{
  'ar': '{count, plural, =1{ليلة واحدة} =2{ليلتان} few{{count} ليالٍ} many{{count} ليلة} other{{count} ليلة}}',
  'en': '{count, plural, =1{1 night} other{{count} nights}}',
  'es': '{count, plural, =1{1 noche} other{{count} noches}}',
  'fr': '{count, plural, =1{1 nuit} other{{count} nuits}}',
  'tr': '{count, plural, other{{count} gece}}',
  'id': '{count, plural, other{{count} malam}}',
  'hi': '{count, plural, =1{1 रात} other{{count} रातें}}',
  'ur': '{count, plural, =1{1 رات} other{{count} راتیں}}',
  'bn': '{count, plural, other{{count} রাত}}',
};

const templateLocale = 'ar';

void main() {
  var changed = 0;
  for (final entry in translations.entries) {
    final file = File('$arbDir/app_${entry.key}.arb');
    if (!file.existsSync()) {
      print('⚠️  غير موجود: ${file.path}');
      continue;
    }

    final content = file.readAsStringSync();
    if (content.contains('"nightsCount"')) {
      print('⏭️  موجود مسبقًا: ${file.path}');
      continue;
    }

    final brace = content.indexOf('{');
    if (brace == -1) {
      print('❌ ملف غير صالح (لا يوجد {): ${file.path}');
      continue;
    }

    final buffer = StringBuffer()
      ..write('\n  "nightsCount": "${entry.value}",');
    if (entry.key == templateLocale) {
      buffer.write(
        '\n  "@nightsCount": { "placeholders": { "count": { "type": "int" } } },',
      );
    }

    final updated = content.substring(0, brace + 1) +
        buffer.toString() +
        content.substring(brace + 1);

    // إزالة BOM إن وُجد، ثم الكتابة بـ UTF-8 عادي.
    file.writeAsStringSync(updated.replaceFirst('\uFEFF', ''));
    print('✅ تمت الإضافة: ${file.path}');
    changed++;
  }
  print('\nانتهى: عُدّل $changed ملف. الآن نفّذ: flutter gen-l10n');
}