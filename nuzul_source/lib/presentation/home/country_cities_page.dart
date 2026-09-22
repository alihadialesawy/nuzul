import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../core/widgets/app_banner.dart';
import '../../core/widgets/price_text.dart';
import '../../data/models/hotel_model.dart';
import '../../data/models/country_destinations_data.dart';
import '../../data/repositories/hotel_repository.dart';

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

/// Repository provider مخصص لهذه الصفحة (بادئة _country عشان يتفادى
/// أي تعارض اسم مع providers تانية بنفس النوع في ملفات أخرى).
final _countryHotelRepositoryProvider = Provider((ref) => HotelRepository());

/// يجيب أفضل 6 فنادق لمدينة معينة: أولًا يحوّل اسم المدينة لكود
/// HotelBeds الرسمي عبر searchDestinations، وبعدين يبحث فعليًا ويرتب
/// النتائج بالتقييم الأعلى. لو المدينة مش موجودة في hotelbeds_destinations
/// أصلًا (نادر لمدن كبيرة زي دي بس ممكن)، بيرجع قائمة فاضية بهدوء.
final cityTopHotelsProvider = FutureProvider.family<List<HotelModel>, String>((ref, cityName) async {
  final repo = ref.watch(_countryHotelRepositoryProvider);

  final destinationsResult = await repo.searchDestinations(cityName);
  final destination = destinationsResult.when(
    success: (list) => list.isNotEmpty ? list.first : null,
    failure: (_) => null,
  );
  if (destination == null) return [];

  final now = DateTime.now();
  final hotelsResult = await repo.searchHotels(
    destinationCode: destination.code,
    cityLabel: destination.name,
    checkIn: now.add(const Duration(days: 14)),
    checkOut: now.add(const Duration(days: 17)),
    guests: 2,
  );

  return hotelsResult.when(
    success: (hotels) {
      final sorted = [...hotels]..sort((a, b) => b.rating.compareTo(a.rating));
      return sorted.take(6).toList();
    },
    failure: (_) => [],
  );
});

class CountryCitiesPage extends StatelessWidget {
  final CountryGuide country;
  const CountryCitiesPage({super.key, required this.country});

  @override
  Widget build(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    return Scaffold(
      appBar: AppBanner(
        tabsBar: Text(
          isArabic ? country.nameAr : country.nameEn,
          style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
        ),
        bannerHeight: 140,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(AppSizes.md),
        itemCount: country.cities.length,
        itemBuilder: (context, index) => _CitySection(cityName: country.cities[index]),
      ),
    );
  }
}

class _CitySection extends ConsumerWidget {
  final String cityName;
  const _CitySection({required this.cityName});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hotelsAsync = ref.watch(cityTopHotelsProvider(cityName));

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSizes.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            cityName,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          const SizedBox(height: AppSizes.sm),
          hotelsAsync.when(
            loading: () => const SizedBox(
              height: 180,
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (error, _) => SizedBox(
              height: 60,
              child: Center(
                child: Text(
                  _t3(context, ar: 'تعذر تحميل فنادق $cityName', en: 'Could not load hotels for $cityName', es: 'No se pudieron cargar los hoteles de $cityName', tr: '$cityName otelleri yüklenemedi',
                      id: 'Gagal memuat hotel di $cityName',
                      hi: '$cityName के होटल लोड नहीं हो सके',
                      ur: '$cityName کے ہوٹل لوڈ نہیں ہو سکے',
                      fr: 'Impossible de charger les hôtels de $cityName',
                      bn: '$cityName এর হোটেল লোড করা যায়নি'),
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                ),
              ),
            ),
            data: (hotels) {
              if (hotels.isEmpty) {
                return SizedBox(
                  height: 60,
                  child: Center(
                    child: Text(
                      _t3(context, ar: 'لا توجد فنادق متاحة حاليًا', en: 'No hotels available right now', es: 'No hay hoteles disponibles', tr: 'Şu anda uygun otel yok',
                          id: 'Tidak ada hotel yang tersedia',
                          hi: 'फिलहाल कोई होटल उपलब्ध नहीं',
                          ur: 'فی الحال کوئی ہوٹل دستیاب نہیں',
                          fr: 'Aucun hôtel disponible pour le moment',
                          bn: 'বর্তমানে কোনো হোটেল নেই'),
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                    ),
                  ),
                );
              }
              return SizedBox(
                height: 200,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: hotels.length,
                  separatorBuilder: (_, __) => const SizedBox(width: AppSizes.sm),
                  itemBuilder: (context, index) => _CityHotelCard(hotel: hotels[index]),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _CityHotelCard extends StatelessWidget {
  final HotelModel hotel;
  const _CityHotelCard({required this.hotel});

  void _openHotelDetails(BuildContext context) {
    final now = DateTime.now();
    context.push(
      AppRoutes.hotelDetails,
      extra: {
        'hotel': hotel,
        'checkIn': now.add(const Duration(days: 14)),
        'checkOut': now.add(const Duration(days: 17)),
        'guests': 2,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 160,
      child: InkWell(
        onTap: () => _openHotelDetails(context),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.divider),
            borderRadius: BorderRadius.circular(12),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 100,
                width: double.infinity,
                child: hotel.images.isNotEmpty
                    ? Image.network(
                  hotel.images.first,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: AppColors.divider,
                    child: const Icon(Icons.hotel, color: AppColors.textHint),
                  ),
                )
                    : Container(
                  color: AppColors.divider,
                  child: const Icon(Icons.hotel, color: AppColors.textHint),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      hotel.name,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(Icons.star, size: 12, color: Colors.amber),
                        const SizedBox(width: 2),
                        Text(hotel.rating.toStringAsFixed(1), style: const TextStyle(fontSize: 11)),
                        const Spacer(),
                        PriceText(
                          sarAmount: hotel.pricePerNight,
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary),
                        ),
                      ],
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