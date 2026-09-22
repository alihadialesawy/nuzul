import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../data/repositories/duffel_repository.dart';
import '../controllers/flight_filters_controller.dart';

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

String _formatMinutesAsTime(double minutes) {
  final total = minutes.round().clamp(0, 1439);
  final h = total ~/ 60;
  final m = total % 60;
  return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
}

/// شريط فلاتر جانبي لنتائج بحث الطيران: خيار "بدون توقف فقط"، قائمة
/// شركات الطيران (محسوبة ديناميكيًا من نتائج البحث الفعلية، مش قائمة
/// ثابتة)، نطاق وقت المغادرة والوصول، وأقصى مدة رحلة.
class FlightFiltersSidebar extends ConsumerWidget {
  final List<DuffelFlightOffer> allOffers;
  const FlightFiltersSidebar({super.key, required this.allOffers});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filters = ref.watch(flightFiltersProvider);
    final notifier = ref.read(flightFiltersProvider.notifier);
    if (allOffers.isNotEmpty) {
      debugPrint('DEBUG departureTime: ${allOffers.first.departureTime}');
      debugPrint('DEBUG arrivalTime: ${allOffers.first.arrivalTime}');
      debugPrint('DEBUG stops: ${allOffers.first.stops}');
      debugPrint('DEBUG durationMinutes: ${allOffers.first.durationMinutes}');
    }
    // نحسب لكل شركة طيران: عدد الرحلات المتاحة، وأرخص سعر لها (بعملته
    // الأصلية كما رجع من Duffel -- مش تحويل عملة هنا، بس للمقارنة
    // النسبية بين الشركات في نفس نتيجة البحث).
    final Map<String, int> counts = {};
    final Map<String, double> minPrices = {};
    final Map<String, String> currencies = {};
    for (final offer in allOffers) {
      counts[offer.airline] = (counts[offer.airline] ?? 0) + 1;
      final currentMin = minPrices[offer.airline];
      if (currentMin == null || offer.totalAmount < currentMin) {
        minPrices[offer.airline] = offer.totalAmount;
        currencies[offer.airline] = offer.totalCurrency;
      }
    }
    final sortedAirlines = counts.keys.toList()
      ..sort((a, b) => (minPrices[a] ?? 0).compareTo(minPrices[b] ?? 0));

    // نحسب أكواد المطارات الفعلية اللي ظهرت في النتائج (مغادرة، وصول،
    // وتوقف) مع عدد مرات ظهور كل كود، عشان نبني قائمة فلتر ديناميكية
    // -- مش قائمة ثابتة، بتتغيّر حسب نتيجة البحث الفعلية.
    final Map<String, int> airportCounts = {};
    for (final offer in allOffers) {
      for (final code in {
        offer.originAirportCode,
        offer.destinationAirportCode,
        ...offer.stopoverAirports,
      }) {
        if (code.isEmpty) continue;
        airportCounts[code] = (airportCounts[code] ?? 0) + 1;
      }
    }
    final sortedAirports = airportCounts.keys.toList()..sort();

    // نفس الفكرة لأنواع الطائرات -- مبنية من قيم offer.aircraft الفعلية
    // الراجعة من Duffel، مش قائمة طائرات ثابتة مفترضة.
    final Map<String, int> aircraftCounts = {};
    for (final offer in allOffers) {
      final aircraft = offer.aircraft;
      if (aircraft == null || aircraft.isEmpty) continue;
      aircraftCounts[aircraft] = (aircraftCounts[aircraft] ?? 0) + 1;
    }
    final sortedAircraft = aircraftCounts.keys.toList()..sort();

    // أقصى عدد توقفات ظاهر فعليًا في النتائج، عشان لا نعرض خيار "توقف
    // واحد أو أقل" لو كل الرحلات أصلاً بدون توقف.
    final maxObservedStops = allOffers.isEmpty
        ? 0
        : allOffers.map((o) => o.stops).reduce((a, b) => a > b ? a : b);

