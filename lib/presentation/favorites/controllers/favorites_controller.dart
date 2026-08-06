import 'package:flutter_riverpod/flutter_riverpod.dart';

/// يدير قائمة الفنادق المفضّلة لدى المستخدم.
///
/// حاليًا بيستخدم اسم الفندق كمعرّف مؤقت (hotelKey) لحين توفر حقل `id`
/// فعلي في HotelModel — لو اتضاف لاحقًا، استبدل الاستدعاءات دي بتمرير
/// hotel.id بدل hotel.name.
class FavoritesNotifier extends StateNotifier<Set<String>> {
  FavoritesNotifier() : super(<String>{});

  bool isFavorite(String hotelKey) => state.contains(hotelKey);

  void toggle(String hotelKey) {
    final updated = Set<String>.from(state);
    if (updated.contains(hotelKey)) {
      updated.remove(hotelKey);
    } else {
      updated.add(hotelKey);
    }
    state = updated;
  }
}

final favoritesProvider =
StateNotifierProvider<FavoritesNotifier, Set<String>>((ref) {
  return FavoritesNotifier();
});