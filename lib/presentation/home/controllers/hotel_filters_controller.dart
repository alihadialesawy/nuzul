import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/hotel_model.dart';

/// حالة كل فلاتر الفنادق مجتمعة، مشتركة بين الشريط الجانبي (اللي بيعدّلها)
/// وقائمة النتائج (اللي بتطبّقها فعليًا على قائمة الفنادق).
class HotelFilterState {
  final RangeValues budgetRange;
  final Set<String> popularFilters;
  final Set<String> propertyTypes;
  final Set<String> meals;
  final Set<String> amenities;
  final Set<String> roomAmenities;
  final Set<String> neighborhoods;
  final Set<String> propertyRatings;

  const HotelFilterState({
    this.budgetRange = const RangeValues(80, 800),
    this.popularFilters = const {},
    this.propertyTypes = const {},
    this.meals = const {},
    this.amenities = const {},
    this.roomAmenities = const {},
    this.neighborhoods = const {},
    this.propertyRatings = const {},
  });

  HotelFilterState copyWith({
    RangeValues? budgetRange,
    Set<String>? popularFilters,
    Set<String>? propertyTypes,
    Set<String>? meals,
    Set<String>? amenities,
    Set<String>? roomAmenities,
    Set<String>? neighborhoods,
    Set<String>? propertyRatings,
  }) {
    return HotelFilterState(
      budgetRange: budgetRange ?? this.budgetRange,
      popularFilters: popularFilters ?? this.popularFilters,
      propertyTypes: propertyTypes ?? this.propertyTypes,
      meals: meals ?? this.meals,
      amenities: amenities ?? this.amenities,
      roomAmenities: roomAmenities ?? this.roomAmenities,
      neighborhoods: neighborhoods ?? this.neighborhoods,
      propertyRatings: propertyRatings ?? this.propertyRatings,
    );
  }
}

/// أسماء مجموعات الفلاتر، تُستخدم لمعرفة أي جزء من الحالة نعدّله.
enum HotelFilterGroup {
  popular,
  propertyType,
  meals,
  amenities,
  roomAmenities,
  neighborhood,
  rating,
}

class HotelFiltersNotifier extends StateNotifier<HotelFilterState> {
  HotelFiltersNotifier() : super(const HotelFilterState());

  void setBudgetRange(RangeValues range) {
    state = state.copyWith(budgetRange: range);
  }

  /// يفتح/يقفل قيمة واحدة جوه مجموعة فلاتر معيّنة.
  void toggle(HotelFilterGroup group, String label) {
    switch (group) {
      case HotelFilterGroup.popular:
        state = state.copyWith(popularFilters: _toggled(state.popularFilters, label));
        break;
      case HotelFilterGroup.propertyType:
        state = state.copyWith(propertyTypes: _toggled(state.propertyTypes, label));
        break;
      case HotelFilterGroup.meals:
        state = state.copyWith(meals: _toggled(state.meals, label));
        break;
      case HotelFilterGroup.amenities:
        state = state.copyWith(amenities: _toggled(state.amenities, label));
        break;
      case HotelFilterGroup.roomAmenities:
        state = state.copyWith(roomAmenities: _toggled(state.roomAmenities, label));
        break;
      case HotelFilterGroup.neighborhood:
        state = state.copyWith(neighborhoods: _toggled(state.neighborhoods, label));
        break;
      case HotelFilterGroup.rating:
        state = state.copyWith(propertyRatings: _toggled(state.propertyRatings, label));
        break;
    }
  }

  bool isSelected(HotelFilterGroup group, String label) {
    switch (group) {
      case HotelFilterGroup.popular:
        return state.popularFilters.contains(label);
      case HotelFilterGroup.propertyType:
        return state.propertyTypes.contains(label);
      case HotelFilterGroup.meals:
        return state.meals.contains(label);
      case HotelFilterGroup.amenities:
        return state.amenities.contains(label);
      case HotelFilterGroup.roomAmenities:
        return state.roomAmenities.contains(label);
      case HotelFilterGroup.neighborhood:
        return state.neighborhoods.contains(label);
      case HotelFilterGroup.rating:
        return state.propertyRatings.contains(label);
    }
  }

