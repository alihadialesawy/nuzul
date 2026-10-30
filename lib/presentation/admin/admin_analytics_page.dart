import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart' show NumberFormat;
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

/// التحليلات — للمالك فقط (super_admin). البيانات من public.admin_analytics().
///
/// • مؤشرات: الزيارات، الزوار، الحسابات الجديدة، الحجوزات، الإيراد، الربح، التحويل.
/// • رسوم يومية: الإيراد، والزيارات والتسجيلات.
/// • الانتشار: الزوار حسب الدولة/الولاية/المدينة، والعملاء حسب الولاية،
///   والتسجيلات حسب الدولة، وأكثر الوجهات حجزًا.
/// • المنصات (ويب/أندرويد/آيفون) وحالات الحجوزات.
///
/// الرسوم مرسومة بـ CustomPainter (بلا مكتبات إضافية).
/// بيانات الزوار تبدأ من يوم نشر track-visit؛ وولاية العميل من أول حجز بعد نشر hotelbeds-book الجديد.
class AdminAnalyticsPage extends StatefulWidget {
  const AdminAnalyticsPage({super.key});

  @override
  State<AdminAnalyticsPage> createState() => _AdminAnalyticsPageState();
}

class _AdminAnalyticsPageState extends State<AdminAnalyticsPage> {
  int _days = 30;
  bool _loading = true;
  String? _error;
  Map<String, dynamic> _data = const {};
  String _geoLevel = 'country'; // country / region / city

  /// تحديث تلقائي كل دقيقة ما دامت الشاشة مفتوحة (بدون إخفاء الرسوم).
  static const _autoRefresh = Duration(seconds: 60);
  Timer? _timer;
  bool _refreshing = false;
  DateTime? _updatedAt;

  static final _money = NumberFormat('#,##0', 'en_US');

