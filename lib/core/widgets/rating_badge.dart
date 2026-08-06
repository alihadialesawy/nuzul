import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../constants/app_sizes.dart';

/// بادج تقييم بأسلوب Booking.com: مربع ملون بالرقم (من 10) على اليسار،
/// وعلى اليمين كلمة وصفية للتقييم وتحتها عدد التقييمات.
///
/// مثال الاستخدام:
/// ```dart
/// RatingBadge(rating: hotel.rating, reviewCount: hotel.reviewCount)
/// ```
class RatingBadge extends StatelessWidget {
  final double rating;
  final int reviewCount;
  final MainAxisAlignment alignment;

  const RatingBadge({
    super.key,
    required this.rating,
    required this.reviewCount,
    this.alignment = MainAxisAlignment.start,
  });

  /// كلمة وصفية للتقييم على مقياس من 10، بالعربي أو الإنجليزي حسب لغة الواجهة.
  static String _label(BuildContext context, double rating) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    if (rating >= 9.0) return isArabic ? 'رائع' : 'Wonderful';
    if (rating >= 8.0) return isArabic ? 'جيد جدًا' : 'Very Good';
    if (rating >= 7.0) return isArabic ? 'جيد' : 'Good';
    if (rating >= 6.0) return isArabic ? 'مقبول' : 'Pleasant';
    return isArabic ? 'متوسط' : 'Fair';
  }

  static String _reviewsText(BuildContext context, int count) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final formattedCount = _formatCount(count);
    return isArabic ? '$formattedCount تقييم' : '$formattedCount reviews';
  }

  static String _formatCount(int count) {
    // فاصلة الآلاف: 4673 -> 4,673
    final str = count.toString();
    final buffer = StringBuffer();
    for (int i = 0; i < str.length; i++) {
      if (i != 0 && (str.length - i) % 3 == 0) buffer.write(',');
      buffer.write(str[i]);
    }
    return buffer.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: alignment,
      mainAxisSize: MainAxisSize.min,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              _label(context, rating),
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),
            Text(
              _reviewsText(context, reviewCount),
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
            ),
          ],
        ),
        const SizedBox(width: AppSizes.sm),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            rating.toStringAsFixed(1),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
        ),
      ],
    );
  }
}