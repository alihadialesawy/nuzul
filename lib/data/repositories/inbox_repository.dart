import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/utils/result.dart';
import '../models/booking_model.dart';
import '../models/inbox_item_model.dart';

class InboxRepository {
  final SupabaseClient _client = Supabase.instance.client;

  /// يجيب فييد الإنبوكس: أحدث حجوزات الفنادق + الطيران + السيارات،
  /// مع تنبيهات أسعار الطيران اللي اتفعّلت فعليًا (notified_at مش
  /// فاضي)، مرتبين بالأحدث أولاً.
  /// ملحوظة: price_watches مربوطة بالإيميل مش بـ user_id (ممكن تتحط
  /// من غير تسجيل دخول)، فبنطابقها بإيميل المستخدم الحالي.
  Future<Result<List<InboxItemModel>>> fetchInboxItems({int limit = 30}) async {
    try {
      final myId = _client.auth.currentUser?.id;
      final myEmail = _client.auth.currentUser?.email;
      if (myId == null) return const Failure('User not authenticated');

      final items = <InboxItemModel>[];

      // حجوزات الفنادق
      final hotelRows = await _client
          .from('bookings')
          .select('*, hotels(name, city, images)')
          .eq('user_id', myId)
          .order('created_at', ascending: false)
          .limit(limit);

      for (final row in (hotelRows as List)) {
        final booking = BookingModel.fromJson(row as Map<String, dynamic>);
        items.add(InboxItemModel(
          id: 'hotel_${booking.id}',
          type: InboxItemType.hotelBooking,
          timestamp: booking.createdAt ?? booking.checkIn,
          status: booking.status,
          hotelBooking: booking,
        ));
      }

      // حجوزات الطيران
      final flightRows = await _client
          .from('flight_bookings')
          .select()
          .eq('user_id', myId)
          .order('created_at', ascending: false)
          .limit(limit);

      for (final row in (flightRows as List)) {
        final map = row as Map<String, dynamic>;
        final createdAt = map['created_at'] != null
            ? DateTime.tryParse(map['created_at'] as String)
            : null;
        final departureTime = map['departure_time'] != null
            ? DateTime.tryParse(map['departure_time'] as String)
            : null;
        items.add(InboxItemModel(
          id: 'flight_${map['id']}',
          type: InboxItemType.flightBooking,
          timestamp: createdAt ?? departureTime ?? DateTime.now(),
          status: map['status'] as String? ?? '',
          airline: map['airline'] as String?,
          flightNumber: map['flight_number'] as String?,
          originCity: map['origin_city'] as String?,
          destinationCity: map['destination_city'] as String?,
          departureTime: departureTime,
        ));
      }

      // حجوزات السيارات
      final carRows = await _client
          .from('car_bookings')
          .select()
          .eq('user_id', myId)
          .order('created_at', ascending: false)
          .limit(limit);

      for (final row in (carRows as List)) {
        final map = row as Map<String, dynamic>;
        final createdAt = map['created_at'] != null
            ? DateTime.tryParse(map['created_at'] as String)
            : null;
        final pickupDate = map['pickup_date'] != null
            ? DateTime.tryParse(map['pickup_date'] as String)
            : null;
        items.add(InboxItemModel(
          id: 'car_${map['id']}',
          type: InboxItemType.carBooking,
          timestamp: createdAt ?? pickupDate ?? DateTime.now(),
          status: map['status'] as String? ?? '',
          carName: map['car_name'] as String?,
          carCompany: map['company'] as String?,
          pickupCity: map['pickup_city'] as String?,
          pickupDate: pickupDate,
        ));
      }

      // تنبيهات أسعار الطيران المفعّلة
      if (myEmail != null) {
        final watchRows = await _client
            .from('price_watches')
            .select()
            .eq('email', myEmail)
            .not('notified_at', 'is', null)
            .order('notified_at', ascending: false)
            .limit(limit);

        for (final row in (watchRows as List)) {
          final map = row as Map<String, dynamic>;
          final notifiedAt = map['notified_at'] != null
              ? DateTime.tryParse(map['notified_at'] as String)
              : null;
          items.add(InboxItemModel(
            id: 'watch_${map['id']}',
            type: InboxItemType.priceWatch,
            timestamp: notifiedAt ?? DateTime.now(),
            originCity: map['origin_city'] as String?,
            destinationCity: map['destination_city'] as String?,
            targetPrice: (map['target_price'] as num?)?.toDouble(),
          ));
        }
      }

      items.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return Success(items);
    } catch (e) {
      return Failure(e.toString());
    }
  }
}