import 'package:flutter/material.dart';

import '../../../core/constants/app_sizes.dart';

class _Deal {
  final IconData icon;
  final String titleEn;
  final String titleAr;
  final String subtitleEn;
  final String subtitleAr;
  final Color color;

  const _Deal({
    required this.icon,
    required this.titleEn,
    required this.titleAr,
    required this.subtitleEn,
    required this.subtitleAr,
    required this.color,
  });
}

const List<_Deal> _deals = [
  _Deal(
    icon: Icons.weekend_outlined,
    titleEn: 'Weekend Getaway',
    titleAr: 'عروض عطلة نهاية الأسبوع',
    subtitleEn: 'Save on stays this weekend',
    subtitleAr: 'وفّر على إقامتك هذا الأسبوع',
    color: Color(0xFF0B6E4F),
  ),
  _Deal(
    icon: Icons.percent_outlined,
    titleEn: 'Early Bird Discount',
    titleAr: 'خصم الحجز المبكر',
    subtitleEn: 'Book ahead and save more',
    subtitleAr: 'احجز مبكرًا ووفّر أكتر',
    color: Color(0xFF1E5F74),
  ),
  _Deal(
    icon: Icons.family_restroom_outlined,
    titleEn: 'Family Stays',
    titleAr: 'عروض العائلات',
    subtitleEn: 'Great deals for family trips',
    subtitleAr: 'عروض مميزة لرحلات العائلة',
    color: Color(0xFF7A4B8A),
  ),
];

/// قسم "عروض وخصومات" ترويجي — العروض حاليًا شكلية (تعرض "قريبًا")
/// إلى أن يُبنى نظام عروض فعلي مرتبط بقاعدة البيانات.
class DealsSection extends StatelessWidget {
  const DealsSection({super.key});

  void _showComingSoon(BuildContext context, bool isArabic) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(isArabic ? 'قريبًا' : 'Coming soon'),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSizes.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSizes.md),
            child: Text(
              isArabic ? 'عروض وخصومات' : 'Deals & Offers',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ),
          const SizedBox(height: AppSizes.sm),
          SizedBox(
            height: 110,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: AppSizes.md),
              itemCount: _deals.length,
              separatorBuilder: (_, __) => const SizedBox(width: AppSizes.sm),
              itemBuilder: (context, index) {
                final deal = _deals[index];
                return InkWell(
                  onTap: () => _showComingSoon(context, isArabic),
                  borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                  child: Container(
                    width: 220,
                    padding: const EdgeInsets.all(AppSizes.md),
                    decoration: BoxDecoration(
                      color: deal.color,
                      borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(deal.icon, color: Colors.white, size: 26),
                        const Spacer(),
                        Text(
                          isArabic ? deal.titleAr : deal.titleEn,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          isArabic ? deal.subtitleAr : deal.subtitleEn,
                          style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}