import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';

/// مكتب الحجوزات — حجوزات HotelBeds الحقيقية (جدول bookings حيث supplier = 'hotelbeds').
///
/// • القراءة: نفس صلاحية المدير المستخدمة في صفحة الحجوزات القديمة.
/// • الإلغاء نيابة عن العميل: عبر دالة hotelbeds-cancel فقط
///   (quote أولًا لعرض الرسوم والاسترداد، ثم confirm). الدالة تلغي عند
///   HotelBeds وتسترد عبر Stripe وترسل بريد الإلغاء للعميل.
/// • لا يوجد هنا أي تعديل يدوي للحالة — حالة هذه الحجوزات يحددها السيرفر فقط.
class AdminBookingDeskPage extends StatefulWidget {
  const AdminBookingDeskPage({super.key});

  @override
  State<AdminBookingDeskPage> createState() => _AdminBookingDeskPageState();
}

String _t(BuildContext context, {required String ar, required String en}) =>
    Localizations.localeOf(context).languageCode == 'ar' ? ar : en;

/// الفلاتر المعروضة. 'attempts' = محاولات لم تكتمل (awaiting_payment/failed).
const _filters = ['active', 'needs_attention', 'cancelled', 'attempts', 'all'];

String _filterLabel(BuildContext context, String f) {
  switch (f) {
    case 'active':
      return _t(context, ar: 'مؤكدة', en: 'Confirmed');
    case 'needs_attention':
      return _t(context, ar: 'تحتاج متابعة', en: 'Needs attention');
    case 'cancelled':
      return _t(context, ar: 'ملغاة', en: 'Cancelled');
    case 'attempts':
      return _t(context, ar: 'محاولات لم تكتمل', en: 'Incomplete attempts');
    default:
      return _t(context, ar: 'الكل', en: 'All');
  }
}

Color _statusColor(String s) {
  switch (s) {
    case 'confirmed':
      return const Color(0xFF00B894);
    case 'cancelled':
      return const Color(0xFF636E72);
    case 'completed':
      return const Color(0xFF0984E3);
    case 'needs_attention':
      return const Color(0xFFD63031);
    case 'processing':
      return const Color(0xFFE17055);
    default:
      return const Color(0xFFB2BEC3);
  }
}

String _statusLabel(BuildContext context, String s) {
  switch (s) {
    case 'confirmed':
      return _t(context, ar: 'مؤكد', en: 'Confirmed');
    case 'cancelled':
      return _t(context, ar: 'ملغي', en: 'Cancelled');
    case 'completed':
      return _t(context, ar: 'مكتمل', en: 'Completed');
    case 'needs_attention':
      return _t(context, ar: 'يحتاج متابعة', en: 'Needs attention');
    case 'processing':
      return _t(context, ar: 'قيد المعالجة', en: 'Processing');
    case 'awaiting_payment':
      return _t(context, ar: 'لم يُدفع', en: 'Not paid');
    case 'failed':
      return _t(context, ar: 'فشل', en: 'Failed');
    default:
      return s;
  }
}

/// انتهت الإقامة؟ (تاريخ الخروج قبل اليوم).
bool _stayEnded(Map<String, dynamic> row) {
  final out = DateTime.tryParse('${row['check_out'] ?? ''}');
  if (out == null) return false;
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  return DateTime(out.year, out.month, out.day).isBefore(today);
}

/// الحالة المعروضة: حجز مؤكد انتهت إقامته يظهر "مكتمل" (عرض فقط، لا يتغير في قاعدة البيانات).
String _displayStatus(Map<String, dynamic> row) {
  final s = '${row['status'] ?? ''}';
  return (s == 'confirmed' && _stayEnded(row)) ? 'completed' : s;
}

String _usd(dynamic v) {
  final n = num.tryParse('$v');
  return n == null ? '—' : '\$${n.toStringAsFixed(2)}';
}

