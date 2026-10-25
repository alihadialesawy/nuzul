import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';

String _t3(
    BuildContext context, {
      required String ar,
      required String en,
      required String es,
      required String tr,
      required String id,
      required String hi,
      required String ur,
      required String fr,
      required String bn,
    }) {
  switch (Localizations.localeOf(context).languageCode) {
    case 'ar':
      return ar;
    case 'es':
      return es;
    case 'tr':
      return tr;
    case 'id':
      return id;
    case 'hi':
      return hi;
    case 'ur':
      return ur;
    case 'fr':
      return fr;
    case 'bn':
      return bn;
    default:
      return en;
  }
}

/// سلايد واحد داخل البانر الإعلاني: صورة خلفية + عنوان + نص فرعي
/// (اختياري)، بيتعرضوا فوق الصورة بتدرّج تظليل أسفلها لوضوح النص.
class PromoSlide {
  final String imageAsset;
  final String title;
  final String? subtitle;

  const PromoSlide({required this.imageAsset, required this.title, this.subtitle});
}

/// بانر إعلانات متحرك تلقائيًا -- بيغيّر السلايد كل 4 ثواني بمفرده
/// (PageView + Timer.periodic)، مع إمكانية اللمس/السحب اليدوي كمان،
/// ونقط مؤشر (dots) في الأسفل توضح السلايد الحالي من إجمالي عددهم.
class PromoBannerCarousel extends StatefulWidget {
  final List<PromoSlide> slides;
  final double height;

  const PromoBannerCarousel({super.key, required this.slides, this.height = 160});

  @override
  State<PromoBannerCarousel> createState() => _PromoBannerCarouselState();
}