  @override
  void initState() {
    super.initState();
    _load();
    _timer = Timer.periodic(_autoRefresh, (_) => _load(silent: true));
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  /// [silent]: تحديث في الخلفية — تبقى الرسوم الحالية ظاهرة حتى تصل الجديدة.
  Future<void> _load({bool silent = false}) async {
    if (silent && (_loading || _refreshing)) return;
    setState(() {
      if (silent) {
        _refreshing = true;
      } else {
        _loading = true;
        _error = null;
      }
    });
    final now = DateTime.now();
    final to = DateTime(now.year, now.month, now.day + 1);
    final from = to.subtract(Duration(days: _days));
    try {
      final r = await Supabase.instance.client.rpc('admin_analytics', params: {
        'p_from': from.toUtc().toIso8601String(),
        'p_to': to.toUtc().toIso8601String(),
      });
      if (!mounted) return;
      setState(() {
        _data = r is Map ? Map<String, dynamic>.from(r) : {};
        _loading = false;
        _refreshing = false;
        _error = null;
        _updatedAt = DateTime.now();
      });
    } catch (e) {
      if (!mounted) return;
      if (silent && _data.isNotEmpty) {
        setState(() => _refreshing = false);
        return;
      }
      setState(() {
        _refreshing = false;
        _error = '$e'.contains('forbidden')
            ? _t3(context, ar: 'هذه الشاشة للمالك فقط.', en: 'This screen is for the owner only.', es: 'Solo para el propietario.')
            : '$e';
        _loading = false;
      });
    }
  }

  List<Map<String, dynamic>> _list(String key) {
    final v = _data[key];
    if (v is! List) return const [];
    return v.whereType<Map>().map((m) => Map<String, dynamic>.from(m)).toList();
  }

  num _kpi(String k) => ((_data['kpis'] as Map?)?[k] as num?) ?? 0;

  /// "US" → "🇺🇸 US"
  static String _flag(String code) {
    final c = code.trim().toUpperCase();
    if (c.length != 2 || !RegExp(r'^[A-Z]{2}$').hasMatch(c)) return code;
    final f = String.fromCharCodes(c.codeUnits.map((u) => 0x1F1E6 + u - 65));
    return '$f $c';
  }

  @override
  Widget build(BuildContext context) {
    final periods = <(int, String)>[
      (7, _t3(context, ar: '7 أيام', en: '7 days', es: '7 días')),
      (30, _t3(context, ar: '30 يومًا', en: '30 days', es: '30 días')),
      (90, _t3(context, ar: '90 يومًا', en: '90 days', es: '90 días')),
      (365, _t3(context, ar: 'سنة', en: '12 months', es: '12 meses')),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(_t3(context, ar: 'التحليلات', en: 'Analytics', es: 'Analítica')),
        actions: [
          _AutoRefreshBadge(updatedAt: _updatedAt, refreshing: _refreshing),
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loading ? null : () => _load()),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSizes.md),
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1200),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Wrap(spacing: 8, runSpacing: 8, children: [
                    for (final p in periods)
                      ChoiceChip(
                        label: Text(p.$2),
                        selected: _days == p.$1,
                        onSelected: _loading
                            ? null
                            : (_) {
                          _days = p.$1;
                          _load();
                        },
                      ),
                  ]),
                  const SizedBox(height: AppSizes.md),
                  if (_loading)
                    const Padding(padding: EdgeInsets.all(AppSizes.xl), child: Center(child: CircularProgressIndicator()))
                  else if (_error != null)
                    Padding(
                      padding: const EdgeInsets.all(AppSizes.lg),
                      child: SelectableText(_error!, style: const TextStyle(color: Colors.red)),
                    )
                  else
                    ..._content(context),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _content(BuildContext context) {
    final daily = _list('daily');
    final xLabels = daily.map((d) {
      final s = '${d['day']}';
      return s.length >= 10 ? s.substring(5, 10) : s;
    }).toList();
    double v(Map<String, dynamic> m, String k) => ((m[k] as num?) ?? 0).toDouble();

    final uniqueVisitors = _kpi('unique_visitors');
    final customers = _kpi('booking_customers');
    final conversion = uniqueVisitors > 0 ? customers * 100 / uniqueVisitors : null;
    final profit = _kpi('profit_est');

    final geoKey = _geoLevel == 'country'
        ? 'visitor_countries'
        : _geoLevel == 'region'
        ? 'visitor_regions'
        : 'visitor_cities';
    final geoItems = _list(geoKey)
        .map((m) => (
    _geoLevel == 'country' ? _flag('${m['label']}') : '${m['label']}',
    ((m['value'] as num?) ?? 0).toDouble(),
    ))
        .toList();

    final wide = MediaQuery.of(context).size.width >= 900;
    Widget pair(Widget a, Widget b) => wide
        ? Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Expanded(child: a),
      const SizedBox(width: AppSizes.md),
      Expanded(child: b),
    ])
        : Column(children: [a, const SizedBox(height: AppSizes.md), b]);

