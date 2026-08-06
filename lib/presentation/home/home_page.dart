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
import 'widgets/deals_section.dart';
import 'widgets/accommodation_types_section.dart';
import 'widgets/featured_hotels_section.dart';
import 'widgets/faq_section.dart';
import 'widgets/search_filters_sidebar.dart';
import 'controllers/hotel_filters_controller.dart';
import 'controllers/duffel_flight_search_controller.dart';
import '../../data/repositories/duffel_repository.dart';
import '../../data/models/hotel_model.dart';
import '../../data/models/flight_model.dart';
import '../../data/models/car_model.dart';
import '../../localization/app_localizations.dart';
import '../auth/controllers/auth_controller.dart';
import '../favorites/controllers/favorites_controller.dart';
import '../search/controllers/search_controller.dart';

/// يختار النص المناسب حسب اللغة الحالية (عربي/إنجليزي/إسباني)، بدل الاعتماد
/// على شرط ثنائي (عربي/غير عربي) اللي كان بيرجّع الإنجليزي دايمًا للإسباني.
String _t3(
    BuildContext context, {
      required String ar,
      required String en,
      required String es,
    }) {
  switch (Localizations.localeOf(context).languageCode) {
    case 'ar':
      return ar;
    case 'es':
      return es;
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

  final _cityController = TextEditingController();
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
    super.dispose();
  }

  void _runSearch() {
    if (_cityController.text.trim().isEmpty) return;
    setState(() {
      _searchParams = {
        'city': _cityController.text.trim(),
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
    final city = _cityController.text.trim();

    if (origin.isEmpty || destination.isEmpty || city.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _t3(
              context,
              ar: 'من فضلك أكمل بيانات الرحلة والإقامة كلها',
              en: 'Please fill in both the flight and stay details',
              es: 'Completa los datos del vuelo y la estancia',
            ),
          ),
        ),
      );
      return;
    }

    ref.read(flightHotelSelectionProvider.notifier).state = (offer: null, hotel: null);
    setState(() {
      _searchParams = {
        'city': city,
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

  /// يُستدعى عند الضغط على وجهة من قسم "وجهات رائجة"، فيملأ حقل المدينة
  /// وينفّذ البحث مباشرة.
  void _selectDestination(String city) {
    _cityController.text = city;
    _runSearch();
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
        assetVariant: _activeTab == 'flights'
            ? 'flights'
            : _activeTab == 'carRental'
            ? 'car_rental'
            : _activeTab == 'flightHotel'
            ? 'flight_hotel'
            : null,
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
              Padding(
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
                  children: const [_TrustSection(), AppFooter()],
                )
                    : _DuffelFlightSearchResults(params: _flightSearchParams!))
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
                    const AccommodationTypesSection(),
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
                  onSubmitted: (_) => _runSearch(),
                ),
              ),
            ],
          ),
          const Divider(height: 16),
          Row(
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
                              ? (_t3(context, ar: 'ليلة واحدة', en: '1 night', es: '1 noche'))
                              : (_t3(context, ar: '$nights ليالي', en: '$nights nights', es: '$nights noches')),
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
                                  _t3(context, ar: 'الضيوف', en: 'Guests', es: 'Huéspedes'),
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
                                    child: Text(_t3(context, ar: 'تم', en: 'Done', es: 'Listo')),
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
                        ),
                        style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ),
              const Spacer(),
              Flexible(
                child: ElevatedButton.icon(
                  onPressed: _runSearch,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF87CEEB),
                    foregroundColor: Colors.white,
                    shape: const StadiumBorder(),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  ),
                  icon: const Icon(Icons.search, size: 18),
                  label: Text(l10n.search),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }


  Widget _buildFlightsSearchBox() {

    final tripTypeLabels = <String, String>{
      'roundtrip': _t3(context, ar: 'ذهاب وعودة', en: 'Roundtrip', es: 'Ida y vuelta'),
      'oneWay': _t3(context, ar: 'ذهاب فقط', en: 'One-way', es: 'Solo ida'),
      'multiCity': _t3(context, ar: 'وجهات متعددة', en: 'Multi-city', es: 'Multidestino'),
    };

    final travelersLabel =
        '$_flightTravelers ${_flightTravelers == 1 ? (_t3(context, ar: "مسافر", en: "traveler", es: "viajero")) : (_t3(context, ar: "مسافرين", en: "travelers", es: "viajeros"))}, $_flightCabinClass';

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
                    _t3(context, ar: 'بدون توقف', en: 'Nonstop', es: 'Sin escalas'),
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
                        hintText: _t3(context, ar: 'المغادرة من', en: 'Leaving from', es: 'Saliendo de'),
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
                        hintText: _t3(context, ar: 'الوجهة', en: 'Going to', es: 'A dónde'),
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
                  const SizedBox(width: 16),
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
                  const Spacer(),
                  Flexible(
                    child: ElevatedButton.icon(
                      onPressed: _runFlightSearch,
                      style: ElevatedButton.styleFrom(
                        shape: const StadiumBorder(),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                      ),
                      icon: const Icon(Icons.search, size: 18),
                      label: Text(_t3(context, ar: 'بحث', en: 'Search', es: 'Buscar')),
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
            Text(_t3(context, ar: 'أضف مكان إقامة', en: 'Add a place to stay', es: 'Añadir alojamiento')),
            const SizedBox(width: AppSizes.md),
            Checkbox(
              value: _addCar,
              onChanged: (v) => setState(() => _addCar = v ?? false),
            ),
            Text(_t3(context, ar: 'أضف سيارة', en: 'Add a car', es: 'Añadir un coche')),
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
                    hintText: _t3(context, ar: 'المغادرة من', en: 'Leaving from', es: 'Saliendo de'),
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
                    hintText: _t3(context, ar: 'الوجهة', en: 'Going to', es: 'A dónde'),
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
                    hintText: _t3(context, ar: 'الإقامة في؟ (المدينة)', en: 'Stay in? (City)', es: '¿Dónde te alojas? (Ciudad)'),
                    hintStyle: const TextStyle(color: Colors.black45),
                    border: InputBorder.none,
                    isDense: true,
                  ),
                  onSubmitted: (_) => _runFlightHotelSearch(),
                ),
              ),
            ],
          ),
          const Divider(height: 16),
          Row(
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
                            ? (_t3(context, ar: 'ليلة واحدة', en: '1 night', es: '1 noche'))
                            : (_t3(context, ar: '$nights ليالي', en: '$nights nights', es: '$nights noches')),
                        style: const TextStyle(fontSize: 12, color: Colors.white),
                      ),
                    ),
                  ],
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
                                  _t3(context, ar: 'الضيوف', en: 'Guests', es: 'Huéspedes'),
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
                                    child: Text(_t3(context, ar: 'تم', en: 'Done', es: 'Listo')),
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
                      ),
                      style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.white),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Flexible(
                child: ElevatedButton.icon(
                  onPressed: _runFlightHotelSearch,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF8FB8D6),
                    foregroundColor: Colors.white,
                    shape: const StadiumBorder(),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  ),
                  icon: const Icon(Icons.search, size: 18),
                  label: Text(l10n.search),
                ),
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
                    hintText: _t3(context, ar: 'مكان الاستلام', en: 'Pick-up location', es: 'Lugar de recogida'),
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
                _t3(context, ar: 'مكان تسليم مختلف', en: 'Different drop-off location', es: 'Lugar de devolución diferente'),
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
                      hintText: _t3(context, ar: 'مكان التسليم', en: 'Drop-off location', es: 'Lugar de devolución'),
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
          Row(
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
              const Spacer(),
              Flexible(
                child: ElevatedButton.icon(
                  onPressed: _runCarRentalSearch,
                  style: ElevatedButton.styleFrom(
                    shape: const StadiumBorder(),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  ),
                  icon: const Icon(Icons.search, size: 18),
                  label: Text(l10n.search),
                ),
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
          _t3(context, ar: 'رحلات الطيران', en: 'Flights', es: 'Vuelos'),
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
          _t3(context, ar: 'الفنادق', en: 'Hotels', es: 'Hoteles'),
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
            ),
          ),
        ),
      );
    }
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
                      child: hotel.images.isNotEmpty
                          ? Image.network(
                        hotel.images.first,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                        const Icon(Icons.hotel, color: AppColors.textHint),
                      )
                          : const Icon(Icons.hotel, color: AppColors.textHint),
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
                                        _t3(context, ar: 'الخريطة', en: 'Map', es: 'Mapa'),
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
                          const SizedBox(width: 8),
                          RatingBadge(
                            rating: hotel.rating,
                            reviewCount: hotel.reviewCount,
                          ),
                        ],
                      ),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Expanded(
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.baseline,
                              textBaseline: TextBaseline.alphabetic,
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
                          Flexible(
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
                                    ? _t3(context, ar: 'مختار', en: 'Selected', es: 'Seleccionado')
                                    : _t3(context, ar: 'اختر', en: 'Select', es: 'Elegir'),
                              ),
                            )
                                : ElevatedButton.icon(
                              onPressed: () => _openHotelDetails(context, searchParams),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              ),
                              icon: Text(l10n.bookNow),
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
        ),
      ),
      error: (error, _) => ErrorView(
        message: error.toString().replaceFirst('Exception: ', ''),
        onRetry: () => ref.invalidate(duffelFlightSearchResultsProvider(params)),
      ),
      data: (offers) {
        if (offers.isEmpty) {
          return ListView(
            padding: const EdgeInsets.all(AppSizes.md),
            children: [
              EmptyView(
                message: _t3(
                  context,
                  ar: 'لا توجد رحلات متاحة لهذا المسار والتاريخ',
                  en: 'No flights available for this route and date',
                  es: 'No hay vuelos disponibles para esta ruta y fecha',
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
          itemCount: offers.length + 2,
          itemBuilder: (context, index) {
            if (index == offers.length) return const _TrustSection();
            if (index == offers.length + 1) return const AppFooter();
            return _DuffelFlightCard(offer: offers[index]);
          },
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
    final duration = offer.arrivalTime.difference(offer.departureTime);
    final hours = duration.inMinutes ~/ 60;
    final minutes = duration.inMinutes % 60;

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
                      _t3(context, ar: 'بدون توقف', en: 'Nonstop', es: 'Sin escalas'),
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
                Flexible(
                  child: onSelect != null
                      ? ElevatedButton.icon(
                    onPressed: onSelect,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: (selected ?? false) ? AppColors.success : null,
                    ),
                    icon: Icon((selected ?? false) ? Icons.check_circle : Icons.add_circle_outline, size: 16),
                    label: Text(
                      (selected ?? false)
                          ? _t3(context, ar: 'مختارة', en: 'Selected', es: 'Seleccionado')
                          : _t3(context, ar: 'اختر', en: 'Select', es: 'Elegir'),
                    ),
                  )
                      : ElevatedButton(
                    onPressed: () {
                      context.push(
                        AppRoutes.duffelFlightBooking,
                        extra: {'offer': offer},
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
        ),
      ),
      error: (error, _) => ErrorView(
        message: _t3(
          context,
          ar: 'تعذر تحميل النتائج، تحقق من الاتصال',
          en: 'Could not load results, check your connection',
          es: 'No se pudieron cargar los resultados, revisa tu conexión',
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
      title: _t3(context, ar: 'المفضّل لدى المسافرين', en: "Travelers' favorite", es: 'Favorito de viajeros'),
      description: _t3(
        context,
        ar: 'آلاف المسافرين اختاروا Safr-AI لحجز رحلاتهم والفنادق بثقة ورضا كامل',
        en: 'Thousands of travelers choose Safr-AI to book their trips and hotels with confidence',
        es: 'Miles de viajeros eligen Safr-AI para reservar sus viajes y hoteles con confianza',
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
      ),
      description: _t3(
        context,
        ar: 'فريق الدعم عندنا جاهز يساعدك في أي وقت طوال أيام الأسبوع بدون توقف',
        en: 'Our support team is ready to help you anytime, any day of the week, without stopping',
        es: 'Nuestro equipo de soporte está listo para ayudarte a cualquier hora, todos los días',
      ),
      ),
      (
      icon: Icons.sell_outlined,
      color: const Color(0xFF0984E3),
      title: _t3(context, ar: 'أسعار شفافة', en: 'Transparent pricing', es: 'Precios transparentes'),
      description: _t3(
        context,
        ar: 'كل الأسعار واضحة من غير رسوم مخفية، وتقدر تشوف التفاصيل قبل ما تأكد الحجز',
        en: 'All prices are clear with no hidden fees, and you can see full details before confirming',
        es: 'Todos los precios son claros sin cargos ocultos, y puedes ver los detalles antes de confirmar',
      ),
      ),
      (
      icon: Icons.card_giftcard_outlined,
      color: const Color(0xFFE67E22),
      title: _t3(context, ar: 'اكسب مكافآت مضاعفة', en: 'Earn double rewards', es: 'Gana recompensas dobles'),
      description: _t3(
        context,
        ar: 'كل حجز تعمله من خلال Safr-AI بيقرّبك أكتر من مكافآت ونقاط إضافية حصرية',
        en: 'Every booking you make through Safr-AI brings you closer to extra exclusive rewards and points',
        es: 'Cada reserva que hagas en Safr-AI te acerca a recompensas y puntos exclusivos adicionales',
      ),
      ),
    ];

    return Padding(
      padding: const EdgeInsets.only(top: AppSizes.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _t3(context, ar: 'ثق بينا نوصلك', en: 'Trust us to take you there', es: 'Confía en nosotros'),
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
      ),
      description: _t3(
        context,
        ar: 'احصل على أسعار تأجير سيارات حصرية لما تكون حاجز رحلة طيران أو فندق معانا',
        en: 'Unlock exclusive car rental prices for your booked flights or hotels',
        es: 'Desbloquea precios exclusivos de alquiler al reservar vuelos u hoteles',
      ),
      ),
      (
      icon: Icons.schedule_outlined,
      color: const Color(0xFF0984E3),
      title: _t3(context, ar: 'تأجير مرن', en: 'Flexible rentals', es: 'Alquileres flexibles'),
      description: _t3(
        context,
        ar: 'سياسة إلغاء مرنة تخليك تخطط لرحلتك من غير قلق',
        en: 'Flexible cancellation policy - plan your trip with ease',
        es: 'Política de cancelación flexible: planifica tu viaje sin preocupaciones',
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
      ),
      description: _t3(
        context,
        ar: 'لو رحلة الطيران أو القطار أو الباص اللي حجزتها اتأخرت أو اتلغت، تقدر تتواصل معانا نساعدك تفضي أو تلغي حجز السيارة مجانًا',
        en: 'If your flight, train, or bus is delayed or canceled, contact us for free help to keep or cancel your rental car',
        es: 'Si tu vuelo, tren o autobús se retrasa o cancela, contáctanos para ayuda gratuita con tu alquiler',
      ),
      ),
      (
      icon: Icons.bolt_outlined,
      color: const Color(0xFFE67E22),
      title: _t3(context, ar: 'دعم عملاء سريع', en: 'Rapid customer support', es: 'Soporte rápido'),
      description: _t3(
        context,
        ar: 'بنرد على مكالمتك عادةً خلال ٣٠ ثانية، ودعم موثوق طول رحلة تأجير السيارة',
        en: 'We usually answer your call within 30 seconds, ensuring reliable support throughout your rental',
        es: 'Solemos responder tu llamada en 30 segundos, con soporte confiable durante todo tu alquiler',
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
              ar: 'مميزات تأجير السيارات معانا',
              en: 'Why rent a car with us',
              es: 'Por qué alquilar con nosotros',
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
                      _t3(context, ar: 'بدون توقف', en: 'Nonstop', es: 'Sin escalas'),
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
        ),
      ),
      error: (error, _) => ErrorView(
        message: _t3(
          context,
          ar: 'تعذر تحميل النتائج، تحقق من الاتصال',
          en: 'Could not load results, check your connection',
          es: 'No se pudieron cargar los resultados, revisa tu conexión',
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
                        _t3(context, ar: '/يوم', en: '/day', es: '/día'),
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
    return _t3(context, ar: 'قريبًا', en: 'Coming soon', es: 'Próximamente');
  }

  @override
  Widget build(BuildContext context) {

    final tabs = <_TravelTab>[
      _TravelTab(
        id: 'stays',
        icon: Icons.bed_outlined,
        label: _t3(context, ar: 'الإقامة', en: 'Stays', es: 'Alojamientos'),
      ),
      _TravelTab(
        id: 'flights',
        icon: Icons.flight_takeoff,
        label: _t3(context, ar: 'رحلات الطيران', en: 'Flights', es: 'Vuelos'),
      ),
      _TravelTab(
        id: 'flightHotel',
        icon: Icons.airplane_ticket_outlined,
        label: _t3(context, ar: 'طيران + فندق', en: 'Flight + Hotel', es: 'Vuelo + Hotel'),
      ),
      _TravelTab(
        id: 'carRental',
        icon: Icons.directions_car_filled_outlined,
        label: _t3(context, ar: 'تأجير السيارات', en: 'Car rental', es: 'Alquiler de coches'),
      ),
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 18),
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
                  padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
                  decoration: BoxDecoration(
                    color: isActive ? AppColors.primaryDark : Colors.transparent,
                    borderRadius: BorderRadius.circular(26),
                    border: isActive
                        ? null
                        : Border.all(color: Colors.white.withOpacity(0.4)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        tab.icon,
                        size: 22,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        tab.label,
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                          fontSize: 16,
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