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

    return Padding(
      padding: const EdgeInsets.only(top: AppSizes.md),
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

/// السلايدات الافتراضية لبانر Stays -- عدّل النصوص أو أضف/احذف سلايدات
/// بحرية، وسمّي صور assets/images/promos/ بنفس الأسماء دي.
List<PromoSlide> defaultStaysPromoSlides(BuildContext context) {
  return [
    PromoSlide(
      imageAsset: 'assets/images/promos/limited_offer.jpg',
      title: _t3(context, ar: 'عرض محدود لفترة قصيرة', en: 'Limited-time offer', es: 'Oferta por tiempo limitado', tr: 'Sınırlı süreli teklif', id: 'Penawaran waktu terbatas',
          hi: 'सीमित समय का ऑफर',
          ur: 'محدود وقت کی پیشکش',
          fr: 'Offre à durée limitée',
          bn: 'সীমিত সময়ের অফার'),
      subtitle: _t3(context, ar: 'وفّر حتى 30% على حجزك القادم', en: 'Save up to 30% on your next stay', es: 'Ahorra hasta un 30% en tu próxima estancia', tr: 'Bir sonraki konaklamanızda %30\'a varan tasarruf edin', id: 'Hemat hingga 30% untuk menginap berikutnya',
          hi: 'अपने अगले प्रवास पर 30% तक बचाएं',
          ur: 'اپنے اگلے قیام پر 30% تک بچائیں',
          fr: 'Économisez jusqu\'à 30% sur votre prochain séjour',
          bn: 'আপনার পরবর্তী থাকার উপর ৩০% পর্যন্ত সাশ্রয় করুন'),
    ),
    PromoSlide(
      imageAsset: 'assets/images/promos/free_cancellation.jpg',
      title: _t3(context, ar: 'إلغاء مجاني', en: 'Free cancellation', es: 'Cancelación gratuita', tr: 'Ücretsiz iptal', id: 'Pembatalan gratis',
          hi: 'मुफ़्त रद्दीकरण',
          ur: 'مفت منسوخی',
          fr: 'Annulation gratuite',
          bn: 'বিনামূল্যে বাতিলকরণ'),
      subtitle: _t3(context, ar: 'احجز الآن وادفع لاحقًا بدون التزام', en: 'Book now, pay later — no commitment', es: 'Reserva ahora, paga después', tr: 'Şimdi rezervasyon yapın, sonra ödeyin', id: 'Pesan sekarang, bayar nanti',
          hi: 'अभी बुक करें, बाद में भुगतान करें',
          ur: 'ابھی بک کریں، بعد میں ادائیگی کریں',
          fr: 'Réservez maintenant, payez plus tard',
          bn: 'এখন বুক করুন, পরে পেমেন্ট করুন'),
    ),
    PromoSlide(
      imageAsset: 'assets/images/promos/family_deals.jpg',
      title: _t3(context, ar: 'عروض حصرية للعائلات', en: 'Exclusive family deals', es: 'Ofertas exclusivas para familias', tr: 'Ailelere özel fırsatlar', id: 'Penawaran eksklusif untuk keluarga',
          hi: 'परिवारों के लिए विशेष ऑफ़र',
          ur: 'خاندانوں کے لیے خصوصی آفرز',
          fr: 'Offres exclusives pour les familles',
          bn: 'পরিবারের জন্য এক্সক্লুসিভ অফার'),
      subtitle: null,
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