    return [
      // ── المؤشرات ──
      Wrap(spacing: 8, runSpacing: 8, children: [
        _Kpi(label: _t3(context, ar: 'الزيارات', en: 'Visits', es: 'Visitas'), value: '${_kpi('visits')}', icon: Icons.visibility_outlined, color: const Color(0xFF0984E3)),
        _Kpi(label: _t3(context, ar: 'زوار مختلفون', en: 'Unique visitors', es: 'Visitantes únicos'), value: '$uniqueVisitors', icon: Icons.people_outline, color: const Color(0xFF6C5CE7)),
        _Kpi(label: _t3(context, ar: 'حسابات جديدة', en: 'New accounts', es: 'Cuentas nuevas'), value: '${_kpi('signups')}', icon: Icons.person_add_alt, color: const Color(0xFF00B894), sub: '${_t3(context, ar: 'الإجمالي', en: 'Total', es: 'Total')}: ${_kpi('total_users')}'),
        _Kpi(label: _t3(context, ar: 'حجوزات مدفوعة', en: 'Paid bookings', es: 'Reservas pagadas'), value: '${_kpi('bookings')}', icon: Icons.hotel_outlined, color: const Color(0xFFE17055)),
        _Kpi(label: _t3(context, ar: 'صافي الإيراد', en: 'Net revenue', es: 'Ingreso neto'), value: '\$${_money.format(_kpi('net_revenue'))}', icon: Icons.payments_outlined, color: const Color(0xFF2D3436)),
        _Kpi(label: _t3(context, ar: 'الربح (تقدير)', en: 'Profit (est.)', es: 'Ganancia (est.)'), value: '\$${_money.format(profit)}', icon: Icons.trending_up, color: profit < 0 ? Colors.red : const Color(0xFF00B894)),
        _Kpi(label: _t3(context, ar: 'التحويل', en: 'Conversion', es: 'Conversión'), value: conversion == null ? '—' : '${conversion.toStringAsFixed(1)}%', icon: Icons.filter_alt_outlined, color: const Color(0xFFFDCB6E), sub: _t3(context, ar: 'زائر ← حجز', en: 'visitor → booking', es: 'visitante → reserva')),
      ]),
      const SizedBox(height: AppSizes.md),

      // ── الرسوم اليومية ──
      pair(
        _Panel(
          title: _t3(context, ar: 'الإيراد اليومي (USD)', en: 'Daily revenue (USD)', es: 'Ingreso diario (USD)'),
          child: _LineChart(
            xLabels: xLabels,
            series: [
              _Series(_t3(context, ar: 'الإيراد', en: 'Revenue', es: 'Ingreso'), const Color(0xFF00B894), daily.map((d) => v(d, 'revenue')).toList()),
            ],
            money: true,
          ),
        ),
        _Panel(
          title: _t3(context, ar: 'الزيارات والتسجيلات والحجوزات يوميًا', en: 'Daily visits, sign-ups & bookings', es: 'Visitas, registros y reservas'),
          child: _LineChart(
            xLabels: xLabels,
            series: [
              _Series(_t3(context, ar: 'زيارات', en: 'Visits', es: 'Visitas'), const Color(0xFF0984E3), daily.map((d) => v(d, 'visits')).toList()),
              _Series(_t3(context, ar: 'تسجيلات', en: 'Sign-ups', es: 'Registros'), const Color(0xFF6C5CE7), daily.map((d) => v(d, 'signups')).toList()),
              _Series(_t3(context, ar: 'حجوزات', en: 'Bookings', es: 'Reservas'), const Color(0xFFE17055), daily.map((d) => v(d, 'bookings')).toList()),
            ],
          ),
        ),
      ),
      const SizedBox(height: AppSizes.md),

      // ── الانتشار ──
      pair(
        _Panel(
          title: _t3(context, ar: 'الزوار حول العالم', en: 'Visitors around the world', es: 'Visitantes en el mundo'),
          trailing: SegmentedButton<String>(
            showSelectedIcon: false,
            style: const ButtonStyle(visualDensity: VisualDensity.compact),
            segments: [
              ButtonSegment(value: 'country', label: Text(_t3(context, ar: 'دول', en: 'Countries', es: 'Países'))),
              ButtonSegment(value: 'region', label: Text(_t3(context, ar: 'ولايات', en: 'States', es: 'Estados'))),
              ButtonSegment(value: 'city', label: Text(_t3(context, ar: 'مدن', en: 'Cities', es: 'Ciudades'))),
            ],
            selected: {_geoLevel},
            onSelectionChanged: (s) => setState(() => _geoLevel = s.first),
          ),
          child: _RankedBars(items: geoItems, color: const Color(0xFF0984E3), empty: _noDataYet(context)),
        ),
        _Panel(
          title: _t3(context, ar: 'العملاء حسب الولاية (عنوان البطاقة)', en: 'Customers by state (card billing)', es: 'Clientes por estado'),
          child: _RankedBars(
            items: _list('customer_states').map((m) => ('${m['label']}', ((m['value'] as num?) ?? 0).toDouble())).toList(),
            color: const Color(0xFFE17055),
            empty: _noDataYet(context),
          ),
        ),
      ),
      const SizedBox(height: AppSizes.md),
      pair(
        _Panel(
          title: _t3(context, ar: 'الحسابات الجديدة حسب الدولة', en: 'New accounts by country', es: 'Cuentas nuevas por país'),
          child: _RankedBars(
            items: _list('signup_countries').map((m) => (_flag('${m['label']}'), ((m['value'] as num?) ?? 0).toDouble())).toList(),
            color: const Color(0xFF6C5CE7),
            empty: _noDataYet(context),
          ),
        ),
        _Panel(
          title: _t3(context, ar: 'أكثر الوجهات حجزًا', en: 'Top booked destinations', es: 'Destinos más reservados'),
          child: _RankedBars(
            items: _list('destinations').map((m) => ('${m['label']}', ((m['value'] as num?) ?? 0).toDouble())).toList(),
            color: const Color(0xFF00B894),
            empty: _t3(context, ar: 'لا حجوزات في هذه الفترة.', en: 'No bookings in this period.', es: 'Sin reservas en este periodo.'),
          ),
        ),
      ),
      const SizedBox(height: AppSizes.md),

      // ── المنصات وحالات الحجوزات ──
      pair(
        _Panel(
          title: _t3(context, ar: 'المنصات (الزيارات)', en: 'Platforms (visits)', es: 'Plataformas (visitas)'),
          child: _Donut(
            items: _list('platforms').map((m) => ('${m['label']}', ((m['value'] as num?) ?? 0).toDouble())).toList(),
            empty: _noDataYet(context),
          ),
        ),
        _Panel(
          title: _t3(context, ar: 'حالات محاولات الحجز', en: 'Booking attempts by status', es: 'Intentos de reserva por estado'),
          child: _Donut(
            items: _list('statuses').map((m) => ('${m['label']}', ((m['value'] as num?) ?? 0).toDouble())).toList(),
            empty: _t3(context, ar: 'لا محاولات في هذه الفترة.', en: 'No attempts in this period.', es: 'Sin intentos en este periodo.'),
          ),
        ),
      ),
      const SizedBox(height: AppSizes.sm),
      Text(
        _t3(context,
            ar: 'الموقع تقريبي (من عنوان IP، ولا يُحفظ العنوان نفسه). بيانات الزوار تبدأ من يوم تفعيل التسجيل، والزيارات من وضع التطوير لا تُحتسب. ولاية العميل من عنوان فاتورة البطاقة.',
            en: 'Locations are approximate (from IP; the IP itself is not stored). Visitor data starts when tracking was enabled; development runs are not counted. Customer state comes from the card billing address.',
            es: 'Ubicaciones aproximadas (por IP; la IP no se guarda). Los datos de visitantes empiezan al activar el registro.'),
        style: const TextStyle(fontSize: 12, color: AppColors.textHint),
      ),
    ];
  }

  String _noDataYet(BuildContext context) => _t3(context,
      ar: 'لا بيانات بعد. ستظهر بعد نشر التحديث وبدء الزيارات.',
      en: 'No data yet. It will appear once the update is live and visits come in.',
      es: 'Aún no hay datos.');
}

