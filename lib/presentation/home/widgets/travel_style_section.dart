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

/// وجهة واحدة داخل قسم "أنماط السفر" -- اسم المدينة (للبحث والعرض)،
/// اسم الدولة/المنطقة (للعرض تحت الكارت بس)، وصورة مخصصة.
class _StyleDestination {
  final String city;
  final String country;
  final String imageAsset;
  const _StyleDestination({required this.city, required this.country, required this.imageAsset});
}

/// أنماط السفر وقوائم مدنها. أسماء المدن هنا هي اللي بتتبعت فعليًا
/// للبحث (onSelected) -- لو مدينة معيّنة مش موجودة في
/// hotelbeds_destinations، البحث هيرجع فاضي (نفس القيد اللي
/// شخّصناه مع "وجهات رائجة").
const Map<String, List<_StyleDestination>> _travelStyles = {
  'honeymoon': [
    _StyleDestination(city: 'Venice', country: 'Italy', imageAsset: 'assets/images/styles/venice.jpg'),
    _StyleDestination(city: 'Maldives', country: 'Maldives', imageAsset: 'assets/images/styles/maldives.jpg'),
    _StyleDestination(city: 'Bahamas', country: 'Bahamas', imageAsset: 'assets/images/styles/bahamas_honeymoon.jpg'),
    _StyleDestination(city: 'Bora Bora', country: 'French Polynesia', imageAsset: 'assets/images/styles/bora_bora.jpg'),
    _StyleDestination(city: 'Phuket', country: 'Thailand', imageAsset: 'assets/images/styles/phuket.jpg'),
    _StyleDestination(city: 'Cancun', country: 'Mexico', imageAsset: 'assets/images/styles/cancun_honeymoon.jpg'),
    _StyleDestination(city: 'Bali', country: 'Indonesia', imageAsset: 'assets/images/styles/bali.jpg'),
  ],
  'beach': [
    _StyleDestination(city: 'Hawaii', country: 'USA', imageAsset: 'assets/images/styles/hawaii.jpg'),
    _StyleDestination(city: 'Palma de Mallorca', country: 'Spain', imageAsset: 'assets/images/styles/palma.jpg'),
    _StyleDestination(city: 'Nice', country: 'France', imageAsset: 'assets/images/styles/nice.jpg'),
    _StyleDestination(city: 'Cancun', country: 'Mexico', imageAsset: 'assets/images/styles/cancun.jpg'),
    _StyleDestination(city: 'Lisbon', country: 'Portugal', imageAsset: 'assets/images/styles/lisbon_beach.jpg'),
    _StyleDestination(city: 'Bahamas', country: 'Bahamas', imageAsset: 'assets/images/styles/bahamas.jpg'),
    _StyleDestination(city: 'Antalya', country: 'Turkey', imageAsset: 'assets/images/styles/antalya.jpg'),
    _StyleDestination(city: 'Condado', country: 'Puerto Rico', imageAsset: 'assets/images/styles/condado.jpg'),
  ],
  'culture': [
    _StyleDestination(city: 'Athens', country: 'Greece', imageAsset: 'assets/images/styles/athens.jpg'),
    _StyleDestination(city: 'Istanbul', country: 'Turkey', imageAsset: 'assets/images/styles/istanbul.jpg'),
    _StyleDestination(city: 'Cairo', country: 'Egypt', imageAsset: 'assets/images/styles/cairo.jpg'),
    _StyleDestination(city: 'Marrakech', country: 'Morocco', imageAsset: 'assets/images/styles/marrakech.jpg'),
    _StyleDestination(city: 'Kyoto', country: 'Japan', imageAsset: 'assets/images/styles/kyoto.jpg'),
    _StyleDestination(city: 'Rome', country: 'Italy', imageAsset: 'assets/images/styles/rome.jpg'),
    _StyleDestination(city: 'Beijing', country: 'China', imageAsset: 'assets/images/styles/beijing.jpg'),
    _StyleDestination(city: 'Tokyo', country: 'Japan', imageAsset: 'assets/images/styles/tokyo.jpg'),
    _StyleDestination(city: 'Agra', country: 'India', imageAsset: 'assets/images/styles/agra.jpg'),
  ],
  'ski': [
    _StyleDestination(city: 'St. Moritz', country: 'Switzerland', imageAsset: 'assets/images/styles/st_moritz.jpg'),
    _StyleDestination(city: 'Whistler', country: 'Canada', imageAsset: 'assets/images/styles/whistler.jpg'),
    _StyleDestination(city: 'Niseko', country: 'Japan', imageAsset: 'assets/images/styles/niseko.jpg'),
    _StyleDestination(city: 'Vail', country: 'USA', imageAsset: 'assets/images/styles/vail.jpg'),
    _StyleDestination(city: 'Aspen', country: 'USA', imageAsset: 'assets/images/styles/aspen.jpg'),
    _StyleDestination(city: 'Chamonix', country: 'France', imageAsset: 'assets/images/styles/chamonix.jpg'),
    _StyleDestination(city: 'Coronet Peak', country: 'New Zealand', imageAsset: 'assets/images/styles/coronet.jpg'),
    _StyleDestination(city: 'Kitzbühel', country: 'Austria', imageAsset: 'assets/images/styles/kitzski.jpg'),
    _StyleDestination(city: 'Dolomiti', country: 'Italy', imageAsset: 'assets/images/styles/dolomiti.jpg'),
  ],
  'family': [
    _StyleDestination(city: 'Orlando', country: 'USA', imageAsset: 'assets/images/styles/orlando.jpg'),
    _StyleDestination(city: 'Paris', country: 'France', imageAsset: 'assets/images/styles/paris.jpg'),
    _StyleDestination(city: 'Sydney', country: 'Australia', imageAsset: 'assets/images/styles/sydney.jpg'),
    _StyleDestination(city: 'Lisbon', country: 'Portugal', imageAsset: 'assets/images/styles/lisbon_family.jpg'),
    _StyleDestination(city: 'Barcelona', country: 'Spain', imageAsset: 'assets/images/styles/barcelona.jpg'),
    _StyleDestination(city: 'Los Angeles', country: 'USA', imageAsset: 'assets/images/styles/los_angeles.jpg'),
    _StyleDestination(city: 'London', country: 'UK', imageAsset: 'assets/images/styles/london.jpg'),
    _StyleDestination(city: 'Amsterdam', country: 'Netherlands', imageAsset: 'assets/images/styles/amsterdam.jpg'),
  ],
};

