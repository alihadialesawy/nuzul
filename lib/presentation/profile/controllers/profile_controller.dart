import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/profile_model.dart';
import '../../../data/repositories/profile_repository.dart';
import '../../auth/controllers/auth_controller.dart';

final profileRepositoryProvider = Provider((ref) => ProfileRepository());

/// يجيب بيانات حساب المستخدم الحالي، ويتجدد تلقائيًا لو تغيّرت حالة
/// تسجيل الدخول (currentUserProvider)
final myProfileProvider = FutureProvider<ProfileModel?>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return null;

  final repo = ref.watch(profileRepositoryProvider);
  final result = await repo.getMyProfile();

  return result.when(
    success: (profile) => profile,
    failure: (message) => throw Exception(message),
  );
});