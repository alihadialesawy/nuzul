import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/utils/result.dart';
import '../../core/utils/error_translator.dart';

double? _toDouble(dynamic v) {
  if (v == null) return null;
  if (v is num) return v.toDouble();
  return double.tryParse('$v');
}

/// شريحة واحدة من سياسة الإلغاء.
/// [from] بتوقيت الوجهة (فيها الـ offset، مثال 2026-12-20T23:59:00-05:00).
/// HotelBeds تشترط عرض الوقت بتوقيت الوجهة، فلا تحوّله لتوقيت جهاز العميل.
class HotelBedsCancellationPolicy {
  final double amount;
  final String from;

  const HotelBedsCancellationPolicy({required this.amount, required this.from});

  factory HotelBedsCancellationPolicy.fromJson(Map<String, dynamic> json) {
    return HotelBedsCancellationPolicy(
      amount: _toDouble(json['amount']) ?? 0,
      from: json['from'] as String? ?? '',
    );
  }

  /// التاريخ والوقت كما هو بتوقيت الوجهة (بدون تحويل).
  String get localDateTimeText {
    if (from.length < 16) return from;
    return '${from.substring(0, 10)} ${from.substring(11, 16)}';
  }
}

/// سعر واحد (rate) داخل غرفة. كل rate له rateKey خاص بالحجز.
class HotelBedsRate {
  final String rateKey;
  final String? rateClass; // NOR / NRF
  final String rateType; // BOOKABLE أو RECHECK
  final String paymentType; // AT_WEB أو AT_HOTEL
  final double net;
  final double? sellingRate;
  final bool hotelMandatory;

  /// سعر البيع بعملة HotelBeds (محسوب على السيرفر، يحترم hotelMandatory).
  final double price;

  /// ما يُدفع الآن بالدولار — هو نفسه المبلغ الذي يُسحب من البطاقة.
  final double priceUsd;

  /// رسوم إلزامية تُدفع في الفندق (تقدير بالدولار)، مثل resort fee.
  final double payAtHotelUsd;

  /// السعر الشامل بالدولار = priceUsd + payAtHotelUsd (يُعرض كرقم رئيسي — FTC).
  final double totalUsd;

  /// تفاصيل الرسوم التي تُدفع في الفندق (type, amount, currency, amountUsd).
  final List<Map<String, dynamic>> atHotelFees;
  final int? allotment;
  final String? boardCode;
  final String? boardName;
  final int rooms;
  final int? adults;
  final int children;
  final String? childrenAges;
  final bool packaging;
  final String? rateCommentsId;
  final String? rateComments;
  final List<HotelBedsCancellationPolicy> cancellationPolicies;
  final bool taxesAllIncluded;
  final List<Map<String, dynamic>> taxes;
  final List<String> promotions;
  final List<String> offers;

  const HotelBedsRate({
    required this.rateKey,
    this.rateClass,
    required this.rateType,
    required this.paymentType,
    required this.net,
    this.sellingRate,
    required this.hotelMandatory,
    required this.price,
    required this.priceUsd,
    this.payAtHotelUsd = 0,
    required this.totalUsd,
    this.atHotelFees = const [],
    this.allotment,
    this.boardCode,
    this.boardName,
    this.rooms = 1,
    this.adults,
    this.children = 0,
    this.childrenAges,
    this.packaging = false,
    this.rateCommentsId,
    this.rateComments,
    this.cancellationPolicies = const [],
    this.taxesAllIncluded = false,
    this.taxes = const [],
    this.promotions = const [],
    this.offers = const [],
  });

  /// يحتاج CheckRate قبل الحجز.
  bool get needsRecheck => rateType == 'RECHECK';

  /// الدفع في الفندق.
  bool get isPayAtHotel => paymentType == 'AT_HOTEL';

  /// غير قابل للاسترداد.
  bool get isNonRefundable => rateClass == 'NRF';

  /// أول موعد تبدأ بعده رسوم الإلغاء (null = لا توجد سياسة).
  HotelBedsCancellationPolicy? get firstCancellationPolicy {
    if (cancellationPolicies.isEmpty) return null;
    final sorted = [...cancellationPolicies]..sort((a, b) => a.from.compareTo(b.from));
    return sorted.first;
  }