// ───────────────────────── مكوّنات ─────────────────────────

class _Kpi extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final String? sub;
  const _Kpi({required this.label, required this.value, required this.icon, required this.color, this.sub});

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 165,
    child: Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.md),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 6),
            Expanded(child: Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary), overflow: TextOverflow.ellipsis)),
          ]),
          const SizedBox(height: 6),
          Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color == const Color(0xFFFDCB6E) ? null : color)),
          if (sub != null) Text(sub!, style: const TextStyle(fontSize: 11, color: AppColors.textHint)),
        ]),
      ),
    ),
  );
}

class _Panel extends StatelessWidget {
  final String title;
  final Widget child;
  final Widget? trailing;
  const _Panel({required this.title, required this.child, this.trailing});

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(AppSizes.md),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 8,
          runSpacing: 8,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            if (trailing != null) trailing!,
          ],
        ),
        const SizedBox(height: AppSizes.md),
        child,
      ]),
    ),
  );
}

class _Series {
  final String name;
  final Color color;
  final List<double> values;
  const _Series(this.name, this.color, this.values);
}

/// رسم خطي بسيط لسلسلة أو أكثر على نفس المحور.
class _LineChart extends StatelessWidget {
  final List<String> xLabels;
  final List<_Series> series;
  final bool money;
  const _LineChart({required this.xLabels, required this.series, this.money = false});

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      if (series.length > 1)
        Wrap(spacing: 12, children: [
          for (final s in series)
            Row(mainAxisSize: MainAxisSize.min, children: [
              Container(width: 10, height: 10, decoration: BoxDecoration(color: s.color, shape: BoxShape.circle)),
              const SizedBox(width: 4),
              Text(s.name, style: const TextStyle(fontSize: 12)),
            ]),
        ]),
      const SizedBox(height: 8),
      Directionality(
        // المحور الزمني من اليسار لليمين دائمًا.
        textDirection: TextDirection.ltr,
        child: SizedBox(
          height: 200,
          width: double.infinity,
          child: CustomPaint(painter: _LinePainter(series: series, xLabels: xLabels, money: money)),
        ),
      ),
    ]);
  }
}

