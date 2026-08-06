/// يمثل سيارة متاحة للتأجير كما هي مخزّنة في جدول cars بـ Supabase
class CarModel {
  final String id;
  final String company;
  final String carName;
  final String category;
  final String pickupCity;
  final double pricePerDay;
  final int seats;
  final String transmission;
  final String? imageUrl;
  final int availableCount;

  const CarModel({
    required this.id,
    required this.company,
    required this.carName,
    required this.category,
    required this.pickupCity,
    required this.pricePerDay,
    required this.seats,
    required this.transmission,
    required this.availableCount,
    this.imageUrl,
  });

  factory CarModel.fromJson(Map<String, dynamic> json) {
    return CarModel(
      id: json['id'] as String,
      company: json['company'] as String,
      carName: json['car_name'] as String,
      category: json['category'] as String,
      pickupCity: json['pickup_city'] as String,
      pricePerDay: (json['price_per_day'] as num).toDouble(),
      seats: json['seats'] as int,
      transmission: json['transmission'] as String,
      imageUrl: json['image_url'] as String?,
      availableCount: json['available_count'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'company': company,
      'car_name': carName,
      'category': category,
      'pickup_city': pickupCity,
      'price_per_day': pricePerDay,
      'seats': seats,
      'transmission': transmission,
      'image_url': imageUrl,
      'available_count': availableCount,
    };
  }
}