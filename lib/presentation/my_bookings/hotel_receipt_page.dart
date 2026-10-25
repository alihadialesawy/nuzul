import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../data/models/booking_model.dart';

/// إيصال الدفع للعميل (منفصل عن القسيمة).
///
/// القسيمة (Voucher) يعرضها النزيل على الفندق، فلا يظهر فيها السعر.
/// الإيصال للعميل وحده: المبلغ المدفوع، والرسوم التي تُدفع في الفندق،
/// والاسترداد إن أُلغي الحجز.
///
/// ⚠️ لا نعرض مبلغ ضريبة مفصّلًا: HotelBeds لا ترسل تفصيل الضرائب في أغلب
/// الحجوزات، واحتساب ضريبة الإقامة على هامش الربح ما زال قيد المراجعة مع
/// المحاسب. الصيغة المعتمدة: "Total includes taxes and fees".
class HotelReceiptPage extends StatelessWidget {
  final BookingModel booking;
  const HotelReceiptPage({super.key, required this.booking});

  static String _usd(double v) => '\$${v.toStringAsFixed(2)} USD';

  static String _date(DateTime d) {
    const m = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${m[d.month - 1]} ${d.day}, ${d.year}';
  }

  static String _title(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1).toLowerCase();

  @override
  Widget build(BuildContext context) {
    final b = booking;
    final paid = b.chargeAmount ?? 0;
    final cancelled = b.status == 'cancelled';
    final refund = b.refundAmount ?? 0;
    final nights = b.checkOut.difference(b.checkIn).inDays;

    return Scaffold(
      appBar: AppBar(title: const Text('Receipt')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSizes.md),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: Column(
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSizes.lg),
                      child: SelectionArea(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // ── الرأس ──
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Image.asset(
                                        'assets/images/logo_flynoom_dark.png',
                                        height: 40,
                                        alignment: AlignmentDirectional.centerStart,
                                        filterQuality: FilterQuality.high,
                                        errorBuilder: (_, __, ___) => const Text(
                                          'FLYNOOM',
                                          style: TextStyle(
                                            fontSize: 22,
                                            fontWeight: FontWeight.w900,
                                            letterSpacing: 2,
                                            color: AppColors.primary,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      const Text('Payment receipt',
                                          style: TextStyle(color: AppColors.textSecondary)),
                                    ],
                                  ),
                                ),
                                if (cancelled)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      border: Border.all(color: AppColors.error),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: const Text('CANCELLED',
                                        style: TextStyle(
                                            color: AppColors.error, fontWeight: FontWeight.bold)),
                                  ),
                              ],
                            ),
                            const Divider(height: AppSizes.xl),

                            // ── المراجع ──
                            if (b.clientReference != null) _Row('Flynoom reference', b.clientReference!),
                            if (b.supplierReference != null) _Row('Booking reference', b.supplierReference!),
                            if (b.createdAt != null) _Row('Payment date', _date(b.createdAt!.toLocal())),
                            _Row('Paid by', b.holderFullName),
                            if ((b.holderEmail ?? '').isNotEmpty) _Row('Email', b.holderEmail!),

                            const SizedBox(height: AppSizes.md),
                            const _Section('Stay'),
                            _Row('Hotel', b.hotelName ?? ''),
                            _Row('Dates', '${_date(b.checkIn)} – ${_date(b.checkOut)}'),
                            _Row('Nights', '$nights'),
                            if ((b.roomName ?? '').isNotEmpty)
                              _Row('Room', [b.roomName, b.boardName]
                                  .where((s) => (s ?? '').isNotEmpty)
                                  .join(' · ')),

                            // ── المبالغ ──
                            const SizedBox(height: AppSizes.md),
                            const _Section('Payment'),
                            _AmountRow('Total paid online', _usd(paid), bold: true),
                            const Padding(
                              padding: EdgeInsets.only(bottom: 6),
                              child: Text(
                                'Includes taxes and fees collected by Flynoom.',
                                style: TextStyle(fontSize: 12, color: AppColors.textHint),
                              ),
                            ),
                            if (cancelled) ...[
                              _AmountRow(
                                'Cancellation fee',
                                _usd(b.cancellationFee ?? (paid - refund).clamp(0, paid).toDouble()),
                              ),
                              _AmountRow('Refunded to your card', _usd(refund),
                                  color: refund > 0 ? AppColors.success : null),
                              if (b.cancelledAt != null)
                                Text('Cancelled on ${_date(b.cancelledAt!.toLocal())}',
                                    style: const TextStyle(fontSize: 12, color: AppColors.textHint)),
                            ],

                            if (b.payAtHotelFees.isNotEmpty) ...[
                              const SizedBox(height: AppSizes.md),
                              const _Section('Payable at the hotel'),
                              for (final f in b.payAtHotelFees)
                                _AmountRow(
                                  _title((f['type'] ?? 'Fee').toString()),
                                  '${((f['amount'] as num?) ?? 0).toStringAsFixed(2)} ${f['currency'] ?? ''}',
                                ),
                              const Text(
                                'Not included in the amount paid online. Paid directly to the hotel.',
                                style: TextStyle(fontSize: 12, color: AppColors.textHint),
                              ),
                            ],

                            const Divider(height: AppSizes.xl),
                            const Text(
                              'FLYNOOM LLC · Michigan, USA · flynoom.com · support@flynoom.com\n'
                                  'The charge appears on your card statement as FLYNOOM.',
                              style: TextStyle(fontSize: 12, color: AppColors.textHint, height: 1.5),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSizes.sm),
                  const Text(
                    'Tip: on the website, press Ctrl+P to print or save this receipt as PDF.',
                    style: TextStyle(fontSize: 12, color: AppColors.textHint),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String text;
  const _Section(this.text);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Text(text.toUpperCase(),
        style: const TextStyle(
            fontSize: 12,
            letterSpacing: 1,
            fontWeight: FontWeight.w700,
            color: AppColors.textSecondary)),
  );
}

class _Row extends StatelessWidget {
  final String label;
  final String value;
  const _Row(this.label, this.value);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 3),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 150,
          child: Text(label, style: const TextStyle(color: AppColors.textSecondary)),
        ),
        Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w500))),
      ],
    ),
  );
}

class _AmountRow extends StatelessWidget {
  final String label;
  final String amount;
  final bool bold;
  final Color? color;
  const _AmountRow(this.label, this.amount, {this.bold = false, this.color});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 3),
    child: Row(
      children: [
        Expanded(child: Text(label)),
        Text(amount,
            style: TextStyle(
              fontWeight: bold ? FontWeight.bold : FontWeight.w500,
              fontSize: bold ? 16 : 14,
              color: color,
            )),
      ],
    ),
  );
}