import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/widgets/price_text.dart';
import '../../../data/models/hotel_model.dart';
import '../../../data/repositories/hotel_repository.dart';
import '../../search/controllers/search_controller.dart';

/// مدن ثابتة معروفة بيتم تجربتها بالترتيب لحد ما نلاقي كفاية فنادق
/// تطابق نوع العقار المطلوب. بديل مباشر وأسرع عن الاعتماد على الموقع
/// الجغرافي وقايمة دول محدودة (اللي كان بيرجع نتايج عشوائية وغير ذات
/// صلة، زي وجهة ريفية بفندق واحد بس). القائمة دي متنوعة جغرافيًا عن
/// قصد (أمريكا/خليج/أوروبا) عشان تزيد فرصة إيجاد نتايج مهما كانت حالة
/// مزامنة hotelbeds_destinations وقتها.
const List<String> _candidateCities = [
  'New York',
  'Dubai',
  'Riyadh',
  'Miami',
  'Cairo',
  'Istanbul',
  'Paris',
  'Barcelona',
  'Chicago',
  'Los Angeles',
];

/// كلمات مفتاحية تُستخدم للمطابقة المرنة (contains، مش == حرفي) مع
/// propertyType الحقيقي القادم من HotelBeds -- اللي اتضح إنه تفصيلي
/// جدًا وبيختلف باختلاف الوجهة (زي "RURAL HOTEL 2*"، "CITY HOTEL 4*"،
/// "APARTMENTS")، مش تصنيف بسيط ثابت زي "Hotels"/"Apartments". المطابقة
/// الحرفية الكاملة كانت بترجع صفر نتائج دايمًا تقريبًا لنفس السبب ده.
const Map<String, List<String>> _propertyTypeKeywords = {
  'Hotels': ['HOTEL', 'HOSTAL', 'MOTEL', 'RESORT'],
  'Apartments': ['APART', 'CONDO'],
  'Villas': ['VILLA', 'HOUSE', 'HOME', 'CHALET'],
  'Resorts': ['HOTEL', 'RESORT'],
  'Chalets': ['CHALET', 'VILLA', 'HOUSE', 'HOME'],
};

class _ButtonCopy {
  final String titleAr;
  final String titleEn;
  final String? subtitleAr;
  final String? subtitleEn;
  const _ButtonCopy({
    required this.titleAr,
    required this.titleEn,
    this.subtitleAr,
    this.subtitleEn,
  });
}

/// نص العنوان والوصف لكل نوع زرار، بعربي/إنجليزي.
const Map<String, _ButtonCopy> _copyForButton = {
  'Hotels': _ButtonCopy(
    titleAr: 'فنادق مميزة',
    titleEn: 'Featured hotels',
  ),
  'Apartments': _ButtonCopy(
    titleAr: 'وجهات شقق مميزة',
    titleEn: 'Featured apartment destinations',
    subtitleAr: 'اكتشف أشهر الوجهات للإقامة في شقق',
    subtitleEn: 'Check out these popular destinations for apartments',
  ),
  'Villas': _ButtonCopy(
    titleAr: 'وجهات فلل مميزة',
    titleEn: 'Featured villa destinations',
    subtitleAr: 'اكتشف أشهر الوجهات للإقامة في فلل',
    subtitleEn: 'Check out these popular destinations for villas',
  ),
  'Resorts': _ButtonCopy(
    titleAr: 'وجهات منتجعات مميزة',
    titleEn: 'Featured resort destinations',
    subtitleAr: 'اكتشف أشهر الوجهات للإقامة في منتجعات',
    subtitleEn: 'Check out these popular destinations for resorts',
  ),
  'Chalets': _ButtonCopy(
    titleAr: 'وجهات شاليهات مميزة',
    titleEn: 'Featured chalet destinations',
    subtitleAr: 'اكتشف أشهر الوجهات للإقامة في شاليهات',
    subtitleEn: 'Check out these popular destinations for chalets',
  ),
};

/// يظهر تحت قسم "أنواع الإقامة الشائعة" لما المستخدم يدوس على نوع
/// (Hotels/Apartments/Villas/Resorts/Chalets): يجرّب قايمة مدن ثابتة
/// معروفة بالترتيب، يجيب نتائج بحث حقيقية فيها، يفلترها بنوع العقار
/// المطابق، ويعرض أول 5 كروت. الدوس على أي كارت يودّي مباشرة لتفاصيل
/// الفندق. لو مفيش نتائج مطابقة في أي مدينة، القسم بيختفي تمامًا بدل
/// ما يعرض حالة فاضية مربكة.
class AccommodationPreviewSection extends ConsumerStatefulWidget {
  final String selectedType;
  const AccommodationPreviewSection({super.key, required this.selectedType});

