class HotelModel {
  final String id;
  final String name;
  final String city;
  final double pricePerNight;
  final double rating;
  final List<String> images;

  HotelModel({
    required this.id,
    required this.name,
    required this.city,
    required this.pricePerNight,
    required this.rating,
    required this.images,
  });

  factory HotelModel.fromJson(Map<String, dynamic> json) {
    return HotelModel(
      id: json['id'] as String,
      name: json['name'] as String,
      city: json['city'] as String,
      pricePerNight: (json['price_per_night'] as num).toDouble(),
      rating: (json['rating'] as num).toDouble(),
      images: List<String>.from(json['images'] ?? []),
    );
  }
}
