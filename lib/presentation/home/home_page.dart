import '../../fast_scroll_behavior.dart';
import 'dart:async';
import '../../core/config/features.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show Supabase;
import 'widgets/us_destinations_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'widgets/travel_inspiration_section.dart';
import 'package:flutter/gestures.dart';
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
import 'widgets/promo_banner_carousel.dart';
import 'widgets/travel_style_section.dart';
import 'widgets/country_browser.dart';
import 'widgets/deals_section.dart';
import 'widgets/accommodation_types_section.dart';
import 'widgets/accommodation_preview_section.dart';
import 'widgets/featured_hotels_section.dart';
import 'widgets/faq_section.dart';
import 'widgets/search_filters_sidebar.dart';
import 'widgets/explore_countries_section.dart';
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
import 'widgets/flight_hotel_deals_section.dart';

/// يختار النص المناسب حسب اللغة الحالية (عربي/إنجليزي/إسباني/تركي/إندونيسي/هندي/أوردو/فرنسي/بنغالي).
String _t3(BuildContext context, {
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

/// قسم "Featured Hotels" مخفي حتى تتوفر بيانات حقيقية من HotelBeds.
/// عرض تقييمات أو أعداد مراجعات أو أسعار غير حقيقية مخالف لقاعدة FTC
/// للمراجعات (16 CFR 465) وقد يُعد إعلانًا مضللًا.
const bool _kFeaturedHotelsEnabled = false;

/// قسم "أنواع الإقامة الشائعة" (فنادق/شقق/فلل/منتجعات/شاليهات) مخفي مؤقتًا:
/// نتائج بحث HotelBeds لا تحدد نوع العقار (تعطي فئة النجوم فقط)، فكانت
/// الأزرار الأربعة الأخيرة لا تعرض شيئًا، وزر "فنادق" يعرض فنادق تجريبية
/// بأسعار بيئة الاختبار. يُعاد عند ربطه بنوع العقار الحقيقي من HotelBeds
/// Content API (accommodationTypeCode).
const bool _kAccommodationTypesEnabled = false;

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

  // نفس فكرة _flightFormExpanded بالظبط، لكن لتبويب Stays -- لما
  // البحث يشتغل (_searchParams != null)، فورم الفنادق (الوجهة +
  // التواريخ + الضيوف) بيتقلّص لشريط ملخّص واحد بدل ما يفضل ظاهر
  // كامل ويشغل مساحة رأسية كبيرة أثناء تصفح النتايج.
  bool _staysFormExpanded = true;

  // بيتحكم في طي بانر Stays فعليًا حسب موضع السكرول في قائمة النتايج
  // (مش بمجرد ما البحث يشتغل) -- بيتحدّث عن طريق _onStaysScroll.
  bool _staysBannerCollapsed = false;
  final _staysScrollController = ScrollController();
  bool _flightsBannerCollapsed = false;
  final _flightsScrollController = ScrollController();

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

  // ───── تبويب العمرة ─────
  // مكة (QCA) أو المدينة (MED) — رموز HotelBeds. التواريخ وعدد الضيوف
  // مشتركة مع تبويب Stays (_checkIn/_checkOut/_guests).
  String _umrahCity = 'QCA';
  /// صورة بانر العمرة: null = الصورة العامة للعمرة (banner_umrah_*)، وبعد
  /// أن يختار العميل مدينة أو يبحث تتغير لصورة مكة أو المدينة
  /// (banner_makkah_* / banner_madinah_*).
  String? _umrahBannerCity;
  final _umrahDateFieldKey = GlobalKey();
  Map<String, dynamic>? _umrahParams;
  bool _umrahFormExpanded = true;

  Map<String, dynamic>? _flightSearchParams;
  Map<String, dynamic>? _carSearchParams;

  @override
  void initState() {
    super.initState();
    _staysScrollController.addListener(_onStaysScroll);
    _flightsScrollController.addListener(_onFlightsScroll);
  }

  void _onFlightsScroll() {
    final shouldCollapse = _flightsScrollController.hasClients &&
        _flightsScrollController.offset > 40;
    if (shouldCollapse != _flightsBannerCollapsed) {
      setState(() => _flightsBannerCollapsed = shouldCollapse);
    }
  }

  /// بيراقب موضع سكرول قائمة نتايج Stays، وبيطي/يفتح بانر الصفحة
  /// تبعًا لكده بدل ما يتقلّص فورًا بمجرد وجود نتايج بحث.
  void _onStaysScroll() {
    final shouldCollapse = _staysScrollController.hasClients &&
        _staysScrollController.offset > 40;
    if (shouldCollapse != _staysBannerCollapsed) {
      setState(() => _staysBannerCollapsed = shouldCollapse);
    }
  }

  @override
  void dispose() {
    _cityController.dispose();
    _flightFromController.dispose();
    _flightToController.dispose();
    _carPickupController.dispose();
    _carDropoffController.dispose();
    _destinationDebounce?.cancel();
    _staysScrollController.dispose();
    _flightsScrollController.dispose();
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
      _staysFormExpanded = false;
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
  void _runFlightHotelSearch() {
    final origin = _flightFromController.text.trim();
    final destination = _flightToController.text.trim();

    if (origin.isEmpty || destination.isEmpty || _selectedDestination == null) {
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
              _t3(context, ar: 'تعديل', en: 'Edit', es: 'Editar', tr: 'Düzenle', id: 'Edit',
                  hi: 'संपादित करें',
                  ur: 'ترمیم کریں',
                  fr: 'Modifier',
                  bn: 'সম্পাদনা করুন'),
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  /// نفس فكرة _buildCollapsedFlightBar بالظبط، لكن لتبويب Stays --
  /// بيعرض شريط ملخّص واحد (المدينة · التواريخ · عدد الضيوف) بدل فورم
  /// البحث الكامل، بمجرد ما نتايج بحث فعلية تظهر.
  Widget _buildCollapsedStaysBar() {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    final params = _searchParams!;
    final label = params['cityLabel'] as String;
    final checkIn = params['checkIn'] as DateTime;
    final checkOut = params['checkOut'] as DateTime;
    final guests = params['guests'] as int;
    final dateLabel =
        '${months[checkIn.month - 1]} ${checkIn.day} - ${months[checkOut.month - 1]} ${checkOut.day}';

    return Container(
      margin: const EdgeInsets.all(AppSizes.md),
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.md, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.primaryDark,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        children: [
          const Icon(Icons.location_on_outlined, color: Colors.white70, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '$label · $dateLabel · $guests',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          TextButton.icon(
            onPressed: () => setState(() => _staysFormExpanded = true),
            icon: const Icon(Icons.edit, size: 16, color: Colors.white),
            label: Text(
              _t3(context, ar: 'تعديل', en: 'Edit', es: 'Editar', tr: 'Düzenle', id: 'Edit',
                  hi: 'संपादित करें',
                  ur: 'ترمیم کریں',
                  fr: 'Modifier',
                  bn: 'সম্পাদনা করুন'),
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
  /// ملحوظة: بنعرض رسالة واضحة لو البحث فشل أو رجّع نتيجة فاضية، بدل
  /// ما نتجاهل الحالة دي بصمت (كان ده سبب "مفيش أي حاجة بتحصل" اللي
  /// ظهر وقت التشخيص).
  Future<void> _selectDestination(String city) async {
    _cityController.text = city;
    final repo = ref.read(hotelRepositoryProvider);
    final result = await repo.searchDestinations(city);
    if (!mounted) return;
    result.when(
      success: (list) {
        if (list.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('DEBUG: لا توجد نتائج بحث لـ "$city" في hotelbeds_destinations')),
          );
          return;
        }
        setState(() => _selectedDestination = list.first);
        _runSearch();
      },
      failure: (message) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('DEBUG: فشل البحث عن "$city" — $message')),
        );
      },
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
      appBar: AppBanner(
        activeTab: _activeTab,
        assetVariant: _activeTab == 'flights'
            ? 'flights'
            : _activeTab == 'carRental'
            ? 'car_rental'
            : _activeTab == 'flightHotel'
            ? 'flight_hotel'
            : _activeTab == 'umrah'
            ? (_umrahBannerCity == 'QCA'
            ? 'makkah'
            : _umrahBannerCity == 'MED'
            ? 'madinah'
            : 'umrah')
            : _activeTab == 'groups'
            ? 'groups'
            : null,
        collapsed: _activeTab == 'flights'
            ? _flightSearchParams != null
            : _activeTab == 'carRental'
            ? _carSearchParams != null
            : _activeTab == 'flightHotel'
            ? (_searchParams != null && _flightSearchParams != null)
            : _activeTab == 'umrah'
            ? (_umrahParams != null && _staysBannerCollapsed)
            : _activeTab == 'groups'
            ? false
            : (_searchParams != null && _staysBannerCollapsed),
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
                  : (_activeTab == 'stays' && _searchParams != null && !_staysFormExpanded)
                  ? _buildCollapsedStaysBar()
                  : (_activeTab == 'umrah' && _umrahParams != null && !_umrahFormExpanded)
                  ? _buildCollapsedUmrahBar()
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
                        offstage: _activeTab != 'umrah',
                        child: _buildUmrahSearchBox(),
                      ),
                      Offstage(
                        offstage: _activeTab != 'groups',
                        child: _buildGroupsHeader(),
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
                    ? FastWheelScroll(
                  controller: _flightsScrollController,
                  child: ListView(
                    controller: _flightsScrollController,
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
                      TravelInspirationSection(
                        originCity: 'Los Angeles',
                        exploreTags: const [
                          ExploreWorldTag(city: 'Vancouver', price: '\$85.90'),
                          ExploreWorldTag(city: 'Guadalajara', price: '\$113.10'),
                        ],
                        lists: [
                          TravelDestinationList(
                            title: 'Popular to Asia',
                            titleColor: Colors.deepOrange,
                            badgeColor: Colors.deepOrange,
                            items: const [
                              TravelDestinationItem(
                                name: 'Tokyo',
                                date: 'Sat, Sep 26',
                                price: '\$412.10',
                                imageUrl: 'https://images.unsplash.com/photo-1540959733332-eab4deabeeaf',
                              ),
                              TravelDestinationItem(
                                name: 'Kuala Lumpur',
                                date: 'Tue, Sep 29',
                                price: '\$389.80',
                                imageUrl: 'https://images.unsplash.com/photo-1596422846543-75c6fc197f07',
                              ),
                            ],
                          ),
                        ],
                        onItemTap: (item) {
                          _flightToController.text = item.name;
                          _runFlightSearch();
                        },
                      ),
                      const SizedBox(height: AppSizes.md),
                      const _TrustSection(),
                      const AppFooter(),
                    ],
                  ),
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
                    : _activeTab == 'umrah'
                    ? (_umrahParams == null
                    ? ListView(
                  padding: const EdgeInsets.all(AppSizes.md),
                  children: [_UmrahIntro(onGroupStays: () => setState(() => _activeTab = 'groups')), const AppFooter()],
                )
                    : Column(
                  children: [
                    _UmrahEntryNotice(onGroupStays: () => setState(() => _activeTab = 'groups')),
                    Expanded(
                      child: _SearchResults(
                        params: _umrahParams!,
                        scrollController: _staysScrollController,
                      ),
                    ),
                  ],
                ))
                    : _activeTab == 'groups'
                    ? ListView(
                  padding: const EdgeInsets.all(AppSizes.md),
                  children: [
                    _GroupStaysForm(
                      initialCheckIn: _checkIn,
                      initialCheckOut: _checkOut,
                    ),
                    const AppFooter(),
                  ],
                )
                    : _activeTab == 'flightHotel'
                    ? ((_searchParams == null || _flightSearchParams == null)
                    ? ListView(
                  padding: const EdgeInsets.all(AppSizes.md),
                  children: [
                    FlightHotelDealsSection(
                      onDealSelected: (origin, deal) {
                        context.push(
                          AppRoutes.flightHotelDealDetails,
                          extra: {'origin': origin, 'deal': deal},
                        );
                      },
                    ),
                    const _TrustSection(),
                    const AppFooter(),
                  ],
                )
                    : _FlightHotelSearchResults(
                  flightParams: _flightSearchParams!,
                  hotelParams: _searchParams!,
                ))
                    : (_searchParams == null
                    ? ListView(
                  children: [
                    PromoBannerCarousel(slides: defaultStaysPromoSlides(context)),
                    TrendingDestinations(onSelected: _selectDestination),
                    TravelStyleSection(onSelected: _selectDestination),
                    // مخفي: بطاقات "Early Bird Discount" و"Save on stays" تعد بخصومات
                    // غير موجودة (انظر kDealsEnabled في features.dart).
                    if (kDealsEnabled) const DealsSection(),
                    if (_kAccommodationTypesEnabled) ...[
                      AccommodationTypesSection(
                        onTypeSelected: _onAccommodationTypeSelected,
                        selectedType: _selectedAccommodationType,
                      ),
                      if (_selectedAccommodationType != null)
                        AccommodationPreviewSection(selectedType: _selectedAccommodationType!),
                    ],
                    // مخفي مؤقتًا: بيانات تجريبية (تقييمات ومراجعات وأسعار غير حقيقية،
                    // وأسماء Hilton/Marriott). يُعاد لاحقًا ببيانات HotelBeds حقيقية.
                    if (_kFeaturedHotelsEnabled) const FeaturedHotelsSection(),
                    const ExploreCountriesSection(),
                    const FaqSection(),
                    const AppFooter(),
                  ],
                )
                    : _SearchResults(params: _searchParams!, scrollController: _staysScrollController)),
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

    final cityField = Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextField(
        controller: _cityController,
        style: const TextStyle(color: Colors.black87),
        decoration: InputDecoration(
          hintText: l10n.whereTo,
          hintStyle: const TextStyle(color: Colors.black45),
          border: InputBorder.none,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        ),
        onChanged: _onCityTextChanged,
        onSubmitted: (_) => _runSearch(),
        onTap: () {
          if (_cityController.text.trim().isEmpty) _openCountryBrowser();
        },
      ),
    );

    final datesPill = GestureDetector(
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
    );

    final guestsPill = GestureDetector(
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
    );

    final searchButton = ElevatedButton.icon(
      onPressed: _runSearch,
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF87CEEB),
        foregroundColor: Colors.white,
        shape: const StadiumBorder(),
        minimumSize: Size.zero,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      ),
      icon: const Icon(Icons.search, size: 18),
      label: Text(l10n.search),
    );

    // أيقونة "تصفّح حسب الدولة" -- بلون بارز (كهرماني) بدل الرمادي
    // الشفاف الباهت، عشان تبقى واضحة ومميزة على خلفية الشريط الغامقة.
    final browseIcon = IconButton(
      onPressed: _openCountryBrowser,
      icon: const Icon(Icons.public, color: Color(0xFFFFC107), size: 22),
      tooltip: _t3(context, ar: 'تصفّح حسب الدولة', en: 'Browse by country', es: 'Explorar por país', tr: 'Ülkeye göre gözat', id: 'Jelajahi berdasarkan negara',
          hi: 'देश के अनुसार ब्राउज़ करें',
          ur: 'ملک کے مطابق دیکھیں',
          fr: 'Parcourir par pays',
          bn: 'দেশ অনুযায়ী ব্রাউজ করুন'),
    );

    final suggestionsList = _destinationSuggestions.isNotEmpty
        ? Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Container(
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
    )
        : const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(AppSizes.sm),
      decoration: BoxDecoration(
        color: AppColors.primaryDark,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primaryDark, width: 2),
      ),
      // LayoutBuilder بيحدد المساحة المتاحة فعليًا: على الشاشات
      // العريضة (ديسكتوب/ويب) كل الحقول بتتحط في صف واحد (Row مع
      // Expanded لحقل المدينة). على الشاشات الضيقة (موبايل)، حقل
      // المدينة بياخد صف كامل لوحده، والباقي (تواريخ/ضيوف/بحث/دول)
      // بيتحط في Wrap تحته عشان يلف تلقائيًا من غير ما يفيض برّه
      // حدود الشاشة (overflow).
      child: LayoutBuilder(
        builder: (context, constraints) {
          const wideBreakpoint = 640.0;
          final isWide = constraints.maxWidth >= wideBreakpoint;

          if (isWide) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    const SizedBox(width: 4),
                    const Icon(Icons.location_on_outlined, size: 20, color: Colors.white70),
                    const SizedBox(width: 8),
                    Expanded(child: cityField),
                    const SizedBox(width: 12),
                    datesPill,
                    const SizedBox(width: 12),
                    guestsPill,
                    const SizedBox(width: 12),
                    searchButton,
                    const SizedBox(width: 8),
                    browseIcon,
                  ],
                ),
                suggestionsList,
              ],
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const SizedBox(width: 4),
                  const Icon(Icons.location_on_outlined, size: 20, color: Colors.white70),
                  const SizedBox(width: 8),
                  Expanded(child: cityField),
                  const SizedBox(width: 4),
                  browseIcon,
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  datesPill,
                  guestsPill,
                  searchButton,
                ],
              ),
              suggestionsList,
            ],
          );
        },
      ),
    );
  }

  // ═══════════════════════ تبويب العمرة ═══════════════════════

  void _runUmrahSearch() {
    setState(() {
      _umrahFormExpanded = false;
      _umrahBannerCity = _umrahCity;
      _umrahParams = {
        'destinationCode': _umrahCity,
        'cityLabel': _umrahCity == 'QCA' ? 'Makkah' : 'Madinah',
        'checkIn': _checkIn,
        'checkOut': _checkOut,
        'guests': _guests,
      };
    });
  }

  Widget _buildCollapsedUmrahBar() {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    final params = _umrahParams!;
    final checkIn = params['checkIn'] as DateTime;
    final checkOut = params['checkOut'] as DateTime;
    final city = params['destinationCode'] == 'QCA'
        ? _t3(context, ar: 'مكة المكرمة', en: 'Makkah', es: 'La Meca', tr: 'Mekke', id: 'Makkah',
        hi: 'मक्का', ur: 'مکہ مکرمہ', fr: 'La Mecque', bn: 'মক্কা')
        : _t3(context, ar: 'المدينة المنورة', en: 'Madinah', es: 'Medina', tr: 'Medine', id: 'Madinah',
        hi: 'मदीना', ur: 'مدینہ منورہ', fr: 'Médine', bn: 'মদিনা');
    final dateLabel =
        '${months[checkIn.month - 1]} ${checkIn.day} - ${months[checkOut.month - 1]} ${checkOut.day}';

    return Container(
      margin: const EdgeInsets.all(AppSizes.md),
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.md, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.primaryDark,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        children: [
          const Icon(Icons.mosque_outlined, color: Colors.white70, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '$city · $dateLabel · ${params['guests']}',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          TextButton.icon(
            onPressed: () => setState(() => _umrahFormExpanded = true),
            icon: const Icon(Icons.edit, size: 16, color: Colors.white),
            label: Text(
              _t3(context, ar: 'تعديل', en: 'Edit', es: 'Editar', tr: 'Düzenle', id: 'Edit',
                  hi: 'संपादित करें', ur: 'ترمیم کریں', fr: 'Modifier', bn: 'সম্পাদনা করুন'),
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUmrahSearchBox() {
    final l10n = AppLocalizations.of(context)!;
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    final datesLabel =
        '${months[_checkIn.month - 1]} ${_checkIn.day} - ${months[_checkOut.month - 1]} ${_checkOut.day}';

    Widget cityChip(String code, String label) {
      final selected = _umrahCity == code;
      return ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => setState(() {
          _umrahCity = code;
          _umrahBannerCity = code;
        }),
        // لون صريح للحالتين: في Material 3 كان لون الشريحة غير المختارة
        // يظهر أبيض فيختفي النص الأبيض ("Madinah" لا يُقرأ).
        color: MaterialStateProperty.resolveWith(
              (states) => states.contains(MaterialState.selected)
              ? Colors.white
              : Colors.white.withOpacity(0.12),
        ),
        labelStyle: TextStyle(
          color: selected ? AppColors.primaryDark : Colors.white,
          fontWeight: FontWeight.w600,
        ),
        side: BorderSide(color: Colors.white.withOpacity(0.5)),
        showCheckmark: false,
      );
    }

    final cityChips = Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        cityChip('QCA', _t3(context, ar: 'مكة المكرمة', en: 'Makkah', es: 'La Meca', tr: 'Mekke', id: 'Makkah',
            hi: 'मक्का', ur: 'مکہ مکرمہ', fr: 'La Mecque', bn: 'মক্কা')),
        cityChip('MED', _t3(context, ar: 'المدينة المنورة', en: 'Madinah', es: 'Medina', tr: 'Medine', id: 'Madinah',
            hi: 'मदीना', ur: 'مدینہ منورہ', fr: 'Médine', bn: 'মদিনা')),
      ],
    );

    final datesPill = GestureDetector(
      key: _umrahDateFieldKey,
      behavior: HitTestBehavior.opaque,
      onTap: () => _pickDateRange(_umrahDateFieldKey),
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
          ],
        ),
      ),
    );

    final guestsPill = Container(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF87CEEB),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            visualDensity: VisualDensity.compact,
            icon: const Icon(Icons.remove, size: 18, color: Colors.white),
            onPressed: _guests > 1 ? () => setState(() => _guests--) : null,
          ),
          const Icon(Icons.person_outline, size: 18, color: Colors.white70),
          const SizedBox(width: 4),
          Text('$_guests', style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.white)),
          IconButton(
            visualDensity: VisualDensity.compact,
            icon: const Icon(Icons.add, size: 18, color: Colors.white),
            onPressed: _guests < 8 ? () => setState(() => _guests++) : null,
          ),
        ],
      ),
    );

    final searchButton = ElevatedButton.icon(
      onPressed: _runUmrahSearch,
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF87CEEB),
        foregroundColor: Colors.white,
        shape: const StadiumBorder(),
        minimumSize: Size.zero,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      ),
      icon: const Icon(Icons.search, size: 18),
      label: Text(l10n.search),
    );

    return Container(
      padding: const EdgeInsets.all(AppSizes.sm),
      decoration: BoxDecoration(
        color: AppColors.primaryDark,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primaryDark, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 2, 4, 8),
            child: Text(
              _t3(context,
                  ar: 'فنادق العمرة في مكة المكرمة والمدينة المنورة',
                  en: 'Umrah hotels in Makkah and Madinah',
                  es: 'Hoteles para la Umrah en La Meca y Medina',
                  tr: 'Mekke ve Medine\'de umre otelleri',
                  id: 'Hotel umrah di Makkah dan Madinah',
                  hi: 'मक्का और मदीना में उमरा होटल',
                  ur: 'مکہ مکرمہ اور مدینہ منورہ میں عمرہ ہوٹل',
                  fr: 'Hôtels pour la Omra à La Mecque et Médine',
                  bn: 'মক্কা ও মদিনায় উমরাহ হোটেল'),
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
            ),
          ),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [cityChips, datesPill, guestsPill, searchButton],
          ),
        ],
      ),
    );
  }

  // ═══════════════════════ تبويب حجوزات المجموعات ═══════════════════════

  Widget _buildGroupsHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSizes.md),
      decoration: BoxDecoration(
        color: AppColors.primaryDark,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          const Icon(Icons.groups, color: Colors.white, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _t3(context,
                  ar: 'حجز 5 غرف أو أكثر؟ أرسل طلبك ونرسل لك عرض سعر مخصص بالبريد.',
                  en: 'Booking 5 or more rooms? Send a request and we will email you a custom quote.',
                  es: '¿Reservas 5 habitaciones o más? Envía tu solicitud y te enviaremos un presupuesto por correo.',
                  tr: '5 veya daha fazla oda mı? Talebinizi gönderin, size e-postayla özel teklif gönderelim.',
                  id: 'Memesan 5 kamar atau lebih? Kirim permintaan dan kami akan mengirim penawaran khusus lewat email.',
                  hi: '5 या अधिक कमरे बुक कर रहे हैं? अनुरोध भेजें, हम ईमेल से विशेष कोटेशन भेजेंगे।',
                  ur: '5 یا زیادہ کمرے؟ درخواست بھیجیں، ہم ای میل پر خصوصی قیمت بھیجیں گے۔',
                  fr: 'Vous réservez 5 chambres ou plus ? Envoyez votre demande et nous vous enverrons un devis par e-mail.',
                  bn: '৫ বা তার বেশি রুম? অনুরোধ পাঠান, আমরা ইমেলে বিশেষ মূল্য পাঠাব।'),
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, height: 1.4),
            ),
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
                  const SizedBox(width: 8),
                  IntrinsicWidth(
                    child: ElevatedButton.icon(
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
  final ScrollController? scrollController;
  const _SearchResults({required this.params, this.scrollController});

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
        var filteredHotels = applyHotelFilters(hotels, activeFilters);

        // مكة/المدينة: نعرض المسافة من الحرم ونرتب من الأقرب (الفنادق بلا
        // إحداثيات صالحة تأتي في آخر القائمة).
        final holySite = HolySite.forDestinationCode(params['destinationCode'] as String?);
        if (holySite != null) {
          double key(HotelModel h) => h.distanceMetersTo(holySite) ?? double.infinity;
          filteredHotels = [...filteredHotels]..sort((a, b) => key(a).compareTo(key(b)));
        }

        final resultsList = filteredHotels.isEmpty
            ? ListView(
          controller: scrollController,
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
          controller: scrollController,
          padding: const EdgeInsets.all(AppSizes.md),
          itemCount: filteredHotels.length + 1,
          itemBuilder: (context, index) {
            if (index == filteredHotels.length) return const AppFooter();
            return _HotelCard(hotel: filteredHotels[index], searchParams: params, holySite: holySite);
          },
        );

        final showFiltersSidebar =
            !isArabic && MediaQuery.of(context).size.width >= 900;

        if (!showFiltersSidebar) return resultsList;

        return Row(
          children: [
            Expanded(child: resultsList),
            SearchFiltersSidebar(hotels: hotels),
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

    final mainContent = ListView(
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
            final filters = ref.watch(flightFiltersProvider);
            final filteredOffers = applyFlightFilters(offers, filters);
            if (filteredOffers.isEmpty) {
              return EmptyView(
                message: _t3(
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
              );
            }
            return Column(
              children: filteredOffers.map((o) => _DuffelFlightCard(offer: o)).toList(),
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
            final activeFilters = ref.watch(hotelFiltersProvider);
            final filteredHotels = applyHotelFilters(hotels, activeFilters);
            if (filteredHotels.isEmpty) {
              return EmptyView(
                message: _t3(
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
              );
            }
            return Column(
              children: filteredHotels
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

    // فلاتر الطيران والفنادق -- بنستخدم نفس الـ widgets الحقيقية
    // الشغالة في تبويبي Flights وStays لوحدهم، بس دلوقتي مع بعض في
    // عمود واحد جنب النتائج، وبتظهر بس لو فيه نتائج فعلية ترشّح.
    final flightOffers = flightsAsync.value ?? const [];
    final hotels = hotelsAsync.value ?? const [];
    final showFiltersSidebar =
        (flightOffers.isNotEmpty || hotels.isNotEmpty) &&
            MediaQuery.of(context).size.width >= 900;

    if (!showFiltersSidebar) return mainContent;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: mainContent),
        SizedBox(
          width: 280,
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(vertical: AppSizes.md),
            child: Column(
              children: [
                if (flightOffers.isNotEmpty) FlightFiltersSidebar(allOffers: flightOffers),
                if (flightOffers.isNotEmpty && hotels.isNotEmpty) const SizedBox(height: AppSizes.lg),
                if (hotels.isNotEmpty) SearchFiltersSidebar(hotels: hotels),
              ],
            ),
          ),
        ),
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

  /// لو اتبعت (نتائج مكة/المدينة)، الكارت يعرض المسافة التقريبية من الحرم.
  final HolySite? holySite;
  const _HotelCard({
    required this.hotel,
    required this.searchParams,
    this.selected,
    this.onSelect,
    this.holySite,
  });

  /// "≈ 350 m" أو "≈ 1.2 km".
  static String _formatDistance(double meters) {
    if (meters < 1000) {
      final rounded = ((meters / 10).round() * 10).clamp(10, 990);
      return '$rounded m';
    }
    return '${(meters / 1000).toStringAsFixed(1)} km';
  }

  Widget _holyDistanceRow(BuildContext context) {
    final site = holySite;
    if (site == null) return const SizedBox.shrink();
    final meters = hotel.distanceMetersTo(site);
    if (meters == null) return const SizedBox.shrink();
    final d = _formatDistance(meters);
    final isMakkah = identical(site, HolySite.masjidAlHaram);
    final text = isMakkah
        ? _t3(context,
        ar: 'تقريبًا $d من الكعبة المشرفة (بخط مستقيم)',
        en: '≈ $d from the Kaaba (straight line)',
        es: '≈ $d de la Kaaba (en línea recta)',
        tr: 'Kâbe\'ye ≈ $d (kuş uçuşu)',
        id: '≈ $d dari Ka\'bah (garis lurus)',
        hi: 'काबा से ≈ $d (सीधी रेखा)',
        ur: 'خانہ کعبہ سے تقریباً $d (سیدھی لکیر)',
        fr: '≈ $d de la Kaaba (à vol d\'oiseau)',
        bn: 'কাবা থেকে ≈ $d (সরলরেখায়)')
        : _t3(context,
        ar: 'تقريبًا $d من المسجد النبوي (بخط مستقيم)',
        en: '≈ $d from the Prophet\'s Mosque (straight line)',
        es: '≈ $d de la Mezquita del Profeta (en línea recta)',
        tr: 'Mescid-i Nebevi\'ye ≈ $d (kuş uçuşu)',
        id: '≈ $d dari Masjid Nabawi (garis lurus)',
        hi: 'मस्जिद-ए-नबवी से ≈ $d (सीधी रेखा)',
        ur: 'مسجد نبوی سے تقریباً $d (سیدھی لکیر)',
        fr: '≈ $d de la Mosquée du Prophète (à vol d\'oiseau)',
        bn: 'মসজিদে নববী থেকে ≈ $d (সরলরেখায়)');
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        children: [
          const Icon(Icons.mosque_outlined, size: 15, color: AppColors.primary),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

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
                        filterQuality: FilterQuality.high,
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
                                _holyDistanceRow(context),
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
    // ⚠️ كل بطاقة هنا وعد للعميل؛ لا تكتب إلا ما هو صحيح الآن.
    // (حُذفت سابقًا: "آلاف المسافرين يختاروننا" و"دعم 24/7" لأنهما غير صحيحين بعد.)
    final items = [
      (
      icon: Icons.lock_outline,
      color: const Color(0xFFF39C12),
      title: _t3(context, ar: 'دفع آمن', en: 'Secure payment', es: 'Pago seguro', tr: 'Güvenli ödeme', id: 'Pembayaran aman',
          hi: 'सुरक्षित भुगतान',
          ur: 'محفوظ ادائیگی',
          fr: 'Paiement sécurisé',
          bn: 'নিরাপদ পেমেন্ট'),
      description: _t3(
        context,
        ar: 'يُحجز المبلغ على بطاقتك أولًا، ولا يُسحب إلا بعد أن يؤكد الفندق حجزك',
        en: 'The amount is only held on your card, and is charged only after the hotel confirms your booking',
        es: 'El importe solo se retiene en tu tarjeta y se cobra únicamente cuando el hotel confirma tu reserva',
        tr: 'Tutar önce kartınızda bloke edilir ve yalnızca otel rezervasyonunuzu onayladıktan sonra tahsil edilir',
        id: 'Dana hanya ditahan di kartu Anda, dan baru ditagih setelah hotel mengonfirmasi pemesanan Anda',
        hi: 'राशि पहले केवल आपके कार्ड पर रोकी जाती है, और होटल की पुष्टि के बाद ही काटी जाती है',
        ur: 'رقم پہلے صرف آپ کے کارڈ پر روکی جاتی ہے، اور ہوٹل کی تصدیق کے بعد ہی وصول کی جاتی ہے',
        fr: 'Le montant est seulement bloqué sur votre carte et n\'est débité qu\'après la confirmation de l\'hôtel',
        bn: 'অর্থ প্রথমে শুধু আপনার কার্ডে আটকে রাখা হয়, এবং হোটেল নিশ্চিত করার পরেই কাটা হয়',
      ),
      ),
      (
      icon: Icons.headset_mic_outlined,
      color: const Color(0xFF00B894),
      title: _t3(
        context,
        ar: 'مساعدة بلغتك',
        en: 'Help in your language',
        es: 'Ayuda en tu idioma',
        tr: 'Kendi dilinizde destek',
        id: 'Bantuan dalam bahasa Anda',
        hi: 'आपकी भाषा में सहायता',
        ur: 'آپ کی زبان میں مدد',
        fr: 'De l\'aide dans votre langue',
        bn: 'আপনার ভাষায় সহায়তা',
      ),
      description: _t3(
        context,
        ar: 'فريق حقيقي يرد على رسائلك بالعربية والإنجليزية عبر support@flynoom.com',
        en: 'Real people reply to your messages in Arabic and English at support@flynoom.com',
        es: 'Personas reales responden tus mensajes en árabe e inglés en support@flynoom.com',
        tr: 'Gerçek kişiler mesajlarınızı support@flynoom.com üzerinden Arapça ve İngilizce yanıtlar',
        id: 'Orang sungguhan membalas pesan Anda dalam bahasa Arab dan Inggris di support@flynoom.com',
        hi: 'असली लोग support@flynoom.com पर अरबी और अंग्रेज़ी में आपके संदेशों का जवाब देते हैं',
        ur: 'حقیقی لوگ support@flynoom.com پر عربی اور انگریزی میں آپ کے پیغامات کا جواب دیتے ہیں',
        fr: 'De vraies personnes répondent à vos messages en arabe et en anglais à support@flynoom.com',
        bn: 'সত্যিকারের মানুষ support@flynoom.com-এ আরবি ও ইংরেজিতে আপনার বার্তার উত্তর দেন',
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
      // بطاقة "اكسب مكافآت مضاعفة" مخفية مع برنامج المكافآت (features.dart).
      if (kRewardsEnabled) (
      icon: Icons.card_giftcard_outlined,
      color: const Color(0xFFE67E22),
      title: _t3(context, ar: 'اكسب مكافآت مضاعفة', en: 'Earn double rewards', es: 'Gana recompensas dobles', tr: 'İki kat ödül kazanın', id: 'Dapatkan reward berlipat',
          hi: 'डबल रिवॉर्ड कमाएं',
          ur: 'ڈبل ریوارڈز حاصل کریں',
          fr: 'Gagnez deux fois plus de récompenses',
          bn: 'দ্বিগুণ পুরস্কার অর্জন করুন'),
      description: _t3(
        context,
        ar: 'كل حجز تقوم به عبر Flynoom يقرّبك أكثر من مكافآت ونقاط إضافية حصرية',
        en: 'Every booking you make through Flynoom brings you closer to extra exclusive rewards and points',
        es: 'Cada reserva que hagas en Flynoom te acerca a recompensas y puntos exclusivos adicionales',
        tr: 'Flynoom üzerinden yaptığınız her rezervasyon, sizi ekstra özel ödül ve puanlara yaklaştırır',
        id: 'Setiap pemesanan melalui Flynoom membawa Anda lebih dekat ke reward dan poin eksklusif tambahan',
        hi: 'Flynoom के ज़रिए की गई हर बुकिंग आपको अतिरिक्त खास रिवॉर्ड और पॉइंट्स के करीब लाती है',
        ur: 'Flynoom کے ذریعے کی گئی ہر بکنگ آپ کو اضافی خصوصی ریوارڈز اور پوائنٹس کے قریب لاتی ہے',
        fr: 'Chaque réservation effectuée via Flynoom vous rapproche de récompenses et de points exclusifs supplémentaires',
        bn: 'Flynoom এর মাধ্যমে করা প্রতিটি বুকিং আপনাকে অতিরিক্ত এক্সক্লুসিভ পুরস্কার ও পয়েন্টের কাছাকাছি নিয়ে যায়',
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
        id: 'umrah',
        icon: Icons.mosque_outlined,
        label: _t3(context, ar: 'العمرة', en: 'Umrah', es: 'Umrah', tr: 'Umre', id: 'Umrah',
            hi: 'उमरा', ur: 'عمرہ', fr: 'Omra', bn: 'উমরাহ'),
      ),
      _TravelTab(
        id: 'groups',
        icon: Icons.groups_outlined,
        label: _t3(context, ar: 'حجوزات المجموعات', en: 'Group stays', es: 'Grupos', tr: 'Grup konaklama', id: 'Grup',
            hi: 'समूह बुकिंग', ur: 'گروپ بکنگ', fr: 'Groupes', bn: 'গ্রুপ বুকিং'),
      ),
      // الطيران و"طيران + فندق" مخفيان حتى يكتمل تسجيل Seller of Travel
      // (انظر core/config/features.dart).
      if (kFlightsEnabled) _TravelTab(
        id: 'flights',
        icon: Icons.flight_takeoff,
        label: _t3(context, ar: 'رحلات الطيران', en: 'Flights', es: 'Vuelos', tr: 'Uçuşlar', id: 'Penerbangan',
            hi: 'उड़ानें',
            ur: 'پروازیں',
            fr: 'Vols',
            bn: 'ফ্লাইট'),
      ),
      if (kFlightsEnabled) _TravelTab(
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
                  if (tab.id == 'stays' || tab.id == 'umrah' || tab.id == 'groups' || tab.id == 'flights' || tab.id == 'flightHotel' || tab.id == 'carRental') {
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
                    // التبويب غير المختار بخلفية داكنة شفافة حتى يبقى مقروءًا
                    // فوق صورة البانر الفاتحة (كان شفافًا تمامًا فيختفي).
                    color: isActive
                        ? AppColors.primaryDark
                        : Colors.black.withOpacity(0.45),
                    borderRadius: BorderRadius.circular(20),
                    border: isActive
                        ? null
                        : Border.all(color: Colors.white.withOpacity(0.7)),
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
/// تنبيه شروط الدخول لمكة والمدينة — يظهر فوق نتائج تبويب العمرة.
/// الهدف: ألا يحجز عميل لا يحق له الدخول ثم يطالب بالمبلغ.
class _UmrahEntryNotice extends StatelessWidget {
  /// يفتح تبويب Group stays (زر "عمرة لمجموعة").
  final VoidCallback? onGroupStays;
  const _UmrahEntryNotice({this.onGroupStays});

  /// روابط رسمية سعودية (تحقق منها أكتوبر 2026):
  ///  - التأشيرة السياحية الإلكترونية (تسمح بالعمرة خارج موسم الحج).
  ///  - منصة نسك عمرة: تصاريح العمرة ودخول المسجد الحرام (إلزامية حتى مع التأشيرة).
  static const _visaUrl = 'https://visa.visitsaudi.com/';
  static const _nusukUrl = 'https://umrah.nusuk.sa/';

  Future<void> _open(BuildContext context, String url) async {
    final ok = await launchUrl(
      Uri.parse(url),
      mode: LaunchMode.externalApplication,
      webOnlyWindowName: '_blank',
    );
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(url)));
    }
  }

  Widget _button({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    bool external = false,
  }) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label),
          if (external) ...[
            const SizedBox(width: 4),
            const Icon(Icons.open_in_new, size: 14),
          ],
        ],
      ),
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.amber.shade900,
        backgroundColor: Colors.white,
        side: BorderSide(color: Colors.amber.shade700),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(AppSizes.md, AppSizes.sm, AppSizes.md, 0),
      padding: const EdgeInsets.all(AppSizes.sm),
      decoration: BoxDecoration(
        color: Colors.amber.withOpacity(0.12),
        border: Border.all(color: Colors.amber.shade700),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.info_outline, color: Colors.amber.shade800, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _t3(context,
                      ar: 'دخول مكة المكرمة مقتصر على المسلمين. تأكد قبل الحجز من حصولك على التأشيرة وتصاريح الدخول المطلوبة؛ الحجز لا يشمل التأشيرة.',
                      en: 'Entry to Makkah is restricted to Muslims. Before booking, make sure you have the required visa and entry permits; your booking does not include a visa.',
                      es: 'La entrada a La Meca está restringida a musulmanes. Antes de reservar, asegúrate de tener el visado y los permisos de entrada necesarios; la reserva no incluye visado.',
                      tr: 'Mekke\'ye giriş Müslümanlarla sınırlıdır. Rezervasyondan önce gerekli vize ve giriş izinlerine sahip olduğunuzdan emin olun; rezervasyon vize içermez.',
                      id: 'Masuk ke Makkah hanya untuk Muslim. Sebelum memesan, pastikan Anda memiliki visa dan izin masuk yang diperlukan; pemesanan tidak termasuk visa.',
                      hi: 'मक्का में प्रवेश केवल मुसलमानों के लिए है। बुकिंग से पहले आवश्यक वीज़ा और प्रवेश अनुमति सुनिश्चित करें; बुकिंग में वीज़ा शामिल नहीं है।',
                      ur: 'مکہ مکرمہ میں داخلہ صرف مسلمانوں کے لیے ہے۔ بکنگ سے پہلے مطلوبہ ویزا اور داخلے کے اجازت نامے یقینی بنائیں؛ بکنگ میں ویزا شامل نہیں۔',
                      fr: 'L\'accès à La Mecque est réservé aux musulmans. Avant de réserver, assurez-vous d\'avoir le visa et les autorisations d\'entrée requis ; la réservation n\'inclut pas de visa.',
                      bn: 'মক্কায় প্রবেশ শুধু মুসলমানদের জন্য। বুকিংয়ের আগে প্রয়োজনীয় ভিসা ও প্রবেশ অনুমতি নিশ্চিত করুন; বুকিংয়ে ভিসা অন্তর্ভুক্ত নয়।'),
                  style: const TextStyle(fontSize: 13, height: 1.4),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsetsDirectional.only(start: 28),
            child: _buttons(context),
          ),
        ],
      ),
    );
  }

  Widget _buttons(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _button(
          icon: Icons.badge_outlined,
          external: true,
          label: _t3(context,
              ar: 'التأشيرة السعودية (الموقع الرسمي)',
              en: 'Saudi eVisa (official site)',
              es: 'eVisa saudí (sitio oficial)',
              tr: 'Suudi e-Vize (resmi site)',
              id: 'eVisa Saudi (situs resmi)',
              hi: 'सऊदी ई-वीज़ा (आधिकारिक साइट)',
              ur: 'سعودی ای ویزا (سرکاری ویب سائٹ)',
              fr: 'eVisa saoudien (site officiel)',
              bn: 'সৌদি ই-ভিসা (অফিসিয়াল সাইট)'),
          onPressed: () => _open(context, _visaUrl),
        ),
        _button(
          icon: Icons.verified_outlined,
          external: true,
          label: _t3(context,
              ar: 'تصاريح العمرة عبر نسك',
              en: 'Umrah permits on Nusuk',
              es: 'Permisos de Umrah en Nusuk',
              tr: 'Nusuk\'ta Umre izinleri',
              id: 'Izin umrah di Nusuk',
              hi: 'नुसुक पर उमरा परमिट',
              ur: 'نسک پر عمرہ اجازت نامے',
              fr: 'Permis de Omra sur Nusuk',
              bn: 'নুসুকে উমরাহ পারমিট'),
          onPressed: () => _open(context, _nusukUrl),
        ),
        if (onGroupStays != null)
          _button(
            icon: Icons.groups_outlined,
            label: _t3(context,
                ar: 'عمرة لمجموعة (5 غرف فأكثر)',
                en: 'Group Umrah (5+ rooms)',
                es: 'Umrah en grupo (5+ habitaciones)',
                tr: 'Grup Umresi (5+ oda)',
                id: 'Umrah grup (5+ kamar)',
                hi: 'समूह उमरा (5+ कमरे)',
                ur: 'گروپ عمرہ (5+ کمرے)',
                fr: 'Omra en groupe (5+ chambres)',
                bn: 'গ্রুপ উমরাহ (৫+ রুম)'),
            onPressed: onGroupStays!,
          ),
      ],
    );
  }
}

/// محتوى تبويب العمرة قبل البحث: لماذا تحجز عمرتك معنا + تنبيه الدخول.
class _UmrahIntro extends StatelessWidget {
  final VoidCallback? onGroupStays;
  const _UmrahIntro({this.onGroupStays});

  @override
  Widget build(BuildContext context) {
    Widget point(IconData icon, String text) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.primary, size: 22),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 14, height: 1.4))),
        ],
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _t3(context,
              ar: 'احجز فندق عمرتك بثقة',
              en: 'Book your Umrah hotel with confidence',
              es: 'Reserva tu hotel para la Umrah con confianza',
              tr: 'Umre otelinizi güvenle rezerve edin',
              id: 'Pesan hotel umrah Anda dengan tenang',
              hi: 'अपना उमरा होटल भरोसे के साथ बुक करें',
              ur: 'اپنا عمرہ ہوٹل اعتماد کے ساتھ بک کریں',
              fr: 'Réservez votre hôtel pour la Omra en toute confiance',
              bn: 'আস্থার সাথে আপনার উমরাহ হোটেল বুক করুন'),
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: AppSizes.sm),
        point(Icons.attach_money, _t3(context,
            ar: 'أسعار شاملة بالدولار، وأي رسوم تُدفع في الفندق تظهر قبل الدفع.',
            en: 'All-in prices in U.S. dollars; any fees paid at the hotel are shown before you pay.',
            es: 'Precios totales en dólares; cualquier cargo a pagar en el hotel se muestra antes de pagar.',
            tr: 'ABD doları ile her şey dahil fiyatlar; otelde ödenecek ücretler ödeme öncesi gösterilir.',
            id: 'Harga total dalam dolar AS; biaya yang dibayar di hotel ditampilkan sebelum membayar.',
            hi: 'अमेरिकी डॉलर में कुल कीमतें; होटल में देय शुल्क भुगतान से पहले दिखाए जाते हैं।',
            ur: 'امریکی ڈالر میں مکمل قیمتیں؛ ہوٹل میں قابلِ ادائیگی فیس ادائیگی سے پہلے دکھائی جاتی ہے۔',
            fr: 'Prix tout compris en dollars ; les frais payables à l\'hôtel sont indiqués avant le paiement.',
            bn: 'মার্কিন ডলারে সব-মিলিয়ে দাম; হোটেলে প্রদেয় ফি পেমেন্টের আগে দেখানো হয়।')),
        point(Icons.event_available_outlined, _t3(context,
            ar: 'سياسة الإلغاء واضحة لكل غرفة، بتوقيت مكة والمدينة.',
            en: 'A clear cancellation policy for every room, in local Saudi time.',
            es: 'Política de cancelación clara para cada habitación, en hora local saudí.',
            tr: 'Her oda için Suudi yerel saatine göre net iptal politikası.',
            id: 'Kebijakan pembatalan yang jelas untuk setiap kamar, dalam waktu setempat Saudi.',
            hi: 'हर कमरे के लिए स्पष्ट रद्दीकरण नीति, सऊदी स्थानीय समय में।',
            ur: 'ہر کمرے کے لیے واضح منسوخی پالیسی، سعودی مقامی وقت کے مطابق۔',
            fr: 'Une politique d\'annulation claire pour chaque chambre, à l\'heure locale saoudienne.',
            bn: 'প্রতিটি রুমের জন্য সৌদি স্থানীয় সময়ে স্পষ্ট বাতিল নীতি।')),
        point(Icons.support_agent, _t3(context,
            ar: 'مساعدة بالعربية والإنجليزية من فريق حقيقي.',
            en: 'Help in Arabic and English from real people.',
            es: 'Ayuda en árabe e inglés de personas reales.',
            tr: 'Gerçek kişilerden Arapça ve İngilizce destek.',
            id: 'Bantuan dalam bahasa Arab dan Inggris dari orang sungguhan.',
            hi: 'असली लोगों से अरबी और अंग्रेज़ी में सहायता।',
            ur: 'حقیقی لوگوں سے عربی اور انگریزی میں مدد۔',
            fr: 'Une aide en arabe et en anglais par de vraies personnes.',
            bn: 'সত্যিকারের মানুষের কাছ থেকে আরবি ও ইংরেজিতে সহায়তা।')),
        const SizedBox(height: AppSizes.sm),
        _UmrahEntryNotice(onGroupStays: onGroupStays),
        const SizedBox(height: AppSizes.lg),
      ],
    );
  }
}

