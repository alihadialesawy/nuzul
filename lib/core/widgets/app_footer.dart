import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app.dart';
import '../constants/app_colors.dart';
import '../constants/app_sizes.dart';
import 'currency_selector_button.dart';

/// فوتر مشترك يُضاف في نهاية كل صفحة رئيسية بالتطبيق. كل قسم
/// (Support/Discover/Terms/About) عمود مستقل بجانب الباقي،
/// وكل روابط القسم ظاهرة تحت عنوانه بشكل دائم من غير حاجة للضغط.
/// روابط قسم "الدعم" فقط مفعّلة فعليًا وتنقل لصفحات حقيقية؛ باقي الروابط
/// لسه شكلية (تعرض "قريبًا") إلى أن تُبنى صفحات فعلية لها لاحقًا.
/// ملحوظة: قسم "Partners" اتشال بالكامل، وشوية روابط اتشالت من باقي
/// الأقسام (مرحلة أولى من تنظيف الفوتر) لأنها إما مش منطبقة على نموذج
/// العمل الحالي (وسيط/aggregator، مش مالك فنادق/أسطول سيارات)، أو
/// سابقة لأوانها (Business/Travel Agents/Investor relations/Press
/// center)، أو خارج نطاق النشاط (حجوزات مطاعم).
///
/// روابط التواصل الاجتماعي (Facebook/Instagram/TikTok/YouTube) تظهر في الشريط السفلي
/// بجانب زر العملة، وتفتح حساب Flynoom الرسمي في تبويب جديد على الويب،
/// أو داخل تطبيق فيسبوك/إنستغرام/تيك توك/يوتيوب على الجوال إن كان مثبتًا.
class AppFooter extends StatelessWidget {
  const AppFooter({super.key});

  static const double _columnWidth = 180;

  /// الحسابات الرسمية — نفس اسم المستخدم على المنصتين.
  static const String facebookUrl = 'https://www.facebook.com/flynoom.booking';
  static const String instagramUrl = 'https://www.instagram.com/flynoom.booking';
  static const String tiktokUrl = 'https://www.tiktok.com/@flynoom';
  static const String youtubeUrl =
      'https://www.youtube.com/channel/UCfa_VHdzyOsXlKmj4-w5VQg';

