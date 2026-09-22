import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/utils/result.dart';
import '../../core/utils/error_translator.dart';

/// نتيجة مبسّطة لعرض رحلة واحد من Duffel.
class DuffelFlightOffer {
  final String id;
  final String airline;
  final String flightNumber;
  final String originCity;
  final String destinationCity;
  final DateTime departureTime;
  final DateTime arrivalTime;
  final String cabinClass;
  final bool nonstop;
  final double totalAmount;
  final String totalCurrency;

  /// معرّفات المسافرين المرتبطة بالعرض ده عند Duffel — لازم نرسلها
  /// بالظبط وقت إنشاء الحجز الفعلي (كل معرّف بيتقابل بمسافر واحد).
  final List<String> passengerIds;

  /// عدد التوقفات الفعلي (0 = رحلة مباشرة). مأخوذ من عدد الأجزاء
  /// (segments) في أول slice ناقص 1، عبر الـ Edge Function.
  final int stops;

  /// أكواد مطارات التوقف الفعلية (لو فيه توقفات)، بترتيب الرحلة.
  final List<String> stopoverAirports;

  /// كود IATA لمطار المغادرة الفعلي (ممكن يختلف عن كود المدينة نفسه
  /// في المدن اللي فيها أكتر من مطار).
  final String originAirportCode;

  /// كود IATA لمطار الوصول الفعلي.
  final String destinationAirportCode;

  /// اسم/موديل الطائرة (لو Duffel رجّعه)، ممكن يكون null.
  final String? aircraft;

  /// مدة الرحلة الفعلية بالدقائق، جاية جاهزة من Duffel (segment/slice
  /// duration بصيغة ISO 8601 زي "PT13H16M") -- مش محسوبة يدويًا من
  /// فرق departureTime/arrivalTime، لأن دول توقيتان محليان مختلفان
  /// لكل مطار من غير UTC offset، وطرحهم مباشرة بيدي مدة غلط.
  final int durationMinutes;

  DuffelFlightOffer({
    required this.id,
    required this.airline,
    required this.flightNumber,
    required this.originCity,
    required this.destinationCity,
    required this.departureTime,
    required this.arrivalTime,
    required this.cabinClass,
    required this.nonstop,
    required this.totalAmount,
    required this.totalCurrency,
    required this.passengerIds,
    required this.stops,
    required this.stopoverAirports,
    required this.originAirportCode,
    required this.destinationAirportCode,
    this.aircraft,
    required this.durationMinutes,
  });

  factory DuffelFlightOffer.fromJson(Map<String, dynamic> json) {
    return DuffelFlightOffer(
      id: json['id'] as String? ?? '',
      airline: json['airline'] as String? ?? '',
      flightNumber: json['flightNumber'] as String? ?? '',
      originCity: json['originCity'] as String? ?? '',
      destinationCity: json['destinationCity'] as String? ?? '',
      departureTime: DateTime.parse(json['departureTime'] as String),
      arrivalTime: DateTime.parse(json['arrivalTime'] as String),
      cabinClass: json['cabinClass'] as String? ?? 'economy',
      nonstop: json['nonstop'] as bool? ?? false,
      totalAmount: double.tryParse('${json['totalAmount']}') ?? 0,
      totalCurrency: json['totalCurrency'] as String? ?? 'USD',
      passengerIds: (json['passengerIds'] as List? ?? []).map((e) => '$e').toList(),
      stops: (json['stops'] as num?)?.toInt() ?? 0,
      stopoverAirports: (json['stopoverAirports'] as List? ?? []).map((e) => '$e').toList(),
      originAirportCode: json['originAirportCode'] as String? ?? '',
      destinationAirportCode: json['destinationAirportCode'] as String? ?? '',
      aircraft: json['aircraft'] as String?,
      durationMinutes: (json['durationMinutes'] as num?)?.toInt() ?? 0,
    );
  }
}

/// اقتراح مكان واحد (مدينة أو مطار) من Duffel Places API.
class DuffelPlace {
  final String iataCode;
  final String name;
  final String cityName;
  final String type; // "city" أو "airport"

  DuffelPlace({
    required this.iataCode,
    required this.name,
    required this.cityName,
    required this.type,
  });

  factory DuffelPlace.fromJson(Map<String, dynamic> json) {
    return DuffelPlace(
      iataCode: json['iataCode'] as String? ?? '',
      name: json['name'] as String? ?? '',
      cityName: json['cityName'] as String? ?? '',
      type: json['type'] as String? ?? 'airport',
    );
  }
}

/// بيانات مسافر واحد مطلوبة لإتمام حجز Duffel فعليًا.
class DuffelPassengerInfo {
  final String id; // من offer.passengerIds
  final String title; // "mr" | "mrs" | "ms" | "miss"
  final String gender; // "m" | "f"
  final String givenName;
  final String familyName;
  final DateTime bornOn;
  final String email;
  final String phoneNumber;

