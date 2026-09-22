import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';

import '../../../app.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/widgets/price_text.dart';
import '../../../data/models/hotel_model.dart';
import '../../search/controllers/search_controller.dart';

/// كاش بسيط على مستوى الجلسة (مش persisted): أول وجهة "ناجحة" (رجعت
/// فنادق فعلية، بغض النظر عن نوع العقار) لكل كود دولة. بمجرد ما نلاقي
/// وجهة شغالة لدولة معيّنة، كل الضغطات الجاية على أي زرار (Hotels/
/// Apartments/...) بتستخدمها على طول بطلب واحد بس -- بدل ما تعيد نفس
/// محاولات البحث المتتالية من الصفر وتصطدم بحد HotelBeds Sandbox
/// لعدد الطلبات (rate limit).
final Map<String, ({String code, String name})> _goodDestinationCache = {};

/// مدينة "مركزية" واحدة من كل دولة عندها وجهات HotelBeds متزامنة فعليًا
/// (SA/AE/EG/TR/ES/FR/MY) -- تُستخدم كمرجع لأقرب دولة لموقع الجهاز
/// الفعلي (بالإحداثيات)، وبعدين نجيب وجهة فعلية من نفس الدولة عبر
/// [HotelRepository.getDestinationsByCountry] بدل تخمين اسم مدينة
/// بالظبط (اللي اتضح إنه مش موثوق -- "Paris" نفسها مش موجودة في
/// الوجهات المتزامنة لفرنسا رغم وجود 300 وجهة تانية فيها). قيد حالي
/// مهم: الولايات المتحدة لسه مش متزامنة، فلو المستخدم فيها هيوصله
/// أقرب دولة من القائمة دي (مش بلده الفعلي) لحد ما تتزامن وجهات أمريكية.
const List<({String countryCode, double lat, double lng})> _hubCountries = [
  (countryCode: 'SA', lat: 24.7136, lng: 46.6753), // Riyadh
  (countryCode: 'AE', lat: 25.2048, lng: 55.2708), // Dubai
  (countryCode: 'EG', lat: 30.0444, lng: 31.2357), // Cairo
  (countryCode: 'TR', lat: 41.0082, lng: 28.9784), // Istanbul
  (countryCode: 'ES', lat: 40.4168, lng: -3.7038), // Madrid
  (countryCode: 'FR', lat: 48.8566, lng: 2.3522), // Paris
  (countryCode: 'MY', lat: 3.1390, lng: 101.6869), // Kuala Lumpur
];

double _haversineKm(double lat1, double lng1, double lat2, double lng2) {
  const r = 6371.0;
  final dLat = (lat2 - lat1) * math.pi / 180;
  final dLng = (lng2 - lng1) * math.pi / 180;
  final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
      math.cos(lat1 * math.pi / 180) *
          math.cos(lat2 * math.pi / 180) *
          math.sin(dLng / 2) *
          math.sin(dLng / 2);
  final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
  return r * c;
}