  /// ضرائب/رسوم غير مشمولة تُدفع في الفندق (لازم تظهر للعميل قبل الدفع).
  List<Map<String, dynamic>> get taxesPayableAtHotel =>
      taxes.where((t) => t['included'] != true).toList();

  factory HotelBedsRate.fromJson(Map<String, dynamic> json) {
    final taxesJson = json['taxes'] as Map<String, dynamic>?;
    return HotelBedsRate(
      rateKey: json['rateKey'] as String? ?? '',
      rateClass: json['rateClass'] as String?,
      rateType: json['rateType'] as String? ?? 'BOOKABLE',
      paymentType: json['paymentType'] as String? ?? 'AT_WEB',
      net: _toDouble(json['net']) ?? 0,
      sellingRate: _toDouble(json['sellingRate']),
      hotelMandatory: json['hotelMandatory'] == true,
      price: _toDouble(json['price']) ?? _toDouble(json['net']) ?? 0,
      priceUsd: _toDouble(json['priceUsd']) ?? 0,
      payAtHotelUsd: _toDouble(json['payAtHotelUsd']) ?? 0,
      totalUsd: _toDouble(json['totalUsd']) ?? _toDouble(json['priceUsd']) ?? 0,
      atHotelFees: (json['atHotelFees'] as List? ?? [])
          .map((f) => Map<String, dynamic>.from(f as Map))
          .toList(),
      allotment: (json['allotment'] as num?)?.toInt(),
      boardCode: json['boardCode'] as String?,
      boardName: json['boardName'] as String?,
      rooms: (json['rooms'] as num?)?.toInt() ?? 1,
      adults: (json['adults'] as num?)?.toInt(),
      children: (json['children'] as num?)?.toInt() ?? 0,
      childrenAges: json['childrenAges']?.toString(),
      packaging: json['packaging'] == true,
      rateCommentsId: json['rateCommentsId'] as String?,
      rateComments: json['rateComments'] as String?,
      cancellationPolicies: (json['cancellationPolicies'] as List? ?? [])
          .map((p) => HotelBedsCancellationPolicy.fromJson(p as Map<String, dynamic>))
          .toList(),
      taxesAllIncluded: taxesJson?['allIncluded'] == true,
      taxes: (taxesJson?['taxes'] as List? ?? [])
          .map((t) => Map<String, dynamic>.from(t as Map))
          .toList(),
      promotions: (json['promotions'] as List? ?? [])
          .map((p) => (p as Map)['name']?.toString() ?? '')
          .where((s) => s.isNotEmpty)
          .toList(),
      offers: (json['offers'] as List? ?? [])
          .map((o) => (o as Map)['name']?.toString() ?? '')
          .where((s) => s.isNotEmpty)
          .toList(),
    );
  }
}

/// نوع غرفة وأسعاره.
class HotelBedsRoom {
  final String code;
  final String name;
  final List<HotelBedsRate> rates;

  const HotelBedsRoom({required this.code, required this.name, required this.rates});

  double? get minPrice =>
      rates.isEmpty ? null : rates.map((r) => r.price).reduce((a, b) => a < b ? a : b);

  /// أقل سعر شامل بالدولار (للترتيب والعرض).
  double? get minTotalUsd =>
      rates.isEmpty ? null : rates.map((r) => r.totalUsd).reduce((a, b) => a < b ? a : b);

  factory HotelBedsRoom.fromJson(Map<String, dynamic> json) {
    return HotelBedsRoom(
      code: '${json['code'] ?? ''}',
      name: json['name'] as String? ?? '',
      rates: (json['rates'] as List? ?? [])
          .map((r) => HotelBedsRate.fromJson(r as Map<String, dynamic>))
          .toList(),
    );
  }
}

/// غرفة مطلوبة في البحث: عدد البالغين وأعمار الأطفال.
class HotelBedsRoomRequest {
  final int adults;
  final List<int> childAges;

  const HotelBedsRoomRequest({this.adults = 2, this.childAges = const []});

  Map<String, dynamic> toJson() => {'adults': adults, 'childAges': childAges};
}

