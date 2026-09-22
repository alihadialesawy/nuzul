import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../core/widgets/rating_badge.dart';
import '../../core/widgets/price_text.dart';
import '../../core/widgets/app_footer.dart';
import '../../core/widgets/app_banner.dart';
import '../../data/models/hotel_model.dart';
import '../../data/models/selected_room.dart';
import '../../localization/app_localizations.dart';
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

/// معرّف نوع الغرفة، تُستخدم للحصول على النص المترجم عبر AppLocalizations
/// وربطه بمعامل السعر (multiplier) على سعر الليلة الأساسي للفندق.
enum RoomTypeId { queen, king, studioSuite }

class RoomOption {
  final RoomTypeId id;
  final IconData icon;
  final double priceMultiplier;
  final bool breakfastIncluded;
  final bool freeCancellation;

  const RoomOption({
    required this.id,
    required this.icon,
    required this.priceMultiplier,
    this.breakfastIncluded = false,
    this.freeCancellation = false,
  });

  String label(AppLocalizations l10n) {
    switch (id) {
      case RoomTypeId.queen:
        return l10n.roomQueen;
      case RoomTypeId.king:
        return l10n.roomKing;
      case RoomTypeId.studioSuite:
        return l10n.roomStudioSuite;
    }
  }
}

const List<RoomOption> _roomOptions = [
  RoomOption(
    id: RoomTypeId.queen,
    icon: Icons.bed_outlined,
    priceMultiplier: 1.0,
    freeCancellation: true,
  ),
  RoomOption(
    id: RoomTypeId.king,
    icon: Icons.king_bed_outlined,
    priceMultiplier: 1.2,
    breakfastIncluded: true,
    freeCancellation: true,
  ),
  RoomOption(
    id: RoomTypeId.studioSuite,
    icon: Icons.weekend_outlined,
    priceMultiplier: 1.8,
    breakfastIncluded: true,
  ),
];

class HotelDetailsPage extends ConsumerStatefulWidget {
  final HotelModel hotel;
  final DateTime checkIn;
  final DateTime checkOut;
  final int guests;

  const HotelDetailsPage({
    super.key,
    required this.hotel,
    required this.checkIn,
    required this.checkOut,
    required this.guests,
  });

  @override
  ConsumerState<HotelDetailsPage> createState() => _HotelDetailsPageState();
}

class _HotelDetailsPageState extends ConsumerState<HotelDetailsPage> {
  // كمية كل نوع غرفة (شكل جدول بوكينج). يدعم اختيار أكتر من نوع غرفة
  // في نفس الوقت -- الضغط على أي زر "I'll reserve" يجمع كل الغرف
  // المختارة بكمية أكبر من صفر في حجز واحد.
  late List<int> _quantities = List.filled(_roomOptions.length, 0);

  void _onQuantityChanged(int index, int quantity) {
    setState(() {
      _quantities[index] = quantity;
    });
  }