String _nearestHubCountry(double lat, double lng) {
  var best = _hubCountries.first;
  var bestDist = _haversineKm(lat, lng, best.lat, best.lng);
  for (final country in _hubCountries.skip(1)) {
    final dist = _haversineKm(lat, lng, country.lat, country.lng);
    if (dist < bestDist) {
      best = country;
      bestDist = dist;
    }
  }
  return best.countryCode;
}

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
    titleAr: 'فنادق اللحظة الأخيرة بالقرب منك الليلة',
    titleEn: 'Last minute hotels near you tonight',
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
/// (Hotels/Apartments/Villas/Resorts/Chalets): يحدد أقرب مدينة "مركزية"
/// لموقع الجهاز الفعلي (من الدول اللي عندها وجهات HotelBeds متزامنة)،
/// يجيب نتائج بحث حقيقية فيها، يفلترها بنوع العقار المطابق، ويعرض أول
/// 5 كروت. الدوس على أي كارت يودّي مباشرة لتفاصيل الفندق. لو الموقع
/// مش متاح (رفض إذن، أو الخدمة مقفولة) أو مفيش نتائج مطابقة، القسم
/// بيختفي تمامًا بدل ما يعرض حالة فاضية مربكة.
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
    debugPrint('DEBUG AccommodationPreviewSection._load() started for ${widget.selectedType}');
    setState(() {
      _loading = true;
      _hotels = [];
      _resolvedParams = null;
    });

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      debugPrint('DEBUG serviceEnabled: $serviceEnabled');
      if (!serviceEnabled) {
        if (mounted) setState(() => _loading = false);
        return;
      }
      var permission = await Geolocator.checkPermission();
      debugPrint('DEBUG permission (initial): $permission');
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        debugPrint('DEBUG permission (after request): $permission');
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        debugPrint('DEBUG stopping: permission denied');
        if (mounted) setState(() => _loading = false);
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.low,
      );
      debugPrint('DEBUG position: ${position.latitude}, ${position.longitude}');
      final countryCode = _nearestHubCountry(position.latitude, position.longitude);
      debugPrint('DEBUG nearest hub countryCode: $countryCode');

      final repo = ref.read(hotelRepositoryProvider);
      final destResult = await repo.getDestinationsByCountry(countryCode);
      final destinations = <({String name, String code})>[];
      destResult.when(
        success: (list) {
          debugPrint('DEBUG getDestinationsByCountry("$countryCode") success, count: ${list.length}');
          destinations.addAll(list.map((d) => (name: d.name, code: d.code)));
        },
        failure: (err) {
          debugPrint('DEBUG getDestinationsByCountry("$countryCode") FAILURE: $err');
        },
      );

      if (destinations.isEmpty) {
        debugPrint('DEBUG stopping: no destinations found for countryCode="$countryCode"');
        if (mounted) setState(() => _loading = false);
        return;
      }

      final checkIn = DateTime.now().add(const Duration(days: 1));
      final checkOut = DateTime.now().add(const Duration(days: 2));
      final targetKeywords = _propertyTypeKeywords[widget.selectedType] ?? [widget.selectedType.toUpperCase()];

      // لو عندنا وجهة "ناجحة" متخزّنة من قبل لنفس الدولة، بنستخدمها
      // على طول بطلب واحد -- بدل ما نعيد نفس محاولات البحث المتتالية
      // ونصطدم بحد HotelBeds Sandbox لعدد الطلبات (429 Rate limit
      // exceeded، اللي حصل فعليًا لما جربنا 20 وجهة مرة واحدة).
      final cached = _goodDestinationCache[countryCode];
      final List<({String name, String code})> candidates;
      if (cached != null) {
        debugPrint('DEBUG using cached destination for $countryCode: "${cached.name}" (${cached.code})');
        candidates = [(name: cached.name, code: cached.code)];
      } else {
        candidates = destinations.take(3).toList();
      }

      final List<HotelModel> collected = [];
      final Set<String> allSeenPropertyTypes = {};
      var rateLimited = false;
      for (var i = 0; i < candidates.length; i++) {
        if (collected.length >= 5 || rateLimited) break;
        final dest = candidates[i];
        final params = <String, dynamic>{
          'destinationCode': dest.code,
          'cityLabel': dest.name,
          'checkIn': checkIn,
          'checkOut': checkOut,
          'guests': 2,
        };
        debugPrint('DEBUG trying destination "${dest.name}" (${dest.code})...');
        try {
          final result = await ref.read(searchResultsProvider(params).future);
          if (result.isNotEmpty) {
            _goodDestinationCache[countryCode] = (code: dest.code, name: dest.name);
          }
          allSeenPropertyTypes.addAll(result.map((h) => h.propertyType));
          final matching = result.where((h) {
            final upper = h.propertyType.toUpperCase();
            return targetKeywords.any((k) => upper.contains(k));
          });
          debugPrint('DEBUG   -> ${result.length} hotels total, ${matching.length} matching "${widget.selectedType}"');
          collected.addAll(matching);
        } catch (e) {
          debugPrint('DEBUG   -> error: $e');
          if (e.toString().contains('429') || e.toString().toLowerCase().contains('rate limit')) {
            debugPrint('DEBUG rate limit hit -- stopping further attempts for this press');
            rateLimited = true;
            break;
          }
        }
        // تأخير بسيط بين الطلبات المتتالية لتقليل احتمال تجاوز حد
        // HotelBeds Sandbox لعدد الطلبات (مؤثر بس لو فيه أكتر من محاولة).
        if (i < candidates.length - 1) {
          await Future.delayed(const Duration(milliseconds: 700));
        }
      }

      final filtered = collected.take(5).toList();
      debugPrint('DEBUG final collected count: ${filtered.length}');
      if (filtered.isEmpty) {
        debugPrint('DEBUG all propertyTypes seen across attempts: $allSeenPropertyTypes');
      }

      if (filtered.isEmpty) {
        debugPrint('DEBUG stopping: no matching hotels found across ${candidates.length} candidate destinations');
        if (mounted) setState(() => _loading = false);
        return;
      }

      if (mounted) {
        setState(() {
          _resolvedParams = {'checkIn': checkIn, 'checkOut': checkOut, 'guests': 2};
          _hotels = filtered;
          _loading = false;
        });
      }
    } catch (e, st) {
      debugPrint('DEBUG _load() EXCEPTION: $e');
      debugPrint('DEBUG stack: $st');
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