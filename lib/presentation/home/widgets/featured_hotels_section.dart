import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/widgets/rating_badge.dart';
import '../../../core/widgets/price_text.dart';
import '../../../data/models/hotel_model.dart';
import '../../../data/repositories/hotel_repository.dart';
import '../../../localization/app_localizations.dart';

final _featuredHotelsProvider = FutureProvider((ref) {
  return HotelRepository().getFeaturedHotels();
});

/// قسم "الفنادق المميزة" — يعرض أفضل الفنادق تقييمًا من قاعدة البيانات
/// الفعلية، ويظهر في الصفحة الرئيسية قبل تنفيذ أي بحث.
class FeaturedHotelsSection extends ConsumerWidget {
  const FeaturedHotelsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final resultAsync = ref.watch(_featuredHotelsProvider);

    return resultAsync.when(
      loading: () => const SizedBox(
        height: 180,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (_, __) => const SizedBox.shrink(),
      data: (result) {
        return result.when(
          success: (hotels) {
            if (hotels.isEmpty) return const SizedBox.shrink();
            return _FeaturedHotelsList(hotels: hotels, isArabic: isArabic);
          },
          // فشل الجلب: لا نعرض القسم بدل ما نظهر رسالة خطأ في صفحة ترحيبية
          failure: (_) => const SizedBox.shrink(),
        );
      },
    );
  }
}

class _FeaturedHotelsList extends StatelessWidget {
  final List<HotelModel> hotels;
  final bool isArabic;

  const _FeaturedHotelsList({required this.hotels, required this.isArabic});

  void _openHotelDetails(BuildContext context, HotelModel hotel) {
    final now = DateTime.now();
    context.push(
      AppRoutes.hotelDetails,
      extra: {
        'hotel': hotel,
        'checkIn': now.add(const Duration(days: 1)),
        'checkOut': now.add(const Duration(days: 3)),
        'guests': 2,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSizes.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSizes.md),
            child: Text(
              isArabic ? 'الفنادق المميزة' : 'Featured Hotels',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ),
          const SizedBox(height: AppSizes.sm),
          SizedBox(
            height: 220,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: AppSizes.md),
              itemCount: hotels.length,
              separatorBuilder: (_, __) => const SizedBox(width: AppSizes.sm),
              itemBuilder: (context, index) {
                final hotel = hotels[index];
                return InkWell(
                  onTap: () => _openHotelDetails(context, hotel),
                  borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                  child: Container(
                    width: 190,
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.divider),
                      borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                          child: Container(
                            height: 110,
                            width: double.infinity,
                            color: AppColors.divider,
                            child: hotel.images.isNotEmpty
                                ? Image.network(
                              hotel.images.first,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) =>
                              const Icon(Icons.hotel, color: AppColors.textHint),
                            )
                                : const Icon(Icons.hotel, color: AppColors.textHint),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(AppSizes.sm),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                hotel.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                hotel.city,
                                style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                              ),
                              const SizedBox(height: 4),
                              RatingBadge(rating: hotel.rating, reviewCount: hotel.reviewCount),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  PriceText(
                                    sarAmount: hotel.pricePerNight,
                                    style: const TextStyle(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 12,
                                    ),
                                  ),
                                  Text(
                                    ' ${l10n.perNight}',
                                    style: const TextStyle(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ],
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