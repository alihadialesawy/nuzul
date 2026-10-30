import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../core/pdf/flynoom_pdf.dart';
import '../../data/models/booking_model.dart';
import 'admin_booking_desk_page.dart';

/// يختار النص المناسب حسب اللغة الحالية (عربي/إنجليزي/إسباني).
String _t3(BuildContext context, {required String ar, required String en, required String es}) {
  switch (Localizations.localeOf(context).languageCode) {
    case 'ar':
      return ar;
    case 'es':
      return es;
    default:
      return en;
  }
}

/// الاعتراضات على الدفع (Chargebacks) — للمالك والمساعدين.
///
/// • تصل تلقائيًا من Stripe عبر stripe-webhook، أو بزر "مزامنة من Stripe".
/// • لكل اعتراض: المبلغ، والسبب، والحالة، والموعد النهائي للرد.
/// • "ملف الأدلة (PDF)": يجمع سجلات الحجز وموافقة العميل تلقائيًا،
///   ثم تفتح الاعتراض في Stripe وترفع الملف هناك (Submit evidence).
class AdminDisputesPage extends StatefulWidget {
  const AdminDisputesPage({super.key});

  @override
  State<AdminDisputesPage> createState() => _AdminDisputesPageState();
}

class _AdminDisputesPageState extends State<AdminDisputesPage> {
  final _client = Supabase.instance.client;
  bool _loading = true;
  bool _syncing = false;
  String? _error;
  List<Map<String, dynamic>> _rows = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await _client
          .from('disputes')
          .select('id, payment_intent_id, booking_id, client_reference, amount, currency, reason, status, evidence_due_by, livemode, created_at')
          .order('created_at', ascending: false)
          .limit(200);
      if (!mounted) return;
      setState(() {
        _rows = List<Map<String, dynamic>>.from(data as List);
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = '$e';
        _loading = false;
      });
    }
  }

  Future<void> _sync() async {
    setState(() => _syncing = true);
    try {
      final res = await _client.functions.invoke('disputes-sync');
      final d = res.data is Map ? Map<String, dynamic>.from(res.data as Map) : <String, dynamic>{};
      if (!mounted) return;
      _snack(d['ok'] == false
          ? '${d['error'] ?? 'Sync failed'}'
          : _t3(context, ar: 'تمت المزامنة: ${d['synced'] ?? 0}', en: 'Synced: ${d['synced'] ?? 0}', es: 'Sincronizado: ${d['synced'] ?? 0}'));
      await _load();
    } catch (e) {
      if (mounted) _snack('$e');
    } finally {
      if (mounted) setState(() => _syncing = false);
    }
  }

  void _snack(String m) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  @override
  Widget build(BuildContext context) {
    final open = _rows.where((r) => _needsResponse('${r['status']}')).length;
    return Scaffold(
      appBar: AppBar(
        title: Text(_t3(context, ar: 'الاعتراضات على الدفع', en: 'Payment Disputes', es: 'Disputas de pago')),
        actions: [
          TextButton.icon(
            onPressed: _syncing ? null : _sync,
            icon: _syncing
                ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.sync),
            label: Text(_t3(context, ar: 'مزامنة من Stripe', en: 'Sync from Stripe', es: 'Sincronizar')),
          ),
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loading ? null : _load),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(child: Padding(padding: const EdgeInsets.all(AppSizes.lg), child: SelectableText(_error!)))
          : ListView(
        padding: const EdgeInsets.all(AppSizes.md),
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 900),
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                _HowTo(openCount: open),
                const SizedBox(height: AppSizes.md),
                if (_rows.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(AppSizes.xl),
                    child: Column(children: [
                      const Icon(Icons.verified_user_outlined, size: 48, color: Color(0xFF00B894)),
                      const SizedBox(height: 8),
                      Text(_t3(context, ar: 'لا توجد اعتراضات. 👍', en: 'No disputes. 👍', es: 'Sin disputas. 👍')),
                    ]),
                  )
                else
                  for (final r in _rows)
                    _DisputeTile(
                      row: r,
                      onTap: () => showDialog<void>(context: context, builder: (_) => _DisputeDialog(row: r)),
                    ),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

bool _needsResponse(String s) => s == 'needs_response' || s == 'warning_needs_response';

Color _statusColor(String s) {
  switch (s) {
    case 'needs_response':
    case 'warning_needs_response':
      return const Color(0xFFD63031);
    case 'under_review':
    case 'warning_under_review':
      return const Color(0xFFE17055);
    case 'won':
    case 'warning_closed':
      return const Color(0xFF00B894);
    case 'lost':
      return const Color(0xFF636E72);
    default:
      return const Color(0xFFB2BEC3);
  }
}

String _statusLabel(BuildContext context, String s) {
  switch (s) {
    case 'needs_response':
    case 'warning_needs_response':
      return _t3(context, ar: 'يحتاج ردًا', en: 'Needs response', es: 'Requiere respuesta');
    case 'under_review':
    case 'warning_under_review':
      return _t3(context, ar: 'قيد مراجعة البنك', en: 'Under review', es: 'En revisión');
    case 'won':
      return _t3(context, ar: 'ربحنا', en: 'Won', es: 'Ganada');
    case 'lost':
      return _t3(context, ar: 'خسرنا', en: 'Lost', es: 'Perdida');
    case 'warning_closed':
      return _t3(context, ar: 'أُغلق', en: 'Closed', es: 'Cerrada');
    default:
      return s;
  }
}

/// أسباب Stripe الشائعة بلغة واضحة.
String _reasonLabel(BuildContext context, String r) {
  switch (r) {
    case 'fraudulent':
      return _t3(context, ar: 'يقول إنه لم يقم بالعملية', en: 'Says they did not make the payment', es: 'Dice que no hizo el pago');
    case 'product_not_received':
      return _t3(context, ar: 'يقول إنه لم يحصل على الخدمة', en: 'Says service was not received', es: 'Dice que no recibió el servicio');
    case 'product_unacceptable':
      return _t3(context, ar: 'يقول إن الخدمة مختلفة عن الوصف', en: 'Says service was not as described', es: 'No es lo descrito');
    case 'credit_not_processed':
      return _t3(context, ar: 'يقول إن الاسترداد لم يصله', en: 'Says refund was not processed', es: 'Reembolso no procesado');
    case 'duplicate':
      return _t3(context, ar: 'يقول إنه دفع مرتين', en: 'Says charged twice', es: 'Cobro duplicado');
    case 'subscription_canceled':
      return _t3(context, ar: 'يقول إنه ألغى', en: 'Says they cancelled', es: 'Dice que canceló');
    default:
      return r;
  }
}

String _due(BuildContext context, dynamic v) {
  final d = DateTime.tryParse('${v ?? ''}')?.toLocal();
  if (d == null) return '—';
  final left = d.difference(DateTime.now());
  final date = '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  if (left.isNegative) return '$date (${_t3(context, ar: 'انتهى', en: 'passed', es: 'vencido')})';
  final days = left.inDays;
  final hours = left.inHours % 24;
  return '$date (${_t3(context, ar: 'باقي $days يوم $hours ساعة', en: '${days}d ${hours}h left', es: '${days}d ${hours}h')})';
}

class _HowTo extends StatelessWidget {
  final int openCount;
  const _HowTo({required this.openCount});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(AppSizes.md),
    decoration: BoxDecoration(
      color: (openCount > 0 ? const Color(0xFFD63031) : const Color(0xFF0984E3)).withOpacity(0.06),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Text(
      _t3(context,
          ar: 'عند اعتراض: افتحه ← "ملف الأدلة (PDF)" ← "فتح في Stripe" ← Submit evidence وارفع الملف قبل الموعد النهائي. '
              'إن لم ترد في الموعد يخسر الاعتراض تلقائيًا.',
          en: 'For each dispute: open it → "Evidence PDF" → "Open in Stripe" → Submit evidence and upload the PDF before the deadline. '
              'No response by the deadline means the dispute is lost automatically.',
          es: 'Para cada disputa: ábrela → "PDF de pruebas" → "Abrir en Stripe" → Submit evidence antes de la fecha límite.'),
      style: const TextStyle(fontSize: 13),
    ),
  );
}

class _DisputeTile extends StatelessWidget {
  final Map<String, dynamic> row;
  final VoidCallback onTap;
  const _DisputeTile({required this.row, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final status = '${row['status'] ?? ''}';
    final color = _statusColor(status);
    return Card(
      margin: const EdgeInsets.only(bottom: AppSizes.sm),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: _needsResponse(status) ? color : AppColors.divider),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.md),
          child: Row(children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('${row['client_reference'] ?? _t3(context, ar: 'حجز غير معروف', en: 'Unknown booking', es: 'Reserva desconocida')}'
                    '  ·  \$${((row['amount'] as num?) ?? 0).toStringAsFixed(2)}',
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 2),
                Text(_reasonLabel(context, '${row['reason'] ?? ''}'),
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                if (_needsResponse(status))
                  Text('${_t3(context, ar: 'الموعد النهائي', en: 'Due', es: 'Vence')}: ${_due(context, row['evidence_due_by'])}',
                      style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w600)),
              ]),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(20)),
              child: Text(_statusLabel(context, status),
                  style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600)),
            ),
            if (row['livemode'] != true)
              const Padding(
                padding: EdgeInsetsDirectional.only(start: 6),
                child: Text('TEST', style: TextStyle(fontSize: 10, color: AppColors.textHint)),
              ),
          ]),
        ),
      ),
    );
  }
}

