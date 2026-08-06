import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/profile_model.dart';
import '../../../data/repositories/profile_repository.dart';
import 'auth_controller.dart';

/// يجيب بروفايل المستخدم الحالي (بما فيه role) من جدول profiles.
/// بيرجع null لو مفيش مستخدم مسجّل دخول، أو لو البروفايل نفسه مش موجود.
final myProfileProvider = FutureProvider<ProfileModel?>((ref) async {
  // نراقب currentUserProvider عشان الـ provider يعيد الجلب تلقائيًا
  // لما المستخدم يسجّل دخول/خروج.
  final user = ref.watch(currentUserProvider);
  if (user == null) return null;

  final result = await ProfileRepository().getMyProfile();
  return result.when(
    success: (profile) => profile,
    failure: (_) => null,
  );
});

/// true لو المستخدم الحالي أدمن. false في أي حالة تانية (زائر، مستخدم
/// عادي، أو لسه بيحمّل/فشل الجلب) — الافتراضي الآمن هو "مش أدمن".
final isAdminProvider = Provider<bool>((ref) {
  final profileAsync = ref.watch(myProfileProvider);
  return profileAsync.valueOrNull?.isAdmin ?? false;
});