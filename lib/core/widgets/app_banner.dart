import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app.dart';
import '../config/features.dart';
import '../constants/app_colors.dart';
import '../constants/app_sizes.dart';
import '../providers/locale_provider.dart';
import 'currency_selector_button.dart';
import '../../presentation/auth/controllers/auth_controller.dart';
import '../../presentation/auth/controllers/admin_controller.dart';

/// يختار النص المناسب حسب اللغة الحالية (عربي/إنجليزي/إسباني).
String appBannerText(
    BuildContext context, {
      required String ar,
      required String en,
      required String es,
    }) {
  switch (Localizations.localeOf(context).languageCode) {
    case 'ar':
      return ar;
    case 'es':
      return es;
    default:
      return en;
  }
}

/// الجملة التسويقية اللي بتظهر فوق صورة البانر، بتتغيّر حسب التبويب
/// النشط (إقامة/طيران/طيران+فندق/تأجير سيارات) ومترجمة لكل اللغات
/// التسع المدعومة في التطبيق.
String _bannerTagline(BuildContext context, String? activeTab, [String? assetVariant]) {
  final languageCode = Localizations.localeOf(context).languageCode;

  String pick({
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
    switch (languageCode) {
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

  switch (activeTab) {
    case 'flights':
      return pick(
        ar: 'نحلّق بك نحو آفاق جديدة',
        en: 'We soar with you toward new horizons',
        es: 'Volamos contigo hacia nuevos horizontes',
        tr: 'Sizinle birlikte yeni ufuklara doğru yükseliyoruz',
        id: 'Kami terbang bersama Anda menuju cakrawala baru',
        hi: 'हम आपके साथ नए क्षितिजों की ओर उड़ान भरते हैं',
        ur: 'ہم آپ کے ساتھ نئے افق کی طرف پرواز کرتے ہیں',
        fr: 'Nous nous envolons avec vous vers de nouveaux horizons',
        bn: 'আমরা আপনার সাথে নতুন দিগন্তের দিকে উড়ে যাই',
      );
    case 'flightHotel':
      return pick(
        ar: 'رحلتك وإقامتك، في احتضان واحد',
        en: 'Your journey and your stay, seamlessly together',
        es: 'Tu viaje y tu estancia, unidos a la perfección',
        tr: 'Yolculuğunuz ve konaklamanız, kusursuz bir uyum içinde',
        id: 'Perjalanan dan menginap Anda, menyatu dengan sempurna',
        hi: 'आपकी यात्रा और ठहराव, एक साथ पूर्ण सामंजस्य में',
        ur: 'آپ کا سفر اور قیام، ایک ساتھ کامل ہم آہنگی میں',
        fr: 'Votre voyage et votre séjour, réunis en toute harmonie',
        bn: 'আপনার যাত্রা ও অবস্থান, নিখুঁত সমন্বয়ে একত্রিত',
      );
    case 'carRental':
      return pick(
        ar: 'طريقك يبدأ من هنا',
        en: 'Your road begins here',
        es: 'Tu camino comienza aquí',
        tr: 'Yolunuz burada başlıyor',
        id: 'Perjalanan Anda dimulai di sini',
        hi: 'आपकी राह यहीं से शुरू होती है',
        ur: 'آپ کا سفر یہیں سے شروع ہوتا ہے',
        fr: 'Votre route commence ici',
        bn: 'আপনার পথ এখান থেকেই শুরু',
      );
    case 'umrah':
    // عند اختيار مكة أو المدينة في تبويب العمرة يتغيّر النص مع صورة البانر.
      if (assetVariant == 'makkah') {
        return pick(
          ar: 'في رحاب البيت العتيق، بجوار المسجد الحرام',
          en: 'In the presence of the Ancient House, near the Sacred Mosque',
          es: 'Junto a la Casa Antigua, cerca de la Mezquita Sagrada',
          tr: "Beyt-i Atik'in huzurunda, Mescid-i Haram'ın yakınında",
          id: 'Di sisi Baitul Atiq, dekat Masjidil Haram',
          hi: 'बैतुल अतीक़ के सान्निध्य में, मस्जिद अल-हराम के निकट',
          ur: 'بیتِ عتیق کے سائے میں، مسجد الحرام کے قریب',
          fr: 'Auprès de la Maison antique, près de la Mosquée sacrée',
          bn: 'বাইতুল আতিকের সান্নিধ্যে, মসজিদুল হারামের কাছে',
        );
      }
      if (assetVariant == 'madinah') {
        return pick(
          ar: 'في طيبة الطيبة، بجوار المسجد النبوي الشريف',
          en: "In blessed Madinah, near the Prophet's Mosque",
          es: 'En la bendita Medina, cerca de la Mezquita del Profeta',
          tr: "Mübarek Medine'de, Mescid-i Nebevi'nin yakınında",
          id: 'Di Madinah yang diberkahi, dekat Masjid Nabawi',
          hi: 'मुबारक मदीना में, मस्जिद-ए-नबवी के निकट',
          ur: 'مدینہ طیبہ میں، مسجد نبوی شریف کے قریب',
          fr: 'À Médine la bénie, près de la Mosquée du Prophète',
          bn: 'পবিত্র মদিনায়, মসজিদে নববীর কাছে',
        );
      }
      // "ضيوف الرحمن": الوصف المعروف لحجاج بيت الله وعُمّاره.
      return pick(
        ar: 'في خدمة ضيوف الرحمن إلى بيت الله الحرام',
        en: 'Serving the guests of Allah on their way to the Sacred House',
        es: 'Al servicio de los invitados de Allah, rumbo a la Casa Sagrada',
        tr: "Allah'ın misafirlerinin hizmetinde, Beytullah'a doğru",
        id: 'Melayani tamu Allah dalam perjalanan menuju Baitullah',
        hi: 'अल्लाह के मेहमानों की सेवा में, बैतुल्लाह की राह पर',
        ur: 'اللہ کے مہمانوں کی خدمت میں، بیت اللہ کی راہ پر',
        fr: "Au service des invités d'Allah, en route vers la Maison sacrée",
        bn: 'আল্লাহর মেহমানদের সেবায়, বাইতুল্লাহর পথে',
      );
    case 'stays':
    default:
      return pick(
        ar: 'ضيافة راقية في كل وجهة تقصدها',
        en: 'Refined hospitality, wherever you go',
        es: 'Hospitalidad refinada, dondequiera que vayas',
        tr: 'Gittiğiniz her yerde seçkin bir konaklama',
        id: 'Keramahan istimewa, di setiap tujuan Anda',
        hi: 'जहाँ भी जाएं, उत्कृष्ट आतिथ्य आपका इंतजार करता है',
        ur: 'جہاں بھی جائیں، شاندار مہمان نوازی آپ کا انتظار کرتی ہے',
        fr: 'Une hospitalité raffinée, où que vous alliez',
        bn: 'আপনি যেখানেই যান, মার্জিত আতিথেয়তা',
      );
  }
}

/// غلاف بسيط يضيف خلفية دائرية شبه شفافة خلف أيقونة الأكشن، لإعطاء
/// شكل أنيق ومتميز من غير أي Material/InkWell مخصص (اللي سبب مشكلة
/// تجمد الماوس على Windows desktop سابقًا - راجع الملاحظة تحت).
class _BannerIconWrap extends StatelessWidget {
  final Widget child;
  const _BannerIconWrap({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.14),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white.withOpacity(0.22), width: 1),
      ),
      margin: const EdgeInsets.symmetric(horizontal: 2),
      // Theme هنا بيلغي الحد الأدنى الإجباري لمنطقة اللمس (48×48) اللي
      // بيفرضها IconButton/PopupMenuButton افتراضيًا، عشان الإطار
      // الدائري يتماشى فعليًا مع حجم الأيقونة المصغّرة جوّاه، مش يفضل
      // متمدد لمساحة أكبر من غير داعي.
      child: Theme(
        data: Theme.of(context).copyWith(
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          visualDensity: VisualDensity.compact,
        ),
        child: child,
      ),
    );
  }
}

