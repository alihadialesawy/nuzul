/// يمثّل نوع غرفة تم اختياره مع الكمية المطلوبة منه، لدعم حجز أكتر من
/// نوع غرفة واحد في نفس عملية الحجز (زي شكل جدول Booking.com).
class SelectedRoom {
  final String label;
  final double pricePerNight;
  final int quantity;

  const SelectedRoom({
    required this.label,
    required this.pricePerNight,
    required this.quantity,
  });

  double get subtotalPerNight => pricePerNight * quantity;
}