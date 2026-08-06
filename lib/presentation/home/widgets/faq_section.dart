import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';

class _FaqItem {
  final String questionEn;
  final String questionAr;
  final String answerEn;
  final String answerAr;

  const _FaqItem({
    required this.questionEn,
    required this.questionAr,
    required this.answerEn,
    required this.answerAr,
  });
}

const List<_FaqItem> _faqItems = [
  _FaqItem(
    questionEn: 'How do I book a room?',
    questionAr: 'كيف أحجز غرفة؟',
    answerEn: 'Search for a city, choose a hotel and room type, then confirm '
        'your booking. Payment is completed securely on supported platforms.',
    answerAr: 'دوّر على مدينة، اختار فندق ونوع الغرفة، وبعدين أكّد الحجز. '
        'الدفع يتم بشكل آمن على المنصات المدعومة.',
  ),
  _FaqItem(
    questionEn: 'Can I cancel my booking?',
    questionAr: 'هل يمكنني إلغاء حجزي؟',
    answerEn: 'Yes, you can review and cancel your bookings from the '
        '"My Bookings" section.',
    answerAr: 'نعم، تقدر تراجع وتلغي حجوزاتك من قسم "حجوزاتي".',
  ),
  _FaqItem(
    questionEn: 'What payment methods are supported?',
    questionAr: 'ما هي وسائل الدفع المتاحة؟',
    answerEn: 'Payments are processed securely through Stripe on supported '
        'platforms (mobile).',
    answerAr: 'الدفع يتم بشكل آمن عبر Stripe على المنصات المدعومة (الموبايل).',
  ),
  _FaqItem(
    questionEn: 'Do I need an account to search for hotels?',
    questionAr: 'هل أحتاج حساب للبحث عن الفنادق؟',
    answerEn: 'No, you can browse and search freely as a guest. An account '
        'is only required when confirming a booking.',
    answerAr: 'لا، تقدر تتصفح وتبحث بحرية كضيف. الحساب مطلوب بس عند تأكيد الحجز.',
  ),
];

/// قسم "أسئلة شائعة" — محتوى ثابت مفيد للمستخدم، مش محتاج بيانات
/// من قاعدة البيانات.
class FaqSection extends StatelessWidget {
  const FaqSection({super.key});

  @override
  Widget build(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSizes.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSizes.md),
            child: Text(
              isArabic ? 'أسئلة شائعة' : 'Frequently Asked Questions',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ),
          const SizedBox(height: AppSizes.sm),
          ..._faqItems.map((item) {
            return ExpansionTile(
              title: Text(
                isArabic ? item.questionAr : item.questionEn,
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              ),
              tilePadding: const EdgeInsets.symmetric(horizontal: AppSizes.md),
              childrenPadding: const EdgeInsets.only(
                left: AppSizes.md,
                right: AppSizes.md,
                bottom: AppSizes.sm,
              ),
              expandedCrossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isArabic ? item.answerAr : item.answerEn,
                  style: const TextStyle(color: AppColors.textSecondary, height: 1.4),
                ),
              ],
            );
          }),
        ],
      ),
    );
  }
}