import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show Supabase;

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';

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

/// بلاغات المجتمع (شرط آبل Guideline 1.2: التعامل مع البلاغ خلال 24 ساعة).
///
/// لكل منشور/تعليق مُبلَّغ عنه ثلاثة قرارات:
///   • تجاهل   — المحتوى سليم، تُغلق البلاغات.
///   • حذف     — يُحذف المنشور/التعليق (وصوره من Storage).
///   • حذف وإيقاف — تُحذف كل منشورات وتعليقات الكاتب، ويُمنع من النشر.
/// البيانات من admin_community_reports() والإجراء عبر admin_community_action().
class AdminCommunityReportsPage extends StatefulWidget {
  const AdminCommunityReportsPage({super.key});

  @override
  State<AdminCommunityReportsPage> createState() => _AdminCommunityReportsPageState();
}

class _AdminCommunityReportsPageState extends State<AdminCommunityReportsPage> {
  static const _bucket = 'community-images';

  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _items = const [];
  final Set<String> _busy = {};

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
      final r = await Supabase.instance.client.rpc('admin_community_reports');
      if (!mounted) return;
      setState(() {
        _items = (r is List ? r : const [])
            .whereType<Map>()
            .map((m) => Map<String, dynamic>.from(m))
            .toList();
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

  String _key(Map<String, dynamic> it) => '${it['post_id']}|${it['comment_id']}';

  String _reasonLabel(BuildContext context, String r) {
    switch (r) {
      case 'spam':
        return _t3(context, ar: 'إزعاج/إعلان', en: 'Spam', es: 'Spam');
      case 'harassment':
        return _t3(context, ar: 'تحرّش/كراهية', en: 'Harassment/hate', es: 'Acoso/odio');
      case 'sexual':
        return _t3(context, ar: 'جنسي/عُري', en: 'Sexual/nudity', es: 'Sexual/desnudos');
      case 'violence':
        return _t3(context, ar: 'عنف', en: 'Violence', es: 'Violencia');
      case 'scam':
        return _t3(context, ar: 'احتيال', en: 'Scam/false info', es: 'Estafa');
      default:
        return _t3(context, ar: 'أخرى', en: 'Other', es: 'Otro');
    }
  }

  static String _ago(dynamic v) {
    final d = DateTime.tryParse('${v ?? ''}');
    if (d == null) return '';
    final h = DateTime.now().difference(d).inHours;
    if (h < 1) return '<1h';
    if (h < 48) return '${h}h';
    return '${(h / 24).floor()}d';
  }

  /// مسار الملف داخل الـ bucket من الرابط العام.
  static String? _storagePath(String url) {
    const marker = '/object/public/$_bucket/';
    final i = url.indexOf(marker);
    if (i < 0) return null;
    return Uri.decodeComponent(url.substring(i + marker.length).split('?').first);
  }

  Future<void> _act(Map<String, dynamic> it, String action) async {
    final ban = action == 'ban';
    if (action != 'dismiss') {
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(ban
              ? _t3(ctx, ar: 'حذف وإيقاف الكاتب؟', en: 'Remove and ban the author?', es: '¿Eliminar y suspender al autor?')
              : _t3(ctx, ar: 'حذف هذا المحتوى؟', en: 'Remove this content?', es: '¿Eliminar este contenido?')),
          content: Text(ban
              ? _t3(ctx,
              ar: 'ستُحذف كل منشورات وتعليقات ${it['author_email'] ?? 'الكاتب'}، ولن يستطيع النشر في المجتمع بعد الآن. لا يمكن التراجع.',
              en: 'All posts and comments by ${it['author_email'] ?? 'the author'} will be deleted, and they will no longer be able to post. This cannot be undone.',
              es: 'Se eliminarán todas las publicaciones y comentarios del autor y no podrá volver a publicar.')
              : _t3(ctx,
              ar: 'سيُحذف نهائيًا مع صوره. لا يمكن التراجع.',
              en: 'It will be deleted permanently with its photos. This cannot be undone.',
              es: 'Se eliminará definitivamente con sus fotos.')),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(_t3(ctx, ar: 'إلغاء', en: 'Cancel', es: 'Cancelar'))),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: AppColors.error),
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(ban
                  ? _t3(ctx, ar: 'حذف وإيقاف', en: 'Remove & ban', es: 'Eliminar y suspender')
                  : _t3(ctx, ar: 'حذف', en: 'Remove', es: 'Eliminar')),
            ),
          ],
        ),
      );
      if (ok != true || !mounted) return;
    }

    final key = _key(it);
    setState(() => _busy.add(key));
    try {
      final client = Supabase.instance.client;
      final r = await client.rpc('admin_community_action', params: {
        'p_post_id': it['post_id'],
        'p_comment_id': it['comment_id'],
        'p_action': action,
      });

      // حذف صور المحتوى المحذوف من Storage (حتى لا تبقى متاحة برابطها).
      final images = (r is Map && r['images'] is List) ? (r['images'] as List) : const [];
      final paths = images.map((u) => _storagePath('$u')).whereType<String>().toList();
      if (paths.isNotEmpty) {
        try {
          await client.storage.from(_bucket).remove(paths);
        } catch (_) {
          // المحتوى حُذف من قاعدة البيانات؛ فشل حذف الصورة لا يوقف الإجراء.
        }
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(action == 'dismiss'
            ? _t3(context, ar: 'أُغلق البلاغ.', en: 'Report dismissed.', es: 'Denuncia descartada.')
            : _t3(context, ar: 'تم الحذف.', en: 'Removed.', es: 'Eliminado.')),
      ));
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e'), backgroundColor: AppColors.error));
    } finally {
      if (mounted) setState(() => _busy.remove(key));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_t3(context, ar: 'بلاغات المجتمع', en: 'Community Reports', es: 'Denuncias de la comunidad')),
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

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(AppSizes.md),
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 820),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppSizes.sm),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _t3(context,
                          ar: 'تعامل مع كل بلاغ خلال 24 ساعة (شرط آبل). "حذف وإيقاف" للمحتوى الجنسي أو الكراهية أو الاحتيال أو تكرار المخالفة.',
                          en: 'Handle every report within 24 hours (Apple requirement). Use "Remove & ban" for sexual content, hate, scams, or repeat offenders.',
                          es: 'Atiende cada denuncia en 24 horas (requisito de Apple).'),
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ),
                  const SizedBox(height: AppSizes.md),
                  if (_items.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: AppSizes.xl),
                      child: Column(children: [
                        const Icon(Icons.verified_user_outlined, size: 56, color: Color(0xFF00B894)),
                        const SizedBox(height: AppSizes.sm),
                        Text(
                          _t3(context, ar: 'لا توجد بلاغات مفتوحة 👍', en: 'No open reports 👍', es: 'No hay denuncias abiertas 👍'),
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                      ]),
                    ),
                  for (final it in _items) _reportCard(context, it),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _reportCard(BuildContext context, Map<String, dynamic> it) {
    final isComment = it['kind'] == 'comment';
    final reasons = (it['reasons'] is List) ? (it['reasons'] as List).map((e) => '$e').toList() : <String>[];
    final details = (it['details'] is List) ? (it['details'] as List).map((e) => '$e').toList() : <String>[];
    final images = (it['images'] is List) ? (it['images'] as List).map((e) => '$e').toList() : <String>[];
    final busy = _busy.contains(_key(it));
    final banned = it['author_banned'] == true;
    final hours = DateTime.tryParse('${it['first_reported_at'] ?? ''}');
    final overdue = hours != null && DateTime.now().difference(hours).inHours >= 24;

    return Card(
      margin: const EdgeInsets.only(bottom: AppSizes.md),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: overdue ? AppColors.error : AppColors.divider, width: overdue ? 1.5 : 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(isComment ? Icons.mode_comment_outlined : Icons.photo_outlined, size: 18),
                const SizedBox(width: 6),
                Text(
                  isComment
                      ? _t3(context, ar: 'تعليق', en: 'Comment', es: 'Comentario')
                      : _t3(context, ar: 'منشور', en: 'Post', es: 'Publicación'),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.error.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${it['reports']} ${_t3(context, ar: 'بلاغ', en: 'report(s)', es: 'denuncia(s)')}',
                    style: const TextStyle(fontSize: 12, color: AppColors.error, fontWeight: FontWeight.w600),
                  ),
                ),
                const Spacer(),
                Text(
                  _ago(it['first_reported_at']),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: overdue ? AppColors.error : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final r in reasons)
                  Chip(
                    visualDensity: VisualDensity.compact,
                    label: Text(_reasonLabel(context, r), style: const TextStyle(fontSize: 12)),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            if ('${it['text'] ?? ''}'.trim().isNotEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSizes.sm),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SelectableText('${it['text']}'),
              ),
            if (images.isNotEmpty) ...[
              const SizedBox(height: 8),
              SizedBox(
                height: 90,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: images.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 6),
                  itemBuilder: (_, i) => ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: Image.network(
                      images[i],
                      width: 90,
                      height: 90,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        width: 90,
                        height: 90,
                        color: AppColors.divider,
                        child: const Icon(Icons.broken_image_outlined),
                      ),
                    ),
                  ),
                ),
              ),
            ],
            if (details.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                _t3(context, ar: 'ملاحظات المبلّغين:', en: 'Reporter notes:', es: 'Notas:'),
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              ),
              for (final d in details)
                Text('• $d', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
            ],
            const SizedBox(height: 8),
            Text(
              '${_t3(context, ar: 'الكاتب', en: 'Author', es: 'Autor')}: '
                  '${it['author_name'] ?? '—'} · ${it['author_email'] ?? '—'}'
                  '${banned ? ' · ${_t3(context, ar: 'موقوف', en: 'BANNED', es: 'SUSPENDIDO')}' : ''}',
              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
            const Divider(height: AppSizes.lg),
            if (busy)
              const Center(child: Padding(padding: EdgeInsets.all(8), child: CircularProgressIndicator()))
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.end,
                children: [
                  OutlinedButton.icon(
                    onPressed: () => _act(it, 'dismiss'),
                    icon: const Icon(Icons.check, size: 18),
                    label: Text(_t3(context, ar: 'تجاهل (سليم)', en: 'Dismiss (OK)', es: 'Descartar')),
                  ),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(foregroundColor: AppColors.error),
                    onPressed: () => _act(it, 'remove'),
                    icon: const Icon(Icons.delete_outline, size: 18),
                    label: Text(_t3(context, ar: 'حذف المحتوى', en: 'Remove', es: 'Eliminar')),
                  ),
                  if (!banned)
                    FilledButton.icon(
                      style: FilledButton.styleFrom(backgroundColor: AppColors.error),
                      onPressed: () => _act(it, 'ban'),
                      icon: const Icon(Icons.block, size: 18),
                      label: Text(_t3(context, ar: 'حذف وإيقاف الكاتب', en: 'Remove & ban', es: 'Eliminar y suspender')),
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}