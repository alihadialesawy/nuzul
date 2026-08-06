import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/hotel_model.dart';
import '../../../data/repositories/hotel_repository.dart';

final adminHotelRepositoryProvider = Provider<HotelRepository>((ref) {
  return HotelRepository();
});

/// قائمة كل الفنادق (بدون فلترة) لعرضها بلوحة إدارة الفنادق.
/// استخدم `ref.invalidate(adminHotelsListProvider)` بعد أي إضافة/تعديل/حذف
/// عشان يعيد الجلب من جديد.
final adminHotelsListProvider =
FutureProvider.autoDispose<List<HotelModel>>((ref) async {
  final repo = ref.watch(adminHotelRepositoryProvider);
  final result = await repo.getAllHotelsForAdmin();
  return result.when(
    success: (hotels) => hotels,
    failure: (message) => throw Exception(message),
  );
});