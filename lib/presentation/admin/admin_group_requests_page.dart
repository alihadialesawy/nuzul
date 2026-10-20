import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';

/// طلبات حجوزات المجموعات (تبويب Group stays).
///
/// القراءة والتعديل مسموحان للمدير فقط عبر سياسات RLS
/// ("admin reads group requests" و "admin updates group requests")
/// المعتمدة على public.is_admin(). أي مستخدم آخر يرى قائمة فارغة.
///
/// دورة الطلب: new → quoted (أرسلت العرض) → won (تم الحجز) أو lost (رفض/لم يرد).
class AdminGroupRequestsPage extends StatefulWidget {
  const AdminGroupRequestsPage({super.key});

  @override
  State<AdminGroupRequestsPage> createState() => _AdminGroupRequestsPageState();
}

String _t(BuildContext context, {required String ar, required String en}) =>
    Localizations.localeOf(context).languageCode == 'ar' ? ar : en;

const _statuses = ['new', 'quoted', 'won', 'lost'];

Color _statusColor(String s) {
  switch (s) {
    case 'new':
      return const Color(0xFF0984E3);
    case 'quoted':
      return const Color(0xFFE17055);
    case 'won':
      return const Color(0xFF00B894);
    case 'lost':
      return const Color(0xFF636E72);
    default:
      return Colors.grey;
  }
}

String _statusLabel(BuildContext context, String s) {
  switch (s) {
    case 'new':
      return _t(context, ar: 'جديد', en: 'New');
    case 'quoted':
      return _t(context, ar: 'أُرسل العرض', en: 'Quoted');
    case 'won':
      return _t(context, ar: 'تم الحجز', en: 'Won');
    case 'lost':
      return _t(context, ar: 'لم يتم', en: 'Lost');
    default:
      return s;
  }
}

String _occasionLabel(BuildContext context, String? o) {
  switch (o) {
    case 'umrah':
      return _t(context, ar: 'عمرة', en: 'Umrah');
    case 'wedding':
      return _t(context, ar: 'زفاف', en: 'Wedding');
    case 'event':
      return _t(context, ar: 'فعالية', en: 'Event');
    case 'family':
      return _t(context, ar: 'عائلة', en: 'Family');
    case 'tour':
      return _t(context, ar: 'رحلة سياحية', en: 'Tour group');
    default:
      return _t(context, ar: 'أخرى', en: 'Other');
  }
}

int _nights(String checkIn, String checkOut) {
  final a = DateTime.tryParse(checkIn);
  final b = DateTime.tryParse(checkOut);
  if (a == null || b == null) return 0;
  return b.difference(a).inDays;
}

class _AdminGroupRequestsPageState extends State<AdminGroupRequestsPage> {
  final _client = Supabase.instance.client;

  /// null = الكل.
  String? _filter = 'new';
  bool _loading = true;
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
      var query = _client.from('group_stay_requests').select();
      if (_filter != null) query = query.eq('status', _filter!);
      final data = await query.order('created_at', ascending: false).limit(200);
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

  Future<bool> _save(String id, {String? status, String? notes}) async {
    final changes = <String, dynamic>{
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    };
    if (status != null) changes['status'] = status;
    if (notes != null) changes['admin_notes'] = notes.trim().isEmpty ? null : notes.trim();
    try {
      await _client.from('group_stay_requests').update(changes).eq('id', id);
      return true;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_t(context, ar: 'تعذر الحفظ: $e', en: 'Save failed: $e'))),
        );
      }
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_t(context, ar: 'طلبات المجموعات', en: 'Group Requests')),
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
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(AppSizes.md, AppSizes.md, AppSizes.md, AppSizes.sm),
            child: Row(
              children: [
                for (final s in [null, ..._statuses])
                  Padding(
                    padding: const EdgeInsetsDirectional.only(end: 8),
                    child: ChoiceChip(
                      label: Text(s == null ? _t(context, ar: 'الكل', en: 'All') : _statusLabel(context, s)),
                      selected: _filter == s,
                      onSelected: (_) {
                        setState(() => _filter = s);
                        _load();
                      },
                    ),
                  ),
              ],
            ),
          ),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 40),
              const SizedBox(height: AppSizes.sm),
              SelectableText(_error!, textAlign: TextAlign.center),
              const SizedBox(height: AppSizes.md),
              OutlinedButton(onPressed: _load, child: Text(_t(context, ar: 'إعادة المحاولة', en: 'Retry'))),
            ],
          ),
        ),
      );
    }
    if (_rows.isEmpty) {
      return Center(
        child: Text(
          _t(context, ar: 'لا توجد طلبات هنا.', en: 'No requests here.'),
          style: const TextStyle(color: AppColors.textSecondary),
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(AppSizes.md, 0, AppSizes.md, AppSizes.lg),
        itemCount: _rows.length,
        itemBuilder: (context, i) => Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: _RequestCard(
              key: ValueKey(_rows[i]['id']),
              row: _rows[i],
              onStatus: (s) async {
                final ok = await _save(_rows[i]['id'] as String, status: s);
                if (ok && mounted) {
                  setState(() => _rows[i] = {..._rows[i], 'status': s});
                }
                return ok;
              },
              onNotes: (n) => _save(_rows[i]['id'] as String, notes: n),
            ),
          ),
        ),
      ),
    );
  }
}