  static List<_FooterSectionData> _footerSections(String languageCode) {
    if (languageCode == 'ar') {
      return [
        _FooterSectionData('الدعم', [
          _FooterLinkData('إدارة رحلاتك', route: AppRoutes.myBookings),
          _FooterLinkData('التواصل مع خدمة العملاء', route: AppRoutes.support),
          _FooterLinkData('مركز مصادر الأمان', route: AppRoutes.support),
        ]),
        _FooterSectionData('استكشف', const [
          _FooterLinkData('برنامج الولاء', route: AppRoutes.myCoins),
          _FooterLinkData('عروض موسمية وعطلات', route: AppRoutes.seasonalDeals),
          _FooterLinkData('مقالات سفر', route: AppRoutes.travelArticles),
          _FooterLinkData('محرك بحث الرحلات', route: AppRoutes.flights),
        ]),
        _FooterSectionData('الشروط والإعدادات', [
          _FooterLinkData('إشعار الخصوصية', route: AppRoutes.privacyNotice),
          _FooterLinkData('شروط الخدمة', route: AppRoutes.termsOfService),
          _FooterLinkData('بيان إمكانية الوصول', route: AppRoutes.accessibilityStatement),
          _FooterLinkData('حل النزاعات', route: AppRoutes.disputeResolution),
        ]),
        _FooterSectionData('عن Flynoom', [
          _FooterLinkData('عن Flynoom', route: AppRoutes.about),
          _FooterLinkData('كيف نعمل', route: AppRoutes.howWeWork),
          _FooterLinkData('الوظائف', route: AppRoutes.careers),
          _FooterLinkData('إرشادات المحتوى والتبليغ', route: AppRoutes.contentGuidelines),
        ]),
      ];
    }

    if (languageCode == 'tr') {
      return [
        _FooterSectionData('Destek', [
          _FooterLinkData('Seyahatlerinizi yönetin', route: AppRoutes.myBookings),
          _FooterLinkData('Müşteri hizmetleriyle iletişime geçin', route: AppRoutes.support),
          _FooterLinkData('Güvenlik kaynak merkezi', route: AppRoutes.support),
        ]),
        _FooterSectionData('Keşfet', const [
          _FooterLinkData('Sadakat programı', route: AppRoutes.myCoins),
          _FooterLinkData('Sezonluk ve tatil fırsatları', route: AppRoutes.seasonalDeals),
          _FooterLinkData('Seyahat yazıları', route: AppRoutes.travelArticles),
          _FooterLinkData('Uçuş bulucu', route: AppRoutes.flights),
        ]),
        _FooterSectionData('Şartlar ve ayarlar', [
          _FooterLinkData('Gizlilik bildirimi', route: AppRoutes.privacyNotice),
          _FooterLinkData('Hizmet şartları', route: AppRoutes.termsOfService),
          _FooterLinkData('Erişilebilirlik beyanı', route: AppRoutes.accessibilityStatement),
          _FooterLinkData('Uyuşmazlık çözümü', route: AppRoutes.disputeResolution),
        ]),
        _FooterSectionData('Hakkında', [
          _FooterLinkData('Flynoom hakkında', route: AppRoutes.about),
          _FooterLinkData('Nasıl çalışırız', route: AppRoutes.howWeWork),
          _FooterLinkData('Kariyer', route: AppRoutes.careers),
          _FooterLinkData('İçerik kuralları ve bildirim', route: AppRoutes.contentGuidelines),
        ]),
      ];
    }

    if (languageCode == 'es') {
      return [
        _FooterSectionData('Soporte', [
          _FooterLinkData('Gestiona tus viajes', route: AppRoutes.myBookings),
          _FooterLinkData('Contactar con servicio al cliente', route: AppRoutes.support),
          _FooterLinkData('Centro de recursos de seguridad', route: AppRoutes.support),
        ]),
        _FooterSectionData('Descubre', const [
          _FooterLinkData('Programa de fidelidad', route: AppRoutes.myCoins),
          _FooterLinkData('Ofertas de temporada y vacaciones', route: AppRoutes.seasonalDeals),
          _FooterLinkData('Artículos de viaje', route: AppRoutes.travelArticles),
          _FooterLinkData('Buscador de vuelos', route: AppRoutes.flights),
        ]),
        _FooterSectionData('Términos y configuración', [
          _FooterLinkData('Aviso de privacidad', route: AppRoutes.privacyNotice),
          _FooterLinkData('Términos de servicio', route: AppRoutes.termsOfService),
          _FooterLinkData('Declaración de accesibilidad', route: AppRoutes.accessibilityStatement),
          _FooterLinkData('Resolución de disputas', route: AppRoutes.disputeResolution),
        ]),
        _FooterSectionData('Sobre Flynoom', [
          _FooterLinkData('Sobre Flynoom', route: AppRoutes.about),
          _FooterLinkData('Cómo trabajamos', route: AppRoutes.howWeWork),
          _FooterLinkData('Empleo', route: AppRoutes.careers),
          _FooterLinkData('Directrices de contenido y reportes', route: AppRoutes.contentGuidelines),
        ]),
      ];
    }

    if (languageCode == 'id') {
      return [
        _FooterSectionData('Dukungan', [
          _FooterLinkData('Kelola perjalanan Anda', route: AppRoutes.myBookings),
          _FooterLinkData('Hubungi Layanan Pelanggan', route: AppRoutes.support),
          _FooterLinkData('Pusat sumber daya keamanan', route: AppRoutes.support),
        ]),
        _FooterSectionData('Jelajahi', const [
          _FooterLinkData('Program loyalitas', route: AppRoutes.myCoins),
          _FooterLinkData('Penawaran musiman dan liburan', route: AppRoutes.seasonalDeals),
          _FooterLinkData('Artikel perjalanan', route: AppRoutes.travelArticles),
          _FooterLinkData('Pencari penerbangan', route: AppRoutes.flights),
        ]),
        _FooterSectionData('Syarat dan pengaturan', [
          _FooterLinkData('Pemberitahuan privasi', route: AppRoutes.privacyNotice),
          _FooterLinkData('Syarat layanan', route: AppRoutes.termsOfService),
          _FooterLinkData('Pernyataan aksesibilitas', route: AppRoutes.accessibilityStatement),
          _FooterLinkData('Penyelesaian sengketa', route: AppRoutes.disputeResolution),
        ]),
        _FooterSectionData('Tentang Flynoom', [
          _FooterLinkData('Tentang Flynoom', route: AppRoutes.about),
          _FooterLinkData('Cara kami bekerja', route: AppRoutes.howWeWork),
          _FooterLinkData('Karier', route: AppRoutes.careers),
          _FooterLinkData('Pedoman konten dan pelaporan', route: AppRoutes.contentGuidelines),
        ]),
      ];
    }

    if (languageCode == 'hi') {
      return [
        _FooterSectionData('सहायता', [
          _FooterLinkData('अपनी यात्राएं प्रबंधित करें', route: AppRoutes.myBookings),
          _FooterLinkData('ग्राहक सेवा से संपर्क करें', route: AppRoutes.support),
          _FooterLinkData('सुरक्षा संसाधन केंद्र', route: AppRoutes.support),
        ]),
        _FooterSectionData('खोजें', const [
          _FooterLinkData('लॉयल्टी प्रोग्राम', route: AppRoutes.myCoins),
          _FooterLinkData('मौसमी और छुट्टियों के ऑफ़र', route: AppRoutes.seasonalDeals),
          _FooterLinkData('यात्रा लेख', route: AppRoutes.travelArticles),
          _FooterLinkData('उड़ान खोजक', route: AppRoutes.flights),
        ]),
        _FooterSectionData('शर्तें और सेटिंग्स', [
          _FooterLinkData('गोपनीयता सूचना', route: AppRoutes.privacyNotice),
          _FooterLinkData('सेवा की शर्तें', route: AppRoutes.termsOfService),
          _FooterLinkData('सुगम्यता विवरण', route: AppRoutes.accessibilityStatement),
          _FooterLinkData('विवाद समाधान', route: AppRoutes.disputeResolution),
        ]),
        _FooterSectionData('Flynoom के बारे में', [
          _FooterLinkData('Flynoom के बारे में', route: AppRoutes.about),
          _FooterLinkData('हम कैसे काम करते हैं', route: AppRoutes.howWeWork),
          _FooterLinkData('करियर', route: AppRoutes.careers),
          _FooterLinkData('सामग्री दिशानिर्देश और रिपोर्टिंग', route: AppRoutes.contentGuidelines),
        ]),
      ];
    }

    if (languageCode == 'bn') {
      return [
        _FooterSectionData('সহায়তা', [
          _FooterLinkData('আপনার ভ্রমণ পরিচালনা করুন', route: AppRoutes.myBookings),
          _FooterLinkData('গ্রাহক সেবার সাথে যোগাযোগ করুন', route: AppRoutes.support),
          _FooterLinkData('নিরাপত্তা রিসোর্স সেন্টার', route: AppRoutes.support),
        ]),
        _FooterSectionData('আবিষ্কার করুন', const [
          _FooterLinkData('লয়্যালটি প্রোগ্রাম', route: AppRoutes.myCoins),
          _FooterLinkData('মৌসুমি ও ছুটির অফার', route: AppRoutes.seasonalDeals),
          _FooterLinkData('ভ্রমণ নিবন্ধ', route: AppRoutes.travelArticles),
          _FooterLinkData('ফ্লাইট অনুসন্ধানকারী', route: AppRoutes.flights),
        ]),
        _FooterSectionData('শর্তাবলী ও সেটিংস', [
          _FooterLinkData('গোপনীয়তা নোটিশ', route: AppRoutes.privacyNotice),
          _FooterLinkData('সেবার শর্তাবলী', route: AppRoutes.termsOfService),
          _FooterLinkData('অ্যাক্সেসিবিলিটি বিবৃতি', route: AppRoutes.accessibilityStatement),
          _FooterLinkData('বিরোধ নিষ্পত্তি', route: AppRoutes.disputeResolution),
        ]),
        _FooterSectionData('Flynoom সম্পর্কে', [
          _FooterLinkData('Flynoom সম্পর্কে', route: AppRoutes.about),
          _FooterLinkData('আমরা কীভাবে কাজ করি', route: AppRoutes.howWeWork),
          _FooterLinkData('ক্যারিয়ার', route: AppRoutes.careers),
          _FooterLinkData('কন্টেন্ট নির্দেশিকা ও রিপোর্টিং', route: AppRoutes.contentGuidelines),
        ]),
      ];
    }

    if (languageCode == 'fr') {
      return [
        _FooterSectionData('Assistance', [
          _FooterLinkData('Gérer vos voyages', route: AppRoutes.myBookings),
          _FooterLinkData('Contacter le service client', route: AppRoutes.support),
          _FooterLinkData('Centre de ressources de sécurité', route: AppRoutes.support),
        ]),
        _FooterSectionData('Découvrir', const [
          _FooterLinkData('Programme de fidélité', route: AppRoutes.myCoins),
          _FooterLinkData('Offres saisonnières et de vacances', route: AppRoutes.seasonalDeals),
          _FooterLinkData('Articles de voyage', route: AppRoutes.travelArticles),
          _FooterLinkData('Recherche de vols', route: AppRoutes.flights),
        ]),
        _FooterSectionData('Conditions et paramètres', [
          _FooterLinkData('Avis de confidentialité', route: AppRoutes.privacyNotice),
          _FooterLinkData("Conditions d'utilisation", route: AppRoutes.termsOfService),
          _FooterLinkData("Déclaration d'accessibilité", route: AppRoutes.accessibilityStatement),
          _FooterLinkData('Résolution des litiges', route: AppRoutes.disputeResolution),
        ]),
        _FooterSectionData('À propos de Flynoom', [
          _FooterLinkData('À propos de Flynoom', route: AppRoutes.about),
          _FooterLinkData('Comment nous travaillons', route: AppRoutes.howWeWork),
          _FooterLinkData('Carrières', route: AppRoutes.careers),
          _FooterLinkData('Directives de contenu et signalement', route: AppRoutes.contentGuidelines),
        ]),
      ];
    }

    if (languageCode == 'ur') {
      return [
        _FooterSectionData('مدد', [
          _FooterLinkData('اپنے سفر کا انتظام کریں', route: AppRoutes.myBookings),
          _FooterLinkData('کسٹمر سروس سے رابطہ کریں', route: AppRoutes.support),
          _FooterLinkData('حفاظتی وسائل کا مرکز', route: AppRoutes.support),
        ]),
        _FooterSectionData('دریافت کریں', const [
          _FooterLinkData('لائلٹی پروگرام', route: AppRoutes.myCoins),
          _FooterLinkData('موسمی اور تعطیلات کے آفرز', route: AppRoutes.seasonalDeals),
          _FooterLinkData('سفری مضامین', route: AppRoutes.travelArticles),
          _FooterLinkData('پرواز تلاش کنندہ', route: AppRoutes.flights),
        ]),
        _FooterSectionData('شرائط اور ترتیبات', [
          _FooterLinkData('پرائیویسی نوٹس', route: AppRoutes.privacyNotice),
          _FooterLinkData('سروس کی شرائط', route: AppRoutes.termsOfService),
          _FooterLinkData('رسائی کا بیان', route: AppRoutes.accessibilityStatement),
          _FooterLinkData('تنازعات کا حل', route: AppRoutes.disputeResolution),
        ]),
        _FooterSectionData('Flynoom کے بارے میں', [
          _FooterLinkData('Flynoom کے بارے میں', route: AppRoutes.about),
          _FooterLinkData('ہم کیسے کام کرتے ہیں', route: AppRoutes.howWeWork),
          _FooterLinkData('کیریئر', route: AppRoutes.careers),
          _FooterLinkData('مواد کے رہنما اصول اور رپورٹنگ', route: AppRoutes.contentGuidelines),
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
        _FooterLinkData('Loyalty program', route: AppRoutes.myCoins),
        _FooterLinkData('Seasonal and holiday deals', route: AppRoutes.seasonalDeals),
        _FooterLinkData('Travel articles', route: AppRoutes.travelArticles),
        _FooterLinkData('Flight finder', route: AppRoutes.flights),
      ]),
      _FooterSectionData('Terms and settings', [
        _FooterLinkData('Privacy Notice', route: AppRoutes.privacyNotice),
        _FooterLinkData('Terms of Service', route: AppRoutes.termsOfService),
        _FooterLinkData('Accessibility Statement', route: AppRoutes.accessibilityStatement),
        _FooterLinkData('Dispute resolution', route: AppRoutes.disputeResolution),
      ]),
      _FooterSectionData('About', [
        _FooterLinkData('About Flynoom', route: AppRoutes.about),
        _FooterLinkData('How We Work', route: AppRoutes.howWeWork),
        _FooterLinkData('Careers', route: AppRoutes.careers),
        _FooterLinkData('Content guidelines and reporting', route: AppRoutes.contentGuidelines),
      ]),
    ];
  }

  static String _followUsLabel(String languageCode) {
    return switch (languageCode) {
      'ar' => 'تابعنا',
      'tr' => 'Bizi takip edin',
      'es' => 'Síguenos',
      'id' => 'Ikuti kami',
      'hi' => 'हमें फ़ॉलो करें',
      'ur' => 'ہمیں فالو کریں',
      'fr' => 'Suivez-nous',
      'bn' => 'আমাদের অনুসরণ করুন',
      _ => 'Follow us',
    };
  }

  void _showComingSoon(BuildContext context, String languageCode) {
    final message = switch (languageCode) {
      'ar' => 'قريبًا',
      'tr' => 'Yakında',
      'es' => 'Próximamente',
      'id' => 'Segera hadir',
      'hi' => 'जल्द आ रहा है',
      'ur' => 'جلد آ رہا ہے',
      'fr' => 'Bientôt disponible',
      'bn' => 'শীঘ্রই আসছে',
      _ => 'Coming soon',
    };
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  void _handleLinkTap(BuildContext context, String languageCode, _FooterLinkData link) {
    if (link.route != null) {
      context.push(link.route!);
      return;
    }
    _showComingSoon(context, languageCode);
  }

  @override
  Widget build(BuildContext context) {
    final languageCode = Localizations.localeOf(context).languageCode;
    final sections = _footerSections(languageCode);

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
                            onTap: () => _handleLinkTap(context, languageCode, link),
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
            // Wrap بدل Row: على الشاشات الضيقة ينزل قسم "تابعنا" لسطر جديد
            // بدل ما يحصل overflow.
            child: Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: AppSizes.md,
              runSpacing: AppSizes.sm,
              children: [
                const CurrencySelectorButton(footerStyle: true),
                _SocialLinks(label: _followUsLabel(languageCode)),
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
              switch (languageCode) {
                'ar' => '© 2026 Flynoom. جميع الحقوق محفوظة.',
                'tr' => '© 2026 Flynoom. Tüm hakları saklıdır.',
                'es' => '© 2026 Flynoom. Todos los derechos reservados.',
                'id' => '© 2026 Flynoom. Semua hak dilindungi.',
                'hi' => '© 2026 Flynoom. सर्वाधिकार सुरक्षित।',
                'ur' => '© 2026 Flynoom. جملہ حقوق محفوظ ہیں۔',
                'fr' => '© 2026 Flynoom. Tous droits réservés.',
                'bn' => '© ২০২৬ Flynoom. সর্বস্বত্ব সংরক্ষিত।',
                _ => '© 2026 Flynoom. All rights reserved.',
              },
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textHint, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}

/// "تابعنا" + أيقونات فيسبوك وإنستغرام وتيك توك ويوتيوب بألوانها الرسمية.
class _SocialLinks extends StatelessWidget {
  final String label;
  const _SocialLinks({required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(width: AppSizes.md),
        const _SocialIconButton(
          tooltip: 'Facebook',
          url: AppFooter.facebookUrl,
          kind: _SocialKind.facebook,
        ),
        const SizedBox(width: AppSizes.sm),
        const _SocialIconButton(
          tooltip: 'Instagram',
          url: AppFooter.instagramUrl,
          kind: _SocialKind.instagram,
        ),
        const SizedBox(width: AppSizes.sm),
        const _SocialIconButton(
          tooltip: 'TikTok',
          url: AppFooter.tiktokUrl,
          kind: _SocialKind.tiktok,
        ),
        const SizedBox(width: AppSizes.sm),
        const _SocialIconButton(
          tooltip: 'YouTube',
          url: AppFooter.youtubeUrl,
          kind: _SocialKind.youtube,
        ),
      ],
    );
  }
}

enum _SocialKind { facebook, instagram, tiktok, youtube }

class _SocialIconButton extends StatefulWidget {
  final String tooltip;
  final String url;
  final _SocialKind kind;

  const _SocialIconButton({
    required this.tooltip,
    required this.url,
    required this.kind,
  });

  @override
  State<_SocialIconButton> createState() => _SocialIconButtonState();
}

class _SocialIconButtonState extends State<_SocialIconButton> {
  static const double _badgeSize = 40;
  static const Color _facebookBlue = Color(0xFF1877F2);
  static const List<Color> _instagramGradient = [
    Color(0xFFFEDA75),
    Color(0xFFFA7E1E),
    Color(0xFFD62976),
    Color(0xFF962FBF),
    Color(0xFF4F5BD5),
  ];

  bool _hovered = false;

  Future<void> _open() async {
    final uri = Uri.parse(widget.url);
    try {
      // externalApplication: على الويب يفتح تبويب جديد، وعلى الجوال يفتح
      // تطبيق فيسبوك/إنستغرام مباشرة إن كان مثبتًا، وإلا المتصفح.
      await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
        webOnlyWindowName: '_blank',
      );
    } catch (e) {
      debugPrint('Could not open ${widget.url}: $e');
    }
  }

  Widget _buildBadge() {
    switch (widget.kind) {
      case _SocialKind.facebook:
        return Container(
          width: _badgeSize,
          height: _badgeSize,
          decoration: const BoxDecoration(
            color: _facebookBlue,
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: const Text(
            'f',
            style: TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w900,
              height: 1.15,
            ),
          ),
        );
      case _SocialKind.instagram:
        return Container(
          width: _badgeSize,
          height: _badgeSize,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(_badgeSize * 0.28),
            gradient: const LinearGradient(
              begin: Alignment.bottomLeft,
              end: Alignment.topRight,
              colors: _instagramGradient,
            ),
          ),
          alignment: Alignment.center,
          child: CustomPaint(
            size: const Size.square(_badgeSize * 0.62),
            painter: _InstagramGlyphPainter(Colors.white),
          ),
        );
      case _SocialKind.tiktok:
        return Container(
          width: _badgeSize,
          height: _badgeSize,
          decoration: const BoxDecoration(
            color: Colors.black,
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: CustomPaint(
            size: const Size.square(_badgeSize * 0.6),
            painter: _TikTokGlyphPainter(),
          ),
        );
      case _SocialKind.youtube:
        return Container(
          width: _badgeSize,
          height: _badgeSize,
          decoration: const BoxDecoration(
            color: Color(0xFFFF0000),
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: const Icon(
            Icons.play_arrow_rounded,
            color: Colors.white,
            size: _badgeSize * 0.72,
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: widget.tooltip,
      child: Semantics(
        link: true,
        label: widget.tooltip,
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          onEnter: (_) => setState(() => _hovered = true),
          onExit: (_) => setState(() => _hovered = false),
          child: GestureDetector(
            onTap: _open,
            child: AnimatedScale(
              scale: _hovered ? 1.1 : 1.0,
              duration: const Duration(milliseconds: 150),
              child: _buildBadge(),
            ),
          ),
        ),
      ),
    );
  }
}

/// رسم شعار إنستغرام البسيط (مربع مستدير + دائرة + نقطة) بدون الحاجة
/// لمكتبة أيقونات خارجية — Material Icons ما فيها أيقونة إنستغرام.
class _InstagramGlyphPainter extends CustomPainter {
  final Color color;
  _InstagramGlyphPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width;
    final stroke = s * 0.1;
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke;

    final inset = stroke / 2;
    final rect = Rect.fromLTWH(inset, inset, s - inset * 2, s - inset * 2);
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, Radius.circular(s * 0.28)),
      paint,
    );

    canvas.drawCircle(Offset(s / 2, s / 2), s * 0.22, paint);

    canvas.drawCircle(
      Offset(s * 0.76, s * 0.24),
      s * 0.07,
      Paint()..color = color,
    );
  }

  @override
  bool shouldRepaint(covariant _InstagramGlyphPainter oldDelegate) =>
      oldDelegate.color != color;
}

/// رسم شعار تيك توك (نوتة موسيقية بظلال سماوية وحمراء) بدون مكتبة خارجية.
class _TikTokGlyphPainter extends CustomPainter {
  static const Color _cyan = Color(0xFF25F4EE);
  static const Color _red = Color(0xFFFE2C55);

  void _drawNote(Canvas canvas, double s, Offset shift, Color color) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = s * 0.13
      ..strokeCap = StrokeCap.round;

    canvas.save();
    canvas.translate(shift.dx, shift.dy);

    // الحلقة السفلية
    canvas.drawCircle(Offset(s * 0.40, s * 0.68), s * 0.15, paint);

    // العمود
    canvas.drawLine(
      Offset(s * 0.55, s * 0.68),
      Offset(s * 0.55, s * 0.12),
      paint,
    );

    // الذيل العلوي
    final flag = Path()
      ..moveTo(s * 0.55, s * 0.12)
      ..quadraticBezierTo(s * 0.60, s * 0.34, s * 0.82, s * 0.36);
    canvas.drawPath(flag, paint);

    canvas.restore();
  }

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width;
    final d = s * 0.045;
    _drawNote(canvas, s, Offset(-d, -d), _cyan);
    _drawNote(canvas, s, Offset(d, d), _red);
    _drawNote(canvas, s, Offset.zero, Colors.white);
  }

  @override
  bool shouldRepaint(covariant _TikTokGlyphPainter oldDelegate) => false;
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