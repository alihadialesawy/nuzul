import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show Supabase;

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

/// صلاحية الإدارة من قاعدة البيانات نفسها: public.is_admin()
/// (true للدورين admin و super_admin). هي نفس الدالة التي تحمي البيانات
/// بـ RLS، فالواجهة والحماية تتفقان دائمًا، ويعمل أي دور إداري نضيفه لاحقًا
/// دون تعديل التطبيق.
final _isAdminRemoteProvider = FutureProvider<bool>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return false;
  try {
    final r = await Supabase.instance.client.rpc('is_admin');
    return r == true;
  } catch (_) {
    return false;
  }
});

/// المالك فقط (super_admin): public.is_owner().
final isOwnerProvider = FutureProvider<bool>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return false;
  try {
    final r = await Supabase.instance.client.rpc('is_owner');
    return r == true;
  } catch (_) {
    return false;
  }
});

/// true لو المستخدم الحالي أدمن (admin أو super_admin). false في أي حالة
/// تانية (زائر، مستخدم عادي، أو لسه بيحمّل/فشل الجلب) — الافتراضي الآمن
/// هو "مش أدمن".
final isAdminProvider = Provider<bool>((ref) {
  final remote = ref.watch(_isAdminRemoteProvider).valueOrNull ?? false;
  final local = ref.watch(myProfileProvider).valueOrNull?.isAdmin ?? false;
  return remote || local;
});