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

/// حل النزاعات — FLYNOOM LLC (جزء من شروط الخدمة، البند 18).
///
/// ⚠️⚠️ أكثر صفحة تحتاج محاميًا قبل الإطلاق. التحكيم الإلزامي والتنازل عن
/// الدعوى الجماعية والتنازل عن هيئة المحلفين لها آثار قانونية كبيرة، وقد تُبطلها
/// المحكمة إن كانت مكتوبة أو معروضة بشكل غير سليم. أسئلة للمحامي:
///   • هل نعتمد AAA (Consumer Arbitration Rules) أم جهة أخرى؟ وما رسومها الحالية؟
///   • البند 4: التزامنا بدفع رسوم التحكيم — هل الصياغة مناسبة؟
///   • هل نضيف بندًا للتحكيم الجماعي (mass arbitration / batching)؟
///   • هل يكفي عرض الشروط برابط، أم نضيف مربع موافقة صريح عند الحجز
///     ("I agree to the Terms, including the arbitration agreement")؟ ← مستحسن.
class DisputeResolutionPage extends StatelessWidget {
  const DisputeResolutionPage({super.key});

  static const String _lastUpdatedEn = 'October 12, 2026';
  static const String _lastUpdatedAr = '12 أكتوبر 2026';

  /// بريد خدمة العملاء (موحّد في كل الصفحات القانونية). يجب أن يصل فعلًا.
  static const String _contactEmail = 'support@flynoom.com';

