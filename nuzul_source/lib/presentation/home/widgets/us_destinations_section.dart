import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';

class _UsCity {
  final String name;
  final double lat;
  final double lng;
  const _UsCity(this.name, this.lat, this.lng);
}

// قائمة مختصرة بأكبر المدن الأمريكية، تُستخدم للمطابقة مع أقرب مدينة
// لموقع المستخدم الفعلي -- بدل الاعتماد على خدمة reverse-geocoding
// خارجية (تحتاج API key منفصل). دقة كافية لتحديد "أقرب مدينة كبرى"
// حتى لو المستخدم مش واقف فيها بالظبط.
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

class _PopularDestination {
  final String cityEn;
  final String cityAr;
  final String dateLabel;
  final String imageAsset;

  const _PopularDestination({
    required this.cityEn,
    required this.cityAr,
    required this.dateLabel,
    required this.imageAsset,
  });
}

/// وجهات أمريكية شائعة (نفس روح trending_destinations.dart) -- صور
/// محلية من assets/images/destinations/. لو الصورة مش موجودة، الكارت
/// بيعرض أيقونة بديلة بدل ما يفشل (errorBuilder).
const List<_PopularDestination> _usDestinations = [
  _PopularDestination(
    cityEn: 'New York',
    cityAr: 'نيويورك',
    dateLabel: 'Aug 25 - Sep 2',
    imageAsset: 'assets/images/destinations/new_york.jpg',
  ),
  _PopularDestination(
    cityEn: 'Orlando',
    cityAr: 'أورلاندو',
    dateLabel: 'Aug 20 - Aug 27',
    imageAsset: 'assets/images/destinations/orlando.jpg',
  ),
  _PopularDestination(
    cityEn: 'Atlanta',
    cityAr: 'أتلانتا',
    dateLabel: 'Aug 21 - Aug 26',
    imageAsset: 'assets/images/destinations/atlanta.jpg',
  ),
  _PopularDestination(
    cityEn: 'Las Vegas',
    cityAr: 'لاس فيغاس',
    dateLabel: 'Aug 20 - Sep 25',
    imageAsset: 'assets/images/destinations/las_vegas.jpg',
  ),
];

/// وجهات أوروبية شائعة.
const List<_PopularDestination> _europeDestinations = [
  _PopularDestination(
    cityEn: 'Barcelona',
    cityAr: 'برشلونة',
    dateLabel: 'Sep 5 - Sep 12',
    imageAsset: 'assets/images/destinations/barcelona.jpg',
  ),
  _PopularDestination(
    cityEn: 'Rome',
    cityAr: 'روما',
    dateLabel: 'Sep 8 - Sep 15',
    imageAsset: 'assets/images/destinations/rome.jpg',
  ),
  _PopularDestination(
    cityEn: 'Paris',
    cityAr: 'باريس',
    dateLabel: 'Sep 10 - Sep 17',
    imageAsset: 'assets/images/destinations/paris.jpg',
  ),
  _PopularDestination(
    cityEn: 'Athens',
    cityAr: 'أثينا',
    dateLabel: 'Sep 12 - Sep 19',
    imageAsset: 'assets/images/destinations/athens.jpg',
  ),
];

/// وجهات آسيوية شائعة.
const List<_PopularDestination> _asiaDestinations = [
  _PopularDestination(
    cityEn: 'Seoul',
    cityAr: 'سيول',
    dateLabel: 'Oct 3 - Oct 12',
    imageAsset: 'assets/images/destinations/seoul.jpg',
  ),
  _PopularDestination(
    cityEn: 'Bangkok',
    cityAr: 'بانكوك',
    dateLabel: 'Oct 5 - Oct 14',
    imageAsset: 'assets/images/destinations/bangkok.jpg',
  ),
  _PopularDestination(
    cityEn: 'Kuala Lumpur',
    cityAr: 'كوالالمبور',
    dateLabel: 'Oct 6 - Oct 15',
    imageAsset: 'assets/images/destinations/kuala_lumpur.jpg',
  ),
  _PopularDestination(
    cityEn: 'Bali',
    cityAr: 'بالي',
    dateLabel: 'Oct 8 - Oct 18',
    imageAsset: 'assets/images/destinations/bali.jpg',
  ),
];

/// يجيب أقرب مدينة أمريكية كبرى لموقع المستخدم الفعلي (بعد طلب إذن
/// الموقع)، عشان تُستخدم كنقطة مغادرة (origin) في كل صفوف "رحلات من
/// مدينتك". لو المستخدم رفض الإذن، أو خدمة الموقع مقفولة، أو حصل أي
/// خطأ، الدالة بترجّع null -- والواجهة بتخفي القسم بالكامل بدل ما
/// تعرض بيانات تخمينية أو رسالة خطأ مزعجة لمستخدم لسه ما بدأش بحث.
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
    );

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

