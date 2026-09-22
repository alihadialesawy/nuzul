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

  static List<_FooterSectionData> _footerSections(String languageCode) {
    if (languageCode == 'ar') {
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

    if (languageCode == 'tr') {
      return [
        _FooterSectionData('Destek', [
          _FooterLinkData('Seyahatlerinizi yönetin', route: AppRoutes.myBookings),
          _FooterLinkData('Müşteri hizmetleriyle iletişime geçin', route: AppRoutes.support),
          _FooterLinkData('Güvenlik kaynak merkezi', route: AppRoutes.support),
        ]),
        _FooterSectionData('Keşfet', const [
          _FooterLinkData('Sadakat programı'),
          _FooterLinkData('Sezonluk ve tatil fırsatları'),
          _FooterLinkData('Seyahat yazıları'),
          _FooterLinkData('İşletmeler için Nuzul'),
          _FooterLinkData('Gezgin değerlendirme ödülleri'),
          _FooterLinkData('Araç kiralama'),
          _FooterLinkData('Uçuş bulucu', route: AppRoutes.flights),
          _FooterLinkData('Restoran rezervasyonları'),
          _FooterLinkData('Seyahat acenteleri için Nuzul'),
        ]),
        _FooterSectionData('Şartlar ve ayarlar', const [
          _FooterLinkData('Gizlilik bildirimi'),
          _FooterLinkData('Hizmet şartları'),
          _FooterLinkData('Erişilebilirlik beyanı'),
          _FooterLinkData('Uyuşmazlık çözümü'),
          _FooterLinkData('Modern kölelik beyanı'),
          _FooterLinkData('İnsan hakları beyanı'),
        ]),
        _FooterSectionData('Ortaklar', const [
          _FooterLinkData('Ortak girişi'),
          _FooterLinkData('Ortak yardımı'),
          _FooterLinkData('Mülkünüzü listeleyin'),
          _FooterLinkData('Ortak olun'),
        ]),
        _FooterSectionData('Hakkında', const [
          _FooterLinkData('Nuzul hakkında'),
          _FooterLinkData('Nasıl çalışırız'),
          _FooterLinkData('Sürdürülebilirlik'),
          _FooterLinkData('Basın merkezi'),
          _FooterLinkData('Kariyer'),
          _FooterLinkData('Yatırımcı ilişkileri'),
          _FooterLinkData('Kurumsal iletişim'),
          _FooterLinkData('İçerik kuralları ve bildirim'),
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
          _FooterLinkData('Programa de fidelidad'),
          _FooterLinkData('Ofertas de temporada y vacaciones'),
          _FooterLinkData('Artículos de viaje'),
          _FooterLinkData('Nuzul para empresas'),
          _FooterLinkData('Premios de reseñas de viajeros'),
          _FooterLinkData('Alquiler de coches'),
          _FooterLinkData('Buscador de vuelos', route: AppRoutes.flights),
          _FooterLinkData('Reservas de restaurantes'),
          _FooterLinkData('Nuzul para agentes de viajes'),
        ]),
        _FooterSectionData('Términos y configuración', const [
          _FooterLinkData('Aviso de privacidad'),
          _FooterLinkData('Términos de servicio'),
          _FooterLinkData('Declaración de accesibilidad'),
          _FooterLinkData('Resolución de disputas'),
          _FooterLinkData('Declaración contra la esclavitud moderna'),
          _FooterLinkData('Declaración de derechos humanos'),
        ]),
        _FooterSectionData('Socios', const [
          _FooterLinkData('Acceso para socios'),
          _FooterLinkData('Ayuda para socios'),
          _FooterLinkData('Publica tu propiedad'),
          _FooterLinkData('Conviértete en afiliado'),
        ]),
        _FooterSectionData('Sobre Nuzul', const [
          _FooterLinkData('Sobre Nuzul'),
          _FooterLinkData('Cómo trabajamos'),
          _FooterLinkData('Sostenibilidad'),
          _FooterLinkData('Centro de prensa'),
          _FooterLinkData('Empleo'),
          _FooterLinkData('Relación con inversores'),
          _FooterLinkData('Contacto corporativo'),
          _FooterLinkData('Directrices de contenido y reportes'),
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
          _FooterLinkData('Program loyalitas'),
          _FooterLinkData('Penawaran musiman dan liburan'),
          _FooterLinkData('Artikel perjalanan'),
          _FooterLinkData('Nuzul untuk Bisnis'),
          _FooterLinkData('Penghargaan ulasan wisatawan'),
          _FooterLinkData('Sewa mobil'),
          _FooterLinkData('Pencari penerbangan', route: AppRoutes.flights),
          _FooterLinkData('Reservasi restoran'),
          _FooterLinkData('Nuzul untuk Agen Perjalanan'),
        ]),
        _FooterSectionData('Syarat dan pengaturan', const [
          _FooterLinkData('Pemberitahuan privasi'),
          _FooterLinkData('Syarat layanan'),
          _FooterLinkData('Pernyataan aksesibilitas'),
          _FooterLinkData('Penyelesaian sengketa'),
          _FooterLinkData('Pernyataan anti-perbudakan modern'),
          _FooterLinkData('Pernyataan hak asasi manusia'),
        ]),
        _FooterSectionData('Mitra', const [
          _FooterLinkData('Masuk mitra'),
          _FooterLinkData('Bantuan mitra'),
          _FooterLinkData('Daftarkan properti Anda'),
          _FooterLinkData('Menjadi afiliasi'),
        ]),
        _FooterSectionData('Tentang Nuzul', const [
          _FooterLinkData('Tentang Nuzul'),
          _FooterLinkData('Cara kami bekerja'),
          _FooterLinkData('Keberlanjutan'),
          _FooterLinkData('Pusat pers'),
          _FooterLinkData('Karier'),
          _FooterLinkData('Hubungan investor'),
          _FooterLinkData('Kontak korporat'),
          _FooterLinkData('Pedoman konten dan pelaporan'),
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
          _FooterLinkData('लॉयल्टी प्रोग्राम'),
          _FooterLinkData('मौसमी और छुट्टियों के ऑफ़र'),
          _FooterLinkData('यात्रा लेख'),
          _FooterLinkData('व्यवसायों के लिए Nuzul'),
          _FooterLinkData('यात्री समीक्षा पुरस्कार'),
          _FooterLinkData('कार किराए पर लें'),
          _FooterLinkData('उड़ान खोजक', route: AppRoutes.flights),
          _FooterLinkData('रेस्टोरेंट आरक्षण'),
          _FooterLinkData('यात्रा एजेंटों के लिए Nuzul'),
        ]),
        _FooterSectionData('शर्तें और सेटिंग्स', const [
          _FooterLinkData('गोपनीयता सूचना'),
          _FooterLinkData('सेवा की शर्तें'),
          _FooterLinkData('सुगम्यता विवरण'),
          _FooterLinkData('विवाद समाधान'),
          _FooterLinkData('आधुनिक दासता विवरण'),
          _FooterLinkData('मानवाधिकार विवरण'),
        ]),
        _FooterSectionData('साझेदार', const [
          _FooterLinkData('पार्टनर लॉगिन'),
          _FooterLinkData('पार्टनर सहायता'),
          _FooterLinkData('अपनी संपत्ति सूचीबद्ध करें'),
          _FooterLinkData('सहबद्ध बनें'),
        ]),
        _FooterSectionData('Nuzul के बारे में', const [
          _FooterLinkData('Nuzul के बारे में'),
          _FooterLinkData('हम कैसे काम करते हैं'),
          _FooterLinkData('स्थिरता'),
          _FooterLinkData('प्रेस केंद्र'),
          _FooterLinkData('करियर'),
          _FooterLinkData('निवेशक संबंध'),
          _FooterLinkData('कॉर्पोरेट संपर्क'),
          _FooterLinkData('सामग्री दिशानिर्देश और रिपोर्टिंग'),
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
          _FooterLinkData('লয়্যালটি প্রোগ্রাম'),
          _FooterLinkData('মৌসুমি ও ছুটির অফার'),
          _FooterLinkData('ভ্রমণ নিবন্ধ'),
          _FooterLinkData('ব্যবসার জন্য Nuzul'),
          _FooterLinkData('ভ্রমণকারী পর্যালোচনা পুরস্কার'),
          _FooterLinkData('গাড়ি ভাড়া'),
          _FooterLinkData('ফ্লাইট অনুসন্ধানকারী', route: AppRoutes.flights),
          _FooterLinkData('রেস্টুরেন্ট রিজার্ভেশন'),
          _FooterLinkData('ভ্রমণ এজেন্টদের জন্য Nuzul'),
        ]),
        _FooterSectionData('শর্তাবলী ও সেটিংস', const [
          _FooterLinkData('গোপনীয়তা নোটিশ'),
          _FooterLinkData('সেবার শর্তাবলী'),
          _FooterLinkData('অ্যাক্সেসিবিলিটি বিবৃতি'),
          _FooterLinkData('বিরোধ নিষ্পত্তি'),
          _FooterLinkData('আধুনিক দাসত্ব বিরোধী বিবৃতি'),
          _FooterLinkData('মানবাধিকার বিবৃতি'),
        ]),
        _FooterSectionData('অংশীদার', const [
          _FooterLinkData('পার্টনার লগইন'),
          _FooterLinkData('পার্টনার সহায়তা'),
          _FooterLinkData('আপনার সম্পত্তি তালিকাভুক্ত করুন'),
          _FooterLinkData('অ্যাফিলিয়েট হন'),
        ]),
        _FooterSectionData('Nuzul সম্পর্কে', const [
          _FooterLinkData('Nuzul সম্পর্কে'),
          _FooterLinkData('আমরা কীভাবে কাজ করি'),
          _FooterLinkData('স্থায়িত্ব'),
          _FooterLinkData('প্রেস সেন্টার'),
          _FooterLinkData('ক্যারিয়ার'),
          _FooterLinkData('বিনিয়োগকারী সম্পর্ক'),
          _FooterLinkData('কর্পোরেট যোগাযোগ'),
          _FooterLinkData('কন্টেন্ট নির্দেশিকা ও রিপোর্টিং'),
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
          _FooterLinkData('Programme de fidélité'),
          _FooterLinkData('Offres saisonnières et de vacances'),
          _FooterLinkData('Articles de voyage'),
          _FooterLinkData('Nuzul pour les entreprises'),
          _FooterLinkData('Prix des avis voyageurs'),
          _FooterLinkData('Location de voitures'),
          _FooterLinkData('Recherche de vols', route: AppRoutes.flights),
          _FooterLinkData('Réservations de restaurants'),
          _FooterLinkData('Nuzul pour les agents de voyage'),
        ]),
        _FooterSectionData('Conditions et paramètres', const [
          _FooterLinkData('Avis de confidentialité'),
          _FooterLinkData("Conditions d'utilisation"),
          _FooterLinkData("Déclaration d'accessibilité"),
          _FooterLinkData('Résolution des litiges'),
          _FooterLinkData("Déclaration contre l'esclavage moderne"),
          _FooterLinkData('Déclaration des droits humains'),
        ]),
        _FooterSectionData('Partenaires', const [
          _FooterLinkData('Connexion partenaire'),
          _FooterLinkData('Aide aux partenaires'),
          _FooterLinkData('Référencer votre établissement'),
          _FooterLinkData('Devenir affilié'),
        ]),
        _FooterSectionData('À propos de Nuzul', const [
          _FooterLinkData('À propos de Nuzul'),
          _FooterLinkData('Comment nous travaillons'),
          _FooterLinkData('Durabilité'),
          _FooterLinkData('Centre de presse'),
          _FooterLinkData('Carrières'),
          _FooterLinkData('Relations investisseurs'),
          _FooterLinkData('Contact entreprise'),
          _FooterLinkData('Directives de contenu et signalement'),
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
          _FooterLinkData('لائلٹی پروگرام'),
          _FooterLinkData('موسمی اور تعطیلات کے آفرز'),
          _FooterLinkData('سفری مضامین'),
          _FooterLinkData('کاروبار کے لیے Nuzul'),
          _FooterLinkData('مسافر جائزہ ایوارڈز'),
          _FooterLinkData('کار کرایہ پر لیں'),
          _FooterLinkData('پرواز تلاش کنندہ', route: AppRoutes.flights),
          _FooterLinkData('ریسٹورنٹ ریزرویشن'),
          _FooterLinkData('سفری ایجنٹوں کے لیے Nuzul'),
        ]),
        _FooterSectionData('شرائط اور ترتیبات', const [
          _FooterLinkData('پرائیویسی نوٹس'),
          _FooterLinkData('سروس کی شرائط'),
          _FooterLinkData('رسائی کا بیان'),
          _FooterLinkData('تنازعات کا حل'),
          _FooterLinkData('جدید غلامی کا بیان'),
          _FooterLinkData('انسانی حقوق کا بیان'),
        ]),
        _FooterSectionData('پارٹنرز', const [
          _FooterLinkData('پارٹنر لاگ ان'),
          _FooterLinkData('پارٹنر مدد'),
          _FooterLinkData('اپنی جائیداد درج کریں'),
          _FooterLinkData('ملحق بنیں'),
        ]),
        _FooterSectionData('Nuzul کے بارے میں', const [
          _FooterLinkData('Nuzul کے بارے میں'),
          _FooterLinkData('ہم کیسے کام کرتے ہیں'),
          _FooterLinkData('پائیداری'),
          _FooterLinkData('پریس سینٹر'),
          _FooterLinkData('کیریئر'),
          _FooterLinkData('سرمایہ کاروں کے تعلقات'),
          _FooterLinkData('کارپوریٹ رابطہ'),
          _FooterLinkData('مواد کے رہنما اصول اور رپورٹنگ'),
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
              switch (languageCode) {
                'ar' => '© 2026 نزل. جميع الحقوق محفوظة.',
                'tr' => '© 2026 Nuzul. Tüm hakları saklıdır.',
                'es' => '© 2026 Nuzul. Todos los derechos reservados.',
                'id' => '© 2026 Nuzul. Semua hak dilindungi.',
                'hi' => '© 2026 Nuzul. सर्वाधिकार सुरक्षित।',
                'ur' => '© 2026 Nuzul. جملہ حقوق محفوظ ہیں۔',
                'fr' => '© 2026 Nuzul. Tous droits réservés.',
                'bn' => '© ২০২৬ Nuzul. সর্বস্বত্ব সংরক্ষিত।',
                _ => '© 2026 Nuzul. All rights reserved.',
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