import 'package:flutter/material.dart';

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

/// كيف نعمل — شرح شفاف لطريقة عمل Flynoom وكيف تربح وكيف ترتّب النتائج.
///
/// ⚠️ كل جملة هنا وعد للعميل، ويجب أن تبقى مطابقة للنظام:
///   • "How we make money": السعر يشمل هامشنا (HOTELBEDS_MARKUP_PERCENT). لا رسوم حجز منفصلة.
///   • "How results are ordered": لا يوجد ترتيب مدفوع. إن أضفت يومًا "Sponsored"
///     أو ترتيبًا مقابل عمولة أعلى، يجب تعديل هذا القسم ووضع علامة واضحة على النتائج.
///   • "Ratings": نعرض تصنيف النجوم الرسمي من المزوّد فقط، لا تقييمات نزلاء.
class HowWeWorkPage extends StatelessWidget {
  const HowWeWorkPage({super.key});

  static const String _contactEmail = 'support@flynoom.com';

  static const List<_InfoSection> _sections = [
    _InfoSection(
      titleEn: 'We are a travel agency, not a hotel',
      titleAr: 'نحن وكالة سفر، لسنا فندقًا',
      bodyEn:
      'Flynoom is operated by FLYNOOM LLC, an online travel agency based in Michigan. We do not own any hotels. We sell hotel rooms supplied by others through our partner HOTELBEDS, one of the world\'s largest hotel supply networks. The hotel provides the stay itself.',
      bodyAr:
      'تدير Flynoom شركةُ FLYNOOM LLC، وهي وكالة سفر إلكترونية مقرها ميشيغان. لا نمتلك أي فنادق، بل نبيع غرفًا فندقية تقدمها جهات أخرى عبر شريكنا HOTELBEDS، إحدى أكبر شبكات توريد الفنادق في العالم. والفندق هو من يقدّم الإقامة نفسها.',
    ),
    _InfoSection(
      titleEn: 'Live prices and availability',
      titleAr: 'أسعار وتوفر لحظي',
      bodyEn:
      'Each time you search, we request current rooms and rates from our supplier. Before you pay, we check the exact rate again. If the price has changed, we show you the new price before you are charged, and you decide whether to continue.',
      bodyAr:
      'في كل عملية بحث نطلب من المزوّد الغرف والأسعار الحالية. وقبل أن تدفع، نتحقق من السعر نفسه مرة أخرى؛ فإن تغيّر نعرض عليك السعر الجديد قبل أي خصم، ولك أن تقرر المتابعة أو لا.',
    ),
    _InfoSection(
      titleEn: 'All-in prices, no hidden fees',
      titleAr: 'أسعار شاملة دون رسوم خفية',
      bodyEn:
      'Prices are shown in U.S. dollars. The total price includes everything you must pay for the stay. Some hotels charge mandatory fees at the property, such as resort fees or local taxes; we include them in the total and list them as "Payable at the hotel", so you see the full cost before you book. We do not add a separate booking fee.',
      bodyAr:
      'تُعرض الأسعار بالدولار الأمريكي. السعر الإجمالي يشمل كل ما يجب عليك دفعه مقابل الإقامة. بعض الفنادق تفرض رسومًا إلزامية تُدفع في الفندق، مثل رسوم المنتجع أو الضرائب المحلية؛ ونحن ندرجها في الإجمالي ونذكرها تحت "تُدفع في الفندق"، لترى التكلفة الكاملة قبل الحجز. ولا نضيف رسوم حجز منفصلة.',
    ),
    _InfoSection(
      titleEn: 'How we make money',
      titleAr: 'كيف نربح',
      bodyEn:
      'Our supplier sells us rooms at a wholesale price. The price you see includes our margin on top of that wholesale price, along with the cost of payment processing. That margin is how Flynoom earns money. We do not charge you any extra service fee at checkout.',
      bodyAr:
      'يبيعنا المزوّد الغرف بسعر الجملة، والسعر الذي تراه يشمل هامشنا فوق سعر الجملة إلى جانب تكلفة معالجة الدفع. هذا الهامش هو مصدر ربح Flynoom، ولا نفرض عليك أي رسوم خدمة إضافية عند الدفع.',
    ),
    _InfoSection(
      titleEn: 'How results are ordered',
      titleAr: 'كيف نرتّب النتائج',
      bodyEn:
      'Hotels cannot pay Flynoom to appear higher in your search results, and we do not show sponsored or paid listings. Results are based on your destination, dates, and number of guests, and on the rooms our supplier has available for your search.',
      bodyAr:
      'لا تستطيع الفنادق الدفع لـ Flynoom لتظهر في مرتبة أعلى في نتائج بحثك، ولا نعرض نتائج مموّلة أو مدفوعة. تعتمد النتائج على وجهتك وتواريخك وعدد النزلاء، وعلى الغرف المتاحة لدى المزوّد لبحثك.',
    ),
    _InfoSection(
      titleEn: 'Star ratings and hotel information',
      titleAr: 'تصنيف النجوم ومعلومات الفندق',
      bodyEn:
      'The star rating shown for each hotel is its official category as provided by our supplier. It is not a guest review score. Hotel photos, descriptions, and amenities also come from our supplier and the hotel. We do not currently publish guest reviews.',
      bodyAr:
      'تصنيف النجوم المعروض لكل فندق هو فئته الرسمية كما يقدّمها المزوّد، وليس درجة تقييم من النزلاء. كما أن صور الفنادق وأوصافها ومرافقها مصدرها المزوّد والفندق. ولا ننشر حاليًا تقييمات النزلاء.',
    ),
    _InfoSection(
      titleEn: 'Secure payment: you are charged only after confirmation',
      titleAr: 'دفع آمن: لا يُخصم المبلغ إلا بعد التأكيد',
      bodyEn:
      'Payments are processed by Stripe, and Flynoom never stores your card number. When you book, we place a temporary hold on your card. We take the payment only after the hotel confirms your booking. If the booking cannot be confirmed, we release the hold and you are not charged.',
      bodyAr:
      'تُعالَج المدفوعات عبر Stripe، ولا تخزّن Flynoom رقم بطاقتك أبدًا. عند الحجز نضع حجزًا مؤقتًا للمبلغ على بطاقتك، ولا نسحب المبلغ إلا بعد أن يؤكد الفندق حجزك. وإن تعذّر تأكيد الحجز، نُلغي الحجز المؤقت ولا يُخصم منك شيء.',
    ),
    _InfoSection(
      titleEn: 'After you book',
      titleAr: 'بعد الحجز',
      bodyEn:
      'You receive a confirmation email with your voucher and booking reference, and your booking appears in "My Bookings". You can view the voucher there and cancel eligible bookings online. Before you confirm a cancellation, we show you the exact fee and refund. Refunds go back to your card, usually within 5 to 10 business days.',
      bodyAr:
      'تصلك رسالة تأكيد على بريدك مع القسيمة ورقم الحجز، ويظهر حجزك في "حجوزاتي"، حيث يمكنك عرض القسيمة وإلغاء الحجوزات المؤهلة عبر الإنترنت. وقبل أن تؤكد الإلغاء، نعرض لك الرسوم والمبلغ المسترد بالضبط. ويُرد المبلغ إلى بطاقتك عادةً خلال 5 إلى 10 أيام عمل.',
    ),
    _InfoSection(
      titleEn: 'Help when you need it',
      titleAr: 'مساعدة عندما تحتاجها',
      bodyEn:
      'If you have a question or a problem with a booking, email us at $_contactEmail with your booking reference. We aim to reply within two business days and will work with the hotel on your behalf. If something is wrong during your stay, please also tell the hotel right away.',
      bodyAr:
      'إذا كان لديك سؤال أو مشكلة في حجز، فراسلنا على $_contactEmail مع رقم الحجز. نسعى للرد خلال يومَي عمل، وسنتابع الأمر مع الفندق نيابة عنك. وإذا حدثت مشكلة أثناء إقامتك، فأبلغ الفندق فورًا أيضًا.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    return Scaffold(
      appBar: AppBar(
        title: Text(isArabic ? 'كيف نعمل' : 'How We Work'),
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
                    isArabic ? 'كيف تعمل Flynoom' : 'How Flynoom works',
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: AppSizes.md),
                Text(
                  isArabic
                      ? 'نريدك أن تعرف بالضبط ما الذي تدفع مقابله، وممن تشتري، وكيف نربح، وكيف نعرض لك النتائج.'
                      : 'We want you to know exactly what you are paying for, who you are buying from, how we make money, and how we show you results.',
                  style: const TextStyle(fontSize: 14, height: 1.6, color: AppColors.textSecondary),
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}