import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';

/// يختار النص المناسب حسب اللغة الحالية.
String _t3(
    BuildContext context, {
      required String ar,
      required String en,
      required String es,
      required String tr,
      required String id,
      required String hi,
      required String ur,
      required String fr,
      required String bn,
    }) {
  switch (Localizations.localeOf(context).languageCode) {
    case 'ar':
      return ar;
    case 'es':
      return es;
    case 'tr':
      return tr;
    case 'id':
      return id;
    case 'hi':
      return hi;
    case 'ur':
      return ur;
    case 'fr':
      return fr;
    case 'bn':
      return bn;
    default:
      return en;
  }
}

/// أهم 6 مدن أمريكية لقسم "وجهات رائجة" -- كل مدينة ليها صورة مخصصة
/// (asset محلي، بدون علم/رمز دولة، بناءً على طلب المستخدم). الدوس على
/// أي كارت بيستدعي onSelected بنفس اسم المدينة، اللي بيشغّل بحث حقيقي
/// (نفس آلية اختيار وجهة من القايمة المقترحة) ويعرض نتايج الفنادق.
class _TrendingCity {
  final String name;
  final String searchQuery;
  final String imageAsset;
  const _TrendingCity({required this.name, required this.searchQuery, required this.imageAsset});
}

const List<_TrendingCity> _trendingCities = [
  _TrendingCity(name: 'New York', searchQuery: 'New York', imageAsset: 'assets/images/destinations/new_york.jpg'),
  _TrendingCity(name: 'Las Vegas', searchQuery: 'Las Vegas', imageAsset: 'assets/images/destinations/las_vegas.jpg'),
  _TrendingCity(name: 'Miami', searchQuery: 'Miami', imageAsset: 'assets/images/destinations/miami.jpg'),
  _TrendingCity(name: 'Chicago', searchQuery: 'Chicago', imageAsset: 'assets/images/destinations/chicago.jpg'),
  _TrendingCity(name: 'Los Angeles', searchQuery: 'Los Angeles', imageAsset: 'assets/images/destinations/los_angeles.jpg'),
  // اسم العرض على الكارت "Washington, D.C." (بالفاصلة والنقطة) --
  // لكن استعلام البحث الفعلي "Washington" بس، لأن الاسم بعلامات الترقيم
  // مش بيتطابق مع تسمية المدينة عند HotelBeds ويرجّع نتيجة فاضية.
  _TrendingCity(name: 'Washington, D.C.', searchQuery: 'Washington', imageAsset: 'assets/images/destinations/washington_dc.jpg'),
];

/// قسم "وجهات رائجة" في تبويب Stays -- 6 كارتات لأهم مدن أمريكية في
/// صف أفقي واحد قابل للسكرول. الدوس على أي كارت بيشغّل onSelected
/// بنفس اسم المدينة، اللي بيدوّر عن كود الوجهة المطابق عند HotelBeds
/// وينفّذ بحث حقيقي (نفس المنطق الموجود بالفعل في _selectDestination
/// بصفحة الـ Home، من غير أي تكرار كود هنا).
class TrendingDestinations extends StatelessWidget {
  final void Function(String city) onSelected;

  const TrendingDestinations({super.key, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSizes.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _t3(context, ar: 'وجهات رائجة', en: 'Trending destinations', es: 'Destinos populares', tr: 'Popüler destinasyonlar', id: 'Destinasi populer',
                hi: 'लोकप्रिय गंतव्य',
                ur: 'مقبول منزلیں',
                fr: 'Destinations populaires',
                bn: 'জনপ্রিয় গন্তব্য'),
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          const SizedBox(height: AppSizes.md),
          SizedBox(
            height: 200,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _trendingCities.length,
              separatorBuilder: (_, __) => const SizedBox(width: AppSizes.sm),
              itemBuilder: (context, index) {
                final city = _trendingCities[index];
                return _TrendingCityCard(
                  city: city,
                  onTap: () => onSelected(city.searchQuery),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _TrendingCityCard extends StatelessWidget {
  final _TrendingCity city;
  final VoidCallback onTap;

  const _TrendingCityCard({required this.city, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        width: 220,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Container(color: Colors.grey.shade200),
              Image.asset(
                city.imageAsset,
                fit: BoxFit.cover,
                filterQuality: FilterQuality.high,
                errorBuilder: (_, __, ___) => Container(
                  color: Colors.grey.shade300,
                  child: const Icon(Icons.location_city, color: AppColors.textHint, size: 32),
                ),
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
                child: Text(
                  city.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}