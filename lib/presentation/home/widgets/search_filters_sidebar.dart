import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../controllers/hotel_filters_controller.dart';

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
            _buildBudgetSection(filters, notifier),
            const Divider(height: 24),
            _buildCheckboxSection(
              title: 'Popular filters',
              group: HotelFilterGroup.popular,
              counts: _popularFilterCounts,
              filters: filters,
              notifier: notifier,
            ),
            const Divider(height: 24),
            _buildCheckboxSection(
              title: 'Property Type',
              group: HotelFilterGroup.propertyType,
              counts: _propertyTypeCounts,
              filters: filters,
              notifier: notifier,
            ),
            const Divider(height: 24),
            _buildCheckboxSection(
              title: 'Meals',
              group: HotelFilterGroup.meals,
              counts: _mealsCounts,
              filters: filters,
              notifier: notifier,
            ),
            const SizedBox(height: 16),
            _buildCheckboxSection(
              title: 'Amenities',
              group: HotelFilterGroup.amenities,
              counts: _amenitiesCounts,
              filters: filters,
              notifier: notifier,
            ),
            const SizedBox(height: 16),
            _buildCheckboxSection(
              title: 'Room amenities',
              group: HotelFilterGroup.roomAmenities,
              counts: _roomAmenitiesCounts,
              filters: filters,
              notifier: notifier,
            ),
            const Divider(height: 24),
            _buildCheckboxSection(
              title: 'Neighborhood',
              group: HotelFilterGroup.neighborhood,
              counts: _neighborhoodCounts,
              filters: filters,
              notifier: notifier,
            ),
            const Divider(height: 24),
            _buildCheckboxSection(
              title: 'Property rating',
              subtitle: 'Find high-quality hotels and vacation rentals',
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

  Widget _buildBudgetSection(HotelFilterState filters, HotelFiltersNotifier notifier) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Your budget (per night)',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
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
                    child: Text(label, style: const TextStyle(fontSize: 14)),
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