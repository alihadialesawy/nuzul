import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../search/controllers/search_controller.dart';

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

/// شاشة تعريفية بمساعد الذكاء الاصطناعي بتاع Safr-AI، ومعاها فورم
/// "تتبّع سعر رحلتك" اللي بيبعت طلب فعلي لجدول price_watches بـ Supabase
/// (الفحص اليومي والإشعار بالإيميل بيتم من خلال Edge Function منفصلة).
class AiTravelPage extends ConsumerStatefulWidget {
  const AiTravelPage({super.key});

  @override
  ConsumerState<AiTravelPage> createState() => _AiTravelPageState();
}

class _AiTravelPageState extends ConsumerState<AiTravelPage> {
  final _formKey = GlobalKey<FormState>();
  final _originController = TextEditingController();
  final _destinationController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _targetPriceController = TextEditingController();
  DateTime? _travelDate;
  bool _nonstopOnly = false;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _originController.dispose();
    _destinationController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _targetPriceController.dispose();
    super.dispose();
  }

  Future<void> _pickTravelDate() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
      initialDate: _travelDate ?? now.add(const Duration(days: 7)),
    );
    if (date != null) setState(() => _travelDate = date);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_travelDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _t3(context, ar: 'اختار تاريخ السفر', en: 'Pick a travel date', es: 'Elige una fecha de viaje'),
          ),
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final repo = ref.read(priceWatchRepositoryProvider);
    final result = await repo.submitPriceWatch(
      email: _emailController.text,
      phone: _phoneController.text,
      originCity: _originController.text,
      destinationCity: _destinationController.text,
      travelDate: _travelDate!,
      // أسعار الرحلات في الجدول مخزّنة بالريال السعودي (SAR) كعملة أساسية
      // (نفس اتفاقية باقي التطبيق)، فبنحوّل السعر المطلوب من دولار لريال
      // بنفس السعر الثابت المستخدم في تحويل العملات (3.75 ريال للدولار)
      // قبل ما نخزّنه، عشان المقارنة في الخلفية تفضل صحيحة.
      targetPrice: double.parse(_targetPriceController.text) * 3.75,
      nonstopOnly: _nonstopOnly,
    );

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    result.when(
      success: (_) {
        _originController.clear();
        _destinationController.clear();
        _emailController.clear();
        _phoneController.clear();
        _targetPriceController.clear();
        setState(() {
          _travelDate = null;
          _nonstopOnly = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _t3(
                context,
                ar: 'تمام! هنبعتلك إيميل أول ما نلاقي السعر ده',
                en: "Got it! We'll email you as soon as we find that price",
                es: '¡Listo! Te avisaremos por correo cuando encontremos ese precio',
              ),
            ),
          ),
        );
      },
      failure: (message) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: AppSizes.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: AppSizes.md),
              // بانر صورة الذكاء الاصطناعي أعلى الشاشة
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.asset(
                  'assets/images/ai_banner.jpg',
                  width: double.infinity,
                  height: 220,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    width: double.infinity,
                    height: 220,
                    color: Colors.white.withOpacity(0.08),
                  ),
                ),
              ),
              const SizedBox(height: AppSizes.lg),
              RichText(
                text: TextSpan(
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    height: 1.2,
                  ),
                  children: [
                    TextSpan(
                      text: _t3(
                        context,
                        ar: 'مساعد السفر الذكي كله في مكان واحد',
                        en: 'Your all-in-one AI travel app',
                        es: 'Tu app de viajes con IA, todo en uno',
                      ),
                    ),
                    const TextSpan(
                      text: '.',
                      style: TextStyle(color: Colors.amber),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSizes.sm),
              Text(
                _t3(
                  context,
                  ar: 'مساعد Safr-AI الذكي بيساعدك تلاقي أفضل عروض الفنادق والطيران والسيارات في ثواني',
                  en: 'Our AI assistant finds the best hotel, flight, and car deals for you in seconds',
                  es: 'Nuestro asistente de IA encuentra las mejores ofertas de hoteles, vuelos y coches en segundos',
                ),
                style: const TextStyle(fontSize: 15, color: Colors.white70),
              ),
              const SizedBox(height: AppSizes.xl),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSizes.lg),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 96,
                      height: 96,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.qr_code_2, size: 72, color: Colors.black87),
                    ),
                    const SizedBox(width: AppSizes.lg),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _t3(
                              context,
                              ar: 'نزّل تطبيق Safr-AI',
                              en: 'Get the Safr-AI app',
                              es: 'Descarga la app de Safr-AI',
                            ),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                          const SizedBox(height: AppSizes.sm),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              _StoreBadge(
                                icon: Icons.apple,
                                topLabel: _t3(context, ar: 'حمّل من', en: 'Download on the', es: 'Disponible en'),
                                bottomLabel: 'App Store',
                              ),
                              _StoreBadge(
                                icon: Icons.shop,
                                topLabel: _t3(context, ar: 'احصل عليه من', en: 'GET IT ON', es: 'Disponible en'),
                                bottomLabel: 'Google Play',
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSizes.xl),
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: _FeatureCard(
                        icon: Icons.chat_bubble_outline,
                        color: const Color(0xFF6C5CE7),
                        title: _t3(context, ar: 'محادثة ذكية', en: 'AI chat assistant', es: 'Chat con IA'),
                        description: _t3(
                          context,
                          ar: 'اسأل مساعد Safr-AI بالعربي أو الإنجليزي عن أي رحلة، وهيرد عليك فورًا باقتراحات مخصصة',
                          en: 'Ask the Safr-AI assistant about any trip and get instant, tailored suggestions back',
                          es: 'Pregunta a Safr-AI sobre tu viaje y recibe sugerencias personalizadas al instante',
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSizes.sm),
                    Expanded(
                      child: _FeatureCard(
                        icon: Icons.trending_down,
                        color: const Color(0xFFE17055),
                        title: _t3(context, ar: 'تتبّع الأسعار', en: 'Price tracking', es: 'Seguimiento de precios'),
                        description: _t3(
                          context,
                          ar: 'الذكاء الاصطناعي بيراقب سعر رحلتك يوميًا ويبعتلك إيميل تلقائي أول ما يوصل السعر اللي حددته',
                          en: 'Our AI checks your flight price daily and emails you automatically the moment it hits your target',
                          es: 'Nuestra IA revisa el precio de tu vuelo a diario y te avisa por correo al alcanzar tu meta',
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSizes.sm),
                    Expanded(
                      child: _FeatureCard(
                        icon: Icons.recommend_outlined,
                        color: const Color(0xFF0984E3),
                        title: _t3(context, ar: 'توصيات مخصصة', en: 'Personalized picks', es: 'Recomendaciones a tu medida'),
                        description: _t3(
                          context,
                          ar: 'كل ما تستخدم Safr-AI أكتر، الاقتراحات بتبقى أدق وأقرب لذوقك وميزانيتك',
                          en: 'The more you use Safr-AI, the sharper its suggestions get for your taste and budget',
                          es: 'Cuanto más usas Safr-AI, más precisas son sus sugerencias según tu gusto y presupuesto',
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSizes.sm),
                    Expanded(
                      child: _FeatureCard(
                        icon: Icons.access_time,
                        color: const Color(0xFF00B894),
                        title: _t3(context, ar: 'متاح ٢٤/٧', en: 'Available 24/7', es: 'Disponible 24/7'),
                        description: _t3(
                          context,
                          ar: 'مساعد الذكاء الاصطناعي شغّال طول الوقت، جاهز يخطط رحلتك في أي ساعة بدون ما تستنى حد',
                          en: 'The AI assistant works around the clock, ready to plan your trip anytime with no waiting',
                          es: 'El asistente de IA trabaja sin parar, listo para planear tu viaje a cualquier hora',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSizes.xl),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSizes.lg),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _t3(
                          context,
                          ar: 'تتبّع سعر رحلتك',
                          en: 'Track your flight price',
                          es: 'Sigue el precio de tu vuelo',
                        ),
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _t3(
                          context,
                          ar: 'حدّد رحلتك والسعر اللي حابب توصله، ومساعدنا الذكي هيدور كل يوم ويبعتلك إيميل أول ما يلاقيه',
                          en: "Tell us your trip and target price, and our AI will search daily and email you as soon as it's found",
                          es: 'Dinos tu viaje y precio deseado, y nuestra IA buscará a diario y te avisará por correo',
                        ),
                        style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: AppSizes.md),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _originController,
                              decoration: InputDecoration(
                                labelText: _t3(context, ar: 'من', en: 'From', es: 'Desde'),
                                prefixIcon: const Icon(Icons.flight_takeoff, size: 18),
                              ),
                              validator: (v) => (v == null || v.trim().isEmpty)
                                  ? _t3(context, ar: 'مطلوب', en: 'Required', es: 'Requerido')
                                  : null,
                            ),
                          ),
                          const SizedBox(width: AppSizes.sm),
                          Expanded(
                            child: TextFormField(
                              controller: _destinationController,
                              decoration: InputDecoration(
                                labelText: _t3(context, ar: 'إلى', en: 'To', es: 'Hasta'),
                                prefixIcon: const Icon(Icons.flight_land, size: 18),
                              ),
                              validator: (v) => (v == null || v.trim().isEmpty)
                                  ? _t3(context, ar: 'مطلوب', en: 'Required', es: 'Requerido')
                                  : null,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSizes.sm),
                      GestureDetector(
                        onTap: _pickTravelDate,
                        child: InputDecorator(
                          decoration: InputDecoration(
                            labelText: _t3(context, ar: 'تاريخ السفر', en: 'Travel date', es: 'Fecha de viaje'),
                            prefixIcon: const Icon(Icons.calendar_today_outlined, size: 18),
                          ),
                          child: Text(
                            _travelDate == null
                                ? _t3(context, ar: 'اختار تاريخ', en: 'Select a date', es: 'Elige una fecha')
                                : '${_travelDate!.year}-${_travelDate!.month.toString().padLeft(2, '0')}-${_travelDate!.day.toString().padLeft(2, '0')}',
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSizes.sm),
                      TextFormField(
                        controller: _targetPriceController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: _t3(context, ar: 'السعر المطلوب (USD)', en: 'Target price (USD)', es: 'Precio deseado (USD)'),
                          prefixIcon: const Icon(Icons.sell_outlined, size: 18),
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return _t3(context, ar: 'مطلوب', en: 'Required', es: 'Requerido');
                          }
                          if (double.tryParse(v) == null) {
                            return _t3(context, ar: 'رقم غير صحيح', en: 'Invalid number', es: 'Número inválido');
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 4),
                      GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => setState(() => _nonstopOnly = !_nonstopOnly),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Checkbox(
                              value: _nonstopOnly,
                              onChanged: (v) => setState(() => _nonstopOnly = v ?? false),
                            ),
                            Text(
                              _t3(context, ar: 'بدون توقف فقط', en: 'Nonstop only', es: 'Solo sin escalas'),
                              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSizes.sm),
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          labelText: _t3(context, ar: 'بريدك الإلكتروني', en: 'Your email', es: 'Tu correo electrónico'),
                          prefixIcon: const Icon(Icons.email_outlined, size: 18),
                        ),
                        validator: (v) {
                          if (v == null || !v.contains('@')) {
                            return _t3(context, ar: 'بريد إلكتروني غير صحيح', en: 'Invalid email', es: 'Correo inválido');
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: AppSizes.sm),
                      TextFormField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        decoration: InputDecoration(
                          labelText: _t3(
                            context,
                            ar: 'رقم الجوال (اختياري — لإشعار SMS)',
                            en: 'Phone number (optional — for SMS alert)',
                            es: 'Teléfono (opcional — para alerta SMS)',
                          ),
                          hintText: '+9665xxxxxxxx',
                          prefixIcon: const Icon(Icons.sms_outlined, size: 18),
                        ),
                      ),
                      const SizedBox(height: AppSizes.md),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isSubmitting ? null : _submit,
                          child: _isSubmitting
                              ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                              : Text(
                            _t3(context, ar: 'ابدأ التتبّع', en: 'Start tracking', es: 'Empezar a seguir'),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSizes.xl),
            ],
          ),
        ),
      ),
    );
  }
}

class _StoreBadge extends StatelessWidget {
  final IconData icon;
  final String topLabel;
  final String bottomLabel;

  const _StoreBadge({
    required this.icon,
    required this.topLabel,
    required this.bottomLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 30),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(topLabel, style: const TextStyle(color: Colors.white70, fontSize: 11)),
              Text(
                bottomLabel,
                style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String description;

  const _FeatureCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          const SizedBox(height: 10),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: color),
          ),
          const SizedBox(height: 5),
          Text(
            description,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.35),
          ),
        ],
      ),
    );
  }
}