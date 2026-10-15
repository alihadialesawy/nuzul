import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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

  static const String _lastUpdatedEn = 'October 12, 2026';
  static const String _lastUpdatedAr = '12 أكتوبر 2026';

  /// بريد التواصل الخاص بإمكانية الوصول. غيّره هنا فقط إن اعتمدت بريدًا آخر
  /// (مثل support@flynoom.com) وسيتغير في كل مكان بالصفحة.
  static const String _contactEmail = 'ali@flynoom.com';

  static const List<_LegalSection> _sections = [
    _LegalSection(
      titleEn: '1. Our Commitment',
      titleAr: '1. التزامنا',
      bodyEn:
      'FLYNOOM LLC ("Flynoom", "we", "us") is committed to making the Flynoom website (flynoom.com) and mobile application usable by everyone, including people with disabilities. We aim to conform to the Web Content Accessibility Guidelines (WCAG) 2.1, Level AA, and to applicable mobile accessibility standards.',
      bodyAr:
      'تلتزم شركة FLYNOOM LLC ("Flynoom" أو "نحن") بجعل موقع Flynoom الإلكتروني (flynoom.com) وتطبيقها على الهاتف قابلَين للاستخدام من قِبل الجميع، بما في ذلك ذوو الإعاقة. نهدف إلى الالتزام بإرشادات إمكانية الوصول لمحتوى الويب (WCAG) الإصدار 2.1، المستوى AA، وبمعايير إمكانية الوصول المعمول بها على الأجهزة المحمولة.',
    ),
    _LegalSection(
      titleEn: '2. What We Are Doing',
      titleAr: '2. ما نقوم به',
      bodyEn:
      'Accessibility is an ongoing effort. We are working to improve screen-reader support, keyboard navigation (including in photo galleries and booking forms), color contrast, and support for larger text sizes set on your device. We review new features for accessibility before release and fix reported issues as a priority.',
      bodyAr:
      'إمكانية الوصول جهد مستمر. نعمل على تحسين دعم قارئات الشاشة، والتنقل عبر لوحة المفاتيح (بما في ذلك معارض الصور ونماذج الحجز)، وتباين الألوان، ودعم أحجام النص الكبيرة المضبوطة على جهازك. نراجع الميزات الجديدة من ناحية إمكانية الوصول قبل إطلاقها، ونعطي الأولوية لإصلاح المشكلات التي تصلنا.',
    ),
    _LegalSection(
      titleEn: '3. Accessible Hotel Rooms',
      titleAr: '3. الغرف الفندقية المهيأة لذوي الإعاقة',
      bodyEn:
      'Hotel descriptions, room details, and amenities shown on Flynoom are provided by our hotel suppliers and by the hotels themselves. We display the accessibility information they provide to us. If you need a specific accessible feature (for example, a roll-in shower, grab bars, or a visual alarm), please contact us before you book and we will ask the hotel to confirm whether that feature is available for your dates. Availability of an accessible room is ultimately controlled by the hotel.',
      bodyAr:
      'أوصاف الفنادق وتفاصيل الغرف والمرافق المعروضة في Flynoom مصدرها مزودو الفنادق لدينا والفنادق نفسها، ونعرض معلومات إمكانية الوصول كما تصلنا منهم. إذا كنت تحتاج ميزة محددة (مثل دُش بمدخل مستوٍ للكرسي المتحرك، أو مقابض دعم، أو إنذار ضوئي)، فيُرجى التواصل معنا قبل الحجز وسنطلب من الفندق تأكيد توفر هذه الميزة في تواريخك. يبقى توفر الغرفة المهيأة في النهاية بيد الفندق.',
    ),
    _LegalSection(
      titleEn: '4. Assistance for Air Travel',
      titleAr: '4. المساعدة في السفر الجوي',
      bodyEn:
      'Airlines are responsible for providing assistance to passengers with disabilities, such as wheelchair service, seating accommodations, and travel with mobility or medical devices. If you need assistance on a flight booked through Flynoom, please contact the airline directly as early as possible (many services require at least 48 hours\' notice). We are also happy to help you pass a request to the airline; contact us with your booking reference.',
      bodyAr:
      'شركات الطيران هي المسؤولة عن تقديم المساعدة للمسافرين من ذوي الإعاقة، مثل خدمة الكرسي المتحرك، وترتيبات المقاعد، والسفر مع الأجهزة الطبية أو أجهزة التنقل. إذا كنت تحتاج مساعدة في رحلة حجزتها عبر Flynoom، فيُرجى التواصل مع شركة الطيران مباشرة في أقرب وقت ممكن (كثير من هذه الخدمات يتطلب إشعارًا قبل 48 ساعة على الأقل). ويسعدنا أيضًا مساعدتك في إيصال طلبك إلى شركة الطيران؛ تواصل معنا مع ذكر رقم حجزك.',
    ),
    _LegalSection(
      titleEn: '5. Known Limitations',
      titleAr: '5. القيود المعروفة',
      bodyEn:
      'Some content on Flynoom comes from third parties, including hotel photos and descriptions from our suppliers and flight information from airlines. This content may not always include text descriptions of images or meet every accessibility standard. Some parts of our own interface may also not yet fully meet WCAG 2.1 Level AA. We are working to improve these areas over time.',
      bodyAr:
      'بعض المحتوى في Flynoom مصدره جهات خارجية، بما في ذلك صور الفنادق وأوصافها من مزودينا ومعلومات الرحلات من شركات الطيران. قد لا يتضمن هذا المحتوى دائمًا وصفًا نصيًا للصور، وقد لا يستوفي كل معايير إمكانية الوصول. كما أن بعض أجزاء واجهتنا قد لا تستوفي بعد المستوى AA من WCAG 2.1 بالكامل. نعمل على تحسين هذه الجوانب مع الوقت.',
    ),
    _LegalSection(
      titleEn: '6. Feedback and Help With Booking',
      titleAr: '6. الملاحظات والمساعدة في الحجز',
      bodyEn:
      'If you encounter an accessibility barrier, or if you are unable to search for or complete a booking because of a disability, please email us at $_contactEmail. Please describe the problem, the page or feature involved, and any assistive technology you were using. We aim to respond within two business days and will work with you to provide the information or help you need, at no additional charge.',
      bodyAr:
      'إذا واجهت أي عائق يتعلق بإمكانية الوصول، أو لم تتمكن من البحث أو إتمام الحجز بسبب إعاقة، فراسلنا على $_contactEmail. يُرجى وصف المشكلة والصفحة أو الميزة المعنية وأي تقنية مساعدة كنت تستخدمها. نسعى للرد خلال يومَي عمل، وسنعمل معك لتوفير المعلومات أو المساعدة التي تحتاجها دون أي رسوم إضافية.',
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
                Semantics(
                  header: true,
                  child: Text(
                    isArabic ? 'بيان إمكانية الوصول' : 'Accessibility Statement',
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isArabic ? 'آخر تحديث: $_lastUpdatedAr' : 'Last updated: $_lastUpdatedEn',
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                ),
                const SizedBox(height: AppSizes.lg),
                for (final s in _sections) ...[
                  Semantics(
                    header: true,
                    child: Text(
                      isArabic ? s.titleAr : s.titleEn,
                      style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
                    ),
                  ),
                  const SizedBox(height: 6),
                  SelectableText(
                    isArabic ? s.bodyAr : s.bodyEn,
                    style: const TextStyle(fontSize: 14, height: 1.6, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: AppSizes.lg),
                ],
                _ContactCard(isArabic: isArabic, email: _contactEmail),
                const SizedBox(height: AppSizes.lg),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ContactCard extends StatelessWidget {
  final bool isArabic;
  final String email;
  const _ContactCard({required this.isArabic, required this.email});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSizes.md),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.textSecondary.withValues(alpha: 0.25)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isArabic ? 'تواصل معنا بشأن إمكانية الوصول' : 'Accessibility contact',
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.email_outlined, size: 18, color: AppColors.textSecondary),
              const SizedBox(width: 8),
              Expanded(child: SelectableText(email, style: const TextStyle(fontSize: 14))),
              IconButton(
                tooltip: isArabic ? 'نسخ البريد' : 'Copy email',
                icon: const Icon(Icons.copy, size: 18),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: email));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(isArabic ? 'تم نسخ البريد' : 'Email copied')),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'FLYNOOM LLC · Michigan, USA',
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}