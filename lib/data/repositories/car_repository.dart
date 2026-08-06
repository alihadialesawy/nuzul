import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/utils/result.dart';
import '../../core/utils/error_translator.dart';
import '../models/car_model.dart';

/// يتعامل مباشرة مع جدول cars بـ Supabase
class CarRepository {
  final SupabaseClient _client = Supabase.instance.client;

  /// بحث عن سيارات متاحة حسب مدينة الاستلام
  /// ملاحظة: زي الفنادق، التحقق الدقيق من عدم تعارض الحجوزات بفترة
  /// التأجير المطلوبة يفضل يكون لاحقًا عبر Postgres/Edge Function.
  Future<Result<List<CarModel>>> searchCars({
    required String pickupCity,
  }) async {
    try {
      final response = await _client
          .from('cars')
          .select()
          .ilike('pickup_city', '%$pickupCity%')
          .gt('available_count', 0)
          .order('price_per_day', ascending: true);

      final cars =
      (response as List).map((row) => CarModel.fromJson(row)).toList();

      return Success(cars);
    } catch (e) {
      return Failure(ErrorTranslator.translate(e));
    }
  }

  Future<Result<CarModel>> getCarDetails(String carId) async {
    try {
      final response =
      await _client.from('cars').select().eq('id', carId).single();

      return Success(CarModel.fromJson(response));
    } catch (e) {
      return Failure(ErrorTranslator.translate(e));
    }
  }
}