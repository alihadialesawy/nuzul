import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';

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

/// إرشادات المحتوى والتبليغ.
///
/// ملاحظات:
///   • قسم "Reviews" يطابق قاعدة FTC للتقييمات (2024): لا تقييمات مزيفة، الإفصاح
///     عن أي مقابل، وعدم حذف التقييمات لأنها سلبية. ينطبق متى نشرنا تقييمات.
///   • قسم حقوق النشر: لحماية "Safe Harbor" في قانون DMCA يُنصح بتسجيل وكيل DMCA
///     لدى U.S. Copyright Office (رسوم رمزية) — اسأل المحامي.
class ContentGuidelinesPage extends StatelessWidget {
  const ContentGuidelinesPage({super.key});

  static const String _lastUpdatedEn = 'October 12, 2026';
  static const String _lastUpdatedAr = '12 أكتوبر 2026';

  static const String _contactEmail = 'support@flynoom.com';

  static const List<_InfoSection> _sections = [
    _InfoSection(
      titleEn: 'What these guidelines cover',
      titleAr: 'ما تغطيه هذه الإرشادات',
      bodyEn:
      'These guidelines apply to anything you post or submit on Flynoom, including community posts, trip journals, comments, reviews, photos, and profile information. They help keep Flynoom useful, honest, and safe for everyone, and they form part of our Terms of Service.',
      bodyAr:
      'تنطبق هذه الإرشادات على أي شيء تنشره أو ترسله في Flynoom، بما في ذلك منشورات المجتمع ويوميات الرحلات والتعليقات والتقييمات والصور ومعلومات الملف الشخصي. وهي تساعد على إبقاء Flynoom مفيدة وصادقة وآمنة للجميع، وتُعد جزءًا من شروط الخدمة.',
    ),
    _InfoSection(
      titleEn: 'Be respectful',
      titleAr: 'كن محترمًا',
      bodyEn:
      'Treat other travelers the way you would want to be treated. Harassment, hate speech, threats, bullying, and personal attacks are not allowed, regardless of who they target.',
      bodyAr:
      'عامل المسافرين الآخرين كما تحب أن تُعامَل. المضايقة وخطاب الكراهية والتهديد والتنمر والهجوم الشخصي غير مسموح بها، أيًا كان المستهدف.',
    ),
    _InfoSection(
      titleEn: 'Share honestly',
      titleAr: 'شارك بصدق',
      bodyEn:
      'Trip journals and reviews must reflect your own real experience. Do not post fake reviews, write about a stay you did not have, or make misleading claims about a destination or property. If you received anything in return for a post (such as payment, a discount, or a free stay), or you are connected to the business you are writing about, you must say so clearly in the post.',
      bodyAr:
      'يجب أن تعكس يوميات الرحلات والتقييمات تجربتك الحقيقية. لا تنشر تقييمات مزيفة، ولا تكتب عن إقامة لم تقم بها، ولا تقدّم ادعاءات مضللة عن وجهة أو فندق. وإذا حصلت على أي مقابل لمنشورك (مثل مال أو خصم أو إقامة مجانية)، أو كانت لك صلة بالجهة التي تكتب عنها، فيجب أن تذكر ذلك بوضوح في المنشور.',
    ),
    _InfoSection(
      titleEn: 'How we handle reviews',
      titleAr: 'كيف نتعامل مع التقييمات',
      bodyEn:
      'When we publish guest reviews, we do not remove or hide a review because it is negative. We remove reviews only when they break these guidelines, for example because they are fake, offensive, off-topic, or contain private information. Hotels cannot pay us to remove or change reviews.',
      bodyAr:
      'عندما ننشر تقييمات النزلاء، لا نحذف أي تقييم ولا نخفيه لأنه سلبي. نحذف التقييمات فقط إذا خالفت هذه الإرشادات، كأن تكون مزيفة أو مسيئة أو خارج الموضوع أو تتضمن معلومات خاصة. ولا تستطيع الفنادق الدفع لنا لحذف التقييمات أو تغييرها.',
    ),
    _InfoSection(
      titleEn: 'Respect privacy',
      titleAr: 'احترم الخصوصية',
      bodyEn:
      'Do not post anyone\'s private information, such as phone numbers, home addresses, ID or passport details, booking references, or the exact location of a private residence, without their consent. Do not post photos of other people in private situations without their permission.',
      bodyAr:
      'لا تنشر معلومات خاصة لأي شخص دون موافقته، مثل أرقام الهاتف أو عناوين المنازل أو بيانات الهوية أو جواز السفر أو أرقام الحجز أو الموقع الدقيق لمسكن خاص. ولا تنشر صورًا لأشخاص آخرين في مواقف خاصة دون إذنهم.',
    ),
    _InfoSection(
      titleEn: 'No spam, scams, or impersonation',
      titleAr: 'لا رسائل مزعجة ولا احتيال ولا انتحال',
      bodyEn:
      'Do not use Flynoom to advertise unrelated products or services, run pyramid or referral schemes, or move other users off Flynoom for fraudulent purposes. Do not pretend to be Flynoom, a hotel, an airline, or another person. Flynoom only emails you from addresses ending in @flynoom.com and will never ask for your full card number or password by email, phone, or message.',
      bodyAr:
      'لا تستخدم Flynoom للترويج لمنتجات أو خدمات غير ذات صلة، أو لتشغيل مخططات هرمية أو إحالات، أو لنقل المستخدمين خارج Flynoom لأغراض احتيالية. ولا تنتحل صفة Flynoom أو فندق أو شركة طيران أو أي شخص آخر. تراسلك Flynoom فقط من عناوين تنتهي بـ @flynoom.com، ولن تطلب منك أبدًا رقم بطاقتك الكامل أو كلمة المرور عبر البريد أو الهاتف أو الرسائل.',
    ),
    _InfoSection(
      titleEn: 'Prohibited content',
      titleAr: 'المحتوى الممنوع',
      bodyEn:
      'We remove content that is illegal; sexually explicit; exploits or endangers children; promotes violence, terrorism, or self-harm; infringes someone else\'s copyright or trademark; or contains malware or phishing links.',
      bodyAr:
      'نحذف المحتوى غير القانوني، أو الجنسي الصريح، أو الذي يستغل الأطفال أو يعرّضهم للخطر، أو يروّج للعنف أو الإرهاب أو إيذاء النفس، أو ينتهك حقوق النشر أو العلامات التجارية لغيرك، أو يحتوي على برمجيات خبيثة أو روابط تصيد.',
    ),
    _InfoSection(
      titleEn: 'How to report content or a problem',
      titleAr: 'كيف تبلّغ عن محتوى أو مشكلة',
      bodyEn:
      'If you see content that breaks these guidelines, use the report option on that post if available, or email $_contactEmail with a link or description. You can use the same address to report wrong hotel information (such as incorrect photos or amenities), suspected fraud on your account, or a message pretending to be from Flynoom. If you are in immediate danger, contact local emergency services first.',
      bodyAr:
      'إذا رأيت محتوى يخالف هذه الإرشادات، فاستخدم خيار الإبلاغ على المنشور إن وُجد، أو راسلنا على $_contactEmail مع رابط أو وصف. ويمكنك استخدام البريد نفسه للإبلاغ عن معلومات فندقية خاطئة (مثل صور أو مرافق غير صحيحة)، أو اشتباه في احتيال على حسابك، أو رسالة تدّعي أنها من Flynoom. وإذا كنت في خطر مباشر، فاتصل بخدمات الطوارئ المحلية أولًا.',
    ),
    _InfoSection(
      titleEn: 'Copyright complaints',
      titleAr: 'شكاوى حقوق النشر',
      bodyEn:
      'If you believe content on Flynoom infringes your copyright, email $_contactEmail with the subject "Copyright Notice" and include: your contact details; a description of the copyrighted work; the location of the content on Flynoom; a statement that you believe in good faith the use is not authorized; a statement, under penalty of perjury, that your notice is accurate and that you are the owner or authorized to act for the owner; and your physical or electronic signature.',
      bodyAr:
      'إذا كنت تعتقد أن محتوى في Flynoom ينتهك حقوق النشر الخاصة بك، فراسلنا على $_contactEmail مع كتابة "Copyright Notice" في عنوان الرسالة، وأرفق: بيانات التواصل معك؛ ووصفًا للعمل المحمي؛ وموضع المحتوى في Flynoom؛ وإقرارًا بأنك تعتقد بحسن نية أن الاستخدام غير مصرّح به؛ وإقرارًا، تحت طائلة عقوبة الحنث باليمين، بأن إشعارك دقيق وأنك المالك أو مفوَّض بالتصرف عنه؛ وتوقيعك الفعلي أو الإلكتروني.',
    ),
    _InfoSection(
      titleEn: 'Enforcement and appeals',
      titleAr: 'التنفيذ والاعتراض',
      bodyEn:
      'Depending on how serious the violation is and whether it has happened before, we may remove content, limit an account\'s ability to post, or suspend or close an account. Where appropriate, we will tell you what was removed and why. You can appeal a decision by emailing $_contactEmail with the subject "Content Appeal". Enforcement under these guidelines does not cancel your existing bookings unless they involve fraud.',
      bodyAr:
      'بحسب خطورة المخالفة وتكرارها، قد نحذف المحتوى، أو نقيّد قدرة الحساب على النشر، أو نعلّق الحساب أو نغلقه. وحيثما كان مناسبًا، سنخبرك بما حُذف وسبب حذفه. ويمكنك الاعتراض على القرار بمراسلتنا على $_contactEmail مع كتابة "Content Appeal" في عنوان الرسالة. ولا يؤدي تطبيق هذه الإرشادات إلى إلغاء حجوزاتك القائمة إلا إذا كانت تتعلق باحتيال.',
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
                Semantics(
                  header: true,
                  child: Text(
                    isArabic ? 'إرشادات المحتوى والتبليغ' : 'Content Guidelines and Reporting',
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
                OutlinedButton.icon(
                  icon: const Icon(Icons.flag_outlined, size: 18),
                  onPressed: () => context.push(AppRoutes.support),
                  label: Text(isArabic ? 'الإبلاغ عن مشكلة' : 'Report an issue'),
                ),
                const SizedBox(height: AppSizes.lg),
              ],
            ),
          ),
        ),
      ),
    );
  }
}