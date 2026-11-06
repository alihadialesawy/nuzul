import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';

/// يختار النص المناسب حسب اللغة الحالية (عربي/إنجليزي/إسباني) — مثل باقي صفحات الإدارة.
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

/// الاحتيال والمخاطر — للمالك والمساعدين.
///
/// تعرض جدول payment_risk_events:
///   • قرارات بوابة الاحتيال في hotelbeds-book (قبول / رفض) وأسبابها.
///   • إنذارات الاحتيال المبكرة من Stripe (stripe-webhook) وما فُعل بكل منها.
///
/// المراجعة الأسبوعية (5 دقائق): هل نرفض زبائن حقيقيين؟ مثلًا حساب قديم له
/// حجوزات ناجحة رُفض بسبب "إشارات خفيفة" → القواعد صارمة أكثر من اللازم
/// (تُعدّل في supabase/functions/_shared/fraud.ts).
class AdminRiskPage extends StatefulWidget {
  const AdminRiskPage({super.key});

  @override
  State<AdminRiskPage> createState() => _AdminRiskPageState();
}

enum _Filter { attention, rejected, efw, allowed, all }

class _AdminRiskPageState extends State<AdminRiskPage> {
  final _client = Supabase.instance.client;
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _rows = [];
  _Filter _filter = _Filter.attention;
  int _days = 7;

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
      final since = DateTime.now().toUtc().subtract(Duration(days: _days)).toIso8601String();
      final data = await _client
          .from('payment_risk_events')
          .select('id, created_at, booking_id, user_id, payment_intent_id, decision, reasons, signals, '
          'risk_level, three_ds, card_country, ip_country, cvc_check, postal_check, card_funding, amount_usd, '
          'bookings(client_reference, hotel_name, hotel_city, holder_first_name, holder_last_name, holder_email, status)')
          .gte('created_at', since)
          .order('created_at', ascending: false)
          .limit(500);
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

  bool _isEfw(Map<String, dynamic> r) => r['decision'] == 'early_fraud_warning';
  bool _isReject(Map<String, dynamic> r) => r['decision'] == 'reject';
  bool _isAllow(Map<String, dynamic> r) => r['decision'] == 'allow';

  /// إنذار احتيال لم يُعالَج تلقائيًا → يحتاج قرارك.
  bool _efwNeedsAction(Map<String, dynamic> r) {
    if (!_isEfw(r)) return false;
    final reasons = List<String>.from((r['reasons'] as List?) ?? const []);
    final action = reasons.isEmpty ? '' : reasons.first;
    return action != 'auto_cancelled_refunded' && action != 'already_cancelled';
  }

  List<Map<String, dynamic>> get _visible {
    switch (_filter) {
      case _Filter.attention:
        return _rows.where((r) => _isReject(r) || _efwNeedsAction(r)).toList();
      case _Filter.rejected:
        return _rows.where(_isReject).toList();
      case _Filter.efw:
        return _rows.where(_isEfw).toList();
      case _Filter.allowed:
        return _rows.where(_isAllow).toList();
      case _Filter.all:
        return _rows;
    }
  }

