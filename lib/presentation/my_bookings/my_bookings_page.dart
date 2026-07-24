import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/error_view.dart';
import '../../core/widgets/loading_view.dart';
import '../../core/widgets/empty_view.dart';
import '../../data/models/booking_model.dart';
import '../../localization/app_localizations.dart';
import '../booking/booking_page.dart' show bookingRepositoryProvider;

final myBookingsProvider = FutureProvider<List<BookingModel>>((ref) async {
  final repo = ref.watch(bookingRepositoryProvider);
  final result = await repo.getMyBookings();

  return result.when(
    success: (bookings) => bookings,
    failure: (message) => throw Exception(message),
  );
});

class MyBookingsPage extends ConsumerWidget {
  const MyBookingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final bookingsAsync = ref.watch(myBookingsProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.myBookings)),
      body: bookingsAsync.when(
        loading: () => LoadingView(message: l10n.loadingBookings),
        error: (error, _) => ErrorView(
          message: l10n.errorLoadBookings,
          onRetry: () => ref.invalidate(myBookingsProvider),
        ),
        data: (bookings) {
          if (bookings.isEmpty) {
            return EmptyView(
              message: l10n.noBookingsYet,
              icon: Icons.receipt_long_outlined,
            );
          }
          return RefreshIndicator(
            onRefresh: () => ref.refresh(myBookingsProvider.future),
            child: ListView.builder(
              padding: const EdgeInsets.all(AppSizes.md),
              itemCount: bookings.length,
              itemBuilder: (context, index) =>
                  _BookingCard(booking: bookings[index]),
            ),
          );
        },
      ),
    );
  }
}

class _BookingCard extends ConsumerStatefulWidget {
  final BookingModel booking;
  const _BookingCard({required this.booking});

  @override
  ConsumerState<_BookingCard> createState() => _BookingCardState();
}

class _BookingCardState extends ConsumerState<_BookingCard> {
  bool _isCancelling = false;

  Color get _statusColor {
    switch (widget.booking.status) {
      case 'confirmed':
        return AppColors.success;
      case 'cancelled':
        return AppColors.error;
      default:
        return AppColors.warning;
    }
  }

  String _statusLabel(AppLocalizations l10n) {
    switch (widget.booking.status) {
      case 'confirmed':
        return l10n.statusConfirmed;
      case 'cancelled':
        return l10n.statusCancelled;
      default:
        return l10n.statusPending;
    }
  }

  bool get _canCancel =>
      widget.booking.status == 'pending' || widget.booking.status == 'confirmed';

  Future<void> _confirmAndCancel() async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.cancelBookingConfirmTitle),
        content: Text(widget.booking.hotelName ?? ''),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancelBookingUndo),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.cancelBookingYes, style: const TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isCancelling = true);

    final repo = ref.read(bookingRepositoryProvider);
    final result = await repo.cancelBooking(widget.booking.id);

    if (!mounted) return;

    result.when(
      success: (_) {
        ref.invalidate(myBookingsProvider);
      },
      failure: (message) {
        setState(() => _isCancelling = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message), backgroundColor: AppColors.error),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final booking = widget.booking;

    return Card(
      margin: const EdgeInsets.only(bottom: AppSizes.md),
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: AppColors.divider,
                    borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                    image: (booking.hotelImages?.isNotEmpty ?? false)
                        ? DecorationImage(
                      image: NetworkImage(booking.hotelImages!.first),
                      fit: BoxFit.cover,
                      onError: (_, __) {},
                    )
                        : null,
                  ),
                  child: (booking.hotelImages?.isEmpty ?? true)
                      ? const Icon(Icons.hotel, color: AppColors.textHint)
                      : null,
                ),
                const SizedBox(width: AppSizes.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        booking.hotelName ?? '',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      if (booking.hotelCity != null)
                        Text(
                          booking.hotelCity!,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _statusColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                  ),
                  child: Text(
                    _statusLabel(l10n),
                    style: TextStyle(
                      color: _statusColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: AppSizes.lg),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${Formatters.date(booking.checkIn)} - ${Formatters.date(booking.checkOut)}',
                  style: const TextStyle(fontSize: 13),
                ),
                Text(
                  Formatters.currency(booking.totalPrice),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),

            if (_canCancel) ...[
              const SizedBox(height: AppSizes.sm),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: _isCancelling ? null : _confirmAndCancel,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.error,
                    side: const BorderSide(color: AppColors.error),
                  ),
                  child: _isCancelling
                      ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                      : Text(l10n.cancelBooking),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}