import 'dart:async';

import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
// استيراد كامل بالبادئة sb: الدالة signInWithOAuth إضافة (extension) من
// supabase_flutter ولا تتوفر مع استيراد show لأسماء محددة.
import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import '../../app.dart';
import '../../core/constants/app_sizes.dart';
import '../../core/utils/validators.dart';
import '../../core/widgets/app_banner.dart';
import '../../localization/app_localizations.dart';
import 'controllers/auth_controller.dart';

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

/// رابط الرجوع لتطبيق Android بعد تسجيل الدخول عبر Google.
/// ⚠️ يجب أن يطابق:
///   1) applicationId في android/app/build.gradle.kts (الجزء قبل ://)
///   2) intent-filter في AndroidManifest.xml (scheme + host)
///   3) Redirect URLs في Supabase ← Authentication ← URL Configuration
const String _kMobileRedirect = 'com.flynoom.app://login-callback';

/// زر Google يظهر على الويب و Android فقط:
/// - iPhone: مخفي حتى نضيف "Sign in with Apple" معه (شرط Apple، المادة 4.8).
/// - Windows/macOS: تسجيل الدخول عبر المتصفح يحتاج إعدادًا خاصًا؛ للتجربة
///   شغّل الويب: flutter run -d chrome --web-port 5000
bool get _googleSupportedHere {
  if (kIsWeb) return true;
  return defaultTargetPlatform == TargetPlatform.android;
}

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _googleLoading = false;
  String? _errorMessage;

  /// الدخول فشل لأن البريد لم يُفعَّل بعد (Confirm email في Supabase).
  bool _notConfirmed = false;
  bool _resending = false;

  /// على Android: بعد العودة من صفحة Google عبر الرابط، يصلنا حدث signedIn
  /// فنغلق صفحة الدخول. (على الويب الصفحة كلها تُعاد تحميلها بعد الرجوع.)
  StreamSubscription? _authSub;
  bool _awaitingGoogle = false;

  @override
  void initState() {
    super.initState();
    _authSub = sb.Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      if (!mounted || !_awaitingGoogle) return;
      if (data.event == sb.AuthChangeEvent.signedIn) {
        _awaitingGoogle = false;
        _leavePage();
      }
    });
  }

  @override
  void dispose() {
    _authSub?.cancel();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _leavePage() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRoutes.home);
    }
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _notConfirmed = false;
    });

    final controller = ref.read(authControllerProvider);
    final result = await controller.signIn(
      email: _emailController.text,
      password: _passwordController.text,
    );

    if (!mounted) return;

    result.when(
      success: (user) => _leavePage(),
      failure: (message) {
        final m = message.toLowerCase();
        final notConfirmed = m.contains('not confirmed') ||
            m.contains('email_not_confirmed') ||
            m.contains('confirm your email') ||
            m.contains('غير مؤكد') ||
            m.contains('تأكيد البريد') ||
            m.contains('تفعيل');
        setState(() {
          _isLoading = false;
          _notConfirmed = notConfirmed;
          _errorMessage = notConfirmed
              ? _t3(context,
              ar: 'لم تفعّل حسابك بعد. افتح رسالة التفعيل في بريدك واضغط الرابط، ثم سجّل الدخول.',
              en: "Your account isn't activated yet. Open the confirmation email and tap the link, then sign in.",
              es: 'Tu cuenta aún no está activada. Abre el correo de confirmación y toca el enlace; luego inicia sesión.')
              : message;
        });
      },
    );
  }

  Future<void> _resendConfirmation() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) return;
    setState(() => _resending = true);
    try {
      await sb.Supabase.instance.client.auth.resend(type: sb.OtpType.signup, email: email);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(_t3(context,
            ar: 'أعدنا إرسال رابط التفعيل إلى $email. تحقق أيضًا من مجلد Spam.',
            en: 'We sent the confirmation link again to $email. Check your spam folder too.',
            es: 'Volvimos a enviar el enlace a $email. Revisa también la carpeta de spam.')),
      ));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(_t3(context,
            ar: 'تعذّر الإرسال الآن. انتظر دقيقة ثم حاول مرة أخرى.',
            en: 'Could not send right now. Please wait a minute and try again.',
            es: 'No se pudo enviar ahora. Espera un minuto e inténtalo de nuevo.')),
      ));
    } finally {
      if (mounted) setState(() => _resending = false);
    }
  }

  /// "نسيت كلمة المرور؟": يرسل Supabase رابط إعادة التعيين إلى البريد.
  /// الويب: يعود الرابط إلى /?flow=recovery فيفتح التطبيق صفحة كلمة المرور
  /// الجديدة (app.dart). Android: يفتح التطبيق عبر _kMobileRedirect ويصل
  /// حدث passwordRecovery.
  Future<void> _forgotPassword() async {
    // النافذة تملك حقل النص الخاص بها وتتخلص منه بنفسها بعد إغلاقها بالكامل
    // (التخلص منه هنا مباشرة بعد الإغلاق يسبب الشاشة الحمراء أثناء حركة الإغلاق).
    final email = await showDialog<String>(
      context: context,
      builder: (_) => _ForgotPasswordDialog(initialEmail: _emailController.text.trim()),
    );
    if (email == null || email.isEmpty || !mounted) return;

    try {
      await sb.Supabase.instance.client.auth.resetPasswordForEmail(
        email,
        redirectTo: kIsWeb ? '${Uri.base.origin}/?flow=recovery' : _kMobileRedirect,
      );
    } on sb.AuthException catch (e) {
      // كثرة الطلبات: نخبر المستخدم أن ينتظر. غير ذلك نعرض نفس الرسالة
      // دائمًا، حتى لا يعرف أحد أي البريد مسجّل عندنا وأيها غير مسجّل.
      if (e.statusCode == '429' || e.message.toLowerCase().contains('rate')) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(_t3(context,
              ar: 'طلبات كثيرة. انتظر دقيقة ثم حاول مرة أخرى.',
              en: 'Too many requests. Please wait a minute and try again.',
              es: 'Demasiadas solicitudes. Espera un minuto e inténtalo de nuevo.')),
        ));
        return;
      }
    } catch (_) {}
    if (!mounted) return;

    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(_t3(ctx, ar: 'تحقق من بريدك', en: 'Check your email', es: 'Revisa tu correo')),
        content: Text(_t3(ctx,
            ar: 'إذا كان هناك حساب بالبريد $email فستصلك رسالة فيها رابط لتعيين كلمة مرور جديدة. '
                'افتح الرابط على هذا الجهاز وهذا المتصفح نفسه. تحقق أيضًا من مجلد Spam.',
            en: "If an account exists for $email, you'll receive an email with a link to set a new password. "
                'Open the link on this same device and browser. Check your spam folder too.',
            es: 'Si existe una cuenta con $email, recibirás un correo con un enlace para crear una nueva contraseña. '
                'Ábrelo en este mismo dispositivo y navegador. Revisa también la carpeta de spam.')),
        actions: [
          FilledButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK')),
        ],
      ),
    );
  }

  /// تسجيل الدخول عبر Google (Supabase OAuth، تدفق PKCE الافتراضي).
  /// الويب: ينتقل المتصفح لصفحة Google ثم يرجع لنفس الموقع مسجّلًا.
  /// Android: يفتح المتصفح، ثم يرجع للتطبيق عبر _kMobileRedirect.
  Future<void> _handleGoogle() async {
    setState(() {
      _googleLoading = true;
      _errorMessage = null;
    });
    _awaitingGoogle = true;

    final failedMsg = _t3(
      context,
      ar: 'تعذّر فتح تسجيل الدخول عبر Google. حاول مرة أخرى.',
      en: 'Could not open Google sign-in. Please try again.',
      es: 'No se pudo abrir el inicio de sesión con Google. Inténtalo de nuevo.',
    );

    try {
      final opened = await sb.Supabase.instance.client.auth.signInWithOAuth(
        sb.OAuthProvider.google,
        // '/' في النهاية ضروري: Redirect URLs في Supabase مثل http://localhost:5000/**
        // لا تطابق الرابط بدون '/'، فيرجع المستخدم إلى Site URL (flynoom.com).
        redirectTo: kIsWeb ? '${Uri.base.origin}/' : _kMobileRedirect,
        authScreenLaunchMode:
        kIsWeb ? sb.LaunchMode.platformDefault : sb.LaunchMode.externalApplication,
        // يعرض قائمة الحسابات دائمًا، حتى يختار المستخدم الحساب الصحيح.
        queryParams: const {'prompt': 'select_account'},
      );
      if (!opened) {
        _awaitingGoogle = false;
        if (mounted) setState(() => _errorMessage = failedMsg);
      }
    } on sb.AuthException catch (e) {
      _awaitingGoogle = false;
      if (mounted) setState(() => _errorMessage = e.message);
    } catch (_) {
      _awaitingGoogle = false;
      if (mounted) setState(() => _errorMessage = failedMsg);
    } finally {
      // على Android يرجع الاستدعاء فور فتح المتصفح؛ لا نترك الزر معطّلًا
      // لو ألغى المستخدم ورجع دون تسجيل.
      if (mounted) setState(() => _googleLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final busy = _isLoading || _googleLoading;

    return Scaffold(
      appBar: const AppBanner(),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSizes.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: AppSizes.md),
              Text(
                _t3(
                  context,
                  ar: 'تسجيل الدخول / إنشاء حساب',
                  en: 'Sign in/register',
                  es: 'Iniciar sesión/registrarse',
                ),
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: AppSizes.sm),
              // مزايا حقيقية فقط (نظام المكافآت مخفي، فلا نعد به هنا).
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.bolt_outlined, size: 16, color: Colors.amber),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      _t3(
                        context,
                        ar: 'بياناتك محفوظة لحجز أسرع',
                        en: 'Faster booking with saved details',
                        es: 'Reserva más rápido con tus datos guardados',
                      ),
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Icon(Icons.event_available_outlined, size: 16, color: Colors.teal),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      _t3(
                        context,
                        ar: 'إدارة الحجوزات بسهولة',
                        en: 'Manage bookings with ease',
                        es: 'Gestiona tus reservas fácilmente',
                      ),
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSizes.xl),
              Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        hintText: _t3(
                          context,
                          ar: 'من فضلك أدخل بريدك الإلكتروني',
                          en: 'Please enter an email address',
                          es: 'Introduce un correo electrónico',
                        ),
                        prefixIcon: const Icon(Icons.email_outlined),
                      ),
                      validator: Validators.email,
                    ),
                    const SizedBox(height: AppSizes.md),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: l10n.password,
                        prefixIcon: const Icon(Icons.lock_outline),
                      ),
                      validator: Validators.password,
                    ),
                    Align(
                      alignment: AlignmentDirectional.centerEnd,
                      child: TextButton(
                        onPressed: busy ? null : _forgotPassword,
                        child: Text(_t3(
                          context,
                          ar: 'نسيت كلمة المرور؟',
                          en: 'Forgot password?',
                          es: '¿Olvidaste tu contraseña?',
                        )),
                      ),
                    ),

                    if (_errorMessage != null) ...[
                      const SizedBox(height: AppSizes.md),
                      Text(
                        _errorMessage!,
                        style: const TextStyle(color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                      if (_notConfirmed)
                        TextButton(
                          onPressed: _resending ? null : _resendConfirmation,
                          child: Text(_t3(context,
                              ar: 'إعادة إرسال رابط التفعيل',
                              en: 'Resend confirmation link',
                              es: 'Reenviar enlace de confirmación')),
                        ),
                    ],

                    const SizedBox(height: AppSizes.md),
                    ElevatedButton(
                      onPressed: busy ? null : _handleLogin,
                      child: _isLoading
                          ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                          : Text(
                        _t3(
                          context,
                          ar: 'المتابعة بالبريد الإلكتروني',
                          en: 'Continue with email',
                          es: 'Continuar con correo electrónico',
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              if (_googleSupportedHere) ...[
                const SizedBox(height: AppSizes.lg),
                Row(
                  children: [
                    const Expanded(child: Divider()),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text(_t3(context, ar: 'أو', en: 'or', es: 'o')),
                    ),
                    const Expanded(child: Divider()),
                  ],
                ),
                const SizedBox(height: AppSizes.lg),
                // زر بأسلوب Google الرسمي (أبيض بإطار + شعار G). ملف الشعار
                // assets/images/google_g.png من صفحة Google Branding Guidelines؛
                // إن لم يوجد يظهر رمز بديل.
                OutlinedButton(
                  onPressed: busy ? null : _handleGoogle,
                  style: OutlinedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF1F1F1F),
                    side: const BorderSide(color: Color(0xFF747775)),
                    minimumSize: const Size.fromHeight(48),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                  ),
                  child: _googleLoading
                      ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                      : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset(
                        'assets/images/google_g.png',
                        height: 20,
                        width: 20,
                        errorBuilder: (_, __, ___) =>
                        const Icon(Icons.g_mobiledata, size: 26, color: Color(0xFF4285F4)),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        _t3(
                          context,
                          ar: 'المتابعة عبر Google',
                          en: 'Continue with Google',
                          es: 'Continuar con Google',
                        ),
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSizes.sm),
                // الموافقة على الشروط عند إنشاء حساب عبر Google (لا يمر بصفحة التسجيل).
                Wrap(
                  alignment: WrapAlignment.center,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      _t3(
                        context,
                        ar: 'بالمتابعة عبر Google، فإنك توافق على',
                        en: 'By continuing with Google, you agree to our',
                        es: 'Al continuar con Google, aceptas nuestros',
                      ),
                      style: const TextStyle(fontSize: 12),
                    ),
                    TextButton(
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      onPressed: () => context.push(AppRoutes.termsOfService),
                      child: Text(
                        _t3(context, ar: 'شروط الخدمة', en: 'Terms of Service', es: 'Términos del servicio'),
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                    Text(
                      _t3(context, ar: 'وتقرّ بـ', en: 'and acknowledge our', es: 'y reconoces nuestro'),
                      style: const TextStyle(fontSize: 12),
                    ),
                    TextButton(
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      onPressed: () => context.push(AppRoutes.privacyNotice),
                      child: Text(
                        _t3(context, ar: 'إشعار الخصوصية', en: 'Privacy Notice', es: 'Aviso de privacidad'),
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ],

              // Apple و Facebook: مؤجلان. Apple يُضاف مع إطلاق تطبيق iPhone
              // (بعد تفعيل حساب Apple Developer)، و Facebook غير مخطط حاليًا.

              const SizedBox(height: AppSizes.lg),
              TextButton(
                onPressed: busy ? null : () => context.push(AppRoutes.register),
                child: Text(l10n.noAccountRegister),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// نافذة "نسيت كلمة المرور؟": تطلب البريد وترجعه عند الضغط على "أرسل الرابط".
class _ForgotPasswordDialog extends StatefulWidget {
  final String initialEmail;
  const _ForgotPasswordDialog({required this.initialEmail});

  @override
  State<_ForgotPasswordDialog> createState() => _ForgotPasswordDialogState();
}

class _ForgotPasswordDialogState extends State<_ForgotPasswordDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _controller = TextEditingController(text: widget.initialEmail);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) Navigator.pop(context, _controller.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_t3(context, ar: 'إعادة تعيين كلمة المرور', en: 'Reset your password', es: 'Restablecer contraseña')),
      content: SizedBox(
        width: 400,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _t3(context,
                    ar: 'أدخل بريدك الإلكتروني وسنرسل لك رابطًا لتعيين كلمة مرور جديدة.',
                    en: "Enter your email and we'll send you a link to set a new password.",
                    es: 'Introduce tu correo y te enviaremos un enlace para crear una nueva contraseña.'),
              ),
              const SizedBox(height: AppSizes.md),
              TextFormField(
                controller: _controller,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(prefixIcon: Icon(Icons.email_outlined)),
                validator: Validators.email,
                onFieldSubmitted: (_) => _submit(),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(_t3(context, ar: 'رجوع', en: 'Back', es: 'Volver')),
        ),
        FilledButton(
          onPressed: _submit,
          child: Text(_t3(context, ar: 'أرسل الرابط', en: 'Send link', es: 'Enviar enlace')),
        ),
      ],
    );
  }
}
