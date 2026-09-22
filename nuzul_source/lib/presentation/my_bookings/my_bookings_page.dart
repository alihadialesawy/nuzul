import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/error_view.dart';
import '../../core/widgets/loading_view.dart';
import '../../core/widgets/empty_view.dart';
import '../../data/models/inbox_item_model.dart';
import '../../data/repositories/inbox_repository.dart';
import '../../localization/app_localizations.dart';
import '../booking/booking_page.dart' show bookingRepositoryProvider;

final inboxRepositoryProvider = Provider((ref) => InboxRepository());

/// المصدر الموحّد لكل الحجوزات (فنادق + طيران عبر Duffel + سيارات) --
/// نفس المصدر بالضبط المستخدم في شاشة Inbox، بدل جدول bookings المحلي
/// وحده (اللي كان بيفوّت حجوزات الطيران الحقيقية تمامًا).
final myBookingsProvider = FutureProvider<List<InboxItemModel>>((ref) async {
  final repo = ref.watch(inboxRepositoryProvider);
  final result = await repo.fetchInboxItems();

  return result.when(
    success: (items) => items
        .where((item) =>
    item.type == InboxItemType.hotelBooking ||
        item.type == InboxItemType.flightBooking ||
        item.type == InboxItemType.carBooking)
        .toList(),
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
        data: (items) {
          if (items.isEmpty) {
            return EmptyView(
              message: l10n.noBookingsYet,
              icon: Icons.receipt_long_outlined,
            );
          }
          return RefreshIndicator(
            onRefresh: () => ref.refresh(myBookingsProvider.future),
            child: ListView.builder(
              padding: const EdgeInsets.all(AppSizes.md),
              itemCount: items.length,
              itemBuilder: (context, index) => _BookingCard(item: items[index]),
            ),
          );
        },
      ),
    );
  }
}

class _BookingCard extends ConsumerStatefulWidget {
  final InboxItemModel item;
  const _BookingCard({required this.item});

  @override
  ConsumerState<_BookingCard> createState() => _BookingCardState();
}

class _BookingCardState extends ConsumerState<_BookingCard> {
  bool _isCancelling = false;

  Color get _statusColor {
    switch (widget.item.status) {
      case 'confirmed':
        return AppColors.success;
      case 'cancelled':
        return AppColors.error;
      default:
        return AppColors.warning;
    }
  }

  String _statusLabel(AppLocalizations l10n) {
    switch (widget.item.status) {
      case 'confirmed':
        return l10n.statusConfirmed;
      case 'cancelled':
        return l10n.statusCancelled;
      default:
        return l10n.statusPending;
    }
  }

  /// إلغاء الحجز متاح حاليًا لحجوزات الفنادق فقط (نفس السلوك القديم) --
  /// إلغاء رحلات Duffel محتاج تدفق منفصل عبر Duffel API مش مبني لسه.
  bool get _canCancel =>
      widget.item.type == InboxItemType.hotelBooking &&
          (widget.item.status == 'pending' || widget.item.status == 'confirmed');

  Future<void> _confirmAndCancel() async {
    final l10n = AppLocalizations.of(context)!;
    final booking = widget.item.hotelBooking;
    if (booking == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.cancelBookingConfirmTitle),
        content: Text(booking.hotelName ?? ''),
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
    final result = await repo.cancelBooking(booking.id);

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
    final item = widget.item;

    return Card(
      margin: const EdgeInsets.only(bottom: AppSizes.md),
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                _buildThumbnail(),
                const SizedBox(width: AppSizes.md),
                Expanded(child: _buildTitleColumn(context)),
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
            _buildDetailsRow(context),
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

  Widget _buildThumbnail() {
    final item = widget.item;

    if (item.type == InboxItemType.hotelBooking) {
      final images = item.hotelBooking?.hotelImages;
      return Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: AppColors.divider,
          borderRadius: BorderRadius.circular(AppSizes.radiusSm),
          image: (images?.isNotEmpty ?? false)
              ? DecorationImage(
            image: NetworkImage(images!.first),
            fit: BoxFit.cover,
            onError: (_, __) {},
          )
              : null,
        ),
        child: (images?.isEmpty ?? true)
            ? const Icon(Icons.hotel, color: AppColors.textHint)
            : null,
      );
    }

    final icon = item.type == InboxItemType.flightBooking
        ? Icons.flight_takeoff
        : Icons.directions_car;

    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: AppColors.divider,
        borderRadius: BorderRadius.circular(AppSizes.radiusSm),
      ),
      child: Icon(icon, color: AppColors.textHint),
    );
  }

  Widget _buildTitleColumn(BuildContext context) {
    final item = widget.item;

    if (item.type == InboxItemType.hotelBooking) {
      final booking = item.hotelBooking;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            booking?.hotelName ?? '',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
          if (booking?.hotelCity != null)
            Text(
              booking!.hotelCity!,
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
        ],
      );
    }

    if (item.type == InboxItemType.flightBooking) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            [item.airline, item.flightNumber].where((s) => s != null && s.isNotEmpty).join(' · '),
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
          if (item.originCity != null && item.destinationCity != null)
            Text(
              '${item.originCity} → ${item.destinationCity}',
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
        ],
      );
    }

    // carBooking
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          item.carName ?? '',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
        ),
        if (item.carCompany != null)
          Text(
            item.carCompany!,
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
      ],
    );
  }

  Widget _buildDetailsRow(BuildContext context) {
    final item = widget.item;

    if (item.type == InboxItemType.hotelBooking) {
      final booking = item.hotelBooking;
      if (booking == null) return const SizedBox.shrink();
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '${Formatters.date(booking.checkIn)} - ${Formatters.date(booking.checkOut)}',
            style: const TextStyle(fontSize: 13),
          ),
          Text(
            Formatters.currency(booking.totalPrice),
            style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
          ),
        ],
      );
    }

    if (item.type == InboxItemType.flightBooking) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            item.departureTime != null ? Formatters.date(item.departureTime!) : '',
            style: const TextStyle(fontSize: 13),
          ),
        ],
      );
    }

    // carBooking
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          item.pickupCity ?? '',
          style: const TextStyle(fontSize: 13),
        ),
        Text(
          item.pickupDate != null ? Formatters.date(item.pickupDate!) : '',
          style: const TextStyle(fontSize: 13),
        ),
      ],
    );
  }
}