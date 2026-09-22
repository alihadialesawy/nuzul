import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../controllers/hotel_filters_controller.dart';

/// يختار النص المناسب حسب اللغة الحالية (عربي/إنجليزي/إسباني/تركي/إندونيسي/هندي/أوردو/فرنسي/بنغالي).
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

/// يترجم مفتاح فلتر (زي "Swimming pool" أو "4 stars") لنص معروض بلغة
/// الواجهة الحالية. المفتاح الإنجليزي نفسه بيفضل هو المستخدم في المقارنة
/// المنطقية (notifier.toggle/isSelected) ومطابقة بيانات الفندق -- الدالة
/// دي بس بتغيّر الشكل المعروض للمستخدم، مش المنطق. أي مفتاح مش موجود في
/// القائمة (زي أسماء الأحياء الحقيقية ببوسطن) بيترجع زي ما هو من غير ترجمة،
/// لأنها بيانات حقيقية (أسماء أماكن فعلية) مش نصوص عرض عامة.
String _labelText(BuildContext context, String key) {
  switch (key) {
    case 'Hotels':
      return _t3(context, ar: 'فنادق', en: 'Hotels', es: 'Hoteles', tr: 'Oteller',
          id: 'Hotel', hi: 'होटल', ur: 'ہوٹلز', fr: 'Hôtels', bn: 'হোটেল');
    case 'Private bathroom':
      return _t3(context, ar: 'حمام خاص', en: 'Private bathroom', es: 'Baño privado', tr: 'Özel banyo',
          id: 'Kamar mandi pribadi', hi: 'निजी बाथरूम', ur: 'نجی باتھ روم', fr: 'Salle de bain privée', bn: 'ব্যক্তিগত বাথরুম');
    case 'Breakfast included':
      return _t3(context, ar: 'إفطار متضمّن', en: 'Breakfast included', es: 'Desayuno incluido', tr: 'Kahvaltı dahil',
          id: 'Termasuk sarapan', hi: 'नाश्ता शामिल', ur: 'ناشتہ شامل', fr: 'Petit-déjeuner inclus', bn: 'নাস্তা অন্তর্ভুক্ত');
    case 'Very Good: 8+':
      return _t3(context, ar: 'جيد جدًا: +8', en: 'Very Good: 8+', es: 'Muy bueno: 8+', tr: 'Çok İyi: 8+',
          id: 'Sangat Baik: 8+', hi: 'बहुत अच्छा: 8+', ur: 'بہت اچھا: +8', fr: 'Très bien : 8+', bn: 'অতি ভালো: ৮+');
    case 'Parking':
      return _t3(context, ar: 'موقف سيارات', en: 'Parking', es: 'Estacionamiento', tr: 'Otopark',
          id: 'Parkir', hi: 'पार्किंग', ur: 'پارکنگ', fr: 'Parking', bn: 'পার্কিং');
    case '4 stars':
      return _t3(context, ar: '4 نجوم', en: '4 stars', es: '4 estrellas', tr: '4 yıldız',
          id: '4 bintang', hi: '4 सितारे', ur: '4 ستارے', fr: '4 étoiles', bn: '৪ তারকা');
    case 'Apartments':
      return _t3(context, ar: 'شقق فندقية', en: 'Apartments', es: 'Apartamentos', tr: 'Daireler',
          id: 'Apartemen', hi: 'अपार्टमेंट', ur: 'اپارٹمنٹس', fr: 'Appartements', bn: 'অ্যাপার্টমেন্ট');
    case 'Airport shuttle':
      return _t3(context, ar: 'خدمة نقل من/إلى المطار', en: 'Airport shuttle', es: 'Traslado al aeropuerto', tr: 'Havaalanı servisi',
          id: 'Antar-jemput bandara', hi: 'एयरपोर्ट शटल', ur: 'ایئرپورٹ شٹل', fr: 'Navette aéroport', bn: 'এয়ারপোর্ট শাটল');
    case 'Condo Hotels':
      return _t3(context, ar: 'فنادق شقق (كوندو)', en: 'Condo Hotels', es: 'Hoteles apartamento', tr: 'Rezidans Oteller',
          id: 'Hotel Kondominium', hi: 'कॉन्डो होटल', ur: 'کونڈو ہوٹلز', fr: 'Hôtels-appartements', bn: 'কনডো হোটেল');
    case 'Guesthouses':
      return _t3(context, ar: 'بيوت ضيافة', en: 'Guesthouses', es: 'Casas de huéspedes', tr: 'Pansiyonlar',
          id: 'Rumah tamu', hi: 'गेस्टहाउस', ur: 'گیسٹ ہاؤسز', fr: 'Maisons d\'hôtes', bn: 'গেস্টহাউস');
    case 'Bed and Breakfasts':
      return _t3(context, ar: 'بيوت مبيت وإفطار', en: 'Bed and Breakfasts', es: 'Alojamiento y desayuno', tr: 'Pansiyon (Oda-Kahvaltı)',
          id: 'Penginapan dengan Sarapan', hi: 'बेड एंड ब्रेकफास्ट', ur: 'بیڈ اینڈ بریک فاسٹ', fr: 'Chambres d\'hôtes', bn: 'বেড অ্যান্ড ব্রেকফাস্ট');
    case 'Motels':
      return _t3(context, ar: 'موتيلات', en: 'Motels', es: 'Moteles', tr: 'Moteller',
          id: 'Motel', hi: 'मोटल', ur: 'موٹلز', fr: 'Motels', bn: 'মোটেল');
    case 'Hostels':
      return _t3(context, ar: 'نُزل (هوستل)', en: 'Hostels', es: 'Hostales', tr: 'Hosteller',
          id: 'Hostel', hi: 'होस्टल', ur: 'ہوسٹلز', fr: 'Auberges', bn: 'হোস্টেল');
    case 'Homestays':
      return _t3(context, ar: 'إقامة مع عائلة (هوم ستاي)', en: 'Homestays', es: 'Alojamiento en casas particulares', tr: 'Ev Konaklaması',
          id: 'Menginap di Rumah Warga', hi: 'होमस्टे', ur: 'ہوم اسٹے', fr: 'Séjours chez l\'habitant', bn: 'হোমস্টে');
    case 'Entire homes & apartments':
      return _t3(context, ar: 'منازل وشقق كاملة', en: 'Entire homes & apartments', es: 'Casas y apartamentos completos', tr: 'Tüm Ev ve Daireler',
          id: 'Seluruh rumah & apartemen', hi: 'पूरे घर और अपार्टमेंट', ur: 'پورے گھر اور اپارٹمنٹس', fr: 'Maisons et appartements entiers', bn: 'সম্পূর্ণ বাড়ি ও অ্যাপার্টমেন্ট');
    case 'Kitchen amenities':
      return _t3(context, ar: 'تجهيزات مطبخ', en: 'Kitchen amenities', es: 'Comodidades de cocina', tr: 'Mutfak olanakları',
          id: 'Fasilitas dapur', hi: 'रसोई सुविधाएं', ur: 'باورچی خانے کی سہولیات', fr: 'Équipements de cuisine', bn: 'রান্নাঘরের সুবিধা');
    case 'Swimming pool':
      return _t3(context, ar: 'مسبح', en: 'Swimming pool', es: 'Piscina', tr: 'Yüzme havuzu',
          id: 'Kolam renang', hi: 'स्विमिंग पूल', ur: 'سوئمنگ پول', fr: 'Piscine', bn: 'সুইমিং পুল');
    case 'Free WiFi':
      return _t3(context, ar: 'واي فاي مجاني', en: 'Free WiFi', es: 'WiFi gratis', tr: 'Ücretsiz WiFi',
          id: 'WiFi gratis', hi: 'मुफ़्त वाई-फाई', ur: 'مفت وائی فائی', fr: 'WiFi gratuit', bn: 'ফ্রি ওয়াইফাই');
    case 'Hot tub/Jacuzzi':
      return _t3(context, ar: 'جاكوزي', en: 'Hot tub/Jacuzzi', es: 'Jacuzzi', tr: 'Jakuzi',
          id: 'Bak air panas/Jacuzzi', hi: 'हॉट टब/जकूज़ी', ur: 'ہاٹ ٹب/جکوزی', fr: 'Bain à remous / Jacuzzi', bn: 'হট টাব/জ্যাকুজি');
    case 'Spa and wellness center':
      return _t3(context, ar: 'سبا ومركز عافية', en: 'Spa and wellness center', es: 'Spa y centro de bienestar', tr: 'Spa ve sağlık merkezi',
          id: 'Spa dan pusat kebugaran', hi: 'स्पा और वेलनेस सेंटर', ur: 'اسپا اور ویلنیس سینٹر', fr: 'Spa et centre de bien-être', bn: 'স্পা ও ওয়েলনেস সেন্টার');
    case 'Air conditioning':
      return _t3(context, ar: 'تكييف هواء', en: 'Air conditioning', es: 'Aire acondicionado', tr: 'Klima',
          id: 'AC', hi: 'एयर कंडीशनिंग', ur: 'ایئر کنڈیشننگ', fr: 'Climatisation', bn: 'এয়ার কন্ডিশনিং');
    case 'Balcony':
      return _t3(context, ar: 'شرفة', en: 'Balcony', es: 'Balcón', tr: 'Balkon',
          id: 'Balkon', hi: 'बालकनी', ur: 'بالکنی', fr: 'Balcon', bn: 'বারান্দা');
    case 'Sea view':
      return _t3(context, ar: 'إطلالة على البحر', en: 'Sea view', es: 'Vista al mar', tr: 'Deniz manzarası',
          id: 'Pemandangan laut', hi: 'समुद्र दृश्य', ur: 'سمندر کا نظارہ', fr: 'Vue sur la mer', bn: 'সমুদ্রের দৃশ্য');
    case 'Kitchen/Kitchenette':
      return _t3(context, ar: 'مطبخ/مطبخ صغير', en: 'Kitchen/Kitchenette', es: 'Cocina/Cocineta', tr: 'Mutfak/Mini mutfak',
          id: 'Dapur/Dapur kecil', hi: 'रसोई/मिनी किचन', ur: 'باورچی خانہ/چھوٹا باورچی خانہ', fr: 'Cuisine/Kitchenette', bn: 'রান্নাঘর/মিনি রান্নাঘর');
    case '2 stars':
      return _t3(context, ar: 'نجمتان', en: '2 stars', es: '2 estrellas', tr: '2 yıldız',
          id: '2 bintang', hi: '2 सितारे', ur: '2 ستارے', fr: '2 étoiles', bn: '২ তারকা');
    case '3 stars':
      return _t3(context, ar: '3 نجوم', en: '3 stars', es: '3 estrellas', tr: '3 yıldız',
          id: '3 bintang', hi: '3 सितारे', ur: '3 ستارے', fr: '3 étoiles', bn: '৩ তারকা');
    case '5 stars':
      return _t3(context, ar: '5 نجوم', en: '5 stars', es: '5 estrellas', tr: '5 yıldız',
          id: '5 bintang', hi: '5 सितारे', ur: '5 ستارے', fr: '5 étoiles', bn: '৫ তারকা');
    default:
    // أسماء أحياء حقيقية (زي "South End"، "Back Bay") أو أي مفتاح
    // جديد لسه مضافش هنا -- بيتعرض زي ما هو من غير ترجمة.
      return key;
  }
}