  static const List<_LegalSection> _sections = [
    _LegalSection(
      titleEn: "1. Let's Talk First",
      titleAr: '1. لنتحدث أولًا',
      bodyEn:
      'Most problems can be solved quickly. If you have a concern about a booking, a charge, or the Service, please email us at $_contactEmail and include your booking reference. If something goes wrong during your stay, please also tell the hotel right away so it can fix the issue on the spot.',
      bodyAr:
      'معظم المشكلات يمكن حلها بسرعة. إذا كان لديك أي اعتراض على حجز أو مبلغ مدفوع أو على الخدمة، فراسلنا على $_contactEmail واذكر رقم حجزك. وإذا حدثت مشكلة أثناء إقامتك، فأبلغ الفندق فورًا أيضًا ليتمكن من حلها في حينها.',
    ),
    _LegalSection(
      titleEn: '2. Formal Notice of Dispute',
      titleAr: '2. الإخطار الرسمي بالنزاع',
      bodyEn:
      'If we cannot resolve your concern informally, either party must send the other a written Notice of Dispute before starting arbitration or a court case. Your notice should be sent to $_contactEmail with the subject "Notice of Dispute" and include your name, account email, booking reference (if any), a description of the problem, and the remedy you want. Our notice to you will be sent to the email on your account. We will both try in good faith to resolve the dispute within 60 days after the notice is received.',
      bodyAr:
      'إذا تعذّر حل اعتراضك وديًا، يجب على كل طرف إرسال إخطار كتابي بالنزاع إلى الطرف الآخر قبل البدء في التحكيم أو رفع دعوى. يُرسل إخطارك إلى $_contactEmail مع كتابة "Notice of Dispute" في عنوان الرسالة، ويتضمن اسمك وبريد حسابك ورقم الحجز (إن وُجد) ووصفًا للمشكلة والحل الذي تطلبه. ونرسل إخطارنا إليك على البريد المسجل في حسابك. ويسعى الطرفان بحسن نية إلى حل النزاع خلال 60 يومًا من استلام الإخطار.',
    ),
    _LegalSection(
      titleEn: '3. Binding Individual Arbitration',
      titleAr: '3. التحكيم الفردي الملزم',
      bodyEn:
      'If the dispute is not resolved within 60 days, you and FLYNOOM LLC agree that any dispute arising from or relating to the Service, any booking, or these Terms will be resolved by binding arbitration on an individual basis, except as stated in Section 6. The arbitration will be administered by the American Arbitration Association (AAA) under its Consumer Arbitration Rules. Unless we both agree otherwise, the arbitration will be conducted by phone, video, or written submissions, or in person in the county where you live. The arbitrator may award the same individual relief that a court could award. YOU AND FLYNOOM ARE EACH GIVING UP THE RIGHT TO A TRIAL IN COURT BEFORE A JUDGE OR JURY.',
      bodyAr:
      'إذا لم يُحل النزاع خلال 60 يومًا، فإنك وشركة FLYNOOM LLC توافقان على حل أي نزاع ناشئ عن الخدمة أو عن أي حجز أو عن هذه الشروط أو متعلق بها عبر التحكيم الملزم بصفة فردية، باستثناء ما ورد في البند 6. تتولى إدارة التحكيم جمعية التحكيم الأمريكية (AAA) وفق قواعدها لتحكيم المستهلكين. وما لم نتفق على غير ذلك، يُجرى التحكيم عبر الهاتف أو الفيديو أو المستندات المكتوبة، أو حضوريًا في المقاطعة التي تقيم فيها. ويجوز للمحكّم أن يقضي بالتعويض الفردي نفسه الذي يمكن أن تقضي به المحكمة. وبذلك يتنازل كل منك ومن Flynoom عن الحق في المحاكمة أمام قاضٍ أو هيئة محلفين.',
    ),
    _LegalSection(
      titleEn: '4. Arbitration Costs',
      titleAr: '4. تكاليف التحكيم',
      bodyEn:
      'Payment of arbitration fees will follow the AAA Consumer Arbitration Rules, under which the business pays most of the fees. If you start arbitration and show that the filing fee you must pay is a hardship, we will consider paying it for you. Each party pays its own attorneys\' fees unless the arbitrator awards them under applicable law.',
      bodyAr:
      'يُحدَّد دفع رسوم التحكيم وفق قواعد AAA لتحكيم المستهلكين، والتي يتحمل فيها النشاط التجاري معظم الرسوم. وإذا بدأت التحكيم وأثبتّ أن رسوم التسجيل المطلوبة منك تمثل عبئًا عليك، فسننظر في دفعها عنك. ويتحمل كل طرف أتعاب محاميه ما لم يقضِ المحكّم بها وفق القانون المعمول به.',
    ),
    _LegalSection(
      titleEn: '5. Class Action Waiver',
      titleAr: '5. التنازل عن الدعوى الجماعية',
      bodyEn:
      'You and FLYNOOM LLC agree that each may bring claims against the other only in an individual capacity, and not as a plaintiff or class member in any class, consolidated, or representative proceeding. The arbitrator may not combine more than one person\'s claims. If this class action waiver is found unenforceable for a particular claim, that claim (and only that claim) will be decided by a court as described in Section 8, and not in arbitration.',
      bodyAr:
      'توافق أنت وشركة FLYNOOM LLC على أن يرفع كل طرف مطالباته ضد الآخر بصفته الفردية فقط، لا بصفته مدعيًا أو عضوًا في أي دعوى جماعية أو موحّدة أو تمثيلية. ولا يجوز للمحكّم ضم مطالبات أكثر من شخص واحد. وإذا ثبت أن هذا التنازل عن الدعوى الجماعية غير قابل للتنفيذ بالنسبة لمطالبة معينة، فإن تلك المطالبة وحدها تنظر فيها المحكمة كما في البند 8، لا هيئة التحكيم.',
    ),
    _LegalSection(
      titleEn: '6. Exceptions',
      titleAr: '6. الاستثناءات',
      bodyEn:
      'Either party may bring an individual claim in small claims court if it qualifies. Either party may ask a court for an injunction to protect intellectual property or stop unauthorized access to the Service. Nothing in this agreement prevents you from bringing an issue to the attention of a government agency, such as the U.S. Department of Transportation (for air travel), the Federal Trade Commission, or your state attorney general, or from using the dispute rights your card issuer provides.',
      bodyAr:
      'يجوز لأي من الطرفين رفع مطالبة فردية أمام محكمة المطالبات الصغيرة إذا كانت مؤهلة لذلك. ويجوز لأي من الطرفين أن يطلب من المحكمة أمرًا قضائيًا لحماية الملكية الفكرية أو لمنع الوصول غير المصرّح به إلى الخدمة. ولا يمنعك أي شيء في هذه الاتفاقية من عرض مشكلتك على جهة حكومية، مثل وزارة النقل الأمريكية (للسفر الجوي) أو لجنة التجارة الفيدرالية أو المدعي العام في ولايتك، أو من استخدام حقوق الاعتراض التي يوفرها لك البنك المُصدر لبطاقتك.',
    ),
    _LegalSection(
      titleEn: '7. Your Right to Opt Out',
      titleAr: '7. حقك في الانسحاب من التحكيم',
      bodyEn:
      'You may opt out of this arbitration agreement within 30 days after you first accept the Terms (for example, by creating an account or making your first booking). To opt out, email $_contactEmail from your account email with the subject "Arbitration Opt-Out" and include your full name. Opting out does not affect any other part of the Terms or your bookings. If you opt out, disputes will be resolved in court as described in Section 8.',
      bodyAr:
      'يمكنك الانسحاب من اتفاقية التحكيم هذه خلال 30 يومًا من أول قبول منك للشروط (مثل إنشاء حساب أو إجراء أول حجز). وللانسحاب، أرسل بريدًا من بريد حسابك إلى $_contactEmail مع كتابة "Arbitration Opt-Out" في عنوان الرسالة، واذكر اسمك الكامل. الانسحاب لا يؤثر على أي جزء آخر من الشروط ولا على حجوزاتك. وإذا انسحبت، تُحل النزاعات أمام المحاكم كما في البند 8.',
    ),
    _LegalSection(
      titleEn: '8. Governing Law and Courts',
      titleAr: '8. القانون الحاكم والمحاكم',
      bodyEn:
      'This arbitration agreement is governed by the Federal Arbitration Act. Where arbitration does not apply, disputes will be resolved in the state or federal courts located in Michigan, and you and Flynoom consent to their jurisdiction, except where the consumer protection law of your state of residence gives you the right to bring the claim in your home state.',
      bodyAr:
      'تخضع اتفاقية التحكيم هذه لقانون التحكيم الفيدرالي الأمريكي. وحيثما لا يسري التحكيم، تُحل النزاعات أمام المحاكم الولائية أو الفيدرالية الواقعة في ميشيغان، وتوافق أنت وFlynoom على اختصاصها، إلا حيثما يمنحك قانون حماية المستهلك في ولاية إقامتك الحق في رفع الدعوى في ولايتك.',
    ),
    _LegalSection(
      titleEn: '9. Changes to This Agreement',
      titleAr: '9. تعديل هذه الاتفاقية',
      bodyEn:
      'If we make a material change to this dispute resolution agreement, you may reject the change by emailing $_contactEmail within 30 days after the change takes effect. Rejecting a change means the earlier version continues to apply to you. Changes never apply to a dispute that was already the subject of a Notice of Dispute before the change. This agreement continues to apply after your account is closed.',
      bodyAr:
      'إذا أجرينا تعديلًا جوهريًا على اتفاقية حل النزاعات هذه، يمكنك رفض التعديل بمراسلتنا على $_contactEmail خلال 30 يومًا من سريانه، وعندها تبقى النسخة السابقة سارية عليك. ولا تسري التعديلات أبدًا على نزاع سبق تقديم إخطار رسمي بشأنه قبل التعديل. وتبقى هذه الاتفاقية سارية بعد إغلاق حسابك.',
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
                Semantics(
                  header: true,
                  child: Text(
                    isArabic ? 'حل النزاعات' : 'Dispute Resolution',
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isArabic ? 'آخر تحديث: $_lastUpdatedAr' : 'Last updated: $_lastUpdatedEn',
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                ),
                if (isArabic) ...[
                  const SizedBox(height: 8),
                  const Text(
                    'هذه ترجمة للتيسير، والنسخة الإنجليزية هي المعتمدة عند أي تعارض.',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 12, fontStyle: FontStyle.italic),
                  ),
                ],
                const SizedBox(height: AppSizes.md),
                _ImportantNotice(isArabic: isArabic),
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// تنبيه بارز في أعلى الصفحة: بند التحكيم يجب أن يكون واضحًا للعميل.
class _ImportantNotice extends StatelessWidget {
  final bool isArabic;
  const _ImportantNotice({required this.isArabic});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSizes.md),
      decoration: BoxDecoration(
        color: Colors.amber.withValues(alpha: 0.12),
        border: Border.all(color: Colors.amber.shade700),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, color: Colors.amber.shade800),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              isArabic
                  ? 'يُرجى القراءة بعناية. تتضمن هذه الصفحة اتفاقية تحكيم ملزم وتنازلًا عن الدعوى الجماعية وعن المحاكمة أمام هيئة محلفين، وهي تؤثر على حقوقك القانونية. يمكنك الانسحاب من التحكيم خلال 30 يومًا (البند 7).'
                  : 'PLEASE READ CAREFULLY. This page contains a binding arbitration agreement and a waiver of class actions and jury trials, which affect your legal rights. You may opt out of arbitration within 30 days (Section 7).',
              style: const TextStyle(fontSize: 14, height: 1.5, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}