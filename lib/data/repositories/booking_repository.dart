import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/utils/result.dart';
import '../../core/utils/error_translator.dart';
import '../models/booking_model.dart';

/// يتعامل مباشرة مع جدول bookings بـ Supabase
class BookingRepository {
  final SupabaseClient _client = Supabase.instance.client;

  Future<Result<BookingModel>> createBooking({
    required String hotelId,
    required String roomId,
    required DateTime checkIn,
    required DateTime checkOut,
    required int guests,
    required double totalPrice,
  }) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) {
        return const Failure('يجب تسجيل الدخول أولاً لإتمام الحجز');
      }

      final response = await _client
          .from('bookings')
          .insert({
        'user_id': userId,
        'hotel_id': hotelId,
        'room_id': roomId,
        'check_in': checkIn.toIso8601String(),
        'check_out': checkOut.toIso8601String(),
        'guests': guests,
        'total_price': totalPrice,
        'status': 'pending',
      })
          .select()
          .single();

      return Success(BookingModel.fromJson(response));
    } catch (e) {
      return Failure(ErrorTranslator.translate(e));
    }
  }

  /// يجيب حجوزات المستخدم مع بيانات الفندق المرتبط (اسم، مدينة، صور)
  /// عبر join تلقائي بصيغة Supabase: 'hotels(name, city, images)'
  Future<Result<List<BookingModel>>> getMyBookings() async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) {
        return const Failure('يجب تسجيل الدخول أولاً');
      }

      final response = await _client
          .from('bookings')
          .select('*, hotels(name, city, images)')
          .eq('user_id', userId)
          .order('check_in', ascending: false);

      final bookings = (response as List)
          .map((row) => BookingModel.fromJson(row))
          .toList();

      return Success(bookings);
    } catch (e) {
      return Failure(ErrorTranslator.translate(e));
    }
  }

  Future<Result<void>> cancelBooking(String bookingId) async {
    try {
      await _client
          .from('bookings')
          .update({'status': 'cancelled'}).eq('id', bookingId);
      return const Success(null);
    } catch (e) {
      return Failure(ErrorTranslator.translate(e));
    }
  }
}