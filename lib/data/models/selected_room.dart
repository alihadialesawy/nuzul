/// يمثّل غرفة/سعرًا تم اختياره للحجز.
///
/// الحقول الأساسية (label, pricePerNight, quantity) كما كانت، ويستخدمها
/// باقي التطبيق. [pricePerNight] دائمًا بالريال (SAR) لأن PriceText يحوّل
/// منه لعملة العرض.
///
/// حقول HotelBeds اختيارية (null للفنادق المحلية)، وتنقل للحجز كل ما
/// يحتاجه السيرفر: rateKey وrateType، وسعر الإقامة بعملة HotelBeds
/// الأصلية، وسياسة الإلغاء، وملاحظات السعر.
class SelectedRoom {
  final String label;
  final double pricePerNight;
  final int quantity;

  // ───── HotelBeds ─────
  final String? rateKey;
  final String? rateType; // BOOKABLE / RECHECK
  final String? paymentType; // AT_WEB / AT_HOTEL
  final String? boardName;

  /// العملة الأصلية للسعر (عملة حساب HotelBeds).
  final String? currency;

  /// السعر الإجمالي للإقامة كاملة بالعملة الأصلية (كل الليالي).
  final double? totalPrice;

  /// ما يُدفع الآن بالدولار كما رآه العميل (يُرسل للسيرفر ليلتزم به).
  final double? priceUsd;

  /// رسوم إلزامية تُدفع في الفندق (تقدير بالدولار).
  final double payAtHotelUsd;

  /// آخر موعد للإلغاء المجاني بتوقيت الفندق (null = لا يوجد).
  final String? freeCancellationUntil;
  final bool isNonRefundable;
  final String? rateCommentsId;
  final String? rateComments;

  const SelectedRoom({
    required this.label,
    required this.pricePerNight,
    required this.quantity,
    this.rateKey,
    this.rateType,
    this.paymentType,
    this.boardName,
    this.currency,
    this.totalPrice,
    this.priceUsd,
    this.payAtHotelUsd = 0,
    this.freeCancellationUntil,
    this.isNonRefundable = false,
    this.rateCommentsId,
    this.rateComments,
  });

  double get subtotalPerNight => pricePerNight * quantity;

  bool get isHotelBeds => rateKey != null && rateKey!.isNotEmpty;

  /// يحتاج CheckRate قبل الحجز.
  bool get needsRecheck => rateType == 'RECHECK';
}