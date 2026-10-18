import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/hotel_model.dart';
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
    case '1 stars':
      return _t3(context, ar: 'نجمة واحدة', en: '1 star', es: '1 estrella', tr: '1 yıldız',
          id: '1 bintang', hi: '1 सितारा', ur: '1 ستارہ', fr: '1 étoile', bn: '১ তারকা');
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

/// شريط فلاتر جانبي متصل بحالة الفلاتر المشتركة (hotelFiltersProvider).
///
/// ⚠️ كل رقم وكل خيار هنا محسوب من نتائج البحث الفعلية [hotels] — لا أرقام
/// ثابتة ولا فلاتر لبيانات لا نملكها (المرافق، الوجبات، تقييمات النزلاء).
/// نتائج HotelBeds لا تحمل المرافق، فلا نعرض فلاترها حتى نجلب تلك البيانات.
///
/// الأقسام: الميزانية (حسب أرخص/أغلى نتيجة)، النجوم الرسمية، المنطقة (zoneName).
class SearchFiltersSidebar extends ConsumerWidget {
  final List<HotelModel> hotels;
  const SearchFiltersSidebar({super.key, this.hotels = const []});

  /// عدد الفنادق لكل قيمة، مرتبة تنازليًا بالعدد.
  static Map<String, int> _countBy(Iterable<String?> values) {
    final counts = <String, int>{};
    for (final v in values) {
      final key = v?.trim();
      if (key == null || key.isEmpty) continue;
      counts[key] = (counts[key] ?? 0) + 1;
    }
    final sorted = counts.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    return Map.fromEntries(sorted);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filters = ref.watch(hotelFiltersProvider);
    final notifier = ref.read(hotelFiltersProvider.notifier);

    // النجوم: من 5 إلى 1، فقط ما يوجد فعلًا في النتائج.
    final starCounts = _countBy(hotels.map((h) {
      final n = h.rating.round();
      return n >= 1 && n <= 5 ? '$n stars' : null;
    }));
    final starsOrdered = Map.fromEntries(
      ['5 stars', '4 stars', '3 stars', '2 stars', '1 stars']
          .where(starCounts.containsKey)
          .map((k) => MapEntry(k, starCounts[k]!)),
    );

    // المناطق: أسماء حقيقية من HotelBeds، أكثر 12 منطقة + أي منطقة مختارة.
    final zoneCounts = _countBy(hotels.map((h) => h.neighborhood));
    final zones = Map.fromEntries(zoneCounts.entries.take(12));
    for (final selected in filters.neighborhoods) {
      zones.putIfAbsent(selected, () => zoneCounts[selected] ?? 0);
    }

    return Container(
      width: 300,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: Border(left: BorderSide(color: Colors.grey.shade300)),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (filters.hasAnyFilter)
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: TextButton.icon(
                  onPressed: notifier.reset,
                  icon: const Icon(Icons.filter_alt_off_outlined, size: 18),
                  label: Text(_t3(context, ar: 'مسح الفلاتر', en: 'Clear filters', es: 'Borrar filtros',
                      tr: 'Filtreleri temizle', id: 'Hapus filter', hi: 'फ़िल्टर हटाएं', ur: 'فلٹرز صاف کریں',
                      fr: 'Effacer les filtres', bn: 'ফিল্টার মুছুন')),
                ),
              ),
            _buildBudgetSection(context, filters, notifier),
            if (starsOrdered.isNotEmpty) ...[
              const Divider(height: 24),
              _buildCheckboxSection(
                context: context,
                title: _t3(context, ar: 'تصنيف النجوم الرسمي', en: 'Official star rating', es: 'Clasificación oficial por estrellas',
                    tr: 'Resmi yıldız sınıfı', id: 'Peringkat bintang resmi', hi: 'आधिकारिक स्टार रेटिंग',
                    ur: 'سرکاری اسٹار ریٹنگ', fr: 'Classement officiel en étoiles', bn: 'অফিসিয়াল তারকা রেটিং'),
                subtitle: _t3(context, ar: 'فئة الفندق من المزوّد، وليست تقييم نزلاء', en: 'Hotel category from our supplier, not guest reviews',
                    es: 'Categoría del proveedor, no opiniones de huéspedes', tr: 'Tedarikçi kategorisi, misafir yorumu değil',
                    id: 'Kategori dari pemasok, bukan ulasan tamu', hi: 'आपूर्तिकर्ता की श्रेणी, अतिथि समीक्षा नहीं',
                    ur: 'فراہم کنندہ کی درجہ بندی، مہمانوں کے جائزے نہیں', fr: 'Catégorie du fournisseur, pas des avis clients',
                    bn: 'সরবরাহকারীর শ্রেণি, অতিথি রিভিউ নয়'),
                group: HotelFilterGroup.rating,
                counts: starsOrdered,
                notifier: notifier,
              ),
            ],
            if (zones.length > 1) ...[
              const Divider(height: 24),
              _buildCheckboxSection(
                context: context,
                title: _t3(context, ar: 'المنطقة', en: 'Area', es: 'Zona', tr: 'Bölge',
                    id: 'Area', hi: 'क्षेत्र', ur: 'علاقہ', fr: 'Quartier', bn: 'এলাকা'),
                group: HotelFilterGroup.neighborhood,
                counts: zones,
                notifier: notifier,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBudgetSection(BuildContext context, HotelFilterState filters, HotelFiltersNotifier notifier) {
    final prices = hotels.map(hotelNightlyUsd).where((p) => p > 0).toList();
    if (prices.length < 2) return const SizedBox.shrink();
    final minP = prices.reduce((a, b) => a < b ? a : b).floorToDouble();
    var maxP = prices.reduce((a, b) => a > b ? a : b).ceilToDouble();
    if (maxP <= minP) maxP = minP + 1;

    // النطاق الحالي مقيّد بحدود هذه النتائج (قد يكون من بحث سابق).
    final current = filters.budgetRange;
    final values = current == null
        ? RangeValues(minP, maxP)
        : RangeValues(
      current.start.clamp(minP, maxP).toDouble(),
      current.end.clamp(minP, maxP).toDouble(),
    );

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
          '\$${values.start.round()} – \$${values.end.round()}',
          style: const TextStyle(fontSize: 14),
        ),
        RangeSlider(
          values: values,
          min: minP,
          max: maxP,
          onChanged: (r) {
            // إرجاع المنزلقين للطرفين = إلغاء فلتر الميزانية.
            if (r.start <= minP && r.end >= maxP) {
              notifier.clearBudget();
            } else {
              notifier.setBudgetRange(r);
            }
          },
        ),
      ],
    );
  }

  Widget _buildCheckboxSection({
    required BuildContext context,
    required String title,
    required HotelFilterGroup group,
    required Map<String, int> counts,
    required HotelFiltersNotifier notifier,
    String? subtitle,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        if (subtitle != null) ...[
          const SizedBox(height: 4),
          Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
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
                    '${counts[label] ?? 0}',
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