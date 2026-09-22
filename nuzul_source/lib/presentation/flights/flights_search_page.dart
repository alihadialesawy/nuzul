import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../core/widgets/app_banner.dart';
import '../../core/widgets/app_footer.dart';
import '../../core/widgets/loading_view.dart';
import '../../core/widgets/error_view.dart';
import '../../core/widgets/empty_view.dart';
import '../../data/repositories/duffel_repository.dart';
import '../home/controllers/duffel_flight_search_controller.dart';

/// شاشة بحث رحلات الطيران المستقلة (مسار /flights، مربوطة من رابط
/// "بحث الرحلات" بالـ Footer). النسخة السابقة كانت شاشة تشخيصية
/// ("Flight search is coming soon") تستخدم نظام محلي منفصل. هذي
/// النسخة توحّد النظام: تستخدم بالضبط نفس duffelFlightSearchResultsProvider
/// و DuffelRepository المستخدمين فعليًا بتبويب الرحلات بالصفحة
/// الرئيسية — بدون أي منطق بحث جديد أو مكرر — وتوجّه النتيجة لنفس
/// شاشة الحجز الحقيقية (/duffel-flight-booking).
class FlightsSearchPage extends ConsumerStatefulWidget {
  const FlightsSearchPage({super.key});

  @override
  ConsumerState<FlightsSearchPage> createState() => _FlightsSearchPageState();
}

class _FlightsSearchPageState extends ConsumerState<FlightsSearchPage> {
  final _fromController = TextEditingController();
  final _toController = TextEditingController();
  DateTimeRange? _dateRange;
  int _travelers = 1;
  bool _nonstopOnly = false;

  Map<String, dynamic>? _searchParams;

  @override
  void dispose() {
    _fromController.dispose();
    _toController.dispose();
    super.dispose();
  }

  void _swapLocations() {
    setState(() {
      final temp = _fromController.text;
      _fromController.text = _toController.text;
      _toController.text = temp;
    });
  }

  Future<void> _pickDateRange() async {
    final now = DateTime.now();
    final range = await showDateRangePicker(
      context: context,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
      initialDateRange: _dateRange ??
          DateTimeRange(
            start: now.add(const Duration(days: 14)),
            end: now.add(const Duration(days: 21)),
          ),
    );
    if (range != null) setState(() => _dateRange = range);
  }

  String _dateRangeLabel(bool isArabic) {
    if (_dateRange == null) {
      return isArabic ? 'التواريخ' : 'Dates';
    }
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    final s = _dateRange!.start;
    final e = _dateRange!.end;
    return '${months[s.month - 1]} ${s.day} - ${months[e.month - 1]} ${e.day}';
  }

