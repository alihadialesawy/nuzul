import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show Supabase;

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import 'admin_booking_desk_page.dart';
import 'admin_group_requests_page.dart';

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

/// مركز التنبيهات ("مهام اليوم"): كل ما يحتاج تدخّلًا في شاشة واحدة.
/// البيانات من الدالة public.admin_alerts() (للمالك والمساعدين، بلا أرباح).
///
/// الأقسام:
///   1) حجوزات عالقة (needs_attention / processing قديم)  ← Booking Desk
///   2) وصول خلال 48 ساعة                                    ← Booking Desk
///   3) ينتهي الإلغاء المجاني خلال 24 ساعة                    ← Booking Desk
///   4) طلبات مجموعات جديدة                                   ← Group Requests
///   5) طلبات حذف حساب لم تكتمل (مهلة 30 يومًا)
class AdminAlertsPage extends StatefulWidget {
  const AdminAlertsPage({super.key});

  /// عدد التنبيهات المهمة (للشارة في لوحة الإدارة). null عند الخطأ.
  static Future<int?> fetchCount() async {
    try {
      final r = await Supabase.instance.client.rpc('admin_alerts');
      if (r is! Map) return null;
      int n(String k) => (r[k] is List) ? (r[k] as List).length : 0;
      return n('stuck') + n('arrivals') + n('free_cancel_ending') + n('group_requests') + n('deletions');
    } catch (_) {
      return null;
    }
  }

  @override
  State<AdminAlertsPage> createState() => _AdminAlertsPageState();
}

class _AdminAlertsPageState extends State<AdminAlertsPage> {
  bool _loading = true;
  String? _error;
  Map<String, dynamic> _data = const {};

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
      final r = await Supabase.instance.client.rpc('admin_alerts');
      if (!mounted) return;
      setState(() {
        _data = r is Map ? Map<String, dynamic>.from(r) : {};
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

  List<Map<String, dynamic>> _list(String key) {
    final v = _data[key];
    if (v is! List) return const [];
    return v.whereType<Map>().map((m) => Map<String, dynamic>.from(m)).toList();
  }

  Future<void> _openBooking(String? ref) async {
    await Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => AdminBookingDeskPage(initialQuery: ref, initialFilter: 'all'),
    ));
    if (mounted) _load();
  }

