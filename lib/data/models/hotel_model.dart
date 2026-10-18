import 'dart:math' as math;

/// إحداثيات الحرمين — تُستخدم لحساب "المسافة من الحرم" في تبويب العمرة.
/// المسجد الحرام: الكعبة المشرفة. المسجد النبوي: الحجرة النبوية تقريبًا.
class HolySite {
  final double latitude;
  final double longitude;
  const HolySite(this.latitude, this.longitude);

  static const masjidAlHaram = HolySite(21.42250, 39.82620);
  static const masjidAnNabawi = HolySite(24.46720, 39.61110);

  /// يختار الحرم المناسب حسب رمز وجهة HotelBeds (QCA = مكة، MED = المدينة).
  static HolySite? forDestinationCode(String? code) {
    switch (code) {
      case 'QCA':
        return masjidAlHaram;
      case 'MED':
        return masjidAnNabawi;
      default:
        return null;
    }
  }
}

class HotelModel {
  final String id;
  final String name;
  final String city;
  final double pricePerNight;
  final double rating;
  final int reviewCount;
  final List<String> images;
  final List<String> amenities;
  final String propertyType;
  final String? neighborhood;
  final int maxGuests;
  final String? currency;

  /// إحداثيات الفندق (من HotelBeds). قد تكون null لبعض الفنادق.
  final double? latitude;
  final double? longitude;

  HotelModel({
    required this.id,
    required this.name,
    required this.city,
    required this.pricePerNight,
    required this.rating,
    required this.reviewCount,
    required this.images,
    required this.amenities,
    this.propertyType = 'Hotels',
    this.neighborhood,
    this.maxGuests = 2,
    this.currency,
    this.latitude,
    this.longitude,
  });

  factory HotelModel.fromJson(Map<String, dynamic> json) {
    return HotelModel(
      id: json['id'] as String,
      name: json['name'] as String,
      city: json['city'] as String,
      pricePerNight: (json['price_per_night'] as num).toDouble(),
      rating: (json['rating'] as num).toDouble(),
      reviewCount: (json['review_count'] as num?)?.toInt() ?? 0,
      images: List<String>.from(json['images'] ?? []),
      amenities: List<String>.from(json['amenities'] ?? []),
      propertyType: json['property_type'] as String? ?? 'Hotels',
      neighborhood: json['neighborhood'] as String?,
      maxGuests: (json['max_guests'] as num?)?.toInt() ?? 2,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
    );
  }

  /// يحوّل عنصر واحد من رد `hotelbeds-search` لنفس شكل HotelModel.
  ///
  /// ملاحظات مهمة على التحويل:
  /// - `id` بصيغة `hb_<code>` لتمييزه عن uuid جدول hotels المحلي.
  /// - rating يُقدَّر من categoryName (أول رقم فيه)، وإلا 3.0.
  /// - ⚠️ السعر: minRate/minPrice في HotelBeds = إجمالي الإقامة كلها
  ///   (كل الليالي) بعملة حساب HotelBeds، وليس سعر ليلة بالريال.
  ///   لذلك يجب تمرير [pricePerNightSar] محسوبًا مسبقًا:
  ///   (minPrice ÷ عدد الليالي) محوّلًا إلى SAR (HotelRepository يفعل ذلك).
  /// - latitude/longitude: يرجعهما hotelbeds-search أرقامًا (أو null).
  factory HotelModel.fromHotelBeds(
      Map<String, dynamic> json, {
        required String cityLabel,
        String? imageUrl,
        double? pricePerNightSar,
      }) {
    final categoryName = json['categoryName'] as String? ?? '';
    final ratingMatch = RegExp(r'(\d+(\.\d+)?)').firstMatch(categoryName);
    final estimatedRating = ratingMatch != null
        ? double.tryParse(ratingMatch.group(1)!) ?? 3.0
        : 3.0;
    // صورة الفندق الحقيقية من hotelbeds-search أولاً، وإلا البديل الممرَّر.
    final mainImage = (json['imageUrl'] as String?) ?? imageUrl;

    double? coord(dynamic v) => v == null ? null : double.tryParse('$v');

    return HotelModel(
      id: 'hb_${json['code']}',
      name: json['name'] as String? ?? '',
      city: (json['destinationName'] as String?)?.isNotEmpty == true
          ? json['destinationName'] as String
          : cityLabel,
      pricePerNight: pricePerNightSar ??
          double.tryParse('${json['minPrice'] ?? json['minRate']}') ??
          0.0,
      rating: estimatedRating.clamp(1.0, 5.0),
      reviewCount: 0,
      images: (mainImage != null && mainImage.isNotEmpty) ? [mainImage] : const [],
      amenities: const [],
      propertyType: categoryName.isNotEmpty ? categoryName : 'Hotels',
      neighborhood: json['zoneName'] as String?,
      maxGuests: 2,
      currency: json['currency'] as String?,
      latitude: coord(json['latitude']),
      longitude: coord(json['longitude']),
    );
  }

  /// المسافة بخط مستقيم (بالمتر) من الفندق إلى [site]، أو null إن لم تتوفر
  /// إحداثيات صالحة. معادلة Haversine.
  ///
  /// ⚠️ مسافة بخط مستقيم وليست مسافة المشي الفعلية؛ تُعرض للعميل بصيغة
  /// "تقريبًا ... بخط مستقيم" حتى لا تكون وعدًا مضلِّلًا.
  double? distanceMetersTo(HolySite site) {
    final lat = latitude, lng = longitude;
    if (lat == null || lng == null || (lat == 0 && lng == 0)) return null;
    const r = 6371000.0;
    double rad(double d) => d * math.pi / 180;
    final dLat = rad(site.latitude - lat);
    final dLng = rad(site.longitude - lng);
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(rad(lat)) * math.cos(rad(site.latitude)) *
            math.sin(dLng / 2) * math.sin(dLng / 2);
    final meters = 2 * r * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    // إحداثيات خاطئة من المزوّد (فندق "في مكة" على بعد مئات الكيلومترات) → نتجاهلها.
    return meters > 50000 ? null : meters;
  }

  /// يحوّل الموديل لصيغة JSON مناسبة للإدراج/التحديث بـ Supabase.
  /// لا يشمل `id` لأنه يُدار من قاعدة البيانات (uuid افتراضي) أو يُمرّر
  /// بشكل منفصل عند التحديث (`.eq('id', ...)`).
  /// (latitude/longitude غير مضمّنين لأن جدول hotels المحلي لا يحتويهما.)
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'city': city,
      'price_per_night': pricePerNight,
      'rating': rating,
      'review_count': reviewCount,
      'images': images,
      'amenities': amenities,
      'property_type': propertyType,
      'neighborhood': neighborhood,
      'max_guests': maxGuests,
    };
  }

  HotelModel copyWith({
    String? name,
    String? city,
    double? pricePerNight,
    double? rating,
    int? reviewCount,
    List<String>? images,
    List<String>? amenities,
    String? propertyType,
    String? neighborhood,
    int? maxGuests,
    String? currency,
    double? latitude,
    double? longitude,
  }) {
    return HotelModel(
      id: id,
      name: name ?? this.name,
      city: city ?? this.city,
      pricePerNight: pricePerNight ?? this.pricePerNight,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
      images: images ?? this.images,
      amenities: amenities ?? this.amenities,
      propertyType: propertyType ?? this.propertyType,
      neighborhood: neighborhood ?? this.neighborhood,
      maxGuests: maxGuests ?? this.maxGuests,
      currency: currency ?? this.currency,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
    );
  }
}