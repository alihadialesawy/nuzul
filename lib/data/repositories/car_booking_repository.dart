import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/utils/result.dart';
import '../../core/utils/error_translator.dart';

/// يتعامل مع جدول car_bookings بـ Supabase — تسجيل حجز سيارة بعد إتمام
/// الدفع (أو بحالة "قيد الانتظار" على المنصات اللي Stripe مش مدعوم
/// عليها بعد، زي سطح المكتب).
class CarBookingRepository {
  final SupabaseClient _client = Supabase.instance.client;

  Future<Result<void>> createCarBooking({
    required String carName,
    required String company,
    required String category,
    required String pickupCity,
    required DateTime pickupDate,
    required DateTime dropoffDate,
    required double totalPrice,
    String status = 'pending',
  }) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) {
        return const Failure('يجب تسجيل الدخول أولاً لإتمام الحجز');
      }

      await _client.from('car_bookings').insert({
        'user_id': userId,
        'car_name': carName,
        'company': company,
        'category': category,
        'pickup_city': pickupCity,
        'pickup_date': pickupDate.toIso8601String(),
        'dropoff_date': dropoffDate.toIso8601String(),
        'total_price': totalPrice,
        'status': status,
      });

      return const Success(null);
    } catch (e) {
      return Failure(ErrorTranslator.translate(e));
    }
  }
}