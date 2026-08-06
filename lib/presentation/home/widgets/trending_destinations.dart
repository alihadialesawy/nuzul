import 'package:flutter/material.dart';

import '../../../core/constants/app_sizes.dart';

class _Destination {
  final String cityEn;
  final String cityAr;
  final String countryCode;
  final Color badgeColor;
  final Color badgeTextColor;
  final String imageAsset;

  const _Destination({
    required this.cityEn,
    required this.cityAr,
    required this.countryCode,
    required this.badgeColor,
    required this.badgeTextColor,
    required this.imageAsset,
  });
}

/// وجهات تجريبية للعرض، بصور محلية من assets/images/destinations/.
const List<_Destination> _destinations = [
  _Destination(
    cityEn: 'Prague',
    cityAr: 'براغ',
    countryCode: 'CZ',
    badgeColor: Color(0xFFD7141A),
    badgeTextColor: Colors.white,
    imageAsset: 'assets/images/destinations/prague_cz.jpg',
  ),
  _Destination(
    cityEn: 'London',
    cityAr: 'لندن',
    countryCode: 'GB',
    badgeColor: Color(0xFF012169),
    badgeTextColor: Colors.white,
    imageAsset: 'assets/images/destinations/london.jpg',
  ),
  _Destination(
    cityEn: 'Tokyo',
    cityAr: 'طوكيو',
    countryCode: 'JP',
    badgeColor: Colors.white,
    badgeTextColor: Color(0xFFBC002D),
    imageAsset: 'assets/images/destinations/tokyo.jpg',
  ),
  _Destination(
    cityEn: 'Paris',
    cityAr: 'باريس',
    countryCode: 'FR',
    badgeColor: Color(0xFF0055A4),
    badgeTextColor: Colors.white,
    imageAsset: 'assets/images/destinations/paris.jpg',
  ),
  _Destination(
    cityEn: 'Madrid',
    cityAr: 'مدريد',
    countryCode: 'ES',
    badgeColor: Color(0xFFAA151B),
    badgeTextColor: Colors.white,
    imageAsset: 'assets/images/destinations/madrid.jpg',
  ),
];

/// قسم "وجهات رائجة" يظهر في الصفحة الرئيسية قبل تنفيذ أي بحث، بشكل
/// شبكة (وجهتين كبار فوق، وثلاث أصغر تحت). الضغط على أي وجهة ينفّذ
/// [onSelected] بتمرير اسم المدينة عشان الصفحة الرئيسية تبحث عنها.
class TrendingDestinations extends StatelessWidget {
  final void Function(String cityQuery) onSelected;

  const TrendingDestinations({super.key, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    return Padding(
      padding: const EdgeInsets.all(AppSizes.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isArabic ? 'وجهات رائجة' : 'Trending destinations',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          const SizedBox(height: AppSizes.sm),
          // الصف الأول: وجهتان كبيرتان
          Row(
            children: [
              Expanded(
                child: _DestinationCard(
                  destination: _destinations[0],
                  isArabic: isArabic,
                  height: 280,
                  onTap: onSelected,
                ),
              ),
              const SizedBox(width: AppSizes.sm),
              Expanded(
                child: _DestinationCard(
                  destination: _destinations[1],
                  isArabic: isArabic,
                  height: 280,
                  onTap: onSelected,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.sm),
          // الصف الثاني: ثلاث وجهات أصغر
          Row(
            children: [
              for (int i = 2; i < 5; i++) ...[
                if (i != 2) const SizedBox(width: AppSizes.sm),
                Expanded(
                  child: _DestinationCard(
                    destination: _destinations[i],
                    isArabic: isArabic,
                    height: 200,
                    onTap: onSelected,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _DestinationCard extends StatelessWidget {
  final _Destination destination;
  final bool isArabic;
  final double height;
  final void Function(String cityQuery) onTap;

  const _DestinationCard({
    required this.destination,
    required this.isArabic,
    required this.height,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cityLabel = isArabic ? destination.cityAr : destination.cityEn;

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppSizes.radiusSm),
      child: InkWell(
        onTap: () => onTap(destination.cityEn),
        child: SizedBox(
          height: height,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Container(color: Colors.grey.shade200),
              Image.asset(
                destination.imageAsset,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(color: Colors.grey.shade300),
              ),
              // تظليل تدريجي أسفل الصورة لوضوح النص الأبيض
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Colors.black54],
                  ),
                ),
              ),
              Positioned(
                left: 12,
                bottom: 10,
                right: 12,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      cityLabel,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                      decoration: BoxDecoration(
                        color: destination.badgeColor,
                        borderRadius: BorderRadius.circular(3),
                        border: Border.all(color: Colors.white, width: 0.5),
                      ),
                      child: Text(
                        destination.countryCode,
                        style: TextStyle(
                          color: destination.badgeTextColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}