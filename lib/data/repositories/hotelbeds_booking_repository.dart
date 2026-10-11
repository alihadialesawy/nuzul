import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/utils/result.dart';
import '../../core/utils/error_translator.dart';

/// شريحة إلغاء كما يرجعها السيرفر بعد CheckRate.
class QuoteCancellationPolicy {
  final double amount; // بعملة HotelBeds
  final double amountUsd; // تكلفة المورد بالدولار
  final double customerFee; // ما يُخصم من العميل عند الإلغاء بعد [from] (USD)
  final String from; // بتوقيت الفندق (مع الـ offset)

  const QuoteCancellationPolicy({
    required this.amount,
    required this.amountUsd,
    required this.customerFee,
    required this.from,
  });

  factory QuoteCancellationPolicy.fromJson(Map<String, dynamic> j) => QuoteCancellationPolicy(
    amount: (j['amount'] as num?)?.toDouble() ?? 0,
    amountUsd: (j['amountUsd'] as num?)?.toDouble() ?? 0,
    customerFee: (j['customerFee'] as num?)?.toDouble() ??
        (j['amountUsd'] as num?)?.toDouble() ??
        0,
    from: j['from'] as String? ?? '',
  );

  DateTime? get fromDate => DateTime.tryParse(from);

  /// "2026-11-08 23:59" كما هو بتوقيت الفندق.
  String get localDateTimeText =>
      from.length >= 16 ? '${from.substring(0, 10)} ${from.substring(11, 16)}' : from;
}

/// نتيجة hotelbeds-prepare: السعر النهائي المؤكد + بيانات الدفع.
class HotelBedsQuote {
  final String bookingId;
  final String clientReference;
  final String clientSecret;
  final double chargeAmount;
  final String chargeCurrency;
  final bool priceChanged;
  final String? roomName;
  final String? boardName;
  final String? rateClass;
  final String? rateComments;
  final List<QuoteCancellationPolicy> cancellationPolicies;

  /// رسوم إلزامية تُدفع في الفندق (تقدير بالدولار) وتفاصيلها.
  final double payAtHotelUsd;
  final List<Map<String, dynamic>> atHotelFees;

  /// السعر الشامل = chargeAmount + payAtHotelUsd.
  double get totalUsd => chargeAmount + payAtHotelUsd;

  const HotelBedsQuote({
    required this.bookingId,
    required this.clientReference,
    required this.clientSecret,
    required this.chargeAmount,
    required this.chargeCurrency,
    required this.priceChanged,
    this.roomName,
    this.boardName,
    this.rateClass,
    this.rateComments,
    this.cancellationPolicies = const [],
    this.payAtHotelUsd = 0,
    this.atHotelFees = const [],
  });

  /// رسوم الإلغاء لو ألغى العميل الآن (USD). 0 = إلغاء مجاني الآن.
  double get currentCancellationFee {
    final now = DateTime.now();
    var fee = 0.0;
    for (final p in cancellationPolicies) {
      final d = p.fromDate;
      if (d != null && !d.isAfter(now) && p.customerFee > fee) fee = p.customerFee;
    }
    return fee;
  }

  /// غير قابل للاسترداد فعلًا: نوع السعر NRF، أو الرسوم الحالية = كامل المبلغ.
  bool get isNonRefundable =>
      rateClass == 'NRF' || (chargeAmount > 0 && currentCancellationFee >= chargeAmount);

  /// المواعيد القادمة (بعد الآن) التي تبدأ عندها رسوم إضافية.
  List<QuoteCancellationPolicy> get upcomingPolicies {
    final now = DateTime.now();
    return cancellationPolicies.where((p) => p.fromDate?.isAfter(now) ?? false).toList();
  }

  factory HotelBedsQuote.fromJson(Map<String, dynamic> j) => HotelBedsQuote(
    bookingId: j['bookingId'] as String,
    clientReference: j['clientReference'] as String? ?? '',
    clientSecret: j['clientSecret'] as String,
    chargeAmount: (j['chargeAmount'] as num).toDouble(),
    chargeCurrency: j['chargeCurrency'] as String? ?? 'USD',
    priceChanged: j['priceChanged'] == true,
    roomName: j['roomName'] as String?,
    boardName: j['boardName'] as String?,
    rateClass: j['rateClass'] as String?,
    rateComments: j['rateComments'] as String?,
    cancellationPolicies: (j['cancellationPolicies'] as List? ?? [])
        .map((p) => QuoteCancellationPolicy.fromJson(Map<String, dynamic>.from(p as Map)))
        .toList()
      ..sort((a, b) => a.from.compareTo(b.from)),
    payAtHotelUsd: (j['payAtHotelUsd'] as num?)?.toDouble() ?? 0,
    atHotelFees: (j['atHotelFees'] as List? ?? [])
        .map((f) => Map<String, dynamic>.from(f as Map))
        .toList(),
  );
}

/// نتيجة hotelbeds-book.
class HotelBedsBookingOutcome {
  /// confirmed = مؤكد ومدفوع. pending = حالة غير محسومة تُراجع يدويًا.
  final String status;
  final String? reference; // رقم حجز HotelBeds
  final String clientReference;

