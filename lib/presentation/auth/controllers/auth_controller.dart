import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/utils/result.dart';
import '../../../core/utils/error_translator.dart';

/// يوفر عميل Supabase auth لأي مكان بالتطبيق
final supabaseAuthProvider = Provider<GoTrueClient>((ref) {
  return Supabase.instance.client.auth;
});

/// يعكس حالة تسجيل الدخول الحالية (null = زائر غير مسجل)
final authStateProvider = StreamProvider<AuthState>((ref) {
  return ref.watch(supabaseAuthProvider).onAuthStateChange;
});

/// يعطي المستخدم الحالي مباشرة (أسهل استخدام بالشاشات)
final currentUserProvider = Provider<User?>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.valueOrNull?.session?.user ??
      Supabase.instance.client.auth.currentUser;
});

/// المسؤول عن عمليات تسجيل الدخول/التسجيل/الخروج
class AuthController {
  final GoTrueClient _auth;
  AuthController(this._auth);

  Future<Result<User>> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );
      final user = response.user;
      if (user == null) {
        return const Failure('تعذر تسجيل الدخول، حاول مرة أخرى');
      }
      return Success(user);
    } catch (e) {
      return Failure(ErrorTranslator.translate(e));
    }
  }

  Future<Result<User>> signUp({
    required String email,
    required String password,
    String? fullName,
  }) async {
    try {
      final response = await _auth.signUp(
        email: email.trim(),
        password: password,
        data: fullName != null ? {'full_name': fullName} : null,
      );
      final user = response.user;
      if (user == null) {
        return const Failure('تعذر إنشاء الحساب، حاول مرة أخرى');
      }
      return Success(user);
    } catch (e) {
      return Failure(ErrorTranslator.translate(e));
    }
  }

  Future<Result<void>> signOut() async {
    try {
      await _auth.signOut();
      return const Success(null);
    } catch (e) {
      return Failure(ErrorTranslator.translate(e));
    }
  }
}

final authControllerProvider = Provider<AuthController>((ref) {
  return AuthController(ref.watch(supabaseAuthProvider));
});