class _LinePainter extends CustomPainter {
  final List<_Series> series;
  final List<String> xLabels;
  final bool money;
  _LinePainter({required this.series, required this.xLabels, required this.money});

  static final _fmt = NumberFormat.compact(locale: 'en_US');

  void _text(Canvas c, String s, Offset at, {TextAlign align = TextAlign.left, double size = 10}) {
    final tp = TextPainter(
      text: TextSpan(text: s, style: TextStyle(fontSize: size, color: const Color(0xFF9CA3AF))),
      textDirection: TextDirection.ltr,
    )..layout();
    var dx = at.dx;
    if (align == TextAlign.right) dx -= tp.width;
    if (align == TextAlign.center) dx -= tp.width / 2;
    tp.paint(c, Offset(dx, at.dy - tp.height / 2));
  }

  @override
  void paint(Canvas canvas, Size size) {
    const left = 44.0, bottom = 20.0, top = 6.0, right = 8.0;
    final w = size.width - left - right;
    final h = size.height - top - bottom;
    final n = series.isEmpty ? 0 : series.map((s) => s.values.length).reduce(math.max);

    var maxV = 0.0;
    for (final s in series) {
      for (final v in s.values) {
        if (v > maxV) maxV = v;
      }
    }
    if (maxV <= 0) maxV = 1;
    // تقريب الحد الأعلى لرقم مريح.
    final mag = math.pow(10, (math.log(maxV) / math.ln10).floor()).toDouble();
    maxV = (maxV / mag).ceil() * mag;

    final grid = Paint()
      ..color = const Color(0xFFE5E7EB)
      ..strokeWidth = 1;
    for (var i = 0; i <= 4; i++) {
      final y = top + h - h * i / 4;
      canvas.drawLine(Offset(left, y), Offset(left + w, y), grid);
      final val = maxV * i / 4;
      _text(canvas, money ? '\$${_fmt.format(val)}' : _fmt.format(val), Offset(left - 6, y), align: TextAlign.right);
    }

    if (n == 0) return;
    double xAt(int i) => n == 1 ? left + w / 2 : left + w * i / (n - 1);
    double yAt(double v) => top + h - h * (v / maxV);

    // تسميات المحور الأفقي: أول، منتصف، آخر.
    final idx = <int>{0, n ~/ 2, n - 1};
    for (final i in idx) {
      if (i < xLabels.length) {
        _text(canvas, xLabels[i], Offset(xAt(i), size.height - 8),
            align: i == 0 ? TextAlign.left : (i == n - 1 ? TextAlign.right : TextAlign.center));
      }
    }

    for (var si = 0; si < series.length; si++) {
      final s = series[si];
      if (s.values.isEmpty) continue;
      final path = Path()..moveTo(xAt(0), yAt(s.values[0]));
      for (var i = 1; i < s.values.length; i++) {
        path.lineTo(xAt(i), yAt(s.values[i]));
      }
      if (si == 0) {
        final area = Path.from(path)
          ..lineTo(xAt(s.values.length - 1), top + h)
          ..lineTo(xAt(0), top + h)
          ..close();
        canvas.drawPath(area, Paint()..color = s.color.withOpacity(0.10));
      }
      canvas.drawPath(
        path,
        Paint()
          ..color = s.color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..strokeJoin = StrokeJoin.round,
      );
      if (s.values.length <= 31) {
        final dot = Paint()..color = s.color;
        for (var i = 0; i < s.values.length; i++) {
          if (s.values[i] > 0) canvas.drawCircle(Offset(xAt(i), yAt(s.values[i])), 2.5, dot);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _LinePainter old) => old.series != series || old.xLabels != xLabels;
}

/// قائمة مرتّبة بأشرطة أفقية (الأكثر أولًا).
class _RankedBars extends StatelessWidget {
  final List<(String, double)> items;
  final Color color;
  final String empty;
  const _RankedBars({required this.items, required this.color, required this.empty});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSizes.md),
        child: Text(empty, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
      );
    }
    final maxV = items.map((e) => e.$2).fold<double>(0, math.max);
    final total = items.map((e) => e.$2).fold<double>(0, (a, b) => a + b);
    return Column(children: [
      for (final it in items.take(10))
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(children: [
            SizedBox(
              width: 150,
              child: Text(it.$1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13)),
            ),
            Expanded(
              child: LayoutBuilder(
                builder: (context, c) => Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: Container(
                    height: 14,
                    width: maxV <= 0 ? 0 : math.max(3, c.maxWidth * it.$2 / maxV),
                    decoration: BoxDecoration(color: color.withOpacity(0.75), borderRadius: BorderRadius.circular(4)),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 70,
              child: Text(
                '${it.$2.toStringAsFixed(0)}  ${total > 0 ? '(${(it.$2 * 100 / total).toStringAsFixed(0)}%)' : ''}',
                textAlign: TextAlign.end,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ),
          ]),
        ),
    ]);
  }
}

/// رسم دائري (Donut) مع مفتاح الألوان.
class _Donut extends StatelessWidget {
  final List<(String, double)> items;
  final String empty;
  const _Donut({required this.items, required this.empty});