  DuffelPassengerInfo({
    required this.id,
    required this.title,
    required this.gender,
    required this.givenName,
    required this.familyName,
    required this.bornOn,
    required this.email,
    required this.phoneNumber,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'gender': gender,
    'givenName': givenName,
    'familyName': familyName,
    'bornOn':
    '${bornOn.year.toString().padLeft(4, '0')}-${bornOn.month.toString().padLeft(2, '0')}-${bornOn.day.toString().padLeft(2, '0')}',
    'email': email,
    'phoneNumber': phoneNumber,
  };
}

/// يتعامل مع Duffel Flights API عن طريق Edge Functions آمنة بدل ما
/// يكلّم Duffel مباشرة من التطبيق — الـ access token بيفضل على
/// السيرفر بس.
///
/// ملاحظة: origin وdestination لازم يكونوا أكواد IATA (زي "BOS"
/// لبوسطن، "JFK" لنيويورك) مش اسم المدينة الحر — دي أكواد قياسية
/// عالمية ومفيش حاجة اسمها "مزامنة" هنا زي HotelBeds. استخدم
/// [searchPlaces] عشان تحوّل اسم مدينة حر لكود IATA فورًا وقت البحث.
class DuffelRepository {
  final SupabaseClient _client = Supabase.instance.client;

  /// يدور على أماكن (مدن/مطارات) مطابقة لاسم حر (زي "Boston" أو حتى
  /// "bost")، ويرجّع أكواد IATA المطابقة. بحث حي مباشر من Duffel —
  /// مفيش أي مزامنة أو تخزين مسبق مطلوب.
  Future<Result<List<DuffelPlace>>> searchPlaces(String query) async {
    try {
      final response = await _client.functions.invoke(
        'duffel-places-suggestions',
        body: {'query': query},
      );

      if (response.status != 200) {
        final error = (response.data is Map) ? response.data['error'] : null;
        return Failure(error?.toString() ?? 'تعذر البحث عن الوجهة');
      }

      final data = response.data as Map<String, dynamic>;
      final places = (data['places'] as List? ?? [])
          .map((row) => DuffelPlace.fromJson(row as Map<String, dynamic>))
          .toList();

      return Success(places);
    } catch (e) {
      return Failure(ErrorTranslator.translate(e));
    }
  }

  Future<Result<List<DuffelFlightOffer>>> searchFlights({
    required String origin,
    required String destination,
    required DateTime departureDate,
    DateTime? returnDate,
    int adults = 1,
    String cabinClass = 'economy',
  }) async {
    try {
      final response = await _client.functions.invoke(
        'duffel-search-flights',
        body: {
          'origin': origin,
          'destination': destination,
          'departureDate': _formatDate(departureDate),
          if (returnDate != null) 'returnDate': _formatDate(returnDate),
          'adults': adults,
          'cabinClass': cabinClass,
        },
      );

      if (response.status != 200) {
        final error = (response.data is Map) ? response.data['error'] : null;
        return Failure(error?.toString() ?? 'تعذر جلب نتائج Duffel');
      }

      final data = response.data as Map<String, dynamic>;
      final offers = (data['offers'] as List? ?? [])
          .map((row) => DuffelFlightOffer.fromJson(row as Map<String, dynamic>))
          .toList();

      return Success(offers);
    } catch (e) {
      return Failure(ErrorTranslator.translate(e));
    }
  }

  /// يطلب Component Client Key من Duffel (عبر Edge Function آمنة) --
  /// ده الرمز الآمن المطلوب لعرض فورم Duffel لجمع بيانات البطاقة
  /// (DuffelCardForm) داخل WebView.
  Future<Result<String>> getComponentClientKey() async {
    try {
      final response = await _client.functions.invoke('duffel-create-component-client-key');

      if (response.status != 200) {
        final error = (response.data is Map) ? response.data['error'] : null;
        return Failure(error?.toString() ?? 'تعذر تجهيز صفحة الدفع');
      }

      final data = response.data as Map<String, dynamic>;
      return Success(data['clientKey'] as String);
    } catch (e) {
      return Failure(ErrorTranslator.translate(e));
    }
  }

  /// ينشئ حجز فعلي (Order) عند Duffel من عرض سبق اختياره. لو
  /// [cardId] و[threeDSecureSessionId] اتبعتوا (بعد ما العميل دفع
  /// ببطاقته عبر DuffelPaymentWebViewPage)، الحجز بيتدفع مباشرة من
  /// بطاقة العميل. لو اتسابوا فاضيين، بيتدفع من رصيد Duffel Balance
  /// التجريبي (سلوك قديم، للاختبار بس).
  Future<Result<({String orderId, String? bookingReference})>> createOrder({
    required String offerId,
    required double totalAmount,
    required String totalCurrency,
    required List<DuffelPassengerInfo> passengers,
    String? cardId,
    String? threeDSecureSessionId,
  }) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) {
        return const Failure('يجب تسجيل الدخول أولاً لإتمام الحجز');
      }
      final response = await _client.functions.invoke(
        'duffel-create-order',
        body: {
          'offerId': offerId,
          'totalAmount': totalAmount.toStringAsFixed(2),
          'totalCurrency': totalCurrency,
          'passengers': passengers.map((p) => p.toJson()).toList(),
          'userId': userId,
          if (cardId != null) 'cardId': cardId,
          if (threeDSecureSessionId != null) 'threeDSecureSessionId': threeDSecureSessionId,
        },
      );

      if (response.status != 200) {
        debugPrint('DEBUG createOrder non-200 response: status=${response.status}, data=${response.data}');
        final error = (response.data is Map) ? response.data['error'] : null;
        return Failure(error?.toString() ?? 'تعذر إتمام الحجز');
      }

      final data = response.data as Map<String, dynamic>;
      return Success((
      orderId: data['orderId'] as String,
      bookingReference: data['bookingReference'] as String?,
      ));
    } catch (e, st) {
      debugPrint('DEBUG createOrder EXCEPTION: $e');
      debugPrint('DEBUG createOrder stack: $st');
      return Failure(ErrorTranslator.translate(e));
    }
  }

  String _formatDate(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}