/// نتيجة فندق واحد من HotelBeds، مع الغرف والأسعار كاملة.
///
/// صفحة تفاصيل الفندق يجب أن تستخدم [rooms] من هذه النتيجة مباشرة،
/// بدون استدعاء Availability مرة ثانية (شرط HotelBeds في الـ Certification).
///
/// [imageUrl] ممكن تكون null — الواجهة تعرض صورة بديلة.
class HotelBedsResult {
  final String code;
  final String name;
  final String? categoryCode;
  final String? categoryName;
  final String? destinationCode;
  final String? destinationName;
  final String? zoneName;
  final double? latitude;
  final double? longitude;
  final String currency;

  /// net من HotelBeds (للتوافق مع الكود القديم — لا تعرضه كسعر بيع).
  final double minRate;
  final double maxRate;

  /// أقل سعر بيع بعملة HotelBeds.
  final double minPrice;

  /// أقل سعر شامل بالدولار للإقامة كاملة (يشمل رسوم الفندق الإلزامية).
  final double? minTotalUsd;

  /// ما يُدفع الآن لنفس السعر، وما يُدفع في الفندق (USD).
  final double? minPriceUsd;
  final double? minPayAtHotelUsd;
  final bool hasPayAtHotel;
  final String? imageUrl;
  final List<HotelBedsRoom> rooms;

  HotelBedsResult({
    required this.code,
    required this.name,
    this.categoryCode,
    this.categoryName,
    this.destinationCode,
    this.destinationName,
    this.zoneName,
    this.latitude,
    this.longitude,
    required this.currency,
    required this.minRate,
    required this.maxRate,
    required this.minPrice,
    this.minTotalUsd,
    this.minPriceUsd,
    this.minPayAtHotelUsd,
    this.hasPayAtHotel = false,
    this.imageUrl,
    this.rooms = const [],
  });

  /// عدد النجوم من categoryCode (مثال: 4EST → 4). null إن لم يُعرف.
  int? get stars {
    final m = RegExp(r'^(\d)').firstMatch(categoryCode ?? categoryName ?? '');
    return m == null ? null : int.tryParse(m.group(1)!);
  }

  factory HotelBedsResult.fromJson(Map<String, dynamic> json) {
    final rawImage = json['imageUrl'] as String?;
    final minRate = _toDouble(json['minRate']) ?? 0;
    return HotelBedsResult(
      code: '${json['code']}',
      name: json['name'] as String? ?? '',
      categoryCode: json['categoryCode'] as String?,
      categoryName: json['categoryName'] as String?,
      destinationCode: json['destinationCode'] as String?,
      destinationName: json['destinationName'] as String?,
      zoneName: json['zoneName'] as String?,
      latitude: _toDouble(json['latitude']),
      longitude: _toDouble(json['longitude']),
      currency: json['currency'] as String? ?? 'EUR',
      minRate: minRate,
      maxRate: _toDouble(json['maxRate']) ?? 0,
      minPrice: _toDouble(json['minPrice']) ?? minRate,
      minTotalUsd: _toDouble(json['minTotalUsd']),
      minPriceUsd: _toDouble(json['minPriceUsd']),
      minPayAtHotelUsd: _toDouble(json['minPayAtHotelUsd']),
      hasPayAtHotel: json['hasPayAtHotel'] == true,
      imageUrl: (rawImage != null && rawImage.isNotEmpty) ? rawImage : null,
      rooms: (json['rooms'] as List? ?? [])
          .map((r) => HotelBedsRoom.fromJson(r as Map<String, dynamic>))
          .toList(),
    );
  }
}

/// ذاكرة مؤقتة لآخر نتائج بحث HotelBeds داخل الجلسة.
///
/// شرط HotelBeds في الـ Certification: لا نكرر Availability عند فتح صفحة
/// الفندق. لذلك صفحة التفاصيل تقرأ الغرف والأسعار من هنا.
/// لو الصفحة فُتحت بدون بحث (تحديث المتصفح مثلًا) أو انتهت صلاحية
/// النتائج، تطلب الصفحة من العميل البحث من جديد.
class HotelBedsSearchCache {
  HotelBedsSearchCache._();

  /// مدة صلاحية الأسعار قبل مطالبة العميل بالبحث من جديد.
  static const Duration validity = Duration(minutes: 30);

  static final Map<String, HotelBedsResult> _byCode = {};
  static DateTime? _searchedAt;
  static String? _searchKey;

