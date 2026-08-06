import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/booking_model.dart';
import '../../../data/repositories/booking_repository.dart';

final adminBookingRepositoryProvider = Provider<BookingRepository>((ref) {
  return BookingRepository();
});

/// كل حجوزات الفنادق لكل الزبائن، لعرضها بلوحة إدارة الحجوزات.
/// استخدم `ref.invalidate(adminBookingsListProvider)` بعد أي تحديث حالة.
final adminBookingsListProvider =
FutureProvider.autoDispose<List<BookingModel>>((ref) async {
  final repo = ref.watch(adminBookingRepositoryProvider);
  final result = await repo.getAllBookingsForAdmin();
  return result.when(
    success: (bookings) => bookings,
    failure: (message) => throw Exception(message),
  );
});