/// نموذج طلب حجز مجموعة (5 غرف فأكثر). يُحفظ في جدول group_stay_requests
/// ويُرد عليه يدويًا بعرض سعر. لا دفع ولا حجز هنا.
class _GroupStaysForm extends StatefulWidget {
  final DateTime initialCheckIn;
  final DateTime initialCheckOut;
  const _GroupStaysForm({required this.initialCheckIn, required this.initialCheckOut});

  @override
  State<_GroupStaysForm> createState() => _GroupStaysFormState();
}

class _GroupStaysFormState extends State<_GroupStaysForm> {
  final _formKey = GlobalKey<FormState>();
  final _city = TextEditingController();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _notes = TextEditingController();
  late DateTime _checkIn = widget.initialCheckIn;
  late DateTime _checkOut = widget.initialCheckOut;
  int _rooms = 5;
  int _guests = 10;
  String _occasion = 'umrah';
  bool _sending = false;
  bool _sent = false;

  /// أشهر وجهات المجموعات: الضغط على البطاقة يملأ حقل المدينة ونوع المجموعة.
  /// (الاسم الإنجليزي يُكتب في الحقل والبريد، الاسم العربي للعرض، نوع المجموعة، اسم ملف الصورة)
  ///
  /// الصور: assets/images/destinations/group_<الاسم>.jpg (مثل group_istanbul.jpg).
  /// إن لم توجد الصورة تظهر البطاقة بخلفية ملونة وأيقونة، فلا يتعطل شيء.
  static const _popularGroupDestinations = <(String, String, String, String)>[
    ('Makkah', 'مكة المكرمة', 'umrah', 'makkah'),
    ('Madinah', 'المدينة المنورة', 'umrah', 'madinah'),
    ('Istanbul', 'إسطنبول', 'tour', 'istanbul'),
    ('Trabzon', 'طرابزون', 'tour', 'trabzon'),
    ('Antalya', 'أنطاليا', 'tour', 'antalya'),
    ('Dubai', 'دبي', 'tour', 'dubai'),
    ('Cairo', 'القاهرة', 'tour', 'cairo'),
    ('Sharm El Sheikh', 'شرم الشيخ', 'tour', 'sharm'),
    ('Amman', 'عمّان', 'tour', 'amman'),
    ('Marrakech', 'مراكش', 'tour', 'marrakech'),
    ('Kuala Lumpur', 'كوالالمبور', 'tour', 'kuala_lumpur'),
    ('Orlando', 'أورلاندو', 'family', 'orlando'),
  ];