/// أقسام "رحلات من مدينتك" في شاشة بحث الطيران (قبل ما المستخدم يعمل
/// بحث): ثلاث صفوف متتالية -- وجهات أمريكية، أوروبية، وآسيوية شائعة،
/// كلها بنفس نقطة المغادرة (أقرب مدينة أمريكية كبرى لموقع المستخدم
/// الفعلي). لو تعذر تحديد الموقع، الأقسام التلاتة بتختفي بالكامل من
/// غير أي أثر بصري (مفيش placeholder ولا رسالة خطأ).
class UsDestinationsSection extends StatefulWidget {
  final void Function(String origin, String destination) onDestinationTap;

  const UsDestinationsSection({super.key, required this.onDestinationTap});

  @override
  State<UsDestinationsSection> createState() => _UsDestinationsSectionState();
}

class _UsDestinationsSectionState extends State<UsDestinationsSection> {
  String? _origin;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final city = await _detectNearestUsCity();
    if (!mounted) return;
    setState(() {
      _origin = city;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading || _origin == null) return const SizedBox.shrink();

    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _DestinationsRow(
          title: isArabic ? 'رحلات من $_origin' : 'Flights from $_origin',
          origin: _origin!,
          destinations: _usDestinations,
          isArabic: isArabic,
          onDestinationTap: widget.onDestinationTap,
        ),
        const SizedBox(height: AppSizes.md),
        _DestinationsRow(
          title: isArabic ? 'وجهات أوروبية شائعة' : 'Popular in Europe',
          origin: _origin!,
          destinations: _europeDestinations,
          isArabic: isArabic,
          onDestinationTap: widget.onDestinationTap,
        ),
        const SizedBox(height: AppSizes.md),
        _DestinationsRow(
          title: isArabic ? 'وجهات آسيوية شائعة' : 'Popular in Asia',
          origin: _origin!,
          destinations: _asiaDestinations,
          isArabic: isArabic,
          onDestinationTap: widget.onDestinationTap,
        ),
      ],
    );
  }
}

/// صف واحد قابل لإعادة الاستخدام: عنوان + سكرول أفقي بكروت الوجهات.
class _DestinationsRow extends StatelessWidget {
  final String title;
  final String origin;
  final List<_PopularDestination> destinations;
  final bool isArabic;
  final void Function(String origin, String destination) onDestinationTap;

  const _DestinationsRow({
    required this.title,
    required this.origin,
    required this.destinations,
    required this.isArabic,
    required this.onDestinationTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          const SizedBox(height: AppSizes.sm),
          SizedBox(
            height: 200,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: destinations.length,
              separatorBuilder: (_, __) => const SizedBox(width: AppSizes.sm),
              itemBuilder: (context, index) {
                final dest = destinations[index];
                return _DestinationCard(
                  origin: origin,
                  destination: dest,
                  isArabic: isArabic,
                  onTap: () => onDestinationTap(origin, dest.cityEn),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// نفس الأسلوب البصري المستخدم في trending_destinations.dart بالظبط:
/// صورة كاملة + تظليل تدريجي أسفلها لوضوح النص الأبيض فوقها. الفرق
/// هنا إن العنوان الرئيسي هو مسار الرحلة (من → إلى) بدل اسم مدينة
/// واحدة، وتحته سطر أصغر للتاريخ ونوع الرحلة (ذهاب وعودة).
class _DestinationCard extends StatelessWidget {
  final String origin;
  final _PopularDestination destination;
  final bool isArabic;
  final VoidCallback onTap;

  const _DestinationCard({
    required this.origin,
    required this.destination,
    required this.isArabic,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final title =
        '$origin ${isArabic ? "إلى" : "to"} ${isArabic ? destination.cityAr : destination.cityEn}';

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppSizes.radiusSm),
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          width: 220,
          height: 200,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Container(color: Colors.grey.shade200),
              Image.asset(
                destination.imageAsset,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: Colors.grey.shade300,
                  child: const Icon(Icons.flight, size: 32, color: AppColors.textHint),
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
                right: 12,
                bottom: 10,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${destination.dateLabel} · ${isArabic ? "ذهاب وعودة" : "Round-trip"}',
                      style: const TextStyle(color: Colors.white70, fontSize: 11),
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