import 'package:flutter/material.dart';

import '../../core/constants/app_sizes.dart';
import '../../core/widgets/app_banner.dart';
import '../../core/widgets/app_footer.dart';
import '../home/widgets/deals_section.dart';

/// صفحة العروض الموسمية — بتعرض نفس DealsSection المستخدمة في تبويب
/// Stays، عشان مانخترعش بيانات عروض وهمية منفصلة، والمحتوى يفضل مصدر
/// واحد يتحدّث في مكان واحد بس.
class SeasonalDealsPage extends StatelessWidget {
  const SeasonalDealsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AppBanner(),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: AppSizes.lg),
          children: const [
            DealsSection(),
            SizedBox(height: AppSizes.xl),
            AppFooter(),
          ],
        ),
      ),
    );
  }
}