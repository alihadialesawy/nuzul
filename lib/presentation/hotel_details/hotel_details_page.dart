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
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSizes.md),
          children: [
            // صورة الفندق
            ClipRRect(
              borderRadius: BorderRadius.circular(AppSizes.radiusSm),
              child: Container(
                height: 200,
                width: double.infinity,
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

            const AppFooter(),
          ],
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
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

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
                    isArabic ? 'نوع الغرفة' : 'Room type',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    isArabic ? 'السعر اليوم' : "Today's Price",
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Text(
                    isArabic ? 'خياراتك' : 'Your choices',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    isArabic ? 'اختر الغرف' : 'Select Rooms',
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
                            text: isArabic ? 'إفطار متضمّن' : 'Breakfast included',
                            color: AppColors.primary,
                          ),
                        _ChoiceLine(
                          icon: Icons.wifi,
                          text: isArabic ? 'إنترنت عالي السرعة' : 'High-speed internet',
                          color: AppColors.primary,
                        ),
                        _ChoiceLine(
                          icon: room.freeCancellation
                              ? Icons.check_circle_outline
                              : Icons.cancel_outlined,
                          text: room.freeCancellation
                              ? (isArabic ? 'إلغاء مجاني' : 'Free cancellation')
                              : (isArabic ? 'إجمالي تكلفة الإلغاء' : 'Total cost to cancel'),
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
                            isArabic ? 'احجز' : "I'll reserve",
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

/// عنصر واحد ضمن فئة معينة (مثال: "برج المملكة" - "2.5 كم").
String _amenitiesSectionTitle(BuildContext context) {
  final isArabic = Localizations.localeOf(context).languageCode == 'ar';
  return isArabic ? 'أشهر المرافق' : 'Most Popular Amenities';
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
/// "restaurants:2") إلى أيقونة ونص مترجم مناسب. أي مفتاح غير معروف
/// يُعرض كنص خام مع أيقونة عامة، عشان أي مرفق جديد يضاف لاحقًا يفضل يظهر
/// حتى لو معندوش أيقونة مخصصة بعد.
_Amenity _parseAmenity(BuildContext context, String raw) {
  final isArabic = Localizations.localeOf(context).languageCode == 'ar';
  final parts = raw.split(':');
  final key = parts.first.trim();
  final extra = parts.length > 1 ? parts[1].trim() : null;

  switch (key) {
    case 'non_smoking_rooms':
      return _Amenity(
        Icons.smoke_free,
        isArabic ? 'غرف لغير المدخنين' : 'Non-smoking rooms',
      );
    case 'fitness_center':
      return _Amenity(
        Icons.fitness_center,
        isArabic ? 'مركز لياقة بدنية' : 'Fitness center',
      );
    case 'free_wifi':
      return _Amenity(
        Icons.wifi,
        isArabic ? 'واي فاي مجاني' : 'Free WiFi',
      );
    case 'disabled_facilities':
      return _Amenity(
        Icons.accessible,
        isArabic ? 'مرافق لذوي الاحتياجات الخاصة' : 'Facilities for disabled guests',
      );
    case 'restaurants':
      final count = int.tryParse(extra ?? '') ?? 1;
      final label = isArabic
          ? (count == 1 ? 'مطعم واحد' : '$count مطاعم')
          : (count == 1 ? '1 restaurant' : '$count restaurants');
      return _Amenity(Icons.restaurant, label);
    case 'front_desk_24h':
      return _Amenity(
        Icons.support_agent,
        isArabic ? 'استقبال على مدار 24 ساعة' : '24-hour front desk',
      );
    case 'bar':
      return _Amenity(Icons.local_bar, isArabic ? 'بار' : 'Bar');
    case 'laundry':
      return _Amenity(
        Icons.local_laundry_service,
        isArabic ? 'خدمة غسيل الملابس' : 'Laundry',
      );
    case 'elevator':
      return _Amenity(Icons.elevator, isArabic ? 'مصعد' : 'Elevator');
    case 'breakfast':
      return _Amenity(Icons.free_breakfast, isArabic ? 'إفطار' : 'Breakfast');
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
List<_AreaCategory> _areaHighlightCategories(BuildContext context) {
  final isArabic = Localizations.localeOf(context).languageCode == 'ar';

  if (isArabic) {
    return [
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
    ];
  }

  return [
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