  @override
  Widget build(BuildContext context) {
    final rejected = _rows.where(_isReject).length;
    final allowed = _rows.where(_isAllow).length;
    final efw = _rows.where(_isEfw).length;
    final efwOpen = _rows.where(_efwNeedsAction).length;
    final total = rejected + allowed;
    final rate = total == 0 ? 0 : (rejected * 100 / total).round();

    return Scaffold(
      appBar: AppBar(
        title: Text(_t3(context, ar: 'الاحتيال والمخاطر', en: 'Fraud & Risk', es: 'Fraude y riesgo')),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loading ? null : _load),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(child: Padding(padding: const EdgeInsets.all(AppSizes.lg), child: SelectableText(_error!)))
          : RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.all(AppSizes.md),
          children: [
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1000),
                child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  _periodChips(),
                  const SizedBox(height: AppSizes.md),
                  Wrap(spacing: AppSizes.sm, runSpacing: AppSizes.sm, children: [
                    _Stat(
                      label: _t3(context, ar: 'مقبولة', en: 'Allowed', es: 'Permitidos'),
                      value: '$allowed',
                      color: AppColors.success,
                    ),
                    _Stat(
                      label: _t3(context, ar: 'مرفوضة من البوابة', en: 'Rejected by gate', es: 'Rechazados'),
                      value: '$rejected',
                      color: const Color(0xFFD63031),
                    ),
                    _Stat(
                      label: _t3(context, ar: 'نسبة الرفض', en: 'Reject rate', es: 'Tasa de rechazo'),
                      value: '$rate%',
                      color: rate > 10 ? const Color(0xFFE17055) : const Color(0xFF0984E3),
                    ),
                    _Stat(
                      label: _t3(context, ar: 'إنذارات احتيال', en: 'Fraud warnings', es: 'Alertas de fraude'),
                      value: '$efw',
                      color: const Color(0xFF6C5CE7),
                    ),
                    _Stat(
                      label: _t3(context, ar: 'تحتاج قرارك', en: 'Need your decision', es: 'Requieren acción'),
                      value: '$efwOpen',
                      color: efwOpen > 0 ? const Color(0xFFB71C1C) : AppColors.textSecondary,
                    ),
                  ]),
                  const SizedBox(height: AppSizes.md),
                  _HowTo(rejectRate: rate, efwOpen: efwOpen),
                  const SizedBox(height: AppSizes.md),
                  _filterChips(),
                  const SizedBox(height: AppSizes.sm),
                  if (_visible.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(AppSizes.xl),
                      child: Center(
                        child: Text(
                          _t3(context,
                              ar: 'لا شيء هنا في هذه الفترة ✅',
                              en: 'Nothing here for this period ✅',
                              es: 'Nada en este periodo ✅'),
                          style: const TextStyle(color: AppColors.textSecondary),
                        ),
                      ),
                    )
                  else
                    ..._visible.map((r) => _RiskTile(
                      row: r,
                      needsAction: _efwNeedsAction(r),
                      onTap: () => _showDetails(r),
                    )),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _periodChips() {
    Widget chip(int d, String label) => ChoiceChip(
      label: Text(label),
      selected: _days == d,
      onSelected: (_) {
        setState(() => _days = d);
        _load();
      },
    );
    return Wrap(spacing: AppSizes.sm, children: [
      chip(1, _t3(context, ar: 'آخر 24 ساعة', en: 'Last 24h', es: 'Últimas 24 h')),
      chip(7, _t3(context, ar: 'آخر 7 أيام', en: 'Last 7 days', es: 'Últimos 7 días')),
      chip(30, _t3(context, ar: 'آخر 30 يومًا', en: 'Last 30 days', es: 'Últimos 30 días')),
      chip(90, _t3(context, ar: 'آخر 90 يومًا', en: 'Last 90 days', es: 'Últimos 90 días')),
    ]);
  }

  Widget _filterChips() {
    Widget chip(_Filter f, String label) => FilterChip(
      label: Text(label),
      selected: _filter == f,
      onSelected: (_) => setState(() => _filter = f),
    );
    return Wrap(spacing: AppSizes.sm, runSpacing: AppSizes.sm, children: [
      chip(_Filter.attention, _t3(context, ar: 'للمراجعة', en: 'To review', es: 'Para revisar')),
      chip(_Filter.rejected, _t3(context, ar: 'المرفوضة', en: 'Rejected', es: 'Rechazados')),
      chip(_Filter.efw, _t3(context, ar: 'إنذارات الاحتيال', en: 'Fraud warnings', es: 'Alertas de fraude')),
      chip(_Filter.allowed, _t3(context, ar: 'المقبولة', en: 'Allowed', es: 'Permitidos')),
      chip(_Filter.all, _t3(context, ar: 'الكل', en: 'All', es: 'Todos')),
    ]);
  }

  Future<void> _showDetails(Map<String, dynamic> r) async {
    final b = r['bookings'] is Map ? Map<String, dynamic>.from(r['bookings'] as Map) : <String, dynamic>{};
    final reasons = List<String>.from((r['reasons'] as List?) ?? const []);
    final signals = List<String>.from((r['signals'] as List?) ?? const []);
    final pi = '${r['payment_intent_id'] ?? ''}';

    Widget line(String k, String? v, {bool copy = false}) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SizedBox(width: 150, child: Text(k, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13))),
        Expanded(child: SelectableText(v == null || v.isEmpty || v == 'null' ? '—' : v, style: const TextStyle(fontSize: 13))),
        if (copy && v != null && v.isNotEmpty && v != 'null')
          IconButton(
            visualDensity: VisualDensity.compact,
            iconSize: 16,
            tooltip: _t3(context, ar: 'نسخ', en: 'Copy', es: 'Copiar'),
            icon: const Icon(Icons.copy),
            onPressed: () => Clipboard.setData(ClipboardData(text: v)),
          ),
      ]),
    );

    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(_decisionLabel(ctx, '${r['decision']}')),
        content: SizedBox(
          width: 560,
          child: SingleChildScrollView(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
              line(_t3(ctx, ar: 'الوقت', en: 'Time', es: 'Hora'), _fmtTime(r['created_at'])),
              line(_t3(ctx, ar: 'رقم Flynoom', en: 'Flynoom ref', es: 'Ref. Flynoom'), '${b['client_reference'] ?? ''}', copy: true),
              line(_t3(ctx, ar: 'الفندق', en: 'Hotel', es: 'Hotel'),
                  [b['hotel_name'], b['hotel_city']].where((e) => e != null && '$e'.isNotEmpty).join(' · ')),
              line(_t3(ctx, ar: 'الضيف', en: 'Guest', es: 'Huésped'),
                  [b['holder_first_name'], b['holder_last_name']].where((e) => e != null).join(' ')),
              line(_t3(ctx, ar: 'البريد', en: 'Email', es: 'Email'), '${b['holder_email'] ?? ''}', copy: true),
              line(_t3(ctx, ar: 'حالة الحجز الآن', en: 'Booking status now', es: 'Estado actual'), '${b['status'] ?? ''}'),
              line(_t3(ctx, ar: 'المبلغ', en: 'Amount', es: 'Importe'),
                  r['amount_usd'] == null ? null : '\$${(r['amount_usd'] as num).toStringAsFixed(2)}'),
              const Divider(),
              Text(_t3(ctx, ar: 'الأسباب', en: 'Reasons', es: 'Motivos'),
                  style: const TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              if (reasons.isEmpty) const Text('—'),
              ...reasons.map((x) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text('• ${_reasonText(ctx, x)}', style: const TextStyle(fontSize: 13)),
              )),
              if (signals.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(_t3(ctx, ar: 'إشارات خفيفة', en: 'Soft signals', es: 'Señales leves'),
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                ...signals.map((x) => Text('• ${_reasonText(ctx, x)}', style: const TextStyle(fontSize: 13))),
              ],
              const Divider(),
              line('Radar', '${r['risk_level'] ?? ''}'),
              line('3D Secure', '${r['three_ds'] ?? ''}'),
              line(_t3(ctx, ar: 'دولة البطاقة / IP', en: 'Card / IP country', es: 'País tarjeta / IP'),
                  '${r['card_country'] ?? '—'} / ${r['ip_country'] ?? '—'}'),
              line('CVC / ZIP', '${r['cvc_check'] ?? '—'} / ${r['postal_check'] ?? '—'}'),
              line(_t3(ctx, ar: 'نوع البطاقة', en: 'Card type', es: 'Tipo de tarjeta'), '${r['card_funding'] ?? ''}'),
              line('PaymentIntent', pi, copy: true),
            ]),
          ),
        ),
        actions: [
          if (pi.startsWith('pi_'))
            TextButton.icon(
              icon: const Icon(Icons.open_in_new, size: 18),
              label: Text(_t3(ctx, ar: 'فتح في Stripe', en: 'Open in Stripe', es: 'Abrir en Stripe')),
              onPressed: () => launchUrl(
                Uri.parse('https://dashboard.stripe.com/payments/$pi'),
                mode: LaunchMode.externalApplication,
              ),
            ),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(_t3(ctx, ar: 'إغلاق', en: 'Close', es: 'Cerrar')),
          ),
        ],
      ),
    );
  }
}

