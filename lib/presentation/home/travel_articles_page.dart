import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../core/widgets/app_banner.dart';
import '../../core/widgets/app_footer.dart';

class _Article {
  final IconData icon;
  final String titleEn;
  final String titleAr;
  final String bodyEn;
  final String bodyAr;
  const _Article({
    required this.icon,
    required this.titleEn,
    required this.titleAr,
    required this.bodyEn,
    required this.bodyAr,
  });
}

/// مقالات سفر عملية دائمة الصلاحية (ليست أخبارًا تفقد قيمتها بسرعة).
/// المحتوى بالإنجليزية والعربية الفصحى؛ اللغات الأخرى تعرض الإنجليزية.
///
/// ⚠️ قواعد المحتوى هنا:
/// - لا أسعار ولا رسوم تأشيرات ولا قواعد دخول محددة: تتغير ولا نتابعها.
///   نحيل القارئ دائمًا للمصدر الرسمي.
/// - لا أسماء علامات تجارية لفنادق أو شركات أو منافسين.
/// - لا وعود بخصومات أو خدمات غير موجودة فعلًا في المنصة.
/// - النصوص مكتوبة خصيصًا لـ Flynoom؛ لا تنسخ مقالات من مواقع أخرى.
class TravelArticlesPage extends StatelessWidget {
  const TravelArticlesPage({super.key});

