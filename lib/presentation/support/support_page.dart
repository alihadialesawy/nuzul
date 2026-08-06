import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../core/widgets/app_banner.dart';
import '../../core/widgets/app_footer.dart';

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

class _FaqItem {
  final String question;
  final String answer;
  const _FaqItem(this.question, this.answer);
}

/// شاشة دعم العملاء: هيدر + تبويبات فئات + أسئلة شائعة قابلة للطي + كلمات
/// دلالية سريعة + شريط وصول سريع (شات/اتصال/طوارئ) تحت.
class SupportPage extends StatefulWidget {
  const SupportPage({super.key});

  @override
  State<SupportPage> createState() => _SupportPageState();
}

class _SupportPageState extends State<SupportPage> {
  String _activeCategory = 'flights';

  void _comingSoon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_t3(context, ar: 'قريبًا', en: 'Coming soon', es: 'Próximamente')),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  List<_FaqItem> _faqsFor(BuildContext context, String category) {
    switch (category) {
      case 'hotels':
        return [
          _FaqItem(
            _t3(context, ar: 'إزاي أحجز غرفة؟', en: 'How do I book a room?', es: '¿Cómo reservo una habitación?'),
            _t3(
              context,
              ar: 'ادخل على تبويب "الإقامة"، اختار المدينة والتواريخ وعدد الضيوف، وابدأ البحث. بعد ما تختار الفندق ونوع الغرفة، أكمل بيانات الحجز والدفع.',
              en: 'Go to the Stays tab, choose your city, dates, and guest count, then search. After picking a hotel and room type, complete your booking and payment.',
              es: 'Ve a la pestaña Alojamientos, elige ciudad, fechas y huéspedes, y busca. Luego elige hotel y tipo de habitación para completar la reserva.',
            ),
          ),
          _FaqItem(
            _t3(context, ar: 'أقدر ألغي حجزي؟', en: 'Can I cancel my booking?', es: '¿Puedo cancelar mi reserva?'),
            _t3(
              context,
              ar: 'أيوه، من صفحة "حجوزاتي" تقدر تلغي أي حجز لسه في حالة "قيد الانتظار" أو "مؤكد"، حسب سياسة الإلغاء بتاعة الفندق.',
              en: 'Yes, from "My Bookings" you can cancel any pending or confirmed booking, subject to the hotel\'s cancellation policy.',
              es: 'Sí, desde "Mis reservas" puedes cancelar cualquier reserva pendiente o confirmada, según la política del hotel.',
            ),
          ),
          _FaqItem(
            _t3(context, ar: 'إيه طرق الدفع المتاحة؟', en: 'What payment methods are supported?', es: '¿Qué métodos de pago se admiten?'),
            _t3(
              context,
              ar: 'بندعم الدفع عبر البطاقات الائتمانية على الأجهزة المدعومة. على بعض الأنظمة، الحجز بيتسجّل "قيد الانتظار" لحد ما يكتمل الدفع.',
              en: 'We support credit card payments on supported devices. On some platforms, bookings are registered as "pending" until payment is completed elsewhere.',
              es: 'Aceptamos pagos con tarjeta en dispositivos compatibles. En algunas plataformas, la reserva queda "pendiente" hasta completar el pago.',
            ),
          ),
          _FaqItem(
            _t3(context, ar: 'محتاج حساب عشان أدوّر على فنادق؟', en: 'Do I need an account to search for hotels?', es: '¿Necesito una cuenta para buscar hoteles?'),
            _t3(
              context,
              ar: 'لأ، تقدر تدوّر وتتصفح النتايج بدون تسجيل دخول. تسجيل الدخول مطلوب بس وقت تأكيد الحجز.',
              en: 'No, you can search and browse results without signing in. An account is only required when confirming a booking.',
              es: 'No, puedes buscar y explorar resultados sin iniciar sesión. Solo se requiere cuenta al confirmar una reserva.',
            ),
          ),
        ];
      case 'carRentals':
        return [
          _FaqItem(
            _t3(context, ar: 'إزاي أأجّر سيارة؟', en: 'How do I rent a car?', es: '¿Cómo alquilo un coche?'),
            _t3(
              context,
              ar: 'من تبويب "تأجير السيارات"، اكتب مدينة الاستلام والتواريخ، وابحث عن السيارات المتاحة.',
              en: 'From the Car rental tab, enter the pickup city and dates, then search available cars.',
              es: 'Desde la pestaña de alquiler, indica ciudad de recogida y fechas, y busca coches disponibles.',
            ),
          ),
          _FaqItem(
            _t3(context, ar: 'أقدر أسلّم السيارة في مكان مختلف؟', en: 'Can I drop off at a different location?', es: '¿Puedo devolver en otro lugar?'),
            _t3(
              context,
              ar: 'أيوه، فعّل خيار "مكان تسليم مختلف" في نموذج البحث واكتب المكان اللي حابب تسلّم فيه.',
              en: 'Yes, enable "Different drop-off location" in the search form and enter your preferred drop-off spot.',
              es: 'Sí, activa "Lugar de devolución diferente" en el formulario e indica el lugar deseado.',
            ),
          ),
        ];
      case 'flightHotel':
        return [
          _FaqItem(
            _t3(context, ar: 'هل حجز طيران + فندق أرخص؟', en: 'Is booking flight + hotel cheaper?', es: '¿Reservar vuelo + hotel es más barato?'),
            _t3(
              context,
              ar: 'بحث "طيران + فندق" بيوريك نتايج الفنادق المتاحة، وبحث الطيران المرتبط هيتفعّل قريبًا مع عروض حصرية للحجز المشترك.',
              en: 'The Flight+Hotel search shows available hotel results now; the linked flight search with bundled deals is coming soon.',
              es: 'La búsqueda combinada muestra hoteles disponibles ahora; los vuelos vinculados llegarán pronto con ofertas exclusivas.',
            ),
          ),
        ];
      case 'flights':
      default:
        return [
          _FaqItem(
            _t3(context, ar: 'فيه عروض على تذاكر الطيران؟', en: 'Are there any flight ticket promotions going on?', es: '¿Hay promociones en vuelos?'),
            _t3(
              context,
              ar: 'العروض بتتغيّر باستمرار حسب الوجهة والتاريخ. استخدم ميزة "تنبيهات الأسعار" عشان نبعتلك إيميل أول ما نلاقي السعر اللي حابب توصله.',
              en: 'Promotions change often by destination and date. Use "Price alerts" so we can email you as soon as we find your target price.',
              es: 'Las promociones cambian según destino y fecha. Usa "Alertas de precio" para recibir un correo al encontrar tu precio deseado.',
            ),
          ),
          _FaqItem(
            _t3(context, ar: 'إزاي أغيّر تذكرتي؟', en: 'How do I change my ticket?', es: '¿Cómo cambio mi boleto?'),
            _t3(
              context,
              ar: 'تعديل التذاكر بعد الحجز هيتفعّل قريبًا. لحد ما يبقى متاح، تواصل مع الدعم من الشات أو المكالمة تحت.',
              en: 'Post-booking ticket changes are coming soon. Until then, contact support via chat or call below.',
              es: 'Los cambios de boleto llegarán pronto. Mientras tanto, contacta soporte por chat o llamada abajo.',
            ),
          ),
          _FaqItem(
            _t3(context, ar: 'إزاي ألغي تذكرة الطيران؟', en: 'How can I cancel my flight ticket?', es: '¿Cómo cancelo mi boleto de vuelo?'),
            _t3(
              context,
              ar: 'إلغاء تذاكر الطيران هيتفعّل قريبًا. حجوزات الفنادق تقدر تلغيها فعليًا من صفحة "حجوزاتي".',
              en: 'Flight ticket cancellation is coming soon. Hotel bookings can already be cancelled from "My Bookings".',
              es: 'La cancelación de vuelos llegará pronto. Las reservas de hotel ya se pueden cancelar desde "Mis reservas".',
            ),
          ),
          _FaqItem(
            _t3(context, ar: 'عندك سؤال مختلف؟ كلّمنا دلوقتي', en: 'Have a different question? Chat with us now.', es: '¿Tienes otra pregunta? Chatea con nosotros.'),
            _t3(
              context,
              ar: 'استخدم زرار "Chat" تحت للتواصل مع فريق الدعم مباشرة.',
              en: 'Use the "Chat" button below to reach our support team directly.',
              es: 'Usa el botón "Chat" abajo para contactar directamente con soporte.',
            ),
          ),
        ];
    }
  }

  List<String> _tagsFor(String category) {
    switch (category) {
      case 'hotels':
        return ['Hot Topics', 'Booking & Price', 'Cancellation', 'Room Info', 'Payment'];
      case 'carRentals':
        return ['Hot Topics', 'Pickup & Return', 'Pricing', 'Insurance', 'License Requirements'];
      case 'flightHotel':
        return ['Hot Topics', 'Bundled Deals', 'Combined Cancellation'];
      case 'flights':
      default:
        return ['Hot Topics', 'Booking & Price', 'Ticketing & Payment', 'Booking Query', 'Passenger Information-related'];
    }
  }

  String _categoryLabel(BuildContext context, String category) {
    switch (category) {
      case 'hotels':
        return _t3(context, ar: 'الفنادق', en: 'Hotels', es: 'Hoteles');
      case 'carRentals':
        return _t3(context, ar: 'تأجير السيارات', en: 'Car Rentals', es: 'Alquiler de coches');
      case 'flightHotel':
        return _t3(context, ar: 'الفنادق والطيران', en: 'Hotels & Homes', es: 'Hoteles y vuelos');
      case 'flights':
      default:
        return _t3(context, ar: 'الطيران', en: 'Flights', es: 'Vuelos');
    }
  }

  @override
  Widget build(BuildContext context) {
    final categories = ['hotels', 'flights', 'flightHotel', 'carRentals'];
    final faqs = _faqsFor(context, _activeCategory);
    final tags = _tagsFor(_activeCategory);

    return Scaffold(
      appBar: const AppBanner(),
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            // هيدر بعنوان "Customer support"
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSizes.lg),
              color: AppColors.primaryDark,
              child: Row(
                children: [
                  Expanded(
                    child: RichText(
                      text: TextSpan(
                        style: const TextStyle(fontSize: 30, fontWeight: FontWeight.bold, color: Colors.white),
                        children: [
                          TextSpan(text: _t3(context, ar: 'دعم العملاء', en: 'Customer support', es: 'Atención al cliente')),
                          const TextSpan(text: ' .', style: TextStyle(color: Colors.amber)),
                        ],
                      ),
                    ),
                  ),
                  const Icon(Icons.support_agent, size: 64, color: Colors.white70),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSizes.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _t3(context, ar: 'شات الخدمة', en: 'Service chat', es: 'Chat de servicio'),
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSizes.md),
                  // تبويبات الفئات
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: categories.map((cat) {
                        final isActive = cat == _activeCategory;
                        return Padding(
                          padding: const EdgeInsetsDirectional.only(end: AppSizes.sm),
                          child: GestureDetector(
                            onTap: () => setState(() => _activeCategory = cat),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              decoration: BoxDecoration(
                                color: isActive ? AppColors.primaryDark : Colors.transparent,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: AppColors.divider),
                              ),
                              child: Text(
                                _categoryLabel(context, cat),
                                style: TextStyle(
                                  color: isActive ? Colors.white : AppColors.textPrimary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: AppSizes.md),
                  // كروت الأسئلة الشائعة (2 عمود)
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final isWide = constraints.maxWidth > 700;
                      if (!isWide) {
                        return Column(
                          children: faqs.map((f) => _FaqTile(item: f)).toList(),
                        );
                      }
                      final rows = <Widget>[];
                      for (var i = 0; i < faqs.length; i += 2) {
                        final second = i + 1 < faqs.length ? faqs[i + 1] : null;
                        rows.add(
                          IntrinsicHeight(
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Expanded(child: _FaqTile(item: faqs[i])),
                                const SizedBox(width: AppSizes.md),
                                Expanded(
                                  child: second != null ? _FaqTile(item: second) : const SizedBox.shrink(),
                                ),
                              ],
                            ),
                          ),
                        );
                        rows.add(const SizedBox(height: AppSizes.sm));
                      }
                      return Column(children: rows);
                    },
                  ),
                  const SizedBox(height: AppSizes.lg),
                  Text(
                    _t3(
                      context,
                      ar: 'المزيد من أسئلة ${_categoryLabel(context, _activeCategory)}',
                      en: 'More ${_categoryLabel(context, _activeCategory)} FAQ',
                      es: 'Más preguntas de ${_categoryLabel(context, _activeCategory)}',
                    ),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: AppSizes.sm),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ...tags.map(
                            (tag) => Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: AppColors.background,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(tag, style: const TextStyle(fontSize: 13)),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Text('...'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            // شريط الوصول السريع تحت
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: _QuickAccessButton(
                      icon: Icons.headset_mic_outlined,
                      label: _t3(context, ar: 'شات', en: 'Chat', es: 'Chat'),
                      onTap: () => _comingSoon(context),
                    ),
                  ),
                  const VerticalDivider(width: 1),
                  Expanded(
                    child: _QuickAccessButton(
                      icon: Icons.call_outlined,
                      label: _t3(context, ar: 'اتصل بنا', en: 'Call us', es: 'Llámanos'),
                      onTap: () => _comingSoon(context),
                    ),
                  ),
                  const VerticalDivider(width: 1),
                  Expanded(
                    child: _QuickAccessButton(
                      icon: Icons.info_outline,
                      label: 'FAQ',
                      onTap: () => _comingSoon(context),
                    ),
                  ),
                  const VerticalDivider(width: 1),
                  Expanded(
                    child: _QuickAccessButton(
                      icon: Icons.sos_outlined,
                      label: _t3(context, ar: 'مساعدة طارئة', en: 'Emergency assistance', es: 'Asistencia de emergencia'),
                      onTap: () => _comingSoon(context),
                    ),
                  ),
                ],
              ),
            ),
            const AppFooter(),
          ],
        ),
      ),
    );
  }
}

class _FaqTile extends StatefulWidget {
  final _FaqItem item;
  const _FaqTile({required this.item});

  @override
  State<_FaqTile> createState() => _FaqTileState();
}

class _FaqTileState extends State<_FaqTile> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSizes.sm),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => setState(() => _expanded = !_expanded),
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.item.question,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                  Icon(_expanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down),
                ],
              ),
              if (_expanded) ...[
                const SizedBox(height: 8),
                Text(
                  widget.item.answer,
                  style: const TextStyle(color: AppColors.textSecondary, height: 1.4),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickAccessButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickAccessButton({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSizes.md),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: AppColors.primary),
            const SizedBox(height: 6),
            Text(label, style: const TextStyle(fontSize: 13), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}