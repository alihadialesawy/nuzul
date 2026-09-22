import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/repositories/duffel_repository.dart';

/// حالة فلاتر نتائج بحث الطيران: شركات الطيران المختارة (فاضية =
/// كل الشركات)، خيار "بدون توقف فقط"، نطاق وقت المغادرة والوصول
/// (بالدقايق من منتصف الليل، 0-1439)، وأقصى مدة رحلة مقبولة (null =
/// بدون حد أقصى).
class FlightFilterState {
  final Set<String> selectedAirlines;
  final bool nonstopOnly;
  final RangeValues departureTimeRange;
  final RangeValues arrivalTimeRange;
  final double? maxDurationMinutes;
  final int? maxStops;
  final Set<String> selectedAirports;
  final Set<String> selectedAircraft;

  const FlightFilterState({
    this.selectedAirlines = const {},
    this.nonstopOnly = false,
    this.departureTimeRange = const RangeValues(0, 1439),
    this.arrivalTimeRange = const RangeValues(0, 1439),
    this.maxDurationMinutes,
    this.maxStops,
    this.selectedAirports = const {},
    this.selectedAircraft = const {},
  });

  FlightFilterState copyWith({
    Set<String>? selectedAirlines,
    bool? nonstopOnly,
    RangeValues? departureTimeRange,
    RangeValues? arrivalTimeRange,
    double? maxDurationMinutes,
    bool clearMaxDuration = false,
    int? maxStops,
    bool clearMaxStops = false,
    Set<String>? selectedAirports,
    Set<String>? selectedAircraft,
  }) {
    return FlightFilterState(
      selectedAirlines: selectedAirlines ?? this.selectedAirlines,
      nonstopOnly: nonstopOnly ?? this.nonstopOnly,
      departureTimeRange: departureTimeRange ?? this.departureTimeRange,
      arrivalTimeRange: arrivalTimeRange ?? this.arrivalTimeRange,
      maxDurationMinutes:
      clearMaxDuration ? null : (maxDurationMinutes ?? this.maxDurationMinutes),
      maxStops: clearMaxStops ? null : (maxStops ?? this.maxStops),
      selectedAirports: selectedAirports ?? this.selectedAirports,
      selectedAircraft: selectedAircraft ?? this.selectedAircraft,
    );
  }
}

class FlightFiltersNotifier extends StateNotifier<FlightFilterState> {
  FlightFiltersNotifier() : super(const FlightFilterState());

  void toggleAirline(String airline) {
    final updated = Set<String>.from(state.selectedAirlines);
    if (updated.contains(airline)) {
      updated.remove(airline);
    } else {
      updated.add(airline);
    }
    state = state.copyWith(selectedAirlines: updated);
  }

  void setNonstopOnly(bool value) {
    state = state.copyWith(nonstopOnly: value);
  }

  void setDepartureTimeRange(RangeValues range) {
    state = state.copyWith(departureTimeRange: range);
  }

  void setArrivalTimeRange(RangeValues range) {
    state = state.copyWith(arrivalTimeRange: range);
  }

  void setMaxDuration(double? minutes) {
    if (minutes == null) {
      state = state.copyWith(clearMaxDuration: true);
    } else {
      state = state.copyWith(maxDurationMinutes: minutes);
    }
  }

  /// null = أي عدد توقفات، 0 = بدون توقف فقط، 1 = توقف واحد أو أقل.
  void setMaxStops(int? stops) {
    if (stops == null) {
      state = state.copyWith(clearMaxStops: true);
    } else {
      state = state.copyWith(maxStops: stops);
    }
  }

  void toggleAirport(String airportCode) {
    final updated = Set<String>.from(state.selectedAirports);
    if (updated.contains(airportCode)) {
      updated.remove(airportCode);
    } else {
      updated.add(airportCode);
    }
    state = state.copyWith(selectedAirports: updated);
  }

  void toggleAircraft(String aircraft) {
    final updated = Set<String>.from(state.selectedAircraft);
    if (updated.contains(aircraft)) {
      updated.remove(aircraft);
    } else {
      updated.add(aircraft);
    }
    state = state.copyWith(selectedAircraft: updated);
  }

  /// يرجّع كل الفلاتر لوضعها الافتراضي. بيتنادى تلقائيًا كل ما نتايج
  /// بحث جديدة توصل، عشان فلاتر بحث قديم ما تفضلش مطبّقة بالغلط على
  /// بحث تاني مختلف تمامًا.
  void reset() {
    state = const FlightFilterState();
  }
}

final flightFiltersProvider =
StateNotifierProvider<FlightFiltersNotifier, FlightFilterState>((ref) {
  return FlightFiltersNotifier();
});

/// يطبّق الفلاتر الحالية على قائمة عروض رحلات حقيقية (بعد ما توصل من
/// Duffel)، ويرجّع القائمة المفلترة بس -- الفلترة بتحصل على النتائج
/// اللي وصلت فعلاً، مش بإعادة نداء API جديد لكل تغيير فلتر.
List<DuffelFlightOffer> applyFlightFilters(
    List<DuffelFlightOffer> offers,
    FlightFilterState filters,
    ) {
  return offers.where((offer) {
    if (filters.nonstopOnly && !offer.nonstop) return false;

    if (filters.selectedAirlines.isNotEmpty &&
        !filters.selectedAirlines.contains(offer.airline)) {
      return false;
    }

    final depMinutes = offer.departureTime.hour * 60 + offer.departureTime.minute;
    if (depMinutes < filters.departureTimeRange.start ||
        depMinutes > filters.departureTimeRange.end) {
      return false;
    }

    final arrMinutes = offer.arrivalTime.hour * 60 + offer.arrivalTime.minute;
    if (arrMinutes < filters.arrivalTimeRange.start ||
        arrMinutes > filters.arrivalTimeRange.end) {
      return false;
    }

    if (filters.maxDurationMinutes != null) {
      final durationMinutes =
          offer.arrivalTime.difference(offer.departureTime).inMinutes;
      if (durationMinutes > filters.maxDurationMinutes!) return false;
    }

    if (filters.maxStops != null && offer.stops > filters.maxStops!) {
      return false;
    }

    // فلتر المطارات: بيتحقق من مطاري المغادرة/الوصول ومطارات التوقف
    // مع بعض -- لو المستخدم اختار مطار معين، أي عرض يمر منه (سواء
    // كمطار انطلاق، وصول، أو توقف) يفضل ظاهر.
    if (filters.selectedAirports.isNotEmpty) {
      final offerAirports = {
        offer.originAirportCode,
        offer.destinationAirportCode,
        ...offer.stopoverAirports,
      };
      final matches = offerAirports.any(filters.selectedAirports.contains);
      if (!matches) return false;
    }

    if (filters.selectedAircraft.isNotEmpty) {
      if (offer.aircraft == null ||
          !filters.selectedAircraft.contains(offer.aircraft)) {
        return false;
      }
    }

    return true;
  }).toList();
}