  static String _key(DateTime checkIn, DateTime checkOut, int guests) =>
      '${checkIn.year}-${checkIn.month}-${checkIn.day}|'
          '${checkOut.year}-${checkOut.month}-${checkOut.day}|$guests';

  static void store({
    required List<HotelBedsResult> results,
    required DateTime checkIn,
    required DateTime checkOut,
    required int guests,
  }) {
    _byCode
      ..clear()
      ..addEntries(results.map((r) => MapEntry(r.code, r)));
    _searchedAt = DateTime.now();
    _searchKey = _key(checkIn, checkOut, guests);
  }

  /// يرجع نتيجة الفندق لو موجودة، ولنفس التواريخ وعدد الضيوف، وغير منتهية.
  static HotelBedsResult? lookup({
    required String code,
    required DateTime checkIn,
    required DateTime checkOut,
    required int guests,
  }) {
    if (_searchedAt == null || _searchKey != _key(checkIn, checkOut, guests)) {
      return null;
    }
    if (DateTime.now().difference(_searchedAt!) > validity) return null;
    return _byCode[code];
  }
}

/// يتعامل مع HotelBeds عبر Edge Functions آمنة — الـ API key والـ Secret
/// على السيرفر فقط.
///
/// destinationCode لازم يكون كود HotelBeds الرسمي (مثل NYC)، من جدولنا
/// hotelbeds_destinations المتزامن مسبقًا (ممنوع قراءته لحظيًا من Content API).
class HotelBedsRepository {
  final SupabaseClient _client = Supabase.instance.client;

  /// السوق الافتراضي (جنسية/بلد إقامة العميل). نبيع داخل أمريكا حاليًا.
  static const String defaultSourceMarket = 'US';

  /// يحوّل اسم مدينة إلى كود وجهة HotelBeds من جدولنا المتزامن.
  ///
  /// الترتيب (الأفضل أولًا):
  /// 1. الكود نفسه (لو المستخدم كتب NYC مثلًا).
  /// 2. تطابق تام للاسم، أو للجزء قبل " - " (مثال: "Orlando" ↔ "Orlando - FL").
  /// 3. اسم يبدأ بالنص المكتوب.
  /// 4. كلمة داخل الاسم تبدأ بالنص المكتوب.
  /// 5. أي تطابق جزئي.
  /// عند التعادل: الاسم الأقصر أولًا.
  ///
  /// [countryCode] يقيّد البحث بدولة (افتراضيًا US). مرّر null للبحث في كل الدول.
  Future<Result<String?>> lookupDestinationCode(
      String cityName, {
        String? countryCode = defaultSourceMarket,
      }) async {
    final query = cityName.trim();
    if (query.isEmpty) return const Success(null);

    try {
      // 1) الكود مباشرة.
      if (RegExp(r'^[A-Za-z0-9]{2,4}$').hasMatch(query)) {
        var codeQuery = _client
            .from('hotelbeds_destinations')
            .select('code')
            .eq('code', query.toUpperCase());
        if (countryCode != null) codeQuery = codeQuery.eq('country_code', countryCode);
        final codeRows = await codeQuery.limit(1) as List;
        if (codeRows.isNotEmpty) return Success(codeRows.first['code'] as String);
      }

      // 2..5) المرشحون بالاسم، ثم الترتيب محليًا.
      final safe = query.replaceAll('%', '').replaceAll('_', ' ');
      var nameQuery = _client
          .from('hotelbeds_destinations')
          .select('code, name')
          .ilike('name', '%$safe%');
      if (countryCode != null) nameQuery = nameQuery.eq('country_code', countryCode);
      final rows = await nameQuery.limit(50) as List;
      if (rows.isEmpty) return const Success(null);

      final q = safe.toLowerCase();
      int score(String name) {
        final n = name.toLowerCase().trim();
        final base = n.split(' - ').first.trim();
        if (n == q || base == q) return 0;
        if (base.startsWith(q)) return 1;
        if (n.startsWith(q)) return 2;
        if (RegExp(r'(^|[\s\-/(])' + RegExp.escape(q)).hasMatch(n)) return 3;
        return 4;
      }

      final candidates = rows
          .map((r) => (code: r['code'] as String, name: (r['name'] as String?) ?? ''))
          .toList()
        ..sort((a, b) {
          final s = score(a.name).compareTo(score(b.name));
          return s != 0 ? s : a.name.length.compareTo(b.name.length);
        });

      return Success(candidates.first.code);
    } catch (e) {
      return Failure(ErrorTranslator.translate(e));
    }
  }

