import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/utils/result.dart';
import '../../core/utils/error_translator.dart';
import '../../core/services/currency_service.dart';
import '../models/hotel_model.dart';
import '../models/destination_model.dart';
import 'hotelbeds_repository.dart';

/// يتعامل مع جدول hotels المحلي (للفنادق المميزة/المفضلة/إدارة
/// الفنادق) ومع HotelBeds Edge Function (للبحث الحي الحقيقي).
class HotelRepository {
  final SupabaseClient _client = Supabase.instance.client;

  /// بحث حي عن فنادق حقيقية عبر HotelBeds (Edge Function `hotelbeds-search`).
  ///
  /// - destinationCode: كود HotelBeds الرسمي من جدول hotelbeds_destinations.
  /// - النتائج الكاملة (الغرف والأسعار وrateKeys) تُحفظ في
  ///   HotelBedsSearchCache لتقرأها صفحة التفاصيل بدون بحث ثانٍ.
  /// - سعر الليلة في HotelModel = (أقل سعر شامل بالدولار ÷ عدد الليالي)
  ///   محوّلًا إلى SAR بالسعر الثابت، لأن PriceText يتوقع ريالًا.
  /// - الصورة الرئيسية تصل جاهزة من hotelbeds-search (imageUrl)، فلا داعي
  ///   لطلب صور إضافي يستهلك حصة HotelBeds.
  Future<Result<List<HotelModel>>> searchHotels({
    required String destinationCode,
    required String cityLabel,
    required DateTime checkIn,
    required DateTime checkOut,
    required int guests,
  }) async {
    try {
      String formatDate(DateTime d) =>
          '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

      final response = await _client.functions.invoke(
        'hotelbeds-search',
        body: {
          'destinationCode': destinationCode,
          'checkIn': formatDate(checkIn),
          'checkOut': formatDate(checkOut),
          'adults': guests,
          'children': 0,
          'rooms': 1,
          'sourceMarket': 'US',
        },
      );

      final data = response.data;
      if (data is Map && data['error'] != null) {
        debugPrint('HOTEL SEARCH FAILED: ${data['error']}');
        return Failure(data['error'].toString());
      }

      final hotelsJson = (data as Map)['hotels'] as List? ?? [];
      final results = hotelsJson
          .map((row) => HotelBedsResult.fromJson(Map<String, dynamic>.from(row as Map)))
          .toList();

      // حفظ النتائج الكاملة لصفحة التفاصيل.
      HotelBedsSearchCache.store(
        results: results,
        checkIn: checkIn,
        checkOut: checkOut,
        guests: guests,
      );

      final nights = checkOut.difference(checkIn).inDays.clamp(1, 365);
      final hotels = <HotelModel>[];
      for (var i = 0; i < results.length; i++) {
        final r = results[i];
        final totalUsd = r.minTotalUsd;
        if (r.rooms.isEmpty || totalUsd == null || totalUsd <= 0) continue;

        // السعر الشامل بالدولار محسوب على السيرفر بنفس معادلة الدفع
        // (يشمل رسوم الفندق الإلزامية). نحوّله لريال بالسعر الثابت فقط
        // لأن PriceText يتوقع ريالًا، فيرجع للدولار بنفس الرقم تمامًا.
        final perNightSar = totalUsd / nights * CurrencyService.sarPerUsd;

        hotels.add(HotelModel.fromHotelBeds(
          Map<String, dynamic>.from(hotelsJson[i] as Map),
          cityLabel: cityLabel,
          pricePerNightSar: perNightSar,
        ));
      }

      return Success(hotels);
    } catch (e) {
      debugPrint('HOTEL SEARCH EXCEPTION: $e');
      return Failure(ErrorTranslator.translate(e));
    }
  }

  /// يبحث في جدول hotelbeds_destinations المحلي (autocomplete) عن
  /// وجهات مطابقة لاسم مكتوب جزئيًا، عشان حقل البحث في الواجهة يقدر
  /// يقترح وجهات فعلية بكودها الرسمي بدل ما المستخدم يكتب اسم حر.
  Future<Result<List<DestinationModel>>> searchDestinations(String query) async {
    try {
      final response = await _client
          .from('hotelbeds_destinations')
          .select()
          .ilike('name', '%$query%')
          .limit(10);

      final destinations = (response as List)
          .map((row) => DestinationModel.fromJson(row))
          .toList();

      return Success(destinations);
    } catch (e) {
      return Failure(ErrorTranslator.translate(e));
    }
  }

  /// يجيب قائمة كل الدول المتاحة في hotelbeds_destinations مع عدد
  /// المدن المزامنة في كل دولة، لعرضها في شاشة "تصفح حسب الدولة".
  /// التجميع (group by) بيتم على مستوى التطبيق بعد الجلب، لأن جدول
  /// الوجهات صغير نسبيًا (مئات الصفوف) فده أبسط من استعلام SQL معقد.
  Future<Result<List<CountrySummary>>> getAvailableCountries() async {
    try {
      final response = await _client
          .from('hotelbeds_destinations')
          .select('country_code');

      final counts = <String, int>{};
      for (final row in (response as List)) {
        final code = (row as Map)['country_code'] as String?;
        if (code == null || code.isEmpty) continue;
        counts[code] = (counts[code] ?? 0) + 1;
      }

      final summaries = counts.entries
          .map((e) => CountrySummary(countryCode: e.key, cityCount: e.value))
          .toList()
        ..sort((a, b) => a.countryCode.compareTo(b.countryCode));

      return Success(summaries);
    } catch (e) {
      return Failure(ErrorTranslator.translate(e));
    }
  }

