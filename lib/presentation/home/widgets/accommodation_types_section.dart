import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';

class _AccommodationType {
  final IconData icon;
  final String labelEn;
  final String labelAr;
  final Color color;

  const _AccommodationType({
    required this.icon,
    required this.labelEn,
    required this.labelAr,
    required this.color,
  });
}

// كل نوع إقامة له لون مميز خاص به بدل اللون الموحّد (AppColors.primary)
// -- نفس فلسفة الألوان المستخدمة في أماكن تانية بالتطبيق (بطاقات
// المسافرين، شريط التنقل الجانبي).
const List<_AccommodationType> _types = [
  _AccommodationType(icon: Icons.hotel, labelEn: 'Hotels', labelAr: 'فنادق', color: Color(0xFF2E86AB)),
  _AccommodationType(icon: Icons.apartment, labelEn: 'Apartments', labelAr: 'شقق', color: Color(0xFF27AE60)),
  _AccommodationType(icon: Icons.villa_outlined, labelEn: 'Villas', labelAr: 'فلل', color: Color(0xFFE67E22)),
  _AccommodationType(icon: Icons.cabin_outlined, labelEn: 'Resorts', labelAr: 'منتجعات', color: Color(0xFF8E44AD)),
  _AccommodationType(icon: Icons.holiday_village_outlined, labelEn: 'Chalets', labelAr: 'شاليهات', color: Color(0xFFD6558E)),
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
            height: 130,
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
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    width: 130,
                    padding: const EdgeInsets.all(AppSizes.md),
                    decoration: BoxDecoration(
                      color: type.color.withOpacity(isSelected ? 0.16 : 0.08),
                      border: Border.all(
                        color: type.color.withOpacity(isSelected ? 0.9 : 0.3),
                        width: isSelected ? 2 : 1,
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(type.icon, color: type.color, size: 38),
                        const SizedBox(height: 10),
                        Text(
                          isArabic ? type.labelAr : type.labelEn,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                            color: type.color,
                          ),
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