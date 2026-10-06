import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/widgets/price_text.dart';

class _UsCity {
  final String name;
  final double lat;
  final double lng;
  const _UsCity(this.name, this.lat, this.lng);
}

// نفس قائمة المدن الأمريكية الكبرى المستخدمة في us_destinations_section.dart
// -- مكررة هنا عمدًا (بدل ما نستورد ملف تاني ونربط الاعتمادية بينهم)
// عشان القسمين يفضلوا مستقلين تمامًا عن بعض.
const List<_UsCity> _usCities = [
  _UsCity('New York', 40.7128, -74.0060),
  _UsCity('Los Angeles', 34.0522, -118.2437),
  _UsCity('Chicago', 41.8781, -87.6298),
  _UsCity('Detroit', 42.3314, -83.0458),
  _UsCity('Dallas', 32.7767, -96.7970),
  _UsCity('Atlanta', 33.7490, -84.3880),
  _UsCity('Miami', 25.7617, -80.1918),
  _UsCity('Houston', 29.7604, -95.3698),
  _UsCity('Phoenix', 33.4484, -112.0740),
  _UsCity('Seattle', 47.6062, -122.3321),
  _UsCity('Denver', 39.7392, -104.9903),
  _UsCity('Boston', 42.3601, -71.0589),
  _UsCity('San Francisco', 37.7749, -122.4194),
  _UsCity('Washington', 38.9072, -77.0369),
  _UsCity('Philadelphia', 39.9526, -75.1652),
  _UsCity('Orlando', 28.5383, -81.3792),
  _UsCity('Las Vegas', 36.1699, -115.1398),
];

const String _defaultOriginCity = 'Detroit';

Future<String?> _detectNearestUsCity() async {
  try {
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return null;
    }
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return null;

    final position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.low,
    ).timeout(const Duration(seconds: 5));

    _UsCity? nearest;
    double bestDistance = double.infinity;
    for (final city in _usCities) {
      final distance = Geolocator.distanceBetween(
        position.latitude,
        position.longitude,
        city.lat,
        city.lng,
      );
      if (distance < bestDistance) {
        bestDistance = distance;
        nearest = city;
      }
    }
    return nearest?.name;
  } catch (_) {
    return null;
  }
}

/// عرض طيران + فندق واحد. القيم هنا بيانات نموذجية (sample) لحد ما
/// يتوفر API حقيقي بيحسب باقة طيران+فندق مدمجة فعليًا؛ الأسعار
/// بالريال السعودي (SAR) نفس باقي التطبيق، وبتتحول تلقائيًا للعملة
/// المختارة عبر PriceText.
class FlightHotelDeal {
  final String destinationCity;
  final String destinationCountry;
  final String dateLabel;
  final String hotelName;
  final int hotelStars;
  final int discountPercent;
  final double originalPriceSar;
  final double finalPriceSar;
  final String imageAsset;

  const FlightHotelDeal({
    required this.destinationCity,
    required this.destinationCountry,
    required this.dateLabel,
    required this.hotelName,
    required this.hotelStars,
    required this.discountPercent,
    required this.originalPriceSar,
    required this.finalPriceSar,
    required this.imageAsset,
  });
}

// TODO: البيانات دي نموذجية (sample) -- استبدلها بأسعار حقيقية أول ما
// يتوفر عندنا API بيحسب باقة طيران+فندق مدمجة فعليًا (بدل ما نعرض
// نتائج الفندق بس زي الوضع الحالي في تبويب Flight+Hotel).
const List<FlightHotelDeal> _sampleDeals = [
  FlightHotelDeal(
    destinationCity: 'New York',
    destinationCountry: 'USA',
    dateLabel: 'Sep 5 - Sep 11',
    hotelName: 'The Manhattan Club',
    hotelStars: 4,
    discountPercent: 29,
    originalPriceSar: 3180,
    finalPriceSar: 2258,
    imageAsset: 'assets/images/deals/new_york.jpg',
  ),
  FlightHotelDeal(
    destinationCity: 'Boston',
    destinationCountry: 'USA',
    dateLabel: 'Sep 6 - Sep 12',
    hotelName: 'Boston Harbor Hotel',
    hotelStars: 5,
    discountPercent: 24,
    originalPriceSar: 3960,
    finalPriceSar: 3010,
    imageAsset: 'assets/images/deals/boston.jpg',
  ),
  FlightHotelDeal(
    destinationCity: 'Los Angeles',
    destinationCountry: 'USA',
    dateLabel: 'Sep 5 - Sep 11',
    hotelName: 'Kimpton Everly Hotel',
    hotelStars: 4,
    discountPercent: 31,
    originalPriceSar: 2870,
    finalPriceSar: 1980,
    imageAsset: 'assets/images/deals/los_angeles.jpg',
  ),
  FlightHotelDeal(
    destinationCity: 'Dallas',
    destinationCountry: 'USA',
    dateLabel: 'Sep 6 - Sep 12',
    hotelName: 'The Adolphus',
    hotelStars: 4,
    discountPercent: 27,
    originalPriceSar: 2340,
    finalPriceSar: 1708,
    imageAsset: 'assets/images/deals/dallas.jpg',
  ),
  FlightHotelDeal(
    destinationCity: 'Chicago',
    destinationCountry: 'USA',
    dateLabel: 'Sep 5 - Sep 11',
    hotelName: 'The Langham Chicago',
    hotelStars: 5,
    discountPercent: 22,
    originalPriceSar: 3420,
    finalPriceSar: 2668,
    imageAsset: 'assets/images/deals/chicago.jpg',
  ),
];

