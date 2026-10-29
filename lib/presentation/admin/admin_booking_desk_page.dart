import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../core/pdf/flynoom_pdf.dart';
import '../../data/models/booking_model.dart';

/// مكتب الحجوزات — حجوزات HotelBeds الحقيقية (جدول bookings حيث supplier = 'hotelbeds').
///
/// • القراءة: نفس صلاحية المدير المستخدمة في صفحة الحجوزات القديمة.
/// • الإلغاء نيابة عن العميل: عبر دالة hotelbeds-cancel فقط
///   (quote أولًا لعرض الرسوم والاسترداد، ثم confirm). الدالة تلغي عند
///   HotelBeds وتسترد عبر Stripe وترسل بريد الإلغاء للعميل.
/// • لا يوجد هنا أي تعديل يدوي للحالة — حالة هذه الحجوزات يحددها السيرفر فقط.
class AdminBookingDeskPage extends StatefulWidget {
  /// يُفتح من مركز التنبيهات مباشرة على حجز معيّن (رقم Flynoom في البحث).
  final String? initialQuery;

  /// الفلتر عند الفتح: active / needs_attention / cancelled / attempts / all.
  final String initialFilter;

  const AdminBookingDeskPage({super.key, this.initialQuery, this.initialFilter = 'active'});

  @override
  State<AdminBookingDeskPage> createState() => _AdminBookingDeskPageState();
}

String _t(BuildContext context, {required String ar, required String en}) =>
    Localizations.localeOf(context).languageCode == 'ar' ? ar : en;

/// الفلاتر المعروضة. 'attempts' = محاولات لم تكتمل (awaiting_payment/failed).
const _filters = ['active', 'needs_attention', 'cancelled', 'attempts', 'all'];