    // أطول مدة رحلة فعلية في النتائج، تُستخدم كحد أقصى لسلايدر المدة
    // (بدل حد ثابت اعتباطي ممكن يبقى أصغر أو أكبر بكتير من الواقع).
    //
    // ملاحظة: المدة مأخوذة جاهزة من offer.durationMinutes (Duffel
    // segment/slice duration) -- مش محسوبة من فرق departureTime
    // وarrivalTime، لأن دول توقيتان محليان مختلفان لكل مطار من غير
    // UTC offset، وطرحهم مباشرة كان بيدي مدة غلط (بيضيف فرق التوقيت
    // بين المطارين على مدة الرحلة الحقيقية).
    final maxObservedDuration = allOffers.isEmpty
        ? 720.0
        : allOffers.map((o) => o.durationMinutes.toDouble()).reduce((a, b) => a > b ? a : b);
    final durationSliderMax = maxObservedDuration < 60 ? 60.0 : maxObservedDuration;
    final currentMaxDuration = filters.maxDurationMinutes ?? durationSliderMax;

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
            Text(
              _t3(context, ar: 'موصى به', en: 'Recommended', es: 'Recomendado', tr: 'Önerilen',
                  id: 'Rekomendasi', hi: 'अनुशंसित', ur: 'تجویز کردہ', fr: 'Recommandé', bn: 'প্রস্তাবিত'),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 4),
            InkWell(
              onTap: () => notifier.setNonstopOnly(!filters.nonstopOnly),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  children: [
                    Checkbox(
                      value: filters.nonstopOnly,
                      onChanged: (v) => notifier.setNonstopOnly(v ?? false),
                    ),
                    Expanded(
                      child: Text(
                        _t3(context, ar: 'بدون توقف', en: 'Nonstop', es: 'Sin escalas', tr: 'Aktarmasız',
                            id: 'Tanpa transit', hi: 'बिना रुके', ur: 'بلا رکاوٹ', fr: 'Sans escale', bn: 'সরাসরি'),
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const Divider(height: 24),

            // قسم التوقفات (Stops): خيارات دقيقة (بدون توقف / توقف واحد
            // أو أقل / أي عدد توقفات) بدل الـ checkbox البسيط اللي فوق.
            // بيظهر بس لو فيه فعلاً رحلات بعدد توقفات مختلف في النتائج.
            if (maxObservedStops > 0) ...[
              Text(
                _t3(context, ar: 'التوقفات', en: 'Stops', es: 'Escalas', tr: 'Aktarmalar',
                    id: 'Transit', hi: 'ठहराव', ur: 'رکاوٹیں', fr: 'Escales', bn: 'যাত্রাবিরতি'),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 4),
              _StopsRadioTile(
                label: _t3(context, ar: 'أي عدد توقفات', en: 'Any number of stops', es: 'Cualquier número de escalas', tr: 'Herhangi bir aktarma sayısı',
                    id: 'Berapa pun jumlah transit', hi: 'कोई भी ठहराव संख्या', ur: 'کوئی بھی رکاوٹ کی تعداد', fr: 'Peu importe le nombre d\'escales', bn: 'যেকোনো সংখ্যক যাত্রাবিরতি'),
                selected: filters.maxStops == null,
                onTap: () => notifier.setMaxStops(null),
              ),
              _StopsRadioTile(
                label: _t3(context, ar: 'بدون توقف فقط', en: 'Nonstop only', es: 'Solo sin escalas', tr: 'Sadece aktarmasız',
                    id: 'Hanya tanpa transit', hi: 'केवल बिना रुके', ur: 'صرف بلا رکاوٹ', fr: 'Sans escale uniquement', bn: 'শুধুমাত্র সরাসরি'),
                selected: filters.maxStops == 0,
                onTap: () => notifier.setMaxStops(0),
              ),
              if (maxObservedStops > 1)
                _StopsRadioTile(
                  label: _t3(context, ar: 'توقف واحد أو أقل', en: '1 stop or fewer', es: '1 escala o menos', tr: '1 veya daha az aktarma',
                      id: '1 transit atau kurang', hi: '1 या उससे कम ठहराव', ur: '1 یا اس سے کم رکاوٹ', fr: '1 escale ou moins', bn: '১টি বা তার কম যাত্রাবিরতি'),
                  selected: filters.maxStops == 1,
                  onTap: () => notifier.setMaxStops(1),
                ),
              const Divider(height: 24),
            ],

            // قسم المدة (Duration): أقصى مدة رحلة مقبولة.
            Text(
              _t3(context, ar: 'مدة الرحلة', en: 'Duration', es: 'Duración', tr: 'Süre',
                  id: 'Durasi', hi: 'अवधि', ur: 'دورانیہ', fr: 'Durée', bn: 'সময়কাল'),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            Text(
              _t3(
                context,
                ar: 'حتى ${(currentMaxDuration / 60).floor()} س ${(currentMaxDuration % 60).round()} د',
                en: 'Up to ${(currentMaxDuration / 60).floor()}h ${(currentMaxDuration % 60).round()}m',
                es: 'Hasta ${(currentMaxDuration / 60).floor()}h ${(currentMaxDuration % 60).round()}m',
                tr: '${(currentMaxDuration / 60).floor()}s ${(currentMaxDuration % 60).round()}dk\'ya kadar',
                id: 'Hingga ${(currentMaxDuration / 60).floor()}j ${(currentMaxDuration % 60).round()}m',
                hi: '${(currentMaxDuration / 60).floor()} घं ${(currentMaxDuration % 60).round()} मि तक',
                ur: '${(currentMaxDuration / 60).floor()} گھ ${(currentMaxDuration % 60).round()} م تک',
                fr: 'Jusqu\'à ${(currentMaxDuration / 60).floor()} h ${(currentMaxDuration % 60).round()} min',
                bn: '${(currentMaxDuration / 60).floor()} ঘ ${(currentMaxDuration % 60).round()} মি পর্যন্ত',
              ),
              style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
            ),
            Slider(
              value: currentMaxDuration.clamp(0, durationSliderMax),
              min: 0,
              max: durationSliderMax,
              divisions: durationSliderMax >= 30 ? (durationSliderMax / 30).round() : null,
              onChanged: (value) => notifier.setMaxDuration(value),
            ),
            if (filters.maxDurationMinutes != null)
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: TextButton(
                  onPressed: () => notifier.setMaxDuration(null),
                  child: Text(_t3(context, ar: 'إعادة تعيين', en: 'Reset', es: 'Restablecer', tr: 'Sıfırla',
                      id: 'Atur ulang', hi: 'रीसेट करें', ur: 'ری سیٹ کریں', fr: 'Réinitialiser', bn: 'রিসেট করুন')),
                ),
              ),
            const Divider(height: 24),

            // قسم الأوقات (Times): نطاق وقت المغادرة والوصول.
            Text(
              _t3(context, ar: 'الأوقات', en: 'Times', es: 'Horarios', tr: 'Saatler',
                  id: 'Waktu', hi: 'समय', ur: 'اوقات', fr: 'Horaires', bn: 'সময়'),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 6),
            Text(
              _t3(context, ar: 'وقت المغادرة', en: 'Departure time', es: 'Hora de salida', tr: 'Kalkış saati',
                  id: 'Waktu keberangkatan', hi: 'प्रस्थान समय', ur: 'روانگی کا وقت', fr: 'Heure de départ', bn: 'ছাড়ার সময়'),
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
            Text(
              '${_formatMinutesAsTime(filters.departureTimeRange.start)} – ${_formatMinutesAsTime(filters.departureTimeRange.end)}',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
            ),
            RangeSlider(
              values: filters.departureTimeRange,
              min: 0,
              max: 1439,
              divisions: 48,
              onChanged: notifier.setDepartureTimeRange,
            ),
            const SizedBox(height: 6),
            Text(
              _t3(context, ar: 'وقت الوصول', en: 'Arrival time', es: 'Hora de llegada', tr: 'Varış saati',
                  id: 'Waktu kedatangan', hi: 'आगमन समय', ur: 'آمد کا وقت', fr: 'Heure d\'arrivée', bn: 'পৌঁছানোর সময়'),
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
            Text(
              '${_formatMinutesAsTime(filters.arrivalTimeRange.start)} – ${_formatMinutesAsTime(filters.arrivalTimeRange.end)}',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
            ),
            RangeSlider(
              values: filters.arrivalTimeRange,
              min: 0,
              max: 1439,
              divisions: 48,
              onChanged: notifier.setArrivalTimeRange,
            ),
            const Divider(height: 24),

            Text(
              _t3(context, ar: 'شركات الطيران', en: 'Airlines', es: 'Aerolíneas', tr: 'Havayolları',
                  id: 'Maskapai', hi: 'एयरलाइंस', ur: 'ایئرلائنز', fr: 'Compagnies aériennes', bn: 'এয়ারলাইন্স'),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 4),
            if (sortedAirlines.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  _t3(context, ar: 'لا توجد شركات طيران لعرضها', en: 'No airlines to show', es: 'No hay aerolíneas para mostrar', tr: 'Gösterilecek havayolu yok',
                      id: 'Tidak ada maskapai untuk ditampilkan', hi: 'दिखाने के लिए कोई एयरलाइन नहीं', ur: 'دکھانے کے لیے کوئی ایئرلائن نہیں', fr: 'Aucune compagnie aérienne à afficher', bn: 'দেখানোর মতো কোনো এয়ারলাইন্স নেই'),
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                ),
              )
            else
              ...sortedAirlines.map((airline) {
                final isSelected = filters.selectedAirlines.contains(airline);
                return InkWell(
                  onTap: () => notifier.toggleAirline(airline),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      children: [
                        Checkbox(
                          value: isSelected,
                          onChanged: (_) => notifier.toggleAirline(airline),
                        ),
                        Expanded(
                          child: Text(
                            '$airline (${counts[airline]})',
                            style: const TextStyle(fontSize: 14),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          '${minPrices[airline]?.toStringAsFixed(0) ?? ''} ${currencies[airline] ?? ''}',
                          style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ),
                );
              }),

            if (sortedAirports.isNotEmpty) ...[
              const Divider(height: 24),
              Text(
                _t3(context, ar: 'المطارات', en: 'Airports', es: 'Aeropuertos', tr: 'Havalimanları',
                    id: 'Bandara', hi: 'हवाई अड्डे', ur: 'ہوائی اڈے', fr: 'Aéroports', bn: 'বিমানবন্দর'),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 4),
              ...sortedAirports.map((code) {
                final isSelected = filters.selectedAirports.contains(code);
                return InkWell(
                  onTap: () => notifier.toggleAirport(code),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      children: [
                        Checkbox(
                          value: isSelected,
                          onChanged: (_) => notifier.toggleAirport(code),
                        ),
                        Expanded(
                          child: Text(
                            code,
                            style: const TextStyle(fontSize: 14),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          '${airportCounts[code] ?? ''}',
                          style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ],

            if (sortedAircraft.isNotEmpty) ...[
              const Divider(height: 24),
              Text(
                _t3(context, ar: 'نوع الطائرة', en: 'Aircraft', es: 'Aeronave', tr: 'Uçak Tipi',
                    id: 'Pesawat', hi: 'विमान', ur: 'ہوائی جہاز', fr: 'Appareil', bn: 'বিমান'),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 4),
              ...sortedAircraft.map((aircraft) {
                final isSelected = filters.selectedAircraft.contains(aircraft);
                return InkWell(
                  onTap: () => notifier.toggleAircraft(aircraft),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      children: [
                        Checkbox(
                          value: isSelected,
                          onChanged: (_) => notifier.toggleAircraft(aircraft),
                        ),
                        Expanded(
                          child: Text(
                            aircraft,
                            style: const TextStyle(fontSize: 14),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          '${aircraftCounts[aircraft] ?? ''}',
                          style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ],
          ],
        ),
      ),
    );
  }
}

/// عنصر اختيار وحيد (radio-like) لقسم التوقفات -- شكل بسيط بدون
/// استخدام Radio widget الرسمي، عشان يتماشى بصريًا مع باقي عناصر
/// الفلتر (Checkbox-style rows).
class _StopsRadioTile extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _StopsRadioTile({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Icon(
              selected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
              size: 18,
              color: selected ? AppColors.primary : Colors.grey.shade500,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(label, style: const TextStyle(fontSize: 14)),
            ),
          ],
        ),
      ),
    );
  }
}