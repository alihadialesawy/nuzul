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

/// معلومات الفندق الحقيقية من HotelBeds Content API (دالة hotelbeds-hotel-info).
/// كل حقل قد يكون فارغًا: الواجهة تعرض فقط ما هو متوفر.
class HotelInfo {
  final String? address;
  final String? checkIn; // "15:00"
  final String? checkOut; // "12:00"
  final int? minAge;
  final List<HotelPoi> pointsOfInterest;
  final List<HotelTerminal> terminals;

  const HotelInfo({
    this.address,
    this.checkIn,
    this.checkOut,
    this.minAge,
    this.pointsOfInterest = const [],
    this.terminals = const [],
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
    );
  }
}

class HotelInfoRepository {
  final _client = Supabase.instance.client;

  /// null عند أي فشل — الصفحة تبقى على النص العام دون أي خطأ للزبون.
  Future<HotelInfo?> fetch(String code) async {
    try {
      final res = await _client.functions.invoke(
        'hotelbeds-hotel-info',
        body: {'code': code.replaceFirst('hb_', '')},
      );
      final data = res.data;
      if (data is! Map || data['ok'] != true) return null;
      return HotelInfo.fromJson(Map<String, dynamic>.from(data));
    } catch (_) {
      return null;
    }
  }
}