import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/utils/result.dart';
import '../../core/utils/error_translator.dart';

/// يتعامل مع جدول flight_bookings بـ Supabase — تسجيل حجز رحلة طيران
/// بعد إتمام الدفع (أو بحالة "قيد الانتظار" على المنصات اللي Stripe
/// مش مدعوم عليها بعد، زي سطح المكتب).
class FlightBookingRepository {
  final SupabaseClient _client = Supabase.instance.client;

  Future<Result<void>> createFlightBooking({
    required String flightNumber,
    required String airline,
    required String originCity,
    required String destinationCity,
    required DateTime departureTime,
    required DateTime arrivalTime,
    required String cabinClass,
    required int travelers,
    required double totalPrice,
    String status = 'pending',
  }) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) {
        return const Failure('يجب تسجيل الدخول أولاً لإتمام الحجز');
      }

      await _client.from('flight_bookings').insert({
        'user_id': userId,
        'flight_number': flightNumber,
        'airline': airline,
        'origin_city': originCity,
        'destination_city': destinationCity,
        'departure_time': departureTime.toIso8601String(),
        'arrival_time': arrivalTime.toIso8601String(),
        'cabin_class': cabinClass,
        'travelers': travelers,
        'total_price': totalPrice,
        'status': status,
      });

      return const Success(null);
    } catch (e) {
      return Failure(ErrorTranslator.translate(e));
    }
  }
}