  Set<String> _toggled(Set<String> current, String label) {
    final next = Set<String>.from(current);
    if (next.contains(label)) {
      next.remove(label);
    } else {
      next.add(label);
    }
    return next;
  }

  void reset() => state = const HotelFilterState();
}

final hotelFiltersProvider =
StateNotifierProvider<HotelFiltersNotifier, HotelFilterState>((ref) {
  return HotelFiltersNotifier();
});

/// يطبّع أي نص للمقارنة من غير حساسية لحالة الأحرف ومن غير مسافات
/// زيادة في البداية/النهاية (زي "  Parking " أو "PARKING" أو "parking"،
/// كلهم بيتطابقوا مع بعض).
String _normalize(String value) => value.trim().toLowerCase();

/// يتحقق هل قائمة amenities الفندق فيها قيمة تطابق label من غير حساسية
/// لحالة الأحرف.
bool _hasAmenity(HotelModel hotel, String label) {
  final target = _normalize(label);
  return hotel.amenities.any((a) => _normalize(a) == target);
}

/// يتحقق هل مجموعة قيم مختارة (مثلاً أنواع عقار مختارة) فيها قيمة تطابق
/// value من غير حساسية لحالة الأحرف.
bool _setContainsCaseInsensitive(Set<String> set, String? value) {
  if (value == null) return false;
  final target = _normalize(value);
  return set.any((v) => _normalize(v) == target);
}

/// يطبّق كل الفلاتر الحالية على قائمة فنادق ويرجّع بس اللي مطابقة.
/// كل المقارنات النصية هنا من غير حساسية لحالة الأحرف.
/// - نطاق السعر: لازم يقع جواه.
/// - نوع العقار / الحي / تصنيف النجوم: OR جوه المجموعة نفسها (يكفي تطابق واحد).
/// - باقي المجموعات (Popular/Meals/Amenities/Room amenities): AND (لازم كل
///   اللي متعلّم يتحقق في الفندق).
List<HotelModel> applyHotelFilters(List<HotelModel> hotels, HotelFilterState f) {
  return hotels.where((hotel) {
    if (hotel.pricePerNight < f.budgetRange.start ||
        hotel.pricePerNight > f.budgetRange.end) {
      return false;
    }

    for (final label in f.popularFilters) {
      if (!_matchesPopularFilter(hotel, label)) return false;
    }

    if (f.propertyTypes.isNotEmpty &&
        !_setContainsCaseInsensitive(f.propertyTypes, hotel.propertyType)) {
      return false;
    }

    for (final label in f.meals) {
      if (!_hasAmenity(hotel, label)) return false;
    }

    for (final label in f.amenities) {
      if (!_hasAmenity(hotel, label)) return false;
    }

    for (final label in f.roomAmenities) {
      if (!_hasAmenity(hotel, label)) return false;
    }

    if (f.neighborhoods.isNotEmpty &&
        !_setContainsCaseInsensitive(f.neighborhoods, hotel.neighborhood)) {
      return false;
    }

    if (f.propertyRatings.isNotEmpty) {
      final starsLabel = '${hotel.rating.round()} stars';
      if (!_setContainsCaseInsensitive(f.propertyRatings, starsLabel)) return false;
    }

    return true;
  }).toList();
}

bool _matchesPopularFilter(HotelModel hotel, String label) {
  final normalizedLabel = _normalize(label);
  switch (normalizedLabel) {
    case 'hotels':
      return _normalize(hotel.propertyType) == 'hotels';
    case 'apartments':
      return _normalize(hotel.propertyType) == 'apartments';
    case 'very good: 8+':
      return hotel.rating * 2 >= 8;
    case '4 stars':
      return hotel.rating.round() == 4;
    default:
      return _hasAmenity(hotel, label);
  }
}