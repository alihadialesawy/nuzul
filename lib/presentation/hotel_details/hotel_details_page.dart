import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
import '../../data/repositories/hotelbeds_repository.dart';

/// صور HotelBeds متوفرة بعدة مقاسات حسب المسار:
///   giata/ ≈320px · giata/bigger/ ≈800px · giata/xl/ ≈1024px · giata/xxl/ ≈2048px
/// يحوّل أي رابط صورة HotelBeds إلى المقاس المطلوب. الروابط الأخرى تبقى كما هي.
final _hbPhotoRe = RegExp(
    r'(photos\.hotelbeds\.com/giata/)(?:(?:small|medium|standard|bigger|xl|xxl|original)/)?');

String _hbSized(String url, String size) => url.contains('photos.hotelbeds.com/giata/')
    ? url.replaceFirstMapped(_hbPhotoRe, (m) => '${m[1]}$size/')
    : url;

/// صورة شبكية بمقاس محدد، وإن لم يوجد هذا المقاس عند HotelBeds نرجع للرابط الأصلي.
Widget _sizedNetworkImage(
    String url,
    String size, {
      BoxFit fit = BoxFit.cover,
      required Widget Function() fallbackIcon,
    }) {
  final sized = _hbSized(url, size);
  return Image.network(
    sized,
    fit: fit,
    filterQuality: FilterQuality.high,
    errorBuilder: (_, __, ___) => sized == url
        ? fallbackIcon()
        : Image.network(
      url,
      fit: fit,
      filterQuality: FilterQuality.high,
      errorBuilder: (_, __, ___) => fallbackIcon(),
    ),
  );
}

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

  // نسخة قابلة للتحديث من الفندق، تُستخدم بدل widget.hotel مباشرة عشان
  // نقدر نضيف الصور الفعلية بعد ما تتجاب من HotelBeds Content API (لو
  // الفندق مصدره HotelBeds ومفيهوش صور جاهزة من الأساس).
  late HotelModel _hotel = widget.hotel;

  // حالة معرض الصور المصغّر (شكل كارت Booking.com): متحكّم التنقل بين
  // الصور، الصفحة الحالية لعرض النقطة المفعّلة، وحالة القلب (مفضّلة).
  final PageController _imageController = PageController();
  int _currentImagePage = 0;
  bool _isFavorite = false;

  /// فنادق HotelBeds: الغرف والأسعار الحقيقية من نتيجة البحث نفسها
  /// (HotelBedsSearchCache) — بدون استدعاء Availability مرة ثانية.
  /// null = الصفحة فُتحت بدون بحث أو انتهت صلاحية الأسعار.
  HotelBedsResult? _hbResult;

  bool get _isHotelBeds => widget.hotel.id.startsWith('hb_');

  @override
  void initState() {
    super.initState();
    if (_isHotelBeds) {
      _hbResult = HotelBedsSearchCache.lookup(
        code: widget.hotel.id.replaceFirst('hb_', ''),
        checkIn: widget.checkIn,
        checkOut: widget.checkOut,
        guests: widget.guests,
      );
    }
    // فنادق HotelBeds بتيجي بمعرّف بادئته hb_ ومن غير صور من استعلام
    // البحث المبسط -- نجيب الصور الفعلية لحظيًا هنا بس (مش في قائمة
    // البحث كلها) عشان نتجنب إبطاء صفحة النتائج.
    if (_hotel.id.startsWith('hb_') && _hotel.images.length <= 1) {
      _loadHotelBedsImages();
    }
  }

  @override
  void dispose() {
    _imageController.dispose();
    super.dispose();
  }

  Future<void> _loadHotelBedsImages() async {
    final code = _hotel.id.replaceFirst('hb_', '');
    final repo = HotelBedsRepository();
    final result = await repo.getHotelImages(code);

    if (!mounted) return;

    result.when(
      success: (images) {
        if (images.isNotEmpty) {
          setState(() {
            _hotel = _hotel.copyWith(images: images);
          });
        }
      },
      failure: (_) {
        // لو فشل الجلب، نسيب الفندق من غير صور (الشاشة أصلاً بتعرض
        // أيقونة بديلة لو مفيش صور)، بدون ما نعطّل باقي الصفحة.
      },
    );
  }

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
            pricePerNight: _hotel.pricePerNight * _roomOptions[i].priceMultiplier,
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
        'hotel': _hotel,
        'checkIn': widget.checkIn,
        'checkOut': widget.checkOut,
        'guests': widget.guests,
        'selectedRooms': selectedRooms,
      },
    );
  }

  /// حجز سعر واحد من HotelBeds: ننقل rateKey وكل تفاصيل السعر لصفحة الحجز.
  /// [totalSar] = سعر الإقامة كاملة محوّلًا للريال (للعرض والمجاميع فقط؛
  /// المبلغ النهائي يُحسب على السيرفر من rateKey في خطوة الحجز).
  Future<void> _reserveHotelBedsRate(
      HotelBedsRoom room,
      HotelBedsRate rate,
      double totalSar,
      ) async {
    final nights = widget.checkOut.difference(widget.checkIn).inDays.clamp(1, 365);
    final firstPolicy = rate.firstCancellationPolicy;
    final policyFrom = firstPolicy != null ? DateTime.tryParse(firstPolicy.from) : null;
    final freeUntil = (policyFrom != null && DateTime.now().isBefore(policyFrom))
        ? firstPolicy!.localDateTimeText
        : null;

    final selected = SelectedRoom(
      label: [
        _titleCase(room.name),
        if (rate.boardName != null) _titleCase(rate.boardName!),
      ].join(' · '),
      pricePerNight: totalSar / nights / rate.rooms,
      quantity: rate.rooms,
      rateKey: rate.rateKey,
      rateType: rate.rateType,
      paymentType: rate.paymentType,
      boardName: rate.boardName,
      currency: _hbResult?.currency,
      totalPrice: rate.price,
      priceUsd: rate.priceUsd,
      payAtHotelUsd: rate.payAtHotelUsd,
      freeCancellationUntil: freeUntil,
      isNonRefundable: rate.isNonRefundable,
      rateCommentsId: rate.rateCommentsId,
      rateComments: rate.rateComments,
    );

    final user = ref.read(currentUserProvider);
    if (user == null) {
      await context.push(AppRoutes.login);
      if (!context.mounted) return;
    }

    context.push(
      AppRoutes.booking,
      extra: {
        'hotel': _hotel,
        'checkIn': widget.checkIn,
        'checkOut': widget.checkOut,
        'guests': widget.guests,
        'selectedRooms': [selected],
      },
    );
  }

  /// أقصى عدد صور في المعرض.
  static const int _maxGalleryImages = 30;

  /// معرض صور بشكل Booking.com:
  /// - شاشة عريضة (≥ 640px) وفيها 3 صور أو أكثر: صورة كبيرة + شبكة 2×2 مصغّرة،
  ///   وآخر مصغّرة عليها "+N" لو فيه صور أكثر.
  /// - شاشة ضيقة: صورة كبيرة بعرض الصفحة.
  /// - في الحالتين: أسهم تنقل + عدّاد (3 / 12)، والضغط يفتح عارض ملء الشاشة.
  Widget _buildImageGallery(HotelModel hotel) {
    final images = hotel.images.take(_maxGalleryImages).toList();

    if (images.isEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(AppSizes.radiusSm),
        child: Container(
          height: 240,
          color: AppColors.divider,
          child: const Center(child: Icon(Icons.hotel, size: 48, color: AppColors.textHint)),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 640 && images.length >= 3;
        final height = wide ? 400.0 : 280.0;

        if (!wide) {
          return SizedBox(height: height, child: _mainCarousel(images));
        }

        final thumbs = images.skip(1).take(4).toList();
        final remaining = images.length - 1 - thumbs.length;

        Widget thumb(int t) {
          if (t >= thumbs.length) return const SizedBox.shrink();
          final isLast = t == thumbs.length - 1 && remaining > 0;
          return _GalleryTile(
            url: thumbs[t],
            overlayText: isLast ? '+$remaining' : null,
            onTap: () => _openGalleryViewer(images, t + 1),
          );
        }

        return SizedBox(
          height: height,
          child: Row(
            children: [
              Expanded(flex: 2, child: _mainCarousel(images)),
              const SizedBox(width: 6),
              Expanded(
                child: Column(
                  children: [
                    Expanded(
                      child: Row(children: [
                        Expanded(child: thumb(0)),
                        const SizedBox(width: 6),
                        Expanded(child: thumb(1)),
                      ]),
                    ),
                    const SizedBox(height: 6),
                    Expanded(
                      child: Row(children: [
                        Expanded(child: thumb(2)),
                        const SizedBox(width: 6),
                        Expanded(child: thumb(3)),
                      ]),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// الصورة الكبيرة: تمرير + أسهم + عدّاد + قلب المفضلة.
  Widget _mainCarousel(List<String> images) {
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final hasMany = images.length > 1;

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppSizes.radiusSm),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Container(
            color: AppColors.divider,
            child: PageView.builder(
              controller: _imageController,
              onPageChanged: (i) => setState(() => _currentImagePage = i),
              itemCount: images.length,
              itemBuilder: (context, i) => GestureDetector(
                onTap: () => _openGalleryViewer(images, i),
                // الصورة الرئيسية كبيرة على الشاشة: مقاس xl بدل bigger/الافتراضي.
                child: _sizedNetworkImage(
                  images[i],
                  'xl',
                  fallbackIcon: () =>
                  const Icon(Icons.hotel, size: 48, color: AppColors.textHint),
                ),
              ),
            ),
          ),
          if (hasMany) ...[
            PositionedDirectional(
              start: 8,
              top: 0,
              bottom: 0,
              child: Center(
                child: _ArrowButton(
                  icon: rtl ? Icons.chevron_right : Icons.chevron_left,
                  onTap: () => _imageController.previousPage(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeOut,
                  ),
                ),
              ),
            ),
            PositionedDirectional(
              end: 8,
              top: 0,
              bottom: 0,
              child: Center(
                child: _ArrowButton(
                  icon: rtl ? Icons.chevron_left : Icons.chevron_right,
                  onTap: () => _imageController.nextPage(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeOut,
                  ),
                ),
              ),
            ),
            PositionedDirectional(
              bottom: 10,
              end: 10,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${_currentImagePage + 1} / ${images.length}',
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
              ),
            ),
          ],
          PositionedDirectional(
            top: 10,
            end: 10,
            child: GestureDetector(
              onTap: () => setState(() => _isFavorite = !_isFavorite),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                child: Icon(
                  _isFavorite ? Icons.favorite : Icons.favorite_border,
                  size: 18,
                  color: _isFavorite ? AppColors.error : AppColors.textSecondary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _openGalleryViewer(List<String> images, int initialIndex) {
    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (_) => _GalleryViewer(images: images, initialIndex: initialIndex),
    );
  }

  /// نجوم تصنيف الفندق الرسمي (من HotelBeds) — وليست تقييم نزلاء.
  Widget _buildStarCategory(HotelModel hotel) {
    final stars = hotel.rating.round().clamp(0, 5);
    if (stars == 0) return const SizedBox.shrink();
    return Row(
      children: [
        ...List.generate(
          stars,
              (_) => const Icon(Icons.star, size: 18, color: Color(0xFFF7B500)),
        ),
        const SizedBox(width: 6),
        Text(
          _t3(context,
              ar: 'فندق $stars نجوم', en: '$stars-star hotel', es: 'Hotel de $stars estrellas',
              tr: '$stars yıldızlı otel', id: 'Hotel bintang $stars', hi: '$stars-सितारा होटल',
              ur: '$stars ستارہ ہوٹل', fr: 'Hôtel $stars étoiles', bn: '$stars-তারকা হোটেল'),
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final hotel = _hotel;

    return Scaffold(
      appBar: const AppBanner(),
      // LayoutBuilder عشان نحدد عرض أقصى للمحتوى على الشاشات العريضة
      // (ويندوز/ويب)، بنفس منطق صفحة المجتمع والملف الشخصي.
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
                    // معرض صور الفندق (شكل Booking.com)
                    _buildImageGallery(hotel),

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
                    // فنادق HotelBeds: نجوم التصنيف الرسمي (لا يوجد تقييم نزلاء
                    // حقيقي بعد، فلا نعرض "درجة مراجعات" غير حقيقية).
                    if (_isHotelBeds)
                      _buildStarCategory(hotel)
                    else
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
                    if (_isHotelBeds)
                      (_hbResult == null
                          ? const _ExpiredResultsCard()
                          : _HotelBedsRoomsList(
                        result: _hbResult!,
                        nights: widget.checkOut
                            .difference(widget.checkIn)
                            .inDays
                            .clamp(1, 365),
                        onReserve: _reserveHotelBedsRate,
                      ))
                    else
                    // فنادق الجدول المحلي (المميزة) — الجدول القديم كما هو.
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

// ═══════════════════════════ غرف HotelBeds الحقيقية ═══════════════════════════

/// "DOUBLE STANDARD" → "Double Standard"
String _titleCase(String s) => s
    .toLowerCase()
    .split(' ')
    .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
    .join(' ');


/// كارت يظهر لو الصفحة فُتحت بدون نتائج بحث صالحة (تحديث المتصفح، رابط
/// مباشر، أو مرّت أكثر من 30 دقيقة). لا نعيد Availability من هنا.
class _ExpiredResultsCard extends StatelessWidget {
  const _ExpiredResultsCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.update, color: AppColors.textSecondary),
                const SizedBox(width: AppSizes.sm),
                Expanded(
                  child: Text(
                    _t3(context,
                        ar: 'انتهت صلاحية الأسعار أو لم يتم البحث بعد. ابحث من جديد لعرض الغرف المتاحة وأسعارها المحدّثة.',
                        en: 'Prices have expired or no search was made. Search again to see available rooms and updated prices.',
                        es: 'Los precios han caducado o no se realizó una búsqueda. Busca de nuevo para ver las habitaciones disponibles y los precios actualizados.',
                        tr: 'Fiyatların süresi doldu veya arama yapılmadı. Müsait odaları ve güncel fiyatları görmek için tekrar arayın.',
                        id: 'Harga sudah kedaluwarsa atau belum ada pencarian. Cari lagi untuk melihat kamar yang tersedia dan harga terbaru.',
                        hi: 'कीमतें समाप्त हो गई हैं या कोई खोज नहीं की गई। उपलब्ध कमरे और अपडेटेड कीमतें देखने के लिए फिर से खोजें।',
                        ur: 'قیمتوں کی میعاد ختم ہو گئی ہے یا تلاش نہیں کی گئی۔ دستیاب کمرے اور تازہ قیمتیں دیکھنے کے لیے دوبارہ تلاش کریں۔',
                        fr: 'Les prix ont expiré ou aucune recherche n\'a été effectuée. Relancez la recherche pour voir les chambres disponibles et les prix à jour.',
                        bn: 'দামের মেয়াদ শেষ হয়েছে বা কোনো অনুসন্ধান করা হয়নি। উপলব্ধ রুম ও হালনাগাদ দাম দেখতে আবার অনুসন্ধান করুন।'),
                    style: const TextStyle(color: AppColors.textSecondary, height: 1.4),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSizes.sm),
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.search, size: 18),
                label: Text(_t3(context,
                    ar: 'ابحث من جديد', en: 'Search again', es: 'Buscar de nuevo', tr: 'Tekrar ara',
                    id: 'Cari lagi', hi: 'फिर से खोजें', ur: 'دوبارہ تلاش کریں',
                    fr: 'Rechercher à nouveau', bn: 'আবার অনুসন্ধান করুন')),
                onPressed: () => context.canPop() ? context.pop() : context.go('/'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// قائمة الغرف الحقيقية من HotelBeds: لكل غرفة كارت، وتحته كل أسعارها
/// (نوع الوجبات، سياسة الإلغاء بتوقيت الفندق، الضرائب التي تُدفع في الفندق،
/// السعر الإجمالي وسعر الليلة، وزر حجز لكل سعر).
class _HotelBedsRoomsList extends ConsumerWidget {
  final HotelBedsResult result;
  final int nights;
  final void Function(HotelBedsRoom room, HotelBedsRate rate, double totalSar) onReserve;

  const _HotelBedsRoomsList({
    required this.result,
    required this.nights,
    required this.onReserve,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rooms = result.rooms.where((r) => r.rates.isNotEmpty).toList()
      ..sort((a, b) => (a.minTotalUsd ?? 0).compareTo(b.minTotalUsd ?? 0));

    if (rooms.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.md),
          child: Text(_t3(context,
              ar: 'لا توجد غرف متاحة لهذه التواريخ', en: 'No rooms available for these dates',
              es: 'No hay habitaciones disponibles para estas fechas', tr: 'Bu tarihler için müsait oda yok',
              id: 'Tidak ada kamar tersedia untuk tanggal ini', hi: 'इन तारीखों के लिए कोई कमरा उपलब्ध नहीं',
              ur: 'ان تاریخوں کے لیے کوئی کمرہ دستیاب نہیں', fr: 'Aucune chambre disponible pour ces dates',
              bn: 'এই তারিখে কোনো রুম উপলব্ধ নেই')),
        ),
      );
    }

    return Column(
      children: [
        for (final room in rooms)
          Card(
            margin: const EdgeInsets.only(bottom: AppSizes.sm),
            child: Padding(
              padding: const EdgeInsets.all(AppSizes.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.bed_outlined, size: 20, color: AppColors.primary),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          _titleCase(room.name),
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSizes.sm),
                  ...([...room.rates]..sort((a, b) => a.totalUsd.compareTo(b.totalUsd))).map((rate) {
                    // أسعار بالدولار من السيرفر (نفس معادلة الدفع). نمررها كريال
                    // بالسعر الثابت لأن PriceText يتوقع ريالًا.
                    const sarPerUsd = 3.75;
                    final payNowSar = rate.priceUsd * sarPerUsd;
                    return _RateRow(
                      rate: rate,
                      nights: nights,
                      totalSar: rate.totalUsd * sarPerUsd,
                      payNowSar: payNowSar,
                      payAtHotelSar: rate.payAtHotelUsd * sarPerUsd,
                      onReserve: () => onReserve(room, rate, payNowSar),
                    );
                  }),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _RateRow extends StatelessWidget {
  final HotelBedsRate rate;
  final int nights;

  /// السعر الشامل (يشمل رسوم الفندق الإلزامية) — الرقم الرئيسي.
  final double totalSar;
  final double payNowSar;
  final double payAtHotelSar;
  final VoidCallback onReserve;

  const _RateRow({
    required this.rate,
    required this.nights,
    required this.totalSar,
    required this.payNowSar,
    required this.payAtHotelSar,
    required this.onReserve,
  });

  Widget _cancellationLine(BuildContext context) {
    if (rate.isNonRefundable) {
      return _ChoiceLine(
        icon: Icons.block,
        color: AppColors.textSecondary,
        text: _t3(context,
            ar: 'غير قابل للاسترداد', en: 'Non-refundable', es: 'No reembolsable', tr: 'İade edilmez',
            id: 'Tidak dapat dikembalikan', hi: 'नॉन-रिफ़ंडेबल', ur: 'ناقابلِ واپسی',
            fr: 'Non remboursable', bn: 'অফেরতযোগ্য'),
      );
    }

    final policy = rate.firstCancellationPolicy;
    if (policy == null) {
      return _ChoiceLine(
        icon: Icons.info_outline,
        color: AppColors.textSecondary,
        text: _t3(context,
            ar: 'تُعرض سياسة الإلغاء قبل الدفع', en: 'Cancellation policy shown before payment',
            es: 'La política de cancelación se muestra antes del pago',
            tr: 'İptal politikası ödemeden önce gösterilir',
            id: 'Kebijakan pembatalan ditampilkan sebelum pembayaran',
            hi: 'रद्दीकरण नीति भुगतान से पहले दिखाई जाती है',
            ur: 'منسوخی کی پالیسی ادائیگی سے پہلے دکھائی جاتی ہے',
            fr: 'La politique d\'annulation est affichée avant le paiement',
            bn: 'পেমেন্টের আগে বাতিল নীতি দেখানো হয়'),
      );
    }

    final from = DateTime.tryParse(policy.from);
    final stillFree = from != null && DateTime.now().isBefore(from);
    if (stillFree) {
      final d = policy.localDateTimeText;
      return _ChoiceLine(
        icon: Icons.check_circle_outline,
        color: AppColors.success,
        text: _t3(context,
            ar: 'إلغاء مجاني حتى $d (بتوقيت الفندق)',
            en: 'Free cancellation until $d (hotel local time)',
            es: 'Cancelación gratuita hasta el $d (hora local del hotel)',
            tr: '$d tarihine kadar ücretsiz iptal (otel yerel saati)',
            id: 'Pembatalan gratis hingga $d (waktu setempat hotel)',
            hi: '$d तक मुफ़्त रद्दीकरण (होटल का स्थानीय समय)',
            ur: '$d تک مفت منسوخی (ہوٹل کا مقامی وقت)',
            fr: 'Annulation gratuite jusqu\'au $d (heure locale de l\'hôtel)',
            bn: '$d পর্যন্ত বিনামূল্যে বাতিল (হোটেলের স্থানীয় সময়)'),
      );
    }

    return _ChoiceLine(
      icon: Icons.warning_amber_outlined,
      color: AppColors.textSecondary,
      text: _t3(context,
          ar: 'تُطبَّق رسوم عند الإلغاء', en: 'Cancellation fees apply',
          es: 'Se aplican cargos por cancelación', tr: 'İptal ücreti uygulanır',
          id: 'Dikenakan biaya pembatalan', hi: 'रद्दीकरण शुल्क लागू',
          ur: 'منسوخی کی فیس لاگو ہے', fr: 'Frais d\'annulation applicables',
          bn: 'বাতিল ফি প্রযোজ্য'),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      margin: const EdgeInsets.only(bottom: AppSizes.sm),
      padding: const EdgeInsets.all(AppSizes.sm),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.divider),
        borderRadius: BorderRadius.circular(AppSizes.radiusSm),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // التفاصيل
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (rate.boardName != null)
                  _ChoiceLine(
                    icon: Icons.restaurant_menu,
                    color: AppColors.primary,
                    text: _titleCase(rate.boardName!),
                  ),
                _cancellationLine(context),
                if (rate.isPayAtHotel)
                  _ChoiceLine(
                    icon: Icons.storefront_outlined,
                    color: AppColors.primary,
                    text: _t3(context,
                        ar: 'الدفع في الفندق', en: 'Pay at hotel', es: 'Pago en el hotel',
                        tr: 'Otelde ödeme', id: 'Bayar di hotel', hi: 'होटल में भुगतान',
                        ur: 'ہوٹل میں ادائیگی', fr: 'Paiement à l\'hôtel', bn: 'হোটেলে পেমেন্ট'),
                  ),
                for (final p in rate.promotions)
                  _ChoiceLine(icon: Icons.local_offer_outlined, color: AppColors.primary, text: p),
                if (rate.rateComments != null && rate.rateComments!.trim().isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Theme(
                      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                      child: ExpansionTile(
                        tilePadding: EdgeInsets.zero,
                        childrenPadding: const EdgeInsets.only(bottom: 6),
                        dense: true,
                        title: Text(
                          _t3(context,
                              ar: 'معلومات مهمة', en: 'Important information',
                              es: 'Información importante', tr: 'Önemli bilgiler',
                              id: 'Informasi penting', hi: 'महत्वपूर्ण जानकारी',
                              ur: 'اہم معلومات', fr: 'Informations importantes',
                              bn: 'গুরুত্বপূর্ণ তথ্য'),
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                        children: [
                          Text(
                            rate.rateComments!.trim(),
                            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: AppSizes.sm),
          // السعر + الحجز
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                PriceText(
                  sarAmount: totalSar,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                Text(
                  payAtHotelSar > 0
                      ? '${_t3(context, ar: 'الإجمالي شاملًا رسوم الفندق', en: 'Total incl. hotel fees', es: 'Total con tasas del hotel', tr: 'Otel ücretleri dahil toplam', id: 'Total termasuk biaya hotel', hi: 'होटल शुल्क सहित कुल', ur: 'ہوٹل فیس سمیت کل', fr: 'Total frais d\'hôtel inclus', bn: 'হোটেল ফি সহ মোট')} · ${l10n.nightsCount(nights)}'
                      : '${_t3(context, ar: 'الإجمالي', en: 'Total', es: 'Total', tr: 'Toplam', id: 'Total', hi: 'कुल', ur: 'کل', fr: 'Total', bn: 'মোট')} · ${l10n.nightsCount(nights)}',
                  style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                  textAlign: TextAlign.end,
                ),
                const SizedBox(height: 2),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    PriceText(
                      sarAmount: totalSar / nights,
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                    Text(
                      ' ${l10n.perNight}',
                      style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                    ),
                  ],
                ),
                // تفصيل إلزامي لما يُدفع الآن وما يُدفع في الفندق.
                if (payAtHotelSar > 0) ...[
                  const SizedBox(height: 2),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        '${_t3(context, ar: 'الآن', en: 'Pay now', es: 'Ahora', tr: 'Şimdi', id: 'Sekarang', hi: 'अभी', ur: 'ابھی', fr: 'Maintenant', bn: 'এখন')} ',
                        style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                      ),
                      PriceText(
                        sarAmount: payNowSar,
                        style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        '${_t3(context, ar: 'في الفندق', en: 'At hotel', es: 'En el hotel', tr: 'Otelde', id: 'Di hotel', hi: 'होटल में', ur: 'ہوٹل میں', fr: 'À l\'hôtel', bn: 'হোটেলে')} ',
                        style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                      ),
                      PriceText(
                        sarAmount: payAtHotelSar,
                        style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 6),
                ElevatedButton(
                  onPressed: onReserve,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                  ),
                  child: Text(
                    _t3(context, ar: 'احجز', en: "I'll reserve", es: 'Reservar', tr: 'Rezervasyon Yap', id: 'Pesan',
                        hi: 'बुक करें', ur: 'بک کریں', fr: 'Réserver', bn: 'বুক করুন'),
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
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
// ═══════════════════════════ معرض الصور ═══════════════════════════

class _ArrowButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _ArrowButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white.withValues(alpha: 0.9),
    shape: const CircleBorder(),
    elevation: 2,
    child: InkWell(
      customBorder: const CircleBorder(),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Icon(icon, size: 24, color: AppColors.textSecondary),
      ),
    ),
  );
}

class _GalleryTile extends StatelessWidget {
  final String url;
  final String? overlayText;
  final VoidCallback onTap;
  const _GalleryTile({required this.url, this.overlayText, required this.onTap});

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(AppSizes.radiusSm),
    child: GestureDetector(
      onTap: onTap,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Container(
            color: AppColors.divider,
            child: _sizedNetworkImage(
              url,
              'bigger',
              fallbackIcon: () => const Icon(Icons.hotel, color: AppColors.textHint),
            ),
          ),
          if (overlayText != null)
            Container(
              color: Colors.black45,
              alignment: Alignment.center,
              child: Text(
                overlayText!,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    ),
  );
}

/// عارض صور بملء الشاشة: أسهم + عدّاد + إغلاق، ويعمل بأسهم لوحة المفاتيح.
class _GalleryViewer extends StatefulWidget {
  final List<String> images;
  final int initialIndex;
  const _GalleryViewer({required this.images, required this.initialIndex});

  @override
  State<_GalleryViewer> createState() => _GalleryViewerState();
}

class _GalleryViewerState extends State<_GalleryViewer> {
  late final PageController _controller = PageController(initialPage: widget.initialIndex);
  late int _index = widget.initialIndex;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _go(int delta) {
    final next = (_index + delta).clamp(0, widget.images.length - 1);
    _controller.animateToPage(next,
        duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
  }

  @override
  Widget build(BuildContext context) {
    final rtl = Directionality.of(context) == TextDirection.rtl;
    return Dialog.fullscreen(
      backgroundColor: Colors.black,
      child: CallbackShortcuts(
        bindings: {
          const SingleActivator(LogicalKeyboardKey.arrowRight): () => _go(rtl ? -1 : 1),
          const SingleActivator(LogicalKeyboardKey.arrowLeft): () => _go(rtl ? 1 : -1),
          const SingleActivator(LogicalKeyboardKey.escape): () => Navigator.of(context).pop(),
        },
        child: Focus(
          autofocus: true,
          child: Stack(
            children: [
              PageView.builder(
                controller: _controller,
                onPageChanged: (i) => setState(() => _index = i),
                itemCount: widget.images.length,
                itemBuilder: (_, i) => InteractiveViewer(
                  child: Center(
                    // ملء الشاشة: أعلى مقاس متاح.
                    child: _sizedNetworkImage(
                      widget.images[i],
                      'xxl',
                      fit: BoxFit.contain,
                      fallbackIcon: () =>
                      const Icon(Icons.hotel, size: 64, color: Colors.white54),
                    ),
                  ),
                ),
              ),
              if (widget.images.length > 1) ...[
                PositionedDirectional(
                  start: 12,
                  top: 0,
                  bottom: 0,
                  child: Center(
                    child: _ArrowButton(
                      icon: rtl ? Icons.chevron_right : Icons.chevron_left,
                      onTap: () => _go(-1),
                    ),
                  ),
                ),
                PositionedDirectional(
                  end: 12,
                  top: 0,
                  bottom: 0,
                  child: Center(
                    child: _ArrowButton(
                      icon: rtl ? Icons.chevron_left : Icons.chevron_right,
                      onTap: () => _go(1),
                    ),
                  ),
                ),
              ],
              PositionedDirectional(
                top: 12,
                end: 12,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white, size: 28),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
              Positioned(
                bottom: 16,
                left: 0,
                right: 0,
                child: Center(
                  child: Text(
                    '${_index + 1} / ${widget.images.length}',
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}