String _date(dynamic v) {
  final s = '${v ?? ''}';
  return s.length >= 10 ? s.substring(0, 10) : s;
}

String _dateTime(dynamic v) {
  final d = DateTime.tryParse('${v ?? ''}')?.toLocal();
  if (d == null) return '—';
  String two(int x) => x.toString().padLeft(2, '0');
  return '${d.year}-${two(d.month)}-${two(d.day)} ${two(d.hour)}:${two(d.minute)}';
}

class _AdminBookingDeskPageState extends State<AdminBookingDeskPage> {
  final _client = Supabase.instance.client;
  final _search = TextEditingController();

  String _filter = 'active';
  String _query = '';
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _rows = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      var q = _client.from('bookings').select().eq('supplier', 'hotelbeds');
      switch (_filter) {
        case 'active':
          q = q.eq('status', 'confirmed');
          break;
        case 'needs_attention':
          q = q.inFilter('status', ['needs_attention', 'processing']);
          break;
        case 'cancelled':
          q = q.eq('status', 'cancelled');
          break;
        case 'attempts':
          q = q.inFilter('status', ['awaiting_payment', 'failed']);
          break;
      }
      final data = await q.order('created_at', ascending: false).limit(300);
      if (!mounted) return;
      setState(() {
        _rows = List<Map<String, dynamic>>.from(data as List);
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  List<Map<String, dynamic>> get _visible {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return _rows;
    bool has(dynamic v) => '${v ?? ''}'.toLowerCase().contains(q);
    return _rows.where((r) =>
    has(r['client_reference']) ||
        has(r['supplier_reference']) ||
        has(r['hotel_name']) ||
        has(r['holder_email']) ||
        has(r['holder_first_name']) ||
        has(r['holder_last_name']) ||
        has(r['id'])).toList();
  }

  @override
  Widget build(BuildContext context) {
    final rows = _visible;
    return Scaffold(
      appBar: AppBar(
        title: Text(_t(context, ar: 'مكتب الحجوزات', en: 'Booking Desk')),
        actions: [
          IconButton(
            tooltip: _t(context, ar: 'تحديث', en: 'Refresh'),
            icon: const Icon(Icons.refresh),
            onPressed: _loading ? null : _load,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSizes.md, AppSizes.md, AppSizes.md, 0),
            child: TextField(
              controller: _search,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                isDense: true,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                hintText: _t(context,
                    ar: 'بحث برقم الحجز أو رقم HotelBeds أو الفندق أو اسم/بريد العميل',
                    en: 'Search by reference, HotelBeds ref, hotel, or guest name/email'),
              ),
              onChanged: (v) => setState(() => _query = v),
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: AppSizes.md, vertical: AppSizes.sm),
            child: Row(
              children: [
                for (final f in _filters)
                  Padding(
                    padding: const EdgeInsetsDirectional.only(end: 8),
                    child: ChoiceChip(
                      label: Text(_filterLabel(context, f)),
                      selected: _filter == f,
                      onSelected: (_) {
                        setState(() => _filter = f);
                        _load();
                      },
                    ),
                  ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(child: _body(rows)),
        ],
      ),
    );
  }

  Widget _body(List<Map<String, dynamic>> rows) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.lg),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 40),
            const SizedBox(height: AppSizes.sm),
            SelectableText(_error!, textAlign: TextAlign.center),
            const SizedBox(height: AppSizes.md),
            OutlinedButton(onPressed: _load, child: Text(_t(context, ar: 'إعادة المحاولة', en: 'Retry'))),
          ]),
        ),
      );
    }
    if (rows.isEmpty) {
      return Center(
        child: Text(_t(context, ar: 'لا توجد حجوزات هنا.', en: 'No bookings here.'),
            style: const TextStyle(color: AppColors.textSecondary)),
      );
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        padding: const EdgeInsets.all(AppSizes.md),
        itemCount: rows.length,
        separatorBuilder: (_, __) => const SizedBox(height: AppSizes.sm),
        itemBuilder: (context, i) => Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: _BookingRow(
              row: rows[i],
              onTap: () async {
                final changed = await showDialog<bool>(
                  context: context,
                  builder: (_) => _BookingDetailsDialog(row: rows[i]),
                );
                if (changed == true) _load();
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _BookingRow extends StatelessWidget {
  final Map<String, dynamic> row;
  final VoidCallback onTap;
  const _BookingRow({required this.row, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final status = _displayStatus(row);
    final guest = [row['holder_first_name'], row['holder_last_name']].where((x) => x != null).join(' ');
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(AppSizes.md),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(
            color: status == 'needs_attention' ? _statusColor(status) : AppColors.divider,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${row['hotel_name'] ?? '-'} · ${row['hotel_city'] ?? '-'}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 2),
                  Text(
                    '${guest.isEmpty ? '-' : guest} · ${row['holder_email'] ?? '-'}',
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${_date(row['check_in'])} → ${_date(row['check_out'])}'
                        '   ·   HB: ${row['supplier_reference'] ?? '—'}',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSizes.sm),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: _statusColor(status).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(_statusLabel(context, status),
                      style: TextStyle(color: _statusColor(status), fontSize: 11, fontWeight: FontWeight.w600)),
                ),
                const SizedBox(height: 6),
                Text(_usd(row['charge_amount']), style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _BookingDetailsDialog extends StatefulWidget {
  final Map<String, dynamic> row;
  const _BookingDetailsDialog({required this.row});

  @override
  State<_BookingDetailsDialog> createState() => _BookingDetailsDialogState();
}

class _BookingDetailsDialogState extends State<_BookingDetailsDialog> {
  bool _busy = false;

  /// يستدعي hotelbeds-cancel ويرجع البيانات، أو يرمي رسالة خطأ مقروءة.
  Future<Map<String, dynamic>> _callCancel(String mode) =>
      _callFunction('hotelbeds-cancel', {'bookingId': widget.row['id'], 'mode': mode});

  /// يستدعي دالة Edge ويرجع البيانات، أو يرمي رسالة خطأ مقروءة.
  Future<Map<String, dynamic>> _callFunction(String name, Map<String, dynamic> body) async {
    try {
      final res = await Supabase.instance.client.functions.invoke(name, body: body);
      final data = res.data is Map ? Map<String, dynamic>.from(res.data as Map) : <String, dynamic>{};
      if (data['error'] != null || data['ok'] == false) {
        throw '${data['message'] ?? data['error']}';
      }
      return data;
    } on FunctionException catch (e) {
      final d = e.details;
      if (d is Map && d['message'] != null) throw '${d['message']}';
      throw '${e.reasonPhrase ?? e.status}';
    }
  }

  Future<void> _cancelOnBehalf() async {
    setState(() => _busy = true);
    Map<String, dynamic> quote;
    try {
      quote = await _callCancel('quote');
    } catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      _snack('$e');
      return;
    }
    if (!mounted) return;
    setState(() => _busy = false);

    final payload = quote['data'] is Map ? Map<String, dynamic>.from(quote['data'] as Map) : quote;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(_t(ctx, ar: 'تأكيد الإلغاء نيابة عن العميل', en: 'Cancel on behalf of guest')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${_t(ctx, ar: 'المدفوع', en: 'Paid')}: ${_usd(payload['chargeAmount'] ?? widget.row['charge_amount'])}'),
            Text('${_t(ctx, ar: 'رسوم الإلغاء', en: 'Cancellation fee')}: ${_usd(payload['fee'])}'),
            Text('${_t(ctx, ar: 'المبلغ المسترد', en: 'Refund')}: ${_usd(payload['refund'])}',
                style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: AppSizes.md),
            Text(
              (num.tryParse('${payload['refund']}') ?? 0) > 0
                  ? _t(ctx,
                  ar: 'سيُلغى الحجز عند الفندق فعليًا، ويُسترد المبلغ للعميل، ويصله بريد الإلغاء. لا يمكن التراجع.',
                  en: 'The booking will be cancelled at the hotel, the refund issued, and the guest emailed. This cannot be undone.')
                  : _t(ctx,
                  ar: 'انتهت فترة الإلغاء المجاني: سيُلغى الحجز عند الفندق دون أي استرداد للعميل، ويصله بريد الإلغاء. لا يمكن التراجع.',
                  en: 'Free cancellation has ended: the booking will be cancelled at the hotel with NO refund, and the guest emailed. This cannot be undone.'),
              style: const TextStyle(color: Colors.red),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(_t(ctx, ar: 'رجوع', en: 'Back'))),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(_t(ctx, ar: 'إلغاء الحجز', en: 'Cancel booking')),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _busy = true);
    try {
      final r = await _callCancel('confirm');
      final p = r['data'] is Map ? Map<String, dynamic>.from(r['data'] as Map) : r;
      if (!mounted) return;
      _snack(p['status'] == 'refund_pending'
          ? _t(context,
          ar: 'أُلغي عند الفندق لكن الاسترداد فشل — راجع Stripe. الحالة: يحتاج متابعة.',
          en: 'Cancelled at hotel but refund failed — check Stripe. Status: needs attention.')
          : _t(context, ar: 'تم الإلغاء والاسترداد.', en: 'Cancelled and refunded.'));
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      _snack('$e');
    }
  }

  /// إعادة إرسال بريد التأكيد (للعميل الذي يقول "لم يصلني الإيميل").
  Future<void> _resendConfirmation() async {
    final controller = TextEditingController(text: '${widget.row['holder_email'] ?? ''}');
    final to = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(_t(ctx, ar: 'إعادة إرسال بريد التأكيد', en: 'Resend confirmation email')),
        content: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _t(ctx,
                    ar: 'تُرسل نفس رسالة التأكيد الأصلية (القسيمة كاملة). يمكنك تعديل البريد إذا كتبه العميل خطأ.',
                    en: 'Sends the original confirmation (full voucher). You can change the address if the guest mistyped it.'),
                style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
              const SizedBox(height: AppSizes.md),
              TextField(
                controller: controller,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: _t(ctx, ar: 'إلى', en: 'To'),
                  border: const OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(_t(ctx, ar: 'رجوع', en: 'Back'))),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: Text(_t(ctx, ar: 'إرسال', en: 'Send')),
          ),
        ],
      ),
    );
    controller.dispose();
    if (to == null || to.isEmpty || !mounted) return;

    setState(() => _busy = true);
    try {
      final r = await _callFunction('hotelbeds-resend-confirmation', {
        'bookingId': widget.row['id'],
        'toEmail': to,
      });
      if (!mounted) return;
      _snack(_t(context, ar: 'أُرسل بريد التأكيد إلى ${r['to'] ?? to}', en: 'Confirmation sent to ${r['to'] ?? to}'));
    } catch (e) {
      if (mounted) _snack('$e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _snack(String m) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  Widget _r(String label, dynamic value, {bool copy = false}) {
    final v = '${value ?? '—'}';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(width: 130, child: Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13))),
          Expanded(child: SelectableText(v, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600))),
          if (copy && value != null)
            IconButton(
              visualDensity: VisualDensity.compact,
              iconSize: 16,
              icon: const Icon(Icons.copy),
              onPressed: () {
                Clipboard.setData(ClipboardData(text: v));
                _snack(_t(context, ar: 'تم النسخ', en: 'Copied'));
              },
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.row;
    // 'completed' = مؤكد وانتهت إقامته: لا إلغاء ولا إعادة إرسال.
    final status = _displayStatus(r);
    final guest = [r['holder_first_name'], r['holder_last_name']].where((x) => x != null).join(' ');
    final policies = (r['cancellation_policies'] is List) ? r['cancellation_policies'] as List : const [];

    return AlertDialog(
      title: Text('${r['hotel_name'] ?? '-'}'),
      content: SizedBox(
        width: 560,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _r(_t(context, ar: 'الحالة', en: 'Status'), _statusLabel(context, status)),
              _r(_t(context, ar: 'رقم HotelBeds', en: 'HotelBeds ref'), r['supplier_reference'], copy: true),
              _r(_t(context, ar: 'رقم Flynoom', en: 'Flynoom ref'), r['client_reference'], copy: true),
              _r(_t(context, ar: 'المدينة', en: 'City'), r['hotel_city']),
              _r(_t(context, ar: 'الدخول', en: 'Check-in'), _date(r['check_in'])),
              _r(_t(context, ar: 'الخروج', en: 'Check-out'), _date(r['check_out'])),
              _r(_t(context, ar: 'العميل', en: 'Guest'), guest.isEmpty ? null : guest),
              _r(_t(context, ar: 'البريد', en: 'Email'), r['holder_email'], copy: true),
              _r(_t(context, ar: 'المدفوع', en: 'Paid'), _usd(r['charge_amount'])),
              _r(_t(context, ar: 'تاريخ الحجز', en: 'Booked at'), _dateTime(r['created_at'])),
              if (status == 'cancelled') ...[
                _r(_t(context, ar: 'رقم الإلغاء', en: 'Cancellation ref'), r['cancellation_reference']),
                _r(_t(context, ar: 'رسوم الإلغاء', en: 'Cancellation fee'), _usd(r['cancellation_fee'])),
                _r(_t(context, ar: 'المسترد', en: 'Refunded'), _usd(r['refund_amount'])),
                _r(_t(context, ar: 'وقت الإلغاء', en: 'Cancelled at'), _dateTime(r['cancelled_at'])),
              ],
              _r('Stripe PaymentIntent', r['payment_intent_id'], copy: true),
              if (r['failure_reason'] != null) ...[
                const SizedBox(height: AppSizes.sm),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: SelectableText('${r['failure_reason']}', style: const TextStyle(fontSize: 12, color: Colors.red)),
                ),
              ],
              if (policies.isNotEmpty) ...[
                const SizedBox(height: AppSizes.md),
                Text(_t(context, ar: 'سياسة الإلغاء (بعملة المورد)', en: 'Cancellation policy (supplier currency)'),
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                for (final p in policies)
                  if (p is Map)
                    Text('• ${_t(context, ar: 'من', en: 'From')} ${p['from']}: ${p['amount']}',
                        style: const TextStyle(fontSize: 12)),
              ],
              if (status == 'needs_attention') ...[
                const SizedBox(height: AppSizes.md),
                Text(
                  _t(context,
                      ar: 'هذا الحجز يحتاج مراجعة يدوية: تحقّق من حالته عند HotelBeds ومن الدفع في Stripe قبل أي إجراء.',
                      en: 'Needs manual review: check the booking at HotelBeds and the payment in Stripe before acting.'),
                  style: const TextStyle(fontSize: 12, color: Colors.red),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _busy ? null : () => Navigator.pop(context, false),
          child: Text(_t(context, ar: 'إغلاق', en: 'Close')),
        ),
        if (status == 'confirmed')
          OutlinedButton.icon(
            onPressed: _busy ? null : _resendConfirmation,
            icon: const Icon(Icons.forward_to_inbox_outlined),
            label: Text(_t(context, ar: 'إعادة إرسال التأكيد', en: 'Resend confirmation')),
          ),
        if (status == 'confirmed')
          FilledButton.icon(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: _busy ? null : _cancelOnBehalf,
            icon: _busy
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.cancel_outlined),
            label: Text(_t(context, ar: 'إلغاء نيابة عن العميل', en: 'Cancel on behalf')),
          ),
      ],
    );
  }
}