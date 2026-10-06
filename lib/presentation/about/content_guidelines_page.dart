import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../app.dart';
import 'package:go_router/go_router.dart';

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

class ContentGuidelinesPage extends StatelessWidget {
  const ContentGuidelinesPage({super.key});

  static const List<_InfoSection> _sections = [
    _InfoSection(
      titleEn: 'What these guidelines cover',
      titleAr: 'اللي بتغطيه هذه الإرشادات',
      bodyEn:
      'These guidelines apply to anything you post in Flynoom\'s Community area, including trip journals, comments, photos, and profile information. They exist to keep the community useful, honest, and safe for everyone.',
      bodyAr:
      'تنطبق هذه الإرشادات على أي شيء تنشره في قسم المجتمع بتطبيق Flynoom، بما في ذلك يوميات الرحلات والتعليقات والصور ومعلومات الملف الشخصي. وُضعت هذه الإرشادات للحفاظ على مجتمع مفيد وصادق وآمن للجميع.',
    ),
    _InfoSection(
      titleEn: 'Be respectful',
      titleAr: 'كن محترمًا',
      bodyEn:
      'Treat other travelers the way you\'d want to be treated. Harassment, hate speech, threats, and personal attacks are not allowed, regardless of who they target.',
      bodyAr:
      'عامل المسافرين الآخرين بالطريقة اللي تحب تُعامَل بيها. المضايقات، وخطاب الكراهية، والتهديدات، والهجمات الشخصية غير مسموح بها، بغض النظر عن الشخص المستهدف.',
    ),
    _InfoSection(
      titleEn: 'Share honestly',
      titleAr: 'شارك بصدق',
      bodyEn:
      'Trip journals and reviews should reflect a real, genuine experience. Fake bookings, misleading claims about a destination or property, and posts made in exchange for payment without disclosure are not allowed.',
      bodyAr:
      'يجب أن تعكس يوميات الرحلات والتقييمات تجربة حقيقية فعلية. الحجوزات الوهمية، والادعاءات المضلّلة عن وجهة أو عقار، والمنشورات المدفوعة من دون الإفصاح عن ذلك — كل ده غير مسموح.',
    ),
    _InfoSection(
      titleEn: 'Respect privacy',
      titleAr: 'احترم الخصوصية',
      bodyEn:
      "Don't post another person's private information (phone numbers, home addresses, ID or passport details, exact location of a private residence) without their consent.",
      bodyAr:
      'لا تنشر معلومات خاصة لشخص آخر (أرقام هاتف، عناوين منزلية، تفاصيل هوية أو جواز سفر، موقع دقيق لمسكن خاص) من دون موافقته.',
    ),
    _InfoSection(
      titleEn: 'No spam or scams',
      titleAr: 'ممنوع السبام أو النصب',
      bodyEn:
      "Don't use the Community to advertise unrelated products or services, run pyramid or referral schemes, or attempt to move other users off-platform for fraudulent purposes.",
      bodyAr:
      'لا تستخدم قسم المجتمع للترويج لمنتجات أو خدمات غير متعلقة به، أو تشغيل مخططات هرمية أو إحالات، أو محاولة نقل مستخدمين آخرين خارج المنصة لأغراض احتيالية.',
    ),
    _InfoSection(
      titleEn: 'Prohibited content',
      titleAr: 'المحتوى الممنوع',
      bodyEn:
      'We remove content that is illegal, sexually explicit, promotes violence or self-harm, infringes someone else\'s intellectual property, or impersonates another person or organization.',
      bodyAr:
      'نحذف أي محتوى غير قانوني، أو جنسي صريح، أو يروّج للعنف أو إيذاء النفس، أو ينتهك الملكية الفكرية لشخص آخر، أو ينتحل شخصية شخص أو جهة أخرى.',
    ),
    _InfoSection(
      titleEn: 'How to report content',
      titleAr: 'كيفية الإبلاغ عن محتوى',
      bodyEn:
      'If you see a post or comment that breaks these guidelines, use the report option on that post, or contact our Customer Service team with a link or description of what you found.',
      bodyAr:
      'لو شفت منشورًا أو تعليقًا يخالف هذه الإرشادات، استخدم خيار الإبلاغ الموجود على المنشور، أو تواصل مع فريق خدمة العملاء لدينا برابط أو وصف لما وجدته.',
    ),
    _InfoSection(
      titleEn: 'Enforcement',
      titleAr: 'التنفيذ',
      bodyEn:
      'Depending on the severity and history of the violation, we may remove content, restrict an account\'s posting ability, or suspend an account. You can appeal a decision by contacting Customer Service.',
      bodyAr:
      'حسب خطورة المخالفة وتاريخها، قد نقوم بحذف المحتوى، أو تقييد قدرة الحساب على النشر، أو تعليق الحساب. يمكنك الاعتراض على قرار عبر التواصل مع خدمة العملاء.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    return Scaffold(
      appBar: AppBar(
        title: Text(isArabic ? 'إرشادات المحتوى والتبليغ' : 'Content Guidelines and Reporting'),
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
                  isArabic ? 'إرشادات المحتوى والتبليغ' : 'Content Guidelines and Reporting',
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
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
                OutlinedButton(
                  onPressed: () => context.push(AppRoutes.support),
                  child: Text(isArabic ? 'الإبلاغ عن مشكلة' : 'Report an issue'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}