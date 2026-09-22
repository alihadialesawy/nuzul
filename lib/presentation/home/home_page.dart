import 'dart:async';
import 'widgets/us_destinations_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../core/providers/locale_provider.dart';
import '../../core/providers/currency_provider.dart';
import '../../core/widgets/error_view.dart';
import '../../core/widgets/loading_view.dart';
import '../../core/widgets/empty_view.dart';
import '../../core/widgets/rating_badge.dart';
import '../../core/widgets/price_text.dart';
import '../../core/widgets/currency_selector_button.dart';
import '../../core/widgets/app_footer.dart';
import '../../core/widgets/app_banner.dart';
import 'widgets/trending_destinations.dart';
import 'widgets/country_browser.dart';
import 'widgets/deals_section.dart';
import 'widgets/accommodation_types_section.dart';
import 'widgets/accommodation_preview_section.dart';
import 'widgets/featured_hotels_section.dart';
import 'widgets/faq_section.dart';
import 'widgets/search_filters_sidebar.dart';
import 'controllers/hotel_filters_controller.dart';
import 'controllers/duffel_flight_search_controller.dart';
import 'controllers/flight_filters_controller.dart';
import 'widgets/flight_filters_sidebar.dart';
import 'widgets/flight_date_price_strip.dart';
import '../../data/repositories/duffel_repository.dart';
import '../../data/models/hotel_model.dart';
import '../../data/models/destination_model.dart';
import '../../data/models/flight_model.dart';
import '../../data/models/car_model.dart';
import '../../localization/app_localizations.dart';
import '../auth/controllers/auth_controller.dart';
import '../favorites/controllers/favorites_controller.dart';
import '../search/controllers/search_controller.dart';

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