class _RequestCard extends StatefulWidget {
  final Map<String, dynamic> row;
  final Future<bool> Function(String status) onStatus;
  final Future<bool> Function(String notes) onNotes;

  const _RequestCard({
    super.key,
    required this.row,
    required this.onStatus,
    required this.onNotes,
  });

  @override
  State<_RequestCard> createState() => _RequestCardState();
}

class _RequestCardState extends State<_RequestCard> {
  late final TextEditingController _notes =
  TextEditingController(text: widget.row['admin_notes'] as String? ?? '');
  bool _savingNotes = false;

  @override
  void dispose() {
    _notes.dispose();
    super.dispose();
  }

  void _copy(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(_t(context, ar: 'تم النسخ: $text', en: 'Copied: $text')), duration: const Duration(seconds: 2)),
    );
  }

  Widget _info(String label, String value, {bool copy = false}) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 2),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: 110,
          child: Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
        ),
        Expanded(child: SelectableText(value, style: const TextStyle(fontWeight: FontWeight.w600))),
        if (copy && value.isNotEmpty)
          IconButton(
            visualDensity: VisualDensity.compact,
            iconSize: 18,
            tooltip: _t(context, ar: 'نسخ', en: 'Copy'),
            icon: const Icon(Icons.copy),
            onPressed: () => _copy(value),
          ),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    final r = widget.row;
    final status = r['status'] as String? ?? 'new';
    final checkIn = r['check_in'] as String? ?? '';
    final checkOut = r['check_out'] as String? ?? '';
    final nights = _nights(checkIn, checkOut);
    final rooms = r['rooms'] as int? ?? 0;
    final created = DateTime.tryParse(r['created_at'] as String? ?? '')?.toLocal();
    final createdLabel = created == null
        ? ''
        : '${created.year}-${created.month.toString().padLeft(2, '0')}-${created.day.toString().padLeft(2, '0')} '
        '${created.hour.toString().padLeft(2, '0')}:${created.minute.toString().padLeft(2, '0')}';

    return Card(
      margin: const EdgeInsets.only(bottom: AppSizes.md),
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${r['destination']} · $rooms ${_t(context, ar: 'غرف', en: 'rooms')} · $nights ${_t(context, ar: 'ليالٍ', en: 'nights')}',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _statusColor(status).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _statusLabel(context, status),
                    style: TextStyle(color: _statusColor(status), fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '${_t(context, ar: 'وصل', en: 'Received')}: $createdLabel · ${rooms * nights} ${_t(context, ar: 'ليلة-غرفة', en: 'room-nights')}',
              style: const TextStyle(fontSize: 12, color: AppColors.textHint),
            ),
            const Divider(height: 20),
            _info(_t(context, ar: 'الدخول', en: 'Check-in'), checkIn),
            _info(_t(context, ar: 'الخروج', en: 'Check-out'), checkOut),
            _info(_t(context, ar: 'الضيوف', en: 'Guests'), '${r['guests']}'),
            _info(_t(context, ar: 'المناسبة', en: 'Occasion'), _occasionLabel(context, r['occasion'] as String?)),
            _info(_t(context, ar: 'الاسم', en: 'Name'), r['contact_name'] as String? ?? ''),
            _info(_t(context, ar: 'البريد', en: 'Email'), r['contact_email'] as String? ?? '', copy: true),
            _info(_t(context, ar: 'الهاتف', en: 'Phone'), r['contact_phone'] as String? ?? '', copy: true),
            _info(_t(context, ar: 'اللغة', en: 'Language'), r['language'] as String? ?? '—'),
            if ((r['notes'] as String?)?.isNotEmpty ?? false) ...[
              const SizedBox(height: AppSizes.sm),
              Text(_t(context, ar: 'ملاحظات العميل', en: 'Customer notes'),
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
              const SizedBox(height: 4),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SelectableText(r['notes'] as String),
              ),
            ],
            const SizedBox(height: AppSizes.md),
            Text(_t(context, ar: 'الحالة', en: 'Status'),
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final s in _statuses)
                  ChoiceChip(
                    label: Text(_statusLabel(context, s)),
                    selected: status == s,
                    selectedColor: _statusColor(s).withOpacity(0.2),
                    onSelected: status == s ? null : (_) => widget.onStatus(s),
                  ),
              ],
            ),
            const SizedBox(height: AppSizes.md),
            TextField(
              controller: _notes,
              maxLines: 3,
              maxLength: 2000,
              decoration: InputDecoration(
                labelText: _t(context, ar: 'ملاحظاتك الداخلية (لا يراها العميل)', en: 'Internal notes (not shown to customer)'),
                hintText: _t(context, ar: 'مثال: عرضت 95\$ للغرفة لليلة، ينتظر رده', en: 'e.g. Quoted \$95/room/night, waiting for reply'),
                border: const OutlineInputBorder(),
              ),
            ),
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: FilledButton.icon(
                onPressed: _savingNotes
                    ? null
                    : () async {
                  setState(() => _savingNotes = true);
                  final ok = await widget.onNotes(_notes.text);
                  if (!mounted) return;
                  setState(() => _savingNotes = false);
                  if (ok) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(_t(context, ar: 'تم حفظ الملاحظات', en: 'Notes saved'))),
                    );
                  }
                },
                icon: _savingNotes
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.save_outlined),
                label: Text(_t(context, ar: 'حفظ الملاحظات', en: 'Save notes')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}