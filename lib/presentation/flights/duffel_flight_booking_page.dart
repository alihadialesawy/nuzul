import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../core/widgets/app_footer.dart';
import '../../core/widgets/app_banner.dart';
import '../../data/repositories/duffel_repository.dart';
import '../../data/repositories/duffel_booking_repository.dart';
import '../home/controllers/duffel_flight_search_controller.dart' show duffelRepositoryProvider;

final duffelBookingRepositoryProvider = Provider((ref) => DuffelBookingRepository());

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

/// صفحة حجز رحلة Duffel حقيقية: فورم بيانات المسافر (لكل مسافر مرتبط
/// بالعرض عبر passengerIds)، تأكيد، وإتمام الحجز فعليًا عبر Duffel
/// Order API (بالدفع من رصيد Duffel Balance التجريبي في بيئة الاختبار).
class DuffelFlightBookingPage extends ConsumerStatefulWidget {
  final DuffelFlightOffer offer;

  const DuffelFlightBookingPage({super.key, required this.offer});

  @override
  ConsumerState<DuffelFlightBookingPage> createState() => _DuffelFlightBookingPageState();
}

class _PassengerFormData {
  String title = 'mr';
  String gender = 'm';
  final givenNameController = TextEditingController();
  final familyNameController = TextEditingController();
  final emailController = TextEditingController();
  final phoneController = TextEditingController();
  DateTime? bornOn;

  void dispose() {
    givenNameController.dispose();
    familyNameController.dispose();
    emailController.dispose();
    phoneController.dispose();
  }
}

