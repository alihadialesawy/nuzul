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

/// ملحوظة: بند التحكيم ده نموذج عام شائع الاستخدام، لكن التحكيم
/// وتنازل الدعوى الجماعية بندود لهما آثار قانونية جوهرية — مهم جدًا
/// تتراجع مع محامٍ قبل التفعيل الفعلي، خصوصًا لو فيه عملاء من ولايات
/// بتقيّد بنود التحكيم الإجباري في عقود المستهلك.
class DisputeResolutionPage extends StatelessWidget {
  const DisputeResolutionPage({super.key});

  static const String _lastUpdatedEn = 'September 1, 2026';
  static const String _lastUpdatedAr = '1 سبتمبر 2026';

  static const List<_LegalSection> _sections = [
    _LegalSection(
      titleEn: "1. Let's Talk First",
      titleAr: '1. لنتحدث أولًا',
      bodyEn:
          'Before filing a claim, we ask that you contact our Customer Service team so we can try to resolve the issue informally. Most concerns can be resolved this way.',
      bodyAr:
          'قبل تقديم أي مطالبة، نطلب منك التواصل أولًا مع فريق خدمة العملاء لدينا حتى نحاول حل المشكلة وديًا. يمكن حل معظم المشكلات بهذه الطريقة.',
    ),
    _LegalSection(
      titleEn: '2. Binding Arbitration',
      titleAr: '2. التحكيم الملزم',
      bodyEn:
          'If a dispute cannot be resolved informally within 60 days, you and Flynoom agree to resolve it through binding arbitration on an individual basis, rather than in court, except as set out below. Arbitration will be administered under the rules of a recognized arbitration organization and will take place in Michigan or another mutually agreed location, or may be conducted by phone, video, or written submission where permitted.',
      bodyAr:
          'إذا تعذّر حل النزاع وديًا خلال 60 يومًا، فإنك و Flynoom توافقان على حله عبر التحكيم الملزم بصفة فردية، بدلًا من اللجوء إلى المحكمة، باستثناء ما هو موضح أدناه. يُدار التحكيم وفق قواعد منظمة تحكيم معترف بها، ويُعقد في ميشيغان أو أي مكان آخر متفق عليه، أو يمكن إجراؤه عبر الهاتف أو الفيديو أو تقديم مستندات كتابية حيثما يُسمح بذلك.',
    ),
    _LegalSection(
      titleEn: '3. Class Action Waiver',
      titleAr: '3. التنازل عن الدعوى الجماعية',
      bodyEn:
          'You and Flynoom agree that any arbitration or claim will be conducted only on an individual basis and not as part of a class, consolidated, or representative action.',
      bodyAr:
          'يوافق كل من العميل و Flynoom على أن أي تحكيم أو مطالبة سيُجرى على أساس فردي فقط، وليس كجزء من دعوى جماعية أو موحّدة أو تمثيلية.',
    ),
    _LegalSection(
      titleEn: '4. Exceptions',
      titleAr: '4. الاستثناءات',
      bodyEn:
          'Either party may bring an individual claim in small claims court instead of arbitration, and either party may seek injunctive or other equitable relief in court to protect intellectual property rights or prevent unauthorized access to the Service.',
      bodyAr:
          'يجوز لأي من الطرفين رفع مطالبة فردية أمام محكمة المطالبات الصغيرة بدلًا من التحكيم، ويجوز لأي من الطرفين طلب أمر قضائي أو أي إجراء إنصافي آخر أمام المحكمة لحماية حقوق الملكية الفكرية أو منع الوصول غير المصرّح به إلى الخدمة.',
    ),
    _LegalSection(
      titleEn: '5. Opt-Out Right',
      titleAr: '5. حق الانسحاب',
      bodyEn:
          'You may opt out of this arbitration agreement by notifying us in writing through our Customer Service page within 30 days of first accepting these Terms. If you opt out, disputes will be resolved in the state or federal courts located in Michigan.',
      bodyAr:
          'يمكنك الانسحاب من اتفاقية التحكيم هذه بإخطارنا كتابيًا عبر صفحة خدمة العملاء خلال 30 يومًا من أول قبول لهذه الشروط. في حال الانسحاب، ستُحل النزاعات أمام المحاكم الولائية أو الفيدرالية الواقعة في ميشيغان.',
    ),
    _LegalSection(
      titleEn: '6. Governing Law and Venue',
      titleAr: '6. القانون الحاكم ومكان التقاضي',
      bodyEn:
          'This agreement to arbitrate is governed by the Federal Arbitration Act. Where arbitration does not apply, disputes will be subject to the exclusive jurisdiction of the state or federal courts located in Michigan.',
      bodyAr:
          'تخضع اتفاقية التحكيم هذه لقانون التحكيم الفيدرالي الأمريكي. وحيثما لا يسري التحكيم، تخضع النزاعات للاختصاص القضائي الحصري للمحاكم الولائية أو الفيدرالية الواقعة في ميشيغان.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    return Scaffold(
      appBar: AppBar(
        title: Text(isArabic ? 'حل النزاعات' : 'Dispute Resolution'),
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
                  isArabic ? 'حل النزاعات' : 'Dispute Resolution',
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