  void _runSearch() {
    final origin = _fromController.text.trim();
    final destination = _toController.text.trim();
    if (origin.isEmpty || destination.isEmpty) return;

    setState(() {
      _searchParams = {
        'origin': origin,
        'destination': destination,
        'departureDate': _dateRange?.start ?? DateTime.now().add(const Duration(days: 1)),
        'travelers': _travelers,
        'nonstopOnly': _nonstopOnly,
      };
    });
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    return Scaffold(
      appBar: const AppBanner(activeTab: 'flights', assetVariant: 'flights'),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSizes.md),
              child: Container(
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
                            controller: _fromController,
                            style: const TextStyle(color: Colors.black87),
                            decoration: InputDecoration(
                              hintText: isArabic ? 'المغادرة من' : 'Leaving from',
                              hintStyle: const TextStyle(color: Colors.black45),
                              border: InputBorder.none,
                              isDense: true,
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: _swapLocations,
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
                            controller: _toController,
                            style: const TextStyle(color: Colors.black87),
                            decoration: InputDecoration(
                              hintText: isArabic ? 'الوجهة' : 'Going to',
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
                          onTap: _pickDateRange,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.calendar_today_outlined, size: 16, color: Colors.white70),
                              const SizedBox(width: 6),
                              Text(
                                _dateRangeLabel(isArabic),
                                style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.white),
                              ),
                            ],
                          ),
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.person_outline, size: 16, color: Colors.white70),
                            IconButton(
                              onPressed: _travelers > 1 ? () => setState(() => _travelers--) : null,
                              icon: const Icon(Icons.remove_circle_outline, color: Colors.white70, size: 18),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                            Text('$_travelers', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                            IconButton(
                              onPressed: () => setState(() => _travelers++),
                              icon: const Icon(Icons.add_circle_outline, color: Colors.white70, size: 18),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                          ],
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Checkbox(
                              value: _nonstopOnly,
                              onChanged: (v) => setState(() => _nonstopOnly = v ?? false),
                              side: const BorderSide(color: Colors.white70),
                            ),
                            Text(
                              isArabic ? 'بدون توقف' : 'Nonstop',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                        ElevatedButton.icon(
                          onPressed: _runSearch,
                          style: ElevatedButton.styleFrom(
                            shape: const StadiumBorder(),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          ),
                          icon: const Icon(Icons.search, size: 18),
                          label: Text(isArabic ? 'بحث' : 'Search'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: _searchParams == null
                  ? ListView(
                padding: const EdgeInsets.all(AppSizes.md),
                children: const [AppFooter()],
              )
                  : _FlightsSearchResultsList(params: _searchParams!),
            ),
          ],
        ),
      ),
    );
  }
}

/// نفس نمط عرض النتائج المستخدم بتبويب الرحلات بالصفحة الرئيسية —
/// يستدعي نفس duffelFlightSearchResultsProvider الحقيقي.
class _FlightsSearchResultsList extends ConsumerWidget {
  final Map<String, dynamic> params;
  const _FlightsSearchResultsList({required this.params});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final resultsAsync = ref.watch(duffelFlightSearchResultsProvider(params));

    return resultsAsync.when(
      loading: () => LoadingView(
        message: isArabic ? 'يبحث عن رحلات الطيران...' : 'Searching for flights...',
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
                message: isArabic
                    ? 'لا توجد رحلات متاحة لهذا المسار والتاريخ'
                    : 'No flights available for this route and date',
                icon: Icons.flight_outlined,
              ),
              const AppFooter(),
            ],
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(AppSizes.md),
          itemCount: offers.length + 1,
          itemBuilder: (context, index) {
            if (index == offers.length) return const AppFooter();
            return _FlightOfferCard(offer: offers[index]);
          },
        );
      },
    );
  }
}

class _FlightOfferCard extends StatelessWidget {
  final DuffelFlightOffer offer;
  const _FlightOfferCard({required this.offer});

  String _formatTime(DateTime t) {
    final h = t.hour.toString().padLeft(2, '0');
    final m = t.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final duration = offer.arrivalTime.difference(offer.departureTime);
    final hours = duration.inMinutes ~/ 60;
    final minutes = duration.inMinutes % 60;

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
                      isArabic ? 'بدون توقف' : 'Nonstop',
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
                    Text(_formatTime(offer.departureTime), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    Text(offer.originCity, style: const TextStyle(color: AppColors.textSecondary)),
                  ],
                ),
                Expanded(
                  child: Column(
                    children: [
                      Text('${hours}h ${minutes}m', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
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
                    Text(_formatTime(offer.arrivalTime), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    Text(offer.destinationCity, style: const TextStyle(color: AppColors.textSecondary)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: AppSizes.sm),
            Row(
              children: [
                Text(offer.cabinClass, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                const Spacer(),
                Text(
                  '${offer.totalAmount.toStringAsFixed(2)} ${offer.totalCurrency}',
                  style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 18),
                ),
                const SizedBox(width: AppSizes.sm),
                SizedBox(
                  width: 100,
                  height: 40,
                  child: ElevatedButton(
                    onPressed: () {
                      context.push(AppRoutes.duffelFlightBooking, extra: {'offer': offer});
                    },
                    child: Text(isArabic ? 'احجز' : 'Book'),
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