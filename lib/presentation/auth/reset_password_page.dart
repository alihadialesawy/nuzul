import 'dart:async';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import '../../app.dart';
import '../../core/constants/app_sizes.dart';
import '../../core/utils/validators.dart';
import '../../core/widgets/app_banner.dart';
import '../../core/i18n/auth_strings.dart';

/// يختار النص المناسب حسب اللغة الحالية (عربي/إنجليزي/إسباني).
String _t3(
    BuildContext context, {
      required String ar,
      required String en,
      required String es,
    }) {
  final lang = Localizations.localeOf(context).languageCode;
  switch (lang) {
    case 'ar':
      return ar;
    case 'es':
      return es;
    case 'en':
      return en;
    default:
    // التركية، الإندونيسية، الهندية، الأردية، الفرنسية، البنغالية.
      return AuthStrings.lookup(en, lang) ?? en;
  }
}

/// صفحة "تعيين كلمة مرور جديدة".
///
/// طريقتان للوصول إليها:
/// 1) **الرمز (الأساسية):** بعد "نسيت كلمة المرور" ننتقل هنا مباشرة ومعنا
///    البريد (?email=...). يكتب الزبون الرمز المكوّن من 6 أرقام الذي وصله في
///    الإيميل ({{ .Token }} في قالب Supabase) مع كلمة المرور الجديدة. يعمل مهما
///    فتح الإيميل (هاتف، كمبيوتر آخر...) — لا قيود PKCE.
/// 2) **الرابط:** الويب يعود إلى flynoom.com/?flow=recovery&code=...، وAndroid
///    يصل حدث passwordRecovery. Supabase يحوّل الرمز إلى جلسة، فيظهر نموذج
///    كلمة المرور فقط. (يعمل فقط على نفس المتصفح/الجهاز.)
class ResetPasswordPage extends StatefulWidget {
  const ResetPasswordPage({super.key});

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _code = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();

  bool _saving = false;
  bool _resending = false;
  bool _obscure = true;
  String? _error;

  /// جاء من رابط الإيميل؟ ننتظر قليلًا حتى يحوّل Supabase رمز الرابط إلى جلسة.
  bool _waiting = false;

  /// عنده جلسة استعادة (من الرابط): يكفي كلمة المرور الجديدة.
  bool _hasSession = false;

  /// الرابط رجع بخطأ (منتهٍ/مستخدم). نعرض نموذج الرمز مع تنبيه.
  late final bool _linkError =
      kIsWeb && (Uri.base.queryParameters['error_code'] ?? Uri.base.queryParameters['error']) != null;
  late final bool _fromLink = kIsWeb && Uri.base.queryParameters['flow'] == 'recovery';

  bool _emailReadFromRoute = false;
  StreamSubscription<sb.AuthState>? _authSub;
  Timer? _timeout;

  sb.GoTrueClient get _auth => sb.Supabase.instance.client.auth;

