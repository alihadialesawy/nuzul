import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/repositories/duffel_repository.dart';

final duffelRepositoryProvider = Provider((ref) => DuffelRepository());

/// يبحث عن رحلات طيران حقيقية عبر Duffel. بياخد نفس شكل الـ params
/// اللي بيستخدمها بحث الطيران الحالي (origin/destination كاسم حر،
/// departureDate، travelers، nonstopOnly)، ويحوّل origin وdestination
/// لأكواد IATA تلقائيًا عبر Duffel Places قبل ما يبحث.
final duffelFlightSearchResultsProvider =
FutureProvider.family<List<DuffelFlightOffer>, Map<String, dynamic>>(
      (ref, params) async {
    final repo = ref.watch(duffelRepositoryProvider);

    final originQuery = params['origin'] as String;
    final destinationQuery = params['destination'] as String;
    final departureDate = params['departureDate'] as DateTime;
    final travelers = params['travelers'] as int? ?? 1;
    final nonstopOnly = params['nonstopOnly'] as bool? ?? false;

    // 1. حوّل اسم المدينة الحر لكود IATA لكل من نقطة الانطلاق والوجهة
    final originResult = await repo.searchPlaces(originQuery);
    final destinationResult = await repo.searchPlaces(destinationQuery);

    final originCode = originResult.when(
      success: (places) => places.isNotEmpty ? places.first.iataCode : null,
      failure: (_) => null,
    );
    final destinationCode = destinationResult.when(
      success: (places) => places.isNotEmpty ? places.first.iataCode : null,
      failure: (_) => null,
    );

    if (originCode == null) {
      throw Exception('تعذر التعرف على مدينة الانطلاق "$originQuery"');
    }
    if (destinationCode == null) {
      throw Exception('تعذر التعرف على الوجهة "$destinationQuery"');
    }

    // 2. ابحث عن الرحلات فعليًا بالأكواد اللي اتحلّت
    final searchResult = await repo.searchFlights(
      origin: originCode,
      destination: destinationCode,
      departureDate: departureDate,
      adults: travelers,
    );

    final offers = searchResult.when(
      success: (offers) => offers,
      failure: (message) => throw Exception(message),
    );

    if (!nonstopOnly) return offers;
    return offers.where((o) => o.nonstop).toList();
  },
);