  /// يجيب كل مدن دولة معينة (مرتبة أبجديًا بالاسم) لعرضها لما المستخدم
  /// يختار دولة في شاشة "تصفح حسب الدولة".
  Future<Result<List<DestinationModel>>> getDestinationsByCountry(String countryCode) async {
    try {
      final response = await _client
          .from('hotelbeds_destinations')
          .select()
          .eq('country_code', countryCode)
          .order('name');

      final destinations = (response as List)
          .map((row) => DestinationModel.fromJson(row))
          .toList();

      return Success(destinations);
    } catch (e) {
      return Failure(ErrorTranslator.translate(e));
    }
  }

  Future<Result<HotelModel>> getHotelDetails(String hotelId) async {
    try {
      final response =
      await _client.from('hotels').select().eq('id', hotelId).single();

      return Success(HotelModel.fromJson(response));
    } catch (e) {
      return Failure(ErrorTranslator.translate(e));
    }
  }

  /// يجيب أفضل الفنادق تقييمًا لعرضها في قسم "الفنادق المميزة" بالصفحة
  /// الرئيسية قبل تنفيذ أي بحث. بيفضل يستخدم جدول hotels المحلي عمدًا
  /// (سريع ومضمون، من غير استهلاك كوتة HotelBeds اليومية المحدودة).
  Future<Result<List<HotelModel>>> getFeaturedHotels({int limit = 6}) async {
    try {
      final response = await _client
          .from('hotels')
          .select()
          .order('rating', ascending: false)
          .limit(limit);

      final hotels =
      (response as List).map((row) => HotelModel.fromJson(row)).toList();

      return Success(hotels);
    } catch (e) {
      return Failure(ErrorTranslator.translate(e));
    }
  }

  /// إضافة/إزالة فندق من المفضلة (جدول وسيط favorites)
  Future<Result<void>> toggleFavorite(String hotelId, bool isFavorite) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) {
        return const Failure('يجب تسجيل الدخول أولاً');
      }

      if (isFavorite) {
        await _client.from('favorites').insert({
          'user_id': userId,
          'hotel_id': hotelId,
        });
      } else {
        await _client
            .from('favorites')
            .delete()
            .eq('user_id', userId)
            .eq('hotel_id', hotelId);
      }
      return const Success(null);
    } catch (e) {
      return Failure(ErrorTranslator.translate(e));
    }
  }

  // ---------------------------------------------------------------------
  // دوال إدارة الفنادق (Admin) — عرض الكل بدون فلترة، إضافة، تعديل، حذف
  // تفضل تعمل على جدول hotels المحلي (منفصل تمامًا عن بحث HotelBeds
  // الحي)، لأن دي فنادق المنصة الخاصة (اللي ظاهرة كـ "فنادق مميزة").
  // ---------------------------------------------------------------------

  /// يجيب كل الفنادق بدون أي فلترة (city/max_guests)، مرتبة بالأحدث أولاً،
  /// لاستخدامها في لوحة إدارة الفنادق.
  Future<Result<List<HotelModel>>> getAllHotelsForAdmin() async {
    try {
      final response = await _client
          .from('hotels')
          .select()
          .order('created_at', ascending: false);

      final hotels =
      (response as List).map((row) => HotelModel.fromJson(row)).toList();

      return Success(hotels);
    } catch (e) {
      return Failure(ErrorTranslator.translate(e));
    }
  }

  /// يضيف فندق جديد ويرجع النسخة المخزّنة (فيها الـ id المُولّد من DB)
  Future<Result<HotelModel>> createHotel(HotelModel hotel) async {
    try {
      final response = await _client
          .from('hotels')
          .insert(hotel.toJson())
          .select()
          .single();

      return Success(HotelModel.fromJson(response));
    } catch (e) {
      return Failure(ErrorTranslator.translate(e));
    }
  }

  /// يحدّث بيانات فندق موجود عن طريق الـ id
  Future<Result<HotelModel>> updateHotel(HotelModel hotel) async {
    try {
      final response = await _client
          .from('hotels')
          .update(hotel.toJson())
          .eq('id', hotel.id)
          .select()
          .single();

      return Success(HotelModel.fromJson(response));
    } catch (e) {
      return Failure(ErrorTranslator.translate(e));
    }
  }

  /// يحذف فندق نهائيًا عن طريق الـ id
  Future<Result<void>> deleteHotel(String hotelId) async {
    try {
      await _client.from('hotels').delete().eq('id', hotelId);
      return const Success(null);
    } catch (e) {
      return Failure(ErrorTranslator.translate(e));
    }
  }
}