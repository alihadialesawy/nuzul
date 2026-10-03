import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../core/widgets/app_banner.dart';
import '../../data/models/passenger_model.dart';
import '../profile/profile_page.dart' show profileRepositoryProvider;
// ملاحظة: المسار أعلاه يفترض lib/presentation/profile/profile_page.dart
// (بنفس نمط lib/presentation/flights/). لو profile_page.dart فعليًا
// بمجلد مختلف، صحّح المسار هنا فقط.

/// يختار النص المناسب حسب اللغة الحالية (عربي/إنجليزي/إسباني) — نفس
/// نمط _t3 المستخدم بـ flight_booking_page.dart
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

/// شاشة جمع بيانات المسافرين قبل تأكيد حجز الطيران عبر Duffel.
/// تستقبل قائمة passengerIds (من العرض المختار وقت البحث)، وعدد
/// النماذج المعروضة = عدد المسافرين بالضبط. المسافر الأول يُعبّى
/// تلقائيًا من بروفايل المستخدم المسجّل دخول (قابل للتعديل).
///
/// عند اكتمال كل الحقول لكل المسافرين، onSubmit يُستدعى بقائمة
/// PassengerModel جاهزة للإرسال لـ duffel-create-order.
class PassengerDetailsPage extends ConsumerStatefulWidget {
  final List<String> passengerIds;
  final void Function(List<PassengerModel> passengers) onSubmit;

  const PassengerDetailsPage({
    super.key,
    required this.passengerIds,
    required this.onSubmit,
  });

  @override
  ConsumerState<PassengerDetailsPage> createState() => _PassengerDetailsPageState();
}