class _PromoBannerCarouselState extends State<PromoBannerCarousel> {
  final _pageController = PageController();
  Timer? _autoTimer;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    if (widget.slides.length > 1) {
      _autoTimer = Timer.periodic(const Duration(seconds: 4), (_) => _advance());
    }
  }

  void _advance() {
    if (!mounted || !_pageController.hasClients) return;
    final nextPage = (_currentPage + 1) % widget.slides.length;
    _pageController.animateToPage(
      nextPage,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _autoTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.slides.isEmpty) return const SizedBox.shrink();

    // هامش يمين ويسار بنفس هامش شريط البحث، حتى لا يمتد الإعلان تحت
    // شريط التمرير (scrollbar) على الويب وسطح المكتب.
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSizes.md, AppSizes.md, AppSizes.md, 0),
      child: SizedBox(
        height: widget.height,
        child: Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: PageView.builder(
                controller: _pageController,
                itemCount: widget.slides.length,
                onPageChanged: (index) => setState(() => _currentPage = index),
                itemBuilder: (context, index) {
                  final slide = widget.slides[index];
                  return Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.asset(
                        slide.imageAsset,
                        fit: BoxFit.cover,
                        filterQuality: FilterQuality.high,
                        errorBuilder: (_, __, ___) => Container(color: AppColors.primaryDark),
                      ),
                      DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                            colors: [
                              Colors.black.withOpacity(0.55),
                              Colors.black.withOpacity(0.0),
                            ],
                          ),
                        ),
                      ),
                      Positioned(
                        left: 20,
                        right: 20,
                        top: 0,
                        bottom: 0,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              slide.title,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 20,
                                shadows: [Shadow(blurRadius: 4, color: Colors.black54)],
                              ),
                            ),
                            if (slide.subtitle != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                slide.subtitle!,
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 13,
                                  shadows: [Shadow(blurRadius: 3, color: Colors.black54)],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            if (widget.slides.length > 1)
              Positioned(
                bottom: 10,
                left: 0,
                right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(widget.slides.length, (index) {
                    final isActive = index == _currentPage;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      width: isActive ? 18 : 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: isActive ? Colors.white : Colors.white54,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    );
                  }),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// السلايدات الافتراضية لبانر Stays.
///
/// ⚠️ كل جملة هنا وعد إعلاني للعميل (FTC Act §5): لا تكتب خصمًا أو نسبة توفير
/// أو "عرضًا حصريًا" أو "عرضًا لفترة محدودة" إلا إذا كان موجودًا فعلًا في
/// النظام بشروط واضحة وتاريخ انتهاء حقيقي. النصوص الحالية تصف ميزات حقيقية فقط.
List<PromoSlide> defaultStaysPromoSlides(BuildContext context) {
  return [
    PromoSlide(
      imageAsset: 'assets/images/promos/limited_offer.jpg',
      title: _t3(context, ar: 'أسعار شاملة بلا رسوم خفية', en: 'All-in prices, no hidden fees', es: 'Precios finales, sin cargos ocultos', tr: 'Her şey dahil fiyatlar, gizli ücret yok', id: 'Harga lengkap, tanpa biaya tersembunyi',
          hi: 'पूरी कीमत, कोई छिपा शुल्क नहीं',
          ur: 'مکمل قیمت، کوئی پوشیدہ فیس نہیں',
          fr: 'Prix tout compris, sans frais cachés',
          bn: 'সব মিলিয়ে দাম, কোনো লুকানো ফি নেই'),
      subtitle: _t3(context, ar: 'ترى الضرائب والرسوم الإلزامية قبل أن تدفع', en: 'See taxes and mandatory fees before you pay', es: 'Ve impuestos y tasas obligatorias antes de pagar', tr: 'Ödemeden önce vergileri ve zorunlu ücretleri görün', id: 'Lihat pajak dan biaya wajib sebelum membayar',
          hi: 'भुगतान से पहले टैक्स और अनिवार्य शुल्क देखें',
          ur: 'ادائیگی سے پہلے ٹیکس اور لازمی فیس دیکھیں',
          fr: 'Voyez les taxes et frais obligatoires avant de payer',
          bn: 'পেমেন্টের আগে ট্যাক্স ও বাধ্যতামূলক ফি দেখুন'),
    ),
    PromoSlide(
      imageAsset: 'assets/images/promos/free_cancellation.jpg',
      title: _t3(context, ar: 'إلغاء مجاني في غرف كثيرة', en: 'Free cancellation on many rooms', es: 'Cancelación gratuita en muchas habitaciones', tr: 'Birçok odada ücretsiz iptal', id: 'Pembatalan gratis untuk banyak kamar',
          hi: 'कई कमरों पर मुफ़्त रद्दीकरण',
          ur: 'بہت سے کمروں پر مفت منسوخی',
          fr: 'Annulation gratuite sur de nombreuses chambres',
          bn: 'অনেক রুমে বিনামূল্যে বাতিল'),
      subtitle: _t3(context, ar: 'سياسة الإلغاء معروضة بوضوح قبل الحجز', en: 'Each room shows its cancellation policy before you book', es: 'Cada habitación muestra su política de cancelación antes de reservar', tr: 'Her oda, rezervasyondan önce iptal politikasını gösterir', id: 'Setiap kamar menampilkan kebijakan pembatalan sebelum Anda memesan',
          hi: 'हर कमरे की रद्दीकरण नीति बुकिंग से पहले दिखती है',
          ur: 'ہر کمرے کی منسوخی کی پالیسی بکنگ سے پہلے دکھائی جاتی ہے',
          fr: 'Chaque chambre affiche sa politique d\'annulation avant la réservation',
          bn: 'বুকিংয়ের আগে প্রতিটি রুমের বাতিল নীতি দেখানো হয়'),
    ),
    PromoSlide(
      imageAsset: 'assets/images/promos/family_deals.jpg',
      title: _t3(context, ar: 'حجوزات المجموعات والعائلات', en: 'Group and family stays', es: 'Estancias para grupos y familias', tr: 'Grup ve aile konaklamaları', id: 'Menginap untuk grup dan keluarga',
          hi: 'समूह और परिवार के ठहराव',
          ur: 'گروپ اور خاندانی قیام',
          fr: 'Séjours en groupe et en famille',
          bn: 'গ্রুপ ও পারিবারিক থাকা'),
      subtitle: _t3(context, ar: '5 غرف فأكثر؟ اطلب عرض سعر من تبويب Group stays', en: '5 or more rooms? Request a quote in Group stays', es: '¿5 habitaciones o más? Pide un presupuesto en Group stays', tr: '5 veya daha fazla oda mı? Group stays bölümünden teklif isteyin', id: '5 kamar atau lebih? Minta penawaran di Group stays',
          hi: '5 या अधिक कमरे? Group stays में कोटेशन मांगें',
          ur: '5 یا زیادہ کمرے؟ Group stays میں قیمت کی درخواست کریں',
          fr: '5 chambres ou plus ? Demandez un devis dans Group stays',
          bn: '৫ বা তার বেশি রুম? Group stays-এ কোটেশন চান'),
    ),
    PromoSlide(
      imageAsset: 'assets/images/promos/weekend_getaway.jpg',
      title: _t3(context, ar: 'رحلة نهاية الأسبوع', en: 'Weekend getaway', es: 'Escapada de fin de semana', tr: 'Hafta sonu kaçamağı', id: 'Liburan akhir pekan',
          hi: 'सप्ताहांत की छुट्टी',
          ur: 'ہفتہ وار چھٹی',
          fr: 'Escapade de week-end',
          bn: 'সাপ্তাহিক ছুটি'),
      subtitle: null,
    ),
  ];
}