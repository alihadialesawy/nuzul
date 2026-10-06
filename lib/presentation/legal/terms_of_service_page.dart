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

/// ملحوظة: مسودة قانونية مبدئية عامة، محتاجة مراجعة محامٍ مرخّص قبل
/// النشر الفعلي — راجع نفس الملحوظة في privacy_notice_page.dart.
class TermsOfServicePage extends StatelessWidget {
  const TermsOfServicePage({super.key});

  static const String _lastUpdatedEn = 'September 1, 2026';
  static const String _lastUpdatedAr = '1 سبتمبر 2026';

  static const List<_LegalSection> _sections = [
    _LegalSection(
      titleEn: '1. Acceptance of Terms',
      titleAr: '1. قبول الشروط',
      bodyEn:
          'These Terms of Service ("Terms") govern your access to and use of Flynoom\'s website and mobile application (the "Service"), operated by Flynoom LLC ("Flynoom", "we", "us"). By creating an account, browsing, or booking through the Service, you agree to be bound by these Terms. If you do not agree, do not use the Service.',
      bodyAr:
          'تحكم شروط الخدمة هذه ("الشروط") وصولك إلى موقع Flynoom الإلكتروني وتطبيقه ("الخدمة") واستخدامك لهما، واللذين تديرهما شركة Flynoom LLC ("Flynoom" أو "نحن"). بإنشائك حسابًا، أو تصفحك، أو حجزك عبر الخدمة، فإنك توافق على الالتزام بهذه الشروط. إذا كنت لا توافق، فلا تستخدم الخدمة.',
    ),
    _LegalSection(
      titleEn: '2. Nature of the Service',
      titleAr: '2. طبيعة الخدمة',
      bodyEn:
          'Flynoom is a travel booking marketplace. We do not own or operate any aircraft, hotels, or rental vehicles. When you book a flight, stay, or other travel service through Flynoom, you are entering into a contract with the actual airline, hotel, or supplier (fulfilled through our technology partners, including Duffel for flights and HotelBeds for hotel stays); Flynoom acts as an intermediary that facilitates the search and booking. Supplier terms, fare rules, and cancellation policies presented at checkout apply in addition to these Terms.',
      bodyAr:
          'Flynoom منصة وسيطة لحجوزات السفر. نحن لا نمتلك أو نشغّل أي طائرات أو فنادق أو مركبات مؤجرة. عندما تحجز رحلة طيران أو إقامة أو أي خدمة سفر أخرى عبر Flynoom، فإنك تدخل في عقد مع شركة الطيران أو الفندق أو المزوّد الفعلي (يتم تنفيذه من خلال شركائنا التقنيين، بما في ذلك Duffel لرحلات الطيران وHotelBeds للإقامات الفندقية)؛ وتعمل Flynoom كوسيط ييسّر عملية البحث والحجز. تُطبَّق شروط المزوّد وقواعد التسعيرة وسياسات الإلغاء الموضحة عند إتمام الحجز بالإضافة إلى هذه الشروط.',
    ),
    _LegalSection(
      titleEn: '3. Eligibility and Account Registration',
      titleAr: '3. الأهلية وتسجيل الحساب',
      bodyEn:
          'You must be at least 18 years old and capable of forming a binding contract to create an account or make a booking. You are responsible for maintaining the confidentiality of your account credentials and for all activity under your account. Guest browsing and search are available without an account; login is required to complete a booking.',
      bodyAr:
          'يجب أن يكون عمرك 18 عامًا على الأقل وأن تكون قادرًا على إبرام عقد ملزم لإنشاء حساب أو إجراء حجز. أنت مسؤول عن الحفاظ على سرية بيانات حسابك وعن جميع الأنشطة التي تتم تحت حسابك. يمكن التصفح والبحث كضيف من دون حساب؛ ويتطلب إتمام الحجز تسجيل الدخول.',
    ),
    _LegalSection(
      titleEn: '4. Bookings, Pricing, and Payment',
      titleAr: '4. الحجوزات والتسعير والدفع',
      bodyEn:
          'Prices displayed are provided by our suppliers in real time and are subject to change until your booking is confirmed and paid for. Payments are processed securely through Stripe; Flynoom does not store your full card details. By submitting a booking, you authorize us to charge the displayed total, including any applicable taxes and fees, to your chosen payment method.',
      bodyAr:
          'الأسعار المعروضة يقدّمها مزوّدونا في الوقت الفعلي وقد تتغيّر حتى يتم تأكيد حجزك ودفع قيمته. تُعالَج المدفوعات بأمان عبر Stripe؛ ولا تخزّن Flynoom بيانات بطاقتك الكاملة. بإرسالك للحجز، فإنك تفوّضنا بخصم المبلغ الإجمالي المعروض، بما يشمل أي ضرائب أو رسوم مطبّقة، من وسيلة الدفع التي اخترتها.',
    ),
    _LegalSection(
      titleEn: '5. Cancellations, Changes, and Refunds',
      titleAr: '5. الإلغاء والتغيير والاسترداد',
      bodyEn:
          'Cancellation, change, and refund eligibility are set by the airline, hotel, or supplier for each booking and are shown before you complete a purchase. Flynoom will assist in submitting cancellation or change requests to the relevant supplier but is not responsible for a supplier\'s refusal to refund under its own policy.',
      bodyAr:
          'يحدد كل مزوّد (شركة الطيران أو الفندق) شروط الإلغاء والتغيير وأهلية الاسترداد لكل حجز، وتُعرض هذه الشروط قبل إتمام الشراء. تساعد Flynoom في تقديم طلبات الإلغاء أو التغيير إلى المزوّد المعني، لكنها غير مسؤولة عن رفض المزوّد رد المبلغ وفق سياسته الخاصة.',
    ),
    _LegalSection(
      titleEn: '6. Acceptable Use',
      titleAr: '6. الاستخدام المقبول',
      bodyEn:
          'You agree not to use the Service to make fraudulent bookings, scrape or reverse-engineer the Service, interfere with its operation, impersonate another person, or violate any applicable law. We may suspend or terminate accounts that violate this section.',
      bodyAr:
          'توافق على عدم استخدام الخدمة لإجراء حجوزات احتيالية، أو استخراج بياناتها أو إعادة هندستها، أو التدخل في تشغيلها، أو انتحال شخصية شخص آخر، أو مخالفة أي قانون معمول به. يجوز لنا تعليق أو إنهاء الحسابات التي تخالف هذا البند.',
    ),
    _LegalSection(
      titleEn: '7. Intellectual Property',
      titleAr: '7. الملكية الفكرية',
      bodyEn:
          'The Service, including its design, text, graphics, and underlying software, is owned by Flynoom or its licensors and protected by intellectual property laws. You may not copy, modify, or distribute any part of the Service without our written permission.',
      bodyAr:
          'الخدمة، بما في ذلك تصميمها ونصوصها ورسومها والبرمجيات الكامنة فيها، مملوكة لـ Flynoom أو للجهات المرخِّصة لها ومحمية بموجب قوانين الملكية الفكرية. لا يجوز لك نسخ أي جزء من الخدمة أو تعديله أو توزيعه دون إذن كتابي منا.',
    ),
    _LegalSection(
      titleEn: '8. Disclaimers',
      titleAr: '8. إخلاء المسؤولية',
      bodyEn:
          'The Service is provided "as is" without warranties of any kind. Flynoom does not guarantee the accuracy of prices, availability, or content supplied by third parties, and is not responsible for the acts or omissions of airlines, hotels, or other suppliers.',
      bodyAr:
          'تُقدَّم الخدمة "كما هي" دون أي ضمانات من أي نوع. لا تضمن Flynoom دقة الأسعار أو التوافر أو المحتوى المقدَّم من أطراف ثالثة، وهي غير مسؤولة عن أفعال أو تقصير شركات الطيران أو الفنادق أو المزوّدين الآخرين.',
    ),
    _LegalSection(
      titleEn: '9. Limitation of Liability',
      titleAr: '9. حدود المسؤولية',
      bodyEn:
          "To the fullest extent permitted by law, Flynoom's total liability for any claim arising from your use of the Service is limited to the amount of fees you paid to Flynoom (not including amounts paid to suppliers) for the booking giving rise to the claim. Flynoom is not liable for indirect, incidental, or consequential damages.",
      bodyAr:
          'إلى أقصى حد يسمح به القانون، تقتصر مسؤولية Flynoom الإجمالية عن أي مطالبة ناشئة عن استخدامك للخدمة على قيمة الرسوم التي دفعتها لـ Flynoom (باستثناء المبالغ المدفوعة للمزوّدين) عن الحجز موضوع المطالبة. لا تتحمل Flynoom مسؤولية عن أي أضرار غير مباشرة أو عرضية أو تبعية.',
    ),
    _LegalSection(
      titleEn: '10. Dispute Resolution',
      titleAr: '10. حل النزاعات',
      bodyEn:
          'Most concerns can be resolved by contacting our Customer Service team. For formal dispute resolution procedures, including arbitration, please see our separate Dispute Resolution page.',
      bodyAr:
          'يمكن حل معظم المشكلات بالتواصل مع فريق خدمة العملاء لدينا. للاطلاع على إجراءات حل النزاعات الرسمية، بما في ذلك التحكيم، يُرجى مراجعة صفحة حل النزاعات المنفصلة لدينا.',
    ),
    _LegalSection(
      titleEn: '11. Governing Law',
      titleAr: '11. القانون الحاكم',
      bodyEn:
          'These Terms are governed by the laws of the State of Michigan, United States, without regard to conflict-of-law principles, except where applicable consumer protection law requires otherwise.',
      bodyAr:
          'تخضع هذه الشروط لقوانين ولاية ميشيغان بالولايات المتحدة، بغض النظر عن مبادئ تنازع القوانين، إلا حيثما تقتضي قوانين حماية المستهلك المعمول بها خلاف ذلك.',
    ),
    _LegalSection(
      titleEn: '12. Changes to These Terms',
      titleAr: '12. تعديلات على هذه الشروط',
      bodyEn:
          'We may revise these Terms from time to time. Continued use of the Service after changes take effect constitutes acceptance of the revised Terms.',
      bodyAr:
          'يجوز لنا تعديل هذه الشروط من وقت لآخر. يُعد استمرارك في استخدام الخدمة بعد سريان التعديلات موافقةً منك على الشروط المعدَّلة.',
    ),
    _LegalSection(
      titleEn: '13. Contact',
      titleAr: '13. التواصل',
      bodyEn: 'Questions about these Terms can be directed to our Customer Service team through the app.',
      bodyAr: 'يمكن توجيه الأسئلة حول هذه الشروط إلى فريق خدمة العملاء لدينا عبر التطبيق.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    return Scaffold(
      appBar: AppBar(
        title: Text(isArabic ? 'شروط الخدمة' : 'Terms of Service'),
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
                  isArabic ? 'شروط الخدمة' : 'Terms of Service',
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