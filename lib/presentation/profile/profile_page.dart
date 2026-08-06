import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';

import '../../app.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../core/widgets/loading_view.dart';
import '../../core/widgets/error_view.dart';
import '../../data/models/profile_model.dart';
import '../auth/controllers/auth_controller.dart';
import 'controllers/profile_controller.dart';

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

void _comingSoon(BuildContext context) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(_t3(context, ar: 'قريبًا', en: 'Coming soon', es: 'Próximamente')),
      duration: const Duration(seconds: 1),
    ),
  );
}

String _maskEmail(String? email) {
  if (email == null || !email.contains('@')) return '-';
  final parts = email.split('@');
  final name = parts[0];
  if (name.length <= 3) return '$name***@${parts[1]}';
  return '${name.substring(0, 3)}****@${parts[1]}';
}

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  Future<void> _logout(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(_t3(dialogContext, ar: 'تسجيل الخروج', en: 'Sign out', es: 'Cerrar sesión')),
        content: Text(
          _t3(
            dialogContext,
            ar: 'هل أنت متأكد إنك تبي تسجل خروج؟',
            en: 'Are you sure you want to sign out?',
            es: '¿Seguro que quieres cerrar sesión?',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(_t3(dialogContext, ar: 'إلغاء', en: 'Cancel', es: 'Cancelar')),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(_t3(dialogContext, ar: 'تسجيل الخروج', en: 'Sign out', es: 'Cerrar sesión')),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final result = await ref.read(authControllerProvider).signOut();
    if (!context.mounted) return;

    result.when(
      success: (_) => context.go(AppRoutes.login),
      failure: (message) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(myProfileProvider);
    final user = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(_t3(context, ar: 'حسابي', en: 'My Account', es: 'Mi cuenta')),
      ),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ProfileSidebar(
            displayName: user?.email?.split('@').first ?? '',
            onLogout: () => _logout(context, ref),
          ),
          const VerticalDivider(width: 1),
          Expanded(
            child: profileAsync.when(
              loading: () => LoadingView(
                message: _t3(context, ar: 'يحمّل بيانات حسابك...', en: 'Loading your account...', es: 'Cargando tu cuenta...'),
              ),
              error: (error, _) => ErrorView(
                message: _t3(
                  context,
                  ar: 'تعذر تحميل بيانات الحساب',
                  en: 'Could not load account data',
                  es: 'No se pudieron cargar los datos',
                ),
                onRetry: () => ref.invalidate(myProfileProvider),
              ),
              data: (profile) => _ProfileMainContent(profile: profile, user: user),
            ),
          ),
        ],
      ),
    );
  }
}

