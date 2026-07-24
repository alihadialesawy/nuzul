class BookingModel {
  final String id;
  final String hotelId;
  final String roomId;
  final DateTime checkIn;
  final DateTime checkOut;
  final int guests;
  final double totalPrice;
  final String status;

  // معلومات الفندق (تُملأ لما نجيب الحجز مع بيانات الفندق المرتبط)
  final String? hotelName;
  final String? hotelCity;
  final List<String>? hotelImages;

  BookingModel({
    required this.id,
    required this.hotelId,
    required this.roomId,
    required this.checkIn,
    required this.checkOut,
    required this.guests,
    required this.totalPrice,
    required this.status,
    this.hotelName,
    this.hotelCity,
    this.hotelImages,
  });

  factory BookingModel.fromJson(Map<String, dynamic> json) {
    // Supabase يرجع بيانات الفندق المرتبط جوه مفتاح 'hotels' لو طلبناها بالـ select
    final hotelData = json['hotels'] as Map<String, dynamic>?;

    return BookingModel(
      id: json['id'] as String,
      hotelId: json['hotel_id'] as String,
      roomId: json['room_id'] as String? ?? '',
      checkIn: DateTime.parse(json['check_in']),
      checkOut: DateTime.parse(json['check_out']),
      guests: json['guests'] as int,
      totalPrice: (json['total_price'] as num).toDouble(),
      status: json['status'] as String,
      hotelName: hotelData?['name'] as String?,
      hotelCity: hotelData?['city'] as String?,
      hotelImages: hotelData?['images'] != null
          ? List<String>.from(hotelData!['images'])
          : null,
    );
  }
}