  @override
  ConsumerState<AccommodationPreviewSection> createState() =>
      _AccommodationPreviewSectionState();
}

class _AccommodationPreviewSectionState extends ConsumerState<AccommodationPreviewSection> {
  bool _loading = true;
  List<HotelModel> _hotels = [];
  Map<String, dynamic>? _resolvedParams;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant AccommodationPreviewSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedType != widget.selectedType) {
      _load();
    }
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _hotels = [];
      _resolvedParams = null;
    });

    try {
      final repo = ref.read(hotelRepositoryProvider);
      final checkIn = DateTime.now().add(const Duration(days: 1));
      final checkOut = DateTime.now().add(const Duration(days: 2));
      final targetKeywords = _propertyTypeKeywords[widget.selectedType] ?? [widget.selectedType.toUpperCase()];

      final List<HotelModel> collected = [];
      var rateLimited = false;

      for (var i = 0; i < _candidateCities.length; i++) {
        if (collected.length >= 5 || rateLimited) break;
        final cityName = _candidateCities[i];

        final destResult = await repo.searchDestinations(cityName);
        final match = destResult.when(
          success: (list) => list.isNotEmpty ? list.first : null,
          failure: (_) => null,
        );
        if (match == null) continue;

        final params = <String, dynamic>{
          'destinationCode': match.code,
          'cityLabel': match.name,
          'checkIn': checkIn,
          'checkOut': checkOut,
          'guests': 2,
        };

        try {
          final result = await ref.read(searchResultsProvider(params).future);
          final matching = result.where((h) {
            final upper = h.propertyType.toUpperCase();
            return targetKeywords.any((k) => upper.contains(k));
          });
          collected.addAll(matching);
          if (collected.isNotEmpty && _resolvedParams == null) {
            _resolvedParams = {'checkIn': checkIn, 'checkOut': checkOut, 'guests': 2};
          }
        } catch (e) {
          if (e.toString().contains('429') || e.toString().toLowerCase().contains('rate limit')) {
            rateLimited = true;
            break;
          }
        }

        if (i < _candidateCities.length - 1) {
          await Future.delayed(const Duration(milliseconds: 400));
        }
      }

      final filtered = collected.take(5).toList();

      if (mounted) {
        setState(() {
          _hotels = filtered;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _openHotelDetails(HotelModel hotel) {
    if (_resolvedParams == null) return;
    context.push(
      AppRoutes.hotelDetails,
      extra: {
        'hotel': hotel,
        'checkIn': _resolvedParams!['checkIn'],
        'checkOut': _resolvedParams!['checkOut'],
        'guests': _resolvedParams!['guests'],
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: AppSizes.lg),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (_hotels.isEmpty) {
      return const SizedBox.shrink();
    }

    final copy = _copyForButton[widget.selectedType];
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final title = copy != null ? (isArabic ? copy.titleAr : copy.titleEn) : widget.selectedType;
    final subtitle = copy == null
        ? null
        : (isArabic ? copy.subtitleAr : copy.subtitleEn);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSizes.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSizes.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: AppSizes.sm),
          SizedBox(
            height: 180,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: AppSizes.md),
              itemCount: _hotels.length,
              separatorBuilder: (_, __) => const SizedBox(width: AppSizes.sm),
              itemBuilder: (context, index) {
                final hotel = _hotels[index];
                return GestureDetector(
                  onTap: () => _openHotelDetails(hotel),
                  child: Container(
                    width: 150,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                      border: Border.all(color: AppColors.divider),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          height: 100,
                          width: double.infinity,
                          child: Container(
                            color: AppColors.divider,
                            alignment: Alignment.center,
                            child: hotel.images.isNotEmpty
                                ? Image.network(
                              hotel.images.first,
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: 100,
                              filterQuality: FilterQuality.high,
                              errorBuilder: (_, __, ___) =>
                              const Icon(Icons.hotel, size: 30, color: AppColors.textHint),
                            )
                                : const Icon(Icons.hotel, size: 30, color: AppColors.textHint),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(6),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                hotel.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                hotel.city,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                              ),
                              const SizedBox(height: 2),
                              PriceText(
                                sarAmount: hotel.pricePerNight,
                                style: const TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
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