/// لون مميز لكل تبويب -- بيتستخدم كخلفية شفافة (opacity منخفضة) لما
/// التبويب مش مفعّل، وبنفس اللون بشفافية أعلى شوية + نص بنفس اللون
/// لما يبقى مفعّل، بدل الخط السفلي البسيط اللي كان موجود قبل كده.
const Map<String, Color> _styleColors = {
  'honeymoon': Color(0xFFE91E63), // وردي
  'beach': Color(0xFF00ACC1), // سماوي/فيروزي
  'culture': Color(0xFFFB8C00), // برتقالي
  'ski': Color(0xFF3F51B5), // أزرق بنفسجي
  'family': Color(0xFF43A047), // أخضر
};

/// قسم "أنماط سفر لكل الأذواق" -- تبويبات (شهر عسل/شاطئ/ثقافة/تزلج/
/// عائلي) داخل حاوية واحدة بألوان شفافة مميزة لكل تبويب، وكل تبويب
/// بيعرض صف أفقي من كارتات المدن. الدوس على أي كارت بيستدعي
/// onSelected بنفس اسم المدينة، اللي بيشغّل نفس آلية البحث المستخدمة
/// في "وجهات رائجة" (من غير أي تكرار منطق هنا).
class TravelStyleSection extends StatefulWidget {
  final void Function(String city) onSelected;

  const TravelStyleSection({super.key, required this.onSelected});

  @override
  State<TravelStyleSection> createState() => _TravelStyleSectionState();
}

class _TravelStyleSectionState extends State<TravelStyleSection> {
  String _activeStyle = 'honeymoon';

