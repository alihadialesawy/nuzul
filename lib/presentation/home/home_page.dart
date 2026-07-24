import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../core/providers/locale_provider.dart';
import '../../core/widgets/error_view.dart';
import '../../core/widgets/loading_view.dart';
import '../../core/widgets/empty_view.dart';
import '../../data/models/hotel_model.dart';
import '../../localization/app_localizations.dart';
import '../auth/controllers/auth_controller.dart';
import '../search/controllers/search_controller.dart';

/// شاشة رئيسية: بحث حر عن الفنادق بدون تسجيل دخول (guest mode)
class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  final _cityController = TextEditingController();
  DateTime _checkIn = DateTime.now().add(const Duration(days: 1));
  DateTime _checkOut = DateTime.now().add(const Duration(days: 3));
  int _guests = 2;

  Map<String, dynamic>? _searchParams;

  @override
  void dispose() {
    _cityController.dispose();
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

  Future<void> _pickDateRange() async {
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDateRange: DateTimeRange(start: _checkIn, end: _checkOut),
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
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.appName),
        actions: [
          // زر تبديل اللغة
          IconButton(
            icon: const Icon(Icons.language),
            tooltip: 'AR / EN',
            onPressed: () => ref.read(localeProvider.notifier).toggle(),
          ),
          IconButton(
            icon: const Icon(Icons.receipt_long_outlined),
            tooltip: l10n.myBookings,
            onPressed: () async {
              final user = ref.read(currentUserProvider);
              if (user == null) {
                await context.push(AppRoutes.login);
                if (context.mounted) context.push(AppRoutes.myBookings);
              } else {
                context.push(AppRoutes.myBookings);
              }
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSizes.md),
              child: Column(
                children: [
                  TextField(
                    controller: _cityController,
                    decoration: InputDecoration(
                      labelText: l10n.whereTo,
                      prefixIcon: const Icon(Icons.location_on_outlined),
                    ),
                    onSubmitted: (_) => _runSearch(),
                  ),
                  const SizedBox(height: AppSizes.sm),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _pickDateRange,
                          icon: const Icon(Icons.calendar_today_outlined),
                          label: Text(
                            '${_checkIn.day}/${_checkIn.month} - ${_checkOut.day}/${_checkOut.month}',
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSizes.sm),
                      Expanded(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            IconButton(
                              onPressed: _guests > 1
                                  ? () => setState(() => _guests--)
                                  : null,
                              icon: const Icon(Icons.remove_circle_outline),
                            ),
                            Text('$_guests ${l10n.guests}'),
                            IconButton(
                              onPressed: () => setState(() => _guests++),
                              icon: const Icon(Icons.add_circle_outline),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSizes.sm),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _runSearch,
                      icon: const Icon(Icons.search),
                      label: Text(l10n.search),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: _searchParams == null
                  ? EmptyView(
                message: l10n.searchPrompt,
                icon: Icons.hotel_outlined,
              )
                  : _SearchResults(params: _searchParams!),
            ),
          ],
        ),
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
    final resultsAsync = ref.watch(searchResultsProvider(params));

    return resultsAsync.when(
      loading: () => LoadingView(message: l10n.searching),
      error: (error, _) => ErrorView(
        message: l10n.errorLoadResults,
        onRetry: () => ref.invalidate(searchResultsProvider(params)),
      ),
      data: (hotels) {
        if (hotels.isEmpty) {
          return EmptyView(
            message: l10n.noResults,
            icon: Icons.hotel_outlined,
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(AppSizes.md),
          itemCount: hotels.length,
          itemBuilder: (context, index) =>
              _HotelCard(hotel: hotels[index], searchParams: params),
        );
      },
    );
  }
}

class _HotelCard extends ConsumerWidget {
  final HotelModel hotel;
  final Map<String, dynamic> searchParams;
  const _HotelCard({required this.hotel, required this.searchParams});

  Future<void> _handleBookNow(
      BuildContext context,
      WidgetRef ref,
      Map<String, dynamic> searchParams,
      ) async {
    final user = ref.read(currentUserProvider);

    if (user == null) {
      await context.push(AppRoutes.login);
      return;
    }

    if (context.mounted) {
      context.push(
        AppRoutes.booking,
        extra: {
          'hotel': hotel,
          'checkIn': searchParams['checkIn'],
          'checkOut': searchParams['checkOut'],
          'guests': searchParams['guests'],
        },
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;

    return Card(
      margin: const EdgeInsets.only(bottom: AppSizes.md),
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppColors.divider,
                    borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                    image: hotel.images.isNotEmpty
                        ? DecorationImage(
                      image: NetworkImage(hotel.images.first),
                      fit: BoxFit.cover,
                      onError: (_, __) {},
                    )
                        : null,
                  ),
                  child: hotel.images.isEmpty
                      ? const Icon(Icons.hotel, color: AppColors.textHint)
                      : null,
                ),
                const SizedBox(width: AppSizes.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        hotel.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.star, size: 16, color: AppColors.secondary),
                          const SizedBox(width: 4),
                          Text('${hotel.rating}'),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${hotel.pricePerNight.toStringAsFixed(0)} ${l10n.perNight}',
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSizes.sm),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => _handleBookNow(context, ref, searchParams),
                child: Text(l10n.bookNow),
              ),
            ),
          ],
        ),
      ),
    );
  }
}