class _DisputeDialog extends StatefulWidget {
  final Map<String, dynamic> row;
  const _DisputeDialog({required this.row});

  @override
  State<_DisputeDialog> createState() => _DisputeDialogState();
}

class _DisputeDialogState extends State<_DisputeDialog> {
  bool _busy = false;

  Future<void> _evidence() async {
    final bookingId = widget.row['booking_id'];
    if (bookingId == null) {
      _snack(_t3(context,
          ar: 'لا يوجد حجز مرتبط بهذا الاعتراض في المنصة.',
          en: 'No Flynoom booking is linked to this dispute.',
          es: 'No hay reserva vinculada.'));
      return;
    }
    setState(() => _busy = true);
    try {
      final client = Supabase.instance.client;
      final row = await client.from('bookings').select().eq('id', bookingId).single();
      final consents = await client
          .from('booking_consents')
          .select()
          .eq('booking_id', bookingId)
          .order('accepted_at');
      final b = BookingModel.fromJson(Map<String, dynamic>.from(row));
      final bytes = await FlynoomPdf.disputeEvidence(
        b: b,
        consents: List<Map<String, dynamic>>.from(consents as List),
        dispute: widget.row,
      );
      await FlynoomPdf.printBytes(bytes, 'Dispute-Evidence-${b.clientReference ?? b.id}.pdf');
    } catch (e) {
      _snack('$e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _openStripe() async {
    final id = widget.row['id'];
    final test = widget.row['livemode'] != true;
    final url = Uri.parse('https://dashboard.stripe.com/${test ? 'test/' : ''}disputes/$id');
    await launchUrl(url, mode: LaunchMode.externalApplication);
  }

  void _openBooking() {
    final ref = widget.row['client_reference'];
    final nav = Navigator.of(context);
    nav.pop();
    nav.push(MaterialPageRoute(
      builder: (_) => AdminBookingDeskPage(initialQuery: ref == null ? null : '$ref', initialFilter: 'all'),
    ));
  }

  void _snack(String m) {
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));
  }

