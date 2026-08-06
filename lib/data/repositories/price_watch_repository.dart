import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/utils/result.dart';
import '../../core/utils/error_translator.dart';

/// يتعامل مع جدول price_watches بـ Supabase — إضافة طلبات تتبّع أسعار
/// رحلات الطيران فقط (write-only من ناحية التطبيق؛ الفحص اليومي
/// والإشعار بيتم من خلال Edge Function منفصلة في الخلفية).
class PriceWatchRepository {
  final SupabaseClient _client = Supabase.instance.client;

  Future<Result<void>> submitPriceWatch({
    required String email,
    String? phone,
    required String originCity,
    required String destinationCity,
    required DateTime travelDate,
    required double targetPrice,
    bool nonstopOnly = false,
  }) async {
    try {
      await _client.from('price_watches').insert({
        'email': email.trim(),
        'phone': (phone == null || phone.trim().isEmpty) ? null : phone.trim(),
        'origin_city': originCity.trim(),
        'destination_city': destinationCity.trim(),
        'travel_date':
        '${travelDate.year.toString().padLeft(4, '0')}-${travelDate.month.toString().padLeft(2, '0')}-${travelDate.day.toString().padLeft(2, '0')}',
        'target_price': targetPrice,
        'nonstop_only': nonstopOnly,
      });
      return const Success(null);
    } catch (e) {
      return Failure(ErrorTranslator.translate(e));
    }
  }
}