import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/hotel_model.dart';
import '../../../data/repositories/hotel_repository.dart';
import '../../../data/models/flight_model.dart';
import '../../../data/repositories/flight_repository.dart';
import '../../../data/models/car_model.dart';
import '../../../data/repositories/car_repository.dart';
import '../../../data/repositories/price_watch_repository.dart';

final hotelRepositoryProvider = Provider((ref) => HotelRepository());

/// يبحث عن الفنادق ويرجع القائمة، أو يرمي استثناء برسالة عربية واضحة
/// (AsyncValue.error بيلتقطه تلقائيًا ويعرضه عبر ErrorView بالشاشة)
final searchResultsProvider =
FutureProvider.family<List<HotelModel>, Map<String, dynamic>>((ref, params) async {
  final repo = ref.watch(hotelRepositoryProvider);

  final result = await repo.searchHotels(
    city: params['city'],
    checkIn: params['checkIn'],
    checkOut: params['checkOut'],
    guests: params['guests'],
  );

  return result.when(
    success: (hotels) => hotels,
    failure: (message) => throw Exception(message),
  );
});

final flightRepositoryProvider = Provider((ref) => FlightRepository());

/// يبحث عن رحلات الطيران ويرجع القائمة، أو يرمي استثناء برسالة واضحة
/// (نفس نمط searchResultsProvider بتاع الفنادق بالظبط)
final flightSearchResultsProvider =
FutureProvider.family<List<FlightModel>, Map<String, dynamic>>((ref, params) async {
  final repo = ref.watch(flightRepositoryProvider);

  final result = await repo.searchFlights(
    origin: params['origin'],
    destination: params['destination'],
    departureDate: params['departureDate'],
    travelers: params['travelers'],
    cabinClass: params['cabinClass'],
    nonstopOnly: params['nonstopOnly'] ?? false,
  );

  return result.when(
    success: (flights) => flights,
    failure: (message) => throw Exception(message),
  );
});

final carRepositoryProvider = Provider((ref) => CarRepository());

/// يبحث عن سيارات التأجير المتاحة حسب مدينة الاستلام
final carSearchResultsProvider =
FutureProvider.family<List<CarModel>, Map<String, dynamic>>((ref, params) async {
  final repo = ref.watch(carRepositoryProvider);

  final result = await repo.searchCars(
    pickupCity: params['pickupCity'],
  );

  return result.when(
    success: (cars) => cars,
    failure: (message) => throw Exception(message),
  );
});

final priceWatchRepositoryProvider = Provider((ref) => PriceWatchRepository());