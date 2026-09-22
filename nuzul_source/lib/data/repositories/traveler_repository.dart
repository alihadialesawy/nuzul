import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/utils/result.dart';
import '../../core/utils/error_translator.dart';
import '../models/traveler_model.dart';

/// يتعامل مع جدول travelers -- المسافرون المحفوظون في ملف المستخدم،
/// كل مستخدم يشوف ويعدّل بس المسافرين اللي هو ضافهم (RLS).
class TravelerRepository {
  final SupabaseClient _client = Supabase.instance.client;

  Future<Result<List<TravelerModel>>> fetchMyTravelers() async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return const Failure('يجب تسجيل الدخول أولاً');

      final response = await _client
          .from('travelers')
          .select()
          .eq('user_id', userId)
          .order('created_at');

      final travelers = (response as List)
          .map((row) => TravelerModel.fromJson(row as Map<String, dynamic>))
          .toList();

      return Success(travelers);
    } catch (e) {
      return Failure(ErrorTranslator.translate(e));
    }
  }

  Future<Result<void>> addTraveler(TravelerModel traveler) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return const Failure('يجب تسجيل الدخول أولاً');

      await _client.from('travelers').insert(traveler.toInsertJson(userId));
      return const Success(null);
    } catch (e) {
      return Failure(ErrorTranslator.translate(e));
    }
  }

  Future<Result<void>> deleteTraveler(String id) async {
    try {
      await _client.from('travelers').delete().eq('id', id);
      return const Success(null);
    } catch (e) {
      return Failure(ErrorTranslator.translate(e));
    }
  }
}