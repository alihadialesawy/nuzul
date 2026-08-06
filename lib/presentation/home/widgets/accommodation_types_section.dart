import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';

class _AccommodationType {
  final IconData icon;
  final String labelEn;
  final String labelAr;

  const _AccommodationType({
    required this.icon,
    required this.labelEn,
    required this.labelAr,
  });
}

const List<_AccommodationType> _types = [
  _AccommodationType(icon: Icons.hotel, labelEn: 'Hotels', labelAr: 'فنادق'),
  _AccommodationType(icon: Icons.apartment, labelEn: 'Apartments', labelAr: 'شقق'),
  _AccommodationType(icon: Icons.villa_outlined, labelEn: 'Villas', labelAr: 'فلل'),
  _AccommodationType(icon: Icons.cabin_outlined, labelEn: 'Resorts', labelAr: 'منتجعات'),
  _AccommodationType(icon: Icons.holiday_village_outlined, labelEn: 'Chalets', labelAr: 'شاليهات'),
];

/// قسم "أنواع الإقامة الشائعة". الفلترة الفعلية غير مفعّلة بعد (لعدم
/// وجود حقل نوع العقار في قاعدة البيانات حاليًا)، والضغط يعرض "قريبًا".
class AccommodationTypesSection extends StatelessWidget {
  const AccommodationTypesSection({super.key});

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
              isArabic ? 'أنواع الإقامة الشائعة' : 'Popular accommodation types',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ),
          const SizedBox(height: AppSizes.sm),
          SizedBox(
            height: 90,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: AppSizes.md),
              itemCount: _types.length,
              separatorBuilder: (_, __) => const SizedBox(width: AppSizes.sm),
              itemBuilder: (context, index) {
                final type = _types[index];
                return InkWell(
                  onTap: () => _showComingSoon(context, isArabic),
                  borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                  child: Container(
                    width: 90,
                    padding: const EdgeInsets.all(AppSizes.sm),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.divider),
                      borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(type.icon, color: AppColors.primary, size: 26),
                        const SizedBox(height: 6),
                        Text(
                          isArabic ? type.labelAr : type.labelEn,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 12),
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