  static const List<_Article> _articles = [
    // ───── مقالات تخص حجز الفنادق (تشرح ما يراه العميل في Flynoom) ─────
    _Article(
      icon: Icons.receipt_long_outlined,
      titleEn: 'Understanding the full price of a hotel stay',
      titleAr: 'فهم السعر الكامل لإقامتك الفندقية',
      bodyEn:
      'The room rate is only part of what you pay. Many destinations add taxes per night or per guest, and some hotels charge mandatory fees such as a resort fee or a city tax that is collected at check-in. Before you pay, look at the price breakdown: the total you pay now, and any amount the hotel will collect when you arrive. Flynoom shows both before you confirm a booking, so there are no surprises at the front desk.',
      bodyAr:
      'سعر الغرفة جزء فقط مما تدفعه. فكثير من الوجهات تضيف ضرائب عن كل ليلة أو عن كل نزيل، وبعض الفنادق تفرض رسومًا إلزامية مثل رسوم المنتجع أو ضريبة المدينة التي تُحصَّل عند الوصول. قبل الدفع، راجع تفاصيل السعر: المبلغ الذي تدفعه الآن، وأي مبلغ سيحصّله الفندق عند وصولك. يعرض لك Flynoom الأمرين قبل تأكيد الحجز، فلا تفاجأ بشيء في مكتب الاستقبال.',
    ),
    _Article(
      icon: Icons.event_busy_outlined,
      titleEn: 'How hotel cancellation policies work',
      titleAr: 'كيف تعمل سياسات إلغاء الحجز في الفنادق',
      bodyEn:
      'Each room comes with its own cancellation policy, and two rooms in the same hotel can have different rules. "Free cancellation" usually means you can cancel without charge until a specific date and time, often counted in the hotel\'s local time zone. After that deadline, part or all of the price may be charged. Non-refundable rates are often cheaper, but they make sense only when your plans are firm. Always read the deadline shown on the room before you book.',
      bodyAr:
      'لكل غرفة سياسة إلغاء خاصة بها، وقد تختلف القواعد بين غرفتين في الفندق نفسه. وعبارة "إلغاء مجاني" تعني عادةً أنك تستطيع الإلغاء دون رسوم حتى تاريخ ووقت محددين، يُحسبان غالبًا بالتوقيت المحلي للفندق. وبعد هذا الموعد قد يُخصم جزء من السعر أو كله. أما الأسعار غير القابلة للاسترداد فتكون أرخص في الغالب، لكنها مناسبة فقط عندما تكون خطتك مؤكدة. اقرأ دائمًا الموعد النهائي المعروض على الغرفة قبل الحجز.',
    ),
    _Article(
      icon: Icons.mosque_outlined,
      titleEn: 'Choosing a hotel for Umrah',
      titleAr: 'اختيار الفندق المناسب لرحلة العمرة',
      bodyEn:
      'Distance to the Haram matters more than almost anything else, especially if you are traveling with elderly family members or children: a short walk saves energy for worship. Check whether the distance listed is walking distance or a straight line on the map. Book early for Ramadan and school holidays, when demand is highest. Before you travel, confirm the current visa and Umrah permit requirements on the official Saudi government websites, as these rules can change.',
      bodyAr:
      'المسافة إلى الحرم أهم من أي شيء آخر تقريبًا، خاصةً إن كنت مسافرًا مع كبار السن أو الأطفال، فالمشي القصير يوفّر جهدك للعبادة. تأكد هل المسافة المذكورة مسافة مشي فعلية أم خط مستقيم على الخريطة. واحجز مبكرًا في رمضان والعطلات المدرسية، حين يكون الطلب في ذروته. وقبل السفر، تأكد من شروط التأشيرة وتصريح العمرة الحالية من المواقع الرسمية للحكومة السعودية، لأن هذه القواعد قد تتغير.',
    ),

    // ───── نصائح سفر عامة ─────
    _Article(
      icon: Icons.luggage_outlined,
      titleEn: 'How to pack light for any trip',
      titleAr: 'كيف تسافر بحقيبة خفيفة في أي رحلة',
      bodyEn:
      'Pick a neutral color scheme so every piece mixes and matches, roll clothes instead of folding to save space, and wear your bulkiest item (jacket, boots) on the plane instead of packing it. Pack one outfit at a time in your head for each day, then remove one item — you almost always packed more than you need.',
      bodyAr:
      'اختر ألوانًا متناسقة حتى تتماشى كل قطعة مع البقية، ولُفّ الملابس بدل طيّها لتوفير المساحة، وارتدِ أثقل قطعة لديك، كالمعطف أو الحذاء الشتوي، في الطائرة بدل وضعها في الحقيبة. تخيّل ملابس كل يوم على حدة، ثم استبعد قطعة واحدة، فغالبًا ستجد أنك جهّزت أكثر مما تحتاج.',
    ),
    _Article(
      icon: Icons.schedule_outlined,
      titleEn: 'Beating jet lag',
      titleAr: 'التغلب على اضطراب الرحلات الطويلة',
      bodyEn:
      'Start shifting your sleep schedule a few days before you fly, in the direction of your destination\'s time zone. On the flight, set your watch to the destination time immediately and try to sleep or stay awake accordingly. Get outside in daylight as soon as you land — natural light is the fastest way to reset your body clock.',
      bodyAr:
      'ابدأ بتعديل مواعيد نومك قبل السفر بأيام، باتجاه توقيت وجهتك. وفي الطائرة اضبط ساعتك على توقيت الوجهة فورًا، وحاول أن تنام أو تبقى مستيقظًا وفقًا له. واخرج إلى ضوء النهار فور وصولك، فالضوء الطبيعي أسرع وسيلة لضبط ساعتك البيولوجية.',
    ),
    _Article(
      icon: Icons.credit_card_outlined,
      titleEn: 'Managing money abroad',
      titleAr: 'إدارة أموالك أثناء السفر',
      bodyEn:
      'Notify your bank before you travel so a foreign charge doesn\'t get flagged as fraud. Carry two payment methods from different networks in case one is declined, and keep a small amount of local cash for places that don\'t take cards. Check your card\'s foreign transaction fee before you go — some cards charge nothing, others add a percentage to every purchase.',
      bodyAr:
      'أبلغ بنكك قبل السفر حتى لا تُعدّ أي عملية دفع من الخارج محاولة احتيال. واحمل وسيلتي دفع من شبكتين مختلفتين احتياطًا إن رُفضت إحداهما، واحتفظ بمبلغ نقدي صغير بالعملة المحلية للأماكن التي لا تقبل البطاقات. وتحقق من رسوم المعاملات الأجنبية على بطاقتك قبل السفر، فبعض البطاقات لا تفرض رسومًا، وبعضها يضيف نسبة على كل عملية شراء.',
    ),
    _Article(
      icon: Icons.wifi_outlined,
      titleEn: 'Staying connected without a huge bill',
      titleAr: 'ابقَ متصلًا دون فاتورة كبيرة',
      bodyEn:
      'An eSIM bought before you land is usually cheaper and easier than a physical SIM card, and most modern phones support it. Download offline maps of your destination before you go so you\'re not relying on data the moment you land, and check whether your accommodation includes free Wi-Fi before assuming it does.',
      bodyAr:
      'شراء شريحة إلكترونية (eSIM) قبل الوصول أرخص وأسهل غالبًا من الشريحة العادية، وتدعمها معظم الهواتف الحديثة. ونزّل خرائط وجهتك للاستخدام دون إنترنت قبل السفر حتى لا تعتمد على البيانات فور وصولك، وتأكد أن مكان إقامتك يوفر شبكة Wi-Fi مجانية قبل أن تفترض ذلك.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    return Scaffold(
      appBar: const AppBanner(),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSizes.lg),
          children: [
            Text(
              isArabic ? 'مقالات سفر' : 'Travel articles',
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppSizes.md),
            Text(
              isArabic
                  ? 'نصائح عملية تفيدك في كل رحلة، وليست أخبارًا موسمية.'
                  : 'Practical tips that hold up trip after trip, not just seasonal news.',
              style: const TextStyle(fontSize: 15, color: AppColors.textSecondary, height: 1.5),
            ),
            const SizedBox(height: AppSizes.xl),
            for (final a in _articles) ...[
              Container(
                padding: const EdgeInsets.all(AppSizes.md),
                margin: const EdgeInsets.only(bottom: AppSizes.md),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.divider),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(a.icon, color: AppColors.primary, size: 24),
                        const SizedBox(width: AppSizes.sm),
                        Expanded(
                          child: Text(
                            isArabic ? a.titleAr : a.titleEn,
                            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSizes.sm),
                    Text(
                      isArabic ? a.bodyAr : a.bodyEn,
                      style: const TextStyle(fontSize: 14, height: 1.6, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: AppSizes.sm),
            // إخلاء مسؤولية: المقالات معلومات عامة وليست نصيحة مهنية.
            Text(
              isArabic
                  ? 'هذه المقالات معلومات عامة للمساعدة في التخطيط، وليست نصيحة قانونية أو طبية أو مالية. تحقق دائمًا من القواعد الحالية من المصادر الرسمية قبل السفر.'
                  : 'These articles are general information to help you plan. They are not legal, medical, or financial advice. Always check current rules with official sources before you travel.',
              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.5),
            ),
            const SizedBox(height: AppSizes.lg),
            const AppFooter(),
          ],
        ),
      ),
    );
  }
}