  Widget _r(String k, String v) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 3),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      SizedBox(width: 130, child: Text(k, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13))),
      Expanded(child: SelectableText(v, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600))),
    ]),
  );

  @override
  Widget build(BuildContext context) {
    final r = widget.row;
    final status = '${r['status'] ?? ''}';
    return AlertDialog(
      title: Text(_t3(context, ar: 'اعتراض على الدفع', en: 'Payment dispute', es: 'Disputa de pago')),
      content: SizedBox(
        width: 520,
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          _r(_t3(context, ar: 'الحالة', en: 'Status', es: 'Estado'), _statusLabel(context, status)),
          _r(_t3(context, ar: 'المبلغ', en: 'Amount', es: 'Importe'), '\$${((r['amount'] as num?) ?? 0).toStringAsFixed(2)}'),
          _r(_t3(context, ar: 'السبب', en: 'Reason', es: 'Motivo'), _reasonLabel(context, '${r['reason'] ?? ''}')),
          _r(_t3(context, ar: 'الموعد النهائي', en: 'Evidence due', es: 'Fecha límite'), _due(context, r['evidence_due_by'])),
          _r(_t3(context, ar: 'رقم Flynoom', en: 'Flynoom ref', es: 'Ref. Flynoom'), '${r['client_reference'] ?? '—'}'),
          _r('Stripe', '${r['id']}'),
          if (r['reason'] == 'fraudulent') ...[
            const SizedBox(height: 8),
            Text(
              _t3(context,
                  ar: 'تنبيه: إن كان الحجز قادمًا ولم يبدأ بعد، فقد يكون الأفضل إلغاؤه عند الفندق قبل الإقامة، حتى لا تدفع للفندق وتخسر الاعتراض معًا.',
                  en: 'Tip: if the stay has not started yet, consider cancelling it at the hotel so you do not pay the hotel and lose the dispute too.',
                  es: 'Consejo: si la estancia no ha empezado, considera cancelarla en el hotel.'),
              style: const TextStyle(fontSize: 12, color: Color(0xFFD63031)),
            ),
          ],
        ]),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(_t3(context, ar: 'إغلاق', en: 'Close', es: 'Cerrar'))),
        if (r['client_reference'] != null)
          TextButton(onPressed: _openBooking, child: Text(_t3(context, ar: 'فتح الحجز', en: 'Open booking', es: 'Abrir reserva'))),
        OutlinedButton.icon(
          onPressed: _openStripe,
          icon: const Icon(Icons.open_in_new, size: 16),
          label: Text(_t3(context, ar: 'فتح في Stripe', en: 'Open in Stripe', es: 'Abrir en Stripe')),
        ),
        FilledButton.icon(
          onPressed: _busy ? null : _evidence,
          icon: _busy
              ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Icon(Icons.picture_as_pdf_outlined, size: 18),
          label: Text(_t3(context, ar: 'ملف الأدلة (PDF)', en: 'Evidence PDF', es: 'PDF de pruebas')),
        ),
      ],
    );
  }
}