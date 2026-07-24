import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/hotel_model.dart';
import '../../../data/repositories/hotel_repository.dart';

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