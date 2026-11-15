import 'package:supabase_flutter/supabase_flutter.dart';

/// معلم قريب من الفندق (المسافة بالأمتار).
class HotelPoi {
  final String name;
  final double distanceM;
  const HotelPoi(this.name, this.distanceM);
}

/// مطار/محطة قريبة (المسافة بالكيلومتر).
class HotelTerminal {
  final String code;
  final String? name;
  final double distanceKm;
  const HotelTerminal(this.code, this.name, this.distanceKm);
}

/// معلومات الفندق الحقيقية من المورّد:
///   • HotelBeds (كود رقمي)      → دالة hotelbeds-hotel-info
///   • LiteAPI (كود مثل lp1faeef) → دالة liteapi-hotel-info (تضيف الصور والوصف والمرافق)
/// كل حقل قد يكون فارغًا: الواجهة تعرض فقط ما هو متوفر.
class HotelInfo {
  final String? address;
  final String? checkIn; // "15:00"
  final String? checkOut; // "12:00"
  final int? minAge;
  final List<HotelPoi> pointsOfInterest;
  final List<HotelTerminal> terminals;

  /// LiteAPI فقط (فارغة مع HotelBeds).
  final List<String> images; // روابط عبر hotelbeds-image-proxy
  final String? description; // وصف الفندق، نص عادي بلغة الزائر إن توفرت
  final String? importantInfo; // معلومات مهمة من الفندق
  final List<String> facilities; // المرافق كما يسميها الفندق

  const HotelInfo({
    this.address,
    this.checkIn,
    this.checkOut,
    this.minAge,
    this.pointsOfInterest = const [],
    this.terminals = const [],
    this.images = const [],
    this.description,
    this.importantInfo,
    this.facilities = const [],
  });

  bool get hasPolicies => checkIn != null || checkOut != null || minAge != null;

  factory HotelInfo.fromJson(Map<String, dynamic> j) {
    String? s(dynamic v) => (v is String && v.trim().isNotEmpty) ? v.trim() : null;
    return HotelInfo(
      address: s(j['address']),
      checkIn: s(j['checkIn']),
      checkOut: s(j['checkOut']),
      minAge: j['minAge'] is num ? (j['minAge'] as num).toInt() : null,
      pointsOfInterest: ((j['pointsOfInterest'] as List?) ?? const [])
          .whereType<Map>()
          .map((p) => HotelPoi('${p['name']}', (p['distanceM'] as num?)?.toDouble() ?? 0))
          .where((p) => p.name.isNotEmpty)
          .toList(),
      terminals: ((j['terminals'] as List?) ?? const [])
          .whereType<Map>()
          .map((t) => HotelTerminal(
        '${t['code']}',
        t['name'] is String ? t['name'] as String : null,
        (t['distanceKm'] as num?)?.toDouble() ?? 0,
      ))
          .where((t) => t.code.isNotEmpty)
          .toList(),
      images: ((j['images'] as List?) ?? const [])
          .whereType<String>()
          .where((u) => u.startsWith('http'))
          .toList(),
      description: s(j['description']),
      importantInfo: s(j['importantInfo']),
      facilities: ((j['facilities'] as List?) ?? const [])
          .whereType<String>()
          .map((f) => f.trim())
          .where((f) => f.isNotEmpty)
          .toList(),
    );
  }
}

class HotelInfoRepository {
  final _client = Supabase.instance.client;

  /// كود HotelBeds رقمي دائمًا؛ أي كود آخر (مثل lp1faeef) من LiteAPI.
  static bool isLiteApiCode(String code) =>
      !RegExp(r'^\d+$').hasMatch(code.replaceFirst('hb_', ''));

  /// null عند أي فشل — الصفحة تبقى على النص العام دون أي خطأ للزبون.
  /// [language] رمز لغة الواجهة (ar, en, ...) — LiteAPI يعيد الوصف والمرافق بها إن توفرت.
  Future<HotelInfo?> fetch(String code, {String language = 'en'}) async {
    final raw = code.replaceFirst('hb_', '');
    final lite = isLiteApiCode(raw);
    try {
      final res = await _client.functions.invoke(
        lite ? 'liteapi-hotel-info' : 'hotelbeds-hotel-info',
        body: {'code': raw, if (lite) 'language': language},
      );
      final data = res.data;
      if (data is! Map || data['ok'] != true) return null;
      return HotelInfo.fromJson(Map<String, dynamic>.from(data));
    } catch (_) {
      return null;
    }
  }
}