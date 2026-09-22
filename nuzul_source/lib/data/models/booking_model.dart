class BookingModel {
  final String id;
  final String userId;
  final String hotelId;
  final String roomId;
  final DateTime checkIn;
  final DateTime checkOut;
  final int guests;
  final double totalPrice;
  final String status;
  final DateTime? createdAt;

  // معلومات الفندق (تُملأ لما نجيب الحجز مع بيانات الفندق المرتبط)
  final String? hotelName;
  final String? hotelCity;
  final List<String>? hotelImages;

  // معلومات الزبون (تُملأ فقط بالاستعلامات اللي تجيب بيانات profiles المرتبطة،
  // مثل getAllBookingsForAdmin — مش موجودة في getMyBookings العادية)
  final String? customerName;
  final String? customerPhone;

  BookingModel({
    required this.id,
    required this.userId,
    required this.hotelId,
    required this.roomId,
    required this.checkIn,
    required this.checkOut,
    required this.guests,
    required this.totalPrice,
    required this.status,
    this.createdAt,
    this.hotelName,
    this.hotelCity,
    this.hotelImages,
    this.customerName,
    this.customerPhone,
  });

  factory BookingModel.fromJson(Map<String, dynamic> json) {
    // Supabase يرجع بيانات الفندق والزبون المرتبطين جوه مفاتيح 'hotels'/'profiles'
    // لو طلبناها بالـ select (join)
    final hotelData = json['hotels'] as Map<String, dynamic>?;
    final profileData = json['profiles'] as Map<String, dynamic>?;

    return BookingModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      hotelId: json['hotel_id'] as String,
      roomId: json['room_id'] as String? ?? '',
      checkIn: DateTime.parse(json['check_in']),
      checkOut: DateTime.parse(json['check_out']),
      guests: json['guests'] as int,
      totalPrice: (json['total_price'] as num).toDouble(),
      status: json['status'] as String,
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at']) : null,
      hotelName: hotelData?['name'] as String?,
      hotelCity: hotelData?['city'] as String?,
      hotelImages: hotelData?['images'] != null
          ? List<String>.from(hotelData!['images'])
          : null,
      customerName: (profileData?['display_name'] as String?)?.isNotEmpty == true
          ? profileData!['display_name'] as String
          : profileData?['full_name'] as String?,
      customerPhone: profileData?['phone'] as String?,
    );
  }
}