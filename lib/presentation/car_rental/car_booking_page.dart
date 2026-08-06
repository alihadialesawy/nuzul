import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../core/widgets/price_text.dart';
import '../../core/widgets/app_footer.dart';
import '../../core/widgets/app_banner.dart';
import '../../data/models/car_model.dart';
import '../../data/repositories/car_booking_repository.dart';
import '../booking/booking_page.dart' show paymentServiceProvider;
import '../../localization/app_localizations.dart';

final carBookingRepositoryProvider = Provider((ref) => CarBookingRepository());

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

class CarBookingPage extends ConsumerStatefulWidget {
  final CarModel car;
  final String pickupCity;
  final DateTime pickupDate;
  final DateTime dropoffDate;

  const CarBookingPage({
    super.key,
    required this.car,
    required this.pickupCity,
    required this.pickupDate,
    required this.dropoffDate,
  });

  @override
  ConsumerState<CarBookingPage> createState() => _CarBookingPageState();
}

class _CarBookingPageState extends ConsumerState<CarBookingPage> {
  bool _isSubmitting = false;
  String? _errorMessage;

  int get _rentalDays {
    final days = widget.dropoffDate.difference(widget.pickupDate).inDays;
    return days < 1 ? 1 : days;
  }

  double get _totalPrice => widget.car.pricePerDay * _rentalDays;

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
    final repo = ref.read(carBookingRepositoryProvider);
    final result = await repo.createCarBooking(
      carName: widget.car.carName,
      company: widget.car.company,
      category: widget.car.category,
      pickupCity: widget.pickupCity,
      pickupDate: widget.pickupDate,
      dropoffDate: widget.dropoffDate,
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
        content: Text(widget.car.carName, textAlign: TextAlign.center),
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

  String _formatDate(DateTime d) {
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final car = widget.car;

    return Scaffold(
      appBar: const AppBanner(),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSizes.md),
          children: [
            Text(
              _t3(context, ar: 'تأكيد حجز السيارة', en: 'Confirm car booking', es: 'Confirmar reserva de coche'),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppSizes.md),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppSizes.md),
                child: Row(
                  children: [
                    Container(
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                        color: AppColors.divider,
                        borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                        image: car.imageUrl != null
                            ? DecorationImage(
                          image: NetworkImage(car.imageUrl!),
                          fit: BoxFit.cover,
                          onError: (_, __) {},
                        )
                            : null,
                      ),
                      child: car.imageUrl == null
                          ? const Icon(Icons.directions_car, color: AppColors.textHint)
                          : null,
                    ),
                    const SizedBox(width: AppSizes.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            car.carName,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${car.company} · ${car.category}',
                            style: const TextStyle(color: AppColors.textSecondary),
                          ),
                        ],
                      ),
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
                      icon: Icons.location_on_outlined,
                      label: _t3(context, ar: 'مكان الاستلام', en: 'Pick-up location', es: 'Lugar de recogida'),
                      value: widget.pickupCity,
                    ),
                    const Divider(),
                    _DetailRow(
                      icon: Icons.calendar_today_outlined,
                      label: _t3(context, ar: 'تاريخ الاستلام', en: 'Pick-up date', es: 'Fecha de recogida'),
                      value: _formatDate(widget.pickupDate),
                    ),
                    const Divider(),
                    _DetailRow(
                      icon: Icons.calendar_today_outlined,
                      label: _t3(context, ar: 'تاريخ التسليم', en: 'Drop-off date', es: 'Fecha de devolución'),
                      value: _formatDate(widget.dropoffDate),
                    ),
                    const Divider(),
                    _DetailRow(
                      icon: Icons.event_repeat_outlined,
                      label: _t3(context, ar: 'عدد الأيام', en: 'Rental days', es: 'Días de alquiler'),
                      value: '$_rentalDays',
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
                            '${_t3(context, ar: 'السعر لليوم', en: 'Price per day', es: 'Precio por día')} × $_rentalDays',
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