  static const _palette = [
    Color(0xFF0984E3), Color(0xFF00B894), Color(0xFFE17055), Color(0xFF6C5CE7),
    Color(0xFFFDCB6E), Color(0xFFD63031), Color(0xFF636E72), Color(0xFF00CEC9),
  ];

  @override
  Widget build(BuildContext context) {
    final total = items.map((e) => e.$2).fold<double>(0, (a, b) => a + b);
    if (items.isEmpty || total <= 0) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSizes.md),
        child: Text(empty, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
      );
    }
    return Row(children: [
      SizedBox(
        width: 140,
        height: 140,
        child: CustomPaint(
          painter: _DonutPainter(items.map((e) => e.$2).toList(), _palette),
          child: Center(
            child: Text(total.toStringAsFixed(0), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          ),
        ),
      ),
      const SizedBox(width: AppSizes.md),
      Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          for (var i = 0; i < items.length; i++)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(children: [
                Container(width: 10, height: 10, decoration: BoxDecoration(color: _palette[i % _palette.length], shape: BoxShape.circle)),
                const SizedBox(width: 6),
                Expanded(child: Text(items[i].$1, style: const TextStyle(fontSize: 13))),
                Text('${items[i].$2.toStringAsFixed(0)} (${(items[i].$2 * 100 / total).toStringAsFixed(0)}%)',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
              ]),
            ),
        ]),
      ),
    ]);
  }
}

class _DonutPainter extends CustomPainter {
  final List<double> values;
  final List<Color> palette;
  _DonutPainter(this.values, this.palette);

  @override
  void paint(Canvas canvas, Size size) {
    final total = values.fold<double>(0, (a, b) => a + b);
    if (total <= 0) return;
    final rect = Rect.fromLTWH(10, 10, size.width - 20, size.height - 20);
    var start = -math.pi / 2;
    for (var i = 0; i < values.length; i++) {
      final sweep = 2 * math.pi * values[i] / total;
      canvas.drawArc(
        rect,
        start,
        sweep,
        false,
        Paint()
          ..color = palette[i % palette.length]
          ..style = PaintingStyle.stroke
          ..strokeWidth = 18,
      );
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter old) => old.values != values;
}

/// "تحديث تلقائي · آخر تحديث 8:41 م" في شريط العنوان.
class _AutoRefreshBadge extends StatelessWidget {
  final DateTime? updatedAt;
  final bool refreshing;
  const _AutoRefreshBadge({required this.updatedAt, required this.refreshing});

  @override
  Widget build(BuildContext context) {
    final ar = Localizations.localeOf(context).languageCode == 'ar';
    final t = updatedAt == null ? '' : TimeOfDay.fromDateTime(updatedAt!).format(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        refreshing
            ? const SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 2))
            : const Icon(Icons.autorenew, size: 16, color: Color(0xFF00B894)),
        const SizedBox(width: 6),
        Text(
          ar ? 'تحديث تلقائي${t.isEmpty ? '' : ' · $t'}' : 'Auto-refresh${t.isEmpty ? '' : ' · $t'}',
          style: const TextStyle(fontSize: 12),
        ),
      ]),
    );
  }
}