  Future<void> _reserveSelectedRooms() async {
    final l10n = AppLocalizations.of(context)!;

    final selectedRooms = <SelectedRoom>[
      for (var i = 0; i < _roomOptions.length; i++)
        if (_quantities[i] > 0)
          SelectedRoom(
            label: _roomOptions[i].label(l10n),
            pricePerNight: widget.hotel.pricePerNight * _roomOptions[i].priceMultiplier,
            quantity: _quantities[i],
          ),
    ];

    if (selectedRooms.isEmpty) return;

    // تسجيل الدخول مطلوب فقط عند خطوة الحجز الفعلية، وليس عند تصفح التفاصيل
    final user = ref.read(currentUserProvider);
    if (user == null) {
      await context.push(AppRoutes.login);
      if (!context.mounted) return;
    }

    context.push(
      AppRoutes.booking,
      extra: {
        'hotel': widget.hotel,
        'checkIn': widget.checkIn,
        'checkOut': widget.checkOut,
        'guests': widget.guests,
        'selectedRooms': selectedRooms,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final hotel = widget.hotel;

    return Scaffold(
      appBar: const AppBanner(),
      // LayoutBuilder عشان نحدد عرض أقصى للمحتوى على الشاشات العريضة
      // (ويندوز/ويب)، بنفس منطق صفحة المجتمع والملف الشخصي -- بدونها،
      // صورة الفندق الرئيسية (اللي كانت بارتفاع ثابت 200 بكسل) بتمتد
      // على عرض الشاشة كامل (~1900 بكسل على ويندوز)، فنسبة العرض
      // للارتفاع بتبقى ضيقة جدًا وطويلة جدًا (~9.5:1)، فيحصل قص شديد
      // ومشوّه للصورة. AspectRatio(16:9) كمان بيضمن نسبة طبيعية
      // للصورة مهما كان عرض الحاوية، بدل ارتفاع ثابت بالبكسل.
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
                  padding: const EdgeInsets.all(AppSizes.md),
                  children: [
                    // صورة الفندق
                    ClipRRect(
                      borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                      child: AspectRatio(
                        aspectRatio: 16 / 9,
                        child: Container(
                          color: AppColors.divider,
                          child: hotel.images.isNotEmpty
                              ? Image.network(
                            hotel.images.first,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                            const Icon(Icons.hotel, size: 48, color: AppColors.textHint),
                          )
                              : const Icon(Icons.hotel, size: 48, color: AppColors.textHint),
                        ),
                      ),
                    ),

                    const SizedBox(height: AppSizes.md),

                    Text(
                      hotel.name,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.location_on_outlined, size: 18, color: AppColors.textSecondary),
                        const SizedBox(width: 4),
                        Text(hotel.city, style: const TextStyle(color: AppColors.textSecondary)),
                      ],
                    ),
                    const SizedBox(height: AppSizes.sm),
                    RatingBadge(
                      rating: hotel.rating,
                      reviewCount: hotel.reviewCount,
                    ),

                    const SizedBox(height: AppSizes.lg),

                    // قسم أنواع الغرف - شكل جدول (Room type / Today's Price / Your choices / Select Rooms)
                    Text(
                      l10n.roomTypeSectionTitle,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: AppSizes.sm),
                    _RoomTypesTable(
                      roomOptions: _roomOptions,
                      hotel: hotel,
                      l10n: l10n,
                      quantities: _quantities,
                      onQuantityChanged: _onQuantityChanged,
                      onReserve: _reserveSelectedRooms,
                    ),

                    const SizedBox(height: AppSizes.lg),

                    // قسم أشهر المرافق
                    if (hotel.amenities.isNotEmpty) ...[
                      Text(
                        _amenitiesSectionTitle(context),
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(height: AppSizes.sm),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(AppSizes.md),
                          child: Builder(
                            builder: (context) {
                              final amenities = hotel.amenities
                                  .map((raw) => _parseAmenity(context, raw))
                                  .toList();

                              final rows = <Widget>[];
                              for (var i = 0; i < amenities.length; i += 2) {
                                final second = i + 1 < amenities.length ? amenities[i + 1] : null;
                                rows.add(
                                  Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 6),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Expanded(child: _AmenityTile(amenity: amenities[i])),
                                        const SizedBox(width: AppSizes.sm),
                                        Expanded(
                                          child: second != null
                                              ? _AmenityTile(amenity: second)
                                              : const SizedBox.shrink(),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }

                              return Column(children: rows);
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSizes.lg),
                    ],

                    // قسم عن المنطقة المحيطة
                    Text(
                      l10n.aboutAreaTitle,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: AppSizes.sm),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(AppSizes.md),
                        child: Text(
                          l10n.aboutAreaDescription(hotel.city),
                          style: const TextStyle(color: AppColors.textSecondary, height: 1.5),
                        ),
                      ),
                    ),

                    const SizedBox(height: AppSizes.md),

                    ..._areaHighlightCategories(context).map(
                          (category) => _AreaCategorySection(category: category),
                    ),

                    const SizedBox(height: AppSizes.md),
                    const _PoliciesSection(),

                    const AppFooter(),
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

/// جدول أنواع الغرف بشكل يشبه Booking.com: عمود لنوع الغرفة مع مواصفاته،
/// عمود للسعر، عمود لما يتضمنه الاختيار (إفطار/إلغاء مجاني...)، وعمود
/// لاختيار الكمية مع زر حجز مخصص لكل صف.
class _RoomTypesTable extends StatelessWidget {
  final List<RoomOption> roomOptions;
  final dynamic hotel;
  final AppLocalizations l10n;
  final List<int> quantities;
  final void Function(int index, int quantity) onQuantityChanged;
  final VoidCallback onReserve;

  const _RoomTypesTable({
    required this.roomOptions,
    required this.hotel,
    required this.l10n,
    required this.quantities,
    required this.onQuantityChanged,
    required this.onReserve,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.divider),
        borderRadius: BorderRadius.circular(AppSizes.radiusSm),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // رأس الجدول
          Container(
            color: AppColors.primary,
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: AppSizes.sm),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Text(
                    _t3(context, ar: 'نوع الغرفة', en: 'Room type', es: 'Tipo de habitación', tr: 'Oda Tipi', id: 'Tipe Kamar',
                        hi: 'कमरे का प्रकार',
                        ur: 'کمرے کی قسم',
                        fr: 'Type de chambre',
                        bn: 'রুমের ধরন'),
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    _t3(context, ar: 'السعر اليوم', en: "Today's Price", es: 'Precio de hoy', tr: 'Bugünkü Fiyat', id: 'Harga Hari Ini',
                        hi: 'आज की कीमत',
                        ur: 'آج کی قیمت',
                        fr: 'Prix du jour',
                        bn: 'আজকের মূল্য'),
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Text(
                    _t3(context, ar: 'خياراتك', en: 'Your choices', es: 'Tus opciones', tr: 'Seçenekleriniz', id: 'Pilihan Anda',
                        hi: 'आपके विकल्प',
                        ur: 'آپ کے اختیارات',
                        fr: 'Vos options',
                        bn: 'আপনার পছন্দ'),
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    _t3(context, ar: 'اختر الغرف', en: 'Select Rooms', es: 'Selecciona habitaciones', tr: 'Oda Seçin', id: 'Pilih Kamar',
                        hi: 'कमरे चुनें',
                        ur: 'کمرے منتخب کریں',
                        fr: 'Choisir les chambres',
                        bn: 'রুম নির্বাচন করুন'),
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
          // صفوف الغرف
          ...List.generate(roomOptions.length, (index) {
            final room = roomOptions[index];
            final price = hotel.pricePerNight * room.priceMultiplier;
            final isLast = index == roomOptions.length - 1;

            return Container(
              decoration: BoxDecoration(
                border: isLast
                    ? null
                    : const Border(bottom: BorderSide(color: AppColors.divider)),
              ),
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: AppSizes.sm),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // عمود نوع الغرفة
                  Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(room.icon, size: 18, color: AppColors.primary),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                room.label(l10n),
                                style: const TextStyle(fontWeight: FontWeight.w600),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // عمود السعر
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        PriceText(
                          sarAmount: price,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          l10n.perNight,
                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  // عمود خياراتك
                  Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (room.breakfastIncluded)
                          _ChoiceLine(
                            icon: Icons.free_breakfast_outlined,
                            text: _t3(context, ar: 'إفطار متضمّن', en: 'Breakfast included', es: 'Desayuno incluido', tr: 'Kahvaltı dahil', id: 'Termasuk sarapan',
                                hi: 'नाश्ता शामिल',
                                ur: 'ناشتہ شامل',
                                fr: 'Petit-déjeuner inclus',
                                bn: 'নাস্তা অন্তর্ভুক্ত'),
                            color: AppColors.primary,
                          ),
                        _ChoiceLine(
                          icon: Icons.wifi,
                          text: _t3(context, ar: 'إنترنت عالي السرعة', en: 'High-speed internet', es: 'Internet de alta velocidad', tr: 'Yüksek hızlı internet', id: 'Internet berkecepatan tinggi',
                              hi: 'हाई-स्पीड इंटरनेट',
                              ur: 'ہائی اسپیڈ انٹرنیٹ',
                              fr: 'Internet haut débit',
                              bn: 'হাই-স্পিড ইন্টারনেট'),
                          color: AppColors.primary,
                        ),
                        _ChoiceLine(
                          icon: room.freeCancellation
                              ? Icons.check_circle_outline
                              : Icons.cancel_outlined,
                          text: room.freeCancellation
                              ? _t3(context, ar: 'إلغاء مجاني', en: 'Free cancellation', es: 'Cancelación gratuita', tr: 'Ücretsiz iptal', id: 'Pembatalan gratis',
                              hi: 'मुफ़्त रद्दीकरण',
                              ur: 'مفت منسوخی',
                              fr: 'Annulation gratuite',
                              bn: 'বিনামূল্যে বাতিলকরণ')
                              : _t3(context, ar: 'إجمالي تكلفة الإلغاء', en: 'Total cost to cancel', es: 'Costo total de cancelación', tr: 'İptal için tam ücret', id: 'Biaya penuh jika dibatalkan',
                              hi: 'रद्द करने पर पूरा शुल्क',
                              ur: 'منسوخی پر مکمل چارج',
                              fr: 'Coût total en cas d\'annulation',
                              bn: 'বাতিলের সম্পূর্ণ খরচ'),
                          color: room.freeCancellation ? AppColors.primary : AppColors.textHint,
                        ),
                      ],
                    ),
                  ),
                  // عمود اختيار الكمية + زر الحجز
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        DropdownButton<int>(
                          value: quantities[index],
                          isExpanded: true,
                          items: List.generate(
                            4,
                                (q) => DropdownMenuItem(value: q, child: Text('$q')),
                          ),
                          onChanged: (value) {
                            if (value != null) onQuantityChanged(index, value);
                          },
                        ),
                        const SizedBox(height: 6),
                        ElevatedButton(
                          onPressed: quantities[index] > 0 ? onReserve : null,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                          ),
                          child: Text(
                            _t3(context, ar: 'احجز', en: "I'll reserve", es: 'Reservar', tr: 'Rezervasyon Yap', id: 'Pesan',
                                hi: 'बुक करें',
                                ur: 'بک کریں',
                                fr: 'Réserver',
                                bn: 'বুক করুন'),
                            style: const TextStyle(fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _ChoiceLine extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;
  const _ChoiceLine({required this.icon, required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 12, color: color),
            ),
          ),
        ],
      ),
    );
  }
}

/// عنوان قسم "أشهر المرافق".
String _amenitiesSectionTitle(BuildContext context) {
  return _t3(context, ar: 'أشهر المرافق', en: 'Most Popular Amenities', es: 'Comodidades más populares', tr: 'En Popüler Olanaklar', id: 'Fasilitas Terpopuler',
      hi: 'सबसे लोकप्रिय सुविधाएं',
      ur: 'مقبول ترین سہولیات',
      fr: 'Équipements les plus populaires',
      bn: 'সবচেয়ে জনপ্রিয় সুবিধা');
}

class _Amenity {
  final IconData icon;
  final String label;
  const _Amenity(this.icon, this.label);
}

class _AmenityTile extends StatelessWidget {
  final _Amenity amenity;
  const _AmenityTile({required this.amenity});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(amenity.icon, size: 20, color: AppColors.primary),
        const SizedBox(width: AppSizes.sm),
        Expanded(
          child: Text(
            amenity.label,
            style: const TextStyle(fontSize: 13),
          ),
        ),
      ],
    );
  }
}

/// يحوّل مفتاح المرفق المخزّن في قاعدة البيانات (مثل "free_wifi" أو
/// "restaurants:2") إلى أيقونة ونص مترجم مناسب (كل اللغات التسع). أي مفتاح
/// غير معروف يُعرض كنص خام مع أيقونة عامة، عشان أي مرفق جديد يضاف لاحقًا
/// يفضل يظهر حتى لو معندوش أيقونة مخصصة بعد.
_Amenity _parseAmenity(BuildContext context, String raw) {
  final parts = raw.split(':');
  final key = parts.first.trim();
  final extra = parts.length > 1 ? parts[1].trim() : null;

  switch (key) {
    case 'non_smoking_rooms':
      return _Amenity(
        Icons.smoke_free,
        _t3(context, ar: 'غرف لغير المدخنين', en: 'Non-smoking rooms', es: 'Habitaciones para no fumadores', tr: 'Sigara içilmeyen odalar', id: 'Kamar bebas rokok',
            hi: 'धूम्रपान-मुक्त कमरे',
            ur: 'تمباکو نوشی سے پاک کمرے',
            fr: 'Chambres non-fumeurs',
            bn: 'ধূমপানমুক্ত রুম'),
      );
    case 'fitness_center':
      return _Amenity(
        Icons.fitness_center,
        _t3(context, ar: 'مركز لياقة بدنية', en: 'Fitness center', es: 'Centro de fitness', tr: 'Fitness merkezi', id: 'Pusat kebugaran',
            hi: 'फिटनेस सेंटर',
            ur: 'فٹنس سینٹر',
            fr: 'Salle de sport',
            bn: 'ফিটনেস সেন্টার'),
      );
    case 'free_wifi':
      return _Amenity(
        Icons.wifi,
        _t3(context, ar: 'واي فاي مجاني', en: 'Free WiFi', es: 'WiFi gratis', tr: 'Ücretsiz WiFi', id: 'WiFi gratis',
            hi: 'मुफ़्त वाई-फाई',
            ur: 'مفت وائی فائی',
            fr: 'WiFi gratuit',
            bn: 'ফ্রি ওয়াইফাই'),
      );
    case 'disabled_facilities':
      return _Amenity(
        Icons.accessible,
        _t3(context, ar: 'مرافق لذوي الاحتياجات الخاصة', en: 'Facilities for disabled guests', es: 'Instalaciones para personas con discapacidad', tr: 'Engelli konuklar için olanaklar', id: 'Fasilitas untuk tamu difabel',
            hi: 'दिव्यांग मेहमानों के लिए सुविधाएं',
            ur: 'معذور مہمانوں کے لیے سہولیات',
            fr: 'Installations pour personnes handicapées',
            bn: 'প্রতিবন্ধী অতিথিদের জন্য সুবিধা'),
      );
    case 'restaurants':
      final count = int.tryParse(extra ?? '') ?? 1;
      final label = _t3(
        context,
        ar: count == 1 ? 'مطعم واحد' : '$count مطاعم',
        en: count == 1 ? '1 restaurant' : '$count restaurants',
        es: count == 1 ? '1 restaurante' : '$count restaurantes',
        tr: count == 1 ? '1 restoran' : '$count restoran',
        id: count == 1 ? '1 restoran' : '$count restoran',
        hi: count == 1 ? '1 रेस्टोरेंट' : '$count रेस्टोरेंट',
        ur: count == 1 ? '1 ریستوران' : '$count ریستوران',
        fr: count == 1 ? '1 restaurant' : '$count restaurants',
        bn: count == 1 ? '১টি রেস্টুরেন্ট' : '$count টি রেস্টুরেন্ট',
      );
      return _Amenity(Icons.restaurant, label);
    case 'front_desk_24h':
      return _Amenity(
        Icons.support_agent,
        _t3(context, ar: 'استقبال على مدار 24 ساعة', en: '24-hour front desk', es: 'Recepción 24 horas', tr: '7/24 resepsiyon', id: 'Resepsionis 24 jam',
            hi: '24 घंटे फ्रंट डेस्क',
            ur: '24 گھنٹے فرنٹ ڈیسک',
            fr: 'Réception 24h/24',
            bn: '২৪ ঘণ্টা ফ্রন্ট ডেস্ক'),
      );
    case 'bar':
      return _Amenity(
        Icons.local_bar,
        _t3(context, ar: 'بار', en: 'Bar', es: 'Bar', tr: 'Bar', id: 'Bar',
            hi: 'बार',
            ur: 'بار',
            fr: 'Bar',
            bn: 'বার'),
      );
    case 'laundry':
      return _Amenity(
        Icons.local_laundry_service,
        _t3(context, ar: 'خدمة غسيل الملابس', en: 'Laundry', es: 'Lavandería', tr: 'Çamaşırhane', id: 'Layanan cuci',
            hi: 'लॉन्ड्री',
            ur: 'لانڈری',
            fr: 'Blanchisserie',
            bn: 'লন্ড্রি'),
      );
    case 'elevator':
      return _Amenity(
        Icons.elevator,
        _t3(context, ar: 'مصعد', en: 'Elevator', es: 'Ascensor', tr: 'Asansör', id: 'Lift',
            hi: 'लिफ्ट',
            ur: 'لفٹ',
            fr: 'Ascenseur',
            bn: 'লিফট'),
      );
    case 'breakfast':
      return _Amenity(
        Icons.free_breakfast,
        _t3(context, ar: 'إفطار', en: 'Breakfast', es: 'Desayuno', tr: 'Kahvaltı', id: 'Sarapan',
            hi: 'नाश्ता',
            ur: 'ناشتہ',
            fr: 'Petit-déjeuner',
            bn: 'নাস্তা'),
      );
    default:
    // مفتاح غير معروف: اعرض النص كما هو مع أيقونة عامة بدل تجاهله
      return _Amenity(Icons.check_circle_outline, raw);
  }
}

class _AreaItem {
  final String name;
  final String distance;
  const _AreaItem(this.name, this.distance);
}

/// فئة من فئات "المنطقة المحيطة" (معالم، مطاعم، مواصلات، مطارات...).
class _AreaCategory {
  final String title;
  final IconData icon;
  final List<_AreaItem> items;
  const _AreaCategory({
    required this.title,
    required this.icon,
    required this.items,
  });
}

/// بيانات تجريبية (Placeholder) إلى أن يتوفر مصدر بيانات فعلي لمواقع
/// المعالم والمطاعم القريبة (مثل Google Places API) مرتبط بإحداثيات الفندق.
/// عناوين الفئات مترجمة لكل اللغات التسع؛ أسماء العناصر نفسها (زي "المتحف
/// الوطني") مقصود إنها تفضل عربي/إنجليزي بس، لأنها بيانات وهمية مؤقتة
/// هتتستبدل ببيانات حقيقية لاحقًا، مش محتوى نهائي يستاهل ترجمة كاملة الآن.
List<_AreaCategory> _areaHighlightCategories(BuildContext context) {
  final isArabic = Localizations.localeOf(context).languageCode == 'ar';

  final categories = isArabic
      ? [
    _AreaCategory(
      title: 'أبرز المعالم السياحية',
      icon: Icons.attractions_outlined,
      items: const [
        _AreaItem('المتحف الوطني', '3.2 كم'),
        _AreaItem('الحديقة المركزية', '3.8 كم'),
        _AreaItem('البرج التاريخي', '4.5 كم'),
        _AreaItem('السوق الشعبي', '5.1 كم'),
      ],
    ),
    _AreaCategory(
      title: 'مطاعم ومقاهي',
      icon: Icons.restaurant_outlined,
      items: const [
        _AreaItem('مقهى الزاوية', '300 م'),
        _AreaItem('مطعم البيت الشامي', '550 م'),
        _AreaItem('كافيه النخلة', '700 م'),
      ],
    ),
    _AreaCategory(
      title: 'وسائل النقل العام',
      icon: Icons.directions_bus_outlined,
      items: const [
        _AreaItem('محطة المترو الرئيسية', '850 م'),
        _AreaItem('موقف الحافلات', '400 م'),
      ],
    ),
    _AreaCategory(
      title: 'أقرب المطارات',
      icon: Icons.flight_outlined,
      items: const [
        _AreaItem('المطار الدولي', '18 كم'),
      ],
    ),
  ]
      : [
    _AreaCategory(
      title: 'Top Attractions',
      icon: Icons.attractions_outlined,
      items: const [
        _AreaItem('National Museum', '3.2 km'),
        _AreaItem('Central Park', '3.8 km'),
        _AreaItem('Historic Tower', '4.5 km'),
        _AreaItem('Old Market', '5.1 km'),
      ],
    ),
    _AreaCategory(
      title: 'Restaurants & Cafes',
      icon: Icons.restaurant_outlined,
      items: const [
        _AreaItem('Corner Cafe', '300 m'),
        _AreaItem('Al Shami House Restaurant', '550 m'),
        _AreaItem('Palm Cafe', '700 m'),
      ],
    ),
    _AreaCategory(
      title: 'Public Transit',
      icon: Icons.directions_bus_outlined,
      items: const [
        _AreaItem('Main Metro Station', '850 m'),
        _AreaItem('Bus Stop', '400 m'),
      ],
    ),
    _AreaCategory(
      title: 'Closest Airports',
      icon: Icons.flight_outlined,
      items: const [
        _AreaItem('International Airport', '18 km'),
      ],
    ),
  ];

  // عناوين الفئات (مش عناصرها) مترجمة لكل اللغات التسع، فوق النسخة
  // العربية/الإنجليزية الأساسية اللي بنيت بيها الـ items فوق.
  final titles = [
    _t3(context, ar: 'أبرز المعالم السياحية', en: 'Top Attractions', es: 'Principales atracciones', tr: 'En Popüler Yerler', id: 'Atraksi Utama',
        hi: 'प्रमुख आकर्षण',
        ur: 'نمایاں مقامات',
        fr: 'Principales attractions',
        bn: 'প্রধান আকর্ষণ'),
    _t3(context, ar: 'مطاعم ومقاهي', en: 'Restaurants & Cafes', es: 'Restaurantes y cafeterías', tr: 'Restoranlar ve Kafeler', id: 'Restoran & Kafe',
        hi: 'रेस्टोरेंट और कैफे',
        ur: 'ریستوران اور کیفے',
        fr: 'Restaurants et cafés',
        bn: 'রেস্টুরেন্ট ও ক্যাফে'),
    _t3(context, ar: 'وسائل النقل العام', en: 'Public Transit', es: 'Transporte público', tr: 'Toplu Taşıma', id: 'Transportasi Umum',
        hi: 'सार्वजनिक परिवहन',
        ur: 'عوامی نقل و حمل',
        fr: 'Transports en commun',
        bn: 'গণপরিবহন'),
    _t3(context, ar: 'أقرب المطارات', en: 'Closest Airports', es: 'Aeropuertos más cercanos', tr: 'En Yakın Havalimanları', id: 'Bandara Terdekat',
        hi: 'निकटतम हवाई अड्डे',
        ur: 'قریب ترین ہوائی اڈے',
        fr: 'Aéroports les plus proches',
        bn: 'নিকটতম বিমানবন্দর'),
  ];

  return [
    for (var i = 0; i < categories.length; i++)
      _AreaCategory(title: titles[i], icon: categories[i].icon, items: categories[i].items),
  ];
}

class _AreaCategorySection extends StatelessWidget {
  final _AreaCategory category;
  const _AreaCategorySection({required this.category});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSizes.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(category.icon, size: 18, color: AppColors.primary),
              const SizedBox(width: AppSizes.sm),
              Text(
                category.title,
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Card(
            margin: EdgeInsets.zero,
            child: Column(
              children: List.generate(category.items.length, (index) {
                final item = category.items[index];
                final isLast = index == category.items.length - 1;
                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSizes.md,
                        vertical: 10,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(child: Text(item.name)),
                          Text(
                            item.distance,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (!isLast) const Divider(height: 1),
                  ],
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

/// يختار النص المناسب حسب اللغة الحالية (عربي/إنجليزي/إسباني/تركي/إندونيسي/هندي/أوردو/فرنسي/بنغالي).
String _policyText(
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

/// قسم "سياسات الفندق" -- بيانات عامة/قياسية شائعة في صناعة الفنادق
/// (مش مسحوبة من HotelBeds لكل فندق تحديدًا، عشان نتجنب استهلاك كوتة
/// إضافية لكل فتح صفحة فندق). بتُعرض كإرشادات عامة متوقعة، مش كبيانات
/// دقيقة 100% خاصة بالفندق ده تحديدًا.
class _PoliciesSection extends StatelessWidget {
  const _PoliciesSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _policyText(context, ar: 'سياسات الفندق', en: 'Policies', es: 'Políticas', tr: 'Politikalar',
              id: 'Kebijakan', hi: 'नीतियां', ur: 'پالیسیاں', fr: 'Politiques', bn: 'নীতিমালা'),
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: AppSizes.sm),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(AppSizes.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _PolicyGroup(
                  title: _policyText(context, ar: 'تسجيل الوصول', en: 'Check-in', es: 'Entrada', tr: 'Giriş',
                      id: 'Check-in', hi: 'चेक-इन', ur: 'چیک ان', fr: 'Arrivée', bn: 'চেক-ইন'),
                  lines: [
                    _policyText(context, ar: 'بداية تسجيل الوصول: 3:00 مساءً؛ نهاية تسجيل الوصول: منتصف الليل',
                        en: 'Check-in start time: 3:00 PM; Check-in end time: midnight',
                        es: 'Hora de inicio: 15:00; Hora límite: medianoche',
                        tr: 'Giriş başlangıç saati: 15:00; Giriş bitiş saati: gece yarısı',
                        id: 'Waktu mulai check-in: 15:00; Waktu akhir check-in: tengah malam',
                        hi: 'चेक-इन शुरू होने का समय: दोपहर 3:00 बजे; समाप्ति का समय: मध्यरात्रि',
                        ur: 'چیک ان شروع ہونے کا وقت: سہ پہر 3:00؛ ختم ہونے کا وقت: آدھی رات',
                        fr: 'Heure de début : 15h00 ; Heure limite : minuit',
                        bn: 'চেক-ইন শুরুর সময়: বিকাল ৩:০০; শেষ সময়: মধ্যরাত'),
                    _policyText(context, ar: 'تسجيل الوصول المبكر خاضع للتوفر', en: 'Early check-in subject to availability',
                        es: 'Entrada anticipada sujeta a disponibilidad', tr: 'Erken giriş uygunluğa bağlıdır',
                        id: 'Check-in awal tergantung ketersediaan', hi: 'जल्दी चेक-इन उपलब्धता के अधीन है',
                        ur: 'ابتدائی چیک ان دستیابی سے مشروط ہے', fr: 'Arrivée anticipée sous réserve de disponibilité',
                        bn: 'আগে চেক-ইন প্রাপ্যতার সাপেক্ষে'),
                    _policyText(context, ar: 'حد أدنى لعمر تسجيل الوصول: 21 سنة', en: 'Minimum check-in age: 21',
                        es: 'Edad mínima para el registro: 21', tr: 'Asgari giriş yaşı: 21',
                        id: 'Usia minimum check-in: 21', hi: 'न्यूनतम चेक-इन आयु: 21',
                        ur: 'کم از کم چیک ان عمر: 21', fr: 'Âge minimum requis : 21 ans',
                        bn: 'ন্যূনতম চেক-ইন বয়স: ২১'),
                  ],
                ),
                const SizedBox(height: AppSizes.md),
                _PolicyGroup(
                  title: _policyText(context, ar: 'تسجيل المغادرة', en: 'Check-out', es: 'Salida', tr: 'Çıkış',
                      id: 'Check-out', hi: 'चेक-आउट', ur: 'چیک آؤٹ', fr: 'Départ', bn: 'চেক-আউট'),
                  lines: [
                    _policyText(context, ar: 'تسجيل المغادرة قبل الظهر', en: 'Check-out before noon',
                        es: 'Salida antes del mediodía', tr: 'Öğleden önce çıkış',
                        id: 'Check-out sebelum siang', hi: 'दोपहर से पहले चेक-आउट',
                        ur: 'دوپہر سے پہلے چیک آؤٹ', fr: 'Départ avant midi',
                        bn: 'দুপুরের আগে চেক-আউট'),
                    _policyText(context, ar: 'تسجيل المغادرة المتأخر خاضع للتوفر', en: 'Late check-out subject to availability',
                        es: 'Salida tardía sujeta a disponibilidad', tr: 'Geç çıkış uygunluğa bağlıdır',
                        id: 'Check-out terlambat tergantung ketersediaan', hi: 'देर से चेक-आउट उपलब्धता के अधीन है',
                        ur: 'تاخیر سے چیک آؤٹ دستیابی سے مشروط ہے', fr: 'Départ tardif sous réserve de disponibilité',
                        bn: 'দেরিতে চেক-আউট প্রাপ্যতার সাপেক্ষে'),
                  ],
                ),
                const SizedBox(height: AppSizes.md),
                _PolicyGroup(
                  title: _policyText(context, ar: 'الأطفال والأسرّة الإضافية', en: 'Children and extra beds', es: 'Niños y camas adicionales', tr: 'Çocuklar ve ilave yataklar',
                      id: 'Anak-anak dan tempat tidur tambahan', hi: 'बच्चे और अतिरिक्त बिस्तर', ur: 'بچے اور اضافی بستر', fr: 'Enfants et lits supplémentaires', bn: 'শিশু ও অতিরিক্ত বিছানা'),
                  lines: [
                    _policyText(context, ar: 'الأطفال مرحّب بهم', en: 'Children are welcome',
                        es: 'Se admiten niños', tr: 'Çocuklar için uygundur',
                        id: 'Anak-anak dipersilakan', hi: 'बच्चों का स्वागत है',
                        ur: 'بچوں کا خیرمقدم ہے', fr: 'Les enfants sont les bienvenus',
                        bn: 'শিশুরা স্বাগত'),
                    _policyText(context, ar: 'الأسرّة المتحركة/الإضافية غير متوفرة', en: 'Rollaway/extra beds are not available',
                        es: 'No hay camas plegables/adicionales', tr: 'Katlanır/ilave yatak bulunmamaktadır',
                        id: 'Tempat tidur tambahan tidak tersedia', hi: 'रोलअवे/अतिरिक्त बिस्तर उपलब्ध नहीं हैं',
                        ur: 'اضافی بستر دستیاب نہیں ہیں', fr: 'Lits d\'appoint non disponibles',
                        bn: 'অতিরিক্ত বিছানা উপলব্ধ নেই'),
                  ],
                ),
                const SizedBox(height: AppSizes.md),
                Text(
                  _policyText(context, ar: 'طرق الدفع المقبولة', en: 'Property payment types', es: 'Métodos de pago aceptados', tr: 'Kabul edilen ödeme yöntemleri',
                      id: 'Metode pembayaran yang diterima', hi: 'स्वीकृत भुगतान विधियां', ur: 'قابل قبول ادائیگی کے طریقے', fr: 'Moyens de paiement acceptés', bn: 'গৃহীত পেমেন্ট পদ্ধতি'),
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: const [
                    _PaymentChip('Visa', 'assets/images/payment/visa.png'),
                    _PaymentChip('Mastercard', 'assets/images/payment/mastercard.png'),
                    _PaymentChip('American Express', 'assets/images/payment/amex.png'),
                    _PaymentChip('Discover', 'assets/images/payment/discover.png'),
                  ],
                ),
                const SizedBox(height: AppSizes.sm),
                Text(
                  _policyText(
                    context,
                    ar: 'ملاحظة: هذه السياسات إرشادية عامة وقد تختلف تفاصيلها الدقيقة حسب الفندق -- يُرجى تأكيدها مباشرة مع الفندق عند الحاجة.',
                    en: 'Note: These are general guideline policies and exact details may vary by property — please confirm directly with the hotel if needed.',
                    es: 'Nota: estas son políticas orientativas generales y los detalles exactos pueden variar según la propiedad. Confirme directamente con el hotel si es necesario.',
                    tr: 'Not: Bunlar genel yönlendirici politikalardır; kesin ayrıntılar tesise göre değişebilir. Gerekirse doğrudan otelle teyit edin.',
                    id: 'Catatan: Ini adalah kebijakan umum sebagai panduan dan detail pastinya dapat berbeda tergantung properti — mohon konfirmasi langsung dengan hotel jika diperlukan.',
                    hi: 'नोट: ये सामान्य दिशानिर्देश नीतियां हैं और सटीक विवरण संपत्ति के अनुसार भिन्न हो सकते हैं — आवश्यकता पड़ने पर कृपया सीधे होटल से पुष्टि करें।',
                    ur: 'نوٹ: یہ عمومی رہنما پالیسیاں ہیں اور صحیح تفصیلات پراپرٹی کے مطابق مختلف ہو سکتی ہیں — ضرورت پڑنے پر براہ راست ہوٹل سے تصدیق کریں۔',
                    fr: 'Remarque : il s\'agit de politiques générales à titre indicatif ; les détails exacts peuvent varier selon l\'établissement. Veuillez confirmer directement auprès de l\'hôtel si nécessaire.',
                    bn: 'দ্রষ্টব্য: এগুলো সাধারণ নির্দেশিকা নীতি এবং সঠিক বিবরণ সম্পত্তি অনুসারে ভিন্ন হতে পারে — প্রয়োজনে সরাসরি হোটেলের সাথে নিশ্চিত করুন।',
                  ),
                  style: const TextStyle(fontSize: 11, color: AppColors.textHint, fontStyle: FontStyle.italic),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _PolicyGroup extends StatelessWidget {
  final String title;
  final List<String> lines;
  const _PolicyGroup({required this.title, required this.lines});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        const SizedBox(height: 4),
        ...lines.map(
              (line) => Padding(
            padding: const EdgeInsets.only(bottom: 3),
            child: Text(
              line,
              style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.4),
            ),
          ),
        ),
      ],
    );
  }
}

class _PaymentChip extends StatelessWidget {
  final String label;
  final String imageAsset;
  const _PaymentChip(this.label, this.imageAsset);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 64,
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.divider),
        borderRadius: BorderRadius.circular(6),
        color: Colors.white,
      ),
      child: Image.asset(
        imageAsset,
        fit: BoxFit.contain,
        // لو صورة الشعار الفعلية مش مضافة بعد في assets/images/payment/،
        // نرجع لشارة نصية بسيطة (اسم الشركة + أيقونة بطاقة عامة) بدل
        // ما نفشل أو نعرض مساحة فاضية.
        errorBuilder: (_, __, ___) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.credit_card, size: 12, color: AppColors.textSecondary),
            const SizedBox(width: 3),
            Flexible(
              child: Text(
                label,
                style: const TextStyle(fontSize: 9),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}