// ───────────────────────── عناصر مساعدة ─────────────────────────

String _fmtTime(dynamic iso) {
  final d = DateTime.tryParse('${iso ?? ''}')?.toLocal();
  if (d == null) return '—';
  String two(int n) => n.toString().padLeft(2, '0');
  return '${d.year}-${two(d.month)}-${two(d.day)} ${two(d.hour)}:${two(d.minute)}';
}

String _decisionLabel(BuildContext c, String d) {
  switch (d) {
    case 'allow':
      return _t3(c, ar: 'مقبولة', en: 'Allowed', es: 'Permitido');
    case 'reject':
      return _t3(c, ar: 'مرفوضة من البوابة', en: 'Rejected by gate', es: 'Rechazado');
    case 'early_fraud_warning':
      return _t3(c, ar: 'إنذار احتيال مبكر', en: 'Early fraud warning', es: 'Alerta temprana de fraude');
    default:
      return d;
  }
}

/// شرح الأسباب والإشارات بلغة بسيطة.
String _reasonText(BuildContext c, String raw) {
  final i = raw.indexOf(':');
  final key = i < 0 ? raw : raw.substring(0, i);
  final val = i < 0 ? '' : raw.substring(i + 1);
  switch (key) {
    case 'sanctioned_card_country':
      return _t3(c, ar: 'بطاقة من دولة خاضعة للعقوبات ($val)', en: 'Card from a sanctioned country ($val)', es: 'Tarjeta de país sancionado ($val)');
    case 'cvc_fail':
      return _t3(c, ar: 'رقم CVC خاطئ', en: 'Wrong CVC', es: 'CVC incorrecto');
    case 'radar_highest':
      return _t3(c, ar: 'تقييم Radar: خطورة قصوى', en: 'Radar risk: highest', es: 'Riesgo Radar: máximo');
    case 'radar_elevated_no_3ds':
      return _t3(c, ar: 'تقييم Radar مرتفع دون تحقق كامل من البنك (3D Secure)', en: 'Radar risk elevated without full 3D Secure', es: 'Riesgo elevado sin 3D Secure completo');
    case 'postal_fail_no_3ds':
      return _t3(c, ar: 'رمز بريدي خاطئ دون 3D Secure', en: 'Wrong ZIP without 3D Secure', es: 'Código postal incorrecto sin 3D Secure');
    case 'too_many_cards':
      return _t3(c, ar: 'بطاقات كثيرة على نفس الحساب خلال 24 ساعة ($val)', en: 'Too many cards on one account in 24h ($val)', es: 'Demasiadas tarjetas en 24 h ($val)');
    case 'soft_signals':
      return _t3(c, ar: 'اجتماع $val إشارات خفيفة دون 3D Secure', en: '$val soft signals without 3D Secure', es: '$val señales leves sin 3D Secure');
    case 'ip_card_mismatch':
      return _t3(c, ar: 'دولة الزائر/دولة البطاقة مختلفتان ($val)', en: 'Visitor/card country differ ($val)', es: 'País visitante/tarjeta distinto ($val)');
    case 'last_minute':
      return _t3(c, ar: 'وصول خلال 48 ساعة', en: 'Check-in within 48 hours', es: 'Llegada en 48 horas');
    case 'high_amount':
      return _t3(c, ar: 'مبلغ كبير (\$$val)', en: 'High amount (\$$val)', es: 'Importe alto (\$$val)');
    case 'prepaid_card':
      return _t3(c, ar: 'بطاقة مسبقة الدفع', en: 'Prepaid card', es: 'Tarjeta prepago');
    case 'fraud_type':
      return _t3(c, ar: 'نوع الاحتيال حسب البنك: $val', en: 'Issuer fraud type: $val', es: 'Tipo de fraude: $val');
    case 'auto_cancelled_refunded':
      return _t3(c, ar: '✅ أُلغي الحجز عند الفندق وأُعيد المبلغ تلقائيًا', en: '✅ Hotel booking cancelled and fully refunded automatically', es: '✅ Cancelado y reembolsado automáticamente');
    case 'already_cancelled':
      return _t3(c, ar: 'الحجز كان ملغى مسبقًا', en: 'Booking was already cancelled', es: 'La reserva ya estaba cancelada');
    case 'manual_stay_started':
      return _t3(c, ar: '⚠️ الإقامة بدأت — قرارك: استرداد أو انتظار الاعتراض', en: '⚠️ Stay started — decide: refund or wait for dispute', es: '⚠️ Estancia iniciada — decide');
    case 'manual_cancellation_fee_applies':
      return _t3(c, ar: '⚠️ الإلغاء لم يعد مجانيًا — قرارك', en: '⚠️ Cancellation no longer free — your decision', es: '⚠️ La cancelación ya no es gratuita');
    case 'manual_hotel_cancel_failed':
      return _t3(c, ar: '⚠️ فشل الإلغاء عند الفندق — راجعه في مكتب الحجوزات', en: '⚠️ Hotel cancellation failed — check Booking Desk', es: '⚠️ Falló la cancelación');
    case 'cancel_unknown_needs_attention':
      return _t3(c, ar: '⚠️ نتيجة الإلغاء غير معروفة — Check with HotelBeds', en: '⚠️ Cancel result unknown — Check with HotelBeds', es: '⚠️ Resultado desconocido');
    case 'hotel_cancelled_refund_failed':
      return _t3(c, ar: '⚠️ أُلغي عند الفندق لكن فشل الاسترداد — استرد من Stripe', en: '⚠️ Cancelled at hotel but refund failed — refund in Stripe', es: '⚠️ Falló el reembolso');
    case 'booking_not_found':
    case 'no_payment_intent':
      return _t3(c, ar: 'لا يوجد حجز مرتبط (غالبًا حدث تجريبي)', en: 'No linked booking (likely a test event)', es: 'Sin reserva vinculada');
    default:
      if (key.startsWith('manual_status_')) {
        return _t3(c,
            ar: '⚠️ حالة الحجز ${key.substring(14)} — راجعه يدويًا',
            en: '⚠️ Booking status ${key.substring(14)} — review manually',
            es: '⚠️ Estado ${key.substring(14)} — revisar');
      }
      return raw;
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _Stat({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) => Container(
    width: 180,
    padding: const EdgeInsets.all(AppSizes.md),
    decoration: BoxDecoration(
      color: Theme.of(context).cardColor,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: AppColors.divider),
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
      const SizedBox(height: 6),
      Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color)),
    ]),
  );
}

