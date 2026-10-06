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

/// مجموعة بداية من مقالات سفر عملية دائمة الصلاحية (مش أخبار عاجلة
/// هتفقد قيمتها بسرعة). المحتوى دلوقتي إنجليزي/عربي بس؛ ممكن نوسّعه
/// للغات التسعة لو القسم لاقى تفاعل فعلي.
class TravelArticlesPage extends StatelessWidget {
  const TravelArticlesPage({super.key});

  static const List<_Article> _articles = [
    _Article(
      icon: Icons.luggage_outlined,
      titleEn: 'How to pack light for any trip',
      titleAr: 'كيف تسافر بحقيبة خفيفة لأي رحلة',
      bodyEn:
      'Pick a neutral color scheme so every piece mixes and matches, roll clothes instead of folding to save space, and wear your bulkiest item (jacket, boots) on the plane instead of packing it. Pack one outfit at a time in your head for each day, then remove one item — you almost always packed more than you need.',
      bodyAr:
      'اختر ألوانًا متناسقة عشان كل قطعة تتماشى مع الباقي، ولفّ الملابس بدل طيّها عشان توفّر مساحة، والبس أثقل قطعة عندك (جاكيت، جزمة) في الطيارة بدل ما تحطها في الشنطة. تخيّل ملابس كل يوم في دماغك الأول، وبعدين شيل قطعة واحدة — غالبًا هتلاقي إنك جهّزت أكتر من اللي محتاجه فعلًا.',
    ),
    _Article(
      icon: Icons.schedule_outlined,
      titleEn: 'Beating jet lag',
      titleAr: 'التغلب على اضطراب الرحلات الطويلة (Jet Lag)',
      bodyEn:
      'Start shifting your sleep schedule a few days before you fly, in the direction of your destination\'s time zone. On the flight, set your watch to the destination time immediately and try to sleep or stay awake accordingly. Get outside in daylight as soon as you land — natural light is the fastest way to reset your body clock.',
      bodyAr:
      'ابدأ تغيير مواعيد نومك قبل السفر بأيام، في اتجاه توقيت وجهتك. في الطيارة، اضبط ساعتك على توقيت الوجهة على طول وحاول تنام أو تصحى بناءً عليه. اخرج تحت ضوء الشمس أول ما توصل — الضوء الطبيعي أسرع طريقة تظبط بيها ساعتك البيولوجية.',
    ),
    _Article(
      icon: Icons.credit_card_outlined,
      titleEn: 'Managing money abroad',
      titleAr: 'إدارة أموالك في السفر',
      bodyEn:
      'Notify your bank before you travel so a foreign charge doesn\'t get flagged as fraud. Carry two payment methods from different networks in case one is declined, and keep a small amount of local cash for places that don\'t take cards. Check your card\'s foreign transaction fee before you go — some charge nothing, others add 3% to every purchase.',
      bodyAr:
      'أبلغ بنكك قبل السفر عشان أي عملية دفع من بره ما تتحسبش احتيال. احمل وسيلتي دفع من شبكتين مختلفتين احتياطًا لو واحدة اترفضت، واحمل كاش محلي بسيط للأماكن اللي ما بتقبلش بطاقات. تأكد من رسوم المعاملات الأجنبية على بطاقتك قبل السفر — بعض البطاقات مفيهاش رسوم، وبعضها بيضيف 3% على كل عملية.',
    ),
    _Article(
      icon: Icons.wifi_outlined,
      titleEn: 'Staying connected without a huge bill',
      titleAr: 'ابقَ متصلًا من غير فاتورة ضخمة',
      bodyEn:
      'An eSIM bought before you land is usually cheaper and easier than a physical SIM card, and most modern phones support it. Download offline maps of your destination before you go so you\'re not relying on data the moment you land, and check whether your hotel or Airbnb includes free wifi before assuming it does.',
      bodyAr:
      'شراء eSIM قبل ما توصل غالبًا أرخص وأسهل من شريحة SIM فعلية، وأغلب الموبايلات الحديثة بتدعمه. نزّل خرائط وجهتك أوفلاين قبل السفر عشان متبقاش معتمد على الإنترنت أول ما توصل، وتأكد إن الفندق أو مكان إقامتك فيه واي فاي مجاني قبل ما تفترض كده.',
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
                  ? 'نصائح عملية تفيدك في أي رحلة، مش بس أخبار موسمية.'
                  : "Practical tips that hold up trip after trip, not just seasonal news.",
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
            const SizedBox(height: AppSizes.lg),
            const AppFooter(),
          ],
        ),
      ),
    );
  }
}