class _DuffelFlightBookingPageState extends ConsumerState<DuffelFlightBookingPage> {
  final _formKey = GlobalKey<FormState>();
  late final List<_PassengerFormData> _passengers;
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _passengers = widget.offer.passengerIds.map((_) => _PassengerFormData()).toList();
    if (_passengers.isEmpty) _passengers.add(_PassengerFormData());
  }

  @override
  void dispose() {
    for (final p in _passengers) {
      p.dispose();
    }
    super.dispose();
  }

  Future<void> _pickBirthDate(_PassengerFormData passenger) async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      firstDate: DateTime(now.year - 100),
      lastDate: now,
      initialDate: DateTime(now.year - 30),
    );
    if (date != null) setState(() => passenger.bornOn = date);
  }

  Future<void> _confirmBooking() async {
    if (!_formKey.currentState!.validate()) return;

    for (final p in _passengers) {
      if (p.bornOn == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _t3(context, ar: 'من فضلك اختار تاريخ ميلاد كل مسافر', en: 'Please pick a birth date for every passenger', es: 'Elige la fecha de nacimiento de cada pasajero'),
            ),
          ),
        );
        return;
      }
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    final repo = ref.read(duffelRepositoryProvider);
    final passengerIds = widget.offer.passengerIds;

    final passengerInfos = List.generate(_passengers.length, (i) {
      final p = _passengers[i];
      return DuffelPassengerInfo(
        id: i < passengerIds.length ? passengerIds[i] : '',
        title: p.title,
        gender: p.gender,
        givenName: p.givenNameController.text.trim(),
        familyName: p.familyNameController.text.trim(),
        bornOn: p.bornOn!,
        email: p.emailController.text.trim(),
        phoneNumber: p.phoneController.text.trim(),
      );
    });

    final orderResult = await repo.createOrder(
      offerId: widget.offer.id,
      totalAmount: widget.offer.totalAmount,
      totalCurrency: widget.offer.totalCurrency,
      passengers: passengerInfos,
    );

    if (!mounted) return;

    await orderResult.when(
      success: (order) async {
        final bookingRepo = ref.read(duffelBookingRepositoryProvider);
        final saveResult = await bookingRepo.saveBooking(
          duffelOrderId: order.orderId,
          bookingReference: order.bookingReference,
          offerId: widget.offer.id,
          airline: widget.offer.airline,
          flightNumber: widget.offer.flightNumber,
          originCity: widget.offer.originCity,
          destinationCity: widget.offer.destinationCity,
          departureTime: widget.offer.departureTime,
          arrivalTime: widget.offer.arrivalTime,
          cabinClass: widget.offer.cabinClass,
          totalAmount: widget.offer.totalAmount,
          totalCurrency: widget.offer.totalCurrency,
        );

        if (!mounted) return;
        setState(() => _isSubmitting = false);

        saveResult.when(
          success: (_) => _showSuccessDialog(order.bookingReference ?? order.orderId),
          failure: (message) {
            _showSuccessDialog(
              order.bookingReference ?? order.orderId,
              extraNote: _t3(
                context,
                ar: 'ملحوظة: الحجز تم بنجاح عند شركة الطيران، لكن حصل خطأ بسيط في حفظ نسخة عندنا: $message',
                en: "Note: the airline confirmed your booking, but we couldn't save a copy on our side: $message",
                es: 'Nota: la reserva se confirmó con la aerolínea, pero no pudimos guardar una copia: $message',
              ),
            );
          },
        );
      },
      failure: (message) {
        setState(() {
          _isSubmitting = false;
          _errorMessage = message;
        });
        return Future.value();
      },
    );
  }

  void _showSuccessDialog(String reference, {String? extraNote}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.check_circle, color: AppColors.success, size: 48),
        title: Text(_t3(context, ar: 'تم تأكيد الحجز!', en: 'Booking confirmed!', es: '¡Reserva confirmada!')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _t3(context, ar: 'رقم الحجز: $reference', en: 'Booking reference: $reference', es: 'Referencia: $reference'),
              textAlign: TextAlign.center,
            ),
            if (extraNote != null) ...[
              const SizedBox(height: AppSizes.sm),
              Text(extraNote, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12)),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.pop();
            },
            child: Text(_t3(context, ar: 'حسنًا', en: 'OK', es: 'Aceptar')),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final offer = widget.offer;

    return Scaffold(
      appBar: const AppBanner(),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(AppSizes.md),
            children: [
              Text(
                _t3(context, ar: 'تأكيد حجز الرحلة', en: 'Confirm flight booking', es: 'Confirmar reserva de vuelo'),
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: AppSizes.md),
              // كارت تفاصيل الرحلة نفسها (شركة الطيران، الأوقات، المدة)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppSizes.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.flight_takeoff, size: 18, color: AppColors.textSecondary),
                          const SizedBox(width: 6),
                          Text(
                            '${offer.airline} · ${offer.flightNumber}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const Spacer(),
                          if (offer.nonstop)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppColors.divider,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                _t3(context, ar: 'بدون توقف', en: 'Nonstop', es: 'Sin escalas'),
                                style: const TextStyle(fontSize: 12),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: AppSizes.sm),
                      Row(
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${offer.departureTime.hour.toString().padLeft(2, '0')}:${offer.departureTime.minute.toString().padLeft(2, '0')}',
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                              Text(offer.originCity, style: const TextStyle(color: AppColors.textSecondary)),
                            ],
                          ),
                          Expanded(
                            child: Column(
                              children: [
                                Text(
                                      () {
                                    final d = offer.arrivalTime.difference(offer.departureTime);
                                    return '${d.inMinutes ~/ 60}h ${d.inMinutes % 60}m';
                                  }(),
                                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                ),
                                const Row(
                                  children: [
                                    Expanded(child: Divider()),
                                    Icon(Icons.flight, size: 14, color: AppColors.textSecondary),
                                    Expanded(child: Divider()),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '${offer.arrivalTime.hour.toString().padLeft(2, '0')}:${offer.arrivalTime.minute.toString().padLeft(2, '0')}',
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                              Text(offer.destinationCity, style: const TextStyle(color: AppColors.textSecondary)),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSizes.md),
              // كارت التفاصيل الإضافية بعناوين واضحة (زي شاشة حجز الطيران
              // القديمة): تاريخ السفر ودرجة السفر
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppSizes.md),
                  child: Column(
                    children: [
                      _DetailRow(
                        icon: Icons.calendar_today_outlined,
                        label: _t3(context, ar: 'تاريخ السفر', en: 'Travel date', es: 'Fecha de viaje'),
                        value:
                        '${offer.departureTime.year}-${offer.departureTime.month.toString().padLeft(2, '0')}-${offer.departureTime.day.toString().padLeft(2, '0')}',
                      ),
                      const Divider(),
                      _DetailRow(
                        icon: Icons.airline_seat_recline_normal,
                        label: _t3(context, ar: 'درجة السفر', en: 'Cabin class', es: 'Clase de cabina'),
                        value: offer.cabinClass,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSizes.md),
              // كارت تفصيل السعر بعنوان "الإجمالي" واضح
              Card(
                color: AppColors.background,
                child: Padding(
                  padding: const EdgeInsets.all(AppSizes.md),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              _t3(context, ar: 'سعر الرحلة', en: 'Flight price', es: 'Precio del vuelo'),
                            ),
                          ),
                          Text('${offer.totalAmount.toStringAsFixed(2)} ${offer.totalCurrency}'),
                        ],
                      ),
                      const Divider(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _t3(context, ar: 'الإجمالي', en: 'Total', es: 'Total'),
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          Text(
                            '${offer.totalAmount.toStringAsFixed(2)} ${offer.totalCurrency}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSizes.lg),
              for (var i = 0; i < _passengers.length; i++) ...[
                Text(
                  _t3(
                    context,
                    ar: 'بيانات المسافر ${i + 1}',
                    en: 'Passenger ${i + 1} details',
                    es: 'Datos del pasajero ${i + 1}',
                  ),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: AppSizes.sm),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _passengers[i].title,
                        decoration: InputDecoration(
                          labelText: _t3(context, ar: 'اللقب', en: 'Title', es: 'Título'),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'mr', child: Text('Mr')),
                          DropdownMenuItem(value: 'mrs', child: Text('Mrs')),
                          DropdownMenuItem(value: 'ms', child: Text('Ms')),
                          DropdownMenuItem(value: 'miss', child: Text('Miss')),
                        ],
                        onChanged: (v) => setState(() => _passengers[i].title = v ?? 'mr'),
                      ),
                    ),
                    const SizedBox(width: AppSizes.sm),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _passengers[i].gender,
                        decoration: InputDecoration(
                          labelText: _t3(context, ar: 'الجنس', en: 'Gender', es: 'Género'),
                        ),
                        items: [
                          DropdownMenuItem(value: 'm', child: Text(_t3(context, ar: 'ذكر', en: 'Male', es: 'Hombre'))),
                          DropdownMenuItem(value: 'f', child: Text(_t3(context, ar: 'أنثى', en: 'Female', es: 'Mujer'))),
                        ],
                        onChanged: (v) => setState(() => _passengers[i].gender = v ?? 'm'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSizes.sm),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _passengers[i].givenNameController,
                        decoration: InputDecoration(
                          labelText: _t3(context, ar: 'الاسم الأول', en: 'Given name', es: 'Nombre'),
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? _t3(context, ar: 'مطلوب', en: 'Required', es: 'Requerido')
                            : null,
                      ),
                    ),
                    const SizedBox(width: AppSizes.sm),
                    Expanded(
                      child: TextFormField(
                        controller: _passengers[i].familyNameController,
                        decoration: InputDecoration(
                          labelText: _t3(context, ar: 'اسم العائلة', en: 'Family name', es: 'Apellido'),
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? _t3(context, ar: 'مطلوب', en: 'Required', es: 'Requerido')
                            : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSizes.sm),
                GestureDetector(
                  onTap: () => _pickBirthDate(_passengers[i]),
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: _t3(context, ar: 'تاريخ الميلاد', en: 'Date of birth', es: 'Fecha de nacimiento'),
                      prefixIcon: const Icon(Icons.calendar_today_outlined, size: 18),
                    ),
                    child: Text(
                      _passengers[i].bornOn == null
                          ? _t3(context, ar: 'اختار تاريخ', en: 'Select a date', es: 'Elige una fecha')
                          : '${_passengers[i].bornOn!.year}-${_passengers[i].bornOn!.month.toString().padLeft(2, '0')}-${_passengers[i].bornOn!.day.toString().padLeft(2, '0')}',
                    ),
                  ),
                ),
                const SizedBox(height: AppSizes.sm),
                TextFormField(
                  controller: _passengers[i].emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: _t3(context, ar: 'البريد الإلكتروني', en: 'Email', es: 'Correo electrónico'),
                  ),
                  validator: (v) => (v == null || !v.contains('@'))
                      ? _t3(context, ar: 'بريد إلكتروني غير صحيح', en: 'Invalid email', es: 'Correo inválido')
                      : null,
                ),
                const SizedBox(height: AppSizes.sm),
                TextFormField(
                  controller: _passengers[i].phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    labelText: _t3(context, ar: 'رقم الجوال', en: 'Phone number', es: 'Teléfono'),
                    hintText: '+19784839704',
                    helperText: _t3(
                      context,
                      ar: 'لازم يبدأ بـ + وكود الدولة (مثال: +19784839704)',
                      en: 'Must start with + and the country code (e.g. +19784839704)',
                      es: 'Debe empezar con + y el código de país (ej. +19784839704)',
                    ),
                    helperMaxLines: 2,
                  ),
                  validator: (v) {
                    final value = v?.trim() ?? '';
                    if (value.isEmpty) {
                      return _t3(context, ar: 'مطلوب', en: 'Required', es: 'Requerido');
                    }
                    if (!RegExp(r'^\+[1-9]\d{7,14}$').hasMatch(value)) {
                      return _t3(
                        context,
                        ar: 'لازم يبدأ بـ + وكود الدولة، من غير مسافات (مثال: +19784839704)',
                        en: 'Must start with + and country code, no spaces (e.g. +19784839704)',
                        es: 'Debe empezar con + y código de país, sin espacios (ej. +19784839704)',
                      );
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppSizes.lg),
              ],
              if (_errorMessage != null) ...[
                Text(
                  _errorMessage!,
                  style: const TextStyle(color: AppColors.error),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSizes.md),
              ],
              ElevatedButton(
                onPressed: _isSubmitting ? null : _confirmBooking,
                child: _isSubmitting
                    ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
                    : Text(_t3(context, ar: 'تأكيد الحجز', en: 'Confirm booking', es: 'Confirmar reserva')),
              ),
              const SizedBox(height: AppSizes.sm),
              Text(
                _t3(
                  context,
                  ar: 'هذا حجز حقيقي في بيئة اختبار Duffel — لن يتم خصم أي مبلغ فعلي',
                  en: 'This is a real booking in the Duffel test environment — no real charge will occur',
                  es: 'Esta es una reserva real en el entorno de prueba de Duffel — no se realizará ningún cargo',
                ),
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textHint, fontSize: 12),
              ),
              const AppFooter(),
            ],
          ),
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.textSecondary),
          const SizedBox(width: AppSizes.sm),
          Expanded(child: Text(label)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}