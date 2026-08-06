import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final controller = ref.read(authControllerProvider);
    final result = await controller.signIn(
      email: _emailController.text,
      password: _passwordController.text,
    );

    if (!mounted) return;

    result.when(
      success: (user) {
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

  /// أزرار الدخول عبر Google/Apple/Facebook — شكل فقط حاليًا، هيتفعّلوا
  /// لاحقًا بربطهم بـ Supabase OAuth signInWithOAuth.
  void _showComingSoon(BuildContext context, String provider) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _t3(
            context,
            ar: 'تسجيل الدخول عبر $provider هيتفعّل قريبًا',
            en: '$provider sign-in is coming soon',
            es: 'El inicio de sesión con $provider llegará pronto',
          ),
        ),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

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
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.card_giftcard, size: 16, color: Colors.amber),
                  const SizedBox(width: 4),
                  Text(
                    _t3(
                      context,
                      ar: 'مكافآت العضوية',
                      en: 'Membership rewards',
                      es: 'Recompensas de socio',
                    ),
                    style: const TextStyle(fontSize: 12),
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

                    if (_errorMessage != null) ...[
                      const SizedBox(height: AppSizes.md),
                      Text(
                        _errorMessage!,
                        style: const TextStyle(color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                    ],

                    const SizedBox(height: AppSizes.md),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _handleLogin,
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
              // ملاحظة: أزرار الدخول الاجتماعي دي شكل بس حاليًا (Placeholders).
              // لتفعيلها فعليًا لاحقًا: Supabase.instance.client.auth.signInWithOAuth(...)
              ElevatedButton.icon(
                onPressed: () => _showComingSoon(context, 'Google'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4285F4),
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(48),
                ),
                icon: const Icon(Icons.g_mobiledata, size: 26),
                label: Text(
                  _t3(
                    context,
                    ar: 'المتابعة عبر Google',
                    en: 'Continue with Google',
                    es: 'Continuar con Google',
                  ),
                ),
              ),
              const SizedBox(height: AppSizes.sm),
              OutlinedButton.icon(
                onPressed: () => _showComingSoon(context, 'Apple'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.black87,
                  minimumSize: const Size.fromHeight(48),
                ),
                icon: const Icon(Icons.apple, size: 22),
                label: Text(
                  _t3(
                    context,
                    ar: 'المتابعة عبر Apple',
                    en: 'Continue with Apple',
                    es: 'Continuar con Apple',
                  ),
                ),
              ),
              const SizedBox(height: AppSizes.sm),
              OutlinedButton.icon(
                onPressed: () => _showComingSoon(context, 'Facebook'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF1877F2),
                  minimumSize: const Size.fromHeight(48),
                ),
                icon: const Icon(Icons.facebook, size: 22, color: Color(0xFF1877F2)),
                label: Text(
                  _t3(
                    context,
                    ar: 'المتابعة عبر Facebook',
                    en: 'Continue with Facebook',
                    es: 'Continuar con Facebook',
                  ),
                  style: const TextStyle(color: Colors.black87),
                ),
              ),

              const SizedBox(height: AppSizes.lg),
              TextButton(
                onPressed: _isLoading
                    ? null
                    : () => context.push(AppRoutes.register),
                child: Text(l10n.noAccountRegister),
              ),
            ],
          ),
        ),
      ),
    );
  }
}