/// زر أكشن: أيقونة بخلفية دائرية، مع اسم الزر يظهر بس عند الوقوف
/// عليه بالماوس (Tooltip قياسي من Flutter - نفس النوع المستخدم أصلاً
/// على أيقونة الأدمن، ومختلف تمامًا عن الـ Material/InkWell المخصص
/// اللي سبب مشكلة الماوس على Windows).
class _BannerAction extends StatelessWidget {
  final Widget child;
  final String label;
  const _BannerAction({required this.child, required this.label});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: label,
      child: _BannerIconWrap(child: child),
    );
  }
}

/// شعار Flynoom (أبيض + برتقالي، خلفية شفافة) أعلى يسار البانر.
/// يُرسم من الكود فوق الصورة — لا يُطبع داخل صور البانر — حتى يبقى
/// حادًا على كل المقاسات ويتغيّر من ملف واحد لكل البانرات.
/// الضغط عليه يرجع للصفحة الرئيسية.
class _BannerLogo extends StatelessWidget {
  final double height;
  const _BannerLogo({required this.height});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Flynoom',
      button: true,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => context.go(AppRoutes.home),
          child: Image.asset(
            // العلامة الملوّنة (F/دبوس/طائرة) بدون حد + FLY أبيض و NOOM برتقالي.
            'assets/images/logo_flynoom_v3.png',
            height: height,
            fit: BoxFit.contain,
            filterQuality: FilterQuality.high,
            // لو الملف مش موجود لأي سبب، لا يظهر شيء بدل خطأ أحمر.
            errorBuilder: (_, __, ___) => const SizedBox.shrink(),
          ),
        ),
      ),
    );
  }
}