/// القائمة الجانبية (Sidebar) — زي هيكل Trip.com بالظبط: Member header،
/// My bookings (بكل الأقسام الفرعية)، Saved/My posts/Price alerts/...،
/// وقسم Account (Profile مفعّل، الباقي "قريبًا")، وزر تسجيل الخروج بالأسفل.
class _ProfileSidebar extends StatelessWidget {
  final String displayName;
  final VoidCallback onLogout;
  const _ProfileSidebar({required this.displayName, required this.onLogout});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 260,
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: AppSizes.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSizes.md),
              child: Row(
                children: [
                  const CircleAvatar(child: Icon(Icons.person)),
                  const SizedBox(width: AppSizes.sm),
                  Text(
                    displayName.isEmpty
                        ? _t3(context, ar: 'عضو', en: 'Member', es: 'Miembro')
                        : displayName,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSizes.md),
            _SidebarSectionHeader(_t3(context, ar: 'حجوزاتي', en: 'My bookings', es: 'Mis reservas')),
            _SidebarItem(label: _t3(context, ar: 'الكل', en: 'All', es: 'Todo'), onTap: () => context.push(AppRoutes.myBookings)),
            _SidebarItem(label: _t3(context, ar: 'الطيران', en: 'Flights', es: 'Vuelos'), onTap: () => context.push(AppRoutes.myBookings)),
            _SidebarItem(label: _t3(context, ar: 'الفنادق', en: 'Hotels', es: 'Hoteles'), onTap: () => context.push(AppRoutes.myBookings)),
            _SidebarItem(label: _t3(context, ar: 'تأجير السيارات', en: 'Car Rentals', es: 'Alquiler de coches'), onTap: () => context.push(AppRoutes.myBookings)),
            _SidebarItem(label: _t3(context, ar: 'نقل المطار', en: 'Airport Transfers', es: 'Traslados'), onTap: () => _comingSoon(context)),
            _SidebarItem(label: _t3(context, ar: 'المعالم والجولات', en: 'Attractions & Tours', es: 'Atracciones y tours'), onTap: () => _comingSoon(context)),
            _SidebarItem(label: _t3(context, ar: 'طيران + فندق', en: 'Flight + Hotel', es: 'Vuelo + Hotel'), onTap: () => context.push(AppRoutes.home)),
            _SidebarItem(label: _t3(context, ar: 'بطاقات الهدايا', en: 'Gift Cards', es: 'Tarjetas de regalo'), onTap: () => _comingSoon(context)),
            _SidebarItem(label: _t3(context, ar: 'التأمين', en: 'Insurance', es: 'Seguro'), onTap: () => _comingSoon(context)),
            _SidebarItem(label: _t3(context, ar: 'جولات خاصة', en: 'Private Tours', es: 'Tours privados'), onTap: () => _comingSoon(context)),
            _SidebarItem(label: _t3(context, ar: 'باقات سياحية', en: 'Tour Packages', es: 'Paquetes turísticos'), onTap: () => _comingSoon(context)),
            const SizedBox(height: AppSizes.sm),
            _SidebarItem(label: _t3(context, ar: 'المحفوظات', en: 'Saved', es: 'Guardado'), bold: true, onTap: () => _comingSoon(context)),
            _SidebarItem(label: _t3(context, ar: 'منشوراتي', en: 'My posts', es: 'Mis publicaciones'), bold: true, onTap: () => _comingSoon(context)),
            _SidebarItem(
              label: _t3(context, ar: 'تنبيهات الأسعار', en: 'Price alerts', es: 'Alertas de precio'),
              bold: true,
              onTap: () => context.push(AppRoutes.aiTravel),
            ),
            _SidebarItem(label: _t3(context, ar: 'بطاقاتي', en: 'My cards', es: 'Mis tarjetas'), bold: true, onTap: () => _comingSoon(context)),
            _SidebarItem(label: _t3(context, ar: 'بطاقات الهدايا', en: 'Gift cards', es: 'Tarjetas de regalo'), bold: true, onTap: () => _comingSoon(context)),
            _SidebarItem(label: _t3(context, ar: 'أكواد الخصم', en: 'Promo codes', es: 'Códigos promo'), bold: true, onTap: () => _comingSoon(context)),
            const SizedBox(height: AppSizes.sm),
            _SidebarSectionHeader(_t3(context, ar: 'الحساب', en: 'Account', es: 'Cuenta')),
            _SidebarItem(
              label: _t3(context, ar: 'الملف الشخصي', en: 'Profile', es: 'Perfil'),
              selected: true,
              onTap: () {},
            ),
            _SidebarItem(label: _t3(context, ar: 'بيانات المسافر المتكرر', en: 'Frequent traveler info', es: 'Viajero frecuente'), onTap: () => _comingSoon(context)),
            _SidebarItem(label: _t3(context, ar: 'بيانات الاتصال', en: 'Contact info', es: 'Información de contacto'), onTap: () => _comingSoon(context)),
            _SidebarItem(label: _t3(context, ar: 'خيارات الفواتير', en: 'Receipt & invoice options', es: 'Opciones de factura'), onTap: () => _comingSoon(context)),
            _SidebarItem(label: _t3(context, ar: 'الاشتراكات', en: 'Subscriptions', es: 'Suscripciones'), onTap: () => _comingSoon(context)),
            const Divider(height: AppSizes.lg),
            _SidebarItem(
              label: _t3(context, ar: 'تسجيل الخروج', en: 'Sign out', es: 'Cerrar sesión'),
              bold: true,
              danger: true,
              onTap: onLogout,
            ),
          ],
        ),
      ),
    );
  }
}

class _SidebarSectionHeader extends StatelessWidget {
  final String title;
  const _SidebarSectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSizes.md, AppSizes.sm, AppSizes.md, 4),
      child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
    );
  }
}

class _SidebarItem extends StatelessWidget {
  final String label;
  final bool bold;
  final bool selected;
  final bool danger;
  final VoidCallback onTap;

  const _SidebarItem({
    required this.label,
    required this.onTap,
    this.bold = false,
    this.selected = false,
    this.danger = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        color: selected ? AppColors.primary.withOpacity(0.08) : null,
        padding: const EdgeInsets.symmetric(horizontal: AppSizes.md, vertical: 8),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: bold || selected ? FontWeight.w600 : FontWeight.normal,
            color: danger
                ? Colors.red
                : (selected ? AppColors.primary : AppColors.textSecondary),
          ),
        ),
      ),
    );
  }
}

