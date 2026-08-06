import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/utils/result.dart';
import '../../core/utils/error_translator.dart';

/// نتيجة مبسّطة لفندق واحد من HotelBeds (Booking API الأساسي بيرجّع بس
/// الاسم والسعر والتصنيف — مفيش صور ولا مرافق في الرد ده؛ دي بتيجي من
/// Content API منفصلة لسه محتاجة نبنيها كخطوة تالية).
class HotelBedsResult {
  final String code;
  final String name;
  final String? categoryName;
  final String? destinationName;
  final String? zoneName;
  final String currency;
  final double minRate;
  final double maxRate;

  HotelBedsResult({
    required this.code,
    required this.name,
    this.categoryName,
    this.destinationName,
    this.zoneName,
    required this.currency,
    required this.minRate,
    required this.maxRate,
  });

  factory HotelBedsResult.fromJson(Map<String, dynamic> json) {
    return HotelBedsResult(
      code: '${json['code']}',
      name: json['name'] as String? ?? '',
      categoryName: json['categoryName'] as String?,
      destinationName: json['destinationName'] as String?,
      zoneName: json['zoneName'] as String?,
      currency: json['currency'] as String? ?? 'EUR',
      minRate: (json['minRate'] as num?)?.toDouble() ?? 0,
      maxRate: (json['maxRate'] as num?)?.toDouble() ?? 0,
    );
  }
}

/// يتعامل مع HotelBeds Hotel API عن طريق Edge Function آمنة
/// (hotelbeds-search) بدل ما يكلّم HotelBeds مباشرة من التطبيق — الـ
/// API key والـ Secret بيفضلوا على السيرفر بس.
///
/// ملاحظة مهمة: destinationCode لازم يكون كود الوجهة الرسمي بتاع
/// HotelBeds (زي BCN لبرشلونة)، مش اسم المدينة الحر. الكود ده بنجيبه
/// من جدولنا الخاص (hotelbeds_destinations) اللي بيتزامن مسبقًا من
/// HotelBeds عبر hotelbeds-sync-destinations — مش بنقرأه لحظيًا من
/// HotelBeds مباشرة (HotelBeds بتمنع ده صراحة في شروط استخدام الـ
/// Content API).
class HotelBedsRepository {
  final SupabaseClient _client = Supabase.instance.client;

  /// يدور على كود الوجهة المطابق لاسم مدينة في جدولنا المتزامن محليًا.
  /// يرجع null لو المدينة لسه مش متزامنة (محتاجة تشغّل
  /// hotelbeds-sync-destinations لدولتها الأول).
  Future<Result<String?>> lookupDestinationCode(String cityName) async {
    try {
      final response = await _client
          .from('hotelbeds_destinations')
          .select('code')
          .ilike('name', '%$cityName%')
          .limit(1);

      final rows = response as List;
      if (rows.isEmpty) return const Success(null);
      return Success(rows.first['code'] as String);
    } catch (e) {
      return Failure(ErrorTranslator.translate(e));
    }
  }

  /// بحث مباشر لو الكود متوفر عندك بالفعل.
  Future<Result<List<HotelBedsResult>>> search({
    required String destinationCode,
    required DateTime checkIn,
    required DateTime checkOut,
    int adults = 2,
    int children = 0,
    int rooms = 1,
  }) async {
    try {
      final response = await _client.functions.invoke(
        'hotelbeds-search',
        body: {
          'destinationCode': destinationCode,
          'checkIn': _formatDate(checkIn),
          'checkOut': _formatDate(checkOut),
          'adults': adults,
          'children': children,
          'rooms': rooms,
        },
      );

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

  /// اختصار مريح: يدور على كود المدينة الأول، وبعدين يبحث بيه مباشرة.
  /// لو المدينة مش متزامنة، بيرجّع رسالة توضيحية بدل خطأ غامض.
  Future<Result<List<HotelBedsResult>>> searchByCityName({
    required String cityName,
    required DateTime checkIn,
    required DateTime checkOut,
    int adults = 2,
    int children = 0,
    int rooms = 1,
  }) async {
    final codeResult = await lookupDestinationCode(cityName);

    return codeResult.when(
      success: (code) {
        if (code == null) {
          return Future.value(Failure(
            'مدينة "$cityName" لسه مش متزامنة مع HotelBeds. شغّل hotelbeds-sync-destinations لدولتها الأول.',
          ));
        }
        return search(
          destinationCode: code,
          checkIn: checkIn,
          checkOut: checkOut,
          adults: adults,
          children: children,
          rooms: rooms,
        );
      },
      failure: (message) => Future.value(Failure(message)),
    );
  }

  String _formatDate(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}