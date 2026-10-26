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

  // معلومات الفندق (مخزّنة مباشرة على صف الحجز وقت الإنشاء)
  final String? hotelName;
  final String? hotelCity;
  final List<String>? hotelImages;

  // معلومات الزبون (تُملأ فقط باستعلام getAllBookingsForAdmin عبر join مع profiles)
  final String? customerName;
  final String? customerPhone;

  // ───── حجوزات HotelBeds (null للحجوزات المحلية القديمة) ─────
  final String? supplier; // 'hotelbeds'
  final String? hotelCode;
  final String? hotelAddress;
  final String? hotelPhone;
  final String? roomName;
  final String? boardName;
  final String? supplierReference; // رقم حجز HotelBeds
  final String? clientReference; // مرجع Flynoom (FLY...)
  final String? supplierName; // للقسيمة: "Payable through ..."
  final String? supplierVat;
  final String? holderFirstName;
  final String? holderLastName;
  final String? holderEmail;
  final String? holderPhone;
  final String? rateComments;
  final List<Map<String, dynamic>> cancellationPolicies;
  final double? chargeAmount; // المبلغ المدفوع فعليًا
  final String? chargeCurrency; // USD
  final Map<String, dynamic>? supplierResponse; // رد HotelBeds الكامل عند الحجز
  final DateTime? cancelledAt;
  final String? cancellationReference;
  final double? cancellationFee;
  final double? refundAmount;
  final double? payAtHotelUsd; // رسوم إلزامية تُدفع في الفندق (تقدير USD)
  final List<Map<String, dynamic>> payAtHotelFees; // التفاصيل بالعملة المحلية
  final String? cardBrand; // visa / mastercard ... (من Stripe)
  final String? cardLast4; // آخر 4 أرقام فقط

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
    this.supplier,
    this.hotelCode,
    this.hotelAddress,
    this.hotelPhone,
    this.roomName,
    this.boardName,
    this.supplierReference,
    this.clientReference,
    this.supplierName,
    this.supplierVat,
    this.holderFirstName,
    this.holderLastName,
    this.holderEmail,
    this.holderPhone,
    this.rateComments,
    this.cancellationPolicies = const [],
    this.chargeAmount,
    this.chargeCurrency,
    this.supplierResponse,
    this.cancelledAt,
    this.cancellationReference,
    this.cancellationFee,
    this.refundAmount,
    this.payAtHotelUsd,
    this.payAtHotelFees = const [],
    this.cardBrand,
    this.cardLast4,
  });

  bool get isHotelBeds => supplier == 'hotelbeds';

  String get holderFullName =>
      [holderFirstName, holderLastName].where((s) => s != null && s.isNotEmpty).join(' ');

  /// الغرف كما أكدتها HotelBeds (للقسيمة): اسم الغرفة، الوجبات، البالغين،
  /// الأطفال وأعمارهم. ترجع قائمة فارغة لو الرد غير محفوظ.
  List<VoucherRoom> get voucherRooms {
    final rooms = (supplierResponse?['booking']?['hotel']?['rooms'] as List?) ?? const [];
    final result = <VoucherRoom>[];
    for (final r in rooms) {
      if (r is! Map) continue;
      final rates = (r['rates'] as List?) ?? const [];
      final rate = rates.isNotEmpty && rates.first is Map ? rates.first as Map : const {};
      final paxes = ((r['paxes'] as List?) ?? const []).whereType<Map>().toList();
      final childAges = paxes
          .where((p) => p['type'] == 'CH')
          .map((p) => (p['age'] as num?)?.toInt())
          .whereType<int>()
          .toList();
      final count = (rate['rooms'] as num?)?.toInt() ?? 1;
      result.add(VoucherRoom(
        name: r['name']?.toString() ?? roomName ?? '',
        boardName: rate['boardName']?.toString() ?? boardName,
        rooms: count,
        adults: (rate['adults'] as num?)?.toInt() ??
            paxes.where((p) => p['type'] == 'AD').length,
        children: (rate['children'] as num?)?.toInt() ?? childAges.length,
        childAges: childAges,
        rateComments: rate['rateComments']?.toString(),
      ));
    }
    return result;
  }

  factory BookingModel.fromJson(Map<String, dynamic> json) {
    final profileData = json['profiles'] as Map<String, dynamic>?;
    double? num_(dynamic v) => v == null ? null : (v is num ? v.toDouble() : double.tryParse('$v'));

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
      hotelName: json['hotel_name'] as String?,
      hotelCity: json['hotel_city'] as String?,
      hotelImages: json['hotel_images'] != null
          ? List<String>.from(json['hotel_images'])
          : null,
      customerName: (profileData?['display_name'] as String?)?.isNotEmpty == true
          ? profileData!['display_name'] as String
          : profileData?['full_name'] as String?,
      customerPhone: profileData?['phone'] as String?,
      supplier: json['supplier'] as String?,
      hotelCode: json['hotel_code'] as String?,
      hotelAddress: json['hotel_address'] as String?,
      hotelPhone: json['hotel_phone'] as String?,
      roomName: json['room_name'] as String?,
      boardName: json['board_name'] as String?,
      supplierReference: json['supplier_reference'] as String?,
      clientReference: json['client_reference'] as String?,
      supplierName: json['supplier_name'] as String?,
      supplierVat: json['supplier_vat'] as String?,
      holderFirstName: json['holder_first_name'] as String?,
      holderLastName: json['holder_last_name'] as String?,
      holderEmail: json['holder_email'] as String?,
      holderPhone: json['holder_phone'] as String?,
      rateComments: json['rate_comments'] as String?,
      cancellationPolicies: (json['cancellation_policies'] as List? ?? const [])
          .whereType<Map>()
          .map((m) => Map<String, dynamic>.from(m))
          .toList(),
      chargeAmount: num_(json['charge_amount']),
      chargeCurrency: json['charge_currency'] as String?,
      supplierResponse: json['supplier_response'] is Map
          ? Map<String, dynamic>.from(json['supplier_response'] as Map)
          : null,
      cancelledAt: json['cancelled_at'] != null ? DateTime.tryParse(json['cancelled_at']) : null,
      cancellationReference: json['cancellation_reference'] as String?,
      cancellationFee: num_(json['cancellation_fee']),
      refundAmount: num_(json['refund_amount']),
      payAtHotelUsd: num_(json['pay_at_hotel_usd']),
      payAtHotelFees: (json['pay_at_hotel_fees'] as List? ?? const [])
          .whereType<Map>()
          .map((m) => Map<String, dynamic>.from(m))
          .toList(),
      cardBrand: json['card_brand'] as String?,
      cardLast4: json['card_last4'] as String?,
    );
  }
}

/// غرفة واحدة كما تظهر في القسيمة.
class VoucherRoom {
  final String name;
  final String? boardName;
  final int rooms;
  final int adults;
  final int children;
  final List<int> childAges;
  final String? rateComments;

  const VoucherRoom({
    required this.name,
    this.boardName,
    this.rooms = 1,
    required this.adults,
    required this.children,
    this.childAges = const [],
    this.rateComments,
  });
}