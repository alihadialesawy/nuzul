import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';

/// لوحة الإحصاءات (للمدير فقط): الأرباح، المستخدمون، الحجوزات.
///
/// المصدر: الدالة public.admin_stats في Supabase (ترفض أي مستخدم غير مدير).
/// الأرقام المالية بالدولار. رسوم Stripe تقديرية (2.9% + 0.30$ لكل عملية).
///
/// ⚠️ قبل التحويل للحساب الحقيقي كل البيانات تجريبية (Stripe Sandbox +
/// بيئة اختبار HotelBeds)؛ الأرقام تفيد للتجربة فقط.
class AdminStatsPage extends StatefulWidget {
  const AdminStatsPage({super.key});

  @override
  State<AdminStatsPage> createState() => _AdminStatsPageState();
}

String _t(BuildContext context, {required String ar, required String en}) =>
    Localizations.localeOf(context).languageCode == 'ar' ? ar : en;

/// الفترات المتاحة (بالأيام؛ null = كل الوقت).
const _periods = <int?>[7, 30, 90, null];

class _AdminStatsPageState extends State<AdminStatsPage> {
  int? _days = 30;
  Map<String, dynamic>? _data;
  String? _error;
  bool _loading = true;

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
      final now = DateTime.now().toUtc();
      final params = <String, dynamic>{
        'p_from': _days == null ? null : now.subtract(Duration(days: _days!)).toIso8601String(),
        'p_to': null,
      };
      final res = await Supabase.instance.client.rpc('admin_stats', params: params);
      if (!mounted) return;
      setState(() {
        _data = Map<String, dynamic>.from(res as Map);
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

  String _periodLabel(BuildContext context, int? d) => d == null
      ? _t(context, ar: 'كل الوقت', en: 'All time')
      : _t(context, ar: 'آخر $d يومًا', en: 'Last $d days');

  static num _n(dynamic v) => v is num ? v : num.tryParse('${v ?? 0}') ?? 0;
  static String _usd(dynamic v) {
    if (v == null) return '—';
    final x = _n(v).toDouble();
    final neg = x < 0;
    final s = x.abs().toStringAsFixed(2).replaceAllMapped(
        RegExp(r'(\d)(?=(\d{3})+\.)'), (m) => '${m[1]},');
    return '${neg ? '-' : ''}\$$s';
  }

  static String _pct(dynamic v) => v == null ? '—' : '${_n(v)}%';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_t(context, ar: 'إحصاءات المنصة', en: 'Platform stats')),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loading ? null : _load),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSizes.md, AppSizes.md, AppSizes.md, 0),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                for (final p in _periods)
                  ChoiceChip(
                    label: Text(_periodLabel(context, p)),
                    selected: _days == p,
                    onSelected: _loading
                        ? null
                        : (_) {
                      setState(() => _days = p);
                      _load();
                    },
                  ),
              ],
            ),
          ),
          Expanded(child: _body(context)),
        ],
      ),
    );
  }

  Widget _body(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.lg),
          child: Text(
            _error!.contains('forbidden')
                ? _t(context, ar: 'هذه الصفحة للمدير فقط.', en: 'Admins only.')
                : _t(context,
                ar: 'تعذّر تحميل الإحصاءات. تأكد من تنفيذ ملف admin_stats.sql.\n$_error',
                en: 'Could not load stats. Make sure admin_stats.sql was run.\n$_error'),
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.error),
          ),
        ),
      );
    }

    final d = _data ?? const {};
    final users = Map<String, dynamic>.from(d['users'] as Map? ?? const {});
    final b = Map<String, dynamic>.from(d['bookings'] as Map? ?? const {});
    final m = Map<String, dynamic>.from(d['money'] as Map? ?? const {});
    final cities = (d['top_cities'] as List? ?? const []).whereType<Map>().toList();
    final settings = d['settings'] is Map ? Map<String, dynamic>.from(d['settings'] as Map) : null;
    final unknownCost = _n(m['unknown_cost_count']).toInt();

    return ListView(
      padding: const EdgeInsets.all(AppSizes.md),
      children: [
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1000),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── نسبة الزيادة المطبقة ──
                _SectionTitle(_t(context, ar: 'نسبة الربح المطبقة', en: 'Markup setting')),
                _Grid(children: [
                  _Stat(
                    label: _t(context, ar: 'نسبة الزيادة على سعر الفندق', en: 'Markup on hotel price'),
                    value: settings == null ? '—' : '${_n(settings['markup_pct'])}%',
                    hint: settings == null
                        ? _t(context, ar: 'تظهر بعد أول حجز جديد', en: 'Shown after the next booking')
                        : 'HOTELBEDS_MARKUP_PERCENT',
                    color: AppColors.primary,
                    big: true,
                  ),
                  _Stat(
                    label: _t(context, ar: 'هامش سعر الصرف', en: 'FX buffer'),
                    value: settings == null ? '—' : '${_n(settings['fx_buffer_pct'])}%',
                    hint: _t(context, ar: 'للعملات غير الدولار فقط', en: 'Non-USD currencies only'),
                  ),
                  _Stat(
                    label: _t(context, ar: 'الإجمالي على العميل', en: 'Total over cost'),
                    value: settings == null
                        ? '—'
                        : '${((1 + _n(settings['markup_pct']) / 100) * (1 + _n(settings['fx_buffer_pct']) / 100) * 100 - 100).toStringAsFixed(1)}%',
                    hint: _t(context, ar: 'الزيادة × هامش الصرف', en: 'Markup × FX buffer'),
                  ),
                ]),
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    _t(context,
                        ar: 'لتغيير النسبة: supabase secrets set HOTELBEDS_MARKUP_PERCENT=… . فنادق "السعر الإلزامي" (hotelMandatory) تُباع بسعر الفندق ولا تُطبق عليها النسبة.',
                        en: 'To change it: supabase secrets set HOTELBEDS_MARKUP_PERCENT=… . Hotel-mandatory rates sell at the hotel price, without markup.'),
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                ),

                // ── المال ──
                _SectionTitle(_t(context, ar: 'الأرباح', en: 'Profit')),
                _Grid(children: [
                  _Stat(
                    label: _t(context, ar: 'صافي الربح (تقديري)', en: 'Net profit (est.)'),
                    value: _usd(m['net_profit_est']),
                    hint: _t(context, ar: 'بعد تكلفة الفنادق ورسوم Stripe', en: 'After hotel cost and Stripe fees'),
                    color: m['net_profit_est'] == null
                        ? null
                        : (_n(m['net_profit_est']) < 0 ? AppColors.error : AppColors.success),
                    big: true,
                  ),
                  _Stat(
                    label: _t(context, ar: 'إجمالي الإيراد', en: 'Revenue'),
                    value: _usd(m['revenue']),
                    hint: _t(context, ar: 'ما دفعه العملاء وبقي معنا', en: 'Paid by guests and kept'),
                  ),
                  _Stat(
                    label: _t(context, ar: 'تكلفة الفنادق', en: 'Hotel cost'),
                    value: _usd(m['cost']),
                    hint: _t(context, ar: 'المدفوع لـ HotelBeds', en: 'Owed to HotelBeds'),
                  ),
                  _Stat(
                    label: _t(context, ar: 'الربح الإجمالي', en: 'Gross profit'),
                    value: _usd(m['gross_profit']),
                    hint: _t(context, ar: 'قبل رسوم Stripe', en: 'Before Stripe fees'),
                  ),
                  _Stat(
                    label: _t(context, ar: 'رسوم Stripe (تقديرية)', en: 'Stripe fees (est.)'),
                    value: _usd(m['stripe_fees_est']),
                    hint: '2.9% + \$0.30',
                  ),
                  _Stat(
                    label: _t(context, ar: 'نسبة الزيادة الفعلية', en: 'Effective markup'),
                    value: _pct(m['effective_markup_pct']),
                    hint: _t(context, ar: 'الربح ÷ التكلفة', en: 'Profit ÷ cost'),
                  ),
                  _Stat(
                    label: _t(context, ar: 'هامش الربح', en: 'Profit margin'),
                    value: _pct(m['margin_pct']),
                    hint: _t(context, ar: 'الربح ÷ الإيراد', en: 'Profit ÷ revenue'),
                  ),
                  _Stat(
                    label: _t(context, ar: 'المبالغ المستردة', en: 'Refunded'),
                    value: _usd(m['refunded']),
                    hint: _t(context,
                        ar: 'بقي من الإلغاءات: ${_usd(m['kept_from_cancellations'])}',
                        en: 'Kept from cancellations: ${_usd(m['kept_from_cancellations'])}'),
                  ),
                ]),
                if (unknownCost > 0)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      _t(context,
                          ar: '$unknownCost حجز قديم بلا تكلفة مسجلة بالدولار، لم يُحسب في الربح (الإيراد والرسوم تشملها). '
                              'الربح يُحسب من ${m['known_cost_count'] ?? 0} حجز فقط.',
                          en: '$unknownCost older booking(s) have no USD cost recorded and are left out of profit (revenue and fees include them). '
                              'Profit is based on ${m['known_cost_count'] ?? 0} booking(s).'),
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ),

                // ── المستخدمون ──
                _SectionTitle(_t(context, ar: 'المستخدمون', en: 'Users')),
                _Grid(children: [
                  _Stat(
                    label: _t(context, ar: 'إجمالي الحسابات', en: 'Total accounts'),
                    value: '${users['total'] ?? 0}',
                    big: true,
                  ),
                  _Stat(
                    label: _t(context, ar: 'حسابات جديدة', en: 'New accounts'),
                    value: '${users['new_in_period'] ?? 0}',
                    hint: _periodLabel(context, _days),
                  ),
                  _Stat(
                    label: _t(context, ar: 'بريد مؤكد', en: 'Email confirmed'),
                    value: '${users['email_confirmed'] ?? 0}',
                  ),
                  _Stat(
                    label: _t(context, ar: 'حجزوا فندقًا', en: 'Booked a hotel'),
                    value: '${users['ever_booked'] ?? 0}',
                    hint: _t(context, ar: 'منذ البداية', en: 'All time'),
                  ),
                  _Stat(
                    label: _t(context, ar: 'نسبة التحويل', en: 'Conversion'),
                    value: _pct(users['conversion_pct']),
                    hint: _t(context, ar: 'من سجّل ← من حجز', en: 'Signed up → booked'),
                  ),
                  _Stat(
                    label: _t(context, ar: 'عملاء متكررون', en: 'Repeat customers'),
                    value: '${users['repeat_customers'] ?? 0}',
                    hint: _t(context, ar: 'أكثر من حجز', en: 'More than one booking'),
                  ),
                ]),

                // ── الحجوزات ──
                _SectionTitle(_t(context, ar: 'الحجوزات', en: 'Bookings')),
                _Grid(children: [
                  _Stat(
                    label: _t(context, ar: 'مؤكدة', en: 'Confirmed'),
                    value: '${b['confirmed'] ?? 0}',
                    color: AppColors.success,
                    big: true,
                  ),
                  _Stat(
                    label: _t(context, ar: 'ملغاة', en: 'Cancelled'),
                    value: '${b['cancelled'] ?? 0}',
                    hint: _t(context, ar: 'نسبة الإلغاء ${_pct(b['cancel_rate_pct'])}', en: 'Cancel rate ${_pct(b['cancel_rate_pct'])}'),
                  ),
                  _Stat(
                    label: _t(context, ar: 'تحتاج متابعة', en: 'Needs attention'),
                    value: '${b['needs_attention'] ?? 0}',
                    color: _n(b['needs_attention']) > 0 ? AppColors.error : null,
                  ),
                  _Stat(
                    label: _t(context, ar: 'محاولات لم تكتمل', en: 'Incomplete attempts'),
                    value: '${b['incomplete'] ?? 0}',
                    hint: _t(context,
                        ar: 'منها ولايات ممنوعة: ${b['blocked_states'] ?? 0}',
                        en: 'Blocked states: ${b['blocked_states'] ?? 0}'),
                  ),
                  _Stat(
                    label: _t(context, ar: 'متوسط قيمة الحجز', en: 'Avg. booking'),
                    value: _usd(b['avg_booking_usd']),
                  ),
                  _Stat(
                    label: _t(context, ar: 'متوسط الليالي', en: 'Avg. nights'),
                    value: '${b['avg_nights'] ?? 0}',
                  ),
                ]),

                // ── أهم الوجهات ──
                if (cities.isNotEmpty) ...[
                  _SectionTitle(_t(context, ar: 'أهم الوجهات', en: 'Top destinations')),
                  Card(
                    child: Column(
                      children: [
                        for (final c in cities)
                          ListTile(
                            dense: true,
                            leading: const Icon(Icons.place_outlined),
                            title: Text('${c['city']}'),
                            subtitle: Text(_t(context,
                                ar: '${c['bookings']} حجز',
                                en: '${c['bookings']} booking(s)')),
                            trailing: Text(_usd(c['revenue']),
                                style: const TextStyle(fontWeight: FontWeight.w600)),
                          ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: AppSizes.lg),
                Text(
                  _t(context,
                      ar: 'الأرقام لحجوزات HotelBeds فقط، وتُحسب حسب تاريخ إنشاء الحجز. رسوم Stripe تقديرية؛ الرقم الدقيق في لوحة Stripe. الضرائب غير مخصومة.',
                      en: 'HotelBeds bookings only, grouped by booking date. Stripe fees are estimates; see Stripe for exact figures. Taxes are not deducted.'),
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: AppSizes.lg, bottom: AppSizes.sm),
    child: Text(text, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
  );
}

/// شبكة بطاقات: 4 أعمدة على الشاشات العريضة، عمودان على الموبايل.
class _Grid extends StatelessWidget {
  final List<Widget> children;
  const _Grid({required this.children});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      final cols = c.maxWidth >= 800 ? 4 : 2;
      const gap = 10.0;
      final w = (c.maxWidth - gap * (cols - 1)) / cols;
      return Wrap(
        spacing: gap,
        runSpacing: gap,
        children: [for (final ch in children) SizedBox(width: w, child: ch)],
      );
    });
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final String value;
  final String? hint;
  final Color? color;
  final bool big;
  const _Stat({required this.label, required this.value, this.hint, this.color, this.big = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.md),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.divider),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: AlignmentDirectional.centerStart,
            child: Text(
              value,
              style: TextStyle(
                fontSize: big ? 26 : 20,
                fontWeight: FontWeight.bold,
                color: color ?? AppColors.textPrimary,
              ),
            ),
          ),
          if (hint != null) ...[
            const SizedBox(height: 4),
            Text(hint!, style: const TextStyle(fontSize: 11, color: AppColors.textHint)),
          ],
        ],
      ),
    );
  }
}