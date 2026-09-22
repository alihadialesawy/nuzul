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
import '../../data/models/traveler_model.dart';
import '../auth/controllers/auth_controller.dart';
import 'controllers/profile_controller.dart';
import 'controllers/traveler_controller.dart';

/// يختار النص المناسب حسب اللغة الحالية (عربي/إنجليزي/إسباني/تركي/إندونيسي/هندي/أوردو/فرنسي/بنغالي).
String _t3(
    BuildContext context, {
      required String ar,
      required String en,
      required String es,
      required String tr,
      required String id,
      required String hi,
      required String ur,
      required String fr,
      required String bn,
    }) {
  switch (Localizations.localeOf(context).languageCode) {
    case 'ar':
      return ar;
    case 'es':
      return es;
    case 'tr':
      return tr;
    case 'id':
      return id;
    case 'hi':
      return hi;
    case 'ur':
      return ur;
    case 'fr':
      return fr;
    case 'bn':
      return bn;
    default:
      return en;
  }
}

void _comingSoon(BuildContext context) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(_t3(context, ar: 'قريبًا', en: 'Coming soon', es: 'Próximamente', tr: 'Yakında',
          id: 'Segera hadir',
          hi: 'जल्द आ रहा है',
          ur: 'جلد آ رہا ہے',
          fr: 'Bientôt disponible',
          bn: 'শীঘ্রই আসছে')),
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

/// يحوّل قيمة الجنس المخزّنة ('m'/'f') إلى نص مترجم للعرض — بدل عرض
/// الحرف الخام أو أي نص حر كان مكتوبًا يدويًا بالحقل القديم.
String _genderLabel(BuildContext context, String? code) {
  if (code == 'f') {
    return _t3(context, ar: 'أنثى', en: 'Female', es: 'Mujer', tr: 'Kadın',
        id: 'Perempuan',
        hi: 'महिला',
        ur: 'عورت',
        fr: 'Femme',
        bn: 'নারী');
  }
  if (code == 'm') {
    return _t3(context, ar: 'ذكر', en: 'Male', es: 'Hombre', tr: 'Erkek',
        id: 'Laki-laki',
        hi: 'पुरुष',
        ur: 'مرد',
        fr: 'Homme',
        bn: 'পুরুষ');
  }
  return '-';
}

/// ألوان مميزة لكل حقل/قسم في شاشة الحساب، عشان الحقول تتفرّق عن بعضها
/// بصريًا بسرعة بدل ما تكون كلها بنفس اللون الرمادي الموحّد.
class _FieldColors {
  static const email = Color(0xFF2E7DD1);
  static const phone = Color(0xFF2FA36B);
  static const password = Color(0xFFE07B39);
  static const devices = Color(0xFF8A5CD6);
  static const signInHistory = Color(0xFF4C5FD5);

  static const gender = Color(0xFFD6558E);
  static const displayName = Color(0xFF1CA7C4);
  static const nationality = Color(0xFF1C9C82);
  static const cityOfResidence = Color(0xFFD6773A);
  static const frequentCity = Color(0xFF3B8FD6);

  static const passportNumber = Color(0xFFB8860B);
  static const passportCountry = Color(0xFF8B5E3C);
  static const passportExpiry = Color(0xFFC0392B);

