import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/traveler_model.dart';
import '../../../data/repositories/traveler_repository.dart';

final travelerRepositoryProvider = Provider<TravelerRepository>((ref) {
  return TravelerRepository();
});

/// قائمة المسافرين المحفوظين للمستخدم الحالي، بترجع فاضية لو مسجّلش
/// دخول أو لسه معندوش أي مسافر محفوظ.
final myTravelersProvider = FutureProvider<List<TravelerModel>>((ref) async {
  final repo = ref.watch(travelerRepositoryProvider);
  final result = await repo.fetchMyTravelers();
  return result.when(
    success: (list) => list,
    failure: (_) => <TravelerModel>[],
  );
});