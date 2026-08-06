import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/utils/result.dart';
import '../../core/utils/error_translator.dart';
import '../models/flight_model.dart';

/// يتعامل مباشرة مع جدول flights بـ Supabase
class FlightRepository {
  final SupabaseClient _client = Supabase.instance.client;

  /// بحث عن رحلات حسب مدينة المغادرة والوجهة وتاريخ الذهاب (+ تاريخ العودة
  /// اختياريًا لو الرحلة "ذهاب وعودة" — البحث الحالي بيرجّع رحلات الذهاب فقط،
  /// وبحث العودة ممكن يتنفذ بنفس الدالة بعكس origin/destination).
  Future<Result<List<FlightModel>>> searchFlights({
    required String origin,
    required String destination,
    required DateTime departureDate,
    required int travelers,
    String? cabinClass,
    bool nonstopOnly = false,
  }) async {
    try {
      final startOfDay = DateTime(departureDate.year, departureDate.month, departureDate.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      var query = _client
          .from('flights')
          .select()
          .ilike('origin_city', '%$origin%')
          .ilike('destination_city', '%$destination%')
          .gte('departure_time', startOfDay.toIso8601String())
          .lt('departure_time', endOfDay.toIso8601String())
          .gte('seats_available', travelers);

      if (cabinClass != null && cabinClass.isNotEmpty) {
        query = query.eq('cabin_class', cabinClass);
      }
      if (nonstopOnly) {
        query = query.eq('nonstop', true);
      }

      final response = await query.order('departure_time', ascending: true);

      final flights =
      (response as List).map((row) => FlightModel.fromJson(row)).toList();

      return Success(flights);
    } catch (e) {
      return Failure(ErrorTranslator.translate(e));
    }
  }

  Future<Result<FlightModel>> getFlightDetails(String flightId) async {
    try {
      final response =
      await _client.from('flights').select().eq('id', flightId).single();

      return Success(FlightModel.fromJson(response));
    } catch (e) {
      return Failure(ErrorTranslator.translate(e));
    }
  }
}