/// فاصل عمودي رفيع بين مجموعات الأزرار.
class _BannerDivider extends StatelessWidget {
  final double height;
  final double horizontalMargin;
  const _BannerDivider({this.height = 22, this.horizontalMargin = 8});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: height,
      margin: EdgeInsets.symmetric(horizontal: horizontalMargin),
      color: Colors.white.withOpacity(0.25),
    );
  }
}

/// البانر المشترك اللي بيظهر أعلى كل شاشات التطبيق: خلفية صورة، اللوجو،
/// وأزرار الإجراءات (AI / تسجيل الدخول / العملة / اللغة / الحساب) في
/// الزاوية العلوية اليسار. لو اتبعتله [tabsBar]، بيظهر فوق منطقة بيضاء
/// (زي شريط تبويبات الصفحة الرئيسية)؛ لو مبعتش، البانر بيبقى بس شريط
/// علوي بسيط (للشاشات التانية زي تسجيل الدخول والحجز). زرار رجوع
/// (سهم) بيظهر تلقائيًا في أقصى اليسار لو فيه صفحة سابقة نقدر نرجعلها.
/// أيقونة لوحة تحكم الأدمن (⚙️) بتظهر بس لو المستخدم الحالي أدمن.
///
/// ملحوظة: الأزرار هنا عمدًا بسيطة (IconButton/OutlinedButton عادي، من
/// غير Material مخصص بـ elevation/InkWell) — نسخة "زجاجية" أنيق أكتر
/// كانت بتسبب خلل معروف في محرك Flutter على Windows desktop
/// ("Cannot hit test a render box with no size") بيجمّد الماوس، فرجعنا
/// للتصميم البسيط المستقر. التحسينات الحالية (خلفية دائرية شبه شفافة +
/// Tooltip قياسي عند hover) ما بتضيف أي طبقة Material/InkWell جديدة،
/// فهي آمنة.
///
/// ملحوظة إضافية (تصليح تجاوز الموبايل): قبل هذا التعديل، فحص
/// isMobile كان يُستخدم بس لاختيار صورة الخلفية، وكل المقاسات
/// (الخط، الأيقونات، المسافات، ارتفاع البانر) كانت ثابتة بغض النظر
/// عن عرض الشاشة — وده كان يسبب overflow حقيقي على آيفون. دلوقتي
/// isMobile بيتحسب مرة واحدة وبيُستخدم لتصغير كل العناصر فعليًا.
///
/// ملحوظة إضافية (وضع collapsed): لو [collapsed] = true، البانر
/// بيخفي الصورة الخلفية والجملة التسويقية ويفضل بس شريط علوي رفيع
/// بالأيقونات + tabsBar مباشرة تحته -- بيُستخدم بعد ما يحصل بحث فعلي
/// عشان نوفر مساحة رأسية أكبر لعرض النتائج على الشاشات العريضة.
///
/// ملحوظة إضافية (إزالة اسم المنصة النصي): تم حذف نص "Flynoom" اللي
/// كان ظاهر أعلى يسار البانر (وكان قابل للدوس للرجوع للرئيسية)، لأن
/// اسم المنصة أصبح ظاهر بالفعل داخل صورة الخلفية نفسها (banner_*.png)،
/// وعرضه كنص كمان كان تكرارًا. الدوس-للرجوع-للرئيسية اتشال معاه بقرار
/// من المستخدم (مفيش بديل قابل للدوس مكانه).
///
/// ملحوظة إضافية (إرجاع الشعار كصورة، أكتوبر 2026): صور البانر الجديدة
/// بدون أي شعار مطبوع داخلها، فالشعار رجع كـ widget مستقل (_BannerLogo)
/// أعلى اليسار، بعد زر الرجوع إن وُجد، وقابل للضغط للرجوع للرئيسية.
/// الصف العلوي مثبّت على اتجاه LTR في كل اللغات (حتى العربية) عشان
/// الشعار يفضل دايمًا على اليسار والأزرار على اليمين.
class AppBanner extends ConsumerWidget implements PreferredSizeWidget {
  final Widget? tabsBar;
  final double bannerHeight;
  final String? assetVariant;
  /// التبويب النشط حاليًا ('stays'/'flights'/'flightHotel'/'carRental')،
  /// بيُستخدم بس لاختيار نص الجملة التسويقية فوق الصورة. مبعتش (null)
  /// في الشاشات اللي مالهاش تبويبات (تسجيل الدخول، الحجز، إلخ).
  final String? activeTab;

