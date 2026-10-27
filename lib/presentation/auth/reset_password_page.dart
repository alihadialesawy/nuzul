import 'dart:async';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import '../../app.dart';
import '../../core/constants/app_sizes.dart';
import '../../core/utils/validators.dart';
import '../../core/widgets/app_banner.dart';

/// يختار النص المناسب حسب اللغة الحالية (عربي/إنجليزي/إسباني).
String _t3(
    BuildContext context, {
      required String ar,
      required String en,
      required String es,
    }) {
  switch (Localizations.localeOf(context).languageCode) {
    case 'ar':
      return ar;
    case 'es':
      return es;
    default:
      return en;
  }
}

/// صفحة "تعيين كلمة مرور جديدة".
///
/// يصل إليها المستخدم من رابط "نسيت كلمة المرور" في بريده:
/// - الويب: الرابط يعيده إلى flynoom.com/?flow=recovery&code=...، فيفتح
///   التطبيق هذه الصفحة مباشرة (انظر app.dart)، ويحوّل Supabase الرمز إلى
///   جلسة مؤقتة.
/// - Android: الرابط يفتح التطبيق، ويصل حدث passwordRecovery فينقلنا هنا.
///
/// ⚠️ الرابط يعمل فقط على نفس المتصفح/الجهاز الذي طُلب منه (أمان PKCE).
class ResetPasswordPage extends StatefulWidget {
  const ResetPasswordPage({super.key});

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _password = TextEditingController();
  final _confirm = TextEditingController();

  bool _saving = false;
  bool _obscure = true;
  String? _error;

  /// ننتظر قليلًا حتى يحوّل Supabase رمز الرابط إلى جلسة.
  bool _waiting = true;
  bool _hasSession = false;

  /// رجع الرابط بخطأ من Supabase (مثل otp_expired: الرابط قديم أو استُخدم).
  late final bool _linkError =
      kIsWeb && (Uri.base.queryParameters['error_code'] ?? Uri.base.queryParameters['error']) != null;
  StreamSubscription<sb.AuthState>? _authSub;
  Timer? _timeout;

  sb.GoTrueClient get _auth => sb.Supabase.instance.client.auth;

  @override
  void initState() {
    super.initState();
    if (_linkError) {
      _waiting = false;
      _hasSession = false;
      return;
    }
    _hasSession = _auth.currentSession != null;
    _waiting = !_hasSession;
    _authSub = _auth.onAuthStateChange.listen((data) {
      if (!mounted) return;
      if (data.session != null) {
        setState(() {
          _hasSession = true;
          _waiting = false;
        });
      }
    });
    if (_waiting) {
      _timeout = Timer(const Duration(seconds: 8), () {
        if (mounted) {
          setState(() {
            _waiting = false;
            _hasSession = _auth.currentSession != null;
          });
        }
      });
    }
  }

  @override
  void dispose() {
    _authSub?.cancel();
    _timeout?.cancel();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await _auth.updateUser(sb.UserAttributes(password: _password.text));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(_t3(context,
            ar: 'تم تغيير كلمة المرور. أنت الآن مسجّل الدخول.',
            en: 'Your password has been changed. You are now signed in.',
            es: 'Tu contraseña se ha cambiado. Ya has iniciado sesión.')),
      ));
      context.go(AppRoutes.home);
    } on sb.AuthException catch (e) {
      if (!mounted) return;
      final m = e.message.toLowerCase();
      setState(() {
        _saving = false;
        _error = m.contains('different from the old')
            ? _t3(context,
            ar: 'كلمة المرور الجديدة يجب أن تختلف عن القديمة.',
            en: 'Your new password must be different from your old one.',
            es: 'La nueva contraseña debe ser diferente de la anterior.')
            : e.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = _t3(context,
            ar: 'تعذّر حفظ كلمة المرور. حاول مرة أخرى.',
            en: 'Could not save your password. Please try again.',
            es: 'No se pudo guardar la contraseña. Inténtalo de nuevo.');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AppBanner(),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSizes.lg),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: _body(context),
            ),
          ),
        ),
      ),
    );
  }

  Widget _body(BuildContext context) {
    if (_waiting) {
      return const Padding(
        padding: EdgeInsets.only(top: 80),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (!_hasSession) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: AppSizes.xl),
          const Icon(Icons.link_off, size: 48, color: Colors.grey),
          const SizedBox(height: AppSizes.md),
          Text(
            _t3(context,
                ar: 'الرابط غير صالح أو انتهت صلاحيته',
                en: 'This link is invalid or has expired',
                es: 'Este enlace no es válido o ha caducado'),
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: AppSizes.sm),
          Text(
            _t3(context,
                ar: 'اطلب رابطًا جديدًا من صفحة تسجيل الدخول، وافتحه على نفس الجهاز والمتصفح الذي طلبته منه.',
                en: 'Request a new link from the sign-in page, and open it on the same device and browser you requested it from.',
                es: 'Solicita un nuevo enlace desde la página de inicio de sesión y ábrelo en el mismo dispositivo y navegador.'),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSizes.lg),
          ElevatedButton(
            onPressed: () => context.go(AppRoutes.login),
            child: Text(_t3(context, ar: 'إلى تسجيل الدخول', en: 'Go to sign in', es: 'Ir a iniciar sesión')),
          ),
        ],
      );
    }

    final email = _auth.currentUser?.email ?? '';
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: AppSizes.md),
          Text(
            _t3(context, ar: 'تعيين كلمة مرور جديدة', en: 'Set a new password', es: 'Crea una nueva contraseña'),
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          if (email.isNotEmpty) ...[
            const SizedBox(height: AppSizes.sm),
            Text(email, textAlign: TextAlign.center, style: const TextStyle(color: Colors.black54)),
          ],
          const SizedBox(height: AppSizes.xl),
          TextFormField(
            controller: _password,
            obscureText: _obscure,
            autofillHints: const [AutofillHints.newPassword],
            decoration: InputDecoration(
              labelText: _t3(context, ar: 'كلمة المرور الجديدة', en: 'New password', es: 'Nueva contraseña'),
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                onPressed: () => setState(() => _obscure = !_obscure),
              ),
            ),
            validator: Validators.password,
          ),
          const SizedBox(height: AppSizes.md),
          TextFormField(
            controller: _confirm,
            obscureText: _obscure,
            autofillHints: const [AutofillHints.newPassword],
            decoration: InputDecoration(
              labelText: _t3(context, ar: 'تأكيد كلمة المرور', en: 'Confirm password', es: 'Confirmar contraseña'),
              prefixIcon: const Icon(Icons.lock_outline),
            ),
            validator: (v) => v != _password.text
                ? _t3(context,
                ar: 'كلمتا المرور غير متطابقتين',
                en: 'Passwords do not match',
                es: 'Las contraseñas no coinciden')
                : null,
            onFieldSubmitted: (_) => _saving ? null : _save(),
          ),
          if (_error != null) ...[
            const SizedBox(height: AppSizes.md),
            Text(_error!, style: const TextStyle(color: Colors.red), textAlign: TextAlign.center),
          ],
          const SizedBox(height: AppSizes.lg),
          ElevatedButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : Text(_t3(context, ar: 'حفظ كلمة المرور', en: 'Save password', es: 'Guardar contraseña')),
          ),
        ],
      ),
    );
  }
}