/// "visa" → "Visa"، "amex" → "American Express"...
String _cardBrand(String b) {
  switch (b.toLowerCase()) {
    case 'visa':
      return 'Visa';
    case 'mastercard':
      return 'Mastercard';
    case 'amex':
      return 'American Express';
    case 'discover':
      return 'Discover';
    case 'diners':
      return 'Diners Club';
    case 'jcb':
      return 'JCB';
    case 'unionpay':
      return 'UnionPay';
    default:
      return b.isEmpty ? 'Card' : b[0].toUpperCase() + b.substring(1);
  }
}

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
    _filter = _filters.contains(widget.initialFilter) ? widget.initialFilter : 'active';
    final q = widget.initialQuery?.trim() ?? '';
    if (q.isNotEmpty) {
      _search.text = q;
      _query = q;
    }
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
    final original = '${widget.row['holder_email'] ?? ''}'.trim();
    final controller = TextEditingController(text: original);
    var saveEmail = true;
    final result = await showDialog<(String, bool)>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setD) {
          final changed = controller.text.trim().toLowerCase() != original.toLowerCase();
          return AlertDialog(
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
                    onChanged: (_) => setD(() {}),
                    decoration: InputDecoration(
                      labelText: _t(ctx, ar: 'إلى', en: 'To'),
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  if (changed) ...[
                    CheckboxListTile(
                      value: saveEmail,
                      onChanged: (v) => setD(() => saveEmail = v ?? false),
                      contentPadding: EdgeInsets.zero,
                      controlAffinity: ListTileControlAffinity.leading,
                      dense: true,
                      title: Text(_t(ctx,
                          ar: 'احفظه بريدًا لهذا الحجز (تصل إليه رسائل الإلغاء لاحقًا)',
                          en: 'Save as this booking\'s email (future cancellation emails go here)')),
                    ),
                    Text(
                      _t(ctx,
                          ar: '⚠️ قبل تغيير البريد تحقق من هوية المتصل: رقم الحجز، والاسم الكامل، وآخر 4 أرقام من البطاقة في Stripe.',
                          en: '⚠️ Before changing the email, verify the caller: booking reference, full name, and last 4 card digits in Stripe.'),
                      style: const TextStyle(fontSize: 12, color: AppColors.error),
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: Text(_t(ctx, ar: 'رجوع', en: 'Back'))),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, (controller.text.trim(), changed && saveEmail)),
                child: Text(_t(ctx, ar: 'إرسال', en: 'Send')),
              ),
            ],
          );
        },
      ),
    );
    controller.dispose();
    if (result == null || result.$1.isEmpty || !mounted) return;
    final to = result.$1;
    final save = result.$2;

    setState(() => _busy = true);
    try {
      final r = await _callFunction('hotelbeds-resend-confirmation', {
        'bookingId': widget.row['id'],
        'toEmail': to,
        'saveEmail': save,
      });
      if (!mounted) return;
      if (save) widget.row['holder_email'] = r['to'] ?? to;
      _snack(save
          ? _t(context,
          ar: 'حُفظ البريد الجديد وأُرسل التأكيد إلى ${r['to'] ?? to}',
          en: 'Email updated and confirmation sent to ${r['to'] ?? to}')
          : _t(context, ar: 'أُرسل بريد التأكيد إلى ${r['to'] ?? to}', en: 'Confirmation sent to ${r['to'] ?? to}'));
    } catch (e) {
      if (mounted) _snack('$e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// "Check with HotelBeds": يسأل HotelBeds هل الحجز موجود، ويقرأ حالة الدفع،
  /// ثم يعرض الإجراء المقترح. لا يتغير شيء إلا بعد تأكيد المدير.
  Future<void> _checkWithHotelBeds() async {
    setState(() => _busy = true);
    Map<String, dynamic> check;
    try {
      check = await _callFunction('hotelbeds-check-booking', {
        'bookingId': widget.row['id'],
        'mode': 'check',
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      _snack('$e');
      return;
    }
    if (!mounted) return;
    setState(() => _busy = false);

    final action = '${check['action'] ?? ''}';
    final canApply = const ['capture_and_confirm', 'release_and_fail', 'mark_confirmed', 'mark_failed']
        .contains(action);
    final positive = action == 'capture_and_confirm' || action == 'mark_confirmed';
    var notifyGuest = true;

    String findingLabel(BuildContext ctx) {
      switch ('${check['finding']}') {
        case 'confirmed':
          return _t(ctx, ar: 'مؤكد عند HotelBeds', en: 'Confirmed at HotelBeds');
        case 'cancelled_at_supplier':
          return _t(ctx, ar: 'ملغى عند HotelBeds', en: 'Cancelled at HotelBeds');
        case 'not_found':
          return _t(ctx, ar: 'غير موجود عند HotelBeds', en: 'Not found at HotelBeds');
        default:
          return _t(ctx, ar: 'غير معروف', en: 'Unknown');
      }
    }

    String paymentLabel(BuildContext ctx) {
      switch ('${check['paymentStatus']}') {
        case 'requires_capture':
          return _t(ctx, ar: 'محجوز على البطاقة (لم يُسحب)', en: 'On hold (not charged)');
        case 'succeeded':
          return _t(ctx, ar: 'مسحوب', en: 'Captured');
        case 'canceled':
          return _t(ctx, ar: 'أُلغي الحجز على البطاقة', en: 'Hold released');
        default:
          return '${check['paymentStatus'] ?? '—'}';
      }
    }

    String applyLabel(BuildContext ctx) {
      switch (action) {
        case 'capture_and_confirm':
          return _t(ctx, ar: 'سحب المبلغ وتأكيد الحجز', en: 'Capture & confirm');
        case 'mark_confirmed':
          return _t(ctx, ar: 'تأكيد الحجز', en: 'Mark confirmed');
        case 'release_and_fail':
          return _t(ctx, ar: 'إلغاء حجز المبلغ وإغلاق الحجز', en: 'Release hold & close');
        default:
          return _t(ctx, ar: 'إغلاق الحجز كفاشل', en: 'Mark failed');
      }
    }

    final apply = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setD) => AlertDialog(
          title: Text(_t(ctx, ar: 'نتيجة الفحص عند HotelBeds', en: 'HotelBeds check result')),
          content: SizedBox(
            width: 460,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${_t(ctx, ar: 'HotelBeds', en: 'HotelBeds')}: ${findingLabel(ctx)}'
                    '${check['hbReference'] != null ? ' (${check['hbReference']})' : ''}',
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text('Stripe: ${paymentLabel(ctx)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: AppSizes.md),
                SelectableText(
                  '${check['message'] ?? ''}',
                  style: TextStyle(
                    fontSize: 13,
                    color: canApply ? AppColors.textSecondary : Colors.red,
                  ),
                ),
                if (canApply && action != 'mark_failed')
                  CheckboxListTile(
                    value: notifyGuest,
                    onChanged: (v) => setD(() => notifyGuest = v ?? true),
                    contentPadding: EdgeInsets.zero,
                    controlAffinity: ListTileControlAffinity.leading,
                    dense: true,
                    title: Text(positive
                        ? _t(ctx, ar: 'أرسل للعميل بريد التأكيد', en: 'Email the guest their confirmation')
                        : _t(ctx,
                        ar: 'أرسل للعميل بريد "لم يكتمل الحجز ولم يُسحب المبلغ"',
                        en: 'Email the guest that the booking was not completed and they were not charged')),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(_t(ctx, ar: 'رجوع', en: 'Back'))),
            if (canApply)
              FilledButton(
                style: FilledButton.styleFrom(backgroundColor: positive ? const Color(0xFF00B894) : Colors.red),
                onPressed: () => Navigator.pop(ctx, true),
                child: Text(applyLabel(ctx)),
              ),
          ],
        ),
      ),
    );
    if (apply != true || !mounted) return;

    setState(() => _busy = true);
    try {
      final r = await _callFunction('hotelbeds-check-booking', {
        'bookingId': widget.row['id'],
        'mode': 'apply',
        'expectAction': action,
        'notifyGuest': notifyGuest,
      });
      if (!mounted) return;
      final emailed = r['emailed'] == true;
      _snack(r['result'] == 'confirmed'
          ? _t(context,
          ar: 'تم تأكيد الحجز${emailed ? ' وأُرسل بريد التأكيد' : ''}.',
          en: 'Booking confirmed${emailed ? ' and confirmation emailed' : ''}.')
          : _t(context,
          ar: 'أُغلق الحجز ولم يُسحب أي مبلغ${emailed ? '، وأُبلغ العميل بالبريد' : ''}.',
          en: 'Booking closed, guest not charged${emailed ? ' and emailed' : ''}.'));
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      _snack('$e');
    }
  }

  /// الوثائق (PDF): الفاتورة، والإيصال، والقسيمة — تفتح نافذة الطباعة،
  /// ومنها يمكن الحفظ كـ PDF أو الطباعة.
  Future<void> _document(String kind) async {
    setState(() => _busy = true);
    try {
      final b = BookingModel.fromJson(widget.row);
      final ref = b.clientReference ?? b.id;
      switch (kind) {
        case 'invoice':
          await FlynoomPdf.printBytes(await FlynoomPdf.invoice(b), 'Invoice-$ref.pdf');
          break;
        case 'receipt':
          await FlynoomPdf.printBytes(await FlynoomPdf.invoice(b, receipt: true), 'Receipt-$ref.pdf');
          break;
        case 'voucher':
          await FlynoomPdf.printBytes(await FlynoomPdf.voucher(b), 'Voucher-$ref.pdf');
          break;
      }
    } catch (e) {
      if (mounted) _snack(_t(context, ar: 'تعذّر إنشاء الوثيقة: $e', en: 'Could not create the document: $e'));
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
              // للتحقق من هوية المتصل قبل تغيير البريد أو الإلغاء.
              _r(
                _t(context, ar: 'البطاقة', en: 'Card'),
                r['card_last4'] == null
                    ? null
                    : '${_cardBrand('${r['card_brand'] ?? ''}')} •••• ${r['card_last4']}',
              ),
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
              if (status == 'needs_attention' || status == 'processing') ...[
                const SizedBox(height: AppSizes.md),
                Text(
                  _t(context,
                      ar: 'هذا الحجز يحتاج مراجعة: اضغط "تحقق من HotelBeds" لمعرفة حالته الحقيقية قبل أي إجراء.',
                      en: 'Needs review: tap "Check with HotelBeds" to see its real status before acting.'),
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
        // الوثائق: لأي حجز دُفع (مؤكد/مكتمل/ملغى).
        if (const ['confirmed', 'completed', 'cancelled'].contains(status) && (r['charge_amount'] != null))
          PopupMenuButton<String>(
            enabled: !_busy,
            tooltip: _t(context, ar: 'الوثائق', en: 'Documents'),
            onSelected: _document,
            itemBuilder: (ctx) => [
              PopupMenuItem(
                value: 'invoice',
                child: ListTile(
                  dense: true,
                  leading: const Icon(Icons.description_outlined),
                  title: Text(_t(ctx, ar: 'الفاتورة (PDF)', en: 'Invoice (PDF)')),
                ),
              ),
              PopupMenuItem(
                value: 'receipt',
                child: ListTile(
                  dense: true,
                  leading: const Icon(Icons.receipt_outlined),
                  title: Text(_t(ctx, ar: 'الإيصال (PDF)', en: 'Receipt (PDF)')),
                ),
              ),
              if (r['supplier_reference'] != null)
                PopupMenuItem(
                  value: 'voucher',
                  child: ListTile(
                    dense: true,
                    leading: const Icon(Icons.confirmation_number_outlined),
                    title: Text(_t(ctx, ar: 'القسيمة (PDF)', en: 'Voucher (PDF)')),
                  ),
                ),
            ],
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.print_outlined, size: 18),
                const SizedBox(width: 6),
                Text(_t(context, ar: 'الوثائق', en: 'Documents')),
              ]),
            ),
          ),
        if (status == 'needs_attention' || status == 'processing')
          FilledButton.icon(
            onPressed: _busy ? null : _checkWithHotelBeds,
            icon: _busy
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.fact_check_outlined),
            label: Text(_t(context, ar: 'تحقق من HotelBeds', en: 'Check with HotelBeds')),
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