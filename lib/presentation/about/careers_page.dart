import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../app.dart';
import 'package:go_router/go_router.dart';

class CareersPage extends StatelessWidget {
  const CareersPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    return Scaffold(
      appBar: AppBar(
        title: Text(isArabic ? 'الوظائف' : 'Careers'),
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
                  isArabic ? 'الوظائف في Flynoom' : 'Careers at Flynoom',
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: AppSizes.md),
                Text(
                  isArabic
                      ? 'Flynoom لسه في مراحلها الأولى جدًا — فريق صغير بيبني منصة سفر من الصفر. مفيش وظائف مفتوحة رسميًا في الوقت الحالي، لكن ده هيتغيّر مع نمو المنصة.'
                      : "Flynoom is still very early — a small team building a travel platform from the ground up. We don't have formal open positions right now, but that will change as the platform grows.",
                  style: const TextStyle(fontSize: 14, height: 1.6, color: AppColors.textSecondary),
                ),
                const SizedBox(height: AppSizes.lg),
                Text(
                  isArabic ? 'مهتم تنضم لينا؟' : 'Interested in joining us?',
                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 6),
                Text(
                  isArabic
                      ? 'لو عندك خبرة تعتقد إنها ممكن تفيد Flynoom (تطوير، تصميم، دعم عملاء، أو أي مجال آخر)، تقدر تتواصل معنا عبر صفحة خدمة العملاء وتقولنا اهتمامك — هنحتفظ برسالتك ونرجعلك أول ما تفتح فرصة تناسبك.'
                      : "If you have experience you think could help Flynoom (development, design, customer support, or anything else), you can reach out through our Customer Service page and let us know — we'll keep your note on file and get back to you when a role opens up.",
                  style: const TextStyle(fontSize: 14, height: 1.6, color: AppColors.textSecondary),
                ),
                const SizedBox(height: AppSizes.lg),
                OutlinedButton(
                  onPressed: () => context.push(AppRoutes.support),
                  child: Text(isArabic ? 'تواصل معنا' : 'Contact us'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}