/// بيانات ثابتة لقسم "استكشف حسب الدولة" — 6 دول، كل واحدة بقائمة
/// مدنها/مناطقها الرئيسية بالترتيب اللي هيظهروا بيه، وصورة تمثيلية
/// (asset محلي) بدل علم الدولة.
class CountryGuide {
  final String imageAsset;
  final String nameAr;
  final String nameEn;
  final List<String> cities;

  const CountryGuide({
    required this.imageAsset,
    required this.nameAr,
    required this.nameEn,
    required this.cities,
  });
}

const List<CountryGuide> countryGuides = [
  CountryGuide(
    imageAsset: 'assets/images/countries/turkey.jpg',
    nameAr: 'تركيا',
    nameEn: 'Turkey',
    cities: ['Istanbul', 'Cappadocia', 'Antalya', 'Izmir', 'Bodrum', 'Trabzon'],
  ),
  CountryGuide(
    imageAsset: 'assets/images/countries/singapore.jpg',
    nameAr: 'سنغافورة',
    nameEn: 'Singapore',
    cities: ['Marina Bay', 'Sentosa', 'Chinatown', 'Kampong Glam', 'Little India', 'Orchard Road'],
  ),
  CountryGuide(
    imageAsset: 'assets/images/countries/united_states.jpg',
    nameAr: 'أمريكا',
    nameEn: 'United States',
    cities: ['New York', 'Orlando', 'Miami', 'Los Angeles', 'San Francisco', 'Las Vegas'],
  ),
  CountryGuide(
    imageAsset: 'assets/images/countries/japan.jpg',
    nameAr: 'اليابان',
    nameEn: 'Japan',
    cities: ['Tokyo', 'Kyoto', 'Nara', 'Osaka', 'Hiroshima', 'Hakone'],
  ),
  CountryGuide(
    imageAsset: 'assets/images/countries/thailand.jpg',
    nameAr: 'تايلاند',
    nameEn: 'Thailand',
    cities: ['Bangkok', 'Phuket', 'Krabi', 'Koh Samui', 'Chiang Mai', 'Pattaya'],
  ),
  CountryGuide(
    imageAsset: 'assets/images/countries/indonesia.jpg',
    nameAr: 'إندونيسيا',
    nameEn: 'Indonesia',
    cities: ['Bali', 'Jakarta', 'Lombok'],
  ),
];