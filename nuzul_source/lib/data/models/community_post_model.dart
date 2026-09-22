enum CommunityBookingType { flight, hotel, car, flightHotel }

CommunityBookingType? communityBookingTypeFromString(String? value) {
  switch (value) {
    case 'flight':
      return CommunityBookingType.flight;
    case 'hotel':
      return CommunityBookingType.hotel;
    case 'car':
      return CommunityBookingType.car;
    case 'flight_hotel':
      return CommunityBookingType.flightHotel;
    default:
      return null;
  }
}

String? communityBookingTypeToString(CommunityBookingType? type) {
  switch (type) {
    case CommunityBookingType.flight:
      return 'flight';
    case CommunityBookingType.hotel:
      return 'hotel';
    case CommunityBookingType.car:
      return 'car';
    case CommunityBookingType.flightHotel:
      return 'flight_hotel';
    case null:
      return null;
  }
}

class CommunityPostModel {
  final String id;
  final String userId;
  final CommunityBookingType? bookingType;
  final String? bookingId;
  final String? destinationCity;
  final String? destinationCountry;
  final String caption;
  final int? rating;
  final List<String> imageUrls;
  final int likesCount;
  final int commentsCount;
  final DateTime createdAt;

  // معلومات مؤلف المنشور (تنضم من join مع profiles عند القراءة، اختيارية)
  final String? authorDisplayName;
  final String? authorAvatarUrl;
  final bool likedByMe;

  const CommunityPostModel({
    required this.id,
    required this.userId,
    this.bookingType,
    this.bookingId,
    this.destinationCity,
    this.destinationCountry,
    required this.caption,
    this.rating,
    this.imageUrls = const [],
    this.likesCount = 0,
    this.commentsCount = 0,
    required this.createdAt,
    this.authorDisplayName,
    this.authorAvatarUrl,
    this.likedByMe = false,
  });

  bool get isVerifiedTrip => bookingId != null && bookingType != null;

  factory CommunityPostModel.fromJson(Map<String, dynamic> json) {
    return CommunityPostModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      bookingType: communityBookingTypeFromString(json['booking_type'] as String?),
      bookingId: json['booking_id'] as String?,
      destinationCity: json['destination_city'] as String?,
      destinationCountry: json['destination_country'] as String?,
      caption: json['caption'] as String? ?? '',
      rating: json['rating'] as int?,
      imageUrls: (json['image_urls'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList(),
      likesCount: json['likes_count'] as int? ?? 0,
      commentsCount: json['comments_count'] as int? ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
      authorDisplayName: json['author_display_name'] as String?,
      authorAvatarUrl: json['author_avatar_url'] as String?,
      likedByMe: json['liked_by_me'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toInsertJson() {
    return {
      'booking_type': communityBookingTypeToString(bookingType),
      'booking_id': bookingId,
      'destination_city': destinationCity,
      'destination_country': destinationCountry,
      'caption': caption,
      'rating': rating,
      'image_urls': imageUrls,
    };
  }
}