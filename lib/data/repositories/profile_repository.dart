import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/utils/result.dart';
import '../../core/utils/error_translator.dart';
import '../models/profile_model.dart';

/// يتعامل مع جدول profiles بـ Supabase — بيانات الحساب الإضافية
/// للمستخدم الحالي (المسجّل دخول).
class ProfileRepository {
  final SupabaseClient _client = Supabase.instance.client;

  Future<Result<ProfileModel?>> getMyProfile() async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) {
        return const Failure('يجب تسجيل الدخول أولاً');
      }

      final response = await _client
          .from('profiles')
          .select()
          .eq('id', userId)
          .maybeSingle();

      if (response == null) return const Success(null);
      return Success(ProfileModel.fromJson(response));
    } catch (e) {
      return Failure(ErrorTranslator.translate(e));
    }
  }

  Future<Result<void>> upsertMyProfile(ProfileModel profile) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) {
        return const Failure('يجب تسجيل الدخول أولاً');
      }

      await _client.from('profiles').upsert({
        ...profile.toJson(),
        'id': userId,
        'updated_at': DateTime.now().toIso8601String(),
      });
      return const Success(null);
    } catch (e) {
      return Failure(ErrorTranslator.translate(e));
    }
  }
}