class _PassengerDetailsPageState extends ConsumerState<PassengerDetailsPage> {
  List<PassengerModel>? _passengers;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _initPassengers();
  }

  Future<void> _initPassengers() async {
    final accountEmail = Supabase.instance.client.auth.currentUser?.email;
    final profileRepo = ref.read(profileRepositoryProvider);
    final profileResult = await profileRepo.getMyProfile();

    final profile = profileResult.when(
      success: (p) => p,
      failure: (_) => null,
    );

    final passengers = <PassengerModel>[];
    for (var i = 0; i < widget.passengerIds.length; i++) {
      final id = widget.passengerIds[i];
      if (i == 0 && profile != null) {
        passengers.add(PassengerModel.fromProfile(
          passengerId: id,
          fullName: profile.fullName,
          dateOfBirth: profile.dateOfBirth,
          gender: profile.gender,
          phone: profile.phone,
          accountEmail: accountEmail,
        ));
      } else {
        passengers.add(PassengerModel.empty(id));
      }
    }

    if (!mounted) return;
    setState(() {
      _passengers = passengers;
      _loading = false;
    });
  }

  bool get _allComplete =>
      _passengers != null && _passengers!.every((p) => p.isComplete);

  void _updatePassenger(int index, PassengerModel updated) {
    setState(() {
      final list = [..._passengers!];
      list[index] = updated;
      _passengers = list;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AppBanner(),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
          padding: const EdgeInsets.all(AppSizes.md),
          children: [
            Text(
              _t3(
                context,
                ar: 'بيانات المسافرين',
                en: 'Passenger details',
                es: 'Datos de los pasajeros',
              ),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppSizes.sm),
            Text(
              _t3(
                context,
                ar: 'الأسماء يجب أن تطابق جواز السفر تمامًا',
                en: 'Names must exactly match the passport',
                es: 'Los nombres deben coincidir exactamente con el pasaporte',
              ),
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
            ),
            const SizedBox(height: AppSizes.md),
            for (var i = 0; i < _passengers!.length; i++) ...[
              _PassengerFormCard(
                index: i,
                passenger: _passengers![i],
                onChanged: (updated) => _updatePassenger(i, updated),
              ),
              const SizedBox(height: AppSizes.md),
            ],
            ElevatedButton(
              onPressed: _allComplete
                  ? () => widget.onSubmit(_passengers!)
                  : null,
              child: Text(
                _t3(context, ar: 'متابعة', en: 'Continue', es: 'Continuar'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PassengerFormCard extends StatefulWidget {
  final int index;
  final PassengerModel passenger;
  final void Function(PassengerModel updated) onChanged;

  const _PassengerFormCard({
    required this.index,
    required this.passenger,
    required this.onChanged,
  });

  @override
  State<_PassengerFormCard> createState() => _PassengerFormCardState();
}

class _PassengerFormCardState extends State<_PassengerFormCard> {
  // ألوان مميزة لكل مسافر حسب ترتيبه (بتتكرر تلقائيًا لو عدد
  // المسافرين زاد عن 4).
  static const List<Color> _passengerColors = [
    Color(0xFF2E86AB), // أزرق - المسافر الأول
    Color(0xFFE67E22), // برتقالي - المسافر الثاني
    Color(0xFF27AE60), // أخضر - المسافر الثالث
    Color(0xFF8E44AD), // بنفسجي - المسافر الرابع
  ];

  late TextEditingController _givenNameController;
  late TextEditingController _familyNameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;

  @override
  void initState() {
    super.initState();
    _givenNameController = TextEditingController(text: widget.passenger.givenName);
    _familyNameController = TextEditingController(text: widget.passenger.familyName);
    _emailController = TextEditingController(text: widget.passenger.email);
    _phoneController = TextEditingController(text: widget.passenger.phoneNumber);
  }

  @override
  void dispose() {
    _givenNameController.dispose();
    _familyNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _emit(PassengerModel updated) => widget.onChanged(updated);

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: widget.passenger.bornOn ?? DateTime(now.year - 30),
      firstDate: DateTime(now.year - 120),
      lastDate: now,
    );
    if (picked != null) {
      _emit(widget.passenger.copyWith(bornOn: picked));
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.passenger;
    final dateLabel = p.bornOn == null
        ? _t3(context, ar: 'تاريخ الميلاد', en: 'Date of birth', es: 'Fecha de nacimiento')
        : '${p.bornOn!.year}-${p.bornOn!.month.toString().padLeft(2, '0')}-${p.bornOn!.day.toString().padLeft(2, '0')}';

    final passengerColor = _passengerColors[widget.index % _passengerColors.length];

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: passengerColor, width: 2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: passengerColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  widget.index == 0
                      ? _t3(context, ar: 'المسافر الرئيسي', en: 'Lead passenger', es: 'Pasajero principal')
                      : '${_t3(context, ar: 'المسافر', en: 'Passenger', es: 'Pasajero')} ${widget.index + 1}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: passengerColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSizes.sm),
            DropdownButtonFormField<String>(
              value: p.title.isEmpty ? null : p.title,
              decoration: InputDecoration(
                labelText: _t3(context, ar: 'اللقب', en: 'Title', es: 'Título'),
                border: const OutlineInputBorder(),
                isDense: true,
              ),
              items: const [
                DropdownMenuItem(value: 'mr', child: Text('Mr')),
                DropdownMenuItem(value: 'mrs', child: Text('Mrs')),
                DropdownMenuItem(value: 'ms', child: Text('Ms')),
                DropdownMenuItem(value: 'miss', child: Text('Miss')),
              ],
              onChanged: (v) => _emit(p.copyWith(title: v)),
            ),
            const SizedBox(height: AppSizes.sm),
            Row(
              children: [
                Expanded(
                  child: RadioListTile<String>(
                    contentPadding: EdgeInsets.zero,
                    title: Text(_t3(context, ar: 'ذكر', en: 'Male', es: 'Hombre')),
                    value: 'm',
                    groupValue: p.gender.isEmpty ? null : p.gender,
                    onChanged: (v) => _emit(p.copyWith(gender: v)),
                  ),
                ),
                Expanded(
                  child: RadioListTile<String>(
                    contentPadding: EdgeInsets.zero,
                    title: Text(_t3(context, ar: 'أنثى', en: 'Female', es: 'Mujer')),
                    value: 'f',
                    groupValue: p.gender.isEmpty ? null : p.gender,
                    onChanged: (v) => _emit(p.copyWith(gender: v)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSizes.sm),
            TextField(
              controller: _givenNameController,
              decoration: InputDecoration(
                labelText: _t3(context, ar: 'الاسم الأول (كما بجواز السفر)', en: 'Given name (as on passport)', es: 'Nombre (como en el pasaporte)'),
                border: const OutlineInputBorder(),
                isDense: true,
              ),
              onChanged: (v) => _emit(p.copyWith(givenName: v)),
            ),
            const SizedBox(height: AppSizes.sm),
            TextField(
              controller: _familyNameController,
              decoration: InputDecoration(
                labelText: _t3(context, ar: 'اسم العائلة (كما بجواز السفر)', en: 'Family name (as on passport)', es: 'Apellido (como en el pasaporte)'),
                border: const OutlineInputBorder(),
                isDense: true,
              ),
              onChanged: (v) => _emit(p.copyWith(familyName: v)),
            ),
            const SizedBox(height: AppSizes.sm),
            InkWell(
              onTap: _pickDate,
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: _t3(context, ar: 'تاريخ الميلاد', en: 'Date of birth', es: 'Fecha de nacimiento'),
                  border: const OutlineInputBorder(),
                  isDense: true,
                ),
                child: Text(dateLabel),
              ),
            ),
            const SizedBox(height: AppSizes.sm),
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: _t3(context, ar: 'البريد الإلكتروني', en: 'Email', es: 'Correo electrónico'),
                border: const OutlineInputBorder(),
                isDense: true,
              ),
              onChanged: (v) => _emit(p.copyWith(email: v)),
            ),
            const SizedBox(height: AppSizes.sm),
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: _t3(context, ar: 'رقم الهاتف', en: 'Phone number', es: 'Número de teléfono'),
                border: const OutlineInputBorder(),
                isDense: true,
              ),
              onChanged: (v) => _emit(p.copyWith(phoneNumber: v)),
            ),
          ],
        ),
      ),
    );
  }
}