import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';

class _InfoSection {
  final String titleEn;
  final String titleAr;
  final String bodyEn;
  final String bodyAr;
  const _InfoSection({
    required this.titleEn,
    required this.titleAr,
    required this.bodyEn,
    required this.bodyAr,
  });
}

class HowWeWorkPage extends StatelessWidget {
  const HowWeWorkPage({super.key});

  static const List<_InfoSection> _sections = [
    _InfoSection(
      titleEn: 'A marketplace, not an airline or a hotel',
      titleAr: 'منصة وسيطة، مش شركة طيران أو فندق',
      bodyEn:
      'Flynoom does not own any aircraft, hotels, or rental cars. We connect you to real inventory from airlines and hotel suppliers through trusted technology partners, so you can search, compare, and book everything in one place.',
      bodyAr:
      'Flynoom لا تمتلك أي طائرات أو فنادق أو سيارات مؤجرة. نحن نصلك بالمخزون الفعلي من شركات الطيران ومزوّدي الفنادق عبر شركاء تقنيين موثوقين، حتى تتمكن من البحث والمقارنة والحجز في مكان واحد.',
    ),
    _InfoSection(
      titleEn: 'Real-time flight search',
      titleAr: 'بحث رحلات في الوقت الفعلي',
      bodyEn:
      'Flight results come from Duffel, a live flight-booking platform connected to major airlines. Prices, seat availability, and schedules are pulled in real time each time you search, so what you see reflects what airlines are actually offering right now.',
      bodyAr:
      'نتائج رحلات الطيران تأتي من Duffel، منصة حجز طيران فعلية متصلة بشركات طيران كبرى. تُجلب الأسعار وتوافر المقاعد والجداول في الوقت الفعلي مع كل عملية بحث، بحيث تعكس ما تعرضه شركات الطيران فعليًا في تلك اللحظة.',
    ),
    _InfoSection(
      titleEn: 'Real-time hotel search',
      titleAr: 'بحث فنادق في الوقت الفعلي',
      bodyEn:
      'Hotel results come from HotelBeds, one of the world\'s largest hotel supply networks. This gives you access to a wide range of properties, room types, and rates without Flynoom having to negotiate with each hotel individually.',
      bodyAr:
      'نتائج الفنادق تأتي من HotelBeds، إحدى أكبر شبكات توريد الفنادق في العالم. يمنحك ذلك وصولًا لمجموعة واسعة من العقارات وأنواع الغرف والأسعار من دون الحاجة لتفاوض Flynoom مع كل فندق على حدة.',
    ),
    _InfoSection(
      titleEn: 'One secure checkout',
      titleAr: 'إتمام دفع واحد وآمن',
      bodyEn:
      'Whatever you book, payment is processed securely through Stripe, a payment processor used by millions of businesses worldwide. Flynoom never stores your full card number.',
      bodyAr:
      'أيًا كان ما تحجزه، تُعالَج المدفوعات بأمان عبر Stripe، معالج مدفوعات تستخدمه ملايين الشركات حول العالم. Flynoom لا تخزّن رقم بطاقتك الكامل أبدًا.',
    ),
    _InfoSection(
      titleEn: 'Support when you need it',
      titleAr: 'دعم وقت ما تحتاجه',
      bodyEn:
      'If something changes with your trip — a flight delay, a booking question, a cancellation request — our Customer Service team is here to help you sort it out with the supplier.',
      bodyAr:
      'لو حصل أي تغيير في رحلتك — تأخير طيران، سؤال عن حجز، طلب إلغاء — فريق خدمة العملاء لدينا موجود لمساعدتك في التنسيق مع المزوّد.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    return Scaffold(
      appBar: AppBar(
        title: Text(isArabic ? 'كيف نعمل' : 'How We Work'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSizes.md),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isArabic ? 'كيف تعمل Flynoom' : 'How Flynoom works',
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: AppSizes.md),
                Text(
                  isArabic
                      ? 'Flynoom منصة تجمع رحلات الطيران والإقامات الفندقية من مزوّدين حقيقيين في مكان واحد، عشان تحجز رحلتك كاملة براحة من غير ما تفتح عشرة مواقع مختلفة.'
                      : 'Flynoom brings flights and hotel stays from real suppliers together in one place, so you can book your whole trip without opening ten different websites.',
                  style: const TextStyle(fontSize: 14, height: 1.6, color: AppColors.textSecondary),
                ),
                const SizedBox(height: AppSizes.lg),
                for (final s in _sections) ...[
                  Text(
                    isArabic ? s.titleAr : s.titleEn,
                    style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    isArabic ? s.bodyAr : s.bodyEn,
                    style: const TextStyle(fontSize: 14, height: 1.6, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: AppSizes.lg),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}