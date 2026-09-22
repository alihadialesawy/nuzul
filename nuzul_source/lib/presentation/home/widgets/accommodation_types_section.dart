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

/// قسم "أنواع الإقامة الشائعة". الدوس على نوع بيبلّغ المتصل (عبر
/// [onTypeSelected]) بقيمة labelEn بتاعه (زي "Hotels")، فيقرر هو
/// (عادةً الصفحة الرئيسية) يعمل إيه -- زي إظهار قسم معاينة تحت مباشرة
/// (AccommodationPreviewSection). الدوس على نفس النوع المتعلّم حاليًا
/// تاني بيُستخدم عادةً كـ toggle لإلغاء التحديد من عند المتصل.
/// [selectedType] لو اتبعت، بيحدد أي زرار متعلّم حاليًا (تمييز بصري
/// فقط، لون إطار مختلف).
class AccommodationTypesSection extends StatelessWidget {
  final void Function(String labelEn) onTypeSelected;
  final String? selectedType;

  const AccommodationTypesSection({
    super.key,
    required this.onTypeSelected,
    this.selectedType,
  });

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
                final isSelected = selectedType == type.labelEn;
                return InkWell(
                  onTap: () => onTypeSelected(type.labelEn),
                  borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                  child: Container(
                    width: 90,
                    padding: const EdgeInsets.all(AppSizes.sm),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: isSelected ? AppColors.primary : AppColors.divider,
                        width: isSelected ? 2 : 1,
                      ),
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