  const HotelBedsBookingOutcome({
    required this.status,
    this.reference,
    required this.clientReference,
  });

  bool get isConfirmed => status == 'confirmed';
}

/// رسوم الإلغاء والاسترداد (USD).
class CancellationQuote {
  final double chargeAmount;
  final double fee;
  final double refund;
  final bool refundPending;

  const CancellationQuote({
    required this.chargeAmount,
    required this.fee,
    required this.refund,
    this.refundPending = false,
  });
}

/// بيانات صاحب الحجز (كما في الهوية).
class BookingHolder {
  final String firstName;
  final String lastName;
  final String email;
  final String phone;

  const BookingHolder({
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phone,
  });

  Map<String, dynamic> toJson() => {
    'firstName': firstName,
    'lastName': lastName,
    'email': email,
    'phone': phone,
  };
}

/// خطوتا حجز HotelBeds عبر السيرفر:
/// 1) [prepare]: CheckRate + حساب المبلغ + PaymentIntent (حجز المبلغ فقط).
/// 2) [book]: بعد إدخال البطاقة، يحجز عند HotelBeds ثم يسحب المبلغ أو يلغيه.
class HotelBedsBookingRepository {
  final SupabaseClient _client = Supabase.instance.client;

  Future<Map<String, dynamic>> _invoke(String fn, Map<String, dynamic> body) async {
    final response = await _client.functions.invoke(fn, body: body);
    final data = response.data;
    if (data is Map) return Map<String, dynamic>.from(data);
    throw Exception('Unexpected response from $fn');
  }

  Future<Result<HotelBedsQuote>> prepare({
    required String rateKey,
    required String hotelCode,
    required String hotelName,
    required String hotelCity,
    String? hotelImage,
    String? roomName,
    required DateTime checkIn,
    required DateTime checkOut,
    required int guests,
    double? expectedPrice,
    double? expectedPriceUsd,
    required BookingHolder holder,
  }) async {
    try {
      final data = await _invoke('hotelbeds-prepare', {
        'rateKey': rateKey,
        'hotelCode': hotelCode,
        'hotelName': hotelName,
        'hotelCity': hotelCity,
        'hotelImage': hotelImage,
        'roomName': roomName,
        'checkIn': _formatDate(checkIn),
        'checkOut': _formatDate(checkOut),
        'guests': guests,
        'expectedPrice': expectedPrice,
        'expectedPriceUsd': expectedPriceUsd,
        'holder': holder.toJson(),
      });
      if (data['ok'] != true) {
        return Failure(data['error']?.toString() ?? 'Could not start the booking.');
      }
      return Success(HotelBedsQuote.fromJson(data));
    } catch (e) {
      return Failure(ErrorTranslator.translate(e));
    }
  }

  Future<Result<HotelBedsBookingOutcome>> book(String bookingId) async {
    try {
      final data = await _invoke('hotelbeds-book', {'bookingId': bookingId});
      if (data['ok'] != true) {
        return Failure(data['error']?.toString() ?? 'The booking could not be completed.');
      }
      return Success(HotelBedsBookingOutcome(
        status: data['status'] as String? ?? 'pending',
        reference: data['reference'] as String?,
        clientReference: data['clientReference'] as String? ?? '',
      ));
    } catch (e) {
      return Failure(ErrorTranslator.translate(e));
    }
  }

  /// رسوم الإلغاء والمبلغ المسترد الآن (بدون إلغاء فعلي).
  Future<Result<CancellationQuote>> cancellationQuote(String bookingId) async {
    try {
      final data = await _invoke('hotelbeds-cancel', {'bookingId': bookingId, 'mode': 'quote'});
      if (data['ok'] != true) {
        return Failure(data['error']?.toString() ?? 'This booking cannot be cancelled online.');
      }
      return Success(CancellationQuote(
        chargeAmount: (data['chargeAmount'] as num?)?.toDouble() ?? 0,
        fee: (data['fee'] as num?)?.toDouble() ?? 0,
        refund: (data['refund'] as num?)?.toDouble() ?? 0,
      ));
    } catch (e) {
      return Failure(ErrorTranslator.translate(e));
    }
  }

  /// إلغاء فعلي عند الفندق + استرداد المبلغ المستحق.
  Future<Result<CancellationQuote>> cancel(String bookingId) async {
    try {
      final data = await _invoke('hotelbeds-cancel', {'bookingId': bookingId, 'mode': 'confirm'});
      if (data['ok'] != true) {
        return Failure(data['error']?.toString() ?? 'The booking could not be cancelled.');
      }
      return Success(CancellationQuote(
        chargeAmount: 0,
        fee: (data['fee'] as num?)?.toDouble() ?? 0,
        refund: (data['refund'] as num?)?.toDouble() ?? 0,
        refundPending: data['status'] == 'refund_pending',
      ));
    } catch (e) {
      return Failure(ErrorTranslator.translate(e));
    }
  }

  String _formatDate(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}