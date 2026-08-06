import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/price_text.dart';
import '../../core/widgets/app_footer.dart';
import '../../core/widgets/app_banner.dart';
import '../../data/models/hotel_model.dart';
import '../../data/models/selected_room.dart';
import '../../data/repositories/booking_repository.dart';
import '../../core/services/payment_service.dart';
import '../../localization/app_localizations.dart';

final bookingRepositoryProvider = Provider((ref) => BookingRepository());
final paymentServiceProvider = Provider((ref) => PaymentService());

/// Stripe غير مدعوم حاليًا إلا على Android/iOS (وWeb إن تم إعداده لاحقًا).
/// على أنظمة سطح المكتب (Windows/macOS/Linux) نتخطى الدفع الفعلي مؤقتًا
/// ونسجّل الحجز بحالة "قيد الانتظار" ليتم إتمام الدفع لاحقًا من جهاز مدعوم.
bool get _isStripeSupportedPlatform {
  if (kIsWeb) return true;
  return defaultTargetPlatform == TargetPlatform.android ||
      defaultTargetPlatform == TargetPlatform.iOS;
}

class BookingPage extends ConsumerStatefulWidget {
  final HotelModel hotel;
  final DateTime checkIn;
  final DateTime checkOut;
  final int guests;

  /// أنواع الغرف المختارة مع كمية كل نوع (يدعم اختيار أكتر من نوع غرفة
  /// في نفس الحجز). لو القائمة فاضية أو لم تُمرَّر، يُستخدم السعر
  /// الأساسي للفندق كنوع غرفة افتراضي بكمية 1.
  final List<SelectedRoom>? selectedRooms;

  const BookingPage({
    super.key,
    required this.hotel,
    required this.checkIn,
    required this.checkOut,
    required this.guests,
    this.selectedRooms,
  });

  @override
  ConsumerState<BookingPage> createState() => _BookingPageState();
}

class _BookingPageState extends ConsumerState<BookingPage> {
  bool _isSubmitting = false;
  String? _errorMessage;

  int get _nights => widget.checkOut.difference(widget.checkIn).inDays;

  List<SelectedRoom> get _rooms =>
      (widget.selectedRooms != null && widget.selectedRooms!.isNotEmpty)
          ? widget.selectedRooms!
          : [
        SelectedRoom(
          label: '',
          pricePerNight: widget.hotel.pricePerNight,
          quantity: 1,
        ),
      ];

  double get _subtotalPerNight =>
      _rooms.fold(0, (sum, room) => sum + room.subtotalPerNight);

  double get _totalPrice => _subtotalPerNight * _nights;

  Future<void> _confirmBooking() async {
    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    // على المنصات غير المدعومة من Stripe (سطح المكتب حاليًا)، نتخطى
    // خطوة الدفع الفعلي ونسجّل الحجز مباشرة بحالة "قيد الانتظار".
    if (!_isStripeSupportedPlatform) {
      await _createBooking(status: 'pending');
      return;
    }

    // 1. نفّذ الدفع الفعلي أولاً عبر Stripe قبل أي تسجيل بقاعدة البيانات
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

    // 2. الدفع نجح فعليًا -> سجّل الحجز بحالة "مؤكد" مباشرة
    await _createBooking(status: 'confirmed');
  }

  Future<void> _createBooking({required String status}) async {
    final repo = ref.read(bookingRepositoryProvider);
    final result = await repo.createBooking(
      hotelId: widget.hotel.id,
      roomId: 'default',
      checkIn: widget.checkIn,
      checkOut: widget.checkOut,
      guests: widget.guests,
      totalPrice: _totalPrice,
      status: status,
    );

    if (!mounted) return;

    result.when(
      success: (booking) {
        setState(() => _isSubmitting = false);
        _showSuccessDialog();
      },
      failure: (message) {
        setState(() {
          _isSubmitting = false;
          _errorMessage = status == 'confirmed'
          // الدفع نجح فعليًا بس فشل تسجيل الحجز -- رسالة توضح الوضع
              ? 'تم الدفع بنجاح، لكن حدث خطأ أثناء تسجيل الحجز: $message'
              : 'حدث خطأ أثناء تسجيل الحجز: $message';
        });
      },
    );
  }

  void _showSuccessDialog() {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.check_circle, color: AppColors.success, size: 48),
        title: Text(l10n.bookingSuccessTitle),
        content: Text(
          '${widget.hotel.name}',
          textAlign: TextAlign.center,
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.pop();
            },
            child: Text(l10n.ok),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final rooms = _rooms;

    return Scaffold(
      appBar: const AppBanner(),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSizes.md),
          children: [
            Text(
              l10n.confirmBookingTitle,
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
                        image: widget.hotel.images.isNotEmpty
                            ? DecorationImage(
                          image: NetworkImage(widget.hotel.images.first),
                          fit: BoxFit.cover,
                          onError: (_, __) {},
                        )
                            : null,
                      ),
                      child: widget.hotel.images.isEmpty
                          ? const Icon(Icons.hotel, color: AppColors.textHint)
                          : null,
                    ),
                    const SizedBox(width: AppSizes.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.hotel.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.hotel.city,
                            style: const TextStyle(color: AppColors.textSecondary),
                          ),
                          // عرض كل أنواع الغرف المختارة مع كمياتها
                          for (final room in rooms)
                            if (room.label.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  '${room.quantity} × ${room.label}',
                                  style: const TextStyle(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                  ),
                                ),
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
                      icon: Icons.calendar_today_outlined,
                      label: l10n.checkInLabel,
                      value: Formatters.date(widget.checkIn),
                    ),
                    const Divider(),
                    _DetailRow(
                      icon: Icons.calendar_today_outlined,
                      label: l10n.checkOutLabel,
                      value: Formatters.date(widget.checkOut),
                    ),
                    const Divider(),
                    _DetailRow(
                      icon: Icons.nights_stay_outlined,
                      label: l10n.nightsLabel,
                      value: Formatters.nights(widget.checkIn, widget.checkOut),
                    ),
                    const Divider(),
                    _DetailRow(
                      icon: Icons.people_outline,
                      label: l10n.guestsLabel,
                      value: '${widget.guests}',
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
                    // سطر سعر منفصل لكل نوع غرفة مختار (لو أكتر من نوع)
                    for (final room in rooms)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                room.label.isNotEmpty
                                    ? '${room.label} × ${room.quantity} × $_nights'
                                    : '×$_nights',
                              ),
                            ),
                            PriceText(sarAmount: room.subtotalPerNight * _nights),
                          ],
                        ),
                      ),
                    const Divider(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          l10n.totalLabel,
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
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
                  : Text(l10n.confirmBookingButton),
            ),

            const SizedBox(height: AppSizes.sm),
            Text(
              l10n.paymentNote,
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