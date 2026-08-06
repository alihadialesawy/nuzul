/// يمثل رحلة طيران واحدة كما هي مخزّنة في جدول flights بـ Supabase
class FlightModel {
  final String id;
  final String airline;
  final String flightNumber;
  final String originCity;
  final String destinationCity;
  final DateTime departureTime;
  final DateTime arrivalTime;
  final double price;
  final String cabinClass;
  final bool nonstop;
  final int seatsAvailable;

  const FlightModel({
    required this.id,
    required this.airline,
    required this.flightNumber,
    required this.originCity,
    required this.destinationCity,
    required this.departureTime,
    required this.arrivalTime,
    required this.price,
    required this.cabinClass,
    required this.nonstop,
    required this.seatsAvailable,
  });

  Duration get duration => arrivalTime.difference(departureTime);

  factory FlightModel.fromJson(Map<String, dynamic> json) {
    return FlightModel(
      id: json['id'] as String,
      airline: json['airline'] as String,
      flightNumber: json['flight_number'] as String,
      originCity: json['origin_city'] as String,
      destinationCity: json['destination_city'] as String,
      departureTime: DateTime.parse(json['departure_time'] as String),
      arrivalTime: DateTime.parse(json['arrival_time'] as String),
      price: (json['price'] as num).toDouble(),
      cabinClass: json['cabin_class'] as String,
      nonstop: json['nonstop'] as bool,
      seatsAvailable: json['seats_available'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'airline': airline,
      'flight_number': flightNumber,
      'origin_city': originCity,
      'destination_city': destinationCity,
      'departure_time': departureTime.toIso8601String(),
      'arrival_time': arrivalTime.toIso8601String(),
      'price': price,
      'cabin_class': cabinClass,
      'nonstop': nonstop,
      'seats_available': seatsAvailable,
    };
  }
}