import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// يطلب إيميل الترحيب للحساب الجديد (دالة welcome-email).
///
/// يُستدعى بعد كل تسجيل دخول، لكن الخادم هو من يقرر: يرسل مرة واحدة فقط لكل
/// حساب، وفقط إن كان الحساب جديدًا وبريده مؤكَّدًا. هنا نتجنب فقط تكرار الطلب
/// في نفس الجلسة. أي فشل يُتجاهل بصمت (الترحيب لا يعطّل شيئًا).
class WelcomeEmailService {
  WelcomeEmailService._();

  static final Set<String> _requested = {};

  static Future<void> maybeSend({required String languageCode}) async {
    final client = Supabase.instance.client;
    final user = client.auth.currentUser;
    if (user == null || user.emailConfirmedAt == null) return;
    if (!_requested.add(user.id)) return;

    // لا داعي لاستدعاء الخادم لحساب قديم (الخادم يتحقق أيضًا).
    final created = DateTime.tryParse(user.createdAt);
    if (created != null && DateTime.now().toUtc().difference(created.toUtc()).inDays > 7) return;

    try {
      await client.functions.invoke('welcome-email', body: {'locale': languageCode});
    } catch (e) {
      debugPrint('welcome-email skipped: $e');
    }
  }
}