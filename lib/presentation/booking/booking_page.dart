import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/hotel_model.dart';
import '../../data/repositories/booking_repository.dart';
import '../../localization/app_localizations.dart';

final bookingRepositoryProvider = Provider((ref) => BookingRepository());

class BookingPage extends ConsumerStatefulWidget {
  final HotelModel hotel;
  final DateTime checkIn;
  final DateTime checkOut;
  final int guests;

  const BookingPage({
    super.key,
    required this.hotel,
    required this.checkIn,
    required this.checkOut,
    required this.guests,
  });

  @override
  ConsumerState<BookingPage> createState() => _BookingPageState();
}

class _BookingPageState extends ConsumerState<BookingPage> {
  bool _isSubmitting = false;
  String? _errorMessage;

  int get _nights => widget.checkOut.difference(widget.checkIn).inDays;
  double get _totalPrice => widget.hotel.pricePerNight * _nights;

  Future<void> _confirmBooking() async {
    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    final repo = ref.read(bookingRepositoryProvider);
    final result = await repo.createBooking(
      hotelId: widget.hotel.id,
      roomId: 'default',
      checkIn: widget.checkIn,
      checkOut: widget.checkOut,
      guests: widget.guests,
      totalPrice: _totalPrice,
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
          _errorMessage = message;
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

    return Scaffold(
      appBar: AppBar(title: Text(l10n.confirmBookingTitle)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSizes.md),
          children: [
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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('${widget.hotel.pricePerNight.toStringAsFixed(0)} × $_nights'),
                        Text(Formatters.currency(_totalPrice)),
                      ],
                    ),
                    const Divider(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          l10n.totalLabel,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        Text(
                          Formatters.currency(_totalPrice),
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