import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../core/widgets/price_text.dart';
import '../../core/widgets/app_footer.dart';
import '../../core/widgets/app_banner.dart';
import '../../data/models/flight_model.dart';
import '../../data/repositories/flight_booking_repository.dart';
import '../booking/booking_page.dart' show paymentServiceProvider;
import '../../localization/app_localizations.dart';

final flightBookingRepositoryProvider = Provider((ref) => FlightBookingRepository());

/// Stripe غير مدعوم حاليًا إلا على Android/iOS (وWeb إن تم إعداده لاحقًا).
/// على أنظمة سطح المكتب نتخطى الدفع الفعلي مؤقتًا ونسجّل الحجز بحالة
/// "قيد الانتظار" ليتم إتمام الدفع لاحقًا من جهاز مدعوم.
bool get _isStripeSupportedPlatform {
  if (kIsWeb) return true;
  return defaultTargetPlatform == TargetPlatform.android ||
      defaultTargetPlatform == TargetPlatform.iOS;
}

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

class FlightBookingPage extends ConsumerStatefulWidget {
  final FlightModel flight;
  final DateTime travelDate;
  final int travelers;

  const FlightBookingPage({
    super.key,
    required this.flight,
    required this.travelDate,
    required this.travelers,
  });

  @override
  ConsumerState<FlightBookingPage> createState() => _FlightBookingPageState();
}

class _FlightBookingPageState extends ConsumerState<FlightBookingPage> {
  bool _isSubmitting = false;
  String? _errorMessage;

  double get _totalPrice => widget.flight.price * widget.travelers;

  Future<void> _confirmBooking() async {
    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    if (!_isStripeSupportedPlatform) {
      await _createBooking(status: 'pending');
      return;
    }

    final paymentService = ref.read(paymentServiceProvider);
    final paymentResult = await paymentService.pay(amount: _totalPrice);

    if (!mounted) return;

    final paymentSucceeded = paymentResult.when(
      success: (_) => true,
      failure: (message) {
        setState(() {
          _isSubmitting = false;
          _errorMessage = message;
        });
        return false;
      },
    );

    if (!paymentSucceeded) return;

    await _createBooking(status: 'confirmed');
  }

  Future<void> _createBooking({required String status}) async {
    final repo = ref.read(flightBookingRepositoryProvider);
    final result = await repo.createFlightBooking(
      flightNumber: widget.flight.flightNumber,
      airline: widget.flight.airline,
      originCity: widget.flight.originCity,
      destinationCity: widget.flight.destinationCity,
      departureTime: widget.flight.departureTime,
      arrivalTime: widget.flight.arrivalTime,
      cabinClass: widget.flight.cabinClass,
      travelers: widget.travelers,
      totalPrice: _totalPrice,
      status: status,
    );

    if (!mounted) return;

    result.when(
      success: (_) {
        setState(() => _isSubmitting = false);
        _showSuccessDialog();
      },
      failure: (message) {
        setState(() {
          _isSubmitting = false;
          _errorMessage = status == 'confirmed'
              ? _t3(
            context,
            ar: 'تم الدفع بنجاح، لكن حدث خطأ أثناء تسجيل الحجز: $message',
            en: 'Payment succeeded, but an error occurred while saving the booking: $message',
            es: 'El pago se realizó, pero ocurrió un error al guardar la reserva: $message',
          )
              : _t3(
            context,
            ar: 'حدث خطأ أثناء تسجيل الحجز: $message',
            en: 'An error occurred while saving the booking: $message',
            es: 'Ocurrió un error al guardar la reserva: $message',
          );
        });
      },
    );
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.check_circle, color: AppColors.success, size: 48),
        title: Text(_t3(context, ar: 'تم تأكيد الحجز!', en: 'Booking confirmed!', es: '¡Reserva confirmada!')),
        content: Text(
          '${widget.flight.airline} · ${widget.flight.flightNumber}',
          textAlign: TextAlign.center,
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

  String _formatTime(DateTime t) {
    final h = t.hour.toString().padLeft(2, '0');
    final m = t.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  String _formatDate(DateTime d) {
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final flight = widget.flight;
    final hours = flight.duration.inMinutes ~/ 60;
    final minutes = flight.duration.inMinutes % 60;

    return Scaffold(
      appBar: const AppBanner(),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSizes.md),
          children: [
            Text(
              _t3(context, ar: 'تأكيد حجز الرحلة', en: 'Confirm flight booking', es: 'Confirmar reserva de vuelo'),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppSizes.md),
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
                          '${flight.airline} · ${flight.flightNumber}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
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
                              _formatTime(flight.departureTime),
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            Text(flight.originCity, style: const TextStyle(color: AppColors.textSecondary)),
                          ],
                        ),
                        Expanded(
                          child: Column(
                            children: [
                              Text(
                                '${hours}h ${minutes}m',
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
                              _formatTime(flight.arrivalTime),
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            Text(flight.destinationCity, style: const TextStyle(color: AppColors.textSecondary)),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSizes.md),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppSizes.md),
                child: Column(
                  children: [
                    _DetailRow(
                      icon: Icons.calendar_today_outlined,
                      label: _t3(context, ar: 'تاريخ السفر', en: 'Travel date', es: 'Fecha de viaje'),
                      value: _formatDate(widget.travelDate),
                    ),
                    const Divider(),
                    _DetailRow(
                      icon: Icons.airline_seat_recline_normal,
                      label: _t3(context, ar: 'درجة السفر', en: 'Cabin class', es: 'Clase de cabina'),
                      value: flight.cabinClass,
                    ),
                    const Divider(),
                    _DetailRow(
                      icon: Icons.people_outline,
                      label: _t3(context, ar: 'عدد المسافرين', en: 'Travelers', es: 'Viajeros'),
                      value: '${widget.travelers}',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSizes.md),
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
                            '${_t3(context, ar: 'سعر الرحلة', en: 'Flight price', es: 'Precio del vuelo')} × ${widget.travelers}',
                          ),
                        ),
                        PriceText(sarAmount: _totalPrice),
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
                        PriceText(
                          sarAmount: _totalPrice,
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
            if (_errorMessage != null) ...[
              const SizedBox(height: AppSizes.md),
              Text(
                _errorMessage!,
                style: const TextStyle(color: AppColors.error),
                textAlign: TextAlign.center,
              ),
            ],
            const SizedBox(height: AppSizes.lg),
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
                ar: 'لن يتم خصم أي مبلغ إلا بعد تأكيد الدفع بنجاح',
                en: "You won't be charged until payment is successfully confirmed",
                es: 'No se te cobrará hasta que el pago se confirme con éxito',
              ),
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textHint, fontSize: 12),
            ),
            const AppFooter(),
          ],
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