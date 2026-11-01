import 'package:flutter/material.dart';

import '../../../core/constants/app_sizes.dart';

class _Deal {
  final IconData icon;
  final String titleEn;
  final String titleAr;
  final String subtitleEn;
  final String subtitleAr;
  final Color color;

  const _Deal({
    required this.icon,
    required this.titleEn,
    required this.titleAr,
    required this.subtitleEn,
    required this.subtitleAr,
    required this.color,
  });
}

const List<_Deal> _deals = [
  _Deal(
    icon: Icons.weekend_outlined,
    titleEn: 'Weekend Getaway',
    titleAr: 'عروض عطلة نهاية الأسبوع',
    subtitleEn: 'Save on stays this weekend',
    subtitleAr: 'وفّر على إقامتك في عطلة نهاية الأسبوع',
    color: Color(0xFF0B6E4F),
  ),
  _Deal(
    icon: Icons.percent_outlined,
    titleEn: 'Early Bird Discount',
    titleAr: 'خصم الحجز المبكر',
    subtitleEn: 'Book ahead and save more',
    subtitleAr: 'احجز مبكرًا ووفّر أكثر',
    color: Color(0xFF1E5F74),
  ),
  _Deal(
    icon: Icons.family_restroom_outlined,
    titleEn: 'Family Stays',
    titleAr: 'عروض العائلات',
    subtitleEn: 'Great deals for family trips',
    subtitleAr: 'عروض مميزة لرحلات العائلة',
    color: Color(0xFF7A4B8A),
  ),
];

/// ترجمات القسم للغات السبع الأخرى.
/// الترتيب: [عنوان القسم، "قريبًا"، ثم (عنوان، وصف) لكل عرض بنفس ترتيب _deals].
/// ⚠️ عند إضافة عرض جديد أضف عنوانه ووصفه في آخر كل قائمة، وإلا سيظهر بالإنجليزية.
const Map<String, List<String>> _i18n = {
  'es': [
    'Ofertas y promociones',
    'Próximamente',
    'Escapada de fin de semana',
    'Ahorra en tu estancia este fin de semana',
    'Descuento por reserva anticipada',
    'Reserva con antelación y ahorra más',
    'Estancias en familia',
    'Grandes ofertas para viajes en familia',
  ],
  'tr': [
    'Fırsatlar ve kampanyalar',
    'Çok yakında',
    'Hafta sonu kaçamağı',
    'Bu hafta sonu konaklamada tasarruf edin',
    'Erken rezervasyon indirimi',
    'Erken rezervasyon yapın, daha çok tasarruf edin',
    'Aile konaklamaları',
    'Aile gezileri için harika fırsatlar',
  ],
  'id': [
    'Penawaran & promo',
    'Segera hadir',
    'Liburan akhir pekan',
    'Hemat menginap akhir pekan ini',
    'Diskon pesan lebih awal',
    'Pesan lebih awal dan hemat lebih banyak',
    'Menginap bersama keluarga',
    'Penawaran menarik untuk liburan keluarga',
  ],
  'hi': [
    'डील्स और ऑफ़र',
    'जल्द आ रहा है',
    'वीकेंड गेटअवे',
    'इस वीकेंड ठहरने पर बचत करें',
    'अर्ली बर्ड छूट',
    'पहले बुक करें और ज़्यादा बचाएँ',
    'परिवार के साथ ठहराव',
    'पारिवारिक यात्राओं के लिए बेहतरीन डील्स',
  ],
  'ur': [
    'ڈیلز اور آفرز',
    'جلد آ رہا ہے',
    'ویک اینڈ کی سیر',
    'اس ویک اینڈ قیام پر بچت کریں',
    'پیشگی بکنگ رعایت',
    'پہلے بک کریں اور زیادہ بچائیں',
    'فیملی قیام',
    'فیملی سفر کے لیے بہترین ڈیلز',
  ],
  'fr': [
    'Offres et promotions',
    'Bientôt disponible',
    'Escapade du week-end',
    'Économisez sur votre séjour ce week-end',
    'Réduction réservation anticipée',
    'Réservez tôt et économisez davantage',
    'Séjours en famille',
    'De belles offres pour voyager en famille',
  ],
  'bn': [
    'অফার ও ছাড়',
    'শীঘ্রই আসছে',
    'সপ্তাহান্তের ছুটি',
    'এই সপ্তাহান্তে থাকায় সাশ্রয় করুন',
    'আগাম বুকিং ছাড়',
    'আগে বুক করুন, আরও সাশ্রয় করুন',
    'পরিবারের সঙ্গে থাকা',
    'পারিবারিক ভ্রমণের জন্য দারুণ অফার',
  ],
};

/// قسم "عروض وخصومات" ترويجي — العروض حاليًا شكلية (تعرض "قريبًا")
/// إلى أن يُبنى نظام عروض فعلي مرتبط بقاعدة البيانات.
/// يُستخدم في تبويب Stays وفي صفحة العروض الموسمية (seasonal_deals_page.dart).
class DealsSection extends StatelessWidget {
  const DealsSection({super.key});

  @override
  Widget build(BuildContext context) {
    final lang = Localizations.localeOf(context).languageCode;
    final isArabic = lang == 'ar';
    final tr = _i18n[lang];

    // نص مترجم من _i18n إن وُجد، وإلا العربية أو الإنجليزية.
    String pick(int i, String en, String ar) =>
        (tr != null && i < tr.length) ? tr[i] : (isArabic ? ar : en);

    void showComingSoon() {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(pick(1, 'Coming soon', 'قريبًا')),
          duration: const Duration(seconds: 1),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSizes.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSizes.md),
            child: Text(
              pick(0, 'Deals & Offers', 'عروض وخصومات'),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ),
          const SizedBox(height: AppSizes.sm),
          SizedBox(
            height: 110,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: AppSizes.md),
              itemCount: _deals.length,
              separatorBuilder: (_, __) => const SizedBox(width: AppSizes.sm),
              itemBuilder: (context, index) {
                final deal = _deals[index];
                return InkWell(
                  onTap: showComingSoon,
                  borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                  child: Container(
                    width: 220,
                    padding: const EdgeInsets.all(AppSizes.md),
                    decoration: BoxDecoration(
                      color: deal.color,
                      borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(deal.icon, color: Colors.white, size: 26),
                        const Spacer(),
                        Text(
                          pick(2 + index * 2, deal.titleEn, deal.titleAr),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          pick(3 + index * 2, deal.subtitleEn, deal.subtitleAr),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}