/// قسم "عروض اليوم" (Daily deals) لتبويب Flight+Hotel -- كل كارت
/// بيمثّل باقة طيران+فندق من أقرب مدينة أمريكية كبرى لموقع المستخدم
/// (بنفس منطق UsDestinationsSection: بيعرض مدينة افتراضية فورًا،
/// وبيتحدّث لو تحديد الموقع نجح خلال 5 ثوانٍ) لوجهة من الخمس وجهات
/// الثابتة. مؤقّت العد التنازلي بيرجع لمنتصف الليل المحلي كل يوم.
class FlightHotelDealsSection extends StatefulWidget {
  final void Function(String originCity, FlightHotelDeal deal) onDealSelected;

  const FlightHotelDealsSection({super.key, required this.onDealSelected});

  @override
  State<FlightHotelDealsSection> createState() => _FlightHotelDealsSectionState();
}

class _FlightHotelDealsSectionState extends State<FlightHotelDealsSection> {
  String _origin = _defaultOriginCity;
  late Timer _countdownTimer;
  Duration _timeLeft = Duration.zero;

  @override
  void initState() {
    super.initState();
    _loadOrigin();
    _updateCountdown();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) => _updateCountdown());
  }

  Future<void> _loadOrigin() async {
    final city = await _detectNearestUsCity();
    if (!mounted) return;
    if (city != null && city != _origin) {
      setState(() => _origin = city);
    }
  }

  void _updateCountdown() {
    final now = DateTime.now();
    final nextMidnight = DateTime(now.year, now.month, now.day + 1);
    if (!mounted) return;
    setState(() => _timeLeft = nextMidnight.difference(now));
  }

  @override
  void dispose() {
    _countdownTimer.cancel();
    super.dispose();
  }

  String _twoDigits(int n) => n.toString().padLeft(2, '0');

  @override
  Widget build(BuildContext context) {
    final h = _twoDigits(_timeLeft.inHours);
    final m = _twoDigits(_timeLeft.inMinutes.remainder(60));
    final s = _twoDigits(_timeLeft.inSeconds.remainder(60));

    return Padding(
      padding: const EdgeInsets.only(top: AppSizes.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Daily deals',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              const SizedBox(width: AppSizes.sm),
              _CountdownChip(value: h),
              const SizedBox(width: 4),
              const Text(':', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(width: 4),
              _CountdownChip(value: m),
              const SizedBox(width: 4),
              const Text(':', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(width: 4),
              _CountdownChip(value: s),
            ],
          ),
          const SizedBox(height: AppSizes.md),
          SizedBox(
            height: 250,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _sampleDeals.length,
              separatorBuilder: (_, __) => const SizedBox(width: AppSizes.sm),
              itemBuilder: (context, index) {
                final deal = _sampleDeals[index];
                return _DealCard(
                  origin: _origin,
                  deal: deal,
                  onTap: () => widget.onDealSelected(_origin, deal),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _CountdownChip extends StatelessWidget {
  final String value;
  const _CountdownChip({required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFE91E63),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        value,
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
      ),
    );
  }
}

class _DealCard extends StatelessWidget {
  final String origin;
  final FlightHotelDeal deal;
  final VoidCallback onTap;

  const _DealCard({required this.origin, required this.deal, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 230,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.divider),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 110,
              width: double.infinity,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(
                    deal.imageAsset,
                    fit: BoxFit.cover,
                    filterQuality: FilterQuality.high,
                    errorBuilder: (_, __, ___) => Container(
                      color: Colors.grey.shade200,
                      child: const Icon(Icons.image_outlined, color: AppColors.textHint, size: 32),
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE91E63),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${deal.discountPercent}% OFF',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$origin ⇌ ${deal.destinationCity}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    deal.dateLabel,
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          deal.hotelName,
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Row(
                        children: List.generate(
                          deal.hotelStars,
                              (_) => const Icon(Icons.star, size: 11, color: Colors.amber),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        deal.originalPriceSar.toStringAsFixed(0),
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                          decoration: TextDecoration.lineThrough,
                        ),
                      ),
                      const SizedBox(width: 6),
                      PriceText(
                        sarAmount: deal.finalPriceSar,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                  const Text(
                    'Per person',
                    style: TextStyle(fontSize: 10, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}