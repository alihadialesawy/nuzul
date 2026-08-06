import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/utils/result.dart';
import '../../core/utils/error_translator.dart';

/// يتعامل مع جدول duffel_bookings بـ Supabase — تسجيل حجز رحلة Duffel
/// حقيقية بعد ما Duffel يأكد الـ Order فعليًا.
class DuffelBookingRepository {
  final SupabaseClient _client = Supabase.instance.client;

  Future<Result<void>> saveBooking({
    required String duffelOrderId,
    String? bookingReference,
    required String offerId,
    required String airline,
    required String flightNumber,
    required String originCity,
    required String destinationCity,
    required DateTime departureTime,
    required DateTime arrivalTime,
    required String cabinClass,
    required double totalAmount,
    required String totalCurrency,
  }) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) {
        return const Failure('يجب تسجيل الدخول أولاً لإتمام الحجز');
      }

      await _client.from('duffel_bookings').insert({
        'user_id': userId,
        'duffel_order_id': duffelOrderId,
        'booking_reference': bookingReference,
        'offer_id': offerId,
        'airline': airline,
        'flight_number': flightNumber,
        'origin_city': originCity,
        'destination_city': destinationCity,
        'departure_time': departureTime.toIso8601String(),
        'arrival_time': arrivalTime.toIso8601String(),
        'cabin_class': cabinClass,
        'total_amount': totalAmount,
        'total_currency': totalCurrency,
        'status': 'confirmed',
      });

      return const Success(null);
    } catch (e) {
      return Failure(ErrorTranslator.translate(e));
    }
  }
}