/// المحتوى الرئيسي: Account Security + Member Profile + Personal info
class _ProfileMainContent extends ConsumerWidget {
  final ProfileModel? profile;
  final User? user;

  const _ProfileMainContent({required this.profile, required this.user});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSizes.lg),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 900),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _t3(context, ar: 'أمان الحساب', en: 'Account Security', es: 'Seguridad de la cuenta'),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
            ),
            const SizedBox(height: AppSizes.md),
            _CardContainer(
              child: Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _SecurityTile(
                          icon: Icons.email_outlined,
                          label: _t3(context, ar: 'البريد المرتبط', en: 'Linked Email', es: 'Correo vinculado'),
                          value: _maskEmail(user?.email),
                          actionLabel: _t3(context, ar: 'تحديث', en: 'Update', es: 'Actualizar'),
                          onAction: () => _updateEmail(context, ref),
                        ),
                      ),
                      const SizedBox(width: AppSizes.md),
                      Expanded(
                        child: _SecurityTile(
                          icon: Icons.phone_outlined,
                          label: _t3(context, ar: 'ربط رقم الهاتف', en: 'Link Phone Number', es: 'Vincular teléfono'),
                          value: (profile?.phone?.isNotEmpty ?? false) ? profile!.phone! : '-',
                          actionLabel: _t3(context, ar: 'ربط', en: 'Link', es: 'Vincular'),
                          filled: true,
                          onAction: () => _editPhone(context, ref, profile, user?.id),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSizes.md),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _SecurityTile(
                          icon: Icons.lock_outline,
                          label: _t3(context, ar: 'كلمة المرور', en: 'Password', es: 'Contraseña'),
                          value: _t3(
                            context,
                            ar: 'اضبط كلمة مرور لحماية حسابك',
                            en: 'Set a password to protect your account',
                            es: 'Configura una contraseña para proteger tu cuenta',
                          ),
                          actionLabel: _t3(context, ar: 'ضبط', en: 'Set', es: 'Configurar'),
                          filled: true,
                          onAction: () => _setPassword(context, ref),
                        ),
                      ),
                      const SizedBox(width: AppSizes.md),
                      Expanded(
                        child: _SecurityTile(
                          icon: Icons.devices_outlined,
                          label: _t3(context, ar: 'إدارة الأجهزة', en: 'Manage devices', es: 'Gestionar dispositivos'),
                          value: _t3(
                            context,
                            ar: 'شوف الأجهزة اللي مسجّل دخول فيها',
                            en: "View devices that you're currently signed in",
                            es: 'Ver dispositivos donde has iniciado sesión',
                          ),
                          actionLabel: _t3(context, ar: 'عرض', en: 'View', es: 'Ver'),
                          onAction: () => _comingSoon(context),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSizes.md),
                  _SecurityTile(
                    icon: Icons.history,
                    label: _t3(context, ar: 'سجل الدخول', en: 'Sign-in history', es: 'Historial de acceso'),
                    value: _t3(context, ar: 'شوف سجل دخولك', en: 'View your sign-in history', es: 'Ver tu historial de acceso'),
                    actionLabel: _t3(context, ar: 'عرض', en: 'View', es: 'Ver'),
                    onAction: () => _comingSoon(context),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSizes.lg),
            _CardContainer(
              color: AppColors.primary.withOpacity(0.06),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          _t3(context, ar: 'الملف الشخصي للعضو', en: 'Member Profile', es: 'Perfil de miembro'),
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                        ),
                      ),
                      TextButton(
                        onPressed: () => _editLegalNameAndDob(context, ref, profile, user?.id),
                        child: Text(_t3(context, ar: 'تعديل', en: 'Edit', es: 'Editar')),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _t3(
                      context,
                      ar: 'ضيف اسمك القانوني وتاريخ ميلادك لإكمال ملفك الشخصي. تأكد إن البيانات مطابقة لهويتك للسفر.',
                      en: 'Add your legal name and date of birth to complete your member profile. Please ensure the info matches your travel ID.',
                      es: 'Añade tu nombre legal y fecha de nacimiento. Asegúrate de que coincida con tu identificación de viaje.',
                    ),
                    style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: AppSizes.md),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(AppSizes.md),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.divider),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _t3(context, ar: 'الاسم القانوني', en: 'Legal name', es: 'Nombre legal'),
                          style: const TextStyle(color: AppColors.textSecondary),
                        ),
                        Text((profile?.fullName?.isNotEmpty ?? false) ? profile!.fullName! : '-'),
                        const SizedBox(height: 6),
                        Text(
                          _t3(context, ar: 'تاريخ الميلاد', en: 'Date of birth', es: 'Fecha de nacimiento'),
                          style: const TextStyle(color: AppColors.textSecondary),
                        ),
                        Text(
                              () {
                            final dob = profile?.dateOfBirth;
                            if (dob == null) return '-';
                            return '${dob.year}-${dob.month.toString().padLeft(2, '0')}-${dob.day.toString().padLeft(2, '0')}';
                          }(),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSizes.lg),
            _CardContainer(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          _t3(context, ar: 'المعلومات الشخصية', en: 'Personal info', es: 'Información personal'),
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                        ),
                      ),
                      TextButton(
                        onPressed: () => _editPersonalInfo(context, ref, profile, user?.id),
                        child: Text(_t3(context, ar: 'تعديل', en: 'Edit', es: 'Editar')),
                      ),
                    ],
                  ),
                  Text(
                    _t3(
                      context,
                      ar: 'أدخل معلوماتك الشخصية عشان نصمّم رحلاتك ونطلعك على عروض قريبة منك',
                      en: 'Enter your personal info to help us tailor your trips and discover nearby deals for you',
                      es: 'Ingresa tu información personal para adaptar tus viajes y ofertas cercanas',
                    ),
                    style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: AppSizes.md),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _InfoTile(
                          icon: Icons.wc_outlined,
                          label: _t3(context, ar: 'الجنس', en: 'Gender', es: 'Género'),
                          value: (profile?.gender?.isNotEmpty ?? false) ? profile!.gender! : '-',
                        ),
                      ),
                      const SizedBox(width: AppSizes.md),
                      Expanded(
                        child: _InfoTile(
                          icon: Icons.badge_outlined,
                          label: _t3(context, ar: 'اسم العرض', en: 'Display name', es: 'Nombre visible'),
                          value: (profile?.displayName?.isNotEmpty ?? false) ? profile!.displayName! : '-',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSizes.sm),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _InfoTile(
                          icon: Icons.public,
                          label: _t3(context, ar: 'الجنسية', en: 'Nationality (country or region)', es: 'Nacionalidad'),
                          value: (profile?.nationality?.isNotEmpty ?? false) ? profile!.nationality! : '-',
                        ),
                      ),
                      const SizedBox(width: AppSizes.md),
                      Expanded(
                        child: _InfoTile(
                          icon: Icons.location_city_outlined,
                          label: _t3(context, ar: 'مدينة الإقامة', en: 'City of residence', es: 'Ciudad de residencia'),
                          value: (profile?.cityOfResidence?.isNotEmpty ?? false) ? profile!.cityOfResidence! : '-',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSizes.sm),
                  _InfoTile(
                    icon: Icons.map_outlined,
                    label: _t3(context, ar: 'المدينة الأكثر زيارة', en: 'Frequently visited city', es: 'Ciudad más visitada'),
                    value: (profile?.frequentlyVisitedCity?.isNotEmpty ?? false) ? profile!.frequentlyVisitedCity! : '-',
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSizes.xl),
          ],
        ),
      ),
    );
  }

  Future<void> _updateEmail(BuildContext context, WidgetRef ref) async {
    final controller = TextEditingController(text: user?.email ?? '');
    await showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(_t3(dialogContext, ar: 'تحديث البريد الإلكتروني', en: 'Update email', es: 'Actualizar correo')),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(labelText: 'Email'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(_t3(dialogContext, ar: 'إلغاء', en: 'Cancel', es: 'Cancelar')),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  await Supabase.instance.client.auth.updateUser(
                    UserAttributes(email: controller.text.trim()),
                  );
                  if (!dialogContext.mounted) return;
                  Navigator.of(dialogContext).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        _t3(
                          context,
                          ar: 'اتبعتلك رسالة تأكيد على الإيميل الجديد',
                          en: 'A confirmation email has been sent to the new address',
                          es: 'Se envió un correo de confirmación a la nueva dirección',
                        ),
                      ),
                    ),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    SnackBar(content: Text(e.toString())),
                  );
                }
              },
              child: Text(_t3(dialogContext, ar: 'حفظ', en: 'Save', es: 'Guardar')),
            ),
          ],
        );
      },
    );
  }

  Future<void> _setPassword(BuildContext context, WidgetRef ref) async {
    final controller = TextEditingController();
    await showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(_t3(dialogContext, ar: 'ضبط كلمة مرور', en: 'Set password', es: 'Configurar contraseña')),
          content: TextField(
            controller: controller,
            obscureText: true,
            decoration: const InputDecoration(labelText: 'Password'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(_t3(dialogContext, ar: 'إلغاء', en: 'Cancel', es: 'Cancelar')),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  await Supabase.instance.client.auth.updateUser(
                    UserAttributes(password: controller.text),
                  );
                  if (!dialogContext.mounted) return;
                  Navigator.of(dialogContext).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(_t3(context, ar: 'اتحدثت كلمة المرور', en: 'Password updated', es: 'Contraseña actualizada')),
                    ),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    SnackBar(content: Text(e.toString())),
                  );
                }
              },
              child: Text(_t3(dialogContext, ar: 'حفظ', en: 'Save', es: 'Guardar')),
            ),
          ],
        );
      },
    );
  }

  Future<void> _editPhone(BuildContext context, WidgetRef ref, ProfileModel? profile, String? userId) async {
    final controller = TextEditingController(text: profile?.phone ?? '');
    await showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(_t3(dialogContext, ar: 'ربط رقم الهاتف', en: 'Link phone number', es: 'Vincular teléfono')),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(labelText: '+9665xxxxxxxx'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(_t3(dialogContext, ar: 'إلغاء', en: 'Cancel', es: 'Cancelar')),
            ),
            ElevatedButton(
              onPressed: () async {
                final updated = (profile ?? ProfileModel(id: userId!)).copyWith(phone: controller.text);
                final repo = ref.read(profileRepositoryProvider);
                final result = await repo.upsertMyProfile(updated);
                if (!dialogContext.mounted) return;
                result.when(
                  success: (_) {
                    ref.invalidate(myProfileProvider);
                    Navigator.of(dialogContext).pop();
                  },
                  failure: (message) => ScaffoldMessenger.of(dialogContext).showSnackBar(
                    SnackBar(content: Text(message)),
                  ),
                );
              },
              child: Text(_t3(dialogContext, ar: 'حفظ', en: 'Save', es: 'Guardar')),
            ),
          ],
        );
      },
    );
  }

  Future<void> _editLegalNameAndDob(BuildContext context, WidgetRef ref, ProfileModel? profile, String? userId) async {
    final nameController = TextEditingController(text: profile?.fullName ?? '');
    DateTime? dob = profile?.dateOfBirth;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        return Padding(
          padding: EdgeInsets.only(
            left: AppSizes.lg,
            right: AppSizes.lg,
            top: AppSizes.lg,
            bottom: MediaQuery.of(sheetContext).viewInsets.bottom + AppSizes.lg,
          ),
          child: StatefulBuilder(
            builder: (sheetContext, setSheetState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    _t3(sheetContext, ar: 'الملف الشخصي للعضو', en: 'Member Profile', es: 'Perfil de miembro'),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  const SizedBox(height: AppSizes.md),
                  TextField(
                    controller: nameController,
                    decoration: InputDecoration(
                      labelText: _t3(sheetContext, ar: 'الاسم القانوني', en: 'Legal name', es: 'Nombre legal'),
                    ),
                  ),
                  const SizedBox(height: AppSizes.sm),
                  GestureDetector(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: sheetContext,
                        firstDate: DateTime(1920),
                        lastDate: DateTime.now(),
                        initialDate: dob ?? DateTime(1990, 1, 1),
                      );
                      if (picked != null) setSheetState(() => dob = picked);
                    },
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: _t3(sheetContext, ar: 'تاريخ الميلاد', en: 'Date of birth', es: 'Fecha de nacimiento'),
                      ),
                      child: Text(
                        dob == null
                            ? _t3(sheetContext, ar: 'اختار تاريخ', en: 'Select a date', es: 'Elige una fecha')
                            : '${dob!.year}-${dob!.month.toString().padLeft(2, '0')}-${dob!.day.toString().padLeft(2, '0')}',
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSizes.md),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        final updated = (profile ?? ProfileModel(id: userId!)).copyWith(
                          fullName: nameController.text,
                          dateOfBirth: dob,
                        );
                        final repo = ref.read(profileRepositoryProvider);
                        final result = await repo.upsertMyProfile(updated);
                        if (!sheetContext.mounted) return;
                        result.when(
                          success: (_) {
                            ref.invalidate(myProfileProvider);
                            Navigator.of(sheetContext).pop();
                          },
                          failure: (message) => ScaffoldMessenger.of(sheetContext).showSnackBar(
                            SnackBar(content: Text(message)),
                          ),
                        );
                      },
                      child: Text(_t3(sheetContext, ar: 'حفظ', en: 'Save', es: 'Guardar')),
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  Future<void> _editPersonalInfo(BuildContext context, WidgetRef ref, ProfileModel? profile, String? userId) async {
    final genderController = TextEditingController(text: profile?.gender ?? '');
    final displayNameController = TextEditingController(text: profile?.displayName ?? '');
    final nationalityController = TextEditingController(text: profile?.nationality ?? '');
    final cityController = TextEditingController(text: profile?.cityOfResidence ?? '');
    final frequentCityController = TextEditingController(text: profile?.frequentlyVisitedCity ?? '');

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        return Padding(
          padding: EdgeInsets.only(
            left: AppSizes.lg,
            right: AppSizes.lg,
            top: AppSizes.lg,
            bottom: MediaQuery.of(sheetContext).viewInsets.bottom + AppSizes.lg,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  _t3(sheetContext, ar: 'المعلومات الشخصية', en: 'Personal info', es: 'Información personal'),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                const SizedBox(height: AppSizes.md),
                TextField(
                  controller: genderController,
                  decoration: InputDecoration(labelText: _t3(sheetContext, ar: 'الجنس', en: 'Gender', es: 'Género')),
                ),
                const SizedBox(height: AppSizes.sm),
                TextField(
                  controller: displayNameController,
                  decoration: InputDecoration(labelText: _t3(sheetContext, ar: 'اسم العرض', en: 'Display name', es: 'Nombre visible')),
                ),
                const SizedBox(height: AppSizes.sm),
                TextField(
                  controller: nationalityController,
                  decoration: InputDecoration(
                    labelText: _t3(sheetContext, ar: 'الجنسية', en: 'Nationality (country or region)', es: 'Nacionalidad'),
                  ),
                ),
                const SizedBox(height: AppSizes.sm),
                TextField(
                  controller: cityController,
                  decoration: InputDecoration(labelText: _t3(sheetContext, ar: 'مدينة الإقامة', en: 'City of residence', es: 'Ciudad de residencia')),
                ),
                const SizedBox(height: AppSizes.sm),
                TextField(
                  controller: frequentCityController,
                  decoration: InputDecoration(
                    labelText: _t3(sheetContext, ar: 'المدينة الأكثر زيارة', en: 'Frequently visited city', es: 'Ciudad más visitada'),
                  ),
                ),
                const SizedBox(height: AppSizes.md),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      final updated = (profile ?? ProfileModel(id: userId!)).copyWith(
                        gender: genderController.text,
                        displayName: displayNameController.text,
                        nationality: nationalityController.text,
                        cityOfResidence: cityController.text,
                        frequentlyVisitedCity: frequentCityController.text,
                      );
                      final repo = ref.read(profileRepositoryProvider);
                      final result = await repo.upsertMyProfile(updated);
                      if (!sheetContext.mounted) return;
                      result.when(
                        success: (_) {
                          ref.invalidate(myProfileProvider);
                          Navigator.of(sheetContext).pop();
                        },
                        failure: (message) => ScaffoldMessenger.of(sheetContext).showSnackBar(
                          SnackBar(content: Text(message)),
                        ),
                      );
                    },
                    child: Text(_t3(sheetContext, ar: 'حفظ', en: 'Save', es: 'Guardar')),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _CardContainer extends StatelessWidget {
  final Widget child;
  final Color? color;
  const _CardContainer({required this.child, this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSizes.md),
      decoration: BoxDecoration(
        color: color ?? Colors.white,
        border: Border.all(color: AppColors.divider),
        borderRadius: BorderRadius.circular(16),
      ),
      child: child,
    );
  }
}

class _SecurityTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String actionLabel;
  final VoidCallback onAction;
  final bool filled;

  const _SecurityTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.actionLabel,
    required this.onAction,
    this.filled = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.md),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(icon, size: 16, color: AppColors.textSecondary),
                    const SizedBox(width: 6),
                    Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                  ],
                ),
                const SizedBox(height: 4),
                Text(value, style: const TextStyle(fontWeight: FontWeight.w600), maxLines: 2, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: filled
                ? ElevatedButton(onPressed: onAction, child: Text(actionLabel))
                : TextButton(onPressed: onAction, child: Text(actionLabel)),
          ),
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoTile({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.md),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: AppColors.textSecondary),
              const SizedBox(width: 6),
              Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}