  /// بحث Availability واحد يُرجع الفنادق مع الغرف والأسعار.
  ///
  /// طريقتان لتحديد الإشغال:
  /// - [roomsSpec]: قائمة غرف، لكل غرفة بالغين وأعمار أطفال (الأدق).
  /// - أو [adults]/[children]/[rooms] كمجاميع + [childAges] (التوافق القديم).
  ///
  /// ⚠️ قبل الـ Certification يجب أن تجمع الواجهة عمر كل طفل؛ بدونها
  /// السيرفر يفترض عمرًا مؤقتًا.
  Future<Result<List<HotelBedsResult>>> search({
    required String destinationCode,
    required DateTime checkIn,
    required DateTime checkOut,
    int adults = 2,
    int children = 0,
    int rooms = 1,
    List<int> childAges = const [],
    List<HotelBedsRoomRequest>? roomsSpec,
    String sourceMarket = defaultSourceMarket,
    String? paymentType, // AT_WEB | AT_HOTEL | BOTH | null = الكل
  }) async {
    try {
      final body = <String, dynamic>{
        'destinationCode': destinationCode,
        'checkIn': _formatDate(checkIn),
        'checkOut': _formatDate(checkOut),
        'adults': adults,
        'children': children,
        'rooms': rooms,
        'childAges': childAges,
        'sourceMarket': sourceMarket,
      };
      if (roomsSpec != null && roomsSpec.isNotEmpty) {
        body['roomsSpec'] = roomsSpec.map((r) => r.toJson()).toList();
      }
      if (paymentType != null) body['paymentType'] = paymentType;

      final response = await _client.functions.invoke('hotelbeds-search', body: body);

      if (response.status != 200) {
        final error = (response.data is Map) ? response.data['error'] : null;
        return Failure(error?.toString() ?? 'تعذر جلب نتائج HotelBeds');
      }

      final data = response.data as Map<String, dynamic>;
      final hotels = (data['hotels'] as List? ?? [])
          .map((row) => HotelBedsResult.fromJson(row as Map<String, dynamic>))
          .toList();

      return Success(hotels);
    } catch (e) {
      return Failure(ErrorTranslator.translate(e));
    }
  }

  Future<Result<List<HotelBedsResult>>> searchByCityName({
    required String cityName,
    required DateTime checkIn,
    required DateTime checkOut,
    int adults = 2,
    int children = 0,
    int rooms = 1,
    List<int> childAges = const [],
    List<HotelBedsRoomRequest>? roomsSpec,
    String sourceMarket = defaultSourceMarket,
    String? paymentType,
    String? countryCode = defaultSourceMarket,
  }) async {
    final codeResult = await lookupDestinationCode(cityName, countryCode: countryCode);

    return codeResult.when(
      success: (code) {
        if (code == null) {
          return Future.value(Failure(
            'لم نجد وجهة باسم "$cityName"${countryCode != null ? ' في $countryCode' : ''}. '
                'تأكد من الاسم، أو أن دولتها متزامنة عبر hotelbeds-sync-destinations.',
          ));
        }
        return search(
          destinationCode: code,
          checkIn: checkIn,
          checkOut: checkOut,
          adults: adults,
          children: children,
          rooms: rooms,
          childAges: childAges,
          roomsSpec: roomsSpec,
          sourceMarket: sourceMarket,
          paymentType: paymentType,
        );
      },
      failure: (message) => Future.value(Failure(message)),
    );
  }

  /// معرض الصور الكامل لفندق (الكود الخام بدون بادئة hb_).
  Future<Result<List<String>>> getHotelImages(String code) async {
    try {
      final response = await _client.functions.invoke(
        'hotelbeds-hotel-images',
        body: {'code': code},
      );

      if (response.status != 200) {
        final error = (response.data is Map) ? response.data['error'] : null;
        return Failure(error?.toString() ?? 'تعذر جلب صور الفندق');
      }

      final data = response.data as Map<String, dynamic>;
      final images = List<String>.from(data['images'] ?? []);
      return Success(images);
    } catch (e) {
      return Failure(ErrorTranslator.translate(e));
    }
  }

  String _formatDate(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}