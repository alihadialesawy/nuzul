import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/utils/result.dart';
import '../../core/utils/error_translator.dart';
import '../models/hotel_model.dart';

/// يتعامل مباشرة مع جدول hotels بـ Supabase
class HotelRepository {
  final SupabaseClient _client = Supabase.instance.client;

  /// بحث عن فنادق حسب المدينة وتوفر التواريخ
  /// ملاحظة: التحقق من التوفر الفعلي (عدم تعارض الحجوزات) يفضل يكون
  /// عبر Postgres function أو Edge Function بدل استعلام بسيط، لتفادي
  /// حجز نفس الغرفة مرتين بنفس الوقت (race condition).
  Future<Result<List<HotelModel>>> searchHotels({
    required String city,
    required DateTime checkIn,
    required DateTime checkOut,
    required int guests,
  }) async {
    try {
      final response = await _client
          .from('hotels')
          .select()
          .ilike('city', '%$city%')
          .gte('max_guests', guests);

      final hotels =
      (response as List).map((row) => HotelModel.fromJson(row)).toList();

      return Success(hotels);
    } catch (e) {
      return Failure(ErrorTranslator.translate(e));
    }
  }

  Future<Result<HotelModel>> getHotelDetails(String hotelId) async {
    try {
      final response =
      await _client.from('hotels').select().eq('id', hotelId).single();

      return Success(HotelModel.fromJson(response));
    } catch (e) {
      return Failure(ErrorTranslator.translate(e));
    }
  }

  /// إضافة/إزالة فندق من المفضلة (جدول وسيط favorites)
  Future<Result<void>> toggleFavorite(String hotelId, bool isFavorite) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) {
        return const Failure('يجب تسجيل الدخول أولاً');
      }

      if (isFavorite) {
        await _client.from('favorites').insert({
          'user_id': userId,
          'hotel_id': hotelId,
        });
      } else {
        await _client
            .from('favorites')
            .delete()
            .eq('user_id', userId)
            .eq('hotel_id', hotelId);
      }
      return const Success(null);
    } catch (e) {
      return Failure(ErrorTranslator.translate(e));
    }
  }
}