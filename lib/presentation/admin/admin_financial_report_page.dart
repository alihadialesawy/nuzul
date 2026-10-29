import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show Supabase;

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../core/pdf/flynoom_pdf.dart';

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

/// التقارير المالية — للمالك فقط (super_admin).
/// البيانات من public.admin_financial_report() التي ترفض أي أحد غير is_owner().
///
/// • اختيار الفترة (هذا الشهر، الشهر الماضي، هذه السنة، السنة الماضية، فترة مخصصة).
/// • ملخص + جدول حجز في كل سطر + حسب المدينة.
/// • طباعة / حفظ PDF، وتنزيل CSV (Excel) للمحاسب.
///
/// ⚠️ تقرير إداري: رسوم Stripe تقديرية (2.9% + 0.30$). المصادر الرسمية للمحاسب
/// هي كشوف Stripe وكشوف/فواتير HotelBeds.
class AdminFinancialReportPage extends StatefulWidget {
  const AdminFinancialReportPage({super.key});

  @override
  State<AdminFinancialReportPage> createState() => _AdminFinancialReportPageState();
}

enum _Period { thisMonth, lastMonth, thisYear, lastYear, custom }

class _AdminFinancialReportPageState extends State<AdminFinancialReportPage> {
  _Period _period = _Period.thisMonth;
  late DateTime _from; // شامل
  late DateTime _to; // غير شامل
  bool _loading = true;
  bool _exporting = false;
  String? _error;
  Map<String, dynamic> _data = const {};

  static final _money = NumberFormat('#,##0.00', 'en_US');

  @override
  void initState() {
    super.initState();
    _applyPeriod(_Period.thisMonth);
  }

  void _applyPeriod(_Period p, {DateTimeRange? custom}) {
    final now = DateTime.now();
    switch (p) {
      case _Period.thisMonth:
        _from = DateTime(now.year, now.month);
        _to = DateTime(now.year, now.month + 1);
        break;
      case _Period.lastMonth:
        _from = DateTime(now.year, now.month - 1);
        _to = DateTime(now.year, now.month);
        break;
      case _Period.thisYear:
        _from = DateTime(now.year);
        _to = DateTime(now.year + 1);
        break;
      case _Period.lastYear:
        _from = DateTime(now.year - 1);
        _to = DateTime(now.year);
        break;
      case _Period.custom:
        if (custom == null) return;
        _from = DateTime(custom.start.year, custom.start.month, custom.start.day);
        _to = DateTime(custom.end.year, custom.end.month, custom.end.day + 1);
        break;
    }
    _period = p;
    _load();
  }