  static const travelerName = Color(0xFF1CA7C4);
  static const travelerDob = Color(0xFFC0392B);
}

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  Future<void> _logout(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(_t3(dialogContext, ar: 'تسجيل الخروج', en: 'Sign out', es: 'Cerrar sesión', tr: 'Çıkış yap',
            id: 'Keluar',
            hi: 'साइन आउट करें',
            ur: 'سائن آؤٹ کریں',
            fr: 'Se déconnecter',
            bn: 'সাইন আউট করুন')),
        content: Text(
          _t3(
            dialogContext,
            ar: 'هل أنت متأكد أنك تريد تسجيل الخروج؟',
            en: 'Are you sure you want to sign out?',
            es: '¿Seguro que quieres cerrar sesión?',
            tr: 'Çıkış yapmak istediğinizden emin misiniz?',
            id: 'Apakah Anda yakin ingin keluar?',
            hi: 'क्या आप वाकई साइन आउट करना चाहते हैं?',
            ur: 'کیا آپ واقعی سائن آؤٹ کرنا چاہتے ہیں؟',
            fr: 'Êtes-vous sûr de vouloir vous déconnecter ?',
            bn: 'আপনি কি নিশ্চিত যে সাইন আউট করতে চান?',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(_t3(dialogContext, ar: 'إلغاء', en: 'Cancel', es: 'Cancelar', tr: 'İptal',
                id: 'Batal',
                hi: 'रद्द करें',
                ur: 'منسوخ کریں',
                fr: 'Annuler',
                bn: 'বাতিল করুন')),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(_t3(dialogContext, ar: 'تسجيل الخروج', en: 'Sign out', es: 'Cerrar sesión', tr: 'Çıkış yap',
                id: 'Keluar',
                hi: 'साइन आउट करें',
                ur: 'سائن آؤٹ کریں',
                fr: 'Se déconnecter',
                bn: 'সাইন আউট করুন')),
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

  /// يفتح فورم إضافة مسافر جديد (اسم، تاريخ ميلاد، بيانات جواز سفر)
  /// وبيحفظه في جدول travelers لاستخدامه لاحقًا وقت الحجز.
  Future<void> _addTraveler(BuildContext context, WidgetRef ref) async {
    final nameController = TextEditingController();
    final passportNumberController = TextEditingController();
    final issuingCountryController = TextEditingController();
    DateTime? dob;
    DateTime? passportExpiry;

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
              return SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      _t3(sheetContext, ar: 'إضافة مسافر', en: 'Add traveler', es: 'Añadir viajero', tr: 'Yolcu ekle',
                          id: 'Tambah wisatawan',
                          hi: 'यात्री जोड़ें',
                          ur: 'مسافر شامل کریں',
                          fr: 'Ajouter un voyageur',
                          bn: 'ভ্রমণকারী যোগ করুন'),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _t3(
                        sheetContext,
                        ar: 'أضف بيانات مسافر لاستخدامها تلقائيًا في حجوزاتك القادمة',
                        en: "Add a traveler's details to use them automatically in your future bookings",
                        es: 'Añade los datos de un viajero para usarlos en tus próximas reservas',
                        tr: 'Gelecekteki rezervasyonlarınızda otomatik kullanmak için bir yolcunun bilgilerini ekleyin',
                        id: 'Tambahkan detail wisatawan untuk digunakan otomatis di pemesanan Anda berikutnya',
                        hi: 'भविष्य की बुकिंग में स्वचालित रूप से उपयोग के लिए यात्री का विवरण जोड़ें',
                        ur: 'اپنی آئندہ بکنگز میں خودکار استعمال کے لیے مسافر کی تفصیلات شامل کریں',
                        fr: 'Ajoutez les informations d\'un voyageur pour les utiliser automatiquement lors de vos prochaines réservations',
                        bn: 'আপনার ভবিষ্যত বুকিংয়ে স্বয়ংক্রিয়ভাবে ব্যবহারের জন্য একজন ভ্রমণকারীর বিবরণ যোগ করুন',
                      ),
                      style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: AppSizes.md),
                    TextField(
                      controller: nameController,
                      decoration: InputDecoration(
                        labelText: _t3(sheetContext, ar: 'الاسم الكامل', en: 'Full name', es: 'Nombre completo', tr: 'Ad Soyad',
                            id: 'Nama lengkap',
                            hi: 'पूरा नाम',
                            ur: 'پورا نام',
                            fr: 'Nom complet',
                            bn: 'পূর্ণ নাম'),
                        prefixIcon: const Icon(Icons.badge_outlined, color: _FieldColors.travelerName),
                        focusedBorder: OutlineInputBorder(
                          borderSide: const BorderSide(color: _FieldColors.travelerName, width: 2),
                          borderRadius: BorderRadius.circular(10),
                        ),
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
                          labelText: _t3(sheetContext, ar: 'تاريخ الميلاد', en: 'Date of birth', es: 'Fecha de nacimiento', tr: 'Doğum tarihi',
                              id: 'Tanggal lahir',
                              hi: 'जन्म तिथि',
                              ur: 'تاریخ پیدائش',
                              fr: 'Date de naissance',
                              bn: 'জন্ম তারিখ'),
                          prefixIcon: const Icon(Icons.calendar_today_outlined, color: _FieldColors.travelerDob),
                        ),
                        child: Text(
                          dob == null
                              ? _t3(sheetContext, ar: 'اختر تاريخ', en: 'Select a date', es: 'Elige una fecha', tr: 'Bir tarih seçin',
                              id: 'Pilih tanggal',
                              hi: 'एक तारीख चुनें',
                              ur: 'ایک تاریخ منتخب کریں',
                              fr: 'Choisir une date',
                              bn: 'একটি তারিখ নির্বাচন করুন')
                              : '${dob!.year}-${dob!.month.toString().padLeft(2, '0')}-${dob!.day.toString().padLeft(2, '0')}',
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSizes.sm),
                    TextField(
                      controller: passportNumberController,
                      decoration: InputDecoration(
                        labelText: _t3(sheetContext, ar: 'رقم جواز السفر', en: 'Passport number', es: 'Número de pasaporte', tr: 'Pasaport numarası',
                            id: 'Nomor paspor',
                            hi: 'पासपोर्ट नंबर',
                            ur: 'پاسپورٹ نمبر',
                            fr: 'Numéro de passeport',
                            bn: 'পাসপোর্ট নম্বর'),
                        prefixIcon: const Icon(Icons.badge_outlined, color: _FieldColors.passportNumber),
                        focusedBorder: OutlineInputBorder(
                          borderSide: const BorderSide(color: _FieldColors.passportNumber, width: 2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSizes.sm),
                    TextField(
                      controller: issuingCountryController,
                      decoration: InputDecoration(
                        labelText: _t3(sheetContext, ar: 'دولة الإصدار', en: 'Issuing country', es: 'País emisor', tr: 'Veren ülke',
                            id: 'Negara penerbit',
                            hi: 'जारीकर्ता देश',
                            ur: 'اجراء کرنے والا ملک',
                            fr: 'Pays de délivrance',
                            bn: 'ইস্যুকারী দেশ'),
                        prefixIcon: const Icon(Icons.public, color: _FieldColors.passportCountry),
                        focusedBorder: OutlineInputBorder(
                          borderSide: const BorderSide(color: _FieldColors.passportCountry, width: 2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSizes.sm),
                    GestureDetector(
                      onTap: () async {
                        final now = DateTime.now();
                        final picked = await showDatePicker(
                          context: sheetContext,
                          firstDate: now,
                          lastDate: DateTime(now.year + 20),
                          initialDate: passportExpiry ?? now.add(const Duration(days: 365)),
                        );
                        if (picked != null) setSheetState(() => passportExpiry = picked);
                      },
                      child: InputDecorator(
                        decoration: InputDecoration(
                          labelText: _t3(sheetContext, ar: 'تاريخ انتهاء الجواز', en: 'Passport expiry', es: 'Vencimiento del pasaporte', tr: 'Pasaport son geçerlilik tarihi',
                              id: 'Kedaluwarsa paspor',
                              hi: 'पासपोर्ट समाप्ति तिथि',
                              ur: 'پاسپورٹ کی میعاد ختم ہونے کی تاریخ',
                              fr: 'Expiration du passeport',
                              bn: 'পাসপোর্ট মেয়াদ শেষ হওয়ার তারিখ'),
                          prefixIcon: const Icon(Icons.event_outlined, color: _FieldColors.passportExpiry),
                        ),
                        child: Text(
                          passportExpiry == null
                              ? _t3(sheetContext, ar: 'اختر تاريخ', en: 'Select a date', es: 'Elige una fecha', tr: 'Bir tarih seçin',
                              id: 'Pilih tanggal',
                              hi: 'एक तारीख चुनें',
                              ur: 'ایک تاریخ منتخب کریں',
                              fr: 'Choisir une date',
                              bn: 'একটি তারিখ নির্বাচন করুন')
                              : '${passportExpiry!.year}-${passportExpiry!.month.toString().padLeft(2, '0')}-${passportExpiry!.day.toString().padLeft(2, '0')}',
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSizes.md),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () async {
                          final name = nameController.text.trim();
                          if (name.isEmpty) {
                            ScaffoldMessenger.of(sheetContext).showSnackBar(
                              SnackBar(
                                content: Text(
                                  _t3(sheetContext, ar: 'من فضلك أدخل اسم المسافر', en: "Please enter the traveler's name", es: 'Introduce el nombre del viajero', tr: 'Lütfen yolcunun adını girin',
                                      id: 'Silakan masukkan nama wisatawan',
                                      hi: 'कृपया यात्री का नाम दर्ज करें',
                                      ur: 'براہ کرم مسافر کا نام درج کریں',
                                      fr: 'Veuillez saisir le nom du voyageur',
                                      bn: 'অনুগ্রহ করে ভ্রমণকারীর নাম লিখুন'),
                                ),
                              ),
                            );
                            return;
                          }
                          final traveler = TravelerModel(
                            id: '',
                            fullName: name,
                            dateOfBirth: dob,
                            passportNumber: passportNumberController.text.trim().isEmpty
                                ? null
                                : passportNumberController.text.trim(),
                            passportIssuingCountry: issuingCountryController.text.trim().isEmpty
                                ? null
                                : issuingCountryController.text.trim(),
                            passportExpiry: passportExpiry,
                          );
                          final repo = ref.read(travelerRepositoryProvider);
                          final result = await repo.addTraveler(traveler);
                          if (!sheetContext.mounted) return;
                          result.when(
                            success: (_) {
                              ref.invalidate(myTravelersProvider);
                              Navigator.of(sheetContext).pop();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    _t3(context, ar: 'تم حفظ المسافر بنجاح', en: 'Traveler saved successfully', es: 'Viajero guardado con éxito', tr: 'Yolcu başarıyla kaydedildi',
                                        id: 'Wisatawan berhasil disimpan',
                                        hi: 'यात्री सफलतापूर्वक सहेजा गया',
                                        ur: 'مسافر کامیابی سے محفوظ ہو گیا',
                                        fr: 'Voyageur enregistré avec succès',
                                        bn: 'ভ্রমণকারী সফলভাবে সংরক্ষিত হয়েছে'),
                                  ),
                                ),
                              );
                            },
                            failure: (message) => ScaffoldMessenger.of(sheetContext).showSnackBar(
                              SnackBar(content: Text(message)),
                            ),
                          );
                        },
                        child: Text(_t3(sheetContext, ar: 'حفظ', en: 'Save', es: 'Guardar', tr: 'Kaydet',
                            id: 'Simpan',
                            hi: 'सहेजें',
                            ur: 'محفوظ کریں',
                            fr: 'Enregistrer',
                            bn: 'সংরক্ষণ করুন')),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(myProfileProvider);
    final user = ref.watch(currentUserProvider);

    final title = Text(_t3(context, ar: 'حسابي', en: 'My Account', es: 'Mi cuenta', tr: 'Hesabım',
        id: 'Akun Saya',
        hi: 'मेरा खाता',
        ur: 'میرا اکاؤنٹ',
        fr: 'Mon compte',
        bn: 'আমার অ্যাকাউন্ট'));

    final sidebar = _ProfileSidebar(
      displayName: user?.email?.split('@').first ?? '',
      onLogout: () => _logout(context, ref),
      onAddTraveler: () => _addTraveler(context, ref),
    );

    final mainContent = profileAsync.when(
      loading: () => LoadingView(
        message: _t3(context, ar: 'يحمّل بيانات حسابك...', en: 'Loading your account...', es: 'Cargando tu cuenta...', tr: 'Hesabınız yükleniyor...',
            id: 'Memuat akun Anda...',
            hi: 'आपका खाता लोड हो रहा है...',
            ur: 'آپ کا اکاؤنٹ لوڈ ہو رہا ہے...',
            fr: 'Chargement de votre compte...',
            bn: 'আপনার অ্যাকাউন্ট লোড হচ্ছে...'),
      ),
      error: (error, _) => ErrorView(
        message: _t3(
          context,
          ar: 'تعذر تحميل بيانات الحساب',
          en: 'Could not load account data',
          es: 'No se pudieron cargar los datos',
          tr: 'Hesap bilgileri yüklenemedi',
          id: 'Gagal memuat data akun',
          hi: 'खाते का डेटा लोड नहीं हो सका',
          ur: 'اکاؤنٹ کا ڈیٹا لوڈ نہیں ہو سکا',
          fr: 'Impossible de charger les données du compte',
          bn: 'অ্যাকাউন্ট ডেটা লোড করা যায়নি',
        ),
        onRetry: () => ref.invalidate(myProfileProvider),
      ),
      data: (profile) => _ProfileMainContent(profile: profile, user: user),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        const wideBreakpoint = 700.0;
        final isWide = constraints.maxWidth >= wideBreakpoint;

        if (isWide) {
          return Scaffold(
            appBar: AppBar(title: title),
            body: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                sidebar,
                const VerticalDivider(width: 1),
                Expanded(child: mainContent),
              ],
            ),
          );
        }

        return Scaffold(
          appBar: AppBar(title: title),
          drawer: Drawer(child: SafeArea(child: sidebar)),
          body: mainContent,
        );
      },
    );
  }
}

class _ProfileSidebar extends StatelessWidget {
  final String displayName;
  final VoidCallback onLogout;
  final VoidCallback onAddTraveler;
  const _ProfileSidebar({
    required this.displayName,
    required this.onLogout,
    required this.onAddTraveler,
  });

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
                        ? _t3(context, ar: 'عضو', en: 'Member', es: 'Miembro', tr: 'Üye',
                        id: 'Anggota',
                        hi: 'सदस्य',
                        ur: 'ممبر',
                        fr: 'Membre',
                        bn: 'সদস্য')
                        : displayName,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSizes.md),
            _SidebarSectionHeader(_t3(context, ar: 'حجوزاتي', en: 'My bookings', es: 'Mis reservas', tr: 'Rezervasyonlarım',
                id: 'Pesanan saya',
                hi: 'मेरी बुकिंग',
                ur: 'میری بکنگز',
                fr: 'Mes réservations',
                bn: 'আমার বুকিং')),
            _SidebarItem(label: _t3(context, ar: 'الكل', en: 'All', es: 'Todo', tr: 'Tümü',
                id: 'Semua',
                hi: 'सभी',
                ur: 'تمام',
                fr: 'Tout',
                bn: 'সব'), onTap: () => context.push(AppRoutes.myBookings)),
            _SidebarItem(label: _t3(context, ar: 'الطيران', en: 'Flights', es: 'Vuelos', tr: 'Uçuşlar',
                id: 'Penerbangan',
                hi: 'उड़ानें',
                ur: 'پروازیں',
                fr: 'Vols',
                bn: 'ফ্লাইট'), onTap: () => context.push(AppRoutes.myBookings)),
            _SidebarItem(label: _t3(context, ar: 'الفنادق', en: 'Hotels', es: 'Hoteles', tr: 'Oteller',
                id: 'Hotel',
                hi: 'होटल',
                ur: 'ہوٹلز',
                fr: 'Hôtels',
                bn: 'হোটেল'), onTap: () => context.push(AppRoutes.myBookings)),
            _SidebarItem(label: _t3(context, ar: 'طيران + فندق', en: 'Flight + Hotel', es: 'Vuelo + Hotel', tr: 'Uçuş + Otel',
                id: 'Penerbangan + Hotel',
                hi: 'उड़ान + होटल',
                ur: 'پرواز + ہوٹل',
                fr: 'Vol + Hôtel',
                bn: 'ফ্লাইট + হোটেল'), onTap: () => context.push(AppRoutes.home)),
            const SizedBox(height: AppSizes.sm),
            _SidebarItem(label: _t3(context, ar: 'المحفوظات', en: 'Saved', es: 'Guardado', tr: 'Kaydedilenler',
                id: 'Tersimpan',
                hi: 'सहेजा गया',
                ur: 'محفوظ شدہ',
                fr: 'Enregistré',
                bn: 'সংরক্ষিত'), bold: true, onTap: () => _comingSoon(context)),
            _SidebarItem(label: _t3(context, ar: 'منشوراتي', en: 'My posts', es: 'Mis publicaciones', tr: 'Gönderilerim',
                id: 'Postingan saya',
                hi: 'मेरी पोस्ट',
                ur: 'میری پوسٹس',
                fr: 'Mes publications',
                bn: 'আমার পোস্ট'), bold: true, onTap: () => _comingSoon(context)),
            _SidebarItem(
              label: _t3(context, ar: 'تنبيهات الأسعار', en: 'Price alerts', es: 'Alertas de precio', tr: 'Fiyat uyarıları',
                  id: 'Peringatan harga',
                  hi: 'मूल्य अलर्ट',
                  ur: 'قیمت الرٹس',
                  fr: 'Alertes de prix',
                  bn: 'মূল্য সতর্কতা'),
              bold: true,
              onTap: () => context.push(AppRoutes.aiTravel),
            ),
            _SidebarItem(
              label: _t3(context, ar: 'عملاتي', en: 'My Coins', es: 'Mis monedas', tr: 'Puanlarım',
                  id: 'Koin Saya',
                  hi: 'मेरे कॉइन',
                  ur: 'میرے کوائنز',
                  fr: 'Mes points',
                  bn: 'আমার কয়েন'),
              bold: true,
              onTap: () => context.push(AppRoutes.myCoins),
            ),
            const SizedBox(height: AppSizes.sm),
            _SidebarSectionHeader(_t3(context, ar: 'الحساب', en: 'Account', es: 'Cuenta', tr: 'Hesap',
                id: 'Akun',
                hi: 'खाता',
                ur: 'اکاؤنٹ',
                fr: 'Compte',
                bn: 'অ্যাকাউন্ট')),
            _SidebarItem(
              label: _t3(context, ar: 'الملف الشخصي', en: 'Profile', es: 'Perfil', tr: 'Profil',
                  id: 'Profil',
                  hi: 'प्रोफ़ाइल',
                  ur: 'پروفائل',
                  fr: 'Profil',
                  bn: 'প্রোফাইল'),
              selected: true,
              onTap: () {},
            ),
            _SidebarItem(label: _t3(context, ar: 'بيانات المسافر المتكرر', en: 'Frequent traveler info', es: 'Viajero frecuente', tr: 'Sık seyahat eden bilgileri',
                id: 'Info wisatawan tetap',
                hi: 'बार-बार यात्रा करने वाले की जानकारी',
                ur: 'بار بار سفر کرنے والے کی معلومات',
                fr: 'Informations voyageur fréquent',
                bn: 'ঘন ঘন ভ্রমণকারীর তথ্য'), onTap: () => _comingSoon(context)),
            _SidebarItem(
              label: _t3(context, ar: 'إضافة مسافرين', en: 'Add Travelers', es: 'Añadir viajeros', tr: 'Yolcu ekle',
                  id: 'Tambah wisatawan',
                  hi: 'यात्री जोड़ें',
                  ur: 'مسافر شامل کریں',
                  fr: 'Ajouter des voyageurs',
                  bn: 'ভ্রমণকারী যোগ করুন'),
              onTap: onAddTraveler,
            ),
            _SidebarItem(label: _t3(context, ar: 'بيانات الاتصال', en: 'Contact info', es: 'Información de contacto', tr: 'İletişim bilgileri',
                id: 'Info kontak',
                hi: 'संपर्क जानकारी',
                ur: 'رابطہ کی معلومات',
                fr: 'Coordonnées',
                bn: 'যোগাযোগের তথ্য'), onTap: () => _comingSoon(context)),
            _SidebarItem(label: _t3(context, ar: 'خيارات الفواتير', en: 'Receipt & invoice options', es: 'Opciones de factura', tr: 'Fatura seçenekleri',
                id: 'Opsi struk & faktur',
                hi: 'रसीद और चालान विकल्प',
                ur: 'رسید اور انوائس کے اختیارات',
                fr: 'Options de reçu et facture',
                bn: 'রসিদ ও চালান বিকল্প'), onTap: () => _comingSoon(context)),
            _SidebarItem(label: _t3(context, ar: 'الاشتراكات', en: 'Subscriptions', es: 'Suscripciones', tr: 'Abonelikler',
                id: 'Langganan',
                hi: 'सदस्यताएं',
                ur: 'سبسکرپشنز',
                fr: 'Abonnements',
                bn: 'সাবস্ক্রিপশন'), onTap: () => _comingSoon(context)),
            const Divider(height: AppSizes.lg),
            _SidebarItem(
              label: _t3(context, ar: 'تسجيل الخروج', en: 'Sign out', es: 'Cerrar sesión', tr: 'Çıkış yap',
                  id: 'Keluar',
                  hi: 'साइन आउट करें',
                  ur: 'سائن آؤٹ کریں',
                  fr: 'Se déconnecter',
                  bn: 'সাইন আউট করুন'),
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
      onTap: () {
        final scaffold = Scaffold.maybeOf(context);
        if (scaffold != null && scaffold.isDrawerOpen) {
          Navigator.of(context).pop();
        }
        onTap();
      },
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

class _ProfileMainContent extends ConsumerWidget {
  final ProfileModel? profile;
  final User? user;

  const _ProfileMainContent({required this.profile, required this.user});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 420;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(AppSizes.lg),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _t3(context, ar: 'أمان الحساب', en: 'Account Security', es: 'Seguridad de la cuenta', tr: 'Hesap güvenliği',
                      id: 'Keamanan akun',
                      hi: 'खाता सुरक्षा',
                      ur: 'اکاؤنٹ سیکیورٹی',
                      fr: 'Sécurité du compte',
                      bn: 'অ্যাকাউন্ট নিরাপত্তা'),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                ),
                const SizedBox(height: AppSizes.md),
                _CardContainer(
                  child: Column(
                    children: [
                      _ResponsiveTilePair(
                        isNarrow: isNarrow,
                        first: _SecurityTile(
                          icon: Icons.email_outlined,
                          color: _FieldColors.email,
                          label: _t3(context, ar: 'البريد المرتبط', en: 'Linked Email', es: 'Correo vinculado', tr: 'Bağlı e-posta',
                              id: 'Email tertaut',
                              hi: 'जुड़ा हुआ ईमेल',
                              ur: 'منسلک ای میل',
                              fr: 'E-mail lié',
                              bn: 'সংযুক্ত ইমেইল'),
                          value: _maskEmail(user?.email),
                          actionLabel: _t3(context, ar: 'تحديث', en: 'Update', es: 'Actualizar', tr: 'Güncelle',
                              id: 'Perbarui',
                              hi: 'अपडेट करें',
                              ur: 'اپ ڈیٹ کریں',
                              fr: 'Mettre à jour',
                              bn: 'আপডেট করুন'),
                          onAction: () => _updateEmail(context, ref),
                        ),
                        second: _SecurityTile(
                          icon: Icons.phone_outlined,
                          color: _FieldColors.phone,
                          label: _t3(context, ar: 'ربط رقم الهاتف', en: 'Link Phone Number', es: 'Vincular teléfono', tr: 'Telefon numarasını bağla',
                              id: 'Tautkan nomor telepon',
                              hi: 'फ़ोन नंबर लिंक करें',
                              ur: 'فون نمبر لنک کریں',
                              fr: 'Lier un numéro de téléphone',
                              bn: 'ফোন নম্বর লিঙ্ক করুন'),
                          value: (profile?.phone?.isNotEmpty ?? false) ? profile!.phone! : '-',
                          actionLabel: _t3(context, ar: 'ربط', en: 'Link', es: 'Vincular', tr: 'Bağla',
                              id: 'Tautkan',
                              hi: 'लिंक करें',
                              ur: 'لنک کریں',
                              fr: 'Lier',
                              bn: 'লিঙ্ক করুন'),
                          filled: true,
                          onAction: () => _editPhone(context, ref, profile, user?.id),
                        ),
                      ),
                      const SizedBox(height: AppSizes.md),
                      _ResponsiveTilePair(
                        isNarrow: isNarrow,
                        first: _SecurityTile(
                          icon: Icons.lock_outline,
                          color: _FieldColors.password,
                          label: _t3(context, ar: 'كلمة المرور', en: 'Password', es: 'Contraseña', tr: 'Şifre',
                              id: 'Kata sandi',
                              hi: 'पासवर्ड',
                              ur: 'پاس ورڈ',
                              fr: 'Mot de passe',
                              bn: 'পাসওয়ার্ড'),
                          value: _t3(
                            context,
                            ar: 'اضبط كلمة مرور لحماية حسابك',
                            en: 'Set a password to protect your account',
                            es: 'Configura una contraseña para proteger tu cuenta',
                            tr: 'Hesabınızı korumak için bir şifre belirleyin',
                            id: 'Atur kata sandi untuk melindungi akun Anda',
                            hi: 'अपने खाते की सुरक्षा के लिए पासवर्ड सेट करें',
                            ur: 'اپنے اکاؤنٹ کی حفاظت کے لیے پاس ورڈ سیٹ کریں',
                            fr: 'Définissez un mot de passe pour protéger votre compte',
                            bn: 'আপনার অ্যাকাউন্ট সুরক্ষিত করতে একটি পাসওয়ার্ড সেট করুন',
                          ),
                          actionLabel: _t3(context, ar: 'ضبط', en: 'Set', es: 'Configurar', tr: 'Ayarla',
                              id: 'Atur',
                              hi: 'सेट करें',
                              ur: 'سیٹ کریں',
                              fr: 'Définir',
                              bn: 'সেট করুন'),
                          filled: true,
                          onAction: () => _setPassword(context, ref),
                        ),
                        second: _SecurityTile(
                          icon: Icons.devices_outlined,
                          color: _FieldColors.devices,
                          label: _t3(context, ar: 'إدارة الأجهزة', en: 'Manage devices', es: 'Gestionar dispositivos', tr: 'Cihazları yönet',
                              id: 'Kelola perangkat',
                              hi: 'डिवाइस प्रबंधित करें',
                              ur: 'ڈیوائسز کا انتظام کریں',
                              fr: 'Gérer les appareils',
                              bn: 'ডিভাইস পরিচালনা করুন'),
                          value: _t3(
                            context,
                            ar: 'اطّلع على الأجهزة التي سجّلت الدخول منها',
                            en: "View devices that you're currently signed in",
                            es: 'Ver dispositivos donde has iniciado sesión',
                            tr: 'Oturum açtığınız cihazları görüntüleyin',
                            id: 'Lihat perangkat yang sedang Anda gunakan untuk masuk',
                            hi: 'उन डिवाइसों को देखें जिनमें आप वर्तमान में साइन इन हैं',
                            ur: 'وہ ڈیوائسز دیکھیں جن میں آپ اس وقت سائن ان ہیں',
                            fr: 'Voir les appareils actuellement connectés',
                            bn: 'আপনি বর্তমানে যেসব ডিভাইসে সাইন ইন আছেন তা দেখুন',
                          ),
                          actionLabel: _t3(context, ar: 'عرض', en: 'View', es: 'Ver', tr: 'Görüntüle',
                              id: 'Lihat',
                              hi: 'देखें',
                              ur: 'دیکھیں',
                              fr: 'Voir',
                              bn: 'দেখুন'),
                          onAction: () => _signOutOtherDevices(context, ref),
                        ),
                      ),
                      const SizedBox(height: AppSizes.md),
                      _SecurityTile(
                        icon: Icons.history,
                        color: _FieldColors.signInHistory,
                        label: _t3(context, ar: 'سجل الدخول', en: 'Sign-in history', es: 'Historial de acceso', tr: 'Oturum açma geçmişi',
                            id: 'Riwayat masuk',
                            hi: 'साइन-इन इतिहास',
                            ur: 'سائن ان کی تاریخ',
                            fr: 'Historique de connexion',
                            bn: 'সাইন-ইন ইতিহাস'),
                        value: _t3(context, ar: 'اطّلع على سجل تسجيل الدخول الخاص بك', en: 'View your sign-in history', es: 'Ver tu historial de acceso', tr: 'Oturum açma geçmişinizi görüntüleyin',
                            id: 'Lihat riwayat masuk Anda',
                            hi: 'अपना साइन-इन इतिहास देखें',
                            ur: 'اپنی سائن ان کی تاریخ دیکھیں',
                            fr: 'Consultez votre historique de connexion',
                            bn: 'আপনার সাইন-ইন ইতিহাস দেখুন'),
                        actionLabel: _t3(context, ar: 'عرض', en: 'View', es: 'Ver', tr: 'Görüntüle',
                            id: 'Lihat',
                            hi: 'देखें',
                            ur: 'دیکھیں',
                            fr: 'Voir',
                            bn: 'দেখুন'),
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
                              _t3(context, ar: 'الملف الشخصي للعضو', en: 'Member Profile', es: 'Perfil de miembro', tr: 'Üye profili',
                                  id: 'Profil anggota',
                                  hi: 'सदस्य प्रोफ़ाइल',
                                  ur: 'ممبر پروفائل',
                                  fr: 'Profil du membre',
                                  bn: 'সদস্য প্রোফাইল'),
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                            ),
                          ),
                          TextButton(
                            onPressed: () => _editLegalNameAndDob(context, ref, profile, user?.id),
                            child: Text(_t3(context, ar: 'تعديل', en: 'Edit', es: 'Editar', tr: 'Düzenle',
                                id: 'Edit',
                                hi: 'संपादित करें',
                                ur: 'ترمیم کریں',
                                fr: 'Modifier',
                                bn: 'সম্পাদনা করুন')),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _t3(
                          context,
                          ar: 'أضف اسمك القانوني وتاريخ ميلادك لإكمال ملفك الشخصي، وتأكد من أن البيانات مطابقة لهويتك المستخدمة في السفر.',
                          en: 'Add your legal name and date of birth to complete your member profile. Please ensure the info matches your travel ID.',
                          es: 'Añade tu nombre legal y fecha de nacimiento. Asegúrate de que coincida con tu identificación de viaje.',
                          tr: 'Üye profilinizi tamamlamak için yasal adınızı ve doğum tarihinizi ekleyin. Bilgilerin seyahat kimliğinizle eşleştiğinden emin olun.',
                          id: 'Tambahkan nama resmi dan tanggal lahir Anda untuk melengkapi profil anggota. Pastikan info sesuai dengan identitas perjalanan Anda.',
                          hi: 'अपनी सदस्य प्रोफ़ाइल पूरी करने के लिए अपना कानूनी नाम और जन्म तिथि जोड़ें। कृपया सुनिश्चित करें कि जानकारी आपकी यात्रा आईडी से मेल खाती है।',
                          ur: 'اپنی ممبر پروفائل مکمل کرنے کے لیے اپنا قانونی نام اور تاریخ پیدائش شامل کریں۔ براہ کرم یقینی بنائیں کہ معلومات آپ کی سفری شناخت سے مطابقت رکھتی ہیں۔',
                          fr: 'Ajoutez votre nom légal et votre date de naissance pour compléter votre profil membre. Assurez-vous que ces informations correspondent à votre pièce d\'identité de voyage.',
                          bn: 'আপনার সদস্য প্রোফাইল সম্পূর্ণ করতে আপনার আইনি নাম ও জন্ম তারিখ যোগ করুন। নিশ্চিত করুন যে তথ্য আপনার ভ্রমণ পরিচয়পত্রের সাথে মিলে যায়।',
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
                              _t3(context, ar: 'الاسم القانوني', en: 'Legal name', es: 'Nombre legal', tr: 'Yasal ad',
                                  id: 'Nama resmi',
                                  hi: 'कानूनी नाम',
                                  ur: 'قانونی نام',
                                  fr: 'Nom légal',
                                  bn: 'আইনি নাম'),
                              style: const TextStyle(color: AppColors.textSecondary),
                            ),
                            Text((profile?.fullName?.isNotEmpty ?? false) ? profile!.fullName! : '-'),
                            const SizedBox(height: 6),
                            Text(
                              _t3(context, ar: 'تاريخ الميلاد', en: 'Date of birth', es: 'Fecha de nacimiento', tr: 'Doğum tarihi',
                                  id: 'Tanggal lahir',
                                  hi: 'जन्म तिथि',
                                  ur: 'تاریخ پیدائش',
                                  fr: 'Date de naissance',
                                  bn: 'জন্ম তারিখ'),
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
                              _t3(context, ar: 'المعلومات الشخصية', en: 'Personal info', es: 'Información personal', tr: 'Kişisel bilgiler',
                                  id: 'Info pribadi',
                                  hi: 'व्यक्तिगत जानकारी',
                                  ur: 'ذاتی معلومات',
                                  fr: 'Informations personnelles',
                                  bn: 'ব্যক্তিগত তথ্য'),
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                            ),
                          ),
                          TextButton(
                            onPressed: () => _editPersonalInfo(context, ref, profile, user?.id),
                            child: Text(_t3(context, ar: 'تعديل', en: 'Edit', es: 'Editar', tr: 'Düzenle',
                                id: 'Edit',
                                hi: 'संपादित करें',
                                ur: 'ترمیم کریں',
                                fr: 'Modifier',
                                bn: 'সম্পাদনা করুন')),
                          ),
                        ],
                      ),
                      Text(
                        _t3(
                          context,
                          ar: 'أدخل معلوماتك الشخصية لمساعدتنا على تخصيص رحلاتك واكتشاف العروض القريبة منك',
                          en: 'Enter your personal info to help us tailor your trips and discover nearby deals for you',
                          es: 'Ingresa tu información personal para adaptar tus viajes y ofertas cercanas',
                          tr: 'Seyahatlerinizi size özel hale getirmemiz ve yakın fırsatları keşfetmeniz için kişisel bilgilerinizi girin',
                          id: 'Masukkan info pribadi Anda agar kami bisa menyesuaikan perjalanan dan menemukan penawaran terdekat untuk Anda',
                          hi: 'अपनी यात्राओं को आपके अनुसार बनाने और आस-पास के ऑफ़र खोजने में मदद के लिए अपनी व्यक्तिगत जानकारी दर्ज करें',
                          ur: 'اپنی سفری معلومات کو آپ کے مطابق بنانے اور قریبی آفرز تلاش کرنے میں مدد کے لیے اپنی ذاتی معلومات درج کریں',
                          fr: 'Saisissez vos informations personnelles pour nous aider à adapter vos voyages et découvrir des offres à proximité',
                          bn: 'আপনার ভ্রমণ উপযোগী করতে এবং কাছাকাছি অফার খুঁজে পেতে আপনার ব্যক্তিগত তথ্য লিখুন',
                        ),
                        style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: AppSizes.md),
                      _ResponsiveTilePair(
                        isNarrow: isNarrow,
                        first: _InfoTile(
                          icon: Icons.wc_outlined,
                          color: _FieldColors.gender,
                          label: _t3(context, ar: 'الجنس', en: 'Gender', es: 'Género', tr: 'Cinsiyet',
                              id: 'Jenis kelamin',
                              hi: 'लिंग',
                              ur: 'جنس',
                              fr: 'Genre',
                              bn: 'লিঙ্গ'),
                          value: _genderLabel(context, profile?.gender),
                        ),
                        second: _InfoTile(
                          icon: Icons.badge_outlined,
                          color: _FieldColors.displayName,
                          label: _t3(context, ar: 'اسم العرض', en: 'Display name', es: 'Nombre visible', tr: 'Görünen ad',
                              id: 'Nama tampilan',
                              hi: 'प्रदर्शन नाम',
                              ur: 'ڈسپلے نام',
                              fr: 'Nom d\'affichage',
                              bn: 'প্রদর্শন নাম'),
                          value: (profile?.displayName?.isNotEmpty ?? false) ? profile!.displayName! : '-',
                        ),
                      ),
                      const SizedBox(height: AppSizes.sm),
                      _ResponsiveTilePair(
                        isNarrow: isNarrow,
                        first: _InfoTile(
                          icon: Icons.public,
                          color: _FieldColors.nationality,
                          label: _t3(context, ar: 'الجنسية', en: 'Nationality (country or region)', es: 'Nacionalidad', tr: 'Uyruk (ülke veya bölge)',
                              id: 'Kewarganegaraan (negara atau wilayah)',
                              hi: 'राष्ट्रीयता (देश या क्षेत्र)',
                              ur: 'شہریت (ملک یا خطہ)',
                              fr: 'Nationalité (pays ou région)',
                              bn: 'জাতীয়তা (দেশ বা অঞ্চল)'),
                          value: (profile?.nationality?.isNotEmpty ?? false) ? profile!.nationality! : '-',
                        ),
                        second: _InfoTile(
                          icon: Icons.location_city_outlined,
                          color: _FieldColors.cityOfResidence,
                          label: _t3(context, ar: 'مدينة الإقامة', en: 'City of residence', es: 'Ciudad de residencia', tr: 'İkamet şehri',
                              id: 'Kota domisili',
                              hi: 'निवास का शहर',
                              ur: 'رہائشی شہر',
                              fr: 'Ville de résidence',
                              bn: 'বসবাসের শহর'),
                          value: (profile?.cityOfResidence?.isNotEmpty ?? false) ? profile!.cityOfResidence! : '-',
                        ),
                      ),
                      const SizedBox(height: AppSizes.sm),
                      _InfoTile(
                        icon: Icons.map_outlined,
                        color: _FieldColors.frequentCity,
                        label: _t3(context, ar: 'المدينة الأكثر زيارة', en: 'Frequently visited city', es: 'Ciudad más visitada', tr: 'En sık ziyaret edilen şehir',
                            id: 'Kota yang sering dikunjungi',
                            hi: 'अक्सर जाया जाने वाला शहर',
                            ur: 'اکثر جانے والا شہر',
                            fr: 'Ville fréquemment visitée',
                            bn: 'প্রায়ই ভ্রমণ করা শহর'),
                        value: (profile?.frequentlyVisitedCity?.isNotEmpty ?? false) ? profile!.frequentlyVisitedCity! : '-',
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
                              _t3(context, ar: 'معلومات جواز السفر', en: 'Passport info', es: 'Información del pasaporte', tr: 'Pasaport bilgileri',
                                  id: 'Info paspor',
                                  hi: 'पासपोर्ट जानकारी',
                                  ur: 'پاسپورٹ کی معلومات',
                                  fr: 'Informations du passeport',
                                  bn: 'পাসপোর্ট তথ্য'),
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                            ),
                          ),
                          TextButton(
                            onPressed: () => _editPassportInfo(context, ref, profile, user?.id),
                            child: Text(_t3(context, ar: 'تعديل', en: 'Edit', es: 'Editar', tr: 'Düzenle',
                                id: 'Edit',
                                hi: 'संपादित करें',
                                ur: 'ترمیم کریں',
                                fr: 'Modifier',
                                bn: 'সম্পাদনা করুন')),
                          ),
                        ],
                      ),
                      Text(
                        _t3(
                          context,
                          ar: 'أضف بيانات جواز سفرك لتسريع حجز رحلاتك والتأكد من توافقها مع متطلبات شركات الطيران',
                          en: 'Add your passport details to speed up flight bookings and make sure they meet airline requirements',
                          es: 'Añade los datos de tu pasaporte para agilizar tus reservas de vuelo y cumplir los requisitos de la aerolínea',
                          tr: 'Uçuş rezervasyonlarınızı hızlandırmak ve havayolu gereksinimlerini karşıladığından emin olmak için pasaport bilgilerinizi ekleyin',
                          id: 'Tambahkan detail paspor Anda untuk mempercepat pemesanan penerbangan dan memastikannya memenuhi persyaratan maskapai',
                          hi: 'अपनी फ्लाइट बुकिंग को तेज़ करने और एयरलाइन आवश्यकताओं को पूरा करने के लिए अपने पासपोर्ट का विवरण जोड़ें',
                          ur: 'اپنی فلائٹ بکنگ کو تیز کرنے اور ایئرلائن کی ضروریات پوری کرنے کے لیے اپنے پاسپورٹ کی تفصیلات شامل کریں',
                          fr: 'Ajoutez les détails de votre passeport pour accélérer vos réservations de vol et répondre aux exigences des compagnies aériennes',
                          bn: 'আপনার ফ্লাইট বুকিং দ্রুত করতে এবং এয়ারলাইন প্রয়োজনীয়তা পূরণ করতে আপনার পাসপোর্টের বিবরণ যোগ করুন',
                        ),
                        style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: AppSizes.md),
                      _ResponsiveTilePair(
                        isNarrow: isNarrow,
                        first: _InfoTile(
                          icon: Icons.badge_outlined,
                          color: _FieldColors.passportNumber,
                          label: _t3(context, ar: 'رقم جواز السفر', en: 'Passport number', es: 'Número de pasaporte', tr: 'Pasaport numarası',
                              id: 'Nomor paspor',
                              hi: 'पासपोर्ट नंबर',
                              ur: 'پاسپورٹ نمبر',
                              fr: 'Numéro de passeport',
                              bn: 'পাসপোর্ট নম্বর'),
                          value: (profile?.passportNumber?.isNotEmpty ?? false) ? profile!.passportNumber! : '-',
                        ),
                        second: _InfoTile(
                          icon: Icons.public,
                          color: _FieldColors.passportCountry,
                          label: _t3(context, ar: 'دولة الإصدار', en: 'Issuing country', es: 'País emisor', tr: 'Veren ülke',
                              id: 'Negara penerbit',
                              hi: 'जारीकर्ता देश',
                              ur: 'اجراء کرنے والا ملک',
                              fr: 'Pays de délivrance',
                              bn: 'ইস্যুকারী দেশ'),
                          value: (profile?.passportIssuingCountry?.isNotEmpty ?? false) ? profile!.passportIssuingCountry! : '-',
                        ),
                      ),
                      const SizedBox(height: AppSizes.sm),
                      _InfoTile(
                        icon: Icons.event_outlined,
                        color: _FieldColors.passportExpiry,
                        label: _t3(context, ar: 'تاريخ الانتهاء', en: 'Expiry date', es: 'Fecha de vencimiento', tr: 'Son geçerlilik tarihi',
                            id: 'Tanggal kedaluwarsa',
                            hi: 'समाप्ति तिथि',
                            ur: 'میعاد ختم ہونے کی تاریخ',
                            fr: 'Date d\'expiration',
                            bn: 'মেয়াদ শেষ হওয়ার তারিখ'),
                        value: () {
                          final expiry = profile?.passportExpiry;
                          if (expiry == null) return '-';
                          return '${expiry.year}-${expiry.month.toString().padLeft(2, '0')}-${expiry.day.toString().padLeft(2, '0')}';
                        }(),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSizes.xl),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _updateEmail(BuildContext context, WidgetRef ref) async {
    final controller = TextEditingController(text: user?.email ?? '');
    await showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(_t3(dialogContext, ar: 'تحديث البريد الإلكتروني', en: 'Update email', es: 'Actualizar correo', tr: 'E-postayı güncelle',
              id: 'Perbarui email',
              hi: 'ईमेल अपडेट करें',
              ur: 'ای میل اپ ڈیٹ کریں',
              fr: 'Mettre à jour l\'e-mail',
              bn: 'ইমেইল আপডেট করুন')),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              labelText: 'Email',
              prefixIcon: const Icon(Icons.email_outlined, color: _FieldColors.email),
              focusedBorder: OutlineInputBorder(
                borderSide: const BorderSide(color: _FieldColors.email, width: 2),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(_t3(dialogContext, ar: 'إلغاء', en: 'Cancel', es: 'Cancelar', tr: 'İptal',
                  id: 'Batal',
                  hi: 'रद्द करें',
                  ur: 'منسوخ کریں',
                  fr: 'Annuler',
                  bn: 'বাতিল করুন')),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: _FieldColors.email),
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
                          ar: 'تم إرسال رسالة تأكيد إلى بريدك الإلكتروني الجديد',
                          en: 'A confirmation email has been sent to the new address',
                          es: 'Se envió un correo de confirmación a la nueva dirección',
                          tr: 'Yeni adrese bir onay e-postası gönderildi',
                          id: 'Email konfirmasi telah dikirim ke alamat baru',
                          hi: 'नए पते पर एक पुष्टिकरण ईमेल भेजा गया है',
                          ur: 'نئے پتے پر ایک تصدیقی ای میل بھیج دی گئی ہے',
                          fr: 'Un e-mail de confirmation a été envoyé à la nouvelle adresse',
                          bn: 'নতুন ঠিকানায় একটি নিশ্চিতকরণ ইমেইল পাঠানো হয়েছে',
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
              child: Text(_t3(dialogContext, ar: 'حفظ', en: 'Save', es: 'Guardar', tr: 'Kaydet',
                  id: 'Simpan',
                  hi: 'सहेजें',
                  ur: 'محفوظ کریں',
                  fr: 'Enregistrer',
                  bn: 'সংরক্ষণ করুন')),
            ),
          ],
        );
      },
    );
  }

  /// يسجّل خروج المستخدم من كل الأجهزة الأخرى المسجّل دخولها بنفس
  /// الحساب (ما عدا هذا الجهاز الحالي) -- خيار أمان سريع وجاهز فعليًا
  /// بمكتبة Supabase (SignOutScope.others) بدون أي بنية خلفية إضافية،
  /// بعكس قائمة أجهزة مفصّلة لكل جهاز لحاله (يحتاج Edge Function جديدة
  /// بصلاحيات Admin لاحقًا لو احتجنا تفاصيل كل جهاز أو إلغاء واحد
  /// بالتحديد).
  Future<void> _signOutOtherDevices(BuildContext context, WidgetRef ref) async {
    await showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(_t3(dialogContext, ar: 'تسجيل خروج من باقي الأجهزة', en: 'Sign out other devices', es: 'Cerrar sesión en otros dispositivos', tr: 'Diğer cihazlardan çıkış yap',
              id: 'Keluar dari perangkat lain',
              hi: 'अन्य डिवाइसों से साइन आउट करें',
              ur: 'دیگر ڈیوائسز سے سائن آؤٹ کریں',
              fr: 'Se déconnecter des autres appareils',
              bn: 'অন্যান্য ডিভাইস থেকে সাইন আউট করুন')),
          content: Text(_t3(dialogContext,
              ar: 'رح يتم تسجيل خروجك من كل الأجهزة الأخرى المسجّل دخولها بحسابك، ما عدا هذا الجهاز. تأكيد؟',
              en: "You'll be signed out on every other device currently signed in to your account, except this one. Continue?",
              es: 'Se cerrará tu sesión en todos los demás dispositivos donde hayas iniciado sesión, excepto en este. ¿Continuar?',
              tr: 'Bu cihaz hariç, hesabınızda oturum açık olan tüm diğer cihazlardan çıkış yapılacak. Devam edilsin mi?',
              id: 'Anda akan keluar dari semua perangkat lain yang sedang masuk ke akun Anda, kecuali perangkat ini. Lanjutkan?',
              hi: 'इस डिवाइस को छोड़कर, आपके खाते में साइन इन बाकी सभी डिवाइसों से आपको साइन आउट कर दिया जाएगा। जारी रखें?',
              ur: 'اس ڈیوائس کے سوا آپ کے اکاؤنٹ میں سائن ان باقی تمام ڈیوائسز سے آپ کو سائن آؤٹ کر دیا جائے گا۔ جاری رکھیں؟',
              fr: 'Vous serez déconnecté de tous les autres appareils actuellement connectés à votre compte, sauf celui-ci. Continuer ?',
              bn: 'এই ডিভাইসটি ছাড়া আপনার অ্যাকাউন্টে সাইন ইন থাকা বাকি সব ডিভাইস থেকে আপনাকে সাইন আউট করে দেওয়া হবে। চালিয়ে যাবেন?')),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(_t3(dialogContext, ar: 'إلغاء', en: 'Cancel', es: 'Cancelar', tr: 'İptal',
                  id: 'Batal',
                  hi: 'रद्द करें',
                  ur: 'منسوخ کریں',
                  fr: 'Annuler',
                  bn: 'বাতিল করুন')),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: _FieldColors.devices),
              onPressed: () async {
                try {
                  await Supabase.instance.client.auth.signOut(scope: SignOutScope.others);
                  if (!dialogContext.mounted) return;
                  Navigator.of(dialogContext).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(_t3(context, ar: 'تم تسجيل الخروج من باقي الأجهزة', en: 'Signed out on other devices', es: 'Sesión cerrada en los demás dispositivos', tr: 'Diğer cihazlardan çıkış yapıldı',
                          id: 'Berhasil keluar dari perangkat lain',
                          hi: 'अन्य डिवाइसों से साइन आउट हो गया',
                          ur: 'دیگر ڈیوائسز سے سائن آؤٹ ہو گیا',
                          fr: 'Déconnecté des autres appareils',
                          bn: 'অন্যান্য ডিভাইস থেকে সাইন আউট হয়েছে')),
                    ),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    SnackBar(content: Text(e.toString())),
                  );
                }
              },
              child: Text(_t3(dialogContext, ar: 'تأكيد', en: 'Confirm', es: 'Confirmar', tr: 'Onayla',
                  id: 'Konfirmasi',
                  hi: 'पुष्टि करें',
                  ur: 'تصدیق کریں',
                  fr: 'Confirmer',
                  bn: 'নিশ্চিত করুন')),
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
          title: Text(_t3(dialogContext, ar: 'ضبط كلمة مرور', en: 'Set password', es: 'Configurar contraseña', tr: 'Şifre belirle',
              id: 'Atur kata sandi',
              hi: 'पासवर्ड सेट करें',
              ur: 'پاس ورڈ سیٹ کریں',
              fr: 'Définir le mot de passe',
              bn: 'পাসওয়ার্ড সেট করুন')),
          content: TextField(
            controller: controller,
            obscureText: true,
            decoration: InputDecoration(
              labelText: 'Password',
              prefixIcon: const Icon(Icons.lock_outline, color: _FieldColors.password),
              focusedBorder: OutlineInputBorder(
                borderSide: const BorderSide(color: _FieldColors.password, width: 2),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(_t3(dialogContext, ar: 'إلغاء', en: 'Cancel', es: 'Cancelar', tr: 'İptal',
                  id: 'Batal',
                  hi: 'रद्द करें',
                  ur: 'منسوخ کریں',
                  fr: 'Annuler',
                  bn: 'বাতিল করুন')),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: _FieldColors.password),
              onPressed: () async {
                try {
                  await Supabase.instance.client.auth.updateUser(
                    UserAttributes(password: controller.text),
                  );
                  if (!dialogContext.mounted) return;
                  Navigator.of(dialogContext).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(_t3(context, ar: 'تم تحديث كلمة المرور', en: 'Password updated', es: 'Contraseña actualizada', tr: 'Şifre güncellendi',
                          id: 'Kata sandi diperbarui',
                          hi: 'पासवर्ड अपडेट हो गया',
                          ur: 'پاس ورڈ اپ ڈیٹ ہو گیا',
                          fr: 'Mot de passe mis à jour',
                          bn: 'পাসওয়ার্ড আপডেট হয়েছে')),
                    ),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    SnackBar(content: Text(e.toString())),
                  );
                }
              },
              child: Text(_t3(dialogContext, ar: 'حفظ', en: 'Save', es: 'Guardar', tr: 'Kaydet',
                  id: 'Simpan',
                  hi: 'सहेजें',
                  ur: 'محفوظ کریں',
                  fr: 'Enregistrer',
                  bn: 'সংরক্ষণ করুন')),
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
          title: Text(_t3(dialogContext, ar: 'ربط رقم الهاتف', en: 'Link phone number', es: 'Vincular teléfono', tr: 'Telefon numarasını bağla',
              id: 'Tautkan nomor telepon',
              hi: 'फ़ोन नंबर लिंक करें',
              ur: 'فون نمبر لنک کریں',
              fr: 'Lier un numéro de téléphone',
              bn: 'ফোন নম্বর লিঙ্ক করুন')),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(
              labelText: '+9665xxxxxxxx',
              prefixIcon: const Icon(Icons.phone_outlined, color: _FieldColors.phone),
              focusedBorder: OutlineInputBorder(
                borderSide: const BorderSide(color: _FieldColors.phone, width: 2),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(_t3(dialogContext, ar: 'إلغاء', en: 'Cancel', es: 'Cancelar', tr: 'İptal',
                  id: 'Batal',
                  hi: 'रद्द करें',
                  ur: 'منسوخ کریں',
                  fr: 'Annuler',
                  bn: 'বাতিল করুন')),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: _FieldColors.phone),
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
              child: Text(_t3(dialogContext, ar: 'حفظ', en: 'Save', es: 'Guardar', tr: 'Kaydet',
                  id: 'Simpan',
                  hi: 'सहेजें',
                  ur: 'محفوظ کریں',
                  fr: 'Enregistrer',
                  bn: 'সংরক্ষণ করুন')),
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
                    _t3(sheetContext, ar: 'الملف الشخصي للعضو', en: 'Member Profile', es: 'Perfil de miembro', tr: 'Üye profili',
                        id: 'Profil anggota',
                        hi: 'सदस्य प्रोफ़ाइल',
                        ur: 'ممبر پروفائل',
                        fr: 'Profil du membre',
                        bn: 'সদস্য প্রোফাইল'),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  const SizedBox(height: AppSizes.md),
                  TextField(
                    controller: nameController,
                    decoration: InputDecoration(
                      labelText: _t3(sheetContext, ar: 'الاسم القانوني', en: 'Legal name', es: 'Nombre legal', tr: 'Yasal ad',
                          id: 'Nama resmi',
                          hi: 'कानूनी नाम',
                          ur: 'قانونی نام',
                          fr: 'Nom légal',
                          bn: 'আইনি নাম'),
                      prefixIcon: const Icon(Icons.badge_outlined, color: AppColors.primary),
                      focusedBorder: OutlineInputBorder(
                        borderSide: const BorderSide(color: AppColors.primary, width: 2),
                        borderRadius: BorderRadius.circular(10),
                      ),
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
                        labelText: _t3(sheetContext, ar: 'تاريخ الميلاد', en: 'Date of birth', es: 'Fecha de nacimiento', tr: 'Doğum tarihi',
                            id: 'Tanggal lahir',
                            hi: 'जन्म तिथि',
                            ur: 'تاریخ پیدائش',
                            fr: 'Date de naissance',
                            bn: 'জন্ম তারিখ'),
                        prefixIcon: const Icon(Icons.calendar_today_outlined, color: AppColors.primary),
                      ),
                      child: Text(
                        dob == null
                            ? _t3(sheetContext, ar: 'اختر تاريخ', en: 'Select a date', es: 'Elige una fecha', tr: 'Bir tarih seçin',
                            id: 'Pilih tanggal',
                            hi: 'एक तारीख चुनें',
                            ur: 'ایک تاریخ منتخب کریں',
                            fr: 'Choisir une date',
                            bn: 'একটি তারিখ নির্বাচন করুন')
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
                      child: Text(_t3(sheetContext, ar: 'حفظ', en: 'Save', es: 'Guardar', tr: 'Kaydet',
                          id: 'Simpan',
                          hi: 'सहेजें',
                          ur: 'محفوظ کریں',
                          fr: 'Enregistrer',
                          bn: 'সংরক্ষণ করুন')),
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
    String? selectedGender = (profile?.gender == 'm' || profile?.gender == 'f') ? profile!.gender : null;
    final displayNameController = TextEditingController(text: profile?.displayName ?? '');
    final nationalityController = TextEditingController(text: profile?.nationality ?? '');
    final cityController = TextEditingController(text: profile?.cityOfResidence ?? '');
    final frequentCityController = TextEditingController(text: profile?.frequentlyVisitedCity ?? '');

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (sheetContext, setSheetState) {
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
                  _t3(sheetContext, ar: 'المعلومات الشخصية', en: 'Personal info', es: 'Información personal', tr: 'Kişisel bilgiler',
                      id: 'Info pribadi',
                      hi: 'व्यक्तिगत जानकारी',
                      ur: 'ذاتی معلومات',
                      fr: 'Informations personnelles',
                      bn: 'ব্যক্তিগত তথ্য'),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                const SizedBox(height: AppSizes.md),
                DropdownButtonFormField<String>(
                  initialValue: selectedGender,
                  decoration: InputDecoration(
                    labelText: _t3(sheetContext, ar: 'الجنس', en: 'Gender', es: 'Género', tr: 'Cinsiyet',
                        id: 'Jenis kelamin',
                        hi: 'लिंग',
                        ur: 'جنس',
                        fr: 'Genre',
                        bn: 'লিঙ্গ'),
                    prefixIcon: const Icon(Icons.wc_outlined, color: _FieldColors.gender),
                    focusedBorder: OutlineInputBorder(
                      borderSide: const BorderSide(color: _FieldColors.gender, width: 2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  items: [
                    DropdownMenuItem(value: 'm', child: Text(_genderLabel(sheetContext, 'm'))),
                    DropdownMenuItem(value: 'f', child: Text(_genderLabel(sheetContext, 'f'))),
                  ],
                  onChanged: (v) => setSheetState(() => selectedGender = v),
                ),
                const SizedBox(height: AppSizes.sm),
                TextField(
                  controller: displayNameController,
                  decoration: InputDecoration(
                    labelText: _t3(sheetContext, ar: 'اسم العرض', en: 'Display name', es: 'Nombre visible', tr: 'Görünen ad',
                        id: 'Nama tampilan',
                        hi: 'प्रदर्शन नाम',
                        ur: 'ڈسپلے نام',
                        fr: 'Nom d\'affichage',
                        bn: 'প্রদর্শন নাম'),
                    prefixIcon: const Icon(Icons.badge_outlined, color: _FieldColors.displayName),
                    focusedBorder: OutlineInputBorder(
                      borderSide: const BorderSide(color: _FieldColors.displayName, width: 2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: AppSizes.sm),
                TextField(
                  controller: nationalityController,
                  decoration: InputDecoration(
                    labelText: _t3(sheetContext, ar: 'الجنسية', en: 'Nationality (country or region)', es: 'Nacionalidad', tr: 'Uyruk (ülke veya bölge)',
                        id: 'Kewarganegaraan (negara atau wilayah)',
                        hi: 'राष्ट्रीयता (देश या क्षेत्र)',
                        ur: 'شہریت (ملک یا خطہ)',
                        fr: 'Nationalité (pays ou région)',
                        bn: 'জাতীয়তা (দেশ বা অঞ্চল)'),
                    prefixIcon: const Icon(Icons.public, color: _FieldColors.nationality),
                    focusedBorder: OutlineInputBorder(
                      borderSide: const BorderSide(color: _FieldColors.nationality, width: 2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: AppSizes.sm),
                TextField(
                  controller: cityController,
                  decoration: InputDecoration(
                    labelText: _t3(sheetContext, ar: 'مدينة الإقامة', en: 'City of residence', es: 'Ciudad de residencia', tr: 'İkamet şehri',
                        id: 'Kota domisili',
                        hi: 'निवास का शहर',
                        ur: 'رہائشی شہر',
                        fr: 'Ville de résidence',
                        bn: 'বসবাসের শহর'),
                    prefixIcon: const Icon(Icons.location_city_outlined, color: _FieldColors.cityOfResidence),
                    focusedBorder: OutlineInputBorder(
                      borderSide: const BorderSide(color: _FieldColors.cityOfResidence, width: 2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: AppSizes.sm),
                TextField(
                  controller: frequentCityController,
                  decoration: InputDecoration(
                    labelText: _t3(sheetContext, ar: 'المدينة الأكثر زيارة', en: 'Frequently visited city', es: 'Ciudad más visitada', tr: 'En sık ziyaret edilen şehir',
                        id: 'Kota yang sering dikunjungi',
                        hi: 'अक्सर जाया जाने वाला शहर',
                        ur: 'اکثر جانے والا شہر',
                        fr: 'Ville fréquemment visitée',
                        bn: 'প্রায়ই ভ্রমণ করা শহর'),
                    prefixIcon: const Icon(Icons.map_outlined, color: _FieldColors.frequentCity),
                    focusedBorder: OutlineInputBorder(
                      borderSide: const BorderSide(color: _FieldColors.frequentCity, width: 2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: AppSizes.md),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      final updated = (profile ?? ProfileModel(id: userId!)).copyWith(
                        gender: selectedGender ?? '',
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
                    child: Text(_t3(sheetContext, ar: 'حفظ', en: 'Save', es: 'Guardar', tr: 'Kaydet',
                        id: 'Simpan',
                        hi: 'सहेजें',
                        ur: 'محفوظ کریں',
                        fr: 'Enregistrer',
                        bn: 'সংরক্ষণ করুন')),
                  ),
                ),
              ],
            ),
          ),
        );
            },
        );
      },
    );
  }

  Future<void> _editPassportInfo(BuildContext context, WidgetRef ref, ProfileModel? profile, String? userId) async {
    final passportNumberController = TextEditingController(text: profile?.passportNumber ?? '');
    final issuingCountryController = TextEditingController(text: profile?.passportIssuingCountry ?? '');
    DateTime? expiry = profile?.passportExpiry;

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
              return SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      _t3(sheetContext, ar: 'معلومات جواز السفر', en: 'Passport info', es: 'Información del pasaporte', tr: 'Pasaport bilgileri',
                          id: 'Info paspor',
                          hi: 'पासपोर्ट जानकारी',
                          ur: 'پاسپورٹ کی معلومات',
                          fr: 'Informations du passeport',
                          bn: 'পাসপোর্ট তথ্য'),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                    const SizedBox(height: AppSizes.md),
                    TextField(
                      controller: passportNumberController,
                      decoration: InputDecoration(
                        labelText: _t3(sheetContext, ar: 'رقم جواز السفر', en: 'Passport number', es: 'Número de pasaporte', tr: 'Pasaport numarası',
                            id: 'Nomor paspor',
                            hi: 'पासपोर्ट नंबर',
                            ur: 'پاسپورٹ نمبر',
                            fr: 'Numéro de passeport',
                            bn: 'পাসপোর্ট নম্বর'),
                        prefixIcon: const Icon(Icons.badge_outlined, color: _FieldColors.passportNumber),
                        focusedBorder: OutlineInputBorder(
                          borderSide: const BorderSide(color: _FieldColors.passportNumber, width: 2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSizes.sm),
                    TextField(
                      controller: issuingCountryController,
                      decoration: InputDecoration(
                        labelText: _t3(sheetContext, ar: 'دولة الإصدار', en: 'Issuing country', es: 'País emisor', tr: 'Veren ülke',
                            id: 'Negara penerbit',
                            hi: 'जारीकर्ता देश',
                            ur: 'اجراء کرنے والا ملک',
                            fr: 'Pays de délivrance',
                            bn: 'ইস্যুকারী দেশ'),
                        prefixIcon: const Icon(Icons.public, color: _FieldColors.passportCountry),
                        focusedBorder: OutlineInputBorder(
                          borderSide: const BorderSide(color: _FieldColors.passportCountry, width: 2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSizes.sm),
                    GestureDetector(
                      onTap: () async {
                        final now = DateTime.now();
                        final picked = await showDatePicker(
                          context: sheetContext,
                          firstDate: now,
                          lastDate: DateTime(now.year + 20),
                          initialDate: expiry ?? now.add(const Duration(days: 365)),
                        );
                        if (picked != null) setSheetState(() => expiry = picked);
                      },
                      child: InputDecorator(
                        decoration: InputDecoration(
                          labelText: _t3(sheetContext, ar: 'تاريخ الانتهاء', en: 'Expiry date', es: 'Fecha de vencimiento', tr: 'Son geçerlilik tarihi',
                              id: 'Tanggal kedaluwarsa',
                              hi: 'समाप्ति तिथि',
                              ur: 'میعاد ختم ہونے کی تاریخ',
                              fr: 'Date d\'expiration',
                              bn: 'মেয়াদ শেষ হওয়ার তারিখ'),
                          prefixIcon: const Icon(Icons.event_outlined, color: _FieldColors.passportExpiry),
                        ),
                        child: Text(
                          expiry == null
                              ? _t3(sheetContext, ar: 'اختر تاريخ', en: 'Select a date', es: 'Elige una fecha', tr: 'Bir tarih seçin',
                              id: 'Pilih tanggal',
                              hi: 'एक तारीख चुनें',
                              ur: 'ایک تاریخ منتخب کریں',
                              fr: 'Choisir une date',
                              bn: 'একটি তারিখ নির্বাচন করুন')
                              : '${expiry!.year}-${expiry!.month.toString().padLeft(2, '0')}-${expiry!.day.toString().padLeft(2, '0')}',
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSizes.md),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: _FieldColors.passportNumber),
                        onPressed: () async {
                          final updated = (profile ?? ProfileModel(id: userId!)).copyWith(
                            passportNumber: passportNumberController.text,
                            passportIssuingCountry: issuingCountryController.text,
                            passportExpiry: expiry,
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
                        child: Text(_t3(sheetContext, ar: 'حفظ', en: 'Save', es: 'Guardar', tr: 'Kaydet',
                            id: 'Simpan',
                            hi: 'सहेजें',
                            ur: 'محفوظ کریں',
                            fr: 'Enregistrer',
                            bn: 'সংরক্ষণ করুন')),
                      ),
                    ),
                  ],
                ),
              );
            },
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

class _ResponsiveTilePair extends StatelessWidget {
  final bool isNarrow;
  final Widget first;
  final Widget second;

  const _ResponsiveTilePair({
    required this.isNarrow,
    required this.first,
    required this.second,
  });

  @override
  Widget build(BuildContext context) {
    if (isNarrow) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          first,
          const SizedBox(height: AppSizes.sm),
          second,
        ],
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: first),
        const SizedBox(width: AppSizes.md),
        Expanded(child: second),
      ],
    );
  }
}

class _SecurityTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String value;
  final String actionLabel;
  final VoidCallback onAction;
  final bool filled;

  const _SecurityTile({
    required this.icon,
    required this.color,
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
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600), maxLines: 2, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 8),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: filled
                ? ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: color),
              onPressed: onAction,
              child: Text(actionLabel, maxLines: 1, overflow: TextOverflow.ellipsis),
            )
                : TextButton(
              style: TextButton.styleFrom(foregroundColor: color),
              onPressed: onAction,
              child: Text(actionLabel, maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String value;

  const _InfoTile({required this.icon, required this.color, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.md),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}