class _HowTo extends StatelessWidget {
  final int rejectRate;
  final int efwOpen;
  const _HowTo({required this.rejectRate, required this.efwOpen});

  @override
  Widget build(BuildContext context) {
    final warn = efwOpen > 0 || rejectRate > 10;
    return Container(
      padding: const EdgeInsets.all(AppSizes.md),
      decoration: BoxDecoration(
        color: (warn ? const Color(0xFFD63031) : const Color(0xFF0984E3)).withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        _t3(context,
            ar: 'المراجعة الأسبوعية: افتح "للمراجعة". لكل رفض اسأل: هل يبدو زبونًا حقيقيًا (حساب قديم، حجوزات سابقة ناجحة)؟ '
                'إن تكرر رفض زبائن حقيقيين فالقواعد صارمة. إنذارات الاحتيال التي "تحتاج قرارك" عالجها اليوم: '
                'إن لم تبدأ الإقامة ألغِ من مكتب الحجوزات واسترد لتجنب الاعتراض. '
                'وإن اشتكى زبون أن كل بطاقاته تُرفض فابحث عن بريده في Stripe ← Radar ← Lists.',
            en: 'Weekly review: open "To review". For each rejection ask: does this look like a real customer (older account, past successful bookings)? '
                'Repeated false rejections mean the rules are too strict. Handle fraud warnings that "need your decision" today: '
                'if the stay has not started, cancel from Booking Desk and refund to avoid the dispute. '
                'If a customer says every card is declined, search their email in Stripe → Radar → Lists.',
            es: 'Revisión semanal: abre "Para revisar". Atiende hoy las alertas de fraude que requieren acción. '
                'Si un cliente dice que todas sus tarjetas se rechazan, busca su email en Stripe → Radar → Lists.'),
        style: const TextStyle(fontSize: 13),
      ),
    );
  }
}

