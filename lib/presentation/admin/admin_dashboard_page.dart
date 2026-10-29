import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show Supabase;

import '../../app.dart';
import '../../core/config/features.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../core/widgets/app_banner.dart';
import 'admin_alerts_page.dart';
import 'admin_booking_desk_page.dart';
import 'admin_financial_report_page.dart';
import 'admin_group_requests_page.dart';
import 'admin_stats_page.dart';

/// يختار النص المناسب حسب اللغة الحالية (عربي/إنجليزي/إسباني).
String _t3(
    BuildContext context, {
      required String ar,
      required String en,
      required String es,
    }) {
  switch (Localizations.localeOf(context).languageCode) {
    case 'ar':
      return ar;
    case 'es':
      return es;
    default:
      return en;
  }
}

/// نقطة الدخول الرئيسية للوحة تحكم الأدمن — بطاقات بسيطة تودّي لكل
/// قسم إدارة (حجوزات، طلبات مجموعات، فنادق...). الوصول لهذي الشاشة محمي
/// على مستوى الـ router (redirect في app.dart)، والبيانات نفسها محمية
/// بسياسات RLS عبر public.is_admin().
///
/// الأدوار (profiles.role):
///   super_admin = المالك: كل البطاقات، بما فيها Platform Stats (الأرباح).
///   admin       = مساعد: كل البطاقات ما عدا Platform Stats.
/// الإخفاء هنا للواجهة فقط؛ الحماية الحقيقية في قاعدة البيانات:
/// admin_stats ترفض أي أحد غير public.is_owner().
class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  /// هل المستخدم الحالي هو المالك؟ (false حتى يصل الرد، فلا تظهر الأرباح لحظيًا لمساعد.)
  bool _isOwner = false;

  /// عدد تنبيهات "مهام اليوم" (null حتى يصل الرد).
  int? _alertCount;
  bool _alertsLoaded = false;

  @override
  void initState() {
    super.initState();
    _checkOwner();
    _loadAlertCount();
  }

  Future<void> _loadAlertCount() async {
    final n = await AdminAlertsPage.fetchCount();
    if (mounted) {
      setState(() {
        _alertCount = n;
        _alertsLoaded = true;
      });
    }
  }

  Future<void> _checkOwner() async {
    try {
      final r = await Supabase.instance.client.rpc('is_owner');
      if (mounted) setState(() => _isOwner = r == true);
    } catch (_) {
      // الدالة غير موجودة بعد أو خطأ شبكة: نخفي الأرباح احتياطًا.
    }
  }

  Future<void> _openAlerts() async {
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AdminAlertsPage()));
    _loadAlertCount();
  }

  /// بطاقة "مهام اليوم" أولًا: حمراء مع العدد إذا كان هناك ما يحتاج تدخّلًا،
  /// خضراء إذا لم يكن هناك شيء، ورمادية أثناء التحميل.
  Widget _actionCenterCard(BuildContext context) {
    final n = _alertCount;
    final loading = !_alertsLoaded;
    final failed = _alertsLoaded && n == null;
    final hasWork = (n ?? 0) > 0;
    final color = (loading || failed)
        ? AppColors.textHint
        : (hasWork ? const Color(0xFFD63031) : const Color(0xFF00B894));
    final subtitle = loading
        ? _t3(context, ar: 'جارٍ التحقق…', en: 'Checking…', es: 'Comprobando…')
        : failed
        ? _t3(context, ar: 'تعذّر التحقق — اضغط للفتح', en: 'Could not check — tap to open', es: 'No se pudo comprobar: toca para abrir')
        : hasWork
        ? _t3(context,
        ar: '$n ${n == 1 ? 'أمر يحتاج' : 'أمور تحتاج'} تدخّلك',
        en: '$n item${n == 1 ? '' : 's'} need${n == 1 ? 's' : ''} your attention',
        es: '$n elemento${n == 1 ? '' : 's'} requiere${n == 1 ? '' : 'n'} atención')
        : _t3(context,
        ar: 'لا شيء يحتاج تدخّلًا الآن',
        en: 'Nothing needs attention right now',
        es: 'Nada requiere atención ahora');

    return Card(
      margin: const EdgeInsets.only(bottom: AppSizes.md),
      color: color.withOpacity(0.08),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: color.withOpacity(0.6), width: 1.5),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: _openAlerts,
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.md),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  hasWork ? Icons.notifications_active : Icons.task_alt,
                  color: color,
                  size: 28,
                ),
              ),
              const SizedBox(width: AppSizes.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _t3(context, ar: 'مهام اليوم', en: 'Action Center', es: 'Centro de tareas'),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 4),
                    Text(subtitle, style: TextStyle(fontSize: 13, color: color, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              if (hasWork)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(20)),
                  child: Text('$n', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                ),
              const SizedBox(width: 8),
              const Icon(Icons.arrow_forward_ios, size: 16, color: AppColors.textHint),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // نص الحجوزات يتبع الأقسام المفعّلة فقط (الطيران والسيارات مخفيان حاليًا).
    final bookingsDescription = (kFlightsEnabled || kCarsEnabled)
        ? _t3(
      context,
      ar: 'مراجعة، تأكيد، أو إلغاء حجوزات الفنادق والرحلات والسيارات',
      en: 'Review, confirm, or cancel hotel, flight, and car bookings',
      es: 'Revisa, confirma o cancela reservas de hoteles, vuelos y coches',
    )
        : _t3(
      context,
      ar: 'مراجعة، تأكيد، أو إلغاء حجوزات الفنادق',
      en: 'Review, confirm, or cancel hotel bookings',
      es: 'Revisa, confirma o cancela reservas de hoteles',
    );

    final sections = <({
    IconData icon,
    Color color,
    String title,
    String description,
    VoidCallback onTap,
    })>[
      if (_isOwner)
        (
        icon: Icons.insights_outlined,
        color: const Color(0xFF6C5CE7),
        title: _t3(context, ar: 'إحصاءات المنصة', en: 'Platform Stats', es: 'Estadísticas'),
        description: _t3(
          context,
          ar: 'الأرباح ونسبة الزيادة، عدد الحسابات، ومن حجز فندقًا',
          en: 'Profit and markup, number of accounts, and who booked a hotel',
          es: 'Ganancias y margen, número de cuentas y quién reservó',
        ),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const AdminStatsPage()),
        ),
        ),
      if (_isOwner)
        (
        icon: Icons.request_quote_outlined,
        color: const Color(0xFF2D3436),
        title: _t3(context, ar: 'التقارير المالية', en: 'Financial Reports', es: 'Informes financieros'),
        description: _t3(
          context,
          ar: 'تقرير بالفترة: المبيعات والمستردات والتكلفة والربح، مع طباعة وPDF وCSV للمحاسب',
          en: 'Sales, refunds, cost and profit by period — print, PDF, and CSV for your accountant',
          es: 'Ventas, reembolsos, costos y ganancia por periodo: imprimir, PDF y CSV',
        ),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const AdminFinancialReportPage()),
        ),
        ),
      (
      icon: Icons.receipt_long_outlined,
      color: const Color(0xFF0984E3),
      title: _t3(context, ar: 'مكتب الحجوزات', en: 'Booking Desk', es: 'Mesa de Reservas'),
      description: _t3(
        context,
        ar: 'حجوزات HotelBeds الحقيقية: التفاصيل، والإلغاء نيابة عن العميل مع الاسترداد',
        en: 'Real HotelBeds bookings: details, and cancel on behalf of the guest with refund',
        es: 'Reservas reales de HotelBeds: detalles y cancelación con reembolso',
      ),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const AdminBookingDeskPage()),
      ),
      ),
      (
      icon: Icons.history_outlined,
      color: const Color(0xFF636E72),
      title: _t3(context, ar: 'الحجوزات القديمة', en: 'Legacy Bookings', es: 'Reservas Antiguas'),
      description: bookingsDescription,
      onTap: () => context.push(AppRoutes.adminBookings),
      ),
      (
      icon: Icons.groups_outlined,
      color: const Color(0xFFE17055),
      title: _t3(context, ar: 'طلبات المجموعات', en: 'Group Requests', es: 'Solicitudes de Grupos'),
      description: _t3(
        context,
        ar: 'طلبات 5 غرف فأكثر: عرض الطلبات، تغيير الحالة، وإضافة ملاحظات',
        en: 'Requests for 5+ rooms: view, update status, and add notes',
        es: 'Solicitudes de 5+ habitaciones: ver, cambiar estado y añadir notas',
      ),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const AdminGroupRequestsPage()),
      ),
      ),
      (
      icon: Icons.hotel_outlined,
      color: const Color(0xFF00B894),
      title: _t3(context, ar: 'إدارة الفنادق', en: 'Manage Hotels', es: 'Gestionar Hoteles'),
      description: _t3(
        context,
        ar: 'إضافة، تعديل، أو حذف الفنادق والغرف المعروضة بالتطبيق',
        en: 'Add, edit, or remove hotels and rooms shown in the app',
        es: 'Añade, edita o elimina hoteles y habitaciones en la app',
      ),
      onTap: () => context.push(AppRoutes.adminHotels),
      ),
    ];

    return Scaffold(
      appBar: AppBanner(
        tabsBar: Text(
          _t3(context, ar: 'لوحة تحكم الأدمن', en: 'Admin Dashboard', es: 'Panel de Administración'),
          style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
        ),
        bannerHeight: 160,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSizes.md),
          children: [
            _actionCenterCard(context),
            for (final section in sections)
              Card(
                margin: const EdgeInsets.only(bottom: AppSizes.md),
                child: InkWell(
                  onTap: section.onTap,
                  child: Padding(
                    padding: const EdgeInsets.all(AppSizes.md),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: section.color.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(section.icon, color: section.color, size: 28),
                        ),
                        const SizedBox(width: AppSizes.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                section.title,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                section.description,
                                style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.arrow_forward_ios, size: 16, color: AppColors.textHint),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}