  Widget _destinationCard(BuildContext context, (String, String, String, String) d, bool isArabic) {
    final selected = _city.text == d.$1;
    final fallback = Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, AppColors.primaryDark],
        ),
      ),
      alignment: Alignment.center,
      child: Icon(
        d.$3 == 'umrah' ? Icons.mosque_outlined : Icons.place_outlined,
        color: Colors.white.withOpacity(0.5),
        size: 40,
      ),
    );

    return SizedBox(
      width: 150,
      height: 110,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => setState(() {
            _city.text = d.$1;
            _occasion = d.$3;
          }),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.asset(
                'assets/images/destinations/group_${d.$4}.jpg',
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => fallback,
              ),
              // تدرّج داكن أسفل الصورة حتى يُقرأ الاسم.
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Colors.black87],
                    stops: [0.45, 1.0],
                  ),
                ),
              ),
              Positioned(
                left: 8,
                right: 8,
                bottom: 8,
                child: Text(
                  isArabic ? d.$2 : d.$1,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
              if (selected)
                PositionedDirectional(
                  top: 6,
                  end: 6,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                    child: const Icon(Icons.check_circle, color: AppColors.primary, size: 22),
                  ),
                ),
              // إطار البطاقة المختارة.
              IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: selected ? AppColors.primary : Colors.black12,
                      width: selected ? 3 : 1,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _popularDestinations(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _t3(context,
              ar: 'وجهات شائعة للمجموعات',
              en: 'Popular group destinations',
              es: 'Destinos populares para grupos',
              tr: 'Gruplar için popüler yerler',
              id: 'Tujuan grup populer',
              hi: 'समूहों के लिए लोकप्रिय गंतव्य',
              ur: 'گروپس کے لیے مقبول مقامات',
              fr: 'Destinations populaires pour les groupes',
              bn: 'গ্রুপের জন্য জনপ্রিয় গন্তব্য'),
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (final d in _popularGroupDestinations) _destinationCard(context, d, isArabic),
          ],
        ),
      ],
    );
  }

  @override
  void initState() {
    super.initState();
    _email.text = Supabase.instance.client.auth.currentUser?.email ?? '';
  }

  @override
  void dispose() {
    _city.dispose();
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    _notes.dispose();
    super.dispose();
  }

  String _d(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<void> _pickDates() async {
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 540)),
      initialDateRange: DateTimeRange(start: _checkIn, end: _checkOut),
    );
    if (range != null) {
      setState(() {
        _checkIn = range.start;
        _checkOut = range.end;
      });
    }
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _sending = true);
    try {
      await Supabase.instance.client.from('group_stay_requests').insert({
        'user_id': Supabase.instance.client.auth.currentUser?.id,
        'destination': _city.text.trim(),
        'check_in': _d(_checkIn),
        'check_out': _d(_checkOut),
        'rooms': _rooms,
        'guests': _guests,
        'occasion': _occasion,
        'contact_name': _name.text.trim(),
        'contact_email': _email.text.trim(),
        'contact_phone': _phone.text.trim(),
        'notes': _notes.text.trim(),
        'language': Localizations.localeOf(context).languageCode,
      });
      if (!mounted) return;
      setState(() {
        _sending = false;
        _sent = true;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _sending = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(_t3(context,
            ar: 'تعذر إرسال الطلب. حاول مرة أخرى أو راسلنا على support@flynoom.com',
            en: 'We could not send your request. Please try again or email support@flynoom.com',
            es: 'No pudimos enviar tu solicitud. Inténtalo de nuevo o escribe a support@flynoom.com',
            tr: 'Talebiniz gönderilemedi. Tekrar deneyin veya support@flynoom.com adresine yazın',
            id: 'Permintaan gagal dikirim. Coba lagi atau email support@flynoom.com',
            hi: 'अनुरोध नहीं भेजा जा सका। फिर कोशिश करें या support@flynoom.com पर ईमेल करें',
            ur: 'درخواست نہیں بھیجی جا سکی۔ دوبارہ کوشش کریں یا support@flynoom.com پر ای میل کریں',
            fr: 'Impossible d\'envoyer la demande. Réessayez ou écrivez à support@flynoom.com',
            bn: 'অনুরোধ পাঠানো যায়নি। আবার চেষ্টা করুন বা support@flynoom.com এ ইমেল করুন')),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_sent) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.lg),
          child: Column(
            children: [
              const Icon(Icons.check_circle, color: AppColors.success, size: 48),
              const SizedBox(height: AppSizes.sm),
              Text(
                _t3(context,
                    ar: 'استلمنا طلبك. سنرسل لك عرض السعر بالبريد خلال يومي عمل.',
                    en: 'We received your request. We will email you a quote within two business days.',
                    es: 'Recibimos tu solicitud. Te enviaremos un presupuesto por correo en dos días hábiles.',
                    tr: 'Talebinizi aldık. İki iş günü içinde e-postayla teklif göndereceğiz.',
                    id: 'Permintaan Anda diterima. Kami akan mengirim penawaran lewat email dalam dua hari kerja.',
                    hi: 'आपका अनुरोध मिल गया। हम दो कार्यदिवसों में ईमेल से कोटेशन भेजेंगे।',
                    ur: 'آپ کی درخواست موصول ہو گئی۔ ہم دو کاروباری دنوں میں ای میل پر قیمت بھیجیں گے۔',
                    fr: 'Nous avons reçu votre demande. Nous vous enverrons un devis par e-mail sous deux jours ouvrés.',
                    bn: 'আপনার অনুরোধ পেয়েছি। দুই কর্মদিবসের মধ্যে ইমেলে মূল্য পাঠাব।'),
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      );
    }

    String? req(String? v) => (v == null || v.trim().isEmpty)
        ? _t3(context, ar: 'مطلوب', en: 'Required', es: 'Obligatorio', tr: 'Zorunlu', id: 'Wajib',
        hi: 'आवश्यक', ur: 'ضروری', fr: 'Obligatoire', bn: 'আবশ্যক')
        : null;

    InputDecoration deco(String label, IconData icon) => InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      border: const OutlineInputBorder(),
      isDense: true,
    );

    Widget counter(String label, int value, int min, int max, ValueChanged<int> onChanged) => Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        IconButton(
          icon: const Icon(Icons.remove_circle_outline),
          onPressed: value > min ? () => onChanged(value - 1) : null,
        ),
        Text('$value', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        IconButton(
          icon: const Icon(Icons.add_circle_outline),
          onPressed: value < max ? () => onChanged(value + 1) : null,
        ),
      ],
    );

    final occasions = <String, String>{
      'umrah': _t3(context, ar: 'مجموعة عمرة', en: 'Umrah group', es: 'Grupo de Umrah', tr: 'Umre grubu', id: 'Grup umrah',
          hi: 'उमरा समूह', ur: 'عمرہ گروپ', fr: 'Groupe Omra', bn: 'উমরাহ গ্রুপ'),
      'wedding': _t3(context, ar: 'حفل زفاف', en: 'Wedding', es: 'Boda', tr: 'Düğün', id: 'Pernikahan',
          hi: 'शादी', ur: 'شادی', fr: 'Mariage', bn: 'বিয়ে'),
      'event': _t3(context, ar: 'مؤتمر أو فعالية', en: 'Conference or event', es: 'Congreso o evento', tr: 'Konferans veya etkinlik', id: 'Konferensi atau acara',
          hi: 'सम्मेलन या कार्यक्रम', ur: 'کانفرنس یا تقریب', fr: 'Conférence ou événement', bn: 'সম্মেলন বা অনুষ্ঠান'),
      'tour': _t3(context, ar: 'رحلة سياحية', en: 'Tour group', es: 'Grupo turístico', tr: 'Tur grubu', id: 'Grup wisata',
          hi: 'पर्यटन समूह', ur: 'سیاحتی گروپ', fr: 'Groupe touristique', bn: 'ভ্রমণ গ্রুপ'),
      'family': _t3(context, ar: 'عائلة كبيرة', en: 'Family gathering', es: 'Reunión familiar', tr: 'Aile toplantısı', id: 'Acara keluarga',
          hi: 'पारिवारिक समारोह', ur: 'خاندانی اجتماع', fr: 'Réunion de famille', bn: 'পারিবারিক সমাবেশ'),
      'other': _t3(context, ar: 'أخرى', en: 'Other', es: 'Otro', tr: 'Diğer', id: 'Lainnya',
          hi: 'अन्य', ur: 'دیگر', fr: 'Autre', bn: 'অন্যান্য'),
    };

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.md),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                _t3(context, ar: 'طلب عرض سعر لمجموعة', en: 'Request a group quote', es: 'Solicitar presupuesto de grupo',
                    tr: 'Grup teklifi isteyin', id: 'Minta penawaran grup', hi: 'समूह कोटेशन का अनुरोध करें',
                    ur: 'گروپ کی قیمت کی درخواست', fr: 'Demander un devis de groupe', bn: 'গ্রুপ মূল্যের অনুরোধ'),
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: AppSizes.md),
              _popularDestinations(context),
              const SizedBox(height: AppSizes.md),
              TextFormField(
                controller: _city,
                onChanged: (_) => setState(() {}),
                decoration: deco(
                    _t3(context, ar: 'المدينة', en: 'Destination city', es: 'Ciudad de destino', tr: 'Varış şehri', id: 'Kota tujuan',
                        hi: 'गंतव्य शहर', ur: 'منزل کا شہر', fr: 'Ville de destination', bn: 'গন্তব্য শহর'),
                    Icons.location_on_outlined),
                validator: req,
              ),
              const SizedBox(height: AppSizes.sm),
              OutlinedButton.icon(
                onPressed: _pickDates,
                icon: const Icon(Icons.calendar_today_outlined, size: 18),
                label: Text('${_d(_checkIn)}  →  ${_d(_checkOut)}'),
              ),
              const SizedBox(height: AppSizes.sm),
              Wrap(
                spacing: AppSizes.md,
                children: [
                  counter(_t3(context, ar: 'الغرف', en: 'Rooms', es: 'Habitaciones', tr: 'Oda', id: 'Kamar',
                      hi: 'कमरे', ur: 'کمرے', fr: 'Chambres', bn: 'রুম'), _rooms, 5, 200,
                      // الضيوف لا يقلّون عن عدد الغرف (ضيف واحد على الأقل لكل غرفة).
                          (v) => setState(() {
                        _rooms = v;
                        if (_guests < v) _guests = v;
                      })),
                  counter(_t3(context, ar: 'الضيوف', en: 'Guests', es: 'Huéspedes', tr: 'Misafir', id: 'Tamu',
                      hi: 'मेहमान', ur: 'مہمان', fr: 'Personnes', bn: 'অতিথি'), _guests, _rooms, 600,
                          (v) => setState(() => _guests = v)),
                ],
              ),
              const SizedBox(height: AppSizes.sm),
              DropdownButtonFormField<String>(
                value: _occasion,
                decoration: deco(
                    _t3(context, ar: 'المناسبة', en: 'Occasion', es: 'Motivo', tr: 'Etkinlik', id: 'Acara',
                        hi: 'अवसर', ur: 'موقع', fr: 'Occasion', bn: 'উপলক্ষ'),
                    Icons.celebration_outlined),
                items: occasions.entries
                    .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
                    .toList(),
                onChanged: (v) => setState(() => _occasion = v ?? 'other'),
              ),
              const SizedBox(height: AppSizes.sm),
              TextFormField(
                controller: _name,
                decoration: deco(
                    _t3(context, ar: 'الاسم الكامل', en: 'Full name', es: 'Nombre completo', tr: 'Ad soyad', id: 'Nama lengkap',
                        hi: 'पूरा नाम', ur: 'پورا نام', fr: 'Nom complet', bn: 'পূর্ণ নাম'),
                    Icons.person_outline),
                validator: req,
              ),
              const SizedBox(height: AppSizes.sm),
              TextFormField(
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                decoration: deco(
                    _t3(context, ar: 'البريد الإلكتروني', en: 'Email', es: 'Correo electrónico', tr: 'E-posta', id: 'Email',
                        hi: 'ईमेल', ur: 'ای میل', fr: 'E-mail', bn: 'ইমেইল'),
                    Icons.email_outlined),
                validator: (v) {
                  final r = req(v);
                  if (r != null) return r;
                  return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v!.trim())
                      ? null
                      : _t3(context, ar: 'بريد غير صحيح', en: 'Invalid email', es: 'Correo no válido', tr: 'Geçersiz e-posta',
                      id: 'Email tidak valid', hi: 'अमान्य ईमेल', ur: 'غلط ای میل', fr: 'E-mail invalide', bn: 'অবৈধ ইমেইল');
                },
              ),
              const SizedBox(height: AppSizes.sm),
              TextFormField(
                controller: _phone,
                keyboardType: TextInputType.phone,
                decoration: deco(
                    _t3(context, ar: 'رقم الهاتف', en: 'Phone number', es: 'Teléfono', tr: 'Telefon', id: 'Nomor telepon',
                        hi: 'फ़ोन नंबर', ur: 'فون نمبر', fr: 'Téléphone', bn: 'ফোন নম্বর'),
                    Icons.phone_outlined),
                validator: req,
              ),
              const SizedBox(height: AppSizes.sm),
              TextFormField(
                controller: _notes,
                maxLines: 3,
                maxLength: 1000,
                decoration: deco(
                    _t3(context, ar: 'ملاحظات (اختياري): الميزانية، نوع الغرف، القرب من الحرم...',
                        en: 'Notes (optional): budget, room types, location preferences...',
                        es: 'Notas (opcional): presupuesto, tipos de habitación, ubicación...',
                        tr: 'Notlar (isteğe bağlı): bütçe, oda tipleri, konum tercihleri...',
                        id: 'Catatan (opsional): anggaran, tipe kamar, preferensi lokasi...',
                        hi: 'नोट्स (वैकल्पिक): बजट, कमरे का प्रकार, स्थान...',
                        ur: 'نوٹس (اختیاری): بجٹ، کمروں کی قسم، مقام...',
                        fr: 'Remarques (facultatif) : budget, types de chambres, emplacement...',
                        bn: 'নোট (ঐচ্ছিক): বাজেট, রুমের ধরন, অবস্থান...'),
                    Icons.notes_outlined),
              ),
              const SizedBox(height: AppSizes.sm),
              ElevatedButton.icon(
                onPressed: _sending ? null : _submit,
                icon: _sending
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.send),
                label: Text(_t3(context, ar: 'إرسال الطلب', en: 'Send request', es: 'Enviar solicitud', tr: 'Talebi gönder',
                    id: 'Kirim permintaan', hi: 'अनुरोध भेजें', ur: 'درخواست بھیجیں', fr: 'Envoyer la demande', bn: 'অনুরোধ পাঠান')),
              ),
              const SizedBox(height: 6),
              Text(
                _t3(context,
                    ar: 'هذا طلب عرض سعر وليس حجزًا. لن يُخصم أي مبلغ الآن.',
                    en: 'This is a quote request, not a booking. You will not be charged.',
                    es: 'Esto es una solicitud de presupuesto, no una reserva. No se te cobrará nada.',
                    tr: 'Bu bir teklif talebidir, rezervasyon değildir. Ücret alınmaz.',
                    id: 'Ini permintaan penawaran, bukan pemesanan. Anda tidak akan ditagih.',
                    hi: 'यह कोटेशन अनुरोध है, बुकिंग नहीं। कोई शुल्क नहीं लिया जाएगा।',
                    ur: 'یہ قیمت کی درخواست ہے، بکنگ نہیں۔ کوئی رقم نہیں لی جائے گی۔',
                    fr: 'Ceci est une demande de devis, pas une réservation. Aucun montant ne sera débité.',
                    bn: 'এটি একটি মূল্যের অনুরোধ, বুকিং নয়। কোনো টাকা কাটা হবে না।'),
                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}