class _RiskTile extends StatelessWidget {
  final Map<String, dynamic> row;
  final bool needsAction;
  final VoidCallback onTap;
  const _RiskTile({required this.row, required this.needsAction, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final decision = '${row['decision']}';
    final b = row['bookings'] is Map ? Map<String, dynamic>.from(row['bookings'] as Map) : <String, dynamic>{};
    final reasons = List<String>.from((row['reasons'] as List?) ?? const []);
    final color = decision == 'allow'
        ? AppColors.success
        : decision == 'reject'
        ? const Color(0xFFD63031)
        : needsAction
        ? const Color(0xFFB71C1C)
        : const Color(0xFF6C5CE7);
    final icon = decision == 'allow'
        ? Icons.verified_user_outlined
        : decision == 'reject'
        ? Icons.block
        : Icons.report_gmailerrorred_outlined;
    final amount = row['amount_usd'] is num ? '\$${(row['amount_usd'] as num).toStringAsFixed(2)}' : '';
    final who = [b['holder_first_name'], b['holder_last_name']].where((e) => e != null).join(' ');
    final summary = reasons.isEmpty
        ? (row['risk_level'] != null ? 'Radar: ${row['risk_level']} · 3DS: ${row['three_ds'] ?? '—'}' : '')
        : reasons.map((r) => _reasonText(context, r)).join(' · ');

    return Card(
      margin: const EdgeInsets.only(bottom: AppSizes.sm),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: needsAction ? color : AppColors.divider),
      ),
      child: ListTile(
        onTap: onTap,
        leading: Icon(icon, color: color),
        title: Text(
          [b['hotel_name'] ?? '—', if (who.isNotEmpty) who].join(' · '),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          '${_fmtTime(row['created_at'])} · ${b['client_reference'] ?? ''}\n$summary',
          style: const TextStyle(fontSize: 12),
        ),
        isThreeLine: true,
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(_decisionLabel(context, decision), style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600)),
            ),
            const SizedBox(height: 4),
            Text(amount, style: const TextStyle(fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}