  @override
  void initState() {
    super.initState();
    _hasSession = !_linkError && _fromLink && _auth.currentSession != null;
    _waiting = !_linkError && _fromLink && !_hasSession;
    _authSub = _auth.onAuthStateChange.listen((data) {
      if (!mounted) return;
      if (data.event == sb.AuthChangeEvent.passwordRecovery && data.session != null) {
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
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_emailReadFromRoute) return;
    _emailReadFromRoute = true;
    String? fromRoute;
    try {
      fromRoute = GoRouterState.of(context).uri.queryParameters['email'];
    } catch (_) {}
    if (fromRoute != null && fromRoute.isNotEmpty) _email.text = fromRoute;
  }

  @override
  void dispose() {
    _authSub?.cancel();
    _timeout?.cancel();
    _email.dispose();
    _code.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  String _codeError() => _t3(context,
      ar: 'الرمز غير صحيح أو انتهت صلاحيته. تحقق منه، أو اطلب رمزًا جديدًا.',
      en: 'The code is incorrect or has expired. Check it, or request a new code.',
      es: 'El código es incorrecto o ha caducado. Revísalo o solicita uno nuevo.');

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      // 1) طريقة الرمز: نتحقق من الرمز أولًا فنحصل على جلسة استعادة.
      if (!_hasSession) {
        try {
          await _auth.verifyOTP(
            email: _email.text.trim(),
            token: _code.text.replaceAll(RegExp(r'\s'), ''),
            type: sb.OtpType.recovery,
          );
        } on sb.AuthException {
          if (!mounted) return;
          setState(() {
            _saving = false;
            _error = _codeError();
          });
          return;
        }
      }

      // 2) حفظ كلمة المرور الجديدة.
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
            : _t3(context,
            ar: 'تعذّر حفظ كلمة المرور. حاول مرة أخرى.',
            en: 'Could not save your password. Please try again.',
            es: 'No se pudo guardar la contraseña. Inténtalo de nuevo.');
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

  /// يرسل رمزًا جديدًا (ورابطًا) إلى البريد المكتوب.
  Future<void> _resend() async {
    final email = _email.text.trim();
    if (Validators.email(email) != null) {
      setState(() => _error = _t3(context,
          ar: 'اكتب بريدك الإلكتروني أولًا.',
          en: 'Enter your email first.',
          es: 'Escribe primero tu correo.'));
      return;
    }
    setState(() {
      _resending = true;
      _error = null;
    });
    String msg = _t3(context,
        ar: 'أرسلنا رمزًا جديدًا إلى $email. تحقق أيضًا من مجلد Spam.',
        en: 'We sent a new code to $email. Check your spam folder too.',
        es: 'Enviamos un nuevo código a $email. Revisa también la carpeta de spam.');
    try {
      await _auth.resetPasswordForEmail(
        email,
        redirectTo: kIsWeb ? '${Uri.base.origin}/?flow=recovery' : 'com.flynoom.app://login-callback',
      );
    } on sb.AuthException catch (e) {
      if (e.statusCode == '429' || e.message.toLowerCase().contains('rate')) {
        msg = _t3(context,
            ar: 'طلبات كثيرة. انتظر دقيقة ثم حاول مرة أخرى.',
            en: 'Too many requests. Please wait a minute and try again.',
            es: 'Demasiadas solicitudes. Espera un minuto e inténtalo de nuevo.');
      }
    } catch (_) {}
    if (!mounted) return;
    setState(() => _resending = false);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
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

    final sessionEmail = _hasSession ? (_auth.currentUser?.email ?? '') : '';
    return AutofillGroup(
      child: Form(
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
            const SizedBox(height: AppSizes.sm),
            if (_hasSession)
              Text(sessionEmail, textAlign: TextAlign.center, style: const TextStyle(color: Colors.black54))
            else ...[
              if (_linkError)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSizes.sm),
                  child: Text(
                    _t3(context,
                        ar: 'الرابط غير صالح أو انتهت صلاحيته. استخدم الرمز المكوّن من 6 أرقام الموجود في الإيميل نفسه، أو اطلب رمزًا جديدًا.',
                        en: 'This link is invalid or has expired. Use the 6-digit code in the same email, or request a new code.',
                        es: 'Este enlace no es válido o ha caducado. Usa el código de 6 dígitos del mismo correo o solicita uno nuevo.'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              Text(
                _t3(context,
                    ar: 'أرسلنا رمزًا من 6 أرقام إلى بريدك. اكتبه هنا مع كلمة المرور الجديدة. يمكنك فتح الإيميل من أي جهاز.',
                    en: 'We sent a 6-digit code to your email. Enter it here with your new password. You can open the email on any device.',
                    es: 'Enviamos un código de 6 dígitos a tu correo. Escríbelo aquí con tu nueva contraseña. Puedes abrir el correo en cualquier dispositivo.'),
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.black54),
              ),
              const SizedBox(height: AppSizes.lg),
              TextFormField(
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                autofillHints: const [AutofillHints.email],
                decoration: InputDecoration(
                  labelText: _t3(context, ar: 'البريد الإلكتروني', en: 'Email', es: 'Correo electrónico'),
                  prefixIcon: const Icon(Icons.email_outlined),
                ),
                validator: Validators.email,
              ),
              const SizedBox(height: AppSizes.md),
              TextFormField(
                controller: _code,
                keyboardType: TextInputType.number,
                autofillHints: const [AutofillHints.oneTimeCode],
                maxLength: 10,
                decoration: InputDecoration(
                  labelText: _t3(context, ar: 'الرمز من الإيميل', en: 'Code from the email', es: 'Código del correo'),
                  prefixIcon: const Icon(Icons.pin_outlined),
                  counterText: '',
                ),
                validator: (v) {
                  final d = (v ?? '').replaceAll(RegExp(r'\s'), '');
                  return RegExp(r'^\d{6,10}$').hasMatch(d)
                      ? null
                      : _t3(context,
                      ar: 'اكتب الرمز المكوّن من 6 أرقام',
                      en: 'Enter the 6-digit code',
                      es: 'Escribe el código de 6 dígitos');
                },
              ),
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: TextButton(
                  onPressed: _resending || _saving ? null : _resend,
                  child: Text(_t3(context, ar: 'أرسل رمزًا جديدًا', en: 'Send a new code', es: 'Enviar un nuevo código')),
                ),
              ),
            ],
            const SizedBox(height: AppSizes.md),
            TextFormField(
              controller: _password,
              obscureText: _obscure,
              autofillHints: const [AutofillHints.newPassword],
              decoration: InputDecoration(
                labelText: _t3(context, ar: 'كلمة المرور الجديدة', en: 'New password', es: 'Nueva contraseña'),
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  tooltip: _t3(context, ar: 'إظهار كلمة المرور', en: 'Show password', es: 'Mostrar contraseña'),
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
              Semantics(
                liveRegion: true,
                child: Text(_error!, style: const TextStyle(color: Colors.red), textAlign: TextAlign.center),
              ),
            ],
            const SizedBox(height: AppSizes.lg),
            ElevatedButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                  height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Text(_t3(context, ar: 'حفظ كلمة المرور', en: 'Save password', es: 'Guardar contraseña')),
            ),
            const SizedBox(height: AppSizes.sm),
            TextButton(
              onPressed: () => context.go(AppRoutes.login),
              child: Text(_t3(context, ar: 'رجوع إلى تسجيل الدخول', en: 'Back to sign in', es: 'Volver a iniciar sesión')),
            ),
          ],
        ),
      ),
    );
  }
}