/// شريط فلاتر جانبي متصل فعليًا بحالة الفلاتر المشتركة (hotelFiltersProvider)،
/// يظهر بجانب قائمة نتائج البحث، بنفس روح فلاتر Booking.com: نطاق سعري،
/// فلاتر شائعة، نوع العقار، الوجبات والمرافق، الحي، وتصنيف العقار.
class SearchFiltersSidebar extends ConsumerWidget {
  const SearchFiltersSidebar({super.key});

  static const Map<String, int> _popularFilterCounts = {
    'Hotels': 76,
    'Private bathroom': 124,
    'Breakfast included': 42,
    'Very Good: 8+': 98,
    'Parking': 97,
    '4 stars': 70,
    'Apartments': 58,
    'Airport shuttle': 8,
  };

  static const Map<String, int> _propertyTypeCounts = {
    'Hotels': 76,
    'Condo Hotels': 5,
    'Apartments': 58,
    'Guesthouses': 3,
    'Bed and Breakfasts': 2,
    'Motels': 2,
    'Hostels': 2,
    'Homestays': 3,
    'Entire homes & apartments': 67,
  };

  static const Map<String, int> _mealsCounts = {
    'Breakfast included': 42,
    'Kitchen amenities': 67,
  };

  static const Map<String, int> _amenitiesCounts = {
    'Swimming pool': 35,
    'Parking': 97,
    'Free WiFi': 139,
    'Hot tub/Jacuzzi': 7,
    'Spa and wellness center': 7,
  };

