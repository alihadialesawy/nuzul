import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app.dart';
import '../constants/app_colors.dart';
import '../constants/app_sizes.dart';
import 'currency_selector_button.dart';

/// فوتر مشترك يُضاف في نهاية كل صفحة رئيسية بالتطبيق. كل قسم
/// (Support/Discover/Terms/Partners/About) عمود مستقل بجانب الباقي،
/// وكل روابط القسم ظاهرة تحت عنوانه بشكل دائم من غير حاجة للضغط.
/// روابط قسم "الدعم" فقط مفعّلة فعليًا وتنقل لصفحات حقيقية؛ باقي الروابط
/// لسه شكلية (تعرض "قريبًا") إلى أن تُبنى صفحات فعلية لها لاحقًا.
class AppFooter extends StatelessWidget {
  const AppFooter({super.key});

  static const double _columnWidth = 180;

  static List<_FooterSectionData> _footerSections(bool isArabic) {
    if (isArabic) {
      return [
        _FooterSectionData('الدعم', [
          _FooterLinkData('إدارة رحلاتك', route: AppRoutes.myBookings),
          _FooterLinkData('التواصل مع خدمة العملاء', route: AppRoutes.support),
          _FooterLinkData('مركز مصادر الأمان', route: AppRoutes.support),
        ]),
        _FooterSectionData('استكشف', const [
          _FooterLinkData('برنامج الولاء'),
          _FooterLinkData('عروض موسمية وعطلات'),
          _FooterLinkData('مقالات سفر'),
          _FooterLinkData('نزل للأعمال'),
          _FooterLinkData('جوائز تقييم المسافرين'),
          _FooterLinkData('تأجير السيارات'),
          _FooterLinkData('محرك بحث الرحلات', route: AppRoutes.flights),
          _FooterLinkData('حجوزات المطاعم'),
          _FooterLinkData('نزل لوكلاء السفر'),
        ]),
        _FooterSectionData('الشروط والإعدادات', const [
          _FooterLinkData('إشعار الخصوصية'),
          _FooterLinkData('شروط الخدمة'),
          _FooterLinkData('بيان إمكانية الوصول'),
          _FooterLinkData('حل النزاعات'),
          _FooterLinkData('بيان مكافحة العمل القسري'),
          _FooterLinkData('بيان حقوق الإنسان'),
        ]),
        _FooterSectionData('الشركاء', const [
          _FooterLinkData('تسجيل دخول الشركاء'),
          _FooterLinkData('مساعدة الشركاء'),
          _FooterLinkData('أضف عقارك'),
          _FooterLinkData('انضم كشريك تسويق'),
        ]),
        _FooterSectionData('عن نزل', const [
          _FooterLinkData('عن نزل'),
          _FooterLinkData('كيف نعمل'),
          _FooterLinkData('الاستدامة'),
          _FooterLinkData('المركز الصحفي'),
          _FooterLinkData('الوظائف'),
          _FooterLinkData('علاقات المستثمرين'),
          _FooterLinkData('التواصل المؤسسي'),
          _FooterLinkData('إرشادات المحتوى والتبليغ'),
        ]),
      ];
    }

    return [
      _FooterSectionData('Support', [
        _FooterLinkData('Manage your trips', route: AppRoutes.myBookings),
        _FooterLinkData('Contact Customer Service', route: AppRoutes.support),
        _FooterLinkData('Safety Resource Center', route: AppRoutes.support),
      ]),
      _FooterSectionData('Discover', const [
        _FooterLinkData('Loyalty program'),
        _FooterLinkData('Seasonal and holiday deals'),
        _FooterLinkData('Travel articles'),
        _FooterLinkData('Nuzul for Business'),
        _FooterLinkData('Traveller Review Awards'),
        _FooterLinkData('Car rental'),
        _FooterLinkData('Flight finder', route: AppRoutes.flights),
        _FooterLinkData('Restaurant reservations'),
        _FooterLinkData('Nuzul for Travel Agents'),
      ]),
      _FooterSectionData('Terms and settings', const [
        _FooterLinkData('Privacy Notice'),
        _FooterLinkData('Terms of Service'),
        _FooterLinkData('Accessibility Statement'),
        _FooterLinkData('Dispute resolution'),
        _FooterLinkData('Modern Slavery Statement'),
        _FooterLinkData('Human Rights Statement'),
      ]),
      _FooterSectionData('Partners', const [
        _FooterLinkData('Extranet login'),
        _FooterLinkData('Partner help'),
        _FooterLinkData('List your property'),
        _FooterLinkData('Become an affiliate'),
      ]),
      _FooterSectionData('About', const [
        _FooterLinkData('About Nuzul'),
        _FooterLinkData('How We Work'),
        _FooterLinkData('Sustainability'),
        _FooterLinkData('Press center'),
        _FooterLinkData('Careers'),
        _FooterLinkData('Investor relations'),
        _FooterLinkData('Corporate contact'),
        _FooterLinkData('Content guidelines and reporting'),
      ]),
    ];
  }

  void _showComingSoon(BuildContext context, bool isArabic) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(isArabic ? 'قريبًا' : 'Coming soon'),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  void _handleLinkTap(BuildContext context, bool isArabic, _FooterLinkData link) {
    if (link.route != null) {
      context.push(link.route!);
      return;
    }
    _showComingSoon(context, isArabic);
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final sections = _footerSections(isArabic);

    return Container(
      color: const Color(0xFFEAF5EC),
      margin: const EdgeInsets.only(top: AppSizes.lg),
      child: Column(
        children: [
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSizes.md,
              vertical: AppSizes.sm,
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: sections.map((section) {
                  return SizedBox(
                    width: _columnWidth,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: Text(
                            section.title,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                        ...section.links.map((link) {
                          return InkWell(
                            onTap: () => _handleLinkTap(context, isArabic, link),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 6),
                              child: Text(
                                link.label,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ),
                          );
                        }),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(AppSizes.md),
            child: Row(
              children: [
                const CurrencySelectorButton(),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(
              bottom: AppSizes.md,
              left: AppSizes.md,
              right: AppSizes.md,
            ),
            child: Text(
              isArabic
                  ? '© 2026 نزل. جميع الحقوق محفوظة.'
                  : '© 2026 Nuzul. All rights reserved.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textHint, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}

class _FooterSectionData {
  final String title;
  final List<_FooterLinkData> links;
  const _FooterSectionData(this.title, this.links);
}

/// رابط واحد جوه قسم الفوتر. لو [route] موجود، الضغط عليه بينقل فعليًا
/// لهذا المسار؛ لو null، الرابط لسه شكلي وبيعرض "قريبًا" بس.
class _FooterLinkData {
  final String label;
  final String? route;
  const _FooterLinkData(this.label, {this.route});
}