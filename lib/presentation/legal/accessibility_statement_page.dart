import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';

class _LegalSection {
  final String titleEn;
  final String titleAr;
  final String bodyEn;
  final String bodyAr;
  const _LegalSection({
    required this.titleEn,
    required this.titleAr,
    required this.bodyEn,
    required this.bodyAr,
  });
}

class AccessibilityStatementPage extends StatelessWidget {
  const AccessibilityStatementPage({super.key});

  static const String _lastUpdatedEn = 'September 1, 2026';
  static const String _lastUpdatedAr = '1 سبتمبر 2026';

  static const List<_LegalSection> _sections = [
    _LegalSection(
      titleEn: '1. Our Commitment',
      titleAr: '1. التزامنا',
      bodyEn:
          'Flynoom is committed to making our website and mobile application usable by everyone, including people with disabilities. We aim to conform to the Web Content Accessibility Guidelines (WCAG) 2.1, Level AA, and to relevant mobile accessibility standards.',
      bodyAr:
          'تلتزم Flynoom بجعل موقعها الإلكتروني وتطبيقها قابلَين للاستخدام من قِبل الجميع، بما في ذلك ذوي الإعاقة. نهدف إلى الالتزام بإرشادات إمكانية الوصول لمحتوى الويب (WCAG) الإصدار 2.1، المستوى AA، وبمعايير إمكانية الوصول ذات الصلة على الأجهزة المحمولة.',
    ),
    _LegalSection(
      titleEn: '2. Ongoing Efforts',
      titleAr: '2. جهود مستمرة',
      bodyEn:
          'Accessibility is an ongoing effort. We are working to improve screen-reader compatibility, keyboard navigation, color contrast, and text scaling across the Service, and we review new features for accessibility before release.',
      bodyAr:
          'إمكانية الوصول جهد مستمر. نعمل على تحسين التوافق مع قارئات الشاشة، والتنقل عبر لوحة المفاتيح، وتباين الألوان، وتكبير النص عبر الخدمة، ونراجع الميزات الجديدة من ناحية إمكانية الوصول قبل إطلاقها.',
    ),
    _LegalSection(
      titleEn: '3. Known Limitations',
      titleAr: '3. القيود المعروفة',
      bodyEn:
          'Some parts of the Service, including certain third-party content supplied by airlines and hotel partners, may not yet fully meet these standards. We are working with our partners to improve this over time.',
      bodyAr:
          'قد لا تتوافق بعض أجزاء الخدمة تمامًا مع هذه المعايير حتى الآن، بما يشمل بعض المحتوى المقدَّم من شركاء الطيران والفنادق. نعمل مع شركائنا على تحسين ذلك مع الوقت.',
    ),
    _LegalSection(
      titleEn: '4. Feedback',
      titleAr: '4. الملاحظات',
      bodyEn:
          'If you encounter an accessibility barrier while using Flynoom, please let us know through our Customer Service page. Please describe the issue, the page or feature involved, and the assistive technology you were using, so we can address it as quickly as possible.',
      bodyAr:
          'إذا واجهت أي عائق يتعلق بإمكانية الوصول أثناء استخدامك لـ Flynoom، يُرجى إخبارنا عبر صفحة خدمة العملاء. يُرجى وصف المشكلة والصفحة أو الميزة المعنية والتقنية المساعدة التي كنت تستخدمها، حتى نتمكن من معالجتها في أسرع وقت ممكن.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    return Scaffold(
      appBar: AppBar(
        title: Text(isArabic ? 'بيان إمكانية الوصول' : 'Accessibility Statement'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSizes.md),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isArabic ? 'بيان إمكانية الوصول' : 'Accessibility Statement',
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  isArabic ? 'آخر تحديث: $_lastUpdatedAr' : 'Last updated: $_lastUpdatedEn',
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                ),
                const SizedBox(height: AppSizes.lg),
                for (final s in _sections) ...[
                  Text(
                    isArabic ? s.titleAr : s.titleEn,
                    style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    isArabic ? s.bodyAr : s.bodyEn,
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