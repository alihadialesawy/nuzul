import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import '../../app.dart';
import '../../core/constants/app_sizes.dart';
import '../../core/utils/validators.dart';
import '../../core/widgets/app_banner.dart';
import '../../localization/app_localizations.dart';
import 'controllers/auth_controller.dart';

/// نص حسب اللغة (عربي/إنجليزي/إسباني، والباقي إنجليزي).
String _t3(BuildContext context, {required String ar, required String en, required String es}) {
  switch (Localizations.localeOf(context).languageCode) {
    case 'ar':
      return ar;
    case 'es':
      return es;
    default:
      return en;
  }
}

class RegisterPage extends ConsumerStatefulWidget {
  const RegisterPage({super.key});

  @override
  ConsumerState<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends ConsumerState<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;
  String? _errorMessage;

  /// بعد التسجيل مع تفعيل "Confirm email" في Supabase: لا توجد جلسة دخول
  /// حتى يضغط العميل رابط التفعيل، فنعرض شاشة "تحقق من بريدك".
  String? _pendingEmail;
  bool _resending = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final controller = ref.read(authControllerProvider);
    final result = await controller.signUp(
      email: _emailController.text,
      password: _passwordController.text,
      fullName: _nameController.text.trim(),
    );

    if (!mounted) return;

    result.when(
      success: (user) {
        // لا جلسة = يلزم تأكيد البريد أولًا.
        if (sb.Supabase.instance.client.auth.currentSession == null) {
          setState(() {
            _isLoading = false;
            _pendingEmail = _emailController.text.trim();
          });
          return;
        }
        if (context.canPop()) {
          context.pop();
        } else {
          context.go(AppRoutes.home);
        }
      },
      failure: (message) {
        setState(() {
          _isLoading = false;
          _errorMessage = message;
        });
      },
    );
  }

  Future<void> _resend() async {
    final email = _pendingEmail;
    if (email == null) return;
    setState(() => _resending = true);
    try {
      await sb.Supabase.instance.client.auth.resend(type: sb.OtpType.signup, email: email);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(_t3(context,
            ar: 'أعدنا إرسال رابط التفعيل إلى $email',
            en: 'We sent the confirmation link again to $email',
            es: 'Volvimos a enviar el enlace de confirmación a $email')),
      ));
    } catch (e) {
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

  Widget _checkEmailView(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: AppSizes.xl),
        const Icon(Icons.mark_email_read_outlined, size: 64, color: Colors.teal),
        const SizedBox(height: AppSizes.md),
        Text(
          _t3(context, ar: 'تحقق من بريدك', en: 'Check your email', es: 'Revisa tu correo'),
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: AppSizes.sm),
        Text(
          _t3(context,
              ar: 'أرسلنا رابط تفعيل إلى $_pendingEmail. افتح الرسالة واضغط الرابط لتفعيل حسابك، ثم سجّل الدخول.',
              en: 'We sent a confirmation link to $_pendingEmail. Open the email and tap the link to activate your account, then sign in.',
              es: 'Enviamos un enlace de confirmación a $_pendingEmail. Abre el correo y toca el enlace para activar tu cuenta; luego inicia sesión.'),
          textAlign: TextAlign.center,
          style: const TextStyle(height: 1.5),
        ),
        const SizedBox(height: AppSizes.sm),
        Text(
          _t3(context,
              ar: 'لم تصلك الرسالة؟ تحقق من مجلد Spam، أو أعد الإرسال.',
              en: "Didn't get it? Check your spam folder, or send it again.",
              es: '¿No lo recibiste? Revisa la carpeta de spam o vuelve a enviarlo.'),
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 13, color: Colors.black54),
        ),
        const SizedBox(height: AppSizes.lg),
        OutlinedButton(
          onPressed: _resending ? null : _resend,
          child: _resending
              ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
              : Text(_t3(context,
              ar: 'إعادة إرسال رابط التفعيل',
              en: 'Resend confirmation link',
              es: 'Reenviar enlace de confirmación')),
        ),
        const SizedBox(height: AppSizes.sm),
        ElevatedButton(
          onPressed: () => context.canPop() ? context.pop() : context.go(AppRoutes.login),
          child: Text(_t3(context, ar: 'الذهاب لتسجيل الدخول', en: 'Go to sign in', es: 'Ir a iniciar sesión')),
        ),
      ],
    );
  }

  String? _confirmPasswordValidator(String? value) {
    if (value != _passwordController.text) {
      return AppLocalizations.of(context)!.confirmPassword;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: const AppBanner(),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSizes.lg),
          child: _pendingEmail != null
              ? _checkEmailView(context)
              : Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: AppSizes.md),
                Text(
                  l10n.register,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: AppSizes.xl),
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: l10n.fullName,
                    prefixIcon: const Icon(Icons.person_outline),
                  ),
                  validator: (v) => Validators.required(v, fieldName: l10n.fullName),
                ),
                const SizedBox(height: AppSizes.md),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: l10n.email,
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
                const SizedBox(height: AppSizes.md),
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: l10n.confirmPassword,
                    prefixIcon: const Icon(Icons.lock_outline),
                  ),
                  validator: _confirmPasswordValidator,
                ),

                if (_errorMessage != null) ...[
                  const SizedBox(height: AppSizes.md),
                  Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                ],

                const SizedBox(height: AppSizes.lg),
                ElevatedButton(
                  onPressed: _isLoading ? null : _handleRegister,
                  child: _isLoading
                      ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                      : Text(l10n.register),
                ),

                const SizedBox(height: AppSizes.md),
                TextButton(
                  onPressed: _isLoading ? null : () => context.pop(),
                  child: Text(l10n.haveAccountLogin),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}