/// شاشة رئيسية: بحث حر عن الفنادق بدون تسجيل دخول (guest mode)
/// حالة اختيار الرحلة والفندق في تبويب Flight+Hotel — Riverpod state
/// بدل ما تفضل جوه StatefulWidget متداخل، عشان شريط الملخص يقدر
/// يتعرض في مكانه الصحيح (bottomNavigationBar بتاعة الـ Scaffold)
/// من غير أي تعقيد في بنية الـ widgets يسبب مشاكل تخطيط.
final flightHotelSelectionProvider =
StateProvider<({DuffelFlightOffer? offer, HotelModel? hotel})>((ref) => (offer: null, hotel: null));

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  // التبويب المفعّل حاليًا في قسم البحث ("stays" أو "flights"). تبويب
  // Car rental لسه شكلي بس ("قريبًا").
  String _activeTab = 'stays';

  // نوع العقار المختار حاليًا من قسم "أنواع الإقامة الشائعة" (Hotels/
  // Apartments/Villas/Resorts/Chalets)، أو null لو مفيش نوع متعلّم.
  // بيتحكم في ظهور AccommodationPreviewSection تحت الأزرار مباشرة.
  String? _selectedAccommodationType;

  // لما نبحث في تبويب الطيران، فورم البحث بيتصغّر لشريط ملخّص واحد
  // (عشان يوفّر مساحة رأسية لنتايج البحث)، وده اللي بيتحكم فيه.
  bool _flightFormExpanded = true;

  final _cityController = TextEditingController();
  DestinationModel? _selectedDestination;
  List<DestinationModel> _destinationSuggestions = [];
  Timer? _destinationDebounce;
  DateTime _checkIn = DateTime.now().add(const Duration(days: 1));
  DateTime _checkOut = DateTime.now().add(const Duration(days: 3));
  int _guests = 2;
  final _dateFieldKey = GlobalKey();
  final _flightHotelDateFieldKey = GlobalKey();

  final _flightFromController = TextEditingController();
  final _flightToController = TextEditingController();
  String _flightTripType = 'roundtrip';
  bool _nonstopOnly = false;
  DateTimeRange? _flightDateRange;
  final _flightDateFieldKey = GlobalKey();
  int _flightTravelers = 1;
  String _flightCabinClass = 'Economy';
  bool _addStay = false;
  bool _addCar = false;

  final _carPickupController = TextEditingController();
  bool _carDifferentDropoff = false;
  final _carDropoffController = TextEditingController();
  DateTimeRange? _carDateRange;
  final _carDateFieldKey = GlobalKey();

  Map<String, dynamic>? _searchParams;
  Map<String, dynamic>? _flightSearchParams;
  Map<String, dynamic>? _carSearchParams;

  @override
  void dispose() {
    _cityController.dispose();
    _flightFromController.dispose();
    _flightToController.dispose();
    _carPickupController.dispose();
    _carDropoffController.dispose();
    _destinationDebounce?.cancel();
    super.dispose();
  }

  void _onCityTextChanged(String query) {
    _destinationDebounce?.cancel();
    _selectedDestination = null;
    if (query.trim().length < 2) {
      setState(() => _destinationSuggestions = []);
      return;
    }
    _destinationDebounce = Timer(const Duration(milliseconds: 300), () async {
      final repo = ref.read(hotelRepositoryProvider);
      final result = await repo.searchDestinations(query.trim());
      if (!mounted) return;
      result.when(
        success: (list) => setState(() => _destinationSuggestions = list),
        failure: (_) => setState(() => _destinationSuggestions = []),
      );
    });
  }

  void _selectDestinationSuggestion(DestinationModel destination) {
    setState(() {
      _cityController.text = destination.name;
      _selectedDestination = destination;
      _destinationSuggestions = [];
    });
  }

  /// يفتح شاشة "تصفّح حسب الدولة" (bottom sheet) عشان المستخدم يقدر
  /// يختار مدينة بالتصفح بدل الكتابة. لما يختار مدينة، بتتقفل الشاشة
  /// تلقائيًا وتتحدد كوجهة البحث (نفس سلوك اختيار اقتراح من القائمة).
  void _openCountryBrowser() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return CountryBrowser(
          repository: ref.read(hotelRepositoryProvider),
          onCitySelected: (destination) {
            _selectDestinationSuggestion(destination);
            Navigator.of(sheetContext).pop();
          },
        );
      },
    );
  }

  /// يُستدعى عند الدوس على نوع عقار جاهز في قسم "أنواع الإقامة
  /// الشائعة" (Hotels/Apartments/Villas/Resorts/Chalets). بيبدّل ظهور
  /// AccommodationPreviewSection تحت الأزرار مباشرة (Toggle: دوسة تانية
  /// على نفس النوع بتلغي التحديد وتخفي القسم).
  void _onAccommodationTypeSelected(String labelEn) {
    setState(() {
      _selectedAccommodationType = _selectedAccommodationType == labelEn ? null : labelEn;
    });
  }

  Future<void> _runSearch() async {
    // لو المستخدم كتب اسم مدينة بحرّيته من غير ما يدوس على أي اقتراح
    // من القائمة، بندوّر على تطابق تمامًا (case-insensitive) لاسم
    // المدينة المكتوب مع نتائج hotelbeds_destinations قبل ما نرفض
    // البحث -- عشان مايبقاش لازم عليه يدوس على الاقتراح بالماوس لو
    // هو أصلاً كتب الاسم صح وكامل.
    if (_selectedDestination == null) {
      final typed = _cityController.text.trim();
      if (typed.isNotEmpty) {
        final repo = ref.read(hotelRepositoryProvider);
        final result = await repo.searchDestinations(typed);
        if (!mounted) return;
        result.when(
          success: (list) {
            for (final d in list) {
              if (d.name.trim().toLowerCase() == typed.toLowerCase()) {
                setState(() {
                  _selectedDestination = d;
                  _destinationSuggestions = [];
                });
                break;
              }
            }
          },
          failure: (_) {},
        );
      }
    }

    if (_selectedDestination == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _t3(
              context,
              ar: 'من فضلك اختر وجهة من القائمة المقترحة',
              en: 'Please pick a destination from the suggestions',
              es: 'Selecciona un destino de las sugerencias',
              tr: 'Lütfen önerilerden bir hedef seçin',
              id: 'Silakan pilih destinasi dari saran',
              hi: 'कृपया सुझावों में से एक गंतव्य चुनें',
              ur: 'براہ کرم تجاویز میں سے ایک منزل منتخب کریں',
              fr: 'Veuillez choisir une destination parmi les suggestions',
              bn: 'অনুগ্রহ করে পরামর্শ থেকে একটি গন্তব্য বেছে নিন',
            ),
          ),
        ),
      );
      return;
    }
    setState(() {
      _searchParams = {
        'destinationCode': _selectedDestination!.code,
        'cityLabel': _selectedDestination!.name,
        'checkIn': _checkIn,
        'checkOut': _checkOut,
        'guests': _guests,
      };
    });
  }

  void _runFlightSearch() {
    final origin = _flightFromController.text.trim();
    final destination = _flightToController.text.trim();
    if (origin.isEmpty || destination.isEmpty) return;
    setState(() {
      _flightFormExpanded = false;
      _flightSearchParams = {
        'origin': origin,
        'destination': destination,
        'departureDate':
        _flightDateRange?.start ?? DateTime.now().add(const Duration(days: 1)),
        'travelers': _flightTravelers,
        'cabinClass': _flightCabinClass,
        'nonstopOnly': _nonstopOnly,
      };
    });
  }

  /// يشغّل بحث الرحلة والفندق مع بعض. لازم الحقول التلاتة (المغادرة من،
  /// الوجهة، مدينة الإقامة) تكون متملية، وإلا بنوريه رسالة توضيحية بدل
  /// ما نتجاهل الضغطة بصمت. تاريخ الذهاب بيتاخد من تاريخ check-in
  /// المشترك، وعدد المسافرين بيتاخد من عدد الضيوف نفسه لتبسيط الفورم.
  Future<void> _runFlightHotelSearch() async {
    final origin = _flightFromController.text.trim();
    final destination = _flightToController.text.trim();

    if (origin.isEmpty || destination.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _t3(
              context,
              ar: 'من فضلك أكمل بيانات الرحلة والإقامة كلها',
              en: 'Please fill in both the flight and stay details',
              es: 'Completa los datos del vuelo y la estancia',
              tr: 'Lütfen hem uçuş hem de konaklama bilgilerini eksiksiz doldurun',
              id: 'Mohon lengkapi detail penerbangan dan menginap',
              hi: 'कृपया उड़ान और ठहरने दोनों की जानकारी भरें',
              ur: 'براہ کرم پرواز اور قیام دونوں کی تفصیلات بھریں',
              fr: 'Veuillez remplir les informations du vol et de l\'hébergement',
              bn: 'অনুগ্রহ করে ফ্লাইট ও থাকার তথ্য উভয়ই পূরণ করুন',
            ),
          ),
        ),
      );
      return;
    }

    // بدل ما نعتمد على اللي كتبه المستخدم بحقل "أين تقيم؟" (ممكن يكتبه
    // بأي لغة، زي "بوسطن" بالعربي، بينما وجهة الطيران معروضة بالإنجليزي
    // "Boston" -- مقارنة نصوص بين لغتين مختلفتين تفشل دايمًا حتى لو نفس
    // المدينة بالظبط)، بهالتبويب تحديدًا (طيران+فندق) مدينة الفندق لازم
    // تتبع وجهة الطيران نفسها دايمًا. فبندوّر مباشرة عن فنادق بنفس اسم
    // وجهة الطيران (destination بالإنجليزي دايمًا)، ونحدّث حقل "أين
    // تقيم؟" ليعرض نفس النتيجة -- فتختفي إمكانية التعارض من أساسها بدل
    // ما نكتشفها بعد ما تصير (ونفس نمط _selectDestination بالملف: نطالب
    // بأول نتيجة List.first مباشرة، لأن الـ API بيرجّع الاسم بصيغة أطول
    // عادة زي "Boston, MA, United States").
    final repo = ref.read(hotelRepositoryProvider);
    final result = await repo.searchDestinations(destination);
    if (!mounted) return;
    result.when(
      success: (list) {
        if (list.isNotEmpty) {
          setState(() {
            _selectedDestination = list.first;
            _cityController.text = list.first.name;
            _destinationSuggestions = [];
          });
        }
      },
      failure: (_) {},
    );

    if (_selectedDestination == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _t3(
              context,
              ar: 'ما قدرنا نلاقي فنادق في مدينة الوصول ($destination) -- جرب رحلة لوجهة ثانية',
              en: 'We couldn\'t find hotels in the arrival city ($destination) — try a different destination',
              es: 'No encontramos hoteles en la ciudad de llegada ($destination): prueba otro destino',
              tr: 'Varış şehrinde ($destination) otel bulamadık — farklı bir varış noktası deneyin',
              id: 'Kami tidak menemukan hotel di kota kedatangan ($destination) — coba tujuan lain',
              hi: 'हमें आगमन शहर ($destination) में होटल नहीं मिले — कोई अन्य गंतव्य आज़माएँ',
              ur: 'ہمیں آمد کے شہر ($destination) میں ہوٹل نہیں ملے — کوئی اور منزل آزمائیں',
              fr: 'Nous n\'avons pas trouvé d\'hôtels dans la ville d\'arrivée ($destination) — essayez une autre destination',
              bn: 'আমরা আগমন শহরে ($destination) হোটেল খুঁজে পাইনি — অন্য গন্তব্য চেষ্টা করুন',
            ),
          ),
          duration: const Duration(seconds: 4),
        ),
      );
      return;
    }

    ref.read(flightHotelSelectionProvider.notifier).state = (offer: null, hotel: null);
    setState(() {
      _searchParams = {
        'destinationCode': _selectedDestination!.code,
        'cityLabel': _selectedDestination!.name,
        'checkIn': _checkIn,
        'checkOut': _checkOut,
        'guests': _guests,
      };
      _flightSearchParams = {
        'origin': origin,
        'destination': destination,
        'departureDate': _checkIn,
        'travelers': _guests,
        'cabinClass': 'Economy',
        'nonstopOnly': false,
      };
    });
  }

  /// شريط ملخّص مصغّر لبحث الطيران (Origin → Destination · التاريخ ·
  /// عدد المسافرين) بيظهر بدل فورم البحث الكامل بعد ما يحصل بحث فعلي،
  /// عشان يوفّر مساحة رأسية أكبر لعرض النتائج. زرار "تعديل" بيرجّع
  /// الفورم الكامل تاني (_flightFormExpanded = true).
  Widget _buildCollapsedFlightBar() {
    final params = _flightSearchParams!;
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    final date = params['departureDate'] as DateTime;
    final dateLabel = '${months[date.month - 1]} ${date.day}';
    return Container(
      margin: const EdgeInsets.all(AppSizes.md),
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.md, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.primaryDark,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        children: [
          const Icon(Icons.flight_takeoff, color: Colors.white70, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '${params['origin']} → ${params['destination']} · $dateLabel · ${params['travelers']}',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          TextButton.icon(
            onPressed: () => setState(() => _flightFormExpanded = true),
            icon: const Icon(Icons.edit, size: 16, color: Colors.white),
            label: Text(
              _t3(context, ar: 'تعديل', en: 'Edit', es: 'Editar', tr: 'Düzenle',
                  id: 'Edit', hi: 'संपादित करें', ur: 'ترمیم کریں', fr: 'Modifier', bn: 'সম্পাদনা করুন'),
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _runCarRentalSearch() {
    final pickupCity = _carPickupController.text.trim();
    if (pickupCity.isEmpty) return;
    final now = DateTime.now();
    setState(() {
      _carSearchParams = {
        'pickupCity': pickupCity,
        'pickupDate': _carDateRange?.start ?? now.add(const Duration(days: 1)),
        'dropoffDate': _carDateRange?.end ?? now.add(const Duration(days: 4)),
      };
    });
  }

  Future<void> _pickCarDateRange() async {
    final now = DateTime.now();
    final position = _datePopoverPosition(_carDateFieldKey);
    final range = await showDateRangePicker(
      context: context,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
      initialDateRange: _carDateRange ??
          DateTimeRange(
            start: now.add(const Duration(days: 1)),
            end: now.add(const Duration(days: 4)),
          ),
      builder: (context, child) => _datePopoverBuilder(position, child),
    );
    if (range != null) setState(() => _carDateRange = range);
  }

  String get _carDateRangeLabel {
    if (_carDateRange == null) return 'Dates';
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    final s = _carDateRange!.start;
    final e = _carDateRange!.end;
    return '${months[s.month - 1]} ${s.day} - ${months[e.month - 1]} ${e.day}';
  }

  void _swapFlightLocations() {
    setState(() {
      final temp = _flightFromController.text;
      _flightFromController.text = _flightToController.text;
      _flightToController.text = temp;
    });
  }

  Future<void> _pickFlightDateRange() async {
    final now = DateTime.now();
    final position = _datePopoverPosition(_flightDateFieldKey);
    final range = await showDateRangePicker(
      context: context,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
      initialDateRange: _flightDateRange ??
          DateTimeRange(
            start: now.add(const Duration(days: 14)),
            end: now.add(const Duration(days: 21)),
          ),
      builder: (context, child) => _datePopoverBuilder(position, child),
    );
    if (range != null) setState(() => _flightDateRange = range);
  }

  String get _flightDateRangeLabel {
    if (_flightDateRange == null) return 'Dates';
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    final s = _flightDateRange!.start;
    final e = _flightDateRange!.end;
    return '${months[s.month - 1]} ${s.day} - ${months[e.month - 1]} ${e.day}';
  }

  Future<void> _pickFlightTravelers() async {
    await showModalBottomSheet(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: const EdgeInsets.all(AppSizes.md),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Travelers',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Travelers'),
                      Row(
                        children: [
                          IconButton(
                            onPressed: _flightTravelers > 1
                                ? () => setSheetState(() => setState(() => _flightTravelers--))
                                : null,
                            icon: const Icon(Icons.remove_circle_outline),
                          ),
                          Text('$_flightTravelers'),
                          IconButton(
                            onPressed: () =>
                                setSheetState(() => setState(() => _flightTravelers++)),
                            icon: const Icon(Icons.add_circle_outline),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSizes.sm),
                  const Text(
                    'Cabin class',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  Wrap(
                    spacing: 8,
                    children: ['Economy', 'Premium Economy', 'Business', 'First']
                        .map(
                          (c) => ChoiceChip(
                        label: Text(c),
                        selected: _flightCabinClass == c,
                        onSelected: (_) =>
                            setSheetState(() => setState(() => _flightCabinClass = c)),
                      ),
                    )
                        .toList(),
                  ),
                  const SizedBox(height: AppSizes.md),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Done'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  /// يُستدعى عند الضغط على وجهة من قسم "وجهات رائجة"، فيدوّر عن كود
  /// الوجهة المطابق في hotelbeds_destinations وينفّذ البحث مباشرة.
  Future<void> _selectDestination(String city) async {
    _cityController.text = city;
    final repo = ref.read(hotelRepositoryProvider);
    final result = await repo.searchDestinations(city);
    if (!mounted) return;
    result.when(
      success: (list) {
        if (list.isEmpty) return;
        setState(() => _selectedDestination = list.first);
        _runSearch();
      },
      failure: (_) {},
    );
  }

  /// يحسب مكان ظهور نافذة التاريخ أسفل الحقل اللي اتضغط عليه مباشرة،
  /// بدل ما تظهر في نص الشاشة.
  Offset _datePopoverPosition(GlobalKey fieldKey, {double width = 380, double height = 560}) {
    final box = fieldKey.currentContext?.findRenderObject() as RenderBox?;
    final overlayBox = Overlay.of(context).context.findRenderObject() as RenderBox?;
    if (box == null || overlayBox == null) {
      return const Offset(24, 100);
    }
    final fieldPosition = box.localToGlobal(Offset.zero, ancestor: overlayBox);
    final screenSize = overlayBox.size;
    var left = fieldPosition.dx;
    var top = fieldPosition.dy + box.size.height + 48;
    if (left + width > screenSize.width) {
      left = screenSize.width - width - 16;
    }
    if (left < 0) left = 16;
    if (top + height > screenSize.height) {
      top = screenSize.height - height - 16;
    }
    if (top < 0) top = 16;
    return Offset(left, top);
  }

  Widget _datePopoverBuilder(Offset position, Widget? child, {double width = 380, double height = 560}) {
    return Stack(
      children: [
        Positioned(
          left: position.dx,
          top: position.dy,
          child: Material(
            elevation: 8,
            borderRadius: BorderRadius.circular(16),
            clipBehavior: Clip.antiAlias,
            child: SizedBox(width: width, height: height, child: child),
          ),
        ),
      ],
    );
  }

  Future<void> _pickDateRange([GlobalKey? fieldKey]) async {
    final position = _datePopoverPosition(fieldKey ?? _dateFieldKey);
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDateRange: DateTimeRange(start: _checkIn, end: _checkOut),
      builder: (context, child) => _datePopoverBuilder(position, child),
    );
    if (range != null) {
      setState(() {
        _checkIn = range.start;
        _checkOut = range.end;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // القسم العلوي (فورم البحث) بحجم ثابت وتحته Expanded لقائمة النتائج.
      // بدون هذا السطر، فتح لوحة المفاتيح يضغط الشاشة فيحاول الـ Expanded
      // ينضغط لصفر بينما فورم البحث الثابت ما بينضغط، فيصير Overflow.
      // منع تصغير الشاشة هون بيخلي الكيبورد يغطي قائمة النتائج بالأسفل
      // فقط (مو مشكلة، المستخدم مركّز بالكتابة بالحقل أصلاً) بدل ما يكسر التخطيط.
      resizeToAvoidBottomInset: false,
      appBar: AppBanner(
        activeTab: _activeTab,
        assetVariant: _activeTab == 'flights'
            ? 'flights'
            : _activeTab == 'carRental'
            ? 'car_rental'
            : _activeTab == 'flightHotel'
            ? 'flight_hotel'
            : null,
        collapsed: _activeTab == 'flights'
            ? _flightSearchParams != null
            : _activeTab == 'carRental'
            ? _carSearchParams != null
            : _activeTab == 'flightHotel'
            ? (_searchParams != null && _flightSearchParams != null)
            : _searchParams != null,
        tabsBar: _TravelTabsBar(
          selectedTab: _activeTab,
          onTabSelected: (id) => setState(() => _activeTab = id),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          border: Border(
            left: BorderSide(color: AppColors.primaryDark, width: 4),
            right: BorderSide(color: AppColors.primaryDark, width: 4),
            bottom: BorderSide(color: AppColors.primaryDark, width: 4),
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              (_activeTab == 'flights' && _flightSearchParams != null && !_flightFormExpanded)
                  ? _buildCollapsedFlightBar()
                  : Padding(
                padding: const EdgeInsets.all(AppSizes.md),
                child: SizedBox(
                  width: double.infinity,
                  child: Stack(
                    children: [
                      Offstage(
                        offstage: _activeTab != 'stays',
                        child: _buildStaysSearchBox(),
                      ),
                      Offstage(
                        offstage: _activeTab != 'flights',
                        child: _buildFlightsSearchBox(),
                      ),
                      Offstage(
                        offstage: _activeTab != 'flightHotel',
                        child: _buildFlightHotelSearchBox(),
                      ),
                      Offstage(
                        offstage: _activeTab != 'carRental',
                        child: _buildCarRentalSearchBox(),
                      ),
                    ],
                  ),
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: _activeTab == 'flights'
                    ? (_flightSearchParams == null
                    ? ListView(
                  padding: const EdgeInsets.all(AppSizes.md),
                  children: [
                    UsDestinationsSection(
                      onDestinationTap: (origin, destination) {
                        _flightFromController.text = origin;
                        _flightToController.text = destination;
                        _runFlightSearch();
                      },
                    ),
                    const SizedBox(height: AppSizes.md),
                    const _TrustSection(),
                    const AppFooter(),
                  ],
                )
                    : Column(
                  children: [
                    FlightDatePriceStrip(
                      origin: _flightSearchParams!['origin'] as String,
                      destination: _flightSearchParams!['destination'] as String,
                      centerDate: _flightSearchParams!['departureDate'] as DateTime,
                      selectedDate: _flightSearchParams!['departureDate'] as DateTime,
                      travelers: _flightSearchParams!['travelers'] as int,
                      cabinClass: _flightSearchParams!['cabinClass'] as String,
                      nonstopOnly: _flightSearchParams!['nonstopOnly'] as bool,
                      onDateSelected: (date) {
                        setState(() {
                          _flightSearchParams = {
                            ..._flightSearchParams!,
                            'departureDate': date,
                          };
                        });
                      },
                    ),
                    const Divider(height: 1),
                    Expanded(
                      child: _DuffelFlightSearchResults(params: _flightSearchParams!),
                    ),
                  ],
                ))
                    : _activeTab == 'carRental'
                    ? (_carSearchParams == null
                    ? ListView(
                  padding: const EdgeInsets.all(AppSizes.md),
                  children: const [_CarTrustSection(), AppFooter()],
                )
                    : _CarSearchResults(params: _carSearchParams!))
                    : _activeTab == 'flightHotel'
                    ? ((_searchParams == null || _flightSearchParams == null)
                    ? ListView(
                  padding: const EdgeInsets.all(AppSizes.md),
                  children: const [_TrustSection(), AppFooter()],
                )
                    : _FlightHotelSearchResults(
                  flightParams: _flightSearchParams!,
                  hotelParams: _searchParams!,
                ))
                    : (_searchParams == null
                    ? ListView(
                  children: [
                    TrendingDestinations(onSelected: _selectDestination),
                    const DealsSection(),
                    AccommodationTypesSection(
                      onTypeSelected: _onAccommodationTypeSelected,
                      selectedType: _selectedAccommodationType,
                    ),
                    if (_selectedAccommodationType != null)
                      AccommodationPreviewSection(selectedType: _selectedAccommodationType!),
                    const FeaturedHotelsSection(),
                    const FaqSection(),
                    const AppFooter(),
                  ],
                )
                    : _SearchResults(params: _searchParams!)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStaysSearchBox() {
    final l10n = AppLocalizations.of(context)!;
    final nights = _checkOut.difference(_checkIn).inDays;
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    final datesLabel =
        '${months[_checkIn.month - 1]} ${_checkIn.day} - ${months[_checkOut.month - 1]} ${_checkOut.day}';

    return Container(
      padding: const EdgeInsets.all(AppSizes.sm),
      decoration: BoxDecoration(
        color: AppColors.primaryDark,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primaryDark, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const SizedBox(width: 4),
              const Icon(Icons.location_on_outlined, size: 20, color: Colors.white70),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _cityController,
                  style: const TextStyle(color: Colors.black87),
                  decoration: InputDecoration(
                    hintText: l10n.whereTo,
                    hintStyle: const TextStyle(color: Colors.black45),
                    border: InputBorder.none,
                    isDense: true,
                  ),
                  onChanged: _onCityTextChanged,
                  onSubmitted: (_) => _runSearch(),
                  onTap: () {
                    if (_cityController.text.trim().isEmpty) _openCountryBrowser();
                  },
                ),
              ),
              IconButton(
                onPressed: _openCountryBrowser,
                icon: const Icon(Icons.public, color: Colors.white70, size: 20),
                tooltip: _t3(context, ar: 'تصفّح حسب الدولة', en: 'Browse by country', es: 'Explorar por país', tr: 'Ülkeye göre gözat', id: 'Jelajahi berdasarkan negara',
                    hi: 'देश के अनुसार ब्राउज़ करें',
                    ur: 'ملک کے مطابق دیکھیں',
                    fr: 'Parcourir par pays',
                    bn: 'দেশ অনুযায়ী ব্রাউজ করুন'),
              ),
            ],
          ),
          if (_destinationSuggestions.isNotEmpty) ...[
            const SizedBox(height: 6),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              constraints: const BoxConstraints(maxHeight: 220),
              child: ListView.builder(
                shrinkWrap: true,
                padding: EdgeInsets.zero,
                itemCount: _destinationSuggestions.length,
                itemBuilder: (context, index) {
                  final d = _destinationSuggestions[index];
                  return ListTile(
                    dense: true,
                    leading: const Icon(Icons.place_outlined, size: 18),
                    title: Text(d.name),
                    subtitle: d.countryCode != null ? Text(d.countryCode!) : null,
                    onTap: () => _selectDestinationSuggestion(d),
                  );
                },
              ),
            ),
          ],
          const Divider(height: 16),
          Wrap(
            spacing: 16,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              GestureDetector(
                key: _dateFieldKey,
                behavior: HitTestBehavior.opaque,
                onTap: _pickDateRange,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF87CEEB),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.calendar_today_outlined, size: 18, color: Colors.white70),
                      const SizedBox(width: 6),
                      Text(datesLabel, style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.white)),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFF87CEEB),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white38),
                        ),
                        child: Text(
                          nights == 1
                              ? (_t3(context, ar: 'ليلة واحدة', en: '1 night', es: '1 noche', tr: '1 gece', id: '1 malam',
                              hi: '1 रात',
                              ur: '1 رات',
                              fr: '1 nuit',
                              bn: '১ রাত'))
                              : (_t3(context, ar: '$nights ليالٍ', en: '$nights nights', es: '$nights noches', tr: '$nights gece', id: '$nights malam',
                              hi: '$nights रातें',
                              ur: '$nights راتیں',
                              fr: '$nights nuits',
                              bn: '$nights রাত')),
                          style: const TextStyle(fontSize: 12, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 16),
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () async {
                  await showModalBottomSheet(
                    context: context,
                    builder: (context) {
                      return StatefulBuilder(
                        builder: (context, setSheetState) {
                          return Padding(
                            padding: const EdgeInsets.all(AppSizes.md),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _t3(context, ar: 'الضيوف', en: 'Guests', es: 'Huéspedes', tr: 'Misafirler', id: 'Tamu',
                                      hi: 'मेहमान',
                                      ur: 'مہمان',
                                      fr: 'Voyageurs',
                                      bn: 'অতিথি'),
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                ),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(l10n.guests),
                                    Row(
                                      children: [
                                        IconButton(
                                          onPressed: _guests > 1
                                              ? () => setSheetState(() => setState(() => _guests--))
                                              : null,
                                          icon: const Icon(Icons.remove_circle_outline),
                                        ),
                                        Text('$_guests'),
                                        IconButton(
                                          onPressed: () =>
                                              setSheetState(() => setState(() => _guests++)),
                                          icon: const Icon(Icons.add_circle_outline),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                const SizedBox(height: AppSizes.md),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    onPressed: () => Navigator.of(context).pop(),
                                    child: Text(_t3(context, ar: 'تم', en: 'Done', es: 'Listo', tr: 'Tamam', id: 'Selesai',
                                        hi: 'हो गया',
                                        ur: 'ہو گیا',
                                        fr: 'Terminé',
                                        bn: 'সম্পন্ন')),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF87CEEB),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.people_outline, size: 18, color: Colors.white70),
                      const SizedBox(width: 6),
                      Text(
                        _t3(
                          context,
                          ar: 'غرفة واحدة، $_guests ضيوف',
                          en: '1 room, $_guests ${_guests == 1 ? 'adult' : 'adults'}',
                          es: '1 habitación, $_guests ${_guests == 1 ? 'adulto' : 'adultos'}',
                          tr: '1 oda, $_guests yetişkin',
                          id: '1 kamar, $_guests dewasa',
                          hi: '1 कमरा, $_guests वयस्क',
                          ur: '1 کمرہ, $_guests بالغ',
                          fr: '1 chambre, $_guests ${_guests == 1 ? 'adulte' : 'adultes'}',
                          bn: '১টি রুম, $_guests জন প্রাপ্তবয়স্ক',
                        ),
                        style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ),
              ElevatedButton.icon(
                onPressed: _runSearch,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF87CEEB),
                  foregroundColor: Colors.white,
                  shape: const StadiumBorder(),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
                icon: const Icon(Icons.search, size: 18),
                label: Text(l10n.search),
              ),
            ],
          ),
        ],
      ),
    );
  }


  Widget _buildFlightsSearchBox() {

    final tripTypeLabels = <String, String>{
      'roundtrip': _t3(context, ar: 'ذهاب وعودة', en: 'Roundtrip', es: 'Ida y vuelta', tr: 'Gidiş-dönüş', id: 'Pulang-pergi',
          hi: 'राउंड ट्रिप',
          ur: 'راؤنڈ ٹرپ',
          fr: 'Aller-retour',
          bn: 'রাউন্ডট্রিপ'),
      'oneWay': _t3(context, ar: 'ذهاب فقط', en: 'One-way', es: 'Solo ida', tr: 'Tek yön', id: 'Sekali jalan',
          hi: 'एक तरफ़ा',
          ur: 'یک طرفہ',
          fr: 'Aller simple',
          bn: 'একমুখী'),
      'multiCity': _t3(context, ar: 'وجهات متعددة', en: 'Multi-city', es: 'Multidestino', tr: 'Çoklu şehir', id: 'Multi-kota',
          hi: 'मल्टी-सिटी',
          ur: 'ملٹی سٹی',
          fr: 'Multi-destinations',
          bn: 'একাধিক শহর'),
    };

    final travelersLabel =
        '$_flightTravelers ${_flightTravelers == 1 ? (_t3(context, ar: "مسافر", en: "traveler", es: "viajero", tr: "yolcu", id: "wisatawan",
        hi: "यात्री",
        ur: "مسافر",
        fr: "voyageur",
        bn: "ভ্রমণকারী")) : (_t3(context, ar: "مسافرين", en: "travelers", es: "viajeros", tr: "yolcu", id: "wisatawan",
        hi: "यात्री",
        ur: "مسافر",
        fr: "voyageurs",
        bn: "ভ্রমণকারী"))}, $_flightCabinClass';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            ...tripTypeLabels.entries.map((entry) {
              final isSelected = _flightTripType == entry.key;
              return Padding(
                padding: const EdgeInsetsDirectional.only(end: AppSizes.lg),
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => setState(() => _flightTripType = entry.key),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Text(
                          entry.value,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: isSelected ? AppColors.primary : Colors.black87,
                          ),
                        ),
                      ),
                      Container(
                        height: 2,
                        width: 60,
                        color: isSelected ? AppColors.primary : Colors.transparent,
                      ),
                    ],
                  ),
                ),
              );
            }),
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => setState(() => _nonstopOnly = !_nonstopOnly),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Checkbox(
                    value: _nonstopOnly,
                    onChanged: (v) => setState(() => _nonstopOnly = v ?? false),
                  ),
                  Text(
                    _t3(context, ar: 'بدون توقف', en: 'Nonstop', es: 'Sin escalas', tr: 'Aktarmasız', id: 'Tanpa transit',
                        hi: 'बिना रुके',
                        ur: 'بلا رکاوٹ',
                        fr: 'Sans escale',
                        bn: 'সরাসরি'),
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSizes.md),

        Container(
          padding: const EdgeInsets.all(AppSizes.sm),
          decoration: BoxDecoration(
            color: AppColors.primaryDark,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.primaryDark, width: 2),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const SizedBox(width: 4),
                  const Icon(Icons.flight_takeoff, size: 18, color: Colors.white70),
                  const SizedBox(width: 6),
                  Expanded(
                    child: TextField(
                      controller: _flightFromController,
                      style: const TextStyle(color: Colors.black87),
                      decoration: InputDecoration(
                        hintText: _t3(context, ar: 'المغادرة من', en: 'Leaving from', es: 'Saliendo de', tr: 'Nereden', id: 'Dari',
                            hi: 'यहाँ से रवाना',
                            ur: 'یہاں سے روانگی',
                            fr: 'Départ de',
                            bn: 'যেখান থেকে যাত্রা'),
                        hintStyle: const TextStyle(color: Colors.black45),
                        border: InputBorder.none,
                        isDense: true,
                      ),
                    ),
                  ),
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: _swapFlightLocations,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white24),
                      ),
                      child: const Icon(Icons.swap_horiz, size: 16, color: Colors.white),
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Icon(Icons.flight_land, size: 18, color: Colors.white70),
                  const SizedBox(width: 6),
                  Expanded(
                    child: TextField(
                      controller: _flightToController,
                      style: const TextStyle(color: Colors.black87),
                      decoration: InputDecoration(
                        hintText: _t3(context, ar: 'الوجهة', en: 'Going to', es: 'A dónde', tr: 'Nereye', id: 'Ke',
                            hi: 'यहाँ जाना है',
                            ur: 'کہاں جانا ہے',
                            fr: 'Destination',
                            bn: 'যেখানে যাচ্ছেন'),
                        hintStyle: const TextStyle(color: Colors.black45),
                        border: InputBorder.none,
                        isDense: true,
                      ),
                    ),
                  ),
                ],
              ),
              const Divider(height: 16),
              Wrap(
                spacing: 16,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  GestureDetector(
                    key: _flightDateFieldKey,
                    behavior: HitTestBehavior.opaque,
                    onTap: _pickFlightDateRange,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.calendar_today_outlined, size: 16, color: Colors.white70),
                        const SizedBox(width: 6),
                        Text(
                          _flightDateRangeLabel,
                          style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: _pickFlightTravelers,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.person_outline, size: 16, color: Colors.white70),
                        const SizedBox(width: 6),
                        Text(
                          travelersLabel,
                          style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: _runFlightSearch,
                    style: ElevatedButton.styleFrom(
                      shape: const StadiumBorder(),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    ),
                    icon: const Icon(Icons.search, size: 18),
                    label: Text(_t3(context, ar: 'بحث', en: 'Search', es: 'Buscar', tr: 'Ara', id: 'Cari',
                        hi: 'खोजें',
                        ur: 'تلاش کریں',
                        fr: 'Rechercher',
                        bn: 'অনুসন্ধান করুন')),
                  ),
                ],
              ),
            ],
          ),
        ),


        const SizedBox(height: AppSizes.sm),
        Row(
          children: [
            Checkbox(
              value: _addStay,
              onChanged: (v) => setState(() => _addStay = v ?? false),
            ),
            Text(_t3(context, ar: 'أضف مكان إقامة', en: 'Add a place to stay', es: 'Añadir alojamiento', tr: 'Konaklama ekle', id: 'Tambahkan penginapan',
                hi: 'ठहरने की जगह जोड़ें',
                ur: 'قیام کی جگہ شامل کریں',
                fr: 'Ajouter un hébergement',
                bn: 'থাকার জায়গা যোগ করুন')),
            const SizedBox(width: AppSizes.md),
            Checkbox(
              value: _addCar,
              onChanged: (v) => setState(() => _addCar = v ?? false),
            ),
            Text(_t3(context, ar: 'أضف سيارة', en: 'Add a car', es: 'Añadir un coche', tr: 'Araç ekle', id: 'Tambahkan mobil',
                hi: 'कार जोड़ें',
                ur: 'کار شامل کریں',
                fr: 'Ajouter une voiture',
                bn: 'গাড়ি যোগ করুন')),
          ],
        ),
      ],
    );
  }

  /// نموذج بحث موحّد: صف الرحلة (From/To)، صف الفندق (المدينة)، ثم
  /// التواريخ + الضيوف + زر بحث واحد. البحث الفعلي بيشغّل بحث الرحلة
  /// وبحث الفندق مع بعض، وبيعرض نتائج الاثنين في نفس الصفحة.
  Widget _buildFlightHotelSearchBox() {
    final l10n = AppLocalizations.of(context)!;
    final nights = _checkOut.difference(_checkIn).inDays;
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    final datesLabel =
        '${months[_checkIn.month - 1]} ${_checkIn.day} - ${months[_checkOut.month - 1]} ${_checkOut.day}';

    return Container(
      padding: const EdgeInsets.all(AppSizes.sm),
      decoration: BoxDecoration(
        color: AppColors.primaryDark,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primaryDark, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.flight_takeoff, size: 18, color: Colors.white70),
              const SizedBox(width: 6),
              Expanded(
                child: TextField(
                  controller: _flightFromController,
                  style: const TextStyle(color: Colors.black87),
                  decoration: InputDecoration(
                    hintText: _t3(context, ar: 'المغادرة من', en: 'Leaving from', es: 'Saliendo de', tr: 'Nereden', id: 'Dari',
                        hi: 'यहाँ से रवाना',
                        ur: 'یہاں سے روانگی',
                        fr: 'Départ de',
                        bn: 'যেখান থেকে যাত্রা'),
                    hintStyle: const TextStyle(color: Colors.black45),
                    border: InputBorder.none,
                    isDense: true,
                  ),
                ),
              ),
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _swapFlightLocations,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white24),
                  ),
                  child: const Icon(Icons.swap_horiz, size: 16, color: Colors.white),
                ),
              ),
              const SizedBox(width: 6),
              const Icon(Icons.flight_land, size: 18, color: Colors.white70),
              const SizedBox(width: 6),
              Expanded(
                child: TextField(
                  controller: _flightToController,
                  style: const TextStyle(color: Colors.black87),
                  decoration: InputDecoration(
                    hintText: _t3(context, ar: 'الوجهة', en: 'Going to', es: 'A dónde', tr: 'Nereye', id: 'Ke',
                        hi: 'यहाँ जाना है',
                        ur: 'کہاں جانا ہے',
                        fr: 'Destination',
                        bn: 'যেখানে যাচ্ছেন'),
                    hintStyle: const TextStyle(color: Colors.black45),
                    border: InputBorder.none,
                    isDense: true,
                  ),
                ),
              ),
            ],
          ),
          const Divider(height: 16),
          Row(
            children: [
              const Icon(Icons.hotel_outlined, size: 20, color: Colors.white70),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _cityController,
                  style: const TextStyle(color: Colors.black87),
                  decoration: InputDecoration(
                    hintText: _t3(context, ar: 'أين تقيم؟ (المدينة)', en: 'Stay in? (City)', es: '¿Dónde te alojas? (Ciudad)', tr: 'Nerede kalıyorsunuz? (Şehir)', id: 'Menginap di? (Kota)',
                        hi: 'कहाँ ठहरना है? (शहर)',
                        ur: 'کہاں ٹھہرنا ہے؟ (شہر)',
                        fr: 'Séjour à ? (Ville)',
                        bn: 'কোথায় থাকবেন? (শহর)'),
                    hintStyle: const TextStyle(color: Colors.black45),
                    border: InputBorder.none,
                    isDense: true,
                  ),
                  onChanged: _onCityTextChanged,
                  onSubmitted: (_) => _runFlightHotelSearch(),
                  onTap: () {
                    if (_cityController.text.trim().isEmpty) _openCountryBrowser();
                  },
                ),
              ),
              IconButton(
                onPressed: _openCountryBrowser,
                icon: const Icon(Icons.public, color: Colors.white70, size: 20),
                tooltip: _t3(context, ar: 'تصفّح حسب الدولة', en: 'Browse by country', es: 'Explorar por país', tr: 'Ülkeye göre gözat', id: 'Jelajahi berdasarkan negara',
                    hi: 'देश के अनुसार ब्राउज़ करें',
                    ur: 'ملک کے مطابق دیکھیں',
                    fr: 'Parcourir par pays',
                    bn: 'দেশ অনুযায়ী ব্রাউজ করুন'),
              ),
            ],
          ),
          if (_destinationSuggestions.isNotEmpty) ...[
            const SizedBox(height: 6),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              constraints: const BoxConstraints(maxHeight: 220),
              child: ListView.builder(
                shrinkWrap: true,
                padding: EdgeInsets.zero,
                itemCount: _destinationSuggestions.length,
                itemBuilder: (context, index) {
                  final d = _destinationSuggestions[index];
                  return ListTile(
                    dense: true,
                    leading: const Icon(Icons.place_outlined, size: 18),
                    title: Text(d.name),
                    subtitle: d.countryCode != null ? Text(d.countryCode!) : null,
                    onTap: () => _selectDestinationSuggestion(d),
                  );
                },
              ),
            ),
          ],
          const Divider(height: 16),
          Wrap(
            spacing: 16,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              GestureDetector(
                key: _flightHotelDateFieldKey,
                behavior: HitTestBehavior.opaque,
                onTap: () => _pickDateRange(_flightHotelDateFieldKey),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.calendar_today_outlined, size: 18, color: Colors.white70),
                    const SizedBox(width: 6),
                    Text(datesLabel, style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.white)),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        nights == 1
                            ? (_t3(context, ar: 'ليلة واحدة', en: '1 night', es: '1 noche', tr: '1 gece', id: '1 malam',
                            hi: '1 रात',
                            ur: '1 رات',
                            fr: '1 nuit',
                            bn: '১ রাত'))
                            : (_t3(context, ar: '$nights ليالٍ', en: '$nights nights', es: '$nights noches', tr: '$nights gece', id: '$nights malam',
                            hi: '$nights रातें',
                            ur: '$nights راتیں',
                            fr: '$nights nuits',
                            bn: '$nights রাত')),
                        style: const TextStyle(fontSize: 12, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () async {
                  await showModalBottomSheet(
                    context: context,
                    builder: (context) {
                      return StatefulBuilder(
                        builder: (context, setSheetState) {
                          return Padding(
                            padding: const EdgeInsets.all(AppSizes.md),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _t3(context, ar: 'الضيوف', en: 'Guests', es: 'Huéspedes', tr: 'Misafirler', id: 'Tamu',
                                      hi: 'मेहमान',
                                      ur: 'مہمان',
                                      fr: 'Voyageurs',
                                      bn: 'অতিথি'),
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                ),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(l10n.guests),
                                    Row(
                                      children: [
                                        IconButton(
                                          onPressed: _guests > 1
                                              ? () => setSheetState(() => setState(() => _guests--))
                                              : null,
                                          icon: const Icon(Icons.remove_circle_outline),
                                        ),
                                        Text('$_guests'),
                                        IconButton(
                                          onPressed: () =>
                                              setSheetState(() => setState(() => _guests++)),
                                          icon: const Icon(Icons.add_circle_outline),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                const SizedBox(height: AppSizes.md),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    onPressed: () => Navigator.of(context).pop(),
                                    child: Text(_t3(context, ar: 'تم', en: 'Done', es: 'Listo', tr: 'Tamam', id: 'Selesai',
                                        hi: 'हो गया',
                                        ur: 'ہو گیا',
                                        fr: 'Terminé',
                                        bn: 'সম্পন্ন')),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  );
                },
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.people_outline, size: 18, color: Colors.white70),
                    const SizedBox(width: 6),
                    Text(
                      _t3(
                        context,
                        ar: 'غرفة واحدة، $_guests ضيوف',
                        en: '1 room, $_guests ${_guests == 1 ? 'adult' : 'adults'}',
                        es: '1 habitación, $_guests ${_guests == 1 ? 'adulto' : 'adultos'}',
                        tr: '1 oda, $_guests yetişkin',
                        id: '1 kamar, $_guests dewasa',
                        hi: '1 कमरा, $_guests वयस्क',
                        ur: '1 کمرہ, $_guests بالغ',
                        fr: '1 chambre, $_guests ${_guests == 1 ? 'adulte' : 'adultes'}',
                        bn: '১টি রুম, $_guests জন প্রাপ্তবয়স্ক',
                      ),
                      style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.white),
                    ),
                  ],
                ),
              ),
              ElevatedButton.icon(
                onPressed: _runFlightHotelSearch,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF8FB8D6),
                  foregroundColor: Colors.white,
                  shape: const StadiumBorder(),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
                icon: const Icon(Icons.search, size: 18),
                label: Text(l10n.search),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// نموذج بحث تأجير السيارات: مكان الاستلام (+ مكان تسليم مختلف اختياري)،
  /// نطاق التاريخ، وزر بحث. البحث الفعلي لسه "قريبًا" (مفيش API مربوط بعد).
  Widget _buildCarRentalSearchBox() {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      padding: const EdgeInsets.all(AppSizes.sm),
      decoration: BoxDecoration(
        color: AppColors.primaryDark,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primaryDark, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const SizedBox(width: 4),
              const Icon(Icons.directions_car_filled_outlined, size: 20, color: Colors.white70),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _carPickupController,
                  style: const TextStyle(color: Colors.black87),
                  decoration: InputDecoration(
                    hintText: _t3(context, ar: 'مكان الاستلام', en: 'Pick-up location', es: 'Lugar de recogida', tr: 'Alış noktası', id: 'Lokasi pengambilan',
                        hi: 'पिक-अप स्थान',
                        ur: 'پک اپ مقام',
                        fr: 'Lieu de prise en charge',
                        bn: 'পিকআপ স্থান'),
                    hintStyle: const TextStyle(color: Colors.black45),
                    border: InputBorder.none,
                    isDense: true,
                  ),
                  onSubmitted: (_) => _runCarRentalSearch(),
                ),
              ),
            ],
          ),
          const Divider(height: 16),
          Row(
            children: [
              Checkbox(
                value: _carDifferentDropoff,
                onChanged: (v) => setState(() => _carDifferentDropoff = v ?? false),
              ),
              Text(
                _t3(context, ar: 'مكان تسليم مختلف', en: 'Different drop-off location', es: 'Lugar de devolución diferente', tr: 'Farklı bir teslim noktası', id: 'Lokasi pengembalian berbeda',
                    hi: 'अलग ड्रॉप-ऑफ स्थान',
                    ur: 'مختلف ڈراپ آف مقام',
                    fr: 'Lieu de restitution différent',
                    bn: 'ভিন্ন ড্রপ-অফ স্থান'),
                style: const TextStyle(color: Colors.white),
              ),
            ],
          ),
          if (_carDifferentDropoff) ...[
            Row(
              children: [
                const SizedBox(width: 4),
                const Icon(Icons.location_on_outlined, size: 20, color: Colors.white70),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _carDropoffController,
                    style: const TextStyle(color: Colors.black87),
                    decoration: InputDecoration(
                      hintText: _t3(context, ar: 'مكان التسليم', en: 'Drop-off location', es: 'Lugar de devolución', tr: 'Teslim noktası', id: 'Lokasi pengembalian',
                          hi: 'ड्रॉप-ऑफ स्थान',
                          ur: 'ڈراپ آف مقام',
                          fr: 'Lieu de restitution',
                          bn: 'ড্রপ-অফ স্থান'),
                      hintStyle: const TextStyle(color: Colors.black45),
                      border: InputBorder.none,
                      isDense: true,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 16),
          ],
          Wrap(
            spacing: 16,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              GestureDetector(
                key: _carDateFieldKey,
                behavior: HitTestBehavior.opaque,
                onTap: _pickCarDateRange,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.calendar_today_outlined, size: 18, color: Colors.white70),
                    const SizedBox(width: 6),
                    Text(_carDateRangeLabel, style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.white)),
                  ],
                ),
              ),
              ElevatedButton.icon(
                onPressed: _runCarRentalSearch,
                style: ElevatedButton.styleFrom(
                  shape: const StadiumBorder(),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
                icon: const Icon(Icons.search, size: 18),
                label: Text(l10n.search),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SearchResults extends ConsumerWidget {
  final Map<String, dynamic> params;
  const _SearchResults({required this.params});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final resultsAsync = ref.watch(searchResultsProvider(params));

    return resultsAsync.when(
      loading: () => LoadingView(message: l10n.searching),
      error: (error, _) => ErrorView(
        message: l10n.errorLoadResults,
        onRetry: () => ref.invalidate(searchResultsProvider(params)),
      ),
      data: (hotels) {
        final activeFilters = ref.watch(hotelFiltersProvider);
        final filteredHotels = applyHotelFilters(hotels, activeFilters);

        final resultsList = filteredHotels.isEmpty
            ? ListView(
          children: [
            EmptyView(
              message: hotels.isEmpty
                  ? l10n.noResults
                  : _t3(
                context,
                ar: 'لا توجد فنادق مطابقة للفلاتر المختارة',
                en: 'No hotels match the selected filters',
                es: 'Ningún hotel coincide con los filtros seleccionados',
                tr: 'Seçilen filtrelere uygun otel yok',
                id: 'Tidak ada hotel yang cocok dengan filter yang dipilih',
                hi: 'चुने गए फ़िल्टर से कोई होटल मेल नहीं खाता',
                ur: 'منتخب فلٹرز سے کوئی ہوٹل مماثل نہیں',
                fr: 'Aucun hôtel ne correspond aux filtres sélectionnés',
                bn: 'নির্বাচিত ফিল্টারের সাথে কোনো হোটেল মেলে না',
              ),
              icon: Icons.hotel_outlined,
            ),
            const AppFooter(),
          ],
        )
            : ListView.builder(
          padding: const EdgeInsets.all(AppSizes.md),
          itemCount: filteredHotels.length + 1,
          itemBuilder: (context, index) {
            if (index == filteredHotels.length) return const AppFooter();
            return _HotelCard(hotel: filteredHotels[index], searchParams: params);
          },
        );

        final showFiltersSidebar =
            !isArabic && MediaQuery.of(context).size.width >= 900;

        if (!showFiltersSidebar) return resultsList;

        return Row(
          children: [
            Expanded(child: resultsList),
            const SearchFiltersSidebar(),
          ],
        );
      },
    );
  }
}

/// نتائج تبويب "Flight + Hotel": يعرض قسم رحلات الطيران فوق وقسم
/// الفنادق تحته في نفس الصفحة، كل قسم بحالة تحميل/خطأ/فارغ مستقلة عن
/// التاني (تأخّر أو فشل تحميل الرحلات مثلاً ميمنعش عرض الفنادق).
class _FlightHotelSearchResults extends ConsumerWidget {
  final Map<String, dynamic> flightParams;
  final Map<String, dynamic> hotelParams;
  const _FlightHotelSearchResults({
    required this.flightParams,
    required this.hotelParams,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final flightsAsync = ref.watch(duffelFlightSearchResultsProvider(flightParams));
    final hotelsAsync = ref.watch(searchResultsProvider(hotelParams));

    return ListView(
      padding: const EdgeInsets.all(AppSizes.md),
      children: [
        Text(
          _t3(context, ar: 'رحلات الطيران', en: 'Flights', es: 'Vuelos', tr: 'Uçuşlar', id: 'Penerbangan',
              hi: 'उड़ानें',
              ur: 'پروازیں',
              fr: 'Vols',
              bn: 'ফ্লাইট'),
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        const SizedBox(height: AppSizes.sm),
        flightsAsync.when(
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(vertical: AppSizes.lg),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (error, _) => ErrorView(
            message: error.toString().replaceFirst('Exception: ', ''),
            onRetry: () => ref.invalidate(duffelFlightSearchResultsProvider(flightParams)),
          ),
          data: (offers) {
            if (offers.isEmpty) {
              return EmptyView(
                message: _t3(
                  context,
                  ar: 'لا توجد رحلات متاحة لهذا المسار والتاريخ',
                  en: 'No flights available for this route and date',
                  es: 'No hay vuelos disponibles para esta ruta y fecha',
                  tr: 'Bu güzergah ve tarih için uçuş bulunamadı',
                  id: 'Tidak ada penerbangan yang tersedia untuk rute dan tanggal ini',
                  hi: 'इस मार्ग और तारीख के लिए कोई उड़ान उपलब्ध नहीं है',
                  ur: 'اس روٹ اور تاریخ کے لیے کوئی پرواز دستیاب نہیں',
                  fr: 'Aucun vol disponible pour cet itinéraire et cette date',
                  bn: 'এই রুট ও তারিখের জন্য কোনো ফ্লাইট নেই',
                ),
                icon: Icons.flight_outlined,
              );
            }
            return Column(
              children: offers.map((o) => _DuffelFlightCard(offer: o)).toList(),
            );
          },
        ),
        const SizedBox(height: AppSizes.xl),
        Text(
          _t3(context, ar: 'الفنادق', en: 'Hotels', es: 'Hoteles', tr: 'Oteller', id: 'Hotel',
              hi: 'होटल',
              ur: 'ہوٹلز',
              fr: 'Hôtels',
              bn: 'হোটেল'),
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        const SizedBox(height: AppSizes.sm),
        hotelsAsync.when(
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(vertical: AppSizes.lg),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (error, _) => ErrorView(
            message: _t3(
              context,
              ar: 'تعذر تحميل الفنادق',
              en: 'Could not load hotels',
              es: 'No se pudieron cargar los hoteles',
              tr: 'Oteller yüklenemedi',
              id: 'Gagal memuat hotel',
              hi: 'होटल लोड नहीं हो सके',
              ur: 'ہوٹل لوڈ نہیں ہو سکے',
              fr: 'Impossible de charger les hôtels',
              bn: 'হোটেল লোড করা যায়নি',
            ),
            onRetry: () => ref.invalidate(searchResultsProvider(hotelParams)),
          ),
          data: (hotels) {
            if (hotels.isEmpty) {
              return EmptyView(
                message: _t3(
                  context,
                  ar: 'لا توجد فنادق متاحة لهذه المدينة والتواريخ',
                  en: 'No hotels available for this city and dates',
                  es: 'No hay hoteles disponibles para esta ciudad y fechas',
                  tr: 'Bu şehir ve tarihler için uygun otel yok',
                  id: 'Tidak ada hotel yang tersedia untuk kota dan tanggal ini',
                  hi: 'इस शहर और तारीखों के लिए कोई होटल उपलब्ध नहीं है',
                  ur: 'اس شہر اور تاریخوں کے لیے کوئی ہوٹل دستیاب نہیں',
                  fr: 'Aucun hôtel disponible pour cette ville et ces dates',
                  bn: 'এই শহর ও তারিখের জন্য কোনো হোটেল নেই',
                ),
                icon: Icons.hotel_outlined,
              );
            }
            return Column(
              children: hotels
                  .map((h) => _HotelCard(hotel: h, searchParams: hotelParams))
                  .toList(),
            );
          },
        ),
        const SizedBox(height: AppSizes.lg),
        const _TrustSection(),
        const AppFooter(),
      ],
    );
  }
}

class _HotelCard extends ConsumerWidget {
  final HotelModel hotel;
  final Map<String, dynamic> searchParams;
  /// لو اتبعتوا، الكارت بيشتغل في "وضع اختيار" (زرار "اختر" بدل الحجز
  /// المباشر) — بيستخدم في تبويب Flight+Hotel عشان المستخدم يختار
  /// فندق واحد يحجزه مع الرحلة في خطوة واحدة.
  final bool? selected;
  final VoidCallback? onSelect;
  const _HotelCard({
    required this.hotel,
    required this.searchParams,
    this.selected,
    this.onSelect,
  });

  void _openHotelDetails(BuildContext context, Map<String, dynamic> searchParams) {
    context.push(
      AppRoutes.hotelDetails,
      extra: {
        'hotel': hotel,
        'checkIn': searchParams['checkIn'],
        'checkOut': searchParams['checkOut'],
        'guests': searchParams['guests'],
      },
    );
  }

  Future<void> _openInMap(BuildContext context) async {
    final query = Uri.encodeComponent('${hotel.name}, ${hotel.city}');
    final uri = Uri.parse('https://www.google.com/maps/search/?api=1&query=$query');
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _t3(
              context,
              ar: 'تعذر فتح الخريطة',
              en: 'Could not open the map',
              es: 'No se pudo abrir el mapa',
              tr: 'Harita açılamadı',
              id: 'Gagal membuka peta',
              hi: 'मानचित्र नहीं खोला जा सका',
              ur: 'نقشہ نہیں کھل سکا',
              fr: 'Impossible d\'ouvrir la carte',
              bn: 'মানচিত্র খোলা যায়নি',
            ),
          ),
        ),
      );
    }
  }

  /// أيقونة مناسبة حسب نوع العقار (فندق/شقة فندقية/هوستيل/فيلا) —
  /// تُستخدم مكان الصورة لما hotel.images تكون فاضية (زي نتائج
  /// HotelBeds اللي مفيهاش روابط صور في الاستجابة المبسطة).
  IconData _propertyIcon(String propertyType) {
    final t = propertyType.toUpperCase();
    if (t.contains('APART')) return Icons.apartment;
    if (t.contains('HOSTEL')) return Icons.night_shelter_outlined;
    if (t.contains('VILLA') || t.contains('HOUSE')) return Icons.villa_outlined;
    return Icons.hotel;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final favorites = ref.watch(favoritesProvider);
    final isFavorite = favorites.contains(hotel.name);
    final starCount = hotel.rating.round().clamp(0, 5);

    return Card(
      clipBehavior: Clip.antiAlias,
      margin: const EdgeInsets.only(bottom: AppSizes.md),
      child: InkWell(
        onTap: () => _openHotelDetails(context, searchParams),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                width: 140,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Container(
                      color: AppColors.divider,
                      alignment: Alignment.center,
                      child: hotel.images.isNotEmpty
                          ? Image.network(
                        hotel.images.first,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Icon(
                          _propertyIcon(hotel.propertyType),
                          size: 36,
                          color: AppColors.textHint,
                        ),
                      )
                          : Icon(
                        _propertyIcon(hotel.propertyType),
                        size: 36,
                        color: AppColors.textHint,
                      ),
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: GestureDetector(
                        onTap: () =>
                            ref.read(favoritesProvider.notifier).toggle(hotel.name),
                        child: CircleAvatar(
                          radius: 16,
                          backgroundColor: Colors.white,
                          child: Icon(
                            isFavorite ? Icons.favorite : Icons.favorite_border,
                            size: 18,
                            color: isFavorite ? Colors.red : Colors.black87,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(AppSizes.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Flexible(
                                      child: Text(
                                        hotel.name,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Row(
                                      children: List.generate(
                                        starCount,
                                            (_) => const Icon(Icons.star, size: 14, color: Colors.amber),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(Icons.location_on_outlined,
                                        size: 15, color: AppColors.textSecondary),
                                    const SizedBox(width: 2),
                                    Flexible(
                                      child: Text(
                                        hotel.city,
                                        style: const TextStyle(
                                          fontSize: 13,
                                          color: AppColors.textSecondary,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const Text(' · ', style: TextStyle(color: AppColors.textSecondary)),
                                    GestureDetector(
                                      onTap: () => _openInMap(context),
                                      child: Text(
                                        _t3(context, ar: 'الخريطة', en: 'Map', es: 'Mapa', tr: 'Harita', id: 'Peta',
                                            hi: 'मानचित्र',
                                            ur: 'نقشہ',
                                            fr: 'Carte',
                                            bn: 'মানচিত্র'),
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          decoration: TextDecoration.underline,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Expanded(
                            child: Wrap(
                              crossAxisAlignment: WrapCrossAlignment.end,
                              children: [
                                PriceText(
                                  sarAmount: hotel.pricePerNight,
                                  style: const TextStyle(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                ),
                                Text(
                                  ' ${l10n.perNight}',
                                  style: const TextStyle(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(
                            width: 150,
                            height: 40,
                            child: onSelect != null
                                ? ElevatedButton.icon(
                              onPressed: onSelect,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: (selected ?? false) ? AppColors.success : null,
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              ),
                              icon: Icon((selected ?? false) ? Icons.check_circle : Icons.add_circle_outline, size: 16),
                              label: Text(
                                (selected ?? false)
                                    ? _t3(context, ar: 'مختار', en: 'Selected', es: 'Seleccionado', tr: 'Seçildi', id: 'Dipilih',
                                    hi: 'चयनित',
                                    ur: 'منتخب شدہ',
                                    fr: 'Sélectionné',
                                    bn: 'নির্বাচিত')
                                    : _t3(context, ar: 'اختر', en: 'Select', es: 'Elegir', tr: 'Seç', id: 'Pilih',
                                    hi: 'चुनें',
                                    ur: 'منتخب کریں',
                                    fr: 'Sélectionner',
                                    bn: 'নির্বাচন করুন'),
                                overflow: TextOverflow.ellipsis,
                              ),
                            )
                                : ElevatedButton.icon(
                              onPressed: () => _openHotelDetails(context, searchParams),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              ),
                              icon: Text(l10n.bookNow, overflow: TextOverflow.ellipsis),
                              label: const Icon(Icons.arrow_forward, size: 16),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// نتائج بحث الطيران الحقيقية عبر Duffel — بتحوّل اسم المدينة الحر
/// لكود IATA تلقائيًا (عبر duffelFlightSearchResultsProvider) وبتعرض
/// عروض الرحلات الفعلية من شركات الطيران.
class _DuffelFlightSearchResults extends ConsumerWidget {
  final Map<String, dynamic> params;
  const _DuffelFlightSearchResults({required this.params});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resultsAsync = ref.watch(duffelFlightSearchResultsProvider(params));

    return resultsAsync.when(
      loading: () => LoadingView(
        message: _t3(
          context,
          ar: 'يبحث عن رحلات الطيران...',
          en: 'Searching for flights...',
          es: 'Buscando vuelos...',
          tr: 'Uçuşlar aranıyor...',
          id: 'Mencari penerbangan...',
          hi: 'उड़ानें खोजी जा रही हैं...',
          ur: 'پروازیں تلاش کی جا رہی ہیں...',
          fr: 'Recherche de vols en cours...',
          bn: 'ফ্লাইট খোঁজা হচ্ছে...',
        ),
      ),
      error: (error, _) => ErrorView(
        message: error.toString().replaceFirst('Exception: ', ''),
        onRetry: () => ref.invalidate(duffelFlightSearchResultsProvider(params)),
      ),
      data: (offers) {
        final filters = ref.watch(flightFiltersProvider);
        final filteredOffers = applyFlightFilters(offers, filters);

        final resultsList = filteredOffers.isEmpty
            ? ListView(
          padding: const EdgeInsets.all(AppSizes.md),
          children: [
            EmptyView(
              message: offers.isEmpty
                  ? _t3(
                context,
                ar: 'لا توجد رحلات متاحة لهذا المسار والتاريخ',
                en: 'No flights available for this route and date',
                es: 'No hay vuelos disponibles para esta ruta y fecha',
                tr: 'Bu güzergah ve tarih için uçuş bulunamadı',
                id: 'Tidak ada penerbangan yang tersedia untuk rute dan tanggal ini',
                hi: 'इस मार्ग और तारीख के लिए कोई उड़ान उपलब्ध नहीं है',
                ur: 'اس روٹ اور تاریخ کے لیے کوئی پرواز دستیاب نہیں',
                fr: 'Aucun vol disponible pour cet itinéraire et cette date',
                bn: 'এই রুট ও তারিখের জন্য কোনো ফ্লাইট নেই',
              )
                  : _t3(
                context,
                ar: 'لا توجد رحلات مطابقة للفلاتر المختارة',
                en: 'No flights match the selected filters',
                es: 'Ningún vuelo coincide con los filtros seleccionados',
                tr: 'Seçilen filtrelere uygun uçuş yok',
                id: 'Tidak ada penerbangan yang cocok dengan filter yang dipilih',
                hi: 'चुने गए फ़िल्टर से कोई उड़ान मेल नहीं खाती',
                ur: 'منتخب فلٹرز سے کوئی پرواز مماثل نہیں',
                fr: 'Aucun vol ne correspond aux filtres sélectionnés',
                bn: 'নির্বাচিত ফিল্টারের সাথে কোনো ফ্লাইট মেলে না',
              ),
              icon: Icons.flight_outlined,
            ),
            const _TrustSection(),
            const AppFooter(),
          ],
        )
            : ListView.builder(
          padding: const EdgeInsets.all(AppSizes.md),
          itemCount: filteredOffers.length + 2,
          itemBuilder: (context, index) {
            if (index == filteredOffers.length) return const _TrustSection();
            if (index == filteredOffers.length + 1) return const AppFooter();
            return _DuffelFlightCard(offer: filteredOffers[index]);
          },
        );

        final showFiltersSidebar =
            offers.isNotEmpty && MediaQuery.of(context).size.width >= 900;

        if (!showFiltersSidebar) return resultsList;

        return Row(
          children: [
            Expanded(child: resultsList),
            FlightFiltersSidebar(allOffers: offers),
          ],
        );
      },
    );
  }
}

/// كارت عرض رحلة حقيقية من Duffel. السعر بيتحوّل تلقائيًا للريال
/// السعودي (عبر convertToSar) وبعدين يتعرض بنفس PriceText المستخدم
/// في باقي التطبيق، فيتوافق تلقائيًا مع العملة المختارة حاليًا. لو
/// عملة العرض من Duffel مش مدعومة (نادر)، بيعرض السعر الأصلي زي ما
/// هو بدل تحويل خاطئ.
class _DuffelFlightCard extends ConsumerWidget {
  final DuffelFlightOffer offer;
  /// لو اتبعتوا، الكارت بيشتغل في "وضع اختيار" (زرار "اختر" بدل الحجز
  /// المباشر) — بيستخدم في تبويب Flight+Hotel عشان المستخدم يختار
  /// رحلة واحدة يحجزها مع الفندق في خطوة واحدة.
  final bool? selected;
  final VoidCallback? onSelect;
  const _DuffelFlightCard({required this.offer, this.selected, this.onSelect});

  String _formatTime(DateTime t) {
    final h = t.hour.toString().padLeft(2, '0');
    final m = t.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final hours = offer.durationMinutes ~/ 60;
    final minutes = offer.durationMinutes % 60;

    final ratesAsync = ref.watch(exchangeRatesProvider);
    final ratesPerUsd = ratesAsync.value ?? const {};
    final sarAmount = convertToSar(
      amount: offer.totalAmount,
      currencyCode: offer.totalCurrency,
      ratesPerUsd: ratesPerUsd,
    );

    return Card(
      margin: const EdgeInsets.only(bottom: AppSizes.md),
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(Icons.flight_takeoff, size: 18, color: AppColors.textSecondary),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    '${offer.airline} · ${offer.flightNumber}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (offer.nonstop)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.divider,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _t3(context, ar: 'بدون توقف', en: 'Nonstop', es: 'Sin escalas', tr: 'Aktarmasız', id: 'Tanpa transit',
                          hi: 'बिना रुके',
                          ur: 'بلا رکاوٹ',
                          fr: 'Sans escale',
                          bn: 'সরাসরি'),
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: AppSizes.sm),
            Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _formatTime(offer.departureTime),
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    Text(offer.originCity, style: const TextStyle(color: AppColors.textSecondary)),
                  ],
                ),
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        '${hours}h ${minutes}m',
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                      const Row(
                        children: [
                          Expanded(child: Divider()),
                          Icon(Icons.flight, size: 14, color: AppColors.textSecondary),
                          Expanded(child: Divider()),
                        ],
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      _formatTime(offer.arrivalTime),
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    Text(offer.destinationCity, style: const TextStyle(color: AppColors.textSecondary)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: AppSizes.sm),
            Row(
              children: [
                Text(
                  offer.cabinClass,
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
                const Spacer(),
                sarAmount != null
                    ? PriceText(
                  sarAmount: sarAmount,
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                )
                    : Text(
                  '${offer.totalAmount.toStringAsFixed(2)} ${offer.totalCurrency}',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(width: AppSizes.sm),
                SizedBox(
                  width: 130,
                  height: 40,
                  child: onSelect != null
                      ? ElevatedButton.icon(
                    onPressed: onSelect,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: (selected ?? false) ? AppColors.success : null,
                    ),
                    icon: Icon((selected ?? false) ? Icons.check_circle : Icons.add_circle_outline, size: 16),
                    label: Text(
                      (selected ?? false)
                          ? _t3(context, ar: 'مختارة', en: 'Selected', es: 'Seleccionado', tr: 'Seçildi', id: 'Dipilih',
                          hi: 'चयनित',
                          ur: 'منتخب شدہ',
                          fr: 'Sélectionné',
                          bn: 'নির্বাচিত')
                          : _t3(context, ar: 'اختر', en: 'Select', es: 'Elegir', tr: 'Seç', id: 'Pilih',
                          hi: 'चुनें',
                          ur: 'منتخب کریں',
                          fr: 'Sélectionner',
                          bn: 'নির্বাচন করুন'),
                      overflow: TextOverflow.ellipsis,
                    ),
                  )
                      : ElevatedButton(
                    onPressed: () {
                      context.push(
                        AppRoutes.duffelFlightBooking,
                        extra: {'offer': offer},
                      );
                    },
                    child: Text(l10n.bookNow, overflow: TextOverflow.ellipsis),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _FlightSearchResults extends ConsumerWidget {
  final Map<String, dynamic> params;
  const _FlightSearchResults({required this.params});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resultsAsync = ref.watch(flightSearchResultsProvider(params));

    return resultsAsync.when(
      loading: () => LoadingView(
        message: _t3(
          context,
          ar: 'يبحث عن رحلات الطيران...',
          en: 'Searching for flights...',
          es: 'Buscando vuelos...',
          tr: 'Uçuşlar aranıyor...',
          id: 'Mencari penerbangan...',
          hi: 'उड़ानें खोजी जा रही हैं...',
          ur: 'پروازیں تلاش کی جا رہی ہیں...',
          fr: 'Recherche de vols en cours...',
          bn: 'ফ্লাইট খোঁজা হচ্ছে...',
        ),
      ),
      error: (error, _) => ErrorView(
        message: _t3(
          context,
          ar: 'تعذر تحميل النتائج، تحقق من الاتصال',
          en: 'Could not load results, check your connection',
          es: 'No se pudieron cargar los resultados, revisa tu conexión',
          tr: 'Sonuçlar yüklenemedi, bağlantınızı kontrol edin',
          id: 'Gagal memuat hasil, periksa koneksi Anda',
          hi: 'परिणाम लोड नहीं हो सके, अपना कनेक्शन जांचें',
          ur: 'نتائج لوڈ نہیں ہو سکے، اپنا کنکشن چیک کریں',
          fr: 'Impossible de charger les résultats, vérifiez votre connexion',
          bn: 'ফলাফল লোড করা যায়নি, আপনার সংযোগ পরীক্ষা করুন',
        ),
        onRetry: () => ref.invalidate(flightSearchResultsProvider(params)),
      ),
      data: (flights) {
        if (flights.isEmpty) {
          return ListView(
            padding: const EdgeInsets.all(AppSizes.md),
            children: [
              EmptyView(
                message: _t3(
                  context,
                  ar: 'لا توجد رحلات متاحة لهذا المسار والتاريخ',
                  en: 'No flights available for this route and date',
                  es: 'No hay vuelos disponibles para esta ruta y fecha',
                  tr: 'Bu güzergah ve tarih için uçuş bulunamadı',
                  id: 'Tidak ada penerbangan yang tersedia untuk rute dan tanggal ini',
                  hi: 'इस मार्ग और तारीख के लिए कोई उड़ान उपलब्ध नहीं है',
                  ur: 'اس روٹ اور تاریخ کے لیے کوئی پرواز دستیاب نہیں',
                  fr: 'Aucun vol disponible pour cet itinéraire et cette date',
                  bn: 'এই রুট ও তারিখের জন্য কোনো ফ্লাইট নেই',
                ),
                icon: Icons.flight_outlined,
              ),
              const _TrustSection(),
              const AppFooter(),
            ],
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(AppSizes.md),
          itemCount: flights.length + 2,
          itemBuilder: (context, index) {
            if (index == flights.length) return const _TrustSection();
            if (index == flights.length + 1) return const AppFooter();
            return _FlightCard(flight: flights[index], searchParams: params);
          },
        );
      },
    );
  }
}

class _TrustSection extends StatelessWidget {
  const _TrustSection();

  @override
  Widget build(BuildContext context) {
    final items = [
      (
      icon: Icons.emoji_events_outlined,
      color: const Color(0xFFF39C12),
      title: _t3(context, ar: 'المفضّل لدى المسافرين', en: "Travelers' favorite", es: 'Favorito de viajeros', tr: 'Gezginlerin favorisi', id: 'Favorit para wisatawan',
          hi: 'यात्रियों की पसंद',
          ur: 'مسافروں کی پسندیدہ',
          fr: 'Préféré des voyageurs',
          bn: 'ভ্রমণকারীদের পছন্দ'),
      description: _t3(
        context,
        ar: 'يختار آلاف المسافرين Safr-AI لحجز رحلاتهم وفنادقهم بثقة ورضا تامّ',
        en: 'Thousands of travelers choose Safr-AI to book their trips and hotels with confidence',
        es: 'Miles de viajeros eligen Safr-AI para reservar sus viajes y hoteles con confianza',
        tr: 'Binlerce gezgin, seyahatlerini ve otellerini güvenle rezerve etmek için Safr-AI\'yi tercih ediyor',
        id: 'Ribuan wisatawan memilih Safr-AI untuk memesan perjalanan dan hotel mereka dengan percaya diri',
        hi: 'हज़ारों यात्री अपनी यात्राएं और होटल भरोसे के साथ बुक करने के लिए Safr-AI चुनते हैं',
        ur: 'ہزاروں مسافر اپنی سفری منصوبہ بندی اور ہوٹل اعتماد کے ساتھ بک کرنے کے لیے Safr-AI کا انتخاب کرتے ہیں',
        fr: 'Des milliers de voyageurs choisissent Safr-AI pour réserver leurs voyages et hôtels en toute confiance',
        bn: 'হাজার হাজার ভ্রমণকারী নিশ্চিন্তে তাদের ভ্রমণ ও হোটেল বুক করতে Safr-AI বেছে নেন',
      ),
      ),
      (
      icon: Icons.headset_mic_outlined,
      color: const Color(0xFF00B894),
      title: _t3(
        context,
        ar: 'دعم العملاء متاح ٢٤/٧',
        en: 'Customer support available 24/7',
        es: 'Atención al cliente 24/7',
        tr: '7/24 müşteri desteği',
        id: 'Dukungan pelanggan tersedia 24/7',
        hi: '24/7 ग्राहक सहायता उपलब्ध है',
        ur: '24/7 کسٹمر سپورٹ دستیاب',
        fr: 'Assistance client disponible 24h/24 et 7j/7',
        bn: 'গ্রাহক সহায়তা ২৪/৭ উপলব্ধ',
      ),
      description: _t3(
        context,
        ar: 'فريق الدعم لدينا جاهز لمساعدتك في أي وقت طوال أيام الأسبوع دون توقف',
        en: 'Our support team is ready to help you anytime, any day of the week, without stopping',
        es: 'Nuestro equipo de soporte está listo para ayudarte a cualquier hora, todos los días',
        tr: 'Destek ekibimiz haftanın her günü, her an size yardımcı olmaya hazır',
        id: 'Tim dukungan kami siap membantu Anda kapan saja, setiap hari, tanpa henti',
        hi: 'हमारी सहायता टीम बिना रुके, हफ़्ते के किसी भी दिन, किसी भी समय आपकी मदद के लिए तैयार है',
        ur: 'ہماری سپورٹ ٹیم ہفتے کے کسی بھی دن، کسی بھی وقت، بغیر رکے آپ کی مدد کے لیے تیار ہے',
        fr: 'Notre équipe d\'assistance est prête à vous aider à tout moment, tous les jours de la semaine, sans interruption',
        bn: 'আমাদের সহায়তা দল সপ্তাহের যেকোনো দিন, যেকোনো সময় আপনাকে সাহায্য করতে প্রস্তুত',
      ),
      ),
      (
      icon: Icons.sell_outlined,
      color: const Color(0xFF0984E3),
      title: _t3(context, ar: 'أسعار شفافة', en: 'Transparent pricing', es: 'Precios transparentes', tr: 'Şeffaf fiyatlandırma', id: 'Harga transparan',
          hi: 'पारदर्शी मूल्य निर्धारण',
          ur: 'شفاف قیمتیں',
          fr: 'Tarification transparente',
          bn: 'স্বচ্ছ মূল্য'),
      description: _t3(
        context,
        ar: 'جميع الأسعار واضحة دون رسوم خفية، ويمكنك الاطلاع على التفاصيل كاملة قبل تأكيد الحجز',
        en: 'All prices are clear with no hidden fees, and you can see full details before confirming',
        es: 'Todos los precios son claros sin cargos ocultos, y puedes ver los detalles antes de confirmar',
        tr: 'Tüm fiyatlar gizli ücret olmadan nettir, onaylamadan önce tüm detayları görebilirsiniz',
        id: 'Semua harga jelas tanpa biaya tersembunyi, dan Anda bisa melihat detail lengkap sebelum konfirmasi',
        hi: 'सभी कीमतें बिना किसी छुपे शुल्क के स्पष्ट हैं, और पुष्टि करने से पहले आप पूरा विवरण देख सकते हैं',
        ur: 'تمام قیمتیں واضح ہیں بغیر کسی چھپی ہوئی فیس کے، اور آپ تصدیق سے پہلے مکمل تفصیلات دیکھ سکتے ہیں',
        fr: 'Tous les prix sont clairs, sans frais cachés, et vous pouvez voir tous les détails avant de confirmer',
        bn: 'সব মূল্য স্পষ্ট, কোনো লুকানো ফি নেই, এবং নিশ্চিত করার আগে আপনি সম্পূর্ণ বিবরণ দেখতে পারেন',
      ),
      ),
      (
      icon: Icons.card_giftcard_outlined,
      color: const Color(0xFFE67E22),
      title: _t3(context, ar: 'اكسب مكافآت مضاعفة', en: 'Earn double rewards', es: 'Gana recompensas dobles', tr: 'İki kat ödül kazanın', id: 'Dapatkan reward berlipat',
          hi: 'डबल रिवॉर्ड कमाएं',
          ur: 'ڈبل ریوارڈز حاصل کریں',
          fr: 'Gagnez deux fois plus de récompenses',
          bn: 'দ্বিগুণ পুরস্কার অর্জন করুন'),
      description: _t3(
        context,
        ar: 'كل حجز تقوم به عبر Safr-AI يقرّبك أكثر من مكافآت ونقاط إضافية حصرية',
        en: 'Every booking you make through Safr-AI brings you closer to extra exclusive rewards and points',
        es: 'Cada reserva que hagas en Safr-AI te acerca a recompensas y puntos exclusivos adicionales',
        tr: 'Safr-AI üzerinden yaptığınız her rezervasyon, sizi ekstra özel ödül ve puanlara yaklaştırır',
        id: 'Setiap pemesanan melalui Safr-AI membawa Anda lebih dekat ke reward dan poin eksklusif tambahan',
        hi: 'Safr-AI के ज़रिए की गई हर बुकिंग आपको अतिरिक्त खास रिवॉर्ड और पॉइंट्स के करीब लाती है',
        ur: 'Safr-AI کے ذریعے کی گئی ہر بکنگ آپ کو اضافی خصوصی ریوارڈز اور پوائنٹس کے قریب لاتی ہے',
        fr: 'Chaque réservation effectuée via Safr-AI vous rapproche de récompenses et de points exclusifs supplémentaires',
        bn: 'Safr-AI এর মাধ্যমে করা প্রতিটি বুকিং আপনাকে অতিরিক্ত এক্সক্লুসিভ পুরস্কার ও পয়েন্টের কাছাকাছি নিয়ে যায়',
      ),
      ),
    ];

    return Padding(
      padding: const EdgeInsets.only(top: AppSizes.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _t3(context, ar: 'ثق بنا لنوصّلك', en: 'Trust us to take you there', es: 'Confía en nosotros', tr: 'Sizi oraya götürmemize güvenin', id: 'Percayakan perjalanan Anda pada kami',
                hi: 'हम पर भरोसा करें, हम आपको वहाँ पहुंचाएंगे',
                ur: 'ہم پر بھروسہ کریں، ہم آپ کو وہاں لے جائیں گے',
                fr: 'Faites-nous confiance pour vous y emmener',
                bn: 'আপনাকে সেখানে পৌঁছে দিতে আমাদের বিশ্বাস করুন'),
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          const SizedBox(height: AppSizes.md),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var i = 0; i < items.length; i++) ...[
                  if (i > 0) const SizedBox(width: AppSizes.sm),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(AppSizes.md),
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.divider),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(items[i].icon, color: items[i].color, size: 26),
                          const SizedBox(height: 10),
                          Text(
                            items[i].title,
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            items[i].description,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.35),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CarTrustSection extends StatelessWidget {
  const _CarTrustSection();

  @override
  Widget build(BuildContext context) {
    final items = [
      (
      icon: Icons.local_offer_outlined,
      color: const Color(0xFFF39C12),
      title: _t3(
        context,
        ar: 'عروض حصرية لضيوف الطيران/الفنادق',
        en: 'Flyer/hotel guest exclusive offers',
        es: 'Ofertas exclusivas para viajeros',
        tr: 'Uçuş/otel misafirlerine özel teklifler',
        id: 'Penawaran eksklusif untuk tamu penerbangan/hotel',
        hi: 'उड़ान/होटल मेहमानों के लिए खास ऑफ़र',
        ur: 'پرواز/ہوٹل مہمانوں کے لیے خصوصی آفرز',
        fr: 'Offres exclusives pour les voyageurs/clients d\'hôtel',
        bn: 'ফ্লাইট/হোটেল অতিথিদের জন্য এক্সক্লুসিভ অফার',
      ),
      description: _t3(
        context,
        ar: 'احصل على أسعار حصرية لتأجير السيارات عند حجز رحلة طيران أو فندق معنا',
        en: 'Unlock exclusive car rental prices for your booked flights or hotels',
        es: 'Desbloquea precios exclusivos de alquiler al reservar vuelos u hoteles',
        tr: 'Bizimle bir uçuş veya otel rezervasyonu yaptığınızda özel araç kiralama fiyatlarının kilidini açın',
        id: 'Dapatkan harga sewa mobil eksklusif saat Anda memesan penerbangan atau hotel bersama kami',
        hi: 'अपनी बुक की गई उड़ानों या होटलों के लिए खास कार किराया कीमतें अनलॉक करें',
        ur: 'اپنی بک کی گئی پروازوں یا ہوٹلوں کے لیے خصوصی کار کرایہ کی قیمتیں حاصل کریں',
        fr: 'Débloquez des tarifs de location de voiture exclusifs pour vos vols ou hôtels réservés',
        bn: 'আপনার বুক করা ফ্লাইট বা হোটেলের জন্য এক্সক্লুসিভ গাড়ি ভাড়ার মূল্য আনলক করুন',
      ),
      ),
      (
      icon: Icons.schedule_outlined,
      color: const Color(0xFF0984E3),
      title: _t3(context, ar: 'تأجير مرن', en: 'Flexible rentals', es: 'Alquileres flexibles', tr: 'Esnek kiralama', id: 'Sewa fleksibel',
          hi: 'लचीली किराए की सुविधा',
          ur: 'لچکدار کرایہ',
          fr: 'Locations flexibles',
          bn: 'নমনীয় ভাড়া'),
      description: _t3(
        context,
        ar: 'سياسة إلغاء مرنة تتيح لك التخطيط لرحلتك دون قلق',
        en: 'Flexible cancellation policy - plan your trip with ease',
        es: 'Política de cancelación flexible: planifica tu viaje sin preocupaciones',
        tr: 'Esnek iptal politikasıyla seyahatinizi rahatça planlayın',
        id: 'Kebijakan pembatalan fleksibel - rencanakan perjalanan Anda dengan tenang',
        hi: 'लचीली रद्दीकरण नीति - आसानी से अपनी यात्रा की योजना बनाएं',
        ur: 'لچکدار منسوخی پالیسی - آسانی سے اپنے سفر کی منصوبہ بندی کریں',
        fr: 'Politique d\'annulation flexible - planifiez votre voyage en toute tranquillité',
        bn: 'নমনীয় বাতিল নীতি - সহজে আপনার ভ্রমণ পরিকল্পনা করুন',
      ),
      ),
      (
      icon: Icons.verified_outlined,
      color: const Color(0xFF00B894),
      title: _t3(
        context,
        ar: 'ضمان حجز وسيلة النقل',
        en: 'Transport booking guarantee',
        es: 'Garantía de reserva de transporte',
        tr: 'Ulaşım rezervasyon garantisi',
        id: 'Jaminan pemesanan transportasi',
        hi: 'परिवहन बुकिंग गारंटी',
        ur: 'ٹرانسپورٹ بکنگ گارنٹی',
        fr: 'Garantie de réservation de transport',
        bn: 'পরিবহন বুকিং গ্যারান্টি',
      ),
      description: _t3(
        context,
        ar: 'إذا تأخّرت أو أُلغيت رحلة الطيران أو القطار أو الحافلة التي حجزتها، يمكنك التواصل معنا لمساعدتك في الاحتفاظ بحجز السيارة أو إلغائه مجانًا',
        en: 'If your flight, train, or bus is delayed or canceled, contact us for free help to keep or cancel your rental car',
        es: 'Si tu vuelo, tren o autobús se retrasa o cancela, contáctanos para ayuda gratuita con tu alquiler',
        tr: 'Rezerve ettiğiniz uçuş, tren veya otobüs gecikir ya da iptal olursa, araç kiralamanızı ücretsiz olarak koruma veya iptal etme konusunda size yardımcı olmak için bizimle iletişime geçin',
        id: 'Jika penerbangan, kereta, atau bus yang Anda pesan tertunda atau dibatalkan, hubungi kami untuk bantuan gratis menahan atau membatalkan sewa mobil Anda',
        hi: 'अगर आपकी उड़ान, ट्रेन या बस देरी से चलती है या रद्द हो जाती है, तो अपनी किराए की कार रखने या रद्द करने में मुफ़्त मदद के लिए हमसे संपर्क करें',
        ur: 'اگر آپ کی پرواز، ٹرین، یا بس تاخیر کا شکار ہو یا منسوخ ہو جائے، تو اپنی کرایہ کی کار رکھنے یا منسوخ کرنے کے لیے مفت مدد کے لیے ہم سے رابطہ کریں',
        fr: 'Si votre vol, train ou bus est retardé ou annulé, contactez-nous pour une aide gratuite afin de conserver ou d\'annuler votre voiture de location',
        bn: 'যদি আপনার ফ্লাইট, ট্রেন বা বাস বিলম্বিত বা বাতিল হয়, আপনার ভাড়া করা গাড়ি রাখা বা বাতিল করার জন্য বিনামূল্যে সাহায্যের জন্য আমাদের সাথে যোগাযোগ করুন',
      ),
      ),
      (
      icon: Icons.bolt_outlined,
      color: const Color(0xFFE67E22),
      title: _t3(context, ar: 'دعم عملاء سريع', en: 'Rapid customer support', es: 'Soporte rápido', tr: 'Hızlı müşteri desteği', id: 'Dukungan pelanggan cepat',
          hi: 'तेज़ ग्राहक सहायता',
          ur: 'تیز کسٹمر سپورٹ',
          fr: 'Assistance client rapide',
          bn: 'দ্রুত গ্রাহক সহায়তা'),
      description: _t3(
        context,
        ar: 'نرد على اتصالك عادةً خلال ٣٠ ثانية، مع دعم موثوق طوال فترة تأجير السيارة',
        en: 'We usually answer your call within 30 seconds, ensuring reliable support throughout your rental',
        es: 'Solemos responder tu llamada en 30 segundos, con soporte confiable durante todo tu alquiler',
        tr: 'Aramanıza genellikle 30 saniye içinde yanıt veririz ve kiralama süreniz boyunca güvenilir destek sağlarız',
        id: 'Kami biasanya menjawab panggilan Anda dalam 30 detik, memastikan dukungan andal selama masa sewa Anda',
        hi: 'हम आमतौर पर आपकी कॉल का जवाब 30 सेकंड के भीतर देते हैं, जिससे आपके किराए की पूरी अवधि में भरोसेमंद सहायता मिलती है',
        ur: 'ہم عام طور پر آپ کی کال کا جواب 30 سیکنڈ کے اندر دیتے ہیں، جس سے آپ کے کرایہ کی پوری مدت میں قابل اعتماد سپورٹ یقینی بنتی ہے',
        fr: 'Nous répondons généralement à votre appel en 30 secondes, garantissant une assistance fiable tout au long de votre location',
        bn: 'আমরা সাধারণত ৩০ সেকেন্ডের মধ্যে আপনার কল ধরি, যা আপনার ভাড়ার পুরো সময় নির্ভরযোগ্য সহায়তা নিশ্চিত করে',
      ),
      ),
    ];

    return Padding(
      padding: const EdgeInsets.only(top: AppSizes.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _t3(
              context,
              ar: 'مميزات تأجير السيارات معنا',
              en: 'Why rent a car with us',
              es: 'Por qué alquilar con nosotros',
              tr: 'Bizimle araç kiralamanın avantajları',
              id: 'Kenapa sewa mobil bersama kami',
              hi: 'हमसे कार किराए पर क्यों लें',
              ur: 'ہم سے کار کیوں کرایہ پر لیں',
              fr: 'Pourquoi louer une voiture chez nous',
              bn: 'কেন আমাদের কাছ থেকে গাড়ি ভাড়া নেবেন',
            ),
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          const SizedBox(height: AppSizes.md),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var i = 0; i < items.length; i++) ...[
                  if (i > 0) const SizedBox(width: AppSizes.sm),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(AppSizes.md),
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.divider),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(items[i].icon, color: items[i].color, size: 26),
                          const SizedBox(height: 10),
                          Text(
                            items[i].title,
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            items[i].description,
                            maxLines: 4,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.35),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FlightCard extends StatelessWidget {
  final FlightModel flight;
  final Map<String, dynamic> searchParams;
  const _FlightCard({required this.flight, required this.searchParams});

  String _formatTime(DateTime t) {
    final h = t.hour.toString().padLeft(2, '0');
    final m = t.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final hours = flight.duration.inMinutes ~/ 60;
    final minutes = flight.duration.inMinutes % 60;

    return Card(
      margin: const EdgeInsets.only(bottom: AppSizes.md),
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(Icons.flight_takeoff, size: 18, color: AppColors.textSecondary),
                const SizedBox(width: 6),
                Text(
                  '${flight.airline} · ${flight.flightNumber}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                if (flight.nonstop)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.divider,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _t3(context, ar: 'بدون توقف', en: 'Nonstop', es: 'Sin escalas', tr: 'Aktarmasız', id: 'Tanpa transit',
                          hi: 'बिना रुके',
                          ur: 'بلا رکاوٹ',
                          fr: 'Sans escale',
                          bn: 'সরাসরি'),
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: AppSizes.sm),
            Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _formatTime(flight.departureTime),
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    Text(flight.originCity, style: const TextStyle(color: AppColors.textSecondary)),
                  ],
                ),
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        '${hours}h ${minutes}m',
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                      const Row(
                        children: [
                          Expanded(child: Divider()),
                          Icon(Icons.flight, size: 14, color: AppColors.textSecondary),
                          Expanded(child: Divider()),
                        ],
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      _formatTime(flight.arrivalTime),
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    Text(flight.destinationCity, style: const TextStyle(color: AppColors.textSecondary)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: AppSizes.sm),
            Row(
              children: [
                Text(
                  flight.cabinClass,
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
                const Spacer(),
                PriceText(
                  sarAmount: flight.price,
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(width: AppSizes.sm),
                Flexible(
                  child: ElevatedButton(
                    onPressed: () {
                      context.push(
                        AppRoutes.flightBooking,
                        extra: {
                          'flight': flight,
                          'travelDate': searchParams['departureDate'] ?? flight.departureTime,
                          'travelers': searchParams['travelers'] ?? 1,
                        },
                      );
                    },
                    child: Text(l10n.bookNow),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CarSearchResults extends ConsumerWidget {
  final Map<String, dynamic> params;
  const _CarSearchResults({required this.params});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resultsAsync = ref.watch(carSearchResultsProvider(params));

    return resultsAsync.when(
      loading: () => LoadingView(
        message: _t3(
          context,
          ar: 'يبحث عن سيارات متاحة...',
          en: 'Searching for available cars...',
          es: 'Buscando coches disponibles...',
          tr: 'Uygun araçlar aranıyor...',
          id: 'Mencari mobil yang tersedia...',
          hi: 'उपलब्ध कारें खोजी जा रही हैं...',
          ur: 'دستیاب کاریں تلاش کی جا رہی ہیں...',
          fr: 'Recherche de voitures disponibles...',
          bn: 'উপলব্ধ গাড়ি খোঁজা হচ্ছে...',
        ),
      ),
      error: (error, _) => ErrorView(
        message: _t3(
          context,
          ar: 'تعذر تحميل النتائج، تحقق من الاتصال',
          en: 'Could not load results, check your connection',
          es: 'No se pudieron cargar los resultados, revisa tu conexión',
          tr: 'Sonuçlar yüklenemedi, bağlantınızı kontrol edin',
          id: 'Gagal memuat hasil, periksa koneksi Anda',
          hi: 'परिणाम लोड नहीं हो सके, अपना कनेक्शन जांचें',
          ur: 'نتائج لوڈ نہیں ہو سکے، اپنا کنکشن چیک کریں',
          fr: 'Impossible de charger les résultats, vérifiez votre connexion',
          bn: 'ফলাফল লোড করা যায়নি, আপনার সংযোগ পরীক্ষা করুন',
        ),
        onRetry: () => ref.invalidate(carSearchResultsProvider(params)),
      ),
      data: (cars) {
        if (cars.isEmpty) {
          return ListView(
            padding: const EdgeInsets.all(AppSizes.md),
            children: [
              EmptyView(
                message: _t3(
                  context,
                  ar: 'لا توجد سيارات متاحة في هذه المدينة',
                  en: 'No cars available in this city',
                  es: 'No hay coches disponibles en esta ciudad',
                  tr: 'Bu şehirde uygun araç yok',
                  id: 'Tidak ada mobil yang tersedia di kota ini',
                  hi: 'इस शहर में कोई कार उपलब्ध नहीं है',
                  ur: 'اس شہر میں کوئی کار دستیاب نہیں',
                  fr: 'Aucune voiture disponible dans cette ville',
                  bn: 'এই শহরে কোনো গাড়ি নেই',
                ),
                icon: Icons.directions_car_outlined,
              ),
              const _CarTrustSection(),
              const AppFooter(),
            ],
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(AppSizes.md),
          itemCount: cars.length + 2,
          itemBuilder: (context, index) {
            if (index == cars.length) return const _CarTrustSection();
            if (index == cars.length + 1) return const AppFooter();
            return _CarCard(car: cars[index], searchParams: params);
          },
        );
      },
    );
  }
}

class _CarCard extends StatelessWidget {
  final CarModel car;
  final Map<String, dynamic> searchParams;
  const _CarCard({required this.car, required this.searchParams});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Card(
      margin: const EdgeInsets.only(bottom: AppSizes.md),
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.md),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 90,
              height: 70,
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                image: car.imageUrl != null
                    ? DecorationImage(
                  image: NetworkImage(car.imageUrl!),
                  fit: BoxFit.cover,
                  onError: (_, __) {},
                )
                    : null,
              ),
              child: car.imageUrl == null
                  ? const Icon(Icons.directions_car, color: AppColors.textHint)
                  : null,
            ),
            const SizedBox(width: AppSizes.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    car.carName,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${car.company} · ${car.category}',
                    style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.event_seat_outlined, size: 14, color: AppColors.textSecondary),
                      const SizedBox(width: 3),
                      Text('${car.seats}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                      const SizedBox(width: 12),
                      const Icon(Icons.settings_outlined, size: 14, color: AppColors.textSecondary),
                      const SizedBox(width: 3),
                      Text(car.transmission, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSizes.sm),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      PriceText(
                        sarAmount: car.pricePerDay,
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        _t3(context, ar: '/يوم', en: '/day', es: '/día', tr: '/gün', id: '/hari',
                            hi: '/दिन',
                            ur: '/دن',
                            fr: '/jour',
                            bn: '/দিন'),
                        style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600, fontSize: 12),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () {
                      context.push(
                        AppRoutes.carBooking,
                        extra: {
                          'car': car,
                          'pickupCity': searchParams['pickupCity'] ?? '',
                          'pickupDate': searchParams['pickupDate'] ?? DateTime.now(),
                          'dropoffDate': searchParams['dropoffDate'] ?? DateTime.now().add(const Duration(days: 3)),
                        },
                      );
                    },
                    child: Text(l10n.bookNow),
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

class _TravelTabsBar extends StatelessWidget {
  final String selectedTab;
  final void Function(String id) onTabSelected;

  const _TravelTabsBar({
    required this.selectedTab,
    required this.onTabSelected,
  });

  static String _comingSoonText(BuildContext context) {
    return _t3(context, ar: 'قريبًا', en: 'Coming soon', es: 'Próximamente', tr: 'Yakında', id: 'Segera hadir',
        hi: 'जल्द आ रहा है',
        ur: 'جلد آ رہا ہے',
        fr: 'Bientôt disponible',
        bn: 'শীঘ্রই আসছে');
  }

  @override
  Widget build(BuildContext context) {

    final tabs = <_TravelTab>[
      _TravelTab(
        id: 'stays',
        icon: Icons.bed_outlined,
        label: _t3(context, ar: 'الإقامة', en: 'Stays', es: 'Alojamientos', tr: 'Konaklama', id: 'Menginap',
            hi: 'ठहरना',
            ur: 'قیام',
            fr: 'Séjours',
            bn: 'থাকার ব্যবস্থা'),
      ),
      _TravelTab(
        id: 'flights',
        icon: Icons.flight_takeoff,
        label: _t3(context, ar: 'رحلات الطيران', en: 'Flights', es: 'Vuelos', tr: 'Uçuşlar', id: 'Penerbangan',
            hi: 'उड़ानें',
            ur: 'پروازیں',
            fr: 'Vols',
            bn: 'ফ্লাইট'),
      ),
      _TravelTab(
        id: 'flightHotel',
        icon: Icons.airplane_ticket_outlined,
        label: _t3(context, ar: 'طيران + فندق', en: 'Flight + Hotel', es: 'Vuelo + Hotel', tr: 'Uçuş + Otel', id: 'Penerbangan + Hotel',
            hi: 'उड़ान + होटल',
            ur: 'پرواز + ہوٹل',
            fr: 'Vol + Hôtel',
            bn: 'ফ্লাইট + হোটেল'),
      ),
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSizes.md),
        child: Row(
          children: tabs.map((tab) {
            final isActive = tab.id == selectedTab;
            return Padding(
              padding: const EdgeInsetsDirectional.only(end: AppSizes.sm),
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  if (tab.id == 'stays' || tab.id == 'flights' || tab.id == 'flightHotel' || tab.id == 'carRental') {
                    onTabSelected(tab.id);
                    return;
                  }
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(_comingSoonText(context)),
                      duration: const Duration(seconds: 1),
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: isActive ? AppColors.primaryDark : Colors.transparent,
                    borderRadius: BorderRadius.circular(20),
                    border: isActive
                        ? null
                        : Border.all(color: Colors.white.withOpacity(0.4)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        tab.icon,
                        size: 16,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        tab.label,
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _TravelTab {
  final String id;
  final IconData icon;
  final String label;
  const _TravelTab({
    required this.id,
    required this.icon,
    required this.label,
  });
}