  Future<void> _pickCustom() async {
    final now = DateTime.now();
    final r = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2026),
      lastDate: DateTime(now.year + 1, 12, 31),
      initialDateRange: DateTimeRange(start: _from, end: _to.subtract(const Duration(days: 1))),
    );
    if (r != null) _applyPeriod(_Period.custom, custom: r);
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final r = await Supabase.instance.client.rpc('admin_financial_report', params: {
        'p_from': _from.toUtc().toIso8601String(),
        'p_to': _to.toUtc().toIso8601String(),
      });
      if (!mounted) return;
      setState(() {
        _data = r is Map ? Map<String, dynamic>.from(r) : {};
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = '$e'.contains('forbidden')
            ? _t3(context, ar: 'هذا التقرير للمالك فقط.', en: 'This report is for the owner only.', es: 'Este informe es solo para el propietario.')
            : '$e';
        _loading = false;
      });
    }
  }

  String get _periodLabel {
    final f = DateFormat('MMM d, yyyy', 'en_US');
    return '${f.format(_from)} – ${f.format(_to.subtract(const Duration(days: 1)))}';
  }

  String get _fileStem => 'Flynoom-Report-${DateFormat('yyyyMMdd').format(_from)}-'
      '${DateFormat('yyyyMMdd').format(_to.subtract(const Duration(days: 1)))}';

  Future<void> _export(String kind) async {
    setState(() => _exporting = true);
    try {
      if (kind == 'csv') {
        await FlynoomPdf.saveBytes(FlynoomPdf.financialReportCsv(_data), '$_fileStem.csv');
      } else {
        final bytes = await FlynoomPdf.financialReport(periodLabel: _periodLabel, data: _data);
        if (kind == 'print') {
          await FlynoomPdf.printBytes(bytes, '$_fileStem.pdf');
        } else {
          await FlynoomPdf.saveBytes(bytes, '$_fileStem.pdf');
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      }
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  String _usd(dynamic v) => v == null ? '—' : '\$${_money.format((v as num).toDouble())}';

  @override
  Widget build(BuildContext context) {
    final chips = <(_Period, String)>[
      (_Period.thisMonth, _t3(context, ar: 'هذا الشهر', en: 'This month', es: 'Este mes')),
      (_Period.lastMonth, _t3(context, ar: 'الشهر الماضي', en: 'Last month', es: 'Mes pasado')),
      (_Period.thisYear, _t3(context, ar: 'هذه السنة', en: 'This year', es: 'Este año')),
      (_Period.lastYear, _t3(context, ar: 'السنة الماضية', en: 'Last year', es: 'Año pasado')),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(_t3(context, ar: 'التقارير المالية', en: 'Financial Reports', es: 'Informes financieros')),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loading ? null : _load),
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
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final c in chips)
                        ChoiceChip(
                          label: Text(c.$2),
                          selected: _period == c.$1,
                          onSelected: _loading ? null : (_) => _applyPeriod(c.$1),
                        ),
                      ChoiceChip(
                        avatar: const Icon(Icons.date_range, size: 16),
                        label: Text(_period == _Period.custom
                            ? _periodLabel
                            : _t3(context, ar: 'فترة مخصصة', en: 'Custom', es: 'Personalizado')),
                        selected: _period == _Period.custom,
                        onSelected: _loading ? null : (_) => _pickCustom(),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSizes.sm),
                  Text(_periodLabel, style: const TextStyle(color: AppColors.textSecondary)),
                  const SizedBox(height: AppSizes.md),
                  if (_loading)
                    const Padding(
                      padding: EdgeInsets.all(AppSizes.xl),
                      child: Center(child: CircularProgressIndicator()),
                    )
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
    final s = Map<String, dynamic>.from((_data['summary'] as Map?) ?? const {});
    final rows = ((_data['rows'] as List?) ?? const []).whereType<Map>().map((m) => Map<String, dynamic>.from(m)).toList();
    final unknown = (s['unknown_cost_count'] as num?) ?? 0;

    Widget card(String label, String value, {Color? color}) => SizedBox(
      width: 180,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.md),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
            const SizedBox(height: 4),
            Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
          ]),
        ),
      ),
    );

    final profit = s['profit_est'] as num?;

    return [
      // ── أزرار التصدير ──
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          FilledButton.icon(
            onPressed: _exporting ? null : () => _export('print'),
            icon: const Icon(Icons.print_outlined),
            label: Text(_t3(context, ar: 'طباعة', en: 'Print', es: 'Imprimir')),
          ),
          OutlinedButton.icon(
            onPressed: _exporting ? null : () => _export('pdf'),
            icon: const Icon(Icons.picture_as_pdf_outlined),
            label: const Text('PDF'),
          ),
          OutlinedButton.icon(
            onPressed: _exporting ? null : () => _export('csv'),
            icon: const Icon(Icons.table_view_outlined),
            label: const Text('CSV (Excel)'),
          ),
          if (_exporting) const Padding(padding: EdgeInsets.all(8), child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))),
        ],
      ),
      const SizedBox(height: AppSizes.md),

      // ── الملخص ──
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          card(_t3(context, ar: 'عدد الحجوزات', en: 'Bookings', es: 'Reservas'), '${s['bookings'] ?? 0}'),
          card(_t3(context, ar: 'إجمالي المبيعات', en: 'Gross sales', es: 'Ventas brutas'), _usd(s['gross_sales'])),
          card(_t3(context, ar: 'المستردات', en: 'Refunds', es: 'Reembolsos'), _usd(s['refunds'])),
          card(_t3(context, ar: 'صافي الإيراد', en: 'Net revenue', es: 'Ingreso neto'), _usd(s['net_revenue'])),
          card(_t3(context, ar: 'تكلفة HotelBeds', en: 'Hotel cost', es: 'Costo hotel'), _usd(s['supplier_cost'])),
          card(_t3(context, ar: 'رسوم Stripe (تقدير)', en: 'Stripe fees (est.)', es: 'Comisiones Stripe (est.)'), _usd(s['stripe_fees_est'])),
          card(
            _t3(context, ar: 'الربح (تقدير)', en: 'Profit (est.)', es: 'Ganancia (est.)'),
            _usd(profit),
            color: profit == null ? null : (profit < 0 ? Colors.red : const Color(0xFF00B894)),
          ),
        ],
      ),
      if (unknown > 0)
        Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Text(
            _t3(context,
                ar: '$unknown حجز بلا تكلفة مسجّلة، فلم يُحسب في الربح.',
                en: '$unknown booking(s) have no recorded hotel cost and are excluded from profit.',
                es: '$unknown reserva(s) sin costo registrado, excluidas de la ganancia.'),
            style: const TextStyle(fontSize: 12, color: Colors.red),
          ),
        ),
      const SizedBox(height: AppSizes.md),

      // ── الجدول ──
      if (rows.isEmpty)
        Padding(
          padding: const EdgeInsets.all(AppSizes.lg),
          child: Text(
            _t3(context, ar: 'لا توجد حجوزات مدفوعة في هذه الفترة.', en: 'No paid bookings in this period.', es: 'No hay reservas pagadas en este periodo.'),
            style: const TextStyle(color: AppColors.textSecondary),
          ),
        )
      else
        Card(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowHeight: 40,
              dataRowMinHeight: 36,
              dataRowMaxHeight: 44,
              columnSpacing: 18,
              columns: [
                for (var i = 0; i < FlynoomPdf.reportColumns.length; i++)
                  DataColumn(label: Text(FlynoomPdf.reportColumns[i]), numeric: i >= 5),
              ],
              rows: [
                for (final r in rows)
                  DataRow(cells: [
                    DataCell(Text(_date(r['created_at']))),
                    DataCell(SelectableText('${r['client_reference'] ?? ''}')),
                    DataCell(ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 220),
                      child: Text('${r['hotel_name'] ?? ''}', overflow: TextOverflow.ellipsis),
                    )),
                    DataCell(Text('${r['hotel_city'] ?? ''}')),
                    DataCell(Text('${r['status'] ?? ''}')),
                    DataCell(Text(_usd(r['paid']))),
                    DataCell(Text(_usd(r['refunded']))),
                    DataCell(Text(_usd(r['kept']))),
                    DataCell(Text(_usd(r['cost']))),
                    DataCell(Text(_usd(r['fee']))),
                    DataCell(Text(
                      _usd(r['profit']),
                      style: TextStyle(
                        color: (r['profit'] as num?) == null
                            ? null
                            : ((r['profit'] as num) < 0 ? Colors.red : const Color(0xFF00B894)),
                      ),
                    )),
                  ]),
              ],
            ),
          ),
        ),
      const SizedBox(height: AppSizes.sm),
      Text(
        _t3(context,
            ar: 'تقرير إداري. رسوم Stripe تقديرية (2.9% + 0.30\$). المصادر الرسمية للمحاسب: كشوف Stripe وكشوف HotelBeds.',
            en: 'Management report. Stripe fees are estimated (2.9% + \$0.30). Official records: Stripe and HotelBeds statements.',
            es: 'Informe de gestión. Comisiones de Stripe estimadas (2,9% + 0,30 \$). Registros oficiales: extractos de Stripe y HotelBeds.'),
        style: const TextStyle(fontSize: 12, color: AppColors.textHint),
      ),
    ];
  }

  static String _date(dynamic v) {
    final d = DateTime.tryParse('${v ?? ''}')?.toLocal();
    return d == null ? '' : DateFormat('yyyy-MM-dd').format(d);
  }
}