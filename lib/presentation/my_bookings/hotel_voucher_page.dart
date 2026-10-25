import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../data/models/booking_model.dart';

/// قسيمة حجز فندق HotelBeds.
///
/// المحتوى بالإنجليزية عمدًا: هي وثيقة يقدّمها النزيل لموظف الاستقبال.
/// تحتوي كل ما تشترطه HotelBeds في الـ Certification:
/// اسم الفندق وعنوانه، اسم صاحب الحجز، عدد النزلاء لكل غرفة وأعمار الأطفال،
/// رقم حجز HotelBeds، تاريخا الوصول والمغادرة، نوع الغرفة والوجبات،
/// ملاحظات السعر (rate comments)، وعبارة "Payable through ...".
class HotelVoucherPage extends StatelessWidget {
  final BookingModel booking;
  const HotelVoucherPage({super.key, required this.booking});

  static String _date(DateTime d) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return '${days[d.weekday - 1]}, ${months[d.month - 1]} ${d.day}, ${d.year}';
  }

  static String _title(String s) => s
      .toLowerCase()
      .split(' ')
      .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
      .join(' ');

  @override
  Widget build(BuildContext context) {
    final b = booking;
    final nights = b.checkOut.difference(b.checkIn).inDays;
    final rooms = b.voucherRooms;
    final cancelled = b.status == 'cancelled';
    final roomComments = rooms
        .map((r) => r.rateComments)
        .whereType<String>()
        .where((c) => c.trim().isNotEmpty)
        .toSet();
    final comments = roomComments.isNotEmpty
        ? roomComments.join('\n\n')
        : (b.rateComments ?? '');

    return Scaffold(
      appBar: AppBar(title: const Text('Booking voucher')),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: ListView(
              padding: const EdgeInsets.all(AppSizes.md),
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
                              const Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // شعار بنص داكن (FLY كحلي) للخلفيات البيضاء.
                                    // لو لم يوجد الملف يظهر الاسم نصًا كما كان.
                                    _VoucherLogo(),
                                    SizedBox(height: 4),
                                    Text('Hotel booking voucher',
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
                          const Divider(height: AppSizes.lg * 2),

                          _Field('Booking reference', b.supplierReference ?? '—', big: true, copy: true),
                          if (b.clientReference != null)
                            _Field('Flynoom reference', b.clientReference!),
                          if (cancelled && b.cancellationReference != null)
                            _Field('Cancellation reference', b.cancellationReference!),

                          const SizedBox(height: AppSizes.md),
                          _Section('Hotel'),
                          Text(b.hotelName ?? '',
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          if (b.hotelAddress != null) Text(b.hotelAddress!),
                          if (b.hotelAddress == null && b.hotelCity != null) Text(b.hotelCity!),
                          if (b.hotelPhone != null) Text('Phone: ${b.hotelPhone}'),

                          const SizedBox(height: AppSizes.md),
                          _Section('Stay'),
                          _Field('Check-in', _date(b.checkIn)),
                          _Field('Check-out', _date(b.checkOut)),
                          _Field('Nights', '$nights'),
                          _Field('Lead guest', b.holderFullName.isNotEmpty ? b.holderFullName : '—'),

                          const SizedBox(height: AppSizes.md),
                          _Section('Rooms'),
                          if (rooms.isEmpty)
                            _Field(
                              'Room',
                              [
                                if (b.roomName != null) _title(b.roomName!),
                                if (b.boardName != null) _title(b.boardName!),
                              ].join(' · '),
                            ),
                          for (var i = 0; i < rooms.length; i++)
                            Padding(
                              padding: const EdgeInsets.only(bottom: AppSizes.sm),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${rooms[i].rooms} × ${_title(rooms[i].name)}',
                                    style: const TextStyle(fontWeight: FontWeight.w600),
                                  ),
                                  if (rooms[i].boardName != null)
                                    Text('Board: ${_title(rooms[i].boardName!)}'),
                                  Text(
                                    'Guests per room: ${rooms[i].adults} adult${rooms[i].adults == 1 ? '' : 's'}'
                                        '${rooms[i].children > 0 ? ', ${rooms[i].children} child${rooms[i].children == 1 ? '' : 'ren'}' : ''}'
                                        '${rooms[i].childAges.isNotEmpty ? ' (ages ${rooms[i].childAges.join(', ')})' : ''}',
                                  ),
                                ],
                              ),
                            ),

                          if (b.payAtHotelFees.isNotEmpty) ...[
                            const SizedBox(height: AppSizes.md),
                            _Section('Payable at the hotel'),
                            for (final f in b.payAtHotelFees)
                              Text(
                                '${_title((f['type'] ?? 'Fee').toString())}: '
                                    '${((f['amount'] as num?) ?? 0).toStringAsFixed(2)} ${f['currency'] ?? ''}',
                              ),
                            const Text(
                              'Mandatory fees not included in the amount paid online.',
                              style: TextStyle(fontSize: 12, color: AppColors.textHint),
                            ),
                          ],

                          if (comments.trim().isNotEmpty) ...[
                            const SizedBox(height: AppSizes.md),
                            _Section('Important information'),
                            Text(comments.trim(),
                                style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                          ],

                          const Divider(height: AppSizes.lg * 2),
                          // ── العبارة الإلزامية من HotelBeds ──
                          Text(
                            'Payable through ${b.supplierName ?? 'HOTELBEDS'}, acting as agent for the '
                                'service operating company, details of which can be provided upon request. '
                                'VAT: ${b.supplierVat ?? '—'} Reference: ${b.supplierReference ?? '—'}',
                            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                          ),
                          const SizedBox(height: AppSizes.sm),
                          const Text(
                            'Booked by FLYNOOM LLC · flynoom.com',
                            style: TextStyle(fontSize: 12, color: AppColors.textHint),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppSizes.sm),
                const Text(
                  'Tip: on the website, press Ctrl+P to print or save this voucher as PDF.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: AppColors.textHint),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  const _Section(this.title);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 4),
    child: Text(
      title.toUpperCase(),
      style: const TextStyle(
        fontSize: 12,
        letterSpacing: 1,
        fontWeight: FontWeight.bold,
        color: AppColors.textSecondary,
      ),
    ),
  );
}

class _Field extends StatelessWidget {
  final String label;
  final String value;
  final bool big;
  final bool copy;
  const _Field(this.label, this.value, {this.big = false, this.copy = false});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 2),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: 170,
          child: Text(label, style: const TextStyle(color: AppColors.textSecondary)),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: big ? 18 : 14,
            ),
          ),
        ),
        if (copy && value != '—')
          IconButton(
            tooltip: 'Copy',
            icon: const Icon(Icons.copy, size: 16),
            onPressed: () => Clipboard.setData(ClipboardData(text: value)),
          ),
      ],
    ),
  );
}

/// شعار Flynoom في رأس القسيمة. يُطبع أيضًا عند Ctrl+P / الحفظ كـ PDF.
class _VoucherLogo extends StatelessWidget {
  const _VoucherLogo();

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/images/logo_flynoom_dark.png',
      height: 40,
      fit: BoxFit.contain,
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
    );
  }
}