  Future<void> _openGroups() async {
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AdminGroupRequestsPage()));
    if (mounted) _load();
  }

  static String _d(dynamic v) {
    final s = '${v ?? ''}';
    return s.length >= 10 ? s.substring(0, 10) : s;
  }

  static String _dt(dynamic v) {
    final d = DateTime.tryParse('${v ?? ''}')?.toLocal();
    if (d == null) return '—';
    String two(int x) => x.toString().padLeft(2, '0');
    return '${d.year}-${two(d.month)}-${two(d.day)} ${two(d.hour)}:${two(d.minute)}';
  }

  String _hoursLeft(BuildContext context, dynamic v) {
    final d = DateTime.tryParse('${v ?? ''}');
    if (d == null) return '';
    final h = d.difference(DateTime.now()).inMinutes / 60;
    final hours = h < 1 ? '<1' : h.toStringAsFixed(0);
    return _t3(context, ar: 'بعد $hours ساعة', en: 'in $hours h', es: 'en $hours h');
  }

  String _arrivalLabel(BuildContext context, dynamic checkIn) {
    final d = DateTime.tryParse('${checkIn ?? ''}');
    if (d == null) return _d(checkIn);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final diff = DateTime(d.year, d.month, d.day).difference(today).inDays;
    if (diff <= 0) return _t3(context, ar: 'اليوم', en: 'Today', es: 'Hoy');
    if (diff == 1) return _t3(context, ar: 'غدًا', en: 'Tomorrow', es: 'Mañana');
    return _d(checkIn);
  }

  void _showDeletion(Map<String, dynamic> d) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(_t3(ctx, ar: 'طلب حذف حساب', en: 'Account deletion request', es: 'Solicitud de eliminación')),
        content: SizedBox(
          width: 460,
          child: SingleChildScrollView(
            child: SelectableText(
              '${_t3(ctx, ar: 'البريد', en: 'Email', es: 'Correo')}: ${d['email'] ?? '—'}\n'
                  '${_t3(ctx, ar: 'الحالة', en: 'Status', es: 'Estado')}: ${d['status']}\n'
                  '${_t3(ctx, ar: 'تاريخ الطلب', en: 'Requested', es: 'Solicitado')}: ${_dt(d['requested_at'])}\n'
                  '${_t3(ctx, ar: 'آخر موعد', en: 'Due by', es: 'Fecha límite')}: ${_dt(d['due'])}\n\n'
                  '${d['details'] ?? ''}\n\n'
                  '${_t3(ctx, ar: 'ملاحظة: "blocked" يعني غالبًا أن للعميل حجزًا قادمًا. راجع حجوزاته قبل الحذف، ثم نفّذ الطلب من Supabase وأبلغه بالبريد.', en: 'Note: "blocked" usually means the guest has an upcoming booking. Review it before deleting, then complete the request in Supabase and email the guest.', es: 'Nota: "blocked" suele indicar una reserva próxima. Revísala antes de eliminar, completa la solicitud en Supabase y avisa al cliente.')}',
            ),
          ),
        ),
        actions: [
          FilledButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_t3(context, ar: 'مهام اليوم', en: 'Action Center', es: 'Centro de tareas')),
        actions: [
          IconButton(
            tooltip: _t3(context, ar: 'تحديث', en: 'Refresh', es: 'Actualizar'),
            icon: const Icon(Icons.refresh),
            onPressed: _loading ? null : _load,
          ),
        ],
      ),
      body: _body(context),
    );
  }

  Widget _body(BuildContext context) {
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
            OutlinedButton(onPressed: _load, child: Text(_t3(context, ar: 'إعادة المحاولة', en: 'Retry', es: 'Reintentar'))),
          ]),
        ),
      );
    }

    final stuck = _list('stuck');
    final arrivals = _list('arrivals');
    final freeCancel = _list('free_cancel_ending');
    final groups = _list('group_requests');
    final deletions = _list('deletions');
    final total = stuck.length + arrivals.length + freeCancel.length + groups.length + deletions.length;

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(AppSizes.md),
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 900),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (total == 0)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: AppSizes.xl),
                      child: Column(children: [
                        const Icon(Icons.task_alt, size: 56, color: Color(0xFF00B894)),
                        const SizedBox(height: AppSizes.sm),
                        Text(
                          _t3(context, ar: 'لا شيء يحتاج تدخّلًا الآن 👍', en: 'Nothing needs attention right now 👍', es: 'Nada requiere atención ahora 👍'),
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                      ]),
                    ),

                  // 1) عالقة
                  _SectionCard(
                    icon: Icons.warning_amber_rounded,
                    color: const Color(0xFFD63031),
                    title: _t3(context, ar: 'حجوزات عالقة', en: 'Stuck bookings', es: 'Reservas bloqueadas'),
                    hint: _t3(context,
                        ar: 'افتح الحجز واضغط "تحقق من HotelBeds" قبل أي إجراء.',
                        en: 'Open the booking and tap "Check with HotelBeds" before acting.',
                        es: 'Abre la reserva y pulsa "Check with HotelBeds" antes de actuar.'),
                    items: [
                      for (final b in stuck)
                        _AlertTile(
                          title: '${b['hotel_name'] ?? '—'} · ${b['guest'] ?? ''}',
                          subtitle: '${b['client_reference'] ?? ''} · ${_d(b['check_in'])} · \$${b['amount'] ?? '—'}\n${b['reason'] ?? ''}',
                          trailing: _dt(b['since']),
                          onTap: () => _openBooking('${b['client_reference'] ?? ''}'),
                        ),
                    ],
                  ),

                  // 2) وصول قريب
                  _SectionCard(
                    icon: Icons.flight_land,
                    color: const Color(0xFF0984E3),
                    title: _t3(context, ar: 'وصول خلال 48 ساعة', en: 'Arrivals in the next 48 hours', es: 'Llegadas en 48 horas'),
                    hint: _t3(context,
                        ar: 'تأكد أن الحجز سليم وأن العميل استلم القسيمة.',
                        en: 'Make sure the booking is fine and the guest has the voucher.',
                        es: 'Comprueba la reserva y que el cliente tenga el bono.'),
                    items: [
                      for (final b in arrivals)
                        _AlertTile(
                          title: '${b['hotel_name'] ?? '—'} · ${b['hotel_city'] ?? ''}',
                          subtitle: '${b['guest'] ?? ''} · HB ${b['supplier_reference'] ?? '—'} · ${b['client_reference'] ?? ''}',
                          trailing: _arrivalLabel(context, b['check_in']),
                          onTap: () => _openBooking('${b['client_reference'] ?? ''}'),
                        ),
                    ],
                  ),

                  // 3) ينتهي الإلغاء المجاني
                  _SectionCard(
                    icon: Icons.timer_outlined,
                    color: const Color(0xFFE17055),
                    title: _t3(context, ar: 'ينتهي الإلغاء المجاني خلال 24 ساعة', en: 'Free cancellation ends within 24 hours', es: 'La cancelación gratuita termina en 24 h'),
                    hint: _t3(context,
                        ar: 'إن طلب العميل الإلغاء ولم يُنفَّذ بعد، ألغِه الآن قبل أن تبدأ الرسوم.',
                        en: 'If the guest asked to cancel and it is not done yet, cancel now before fees apply.',
                        es: 'Si el cliente pidió cancelar y aún no se hizo, cancela ahora antes de que haya cargos.'),
                    items: [
                      for (final b in freeCancel)
                        _AlertTile(
                          title: '${b['hotel_name'] ?? '—'} · ${b['guest'] ?? ''}',
                          subtitle: '${b['client_reference'] ?? ''} · ${_t3(context, ar: 'الوصول', en: 'Check-in', es: 'Llegada')} ${_d(b['check_in'])}',
                          trailing: _hoursLeft(context, b['deadline']),
                          onTap: () => _openBooking('${b['client_reference'] ?? ''}'),
                        ),
                    ],
                  ),

                  // 4) مجموعات
                  _SectionCard(
                    icon: Icons.groups_outlined,
                    color: const Color(0xFF6C5CE7),
                    title: _t3(context, ar: 'طلبات مجموعات جديدة', en: 'New group requests', es: 'Nuevas solicitudes de grupo'),
                    hint: _t3(context,
                        ar: 'لم يُرد عليها بعد (الحالة: new).',
                        en: 'Not answered yet (status: new).',
                        es: 'Aún sin respuesta (estado: new).'),
                    items: [
                      for (final g in groups)
                        _AlertTile(
                          title: '${g['destination'] ?? '—'} · ${g['rooms'] ?? '?'} ${_t3(context, ar: 'غرف', en: 'rooms', es: 'habitaciones')}',
                          subtitle: '${g['contact_name'] ?? ''} · ${_d(g['check_in'])}',
                          trailing: _dt(g['created_at']),
                          onTap: _openGroups,
                        ),
                    ],
                  ),

                  // 5) حذف الحسابات
                  _SectionCard(
                    icon: Icons.person_remove_outlined,
                    color: const Color(0xFF636E72),
                    title: _t3(context, ar: 'طلبات حذف حساب لم تكتمل', en: 'Pending account deletions', es: 'Eliminaciones de cuenta pendientes'),
                    hint: _t3(context,
                        ar: 'وعدنا في سياسة الخصوصية بتنفيذها خلال 30 يومًا.',
                        en: 'Our Privacy Notice promises completion within 30 days.',
                        es: 'Nuestro aviso de privacidad promete completarlas en 30 días.'),
                    items: [
                      for (final d in deletions)
                        _AlertTile(
                          title: '${d['email'] ?? '—'} · ${d['status']}',
                          subtitle: '${_t3(context, ar: 'آخر موعد', en: 'Due by', es: 'Fecha límite')}: ${_d(d['due'])}',
                          trailing: _d(d['requested_at']),
                          onTap: () => _showDeletion(d),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String hint;
  final List<Widget> items;

  const _SectionCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.hint,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    final empty = items.isEmpty;
    return Card(
      margin: const EdgeInsets.only(bottom: AppSizes.md),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: empty ? AppColors.divider : color.withOpacity(0.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: empty ? AppColors.textHint : color),
                const SizedBox(width: AppSizes.sm),
                Expanded(
                  child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                  decoration: BoxDecoration(
                    color: (empty ? AppColors.textHint : color).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${items.length}',
                    style: TextStyle(fontWeight: FontWeight.bold, color: empty ? AppColors.textHint : color),
                  ),
                ),
              ],
            ),
            if (!empty) ...[
              const SizedBox(height: 4),
              Text(hint, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              const SizedBox(height: AppSizes.sm),
              ...items,
            ],
          ],
        ),
      ),
    );
  }
}

class _AlertTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final String trailing;
  final VoidCallback onTap;

  const _AlertTile({required this.title, required this.subtitle, required this.trailing, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                  const SizedBox(height: 2),
                  Text(subtitle.trim(), style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                ],
              ),
            ),
            const SizedBox(width: AppSizes.sm),
            Text(trailing, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
            const Icon(Icons.chevron_right, size: 18, color: AppColors.textHint),
          ],
        ),
      ),
    );
  }
}