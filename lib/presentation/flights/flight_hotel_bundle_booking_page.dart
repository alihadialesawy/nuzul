import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../core/widgets/app_footer.dart';
import '../../core/widgets/app_banner.dart';
import '../../core/widgets/price_text.dart';
import '../../data/models/hotel_model.dart';
import '../../data/repositories/duffel_repository.dart';
import '../../data/repositories/duffel_booking_repository.dart';
import '../booking/booking_page.dart' show paymentServiceProvider, bookingRepositoryProvider;
import '../home/controllers/duffel_flight_search_controller.dart' show duffelRepositoryProvider;

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

final duffelBookingRepositoryProvider2 = Provider((ref) => DuffelBookingRepository());

bool get _isStripeSupportedPlatform {
  if (kIsWeb) return true;
  return defaultTargetPlatform == TargetPlatform.android ||
      defaultTargetPlatform == TargetPlatform.iOS;
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

/// صفحة حجز مجمّعة: بتحجز الرحلة (Duffel) والفندق مع بعض في خطوة واحدة
/// وبتعرض ملخص واحد للسعر الإجمالي بعد ما تخلص الاتنين بنجاح.
class FlightHotelBundleBookingPage extends ConsumerStatefulWidget {
  final DuffelFlightOffer offer;
  final HotelModel hotel;
  final DateTime checkIn;
  final DateTime checkOut;
  final int guests;

  const FlightHotelBundleBookingPage({
    super.key,
    required this.offer,
    required this.hotel,
    required this.checkIn,
    required this.checkOut,
    required this.guests,
  });

  @override
  ConsumerState<FlightHotelBundleBookingPage> createState() => _FlightHotelBundleBookingPageState();
}

class _FlightHotelBundleBookingPageState extends ConsumerState<FlightHotelBundleBookingPage> {
  final _formKey = GlobalKey<FormState>();
  late final List<_PassengerFormData> _passengers;
  bool _isSubmitting = false;
  String? _errorMessage;

  int get _nights => widget.checkOut.difference(widget.checkIn).inDays;
  double get _hotelTotal => widget.hotel.pricePerNight * _nights;

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
            content: Text(_t3(
              context,
              ar: 'من فضلك اختار تاريخ ميلاد كل مسافر',
              en: 'Please pick a birth date for every passenger',
              es: 'Elige la fecha de nacimiento de cada pasajero',
            )),
          ),
        );
        return;
      }
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    // 1. احجز الرحلة فعليًا عند Duffel أولاً
    final duffelRepo = ref.read(duffelRepositoryProvider);
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

    final orderResult = await duffelRepo.createOrder(
      offerId: widget.offer.id,
      totalAmount: widget.offer.totalAmount,
      totalCurrency: widget.offer.totalCurrency,
      passengers: passengerInfos,
    );

    if (!mounted) return;

    final flightBooked = orderResult.when(
      success: (_) => true,
      failure: (message) {
        setState(() {
          _isSubmitting = false;
          _errorMessage = _t3(
            context,
            ar: 'تعذر حجز الرحلة: $message',
            en: 'Could not book the flight: $message',
            es: 'No se pudo reservar el vuelo: $message',
          );
        });
        return false;
      },
    );

    if (!flightBooked) return;

    final order = orderResult.when(
      success: (o) => o,
      failure: (_) => (orderId: '', bookingReference: null),
    );

    // 2. سجّل نسخة حجز الرحلة عندنا
    final duffelBookingRepo = ref.read(duffelBookingRepositoryProvider2);
    await duffelBookingRepo.saveBooking(
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

    // 3. احجز الفندق (بنفس منطق الدفع المستخدم في حجز الفنادق العادي:
    // Stripe لو المنصة مدعومة، وإلا حالة "قيد الانتظار")
    String hotelStatus = 'pending';
    if (_isStripeSupportedPlatform) {
      final paymentService = ref.read(paymentServiceProvider);
      final paymentResult = await paymentService.pay(amount: _hotelTotal);
      final paid = paymentResult.when(success: (_) => true, failure: (_) => false);
      if (paid) hotelStatus = 'confirmed';
    }

    final hotelRepo = ref.read(bookingRepositoryProvider);
    final hotelResult = await hotelRepo.createBooking(
      hotelId: widget.hotel.id,
      roomId: 'default',
      checkIn: widget.checkIn,
      checkOut: widget.checkOut,
      guests: widget.guests,
      totalPrice: _hotelTotal,
      status: hotelStatus,
    );

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    hotelResult.when(
      success: (_) => _showSuccessDialog(order.bookingReference ?? order.orderId),
      failure: (message) => _showSuccessDialog(
        order.bookingReference ?? order.orderId,
        extraNote: _t3(
          context,
          ar: 'الرحلة اتحجزت بنجاح، لكن حصل خطأ في حجز الفندق: $message',
          en: 'The flight was booked successfully, but there was an error booking the hotel: $message',
          es: 'El vuelo se reservó con éxito, pero hubo un error al reservar el hotel: $message',
        ),
      ),
    );
  }

  void _showSuccessDialog(String flightReference, {String? extraNote}) {
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
              _t3(
                context,
                ar: 'رقم حجز الرحلة: $flightReference\nالفندق: ${widget.hotel.name}',
                en: 'Flight booking reference: $flightReference\nHotel: ${widget.hotel.name}',
                es: 'Referencia del vuelo: $flightReference\nHotel: ${widget.hotel.name}',
              ),
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
    final hotel = widget.hotel;
    final grandTotalNote = _t3(
      context,
      ar: 'السعرين منفصلين حاليًا (الرحلة بعملتها، الفندق بالريال) لحد ما نضيف تحويل عملات موحّد',
      en: "Prices are shown separately for now (flight in its own currency, hotel in SAR) until unified currency conversion is added",
      es: 'Los precios se muestran por separado por ahora (vuelo en su moneda, hotel en SAR)',
    );

    return Scaffold(
      appBar: const AppBanner(),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(AppSizes.md),
            children: [
              Text(
                _t3(context, ar: 'تأكيد حجز الرحلة والفندق', en: 'Confirm your flight + hotel booking', es: 'Confirmar vuelo y hotel'),
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: AppSizes.md),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppSizes.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.flight_takeoff, size: 18, color: AppColors.textSecondary),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              '${offer.airline} · ${offer.flightNumber}',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          Text('${offer.totalAmount.toStringAsFixed(2)} ${offer.totalCurrency}'),
                        ],
                      ),
                      Text(
                        '${offer.originCity} → ${offer.destinationCity}',
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                      ),
                      const Divider(height: AppSizes.lg),
                      Row(
                        children: [
                          const Icon(Icons.hotel_outlined, size: 18, color: AppColors.textSecondary),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(hotel.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                          ),
                          PriceText(sarAmount: _hotelTotal),
                        ],
                      ),
                      Text(
                        '${hotel.city} · $_nights ${_t3(context, ar: 'ليالي', en: 'nights', es: 'noches')}',
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                      ),
                      const SizedBox(height: 6),
                      Text(grandTotalNote, style: const TextStyle(fontSize: 11, color: AppColors.textHint)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSizes.lg),
              for (var i = 0; i < _passengers.length; i++) ...[
                Text(
                  _t3(context, ar: 'بيانات المسافر ${i + 1}', en: 'Passenger ${i + 1} details', es: 'Datos del pasajero ${i + 1}'),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: AppSizes.sm),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _passengers[i].title,
                        decoration: InputDecoration(labelText: _t3(context, ar: 'اللقب', en: 'Title', es: 'Título')),
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
                        decoration: InputDecoration(labelText: _t3(context, ar: 'الجنس', en: 'Gender', es: 'Género')),
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
                        decoration: InputDecoration(labelText: _t3(context, ar: 'الاسم الأول', en: 'Given name', es: 'Nombre')),
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? _t3(context, ar: 'مطلوب', en: 'Required', es: 'Requerido')
                            : null,
                      ),
                    ),
                    const SizedBox(width: AppSizes.sm),
                    Expanded(
                      child: TextFormField(
                        controller: _passengers[i].familyNameController,
                        decoration: InputDecoration(labelText: _t3(context, ar: 'اسم العائلة', en: 'Family name', es: 'Apellido')),
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
                  decoration: InputDecoration(labelText: _t3(context, ar: 'البريد الإلكتروني', en: 'Email', es: 'Correo electrónico')),
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
                      ar: 'لازم يبدأ بـ + وكود الدولة',
                      en: 'Must start with + and the country code',
                      es: 'Debe empezar con + y código de país',
                    ),
                  ),
                  validator: (v) {
                    final value = v?.trim() ?? '';
                    if (value.isEmpty) return _t3(context, ar: 'مطلوب', en: 'Required', es: 'Requerido');
                    if (!RegExp(r'^\+[1-9]\d{7,14}$').hasMatch(value)) {
                      return _t3(context, ar: 'صيغة غير صحيحة', en: 'Invalid format', es: 'Formato inválido');
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppSizes.lg),
              ],
              if (_errorMessage != null) ...[
                Text(_errorMessage!, style: const TextStyle(color: AppColors.error), textAlign: TextAlign.center),
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
                  ar: 'هذا حجز حقيقي للرحلة (بيئة اختبار Duffel)، والفندق هيتسجل عندنا فورًا',
                  en: 'This is a real flight booking (Duffel test environment); the hotel booking is saved immediately',
                  es: 'Esta es una reserva real de vuelo (entorno de prueba de Duffel); el hotel se guarda de inmediato',
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