  static const Map<String, int> _roomAmenitiesCounts = {
    'Air conditioning': 127,
    'Private bathroom': 124,
    'Balcony': 9,
    'Sea view': 5,
    'Kitchen/Kitchenette': 67,
  };

  static const Map<String, int> _neighborhoodCounts = {
    'Downtown Boston': 85,
    "Guests' favorite area": 75,
    'South End': 24,
    'Back Bay': 20,
    'Fenway Kenmore': 15,
    'Theater District': 13,
    'South Boston': 13,
    'Waterfront': 12,
    'Seaport': 11,
    'Dorchester': 9,
  };

  static const Map<String, int> _propertyRatingCounts = {
    '2 stars': 3,
    '3 stars': 52,
    '4 stars': 70,
    '5 stars': 12,
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filters = ref.watch(hotelFiltersProvider);
    final notifier = ref.read(hotelFiltersProvider.notifier);

    return Container(
      width: 300,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          left: BorderSide(color: Colors.grey.shade300),
        ),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildBudgetSection(context, filters, notifier),
            const Divider(height: 24),
            _buildCheckboxSection(
              context: context,
              title: _t3(context, ar: 'الفلاتر الشائعة', en: 'Popular filters', es: 'Filtros populares', tr: 'Popüler filtreler',
                  id: 'Filter populer', hi: 'लोकप्रिय फ़िल्टर', ur: 'مقبول فلٹرز', fr: 'Filtres populaires', bn: 'জনপ্রিয় ফিল্টার'),
              group: HotelFilterGroup.popular,
              counts: _popularFilterCounts,
              filters: filters,
              notifier: notifier,
            ),
            const Divider(height: 24),
            _buildCheckboxSection(
              context: context,
              title: _t3(context, ar: 'نوع العقار', en: 'Property Type', es: 'Tipo de propiedad', tr: 'Mülk Tipi',
                  id: 'Tipe Properti', hi: 'प्रॉपर्टी का प्रकार', ur: 'پراپرٹی کی قسم', fr: 'Type de propriété', bn: 'সম্পত্তির ধরন'),
              group: HotelFilterGroup.propertyType,
              counts: _propertyTypeCounts,
              filters: filters,
              notifier: notifier,
            ),
            const Divider(height: 24),
            _buildCheckboxSection(
              context: context,
              title: _t3(context, ar: 'الوجبات', en: 'Meals', es: 'Comidas', tr: 'Yemekler',
                  id: 'Makanan', hi: 'भोजन', ur: 'کھانا', fr: 'Repas', bn: 'খাবার'),
              group: HotelFilterGroup.meals,
              counts: _mealsCounts,
              filters: filters,
              notifier: notifier,
            ),
            const SizedBox(height: 16),
            _buildCheckboxSection(
              context: context,
              title: _t3(context, ar: 'المرافق', en: 'Amenities', es: 'Comodidades', tr: 'Olanaklar',
                  id: 'Fasilitas', hi: 'सुविधाएं', ur: 'سہولیات', fr: 'Équipements', bn: 'সুবিধা'),
              group: HotelFilterGroup.amenities,
              counts: _amenitiesCounts,
              filters: filters,
              notifier: notifier,
            ),
            const SizedBox(height: 16),
            _buildCheckboxSection(
              context: context,
              title: _t3(context, ar: 'مرافق الغرفة', en: 'Room amenities', es: 'Comodidades de la habitación', tr: 'Oda olanakları',
                  id: 'Fasilitas kamar', hi: 'कमरे की सुविधाएं', ur: 'کمرے کی سہولیات', fr: 'Équipements de la chambre', bn: 'রুমের সুবিধা'),
              group: HotelFilterGroup.roomAmenities,
              counts: _roomAmenitiesCounts,
              filters: filters,
              notifier: notifier,
            ),
            const Divider(height: 24),
            _buildCheckboxSection(
              context: context,
              title: _t3(context, ar: 'الحي', en: 'Neighborhood', es: 'Barrio', tr: 'Semt',
                  id: 'Lingkungan', hi: 'इलाका', ur: 'علاقہ', fr: 'Quartier', bn: 'এলাকা'),
              group: HotelFilterGroup.neighborhood,
              counts: _neighborhoodCounts,
              filters: filters,
              notifier: notifier,
            ),
            const Divider(height: 24),
            _buildCheckboxSection(
              context: context,
              title: _t3(context, ar: 'تصنيف العقار', en: 'Property rating', es: 'Calificación de la propiedad', tr: 'Mülk puanı',
                  id: 'Peringkat properti', hi: 'प्रॉपर्टी रेटिंग', ur: 'پراپرٹی ریٹنگ', fr: 'Évaluation de l\'établissement', bn: 'সম্পত্তির রেটিং'),
              subtitle: _t3(context, ar: 'اكتشف فنادق ووحدات إجازات عالية الجودة', en: 'Find high-quality hotels and vacation rentals',
                  es: 'Encuentra hoteles y alquileres vacacionales de alta calidad', tr: 'Yüksek kaliteli oteller ve tatil kiralıkları bulun',
                  id: 'Temukan hotel dan sewa liburan berkualitas tinggi', hi: 'उच्च गुणवत्ता वाले होटल और छुट्टियों के किराये खोजें',
                  ur: 'اعلیٰ معیار کے ہوٹلز اور تعطیلاتی کرایہ تلاش کریں', fr: 'Trouvez des hôtels et locations de vacances de qualité',
                  bn: 'উচ্চমানের হোটেল ও ছুটির ভাড়া খুঁজুন'),
              group: HotelFilterGroup.rating,
              counts: _propertyRatingCounts,
              filters: filters,
              notifier: notifier,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBudgetSection(BuildContext context, HotelFilterState filters, HotelFiltersNotifier notifier) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _t3(context, ar: 'ميزانيتك (لليلة)', en: 'Your budget (per night)', es: 'Tu presupuesto (por noche)', tr: 'Bütçeniz (gecelik)',
              id: 'Anggaran Anda (per malam)', hi: 'आपका बजट (प्रति रात)', ur: 'آپ کا بجٹ (فی رات)', fr: 'Votre budget (par nuit)', bn: 'আপনার বাজেট (প্রতি রাত)'),
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 8),
        Text(
          '\$${filters.budgetRange.start.round()} – \$${filters.budgetRange.end.round()}+',
          style: const TextStyle(fontSize: 14),
        ),
        RangeSlider(
          values: filters.budgetRange,
          min: 80,
          max: 800,
          divisions: 20,
          onChanged: notifier.setBudgetRange,
        ),
      ],
    );
  }

  Widget _buildCheckboxSection({
    required BuildContext context,
    required String title,
    required HotelFilterGroup group,
    required Map<String, int> counts,
    required HotelFilterState filters,
    required HotelFiltersNotifier notifier,
    String? subtitle,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
        ],
        const SizedBox(height: 4),
        ...counts.keys.map((label) {
          final isSelected = notifier.isSelected(group, label);
          return InkWell(
            onTap: () => notifier.toggle(group, label),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                children: [
                  Checkbox(
                    value: isSelected,
                    onChanged: (_) => notifier.toggle(group, label),
                  ),
                  Expanded(
                    child: Text(_labelText(context, label), style: const TextStyle(fontSize: 14)),
                  ),
                  Text(
                    '${counts[label] ?? ''}',
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }
}