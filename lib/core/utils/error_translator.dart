import 'package:supabase_flutter/supabase_flutter.dart';

/// يحوّل أخطاء Supabase التقنية (إنجليزي) إلى رسائل عربية مفهومة للمستخدم
class ErrorTranslator {
  ErrorTranslator._();

  static String translate(Object error) {
    if (error is AuthException) {
      return _translateAuthError(error.message);
    }
    if (error is PostgrestException) {
      return _translatePostgrestError(error.message);
    }
    if (error.toString().contains('SocketException') ||
        error.toString().contains('Failed host lookup')) {
      return 'لا يوجد اتصال بالإنترنت، تحقق من الشبكة وحاول مرة أخرى';
    }
    return 'حدث خطأ غير متوقع، حاول مرة أخرى';
  }

  static String _translateAuthError(String message) {
    final lower = message.toLowerCase();

    if (lower.contains('invalid login credentials')) {
      return 'البريد الإلكتروني أو كلمة المرور غير صحيحة';
    }
    if (lower.contains('user already registered') ||
        lower.contains('already registered')) {
      return 'هذا البريد الإلكتروني مسجل مسبقًا';
    }
    if (lower.contains('email not confirmed')) {
      return 'يجب تأكيد البريد الإلكتروني أولاً';
    }
    if (lower.contains('password should be at least')) {
      return 'كلمة المرور قصيرة جدًا، يجب أن لا تقل عن 6 أحرف';
    }
    if (lower.contains('invalid email')) {
      return 'صيغة البريد الإلكتروني غير صحيحة';
    }
    if (lower.contains('rate limit')) {
      return 'محاولات كثيرة جدًا، حاول مرة أخرى بعد قليل';
    }
    return 'حدث خطأ أثناء تسجيل الدخول، حاول مرة أخرى';
  }

  static String _translatePostgrestError(String message) {
    final lower = message.toLowerCase();

    if (lower.contains('duplicate key')) {
      return 'هذا العنصر موجود مسبقًا';
    }
    if (lower.contains('violates row-level security')) {
      return 'ليس لديك صلاحية للقيام بهذه العملية';
    }
    if (lower.contains('foreign key')) {
      return 'لا يمكن إتمام العملية، البيانات المرتبطة غير موجودة';
    }
    return 'حدث خطأ أثناء معالجة البيانات، حاول مرة أخرى';
  }
}