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
    );
  }

  /// يحوّل عنصر واحد من رد `hotelbeds-search` Edge Function (حقول:
  /// code, name, categoryName, destinationName, currency, minRate,
  /// maxRate, zoneName) لنفس شكل HotelModel المستخدم في التطبيق.
  ///
  /// ملاحظات مهمة على التحويل:
  /// - `id` بيتحط بصيغة `hb_<code>` (بادئة hb_) عشان نميّزه بوضوح عن
  ///   الـ id بتاع جدول hotels المحلي (uuid) في أي مكان بيتقارن فيه.
  /// - HotelBeds مش بيرجّع صور ولا تقييم فعلي في استجابة البحث
  ///   المبسطة دي (بترجع بس أسعار/تصنيف)، فـ images بتفضل قائمة فاضية
  ///   و rating بيتقدّر تقريبيًا من categoryName (نص زي "4 STARS" أو
  ///   "SUPERIOR 4*" أو "HOSTEL 2*") عن طريق استخراج أول رقم موجود
  ///   فيه؛ لو مفيش رقم (زي "WITHOUT OFFICIAL CATEGORY") بيرجع 3.0
  ///   كقيمة افتراضية معقولة.
  /// - `pricePerNight` بياخد قيمة minRate (أرخص غرفة متاحة لليلة).
  factory HotelModel.fromHotelBeds(
      Map<String, dynamic> json, {
        required String cityLabel,
        String? imageUrl,
      }) {
    final categoryName = json['categoryName'] as String? ?? '';
    final ratingMatch = RegExp(r'(\d+(\.\d+)?)').firstMatch(categoryName);
    final estimatedRating = ratingMatch != null
        ? double.tryParse(ratingMatch.group(1)!) ?? 3.0
        : 3.0;

    return HotelModel(
      id: 'hb_${json['code']}',
      name: json['name'] as String? ?? '',
      city: (json['destinationName'] as String?)?.isNotEmpty == true
          ? json['destinationName'] as String
          : cityLabel,
      pricePerNight: double.tryParse('${json['minRate']}') ?? 0.0,
      rating: estimatedRating.clamp(1.0, 5.0),
      reviewCount: 0,
      images: imageUrl != null ? [imageUrl] : const [],
      amenities: const [],
      propertyType: categoryName.isNotEmpty ? categoryName : 'Hotels',
      neighborhood: json['zoneName'] as String?,
      maxGuests: 2,
      currency: json['currency'] as String?,
    );
  }

  /// يحوّل الموديل لصيغة JSON مناسبة للإدراج/التحديث بـ Supabase.
  /// لا يشمل `id` لأنه يُدار من قاعدة البيانات (uuid افتراضي) أو يُمرّر
  /// بشكل منفصل عند التحديث (`.eq('id', ...)`).
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
    );
  }
}