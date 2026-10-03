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
    String status = 'pending',
    String? hotelName,
    String? hotelCity,
    List<String>? hotelImages,
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
        'status': status,
        'hotel_name': hotelName,
        'hotel_city': hotelCity,
        'hotel_images': hotelImages,
      })
          .select()
          .single();

      return Success(BookingModel.fromJson(response));
    } catch (e) {
      return Failure(ErrorTranslator.translate(e));
    }
  }

  /// يجيب حجوزات المستخدم -- بيانات الفندق (اسم/مدينة/صور) مخزّنة
  /// مباشرة على صف الحجز نفسه وقت الإنشاء، فمفيش حاجة لأي join هش
  /// يعتمد على foreign key مع جدول hotels المحلي (اللي فنادق HotelBeds
  /// مش موجودة فيه أصلاً).
  Future<Result<List<BookingModel>>> getMyBookings() async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) {
        return const Failure('يجب تسجيل الدخول أولاً');
      }

      final response = await _client
          .from('bookings')
          .select()
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

  // ---------------------------------------------------------------------
  // دوال إدارة الحجوزات (Admin)
  // ---------------------------------------------------------------------

  /// يجيب حجوزات كل الزبائن مع بيانات الزبون (من profiles، لسه رابط
  /// صحيح وموجود). بيانات الفندق بقت مخزّنة مباشرة على صف الحجز.
  Future<Result<List<BookingModel>>> getAllBookingsForAdmin() async {
    try {
      final response = await _client
          .from('bookings')
          .select('*, profiles(display_name, full_name, phone)')
          .order('created_at', ascending: false);

      final bookings = (response as List)
          .map((row) => BookingModel.fromJson(row))
          .toList();

      return Success(bookings);
    } catch (e) {
      return Failure(ErrorTranslator.translate(e));
    }
  }

  /// يحدّث حالة حجز معيّن (pending/confirmed/cancelled) — يستخدمها الأدمن
  /// للتأكيد أو الإلغاء اليدوي من لوحة إدارة الحجوزات.
  Future<Result<void>> updateBookingStatus(String bookingId, String status) async {
    try {
      await _client.from('bookings').update({'status': status}).eq('id', bookingId);
      return const Success(null);
    } catch (e) {
      return Failure(ErrorTranslator.translate(e));
    }
  }
}