  /// لو true، البانر بيختفي (الصورة الخلفية + الجملة التسويقية) ويفضل
  /// بس شريط علوي رفيع بالأيقونات + tabsBar مباشرة تحته -- بيُستخدم
  /// بعد ما يحصل بحث فعلي عشان نوفر مساحة رأسية أكبر لعرض النتائج.
  final bool collapsed;

  const AppBanner({
    super.key,
    this.tabsBar,
    this.bannerHeight = 260,
    this.assetVariant,
    this.activeTab,
    this.collapsed = false,
  });

  // مقدار الارتفاع الإضافي المحجوز لما فيه tabsBar، عشان العنوان
  // التسويقي (سطرين أحيانًا) + التبويبات ما يتضاغطوا على بعض على
  // الموبايل. لازم يكون نفس القيمة بالضبط بين preferredSize (اللي
  // يستخدمه الـ Scaffold لحجز المساحة قبل الرسم، وما عنده context
  // يقدر يتحقق منه عرض الشاشة) وبين build() — وإلا يصير تعارض
  // (مساحة محجوزة أقل من المرسومة فعليًا = تجاوز/قص). فبدل ما نربطها
  // بـ isMobile (اللي محتاج context)، نحجزها دائمًا لو فيه tabsBar؛
  // على الشاشات الواسعة المساحة الزيادة مجرد فراغ إضافي بسيط، غير
  // مؤثر بصريًا.
  static const double _tabsBarExtraHeight = 46;

  // الارتفاع الفعلي المستخدم للبانر: القيمة العادية bannerHeight، أو
  // ارتفاع مصغّر ثابت (64) لو collapsed = true. نفس القيمة دي لازم
  // تُستخدم في preferredSize وbuild() مع بعض بالظبط لنفس سبب
  // _tabsBarExtraHeight فوق (تجنّب تعارض المساحة المحجوزة/المرسومة).
  double get _effectiveBannerHeight => collapsed ? 120 : bannerHeight;

