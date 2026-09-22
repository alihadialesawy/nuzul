import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../core/widgets/app_banner.dart';
import '../auth/controllers/auth_controller.dart';

/// يختار النص المناسب حسب اللغة الحالية (عربي/إنجليزي/إسباني/تركي/إندونيسي/هندي/أوردو/فرنسي/بنغالي).
String _t3(
    BuildContext context, {
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
  switch (Localizations.localeOf(context).languageCode) {
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

/// صفحة "عملاتي" -- برنامج ولاء بنفس روح Trip.com Rewards: شارة
/// المستوى الحالي + رصيد العملات + جدول مقارنة مزايا المستويات
/// الأربعة. ملحوظة مهمة: دي واجهة عرض حاليًا فقط -- مفيش نظام حقيقي
/// خلف الكواليس بيحسب حجوزات المستخدم أو يراكم عملات فعلية بعد
/// (زي ما هو الحال مع "بطاقاتي"/"أكواد الخصم" اللي كانت "قريبًا").
/// المستوى المعروض هنا (Silver، 0 عملة) قيمة مبدئية ثابتة لحد ما
/// يتضاف نظام تتبّع حقيقي مرتبط بجدول الحجوزات.
class MyCoinsPage extends ConsumerWidget {
  const MyCoinsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final displayName = user?.email?.split('@').first ?? '';

    return Scaffold(
      appBar: const AppBanner(),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            const maxContentWidth = 900.0;
            final isWide = constraints.maxWidth > maxContentWidth;

            return Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: isWide ? maxContentWidth : double.infinity,
                ),
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    // بانر علوي بلون العلامة التجارية، بنفس أسلوب Trip.com Rewards
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: AppSizes.xl, horizontal: AppSizes.md),
                      color: AppColors.primaryDark,
                      child: Column(
                        children: [
                          const Text(
                            'SkyNoom',
                            style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            _t3(context, ar: 'المكافآت', en: 'REWARDS', es: 'RECOMPENSAS', tr: 'ÖDÜLLER',
                                id: 'HADIAH', hi: 'रिवॉर्ड्स', ur: 'انعامات', fr: 'RÉCOMPENSES', bn: 'পুরস্কার'),
                            style: const TextStyle(
                              color: Colors.amber,
                              fontSize: 32,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _t3(context, ar: 'برنامج ولاء SkyNoom', en: "SkyNoom's loyalty program", es: 'Programa de fidelidad de SkyNoom', tr: 'SkyNoom sadakat programı',
                                id: 'Program loyalitas SkyNoom', hi: 'SkyNoom का लॉयल्टी प्रोग्राम', ur: 'SkyNoom کا وفاداری پروگرام', fr: 'Programme de fidélité SkyNoom', bn: 'SkyNoom-এর লয়্যালটি প্রোগ্রাম'),
                            style: const TextStyle(color: Colors.white70, fontSize: 13),
                          ),
                        ],
                      ),
                    ),

                    Padding(
                      padding: const EdgeInsets.all(AppSizes.md),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _t3(
                              context,
                              ar: displayName.isEmpty
                                  ? 'مرحبًا، تهانينا على عضويتك في المستوى الفضي'
                                  : 'مرحبًا $displayName، تهانينا على عضويتك في المستوى الفضي',
                              en: displayName.isEmpty
                                  ? 'Hi there, congrats on being a Silver Tier Member'
                                  : 'Hi $displayName, congrats on being a Silver Tier Member',
                              es: 'Hola, felicidades por ser miembro del nivel Plata',
                              tr: 'Merhaba, Gümüş Seviye Üye olduğunuz için tebrikler',
                              id: 'Halo, selamat menjadi Anggota Tingkat Perak',
                              hi: 'नमस्ते, सिल्वर टियर सदस्य बनने पर बधाई',
                              ur: 'ہیلو، سلور ٹیئر ممبر بننے پر مبارک ہو',
                              fr: 'Bonjour, félicitations pour votre statut de membre Argent',
                              bn: 'হ্যালো, সিলভার টায়ার সদস্য হওয়ার জন্য অভিনন্দন',
                            ),
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                          ),
                          const SizedBox(height: AppSizes.md),
                          LayoutBuilder(
                            builder: (context, cardConstraints) {
                              final isNarrow = cardConstraints.maxWidth < 500;
                              final tierCard = _InfoCard(
                                child: Row(
                                  children: [
                                    Container(
                                      width: 48,
                                      height: 48,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Colors.blueGrey.shade100,
                                        border: Border.all(color: Colors.blueGrey.shade300, width: 2),
                                      ),
                                      child: const Icon(Icons.workspace_premium, color: Colors.blueGrey),
                                    ),
                                    const SizedBox(width: AppSizes.sm),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            _t3(context, ar: 'عضو المستوى الفضي', en: "You're a Silver Tier Member", es: 'Eres miembro del nivel Plata', tr: 'Gümüş Seviye Üyesisiniz',
                                                id: 'Anda Anggota Tingkat Perak', hi: 'आप सिल्वर टियर सदस्य हैं', ur: 'آپ سلور ٹیئر ممبر ہیں', fr: 'Vous êtes membre Argent', bn: 'আপনি সিলভার টায়ার সদস্য'),
                                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            _t3(context, ar: 'أكمل حجزًا واحدًا للترقية إلى المستوى الذهبي', en: 'Complete 1 booking to unlock Gold', es: 'Completa 1 reserva para desbloquear Oro', tr: '1 rezervasyon tamamlayarak Altın seviyeye ulaşın',
                                                id: 'Selesaikan 1 pemesanan untuk membuka Emas', hi: 'गोल्ड अनलॉक करने के लिए 1 बुकिंग पूरी करें', ur: 'گولڈ کھولنے کے لیے 1 بکنگ مکمل کریں', fr: 'Effectuez 1 réservation pour débloquer Or', bn: 'গোল্ড আনলক করতে ১টি বুকিং সম্পন্ন করুন'),
                                            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                          ),
                                          const SizedBox(height: 8),
                                          ClipRRect(
                                            borderRadius: BorderRadius.circular(4),
                                            child: LinearProgressIndicator(
                                              value: 0,
                                              minHeight: 6,
                                              backgroundColor: AppColors.divider,
                                              valueColor: const AlwaysStoppedAnimation(AppColors.primary),
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            _t3(context, ar: '0 / 1 حجز', en: '0 / 1 booking', es: '0 / 1 reserva', tr: '0 / 1 rezervasyon',
                                                id: '0 / 1 pesanan', hi: '0 / 1 बुकिंग', ur: '0 / 1 بکنگ', fr: '0 / 1 réservation', bn: '0 / 1 বুকিং'),
                                            style: const TextStyle(fontSize: 11, color: AppColors.textHint),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              );

                              final coinsCard = _InfoCard(
                                child: Row(
                                  children: [
                                    Container(
                                      width: 48,
                                      height: 48,
                                      decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.amber),
                                      child: const Icon(Icons.monetization_on, color: Colors.white),
                                    ),
                                    const SizedBox(width: AppSizes.sm),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text('0', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
                                          Text(
                                            _t3(context, ar: 'رصيد العملات', en: 'Coins', es: 'Monedas', tr: 'Puanlar',
                                                id: 'Koin', hi: 'कॉइन', ur: 'کوائنز', fr: 'Points', bn: 'কয়েন'),
                                            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              );

                              if (isNarrow) {
                                return Column(
                                  children: [
                                    tierCard,
                                    const SizedBox(height: AppSizes.sm),
                                    coinsCard,
                                  ],
                                );
                              }
                              return Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(child: tierCard),
                                  const SizedBox(width: AppSizes.sm),
                                  Expanded(child: coinsCard),
                                ],
                              );
                            },
                          ),

                          const SizedBox(height: AppSizes.xl),
                          Text(
                            _t3(context, ar: 'الأعضاء يستمتعون بمزايا حصرية وعروض للأعضاء فقط وخدمات ذات أولوية. انضم إلينا لفتحها كلها!',
                                en: 'members enjoy exclusive perks, member-only deals, and priority services. Join us to unlock them all!',
                                es: 'los miembros disfrutan de ventajas exclusivas, ofertas solo para miembros y servicios prioritarios. ¡Únete para desbloquearlos todos!',
                                tr: 'üyeler özel avantajlardan, yalnızca üyelere özel fırsatlardan ve öncelikli hizmetlerden yararlanır. Hepsini açmak için bize katılın!',
                                id: 'anggota menikmati keuntungan eksklusif, penawaran khusus anggota, dan layanan prioritas. Bergabunglah untuk membuka semuanya!',
                                hi: 'सदस्य विशेष लाभ, सदस्य-केवल ऑफ़र और प्राथमिकता सेवाओं का आनंद लेते हैं। सभी को अनलॉक करने के लिए हमसे जुड़ें!',
                                ur: 'ممبران خصوصی فوائد، صرف ممبران کے لیے آفرز، اور ترجیحی خدمات سے لطف اندوز ہوتے ہیں۔ سب کچھ کھولنے کے لیے ہمارے ساتھ شامل ہوں!',
                                fr: 'les membres profitent d\'avantages exclusifs, d\'offres réservées aux membres et de services prioritaires. Rejoignez-nous pour tout débloquer !',
                                bn: 'সদস্যরা একচেটিয়া সুবিধা, শুধুমাত্র সদস্যদের জন্য অফার এবং অগ্রাধিকার পরিষেবা উপভোগ করেন। সবকিছু আনলক করতে আমাদের সাথে যোগ দিন!'),
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          const SizedBox(height: AppSizes.lg),

                          const _TiersComparisonTable(),

                          const SizedBox(height: AppSizes.xl),
                          const _FaqSection(),

                          const SizedBox(height: AppSizes.xl),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final Widget child;
  const _InfoCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.md),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: child,
    );
  }
}

class _TierColumn {
  final String name;
  final Color color;
  final int rewardsCount;
  const _TierColumn({required this.name, required this.color, required this.rewardsCount});
}

/// جدول مقارنة مزايا المستويات الأربعة (Silver/Gold/Platinum/Diamond)،
/// بنفس بنية جدول Trip.com Rewards المرجعي. القيم هنا وصفية/تسويقية
/// وليست مرتبطة بمنطق فعلي بعد.
class _TiersComparisonTable extends StatelessWidget {
  const _TiersComparisonTable();

  @override
  Widget build(BuildContext context) {
    final tiers = [
      _TierColumn(name: _t3(context, ar: 'فضي', en: 'Silver', es: 'Plata', tr: 'Gümüş', id: 'Perak', hi: 'सिल्वर', ur: 'سلور', fr: 'Argent', bn: 'সিলভার'), color: Colors.blueGrey, rewardsCount: 3),
      _TierColumn(name: _t3(context, ar: 'ذهبي', en: 'Gold', es: 'Oro', tr: 'Altın', id: 'Emas', hi: 'गोल्ड', ur: 'گولڈ', fr: 'Or', bn: 'গোল্ড'), color: Colors.amber.shade800, rewardsCount: 3),
      _TierColumn(name: _t3(context, ar: 'بلاتيني', en: 'Platinum', es: 'Platino', tr: 'Platin', id: 'Platinum', hi: 'प्लैटिनम', ur: 'پلاٹینم', fr: 'Platine', bn: 'প্ল্যাটিনাম'), color: Colors.blue.shade700, rewardsCount: 5),
      _TierColumn(name: _t3(context, ar: 'ماسي', en: 'Diamond', es: 'Diamante', tr: 'Elmas', id: 'Berlian', hi: 'डायमंड', ur: 'ڈائمنڈ', fr: 'Diamant', bn: 'ডায়মন্ড'), color: Colors.purple.shade700, rewardsCount: 7),
    ];

    final rewardsLabel = _t3(context, ar: 'مزايا', en: 'rewards', es: 'ventajas', tr: 'ödül', id: 'hadiah', hi: 'रिवॉर्ड्स', ur: 'انعامات', fr: 'avantages', bn: 'পুরস্কার');

    final perkRows = <(String label, List<String> values)>[
      (
      _t3(context, ar: 'اكسب عملات', en: 'Earn Coins', es: 'Gana monedas', tr: 'Puan Kazan', id: 'Dapatkan Koin', hi: 'कॉइन कमाएं', ur: 'کوائنز کمائیں', fr: 'Gagnez des points', bn: 'কয়েন অর্জন করুন'),
      [
        _t3(context, ar: 'اكسب عملات عادي', en: 'Earn Coins', es: 'Gana monedas', tr: 'Puan Kazan', id: 'Dapatkan Koin', hi: 'कॉइन कमाएं', ur: 'کوائنز کمائیں', fr: 'Gagnez des points', bn: 'কয়েন অর্জন করুন'),
        _t3(context, ar: 'اكسب 20% أكثر', en: 'Earn 20% More', es: 'Gana 20% más', tr: '%20 Daha Fazla Kazan', id: 'Dapatkan 20% Lebih', hi: '20% अधिक कमाएं', ur: '20% زیادہ کمائیں', fr: 'Gagnez 20% de plus', bn: '২০% বেশি অর্জন করুন'),
        _t3(context, ar: 'اكسب 50% أكثر', en: 'Earn 50% More', es: 'Gana 50% más', tr: '%50 Daha Fazla Kazan', id: 'Dapatkan 50% Lebih', hi: '50% अधिक कमाएं', ur: '50% زیادہ کمائیں', fr: 'Gagnez 50% de plus', bn: '৫০% বেশি অর্জন করুন'),
        _t3(context, ar: 'اكسب 100% أكثر', en: 'Earn 100% More', es: 'Gana 100% más', tr: '%100 Daha Fazla Kazan', id: 'Dapatkan 100% Lebih', hi: '100% अधिक कमाएं', ur: '100% زیادہ کمائیں', fr: 'Gagnez 100% de plus', bn: '১০০% বেশি অর্জন করুন'),
      ]
      ),
      (
      _t3(context, ar: 'دخول مجاني لصالة كبار الشخصيات بالمطار', en: 'Free Airport VIP Lounge Access', es: 'Acceso gratuito a sala VIP', tr: 'Ücretsiz Havaalanı VIP Salonu', id: 'Akses Lounge VIP Bandara Gratis', hi: 'मुफ़्त एयरपोर्ट VIP लाउंज', ur: 'مفت ایئرپورٹ وی آئی پی لاؤنج', fr: 'Accès salon VIP gratuit', bn: 'ফ্রি এয়ারপোর্ট ভিআইপি লাউঞ্জ'),
      ['-', '-', _t3(context, ar: 'مرة واحدة', en: '1 time', es: '1 vez', tr: '1 kez', id: '1 kali', hi: '1 बार', ur: '1 مرتبہ', fr: '1 fois', bn: '১ বার'), _t3(context, ar: 'مرتان', en: '2 times', es: '2 veces', tr: '2 kez', id: '2 kali', hi: '2 बार', ur: '2 مرتبہ', fr: '2 fois', bn: '২ বার')]
      ),
      (
      _t3(context, ar: 'باقة بيانات eSIM عالمية مجانية', en: 'Free Global eSIM Data Package', es: 'Paquete eSIM global gratuito', tr: 'Ücretsiz Global eSIM Paketi', id: 'Paket Data eSIM Global Gratis', hi: 'मुफ़्त ग्लोबल eSIM डेटा पैकेज', ur: 'مفت گلوبل eSIM ڈیٹا پیکج', fr: 'Forfait eSIM mondial gratuit', bn: 'ফ্রি গ্লোবাল eSIM ডেটা প্যাকেজ'),
      ['-', '-', '1GB / 3d', '3GB / 5d']
      ),
      (
      _t3(context, ar: 'ترقية مركبة النقل من المطار', en: 'Airport Transfer Model Upgrade', es: 'Mejora de traslado al aeropuerto', tr: 'Havalimanı Transfer Yükseltmesi', id: 'Peningkatan Model Antar-Jemput', hi: 'एयरपोर्ट ट्रांसफर अपग्रेड', ur: 'ایئرپورٹ ٹرانسفر اپ گریڈ', fr: 'Surclassement transfert aéroport', bn: 'এয়ারপোর্ট ট্রান্সফার আপগ্রেড'),
      ['-', '-', '-', _t3(context, ar: 'مرتان', en: '2 times', es: '2 veces', tr: '2 kez', id: '2 kali', hi: '2 बार', ur: '2 مرتبہ', fr: '2 fois', bn: '২ বার')]
      ),
      (
      _t3(context, ar: 'بدون رسوم إدارية على استرداد الحجوزات', en: 'No Admin Fee for Trip Refunds', es: 'Sin cargo administrativo en reembolsos', tr: 'İptal İadelerinde Yönetim Ücreti Yok', id: 'Tanpa Biaya Admin untuk Refund', hi: 'रिफंड पर कोई एडमिन शुल्क नहीं', ur: 'ریفنڈ پر کوئی ایڈمن فیس نہیں', fr: 'Aucun frais de gestion sur les remboursements', bn: 'রিফান্ডে কোনো অ্যাডমিন ফি নেই'),
      ['-', _t3(context, ar: 'مشمول', en: 'Included', es: 'Incluido', tr: 'Dahil', id: 'Termasuk', hi: 'शामिल', ur: 'شامل', fr: 'Inclus', bn: 'অন্তর্ভুক্ত'), _t3(context, ar: 'مشمول', en: 'Included', es: 'Incluido', tr: 'Dahil', id: 'Termasuk', hi: 'शामिल', ur: 'شامل', fr: 'Inclus', bn: 'অন্তর্ভুক্ত'), _t3(context, ar: 'مشمول', en: 'Included', es: 'Incluido', tr: 'Dahil', id: 'Termasuk', hi: 'शामिल', ur: 'شامل', fr: 'Inclus', bn: 'অন্তর্ভুক্ত')]
      ),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Table(
        border: TableBorder(
          horizontalInside: BorderSide(color: AppColors.divider),
        ),
        defaultColumnWidth: const FixedColumnWidth(140),
        columnWidths: const {0: FixedColumnWidth(220)},
        children: [
          TableRow(
            children: [
              const SizedBox(),
              for (final tier in tiers)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSizes.sm),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundColor: tier.color.withOpacity(0.15),
                        child: Icon(Icons.workspace_premium, color: tier.color, size: 18),
                      ),
                      const SizedBox(height: 4),
                      Text(tier.name, style: TextStyle(fontWeight: FontWeight.bold, color: tier.color)),
                      Text(
                        '${tier.rewardsCount} $rewardsLabel',
                        style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          for (final row in perkRows)
            TableRow(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSizes.sm),
                  child: Text(row.$1, style: const TextStyle(fontSize: 13)),
                ),
                for (final value in row.$2)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: AppSizes.sm),
                    child: Center(
                      child: Text(
                        value,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}

/// قسم "الأسئلة الشائعة" (FAQs) أسفل صفحة عملاتي -- تابات فئات (المستوى/
/// المكافآت/العملات/الشروط والأحكام) + قائمة أسئلة قابلة للطي (accordion)
/// لكل فئة. محتوى ثابت/عام حاليًا (زي جدول المقارنة فوقه)، مش مرتبط بمنطق
/// حقيقي بعد.
class _FaqSection extends StatefulWidget {
  const _FaqSection();

  @override
  State<_FaqSection> createState() => _FaqSectionState();
}

class _FaqSectionState extends State<_FaqSection> {
  int _activeTab = 0;

  List<String> _tabLabels(BuildContext context) => [
    _t3(context, ar: 'المستوى', en: 'Member tier', es: 'Nivel de miembro', tr: 'Üyelik Seviyesi',
        id: 'Tingkat Anggota', hi: 'सदस्य स्तर', ur: 'ممبر ٹیئر', fr: 'Niveau de membre', bn: 'সদস্য স্তর'),
    _t3(context, ar: 'المكافآت', en: 'Member Rewards', es: 'Recompensas', tr: 'Üye Ödülleri',
        id: 'Hadiah Anggota', hi: 'सदस्य रिवॉर्ड्स', ur: 'ممبر انعامات', fr: 'Récompenses membres', bn: 'সদস্য পুরস্কার'),
    _t3(context, ar: 'العملات', en: 'Coins', es: 'Monedas', tr: 'Puanlar',
        id: 'Koin', hi: 'कॉइन', ur: 'کوائنز', fr: 'Points', bn: 'কয়েন'),
    _t3(context, ar: 'الشروط والأحكام', en: 'Terms & Conditions', es: 'Términos y condiciones', tr: 'Şartlar ve Koşullar',
        id: 'Syarat & Ketentuan', hi: 'नियम व शर्तें', ur: 'شرائط و ضوابط', fr: 'Conditions générales', bn: 'শর্তাবলী'),
  ];

  List<({String q, String a})> _faqsFor(BuildContext context, int tabIndex) {
    switch (tabIndex) {
      case 0: // Member tier
        return [
          (
          q: _t3(context, ar: 'كيف أترقّى بين المستويات؟', en: 'How to progress?', es: '¿Cómo progreso?', tr: 'Nasıl ilerlerim?',
              id: 'Bagaimana cara naik tingkat?', hi: 'प्रगति कैसे करें?', ur: 'ترقی کیسے کریں؟', fr: 'Comment progresser ?', bn: 'কীভাবে অগ্রসর হবেন?'),
          a: _t3(context, ar: 'كل ما تكمّل حجوزات أكتر عبر SkyNoom، كل ما تترقّى لمستوى أعلى ومزايا أكثر.',
              en: 'The more bookings you complete through SkyNoom, the higher your tier climbs and the more perks you unlock.',
              es: 'Cuantas más reservas completes en SkyNoom, más alto será tu nivel y más ventajas desbloquearás.',
              tr: 'SkyNoom üzerinden ne kadar çok rezervasyon tamamlarsanız, seviyeniz o kadar yükselir ve daha fazla avantaj açarsınız.',
              id: 'Semakin banyak pemesanan yang Anda selesaikan melalui SkyNoom, semakin tinggi tingkat Anda dan semakin banyak keuntungan yang terbuka.',
              hi: 'आप SkyNoom के ज़रिए जितनी अधिक बुकिंग पूरी करेंगे, आपका स्तर उतना ही ऊँचा होगा और उतने ही अधिक लाभ खुलेंगे।',
              ur: 'آپ SkyNoom کے ذریعے جتنی زیادہ بکنگز مکمل کریں گے، آپ کا ٹیئر اتنا ہی بلند ہوگا اور اتنے ہی زیادہ فوائد کھلیں گے۔',
              fr: 'Plus vous effectuez de réservations via SkyNoom, plus votre niveau augmente et plus vous débloquez d\'avantages.',
              bn: 'SkyNoom-এর মাধ্যমে আপনি যত বেশি বুকিং সম্পন্ন করবেন, আপনার স্তর তত উঁচুতে উঠবে এবং তত বেশি সুবিধা আনলক হবে।'),
          ),
          (
          q: _t3(context, ar: 'إزاي أحافظ على مستواي؟', en: 'How do I maintain my tier?', es: '¿Cómo mantengo mi nivel?', tr: 'Seviyemi nasıl korurum?',
              id: 'Bagaimana cara mempertahankan tingkat saya?', hi: 'मैं अपना स्तर कैसे बनाए रखूं?', ur: 'میں اپنا ٹیئر کیسے برقرار رکھوں؟', fr: 'Comment maintenir mon niveau ?', bn: 'কীভাবে আমার স্তর বজায় রাখব?'),
          a: _t3(context, ar: 'المستويات بتتجدد سنويًا حسب عدد الحجوزات المكتملة خلال آخر 12 شهر.',
              en: 'Tiers are reassessed annually based on the number of completed bookings over the previous 12 months.',
              es: 'Los niveles se reevalúan anualmente según el número de reservas completadas en los últimos 12 meses.',
              tr: 'Seviyeler, son 12 aydaki tamamlanan rezervasyon sayısına göre yıllık olarak yeniden değerlendirilir.',
              id: 'Tingkat dievaluasi ulang setiap tahun berdasarkan jumlah pemesanan yang diselesaikan dalam 12 bulan terakhir.',
              hi: 'पिछले 12 महीनों में पूरी की गई बुकिंग की संख्या के आधार पर स्तरों का सालाना पुनर्मूल्यांकन किया जाता है।',
              ur: 'گزشتہ 12 مہینوں میں مکمل کی گئی بکنگز کی تعداد کی بنیاد پر ٹیئرز کا سالانہ دوبارہ جائزہ لیا جاتا ہے۔',
              fr: 'Les niveaux sont réévalués chaque année en fonction du nombre de réservations effectuées au cours des 12 derniers mois.',
              bn: 'বিগত ১২ মাসে সম্পন্ন বুকিং সংখ্যার ভিত্তিতে স্তরসমূহ বার্ষিক পুনর্মূল্যায়ন করা হয়।'),
          ),
          (
          q: _t3(context, ar: 'إزاي بتتحسب الحجوزات والمبالغ المصروفة؟', en: 'How are bookings and spending amounts calculated?', es: '¿Cómo se calculan las reservas y los gastos?', tr: 'Rezervasyonlar ve harcamalar nasıl hesaplanır?',
              id: 'Bagaimana pemesanan dan jumlah pengeluaran dihitung?', hi: 'बुकिंग और खर्च की गणना कैसे होती है?', ur: 'بکنگز اور اخراجات کیسے شمار ہوتے ہیں؟', fr: 'Comment sont calculées les réservations et les dépenses ?', bn: 'বুকিং ও ব্যয়ের পরিমাণ কীভাবে গণনা করা হয়?'),
          a: _t3(context, ar: 'بنحسب بس الحجوزات المؤكدة والمكتملة فعليًا (مش الملغاة)، بناءً على قيمة الحجز الإجمالية وقت الدفع.',
              en: 'Only confirmed, completed bookings count (not cancelled ones), based on the total booking value at the time of payment.',
              es: 'Solo cuentan las reservas confirmadas y completadas (no las canceladas), según el valor total al momento del pago.',
              tr: 'Yalnızca onaylanmış ve tamamlanmış rezervasyonlar sayılır (iptal edilenler değil), ödeme anındaki toplam rezervasyon tutarına göre.',
              id: 'Hanya pemesanan yang dikonfirmasi dan selesai yang dihitung (bukan yang dibatalkan), berdasarkan nilai total pemesanan saat pembayaran.',
              hi: 'केवल पुष्ट और पूर्ण बुकिंग ही गिनी जाती हैं (रद्द नहीं), भुगतान के समय कुल बुकिंग मूल्य के आधार पर।',
              ur: 'صرف تصدیق شدہ اور مکمل بکنگز شمار ہوتی ہیں (منسوخ شدہ نہیں)، ادائیگی کے وقت کل بکنگ ویلیو کی بنیاد پر۔',
              fr: 'Seules les réservations confirmées et terminées comptent (pas les réservations annulées), sur la base de la valeur totale au moment du paiement.',
              bn: 'শুধুমাত্র নিশ্চিত ও সম্পন্ন বুকিং গণনা করা হয় (বাতিল করা নয়), পেমেন্টের সময় মোট বুকিং মূল্যের ভিত্তিতে।'),
          ),
          (
          q: _t3(context, ar: 'هيحصل إيه لو ألغيت حجز اتحسب في تقدّمي للترقية؟', en: 'What happens if I cancel a booking that was already calculated into my upgrade progress?', es: '¿Qué pasa si cancelo una reserva que ya se contó en mi progreso?', tr: 'Yükseltme ilerlememe dahil edilmiş bir rezervasyonu iptal edersem ne olur?',
              id: 'Apa yang terjadi jika saya membatalkan pemesanan yang sudah dihitung dalam progres upgrade saya?', hi: 'अगर मैं वह बुकिंग रद्द कर दूं जो पहले से मेरी अपग्रेड प्रगति में गिनी गई थी तो क्या होगा?', ur: 'اگر میں وہ بکنگ منسوخ کر دوں جو پہلے سے میری اپ گریڈ پیش رفت میں شمار ہو چکی ہے تو کیا ہوگا؟', fr: 'Que se passe-t-il si j\'annule une réservation déjà comptée dans ma progression ?', bn: 'যদি আমি এমন একটি বুকিং বাতিল করি যা ইতিমধ্যে আমার আপগ্রেড অগ্রগতিতে গণনা করা হয়েছে তাহলে কী হবে?'),
          a: _t3(context, ar: 'بيتشال تأثيرها من إجمالي تقدّمك تلقائيًا، وممكن يرجّعك لمستوى أقل لو كنت معتمد عليها في الترقية.',
              en: 'Its contribution is automatically removed from your total progress, which may drop you back a tier if you relied on it to upgrade.',
              es: 'Su contribución se elimina automáticamente de tu progreso total, lo que podría bajarte de nivel si dependías de ella.',
              tr: 'Katkısı toplam ilerlemenizden otomatik olarak çıkarılır; yükseltme için ona bağlıysanız bu sizi bir alt seviyeye düşürebilir.',
              id: 'Kontribusinya otomatis dihapus dari total progres Anda, yang dapat menurunkan tingkat Anda jika Anda bergantung padanya untuk naik tingkat.',
              hi: 'इसका योगदान आपकी कुल प्रगति से स्वतः हटा दिया जाता है, जो अगर आप इस पर निर्भर थे तो आपको निचले स्तर पर ला सकता है।',
              ur: 'اس کا حصہ خودکار طور پر آپ کی کل پیش رفت سے ہٹا دیا جاتا ہے، جو اگر آپ اس پر انحصار کر رہے تھے تو آپ کو نچلے ٹیئر پر لے جا سکتا ہے۔',
              fr: 'Sa contribution est automatiquement retirée de votre progression totale, ce qui peut vous faire redescendre d\'un niveau si vous en dépendiez.',
              bn: 'এর অবদান স্বয়ংক্রিয়ভাবে আপনার মোট অগ্রগতি থেকে সরিয়ে ফেলা হয়, যা আপনাকে নিম্ন স্তরে নামিয়ে দিতে পারে যদি আপগ্রেডের জন্য এটির উপর নির্ভর করে থাকেন।'),
          ),
        ];
      case 1: // Member Rewards
        return [
          (
          q: _t3(context, ar: 'إزاي أستخدم مزايا مستواي؟', en: 'How do I use my tier perks?', es: '¿Cómo uso las ventajas de mi nivel?', tr: 'Seviye avantajlarımı nasıl kullanırım?',
              id: 'Bagaimana cara menggunakan keuntungan tingkat saya?', hi: 'मैं अपने स्तर के लाभ कैसे उपयोग करूं?', ur: 'میں اپنے ٹیئر کے فوائد کیسے استعمال کروں؟', fr: 'Comment utiliser les avantages de mon niveau ?', bn: 'আমি কীভাবে আমার স্তরের সুবিধা ব্যবহার করব?'),
          a: _t3(context, ar: 'المزايا (زي صالة كبار الشخصيات وترقيات النقل) بتتفعّل تلقائيًا وقت الحجز حسب مستواك الحالي، من غير أي خطوة إضافية منك.',
              en: 'Perks (like lounge access and transfer upgrades) are applied automatically at booking based on your current tier — no extra steps needed.',
              es: 'Las ventajas (como acceso a sala VIP y mejoras de traslado) se aplican automáticamente al reservar según tu nivel actual, sin pasos adicionales.',
              tr: 'Avantajlar (VIP salon erişimi ve transfer yükseltmeleri gibi) rezervasyon sırasında mevcut seviyenize göre otomatik olarak uygulanır, ekstra adım gerekmez.',
              id: 'Keuntungan (seperti akses lounge dan peningkatan antar-jemput) diterapkan secara otomatis saat pemesanan sesuai tingkat Anda saat ini — tanpa langkah tambahan.',
              hi: 'लाभ (जैसे लाउंज एक्सेस और ट्रांसफर अपग्रेड) आपके वर्तमान स्तर के आधार पर बुकिंग के समय स्वतः लागू हो जाते हैं — कोई अतिरिक्त कदम नहीं चाहिए।',
              ur: 'فوائد (جیسے لاؤنج تک رسائی اور ٹرانسفر اپ گریڈز) آپ کے موجودہ ٹیئر کی بنیاد پر بکنگ کے وقت خودکار طور پر لاگو ہوتے ہیں — کوئی اضافی قدم درکار نہیں۔',
              fr: 'Les avantages (comme l\'accès au salon et les surclassements de transfert) sont appliqués automatiquement lors de la réservation selon votre niveau actuel — aucune étape supplémentaire.',
              bn: 'সুবিধা (যেমন লাউঞ্জ অ্যাক্সেস ও ট্রান্সফার আপগ্রেড) আপনার বর্তমান স্তরের ভিত্তিতে বুকিংয়ের সময় স্বয়ংক্রিয়ভাবে প্রয়োগ হয় — কোনো অতিরিক্ত পদক্ষেপ প্রয়োজন নেই।'),
          ),
          (
          q: _t3(context, ar: 'هل المزايا بتنتهي صلاحيتها؟', en: 'Do perks expire?', es: '¿Las ventajas caducan?', tr: 'Avantajların süresi doluyor mu?',
              id: 'Apakah keuntungan memiliki masa berlaku?', hi: 'क्या लाभ समाप्त हो जाते हैं?', ur: 'کیا فوائد کی میعاد ختم ہوتی ہے؟', fr: 'Les avantages expirent-ils ?', bn: 'সুবিধাগুলোর মেয়াদ কি শেষ হয়ে যায়?'),
          a: _t3(context, ar: 'المزايا مرتبطة بمستواك الحالي، فطالما محتفظ بيه، مزاياك تفضل متاحة طول العام.',
              en: 'Perks are tied to your current tier — as long as you keep it, your perks remain available throughout the year.',
              es: 'Las ventajas están vinculadas a tu nivel actual; mientras lo mantengas, seguirán disponibles durante todo el año.',
              tr: 'Avantajlar mevcut seviyenize bağlıdır; onu korudukça avantajlarınız yıl boyunca kullanılabilir kalır.',
              id: 'Keuntungan terikat pada tingkat Anda saat ini — selama Anda mempertahankannya, keuntungan Anda tetap tersedia sepanjang tahun.',
              hi: 'लाभ आपके वर्तमान स्तर से जुड़े होते हैं — जब तक आप इसे बनाए रखते हैं, आपके लाभ पूरे साल उपलब्ध रहते हैं।',
              ur: 'فوائد آپ کے موجودہ ٹیئر سے منسلک ہیں — جب تک آپ اسے برقرار رکھیں، آپ کے فوائد سال بھر دستیاب رہتے ہیں۔',
              fr: 'Les avantages sont liés à votre niveau actuel — tant que vous le conservez, vos avantages restent disponibles toute l\'année.',
              bn: 'সুবিধাগুলো আপনার বর্তমান স্তরের সাথে যুক্ত — যতক্ষণ আপনি এটি বজায় রাখেন, আপনার সুবিধা সারা বছর উপলব্ধ থাকে।'),
          ),
        ];
      case 2: // Coins
        return [
          (
          q: _t3(context, ar: 'إزاي أكسب عملات؟', en: 'How do I earn coins?', es: '¿Cómo gano monedas?', tr: 'Puanları nasıl kazanırım?',
              id: 'Bagaimana cara mendapatkan koin?', hi: 'मैं कॉइन कैसे कमाऊं?', ur: 'میں کوائنز کیسے کماؤں؟', fr: 'Comment gagner des points ?', bn: 'কীভাবে কয়েন অর্জন করব?'),
          a: _t3(context, ar: 'بتكسب عملات تلقائيًا مقابل كل حجز مكتمل عبر SkyNoom، والنسبة بتزيد كل ما مستواك يعلى.',
              en: 'You earn coins automatically for every completed booking through SkyNoom, and the earning rate increases as your tier goes up.',
              es: 'Ganas monedas automáticamente por cada reserva completada en SkyNoom, y la tasa aumenta con tu nivel.',
              tr: 'SkyNoom üzerinden tamamlanan her rezervasyon için otomatik olarak puan kazanırsınız ve seviyeniz yükseldikçe kazanım oranı artar.',
              id: 'Anda mendapatkan koin secara otomatis untuk setiap pemesanan yang selesai melalui SkyNoom, dan tingkat perolehannya meningkat seiring naiknya tingkat Anda.',
              hi: 'SkyNoom के ज़रिए हर पूर्ण बुकिंग पर आप स्वतः कॉइन कमाते हैं, और आपका स्तर बढ़ने के साथ अर्जन दर भी बढ़ती है।',
              ur: 'SkyNoom کے ذریعے ہر مکمل بکنگ پر آپ خودکار طور پر کوائنز کماتے ہیں، اور آپ کا ٹیئر بڑھنے کے ساتھ کمانے کی شرح بھی بڑھتی ہے۔',
              fr: 'Vous gagnez automatiquement des points pour chaque réservation terminée via SkyNoom, et le taux de gain augmente avec votre niveau.',
              bn: 'SkyNoom-এর মাধ্যমে প্রতিটি সম্পন্ন বুকিংয়ের জন্য আপনি স্বয়ংক্রিয়ভাবে কয়েন অর্জন করেন, এবং আপনার স্তর বাড়ার সাথে সাথে অর্জনের হারও বাড়ে।'),
          ),
          (
          q: _t3(context, ar: 'إزاي أستخدم عملاتي؟', en: 'How do I redeem my coins?', es: '¿Cómo canjeo mis monedas?', tr: 'Puanlarımı nasıl kullanırım?',
              id: 'Bagaimana cara menukarkan koin saya?', hi: 'मैं अपने कॉइन कैसे भुनाऊं?', ur: 'میں اپنے کوائنز کیسے استعمال کروں؟', fr: 'Comment utiliser mes points ?', bn: 'কীভাবে আমার কয়েন ব্যবহার করব?'),
          a: _t3(context, ar: 'العملات هتبقى قابلة للاستبدال بخصومات على حجوزاتك الجاية بمجرد ما ميزة الاستبدال تتفعّل بالكامل.',
              en: 'Coins will be redeemable for discounts on future bookings once the redemption feature is fully activated.',
              es: 'Las monedas se podrán canjear por descuentos en futuras reservas una vez que la función de canje esté totalmente activada.',
              tr: 'İtfa özelliği tam olarak etkinleştirildiğinde puanlar gelecekteki rezervasyonlarda indirim için kullanılabilir olacaktır.',
              id: 'Koin akan dapat ditukarkan dengan diskon untuk pemesanan mendatang setelah fitur penukaran sepenuhnya diaktifkan.',
              hi: 'रिडेम्पशन सुविधा पूरी तरह सक्रिय होते ही कॉइन भविष्य की बुकिंग पर छूट के लिए भुनाए जा सकेंगे।',
              ur: 'ری ڈیمپشن فیچر مکمل طور پر فعال ہونے کے بعد کوائنز مستقبل کی بکنگز پر رعایت کے لیے استعمال کیے جا سکیں گے۔',
              fr: 'Les points pourront être échangés contre des réductions sur vos futures réservations une fois la fonction d\'échange pleinement activée.',
              bn: 'রিডেম্পশন ফিচার সম্পূর্ণরূপে সক্রিয় হওয়ার পর ভবিষ্যতের বুকিংয়ে ছাড়ের জন্য কয়েন ব্যবহার করা যাবে।'),
          ),
        ];
      default: // Terms & Conditions
        return [
          (
          q: _t3(context, ar: 'أين أجد الشروط الكاملة؟', en: 'Where can I find the full terms?', es: '¿Dónde encuentro los términos completos?', tr: 'Tam şartları nerede bulabilirim?',
              id: 'Di mana saya bisa menemukan syarat lengkap?', hi: 'मुझे पूरी शर्तें कहाँ मिलेंगी?', ur: 'مکمل شرائط کہاں ملیں گی؟', fr: 'Où puis-je trouver les conditions complètes ?', bn: 'সম্পূর্ণ শর্তাবলী কোথায় পাব?'),
          a: _t3(context, ar: 'برنامج المكافآت لسه في مرحلة التطوير، والشروط والأحكام التفصيلية هتُنشر بشكل رسمي قبل الإطلاق الكامل للميزة.',
              en: 'The rewards program is still in development, and the detailed terms and conditions will be published officially before the feature\'s full launch.',
              es: 'El programa de recompensas aún está en desarrollo, y los términos y condiciones detallados se publicarán oficialmente antes del lanzamiento completo.',
              tr: 'Ödül programı hâlâ geliştirme aşamasındadır; ayrıntılı şartlar ve koşullar, özelliğin tam lansmanından önce resmi olarak yayınlanacaktır.',
              id: 'Program hadiah masih dalam pengembangan, dan syarat serta ketentuan lengkap akan dipublikasikan secara resmi sebelum peluncuran penuh fitur ini.',
              hi: 'रिवॉर्ड्स प्रोग्राम अभी विकासाधीन है, और विस्तृत नियम व शर्तें फीचर के पूर्ण लॉन्च से पहले आधिकारिक रूप से प्रकाशित की जाएंगी।',
              ur: 'انعامی پروگرام ابھی ترقی کے مرحلے میں ہے، اور تفصیلی شرائط و ضوابط فیچر کے مکمل لانچ سے پہلے باضابطہ طور پر شائع کی جائیں گی۔',
              fr: 'Le programme de récompenses est encore en développement, et les conditions générales détaillées seront publiées officiellement avant le lancement complet de la fonctionnalité.',
              bn: 'পুরস্কার প্রোগ্রামটি এখনও উন্নয়নাধীন, এবং বিস্তারিত শর্তাবলী ফিচারের সম্পূর্ণ লঞ্চের আগে আনুষ্ঠানিকভাবে প্রকাশিত হবে।'),
          ),
        ];
    }
  }

  @override
  Widget build(BuildContext context) {
    final labels = _tabLabels(context);
    final faqs = _faqsFor(context, _activeTab);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          _t3(context, ar: 'الأسئلة الشائعة', en: 'FAQs', es: 'Preguntas frecuentes', tr: 'Sıkça Sorulan Sorular',
              id: 'FAQ', hi: 'सामान्य प्रश्न', ur: 'اکثر پوچھے گئے سوالات', fr: 'FAQ', bn: 'প্রশ্নোত্তর'),
          textAlign: TextAlign.center,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
        ),
        const SizedBox(height: AppSizes.md),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(labels.length, (index) {
              final isActive = index == _activeTab;
              return Padding(
                padding: const EdgeInsetsDirectional.only(end: AppSizes.sm),
                child: GestureDetector(
                  onTap: () => setState(() => _activeTab = index),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: isActive ? AppColors.primaryDark : AppColors.background,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      labels[index],
                      style: TextStyle(
                        color: isActive ? Colors.white : AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
        const SizedBox(height: AppSizes.md),
        if (_activeTab == 0) ...[
          Text(
            _t3(
              context,
              ar: 'يوجد حاليًا 4 مستويات في برنامج SkyNoom Rewards: فضي، ذهبي، بلاتيني، وماسي. كل ما تحجز أكتر، كل ما ترتقي لمستوى أعلى ومكافآت أكبر.',
              en: 'There are currently 4 SkyNoom Rewards tiers: Silver, Gold, Platinum, and Diamond. More bookings, higher tiers, greater rewards.',
              es: 'Actualmente hay 4 niveles en SkyNoom Rewards: Plata, Oro, Platino y Diamante. Más reservas, niveles más altos, mayores recompensas.',
              tr: 'Şu anda 4 SkyNoom Rewards seviyesi bulunmaktadır: Gümüş, Altın, Platin ve Elmas. Daha fazla rezervasyon, daha yüksek seviye, daha büyük ödüller.',
              id: 'Saat ini ada 4 tingkat SkyNoom Rewards: Perak, Emas, Platinum, dan Berlian. Semakin banyak pemesanan, semakin tinggi tingkat, semakin besar hadiah.',
              hi: 'वर्तमान में SkyNoom Rewards के 4 स्तर हैं: सिल्वर, गोल्ड, प्लैटिनम और डायमंड। जितनी अधिक बुकिंग, उतना ऊँचा स्तर, उतना बड़ा रिवॉर्ड।',
              ur: 'اس وقت SkyNoom Rewards کے 4 ٹیئرز ہیں: سلور، گولڈ، پلاٹینم، اور ڈائمنڈ۔ جتنی زیادہ بکنگز، اتنا بلند ٹیئر، اتنا بڑا انعام۔',
              fr: 'Il existe actuellement 4 niveaux SkyNoom Rewards : Argent, Or, Platine et Diamant. Plus de réservations, niveaux plus élevés, récompenses plus importantes.',
              bn: 'বর্তমানে ৪টি SkyNoom Rewards স্তর রয়েছে: সিলভার, গোল্ড, প্ল্যাটিনাম, এবং ডায়মন্ড। বেশি বুকিং, উঁচু স্তর, বড় পুরস্কার।',
            ),
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppSizes.md),
          Row(
            children: [
              _TierBadgeStep(label: 'Silver', color: Colors.blueGrey, showArrow: true),
              _TierBadgeStep(label: 'Gold', color: Colors.amber.shade800, showArrow: true),
              _TierBadgeStep(label: 'Platinum', color: Colors.blue.shade700, showArrow: true),
              _TierBadgeStep(label: 'Diamond', color: Colors.purple.shade700, showArrow: false),
            ],
          ),
          const SizedBox(height: AppSizes.md),
        ],
        ...faqs.map((faq) => _FaqTile(question: faq.q, answer: faq.a)),
      ],
    );
  }
}

class _TierBadgeStep extends StatelessWidget {
  final String label;
  final Color color;
  final bool showArrow;
  const _TierBadgeStep({required this.label, required this.color, required this.showArrow});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: AppSizes.md),
        decoration: BoxDecoration(color: color.withOpacity(0.08)),
        child: Column(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: color.withOpacity(0.15),
              child: Icon(Icons.workspace_premium, color: color, size: 18),
            ),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}

class _FaqTile extends StatefulWidget {
  final String question;
  final String answer;
  const _FaqTile({required this.question, required this.answer});

  @override
  State<_FaqTile> createState() => _FaqTileState();
}

class _FaqTileState extends State<_FaqTile> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        InkWell(
          onTap: () => setState(() => _expanded = !_expanded),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSizes.sm),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    widget.question,
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                ),
                Icon(_expanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down),
              ],
            ),
          ),
        ),
        if (_expanded)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSizes.sm),
            child: Text(
              widget.answer,
              style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.4),
            ),
          ),
        const Divider(height: 1),
      ],
    );
  }
}