  String _styleLabel(BuildContext context, String key) {
    switch (key) {
      case 'honeymoon':
        return _t3(context, ar: 'شهر العسل', en: 'Honeymoon', es: 'Luna de miel', tr: 'Balayı', id: 'Bulan madu',
            hi: 'हनीमून', ur: 'ہنی مون', fr: 'Lune de miel', bn: 'হানিমুন');
      case 'beach':
        return _t3(context, ar: 'شاطئ', en: 'Beach', es: 'Playa', tr: 'Plaj', id: 'Pantai',
            hi: 'समुद्र तट', ur: 'ساحل سمندر', fr: 'Plage', bn: 'সৈকত');
      case 'culture':
        return _t3(context, ar: 'ثقافة', en: 'Culture', es: 'Cultura', tr: 'Kültür', id: 'Budaya',
            hi: 'संस्कृति', ur: 'ثقافت', fr: 'Culture', bn: 'সংস্কৃতি');
      case 'ski':
        return _t3(context, ar: 'تزلج', en: 'Ski', es: 'Esquí', tr: 'Kayak', id: 'Ski',
            hi: 'स्कीइंग', ur: 'سکینگ', fr: 'Ski', bn: 'স্কি');
      case 'family':
        return _t3(context, ar: 'عائلي', en: 'Family', es: 'Familia', tr: 'Aile', id: 'Keluarga',
            hi: 'परिवार', ur: 'خاندان', fr: 'Famille', bn: 'পরিবার');
      default:
        return key;
    }
  }

  @override
  Widget build(BuildContext context) {
    final destinations = _travelStyles[_activeStyle] ?? const [];

    return Padding(
      padding: const EdgeInsets.only(top: AppSizes.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _t3(context, ar: 'إقامات تناسب كل أسلوب سفر', en: 'Stays for every travel style', es: 'Alojamientos para cada estilo de viaje', tr: 'Her seyahat tarzına uygun konaklama', id: 'Menginap untuk setiap gaya perjalanan',
                hi: 'हर यात्रा शैली के लिए ठहरने की जगहें',
                ur: 'ہر سفری انداز کے لیے قیام',
                fr: 'Des séjours pour tous les styles de voyage',
                bn: 'প্রতিটি ভ্রমণ শৈলীর জন্য থাকার ব্যবস্থা'),
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          const SizedBox(height: 4),
          Text(
            _t3(context, ar: 'أسعار متوسطة بناءً على الشهر الحالي', en: 'Average prices based on current calendar month', es: 'Precios promedio del mes actual', tr: 'Mevcut takvim ayına göre ortalama fiyatlar', id: 'Harga rata-rata berdasarkan bulan kalender saat ini',
                hi: 'वर्तमान कैलेंडर माह के आधार पर औसत मूल्य',
                ur: 'موجودہ کیلنڈر مہینے کی بنیاد پر اوسط قیمتیں',
                fr: 'Prix moyens basés sur le mois calendaire en cours',
                bn: 'বর্তমান ক্যালেন্ডার মাসের ভিত্তিতে গড় মূল্য'),
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: AppSizes.md),
          // كل التبويبات داخل حاوية واحدة (Container) بخلفية فاتحة،
          // وكل تبويب بيبقى Pill بلون شفاف مميز خاص بيه بدل الخط
          // السفلي البسيط.
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(16),
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _travelStyles.keys.map((key) {
                  final isActive = key == _activeStyle;
                  final color = _styleColors[key] ?? AppColors.primary;
                  return Padding(
                    padding: const EdgeInsetsDirectional.only(end: 8),
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => setState(() => _activeStyle = key),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: isActive ? color.withOpacity(0.18) : color.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isActive ? color : Colors.transparent,
                            width: 1.5,
                          ),
                        ),
                        child: Text(
                          _styleLabel(context, key),
                          style: TextStyle(
                            fontWeight: isActive ? FontWeight.bold : FontWeight.w600,
                            fontSize: 14,
                            color: isActive ? color : Colors.black87,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: AppSizes.md),
          SizedBox(
            height: 230,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: destinations.length,
              separatorBuilder: (_, __) => const SizedBox(width: AppSizes.sm),
              itemBuilder: (context, index) {
                final destination = destinations[index];
                return _StyleDestinationCard(
                  destination: destination,
                  onTap: () => widget.onSelected(destination.city),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _StyleDestinationCard extends StatelessWidget {
  final _StyleDestination destination;
  final VoidCallback onTap;

  const _StyleDestinationCard({required this.destination, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        width: 170,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.asset(
                  destination.imageAsset,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  filterQuality: FilterQuality.high,
                  errorBuilder: (_, __, ___) => Container(
                    color: Colors.grey.shade200,
                    child: const Icon(Icons.image_outlined, color: AppColors.textHint, size: 32),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              destination.city,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              destination.country,
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}