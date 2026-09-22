import 'booking_model.dart';

enum InboxItemType { hotelBooking, flightBooking, carBooking, priceWatch }

/// عنصر موحّد في فييد الإنبوكس — يُبنى محليًا من صفوف الحجوزات و
/// price_watches مباشرة (نهج "بسيط وسريع": مفيش جدول notifications
/// منفصل، ومفيش triggers).
class InboxItemModel {
  final String id;
  final InboxItemType type;
  final DateTime timestamp;
  final String status;

  /// يُملأ فقط لو type == hotelBooking
  final BookingModel? hotelBooking;

  /// تُملأ فقط لو type == flightBooking
  final String? airline;
  final String? flightNumber;
  final String? originCity;
  final String? destinationCity;
  final DateTime? departureTime;

  /// تُملأ فقط لو type == carBooking
  final String? carName;
  final String? carCompany;
  final String? pickupCity;
  final DateTime? pickupDate;

  /// تُملأ فقط لو type == priceWatch
  final double? targetPrice;

  const InboxItemModel({
    required this.id,
    required this.type,
    required this.timestamp,
    this.status = '',
    this.hotelBooking,
    this.airline,
    this.flightNumber,
    this.originCity,
    this.destinationCity,
    this.departureTime,
    this.carName,
    this.carCompany,
    this.pickupCity,
    this.pickupDate,
    this.targetPrice,
  });
}