  @override
  Size get preferredSize {
    return Size.fromHeight(
      tabsBar != null ? _effectiveBannerHeight + _tabsBarExtraHeight : _effectiveBannerHeight,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final isAdmin = ref.watch(isAdminProvider);
    final canPop = Navigator.of(context).canPop();
    final isMobile = MediaQuery.of(context).size.width < 600;

    // مقاسات متجاوبة: نفس القيم الأصلية على الشاشات الواسعة، وقيم
    // أصغر فعليًا (مش بس صورة خلفية مختلفة) على الموبايل.
    final iconSize = isMobile ? 15.0 : 18.0;
    final iconPadding = isMobile ? 6.0 : 8.0;
    final actionSpacing = isMobile ? 1.0 : 4.0;
    final dividerMargin = isMobile ? 5.0 : 8.0;
    final taglineFontSize = isMobile ? 17.0 : 24.0;
    final logoHeight = isMobile ? 26.0 : 42.0;

    return SizedBox(
      height: preferredSize.height,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (collapsed)
            Builder(
              builder: (context) {
                final variantSuffix = assetVariant != null ? '${assetVariant}_' : '';
                final assetPath = isMobile
                    ? 'assets/images/banner_${variantSuffix}mobile.png'
                    : 'assets/images/banner_${variantSuffix}desktop.png';
                final defaultAssetPath = isMobile
                    ? 'assets/images/banner_mobile.png'
                    : 'assets/images/banner_desktop.png';
                return Image.asset(
                  assetPath,
                  fit: BoxFit.cover,
                  filterQuality: FilterQuality.high,
                  errorBuilder: (_, __, ___) => Image.asset(
                    defaultAssetPath,
                    fit: BoxFit.cover,
                    filterQuality: FilterQuality.high,
                    errorBuilder: (_, __, ___) => Container(color: AppColors.primaryDark),
                  ),
                );
              },
            )
          else ...[
            Builder(
              builder: (context) {
                final variantSuffix = assetVariant != null ? '${assetVariant}_' : '';
                final assetPath = isMobile
                    ? 'assets/images/banner_${variantSuffix}mobile.png'
                    : 'assets/images/banner_${variantSuffix}desktop.png';
                final defaultAssetPath = isMobile
                    ? 'assets/images/banner_mobile.png'
                    : 'assets/images/banner_desktop.png';
                return Image.asset(
                  assetPath,
                  fit: BoxFit.cover,
                  filterQuality: FilterQuality.high,
                  errorBuilder: (_, __, ___) => Image.asset(
                    defaultAssetPath,
                    fit: BoxFit.cover,
                    filterQuality: FilterQuality.high,
                    errorBuilder: (_, __, ___) => Image.asset(
                      'assets/images/banner_desktop.png',
                      fit: BoxFit.cover,
                      filterQuality: FilterQuality.high,
                      errorBuilder: (_, __, ___) => Container(color: AppColors.primaryDark),
                    ),
                  ),
                );
              },
            ),
          ],
          // تظليل خفيف أعلى البانر حتى يبقى الشعار (خاصة "NOOM" البرتقالي)
          // والأيقونات واضحة فوق أي صورة، حتى لو كانت سماء غروب برتقالية.
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: isMobile ? 80 : 110,
            child: const IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0x8C000000), Color(0x00000000)],
                  ),
                ),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: isMobile ? AppSizes.sm : AppSizes.md,
                vertical: 8,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // LTR ثابت: الشعار يسار والأزرار يمين في كل اللغات.
                  Directionality(
                    textDirection: TextDirection.ltr,
                    child: Row(
                      children: [
                        if (canPop) ...[
                          _BannerIconWrap(
                            child: IconButton(
                              icon: const Icon(Icons.arrow_back, color: Colors.white),
                              iconSize: iconSize,
                              padding: EdgeInsets.all(iconPadding),
                              constraints: const BoxConstraints(),
                              onPressed: () => context.pop(),
                            ),
                          ),
                          const SizedBox(width: 4),
                        ],
                        _BannerLogo(height: logoHeight),
                        SizedBox(width: isMobile ? 8 : 16),
                        Expanded(
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            // reverse: true بيخلي المحتوى يتثبّت على أقصى
                            // اليمين لما تكون فيه مساحة فاضية (زي شاشات
                            // Windows/الويب العريضة)، بدل السلوك الافتراضي
                            // لـ SingleChildScrollView اللي بيثبّت المحتوى
                            // على أقصى الشمال ويلغي أثر mainAxisAlignment.end.
                            reverse: true,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                if (isAdmin) ...[
                                  _BannerAction(
                                    label: appBannerText(
                                      context,
                                      ar: 'لوحة تحكم الأدمن',
                                      en: 'Admin dashboard',
                                      es: 'Panel de administración',
                                    ),
                                    child: IconButton(
                                      icon: const Icon(Icons.admin_panel_settings_outlined, color: Colors.white),
                                      iconSize: iconSize,
                                      padding: EdgeInsets.all(iconPadding),
                                      constraints: const BoxConstraints(),
                                      onPressed: () => context.push(AppRoutes.adminDashboard),
                                    ),
                                  ),
                                  SizedBox(width: actionSpacing),
                                ],
                                // زر AI مخفي مع صفحته (انظر kAiEnabled في features.dart).
                                if (kAiEnabled) ...[
                                  OutlinedButton.icon(
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: Colors.white,
                                      backgroundColor: Colors.white.withOpacity(0.16),
                                      side: const BorderSide(color: Colors.white, width: 1.2),
                                      shape: const StadiumBorder(),
                                      padding: EdgeInsets.symmetric(
                                        horizontal: isMobile ? 7 : 10,
                                        vertical: 4,
                                      ),
                                      minimumSize: Size.zero,
                                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                    ),
                                    onPressed: () => context.push(AppRoutes.aiTravel),
                                    icon: const Icon(Icons.auto_awesome, size: 12),
                                    label: const Text('AI', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                                  ),
                                  _BannerDivider(horizontalMargin: dividerMargin),
                                ],

                                _BannerAction(
                                  label: appBannerText(context, ar: 'العملة', en: 'Currency', es: 'Moneda'),
                                  child: const CurrencySelectorButton(),
                                ),
                                _BannerAction(
                                  label: appBannerText(context, ar: 'اللغة', en: 'Language', es: 'Idioma'),
                                  child: PopupMenuButton<Locale>(
                                    icon: Icon(Icons.language, color: Colors.white, size: iconSize),
                                    padding: EdgeInsets.all(iconPadding),
                                    onSelected: (locale) => ref.read(localeProvider.notifier).setLocale(locale),
                                    itemBuilder: (context) => const [
                                      PopupMenuItem(value: Locale('ar'), child: Text('العربية')),
                                      PopupMenuItem(value: Locale('en'), child: Text('English')),
                                      PopupMenuItem(value: Locale('es'), child: Text('Español')),
                                      PopupMenuItem(value: Locale('tr'), child: Text('Türkçe')),
                                      PopupMenuItem(value: Locale('id'), child: Text('Bahasa Indonesia')),
                                      PopupMenuItem(value: Locale('hi'), child: Text('हिन्दी')),
                                      PopupMenuItem(value: Locale('ur'), child: Text('اردو')),
                                      PopupMenuItem(value: Locale('fr'), child: Text('Français')),
                                      PopupMenuItem(value: Locale('bn'), child: Text('বাংলা')),
                                    ],
                                  ),
                                ),
                                _BannerAction(
                                  label: appBannerText(context, ar: 'حجوزاتي', en: 'My bookings', es: 'Mis reservas'),
                                  child: IconButton(
                                    icon: const Icon(Icons.receipt_long_outlined, color: Colors.white),
                                    iconSize: iconSize,
                                    padding: EdgeInsets.all(iconPadding),
                                    constraints: const BoxConstraints(),
                                    onPressed: () async {
                                      if (user == null) {
                                        await context.push(AppRoutes.login);
                                        if (context.mounted) context.push(AppRoutes.myBookings);
                                      } else {
                                        context.push(AppRoutes.myBookings);
                                      }
                                    },
                                  ),
                                ),
                                _BannerAction(
                                  label: appBannerText(context, ar: 'الدعم', en: 'Support', es: 'Soporte'),
                                  child: IconButton(
                                    icon: const Icon(Icons.support_agent_outlined, color: Colors.white),
                                    iconSize: iconSize,
                                    padding: EdgeInsets.all(iconPadding),
                                    constraints: const BoxConstraints(),
                                    onPressed: () => context.push(AppRoutes.support),
                                  ),
                                ),
                                if (user == null)
                                  OutlinedButton(
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: Colors.white,
                                      backgroundColor: Colors.white.withOpacity(0.16),
                                      side: const BorderSide(color: Colors.white, width: 1.2),
                                      shape: const StadiumBorder(),
                                      padding: EdgeInsets.symmetric(
                                        horizontal: isMobile ? 7 : 10,
                                        vertical: 4,
                                      ),
                                      minimumSize: Size.zero,
                                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                    ),
                                    onPressed: () => context.push(AppRoutes.login),
                                    child: Text(
                                      appBannerText(context, ar: 'تسجيل الدخول', en: 'Sign in', es: 'Iniciar sesión'),
                                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (tabsBar != null) ...[
                    if (collapsed)
                      const SizedBox(height: 8)
                    else
                      Expanded(
                        child: Align(
                          alignment: AlignmentDirectional.bottomStart,
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Text(
                              _bannerTagline(context, activeTab, assetVariant),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: taglineFontSize,
                                fontWeight: FontWeight.bold,
                                height: 1.25,
                                shadows: const [
                                  Shadow(color: Colors.black38, blurRadius: 6, offset: Offset(0, 1)),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    tabsBar!,
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}