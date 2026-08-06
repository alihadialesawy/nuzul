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
    );
  }
}