import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/utils/result.dart';
import '../models/booking_model.dart';
import '../models/inbox_item_model.dart';

class InboxRepository {
  final SupabaseClient _client = Supabase.instance.client;

  /// يجيب فييد الإنبوكس: أحدث حجوزات الفنادق + الطيران (Duffel) + السيارات،
  /// مع تنبيهات أسعار الطيران المفعّلة، مرتبين بالأحدث أولاً.
  ///
  /// كل مصدر (وكل صف داخله) معزول: لو فشل جدول أو صف واحد، يُطبع السبب
  /// في الـ console ويكمل الباقي، بدل ما تفشل الصفحة كلها.
  /// الفشل الكامل فقط لو فشلت كل المصادر.
  Future<Result<List<InboxItemModel>>> fetchInboxItems({int limit = 30}) async {
    final myId = _client.auth.currentUser?.id;
    final myEmail = _client.auth.currentUser?.email;
    if (myId == null) return const Failure('User not authenticated');

    final items = <InboxItemModel>[];
    final errors = <String>[];

    // ───── حجوزات الفنادق ─────
    await _safeSource('bookings', errors, () async {
      final rows = await _client
          .from('bookings')
          .select()
          .eq('user_id', myId)
          .order('created_at', ascending: false)
          .limit(limit);

      for (final row in (rows as List)) {
        _safeRow('bookings', row, () {
          final booking = BookingModel.fromJson(Map<String, dynamic>.from(row as Map));
          items.add(InboxItemModel(
            id: 'hotel_${booking.id}',
            type: InboxItemType.hotelBooking,
            timestamp: booking.createdAt ?? booking.checkIn,
            status: booking.status,
            hotelBooking: booking,
          ));
        });
      }
    });

    // ───── حجوزات الطيران (duffel_bookings) ─────
    await _safeSource('duffel_bookings', errors, () async {
      final rows = await _client
          .from('duffel_bookings')
          .select()
          .eq('user_id', myId)
          .order('created_at', ascending: false)
          .limit(limit);

      for (final row in (rows as List)) {
        _safeRow('duffel_bookings', row, () {
          final map = Map<String, dynamic>.from(row as Map);
          final createdAt = _date(map['created_at']);
          final departureTime = _date(map['departure_time']);
          items.add(InboxItemModel(
            id: 'flight_${map['id']}',
            type: InboxItemType.flightBooking,
            timestamp: createdAt ?? departureTime ?? DateTime.now(),
            status: map['status'] as String? ?? 'confirmed',
            airline: map['airline'] as String?,
            flightNumber: map['flight_number'] as String?,
            originCity: map['origin_city'] as String?,
            destinationCity: map['destination_city'] as String?,
            departureTime: departureTime,
          ));
        });
      }
    });

    // ───── حجوزات السيارات ─────
    await _safeSource('car_bookings', errors, () async {
      final rows = await _client
          .from('car_bookings')
          .select()
          .eq('user_id', myId)
          .order('created_at', ascending: false)
          .limit(limit);

      for (final row in (rows as List)) {
        _safeRow('car_bookings', row, () {
          final map = Map<String, dynamic>.from(row as Map);
          final createdAt = _date(map['created_at']);
          final pickupDate = _date(map['pickup_date']);
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
        });
      }
    });

    // ───── تنبيهات أسعار الطيران المفعّلة ─────
    if (myEmail != null) {
      await _safeSource('price_watches', errors, () async {
        final rows = await _client
            .from('price_watches')
            .select()
            .eq('email', myEmail)
            .not('notified_at', 'is', null)
            .order('notified_at', ascending: false)
            .limit(limit);

        for (final row in (rows as List)) {
          _safeRow('price_watches', row, () {
            final map = Map<String, dynamic>.from(row as Map);
            items.add(InboxItemModel(
              id: 'watch_${map['id']}',
              type: InboxItemType.priceWatch,
              timestamp: _date(map['notified_at']) ?? DateTime.now(),
              originCity: map['origin_city'] as String?,
              destinationCity: map['destination_city'] as String?,
              targetPrice: (map['target_price'] as num?)?.toDouble(),
            ));
          });
        }
      });
    }

    // فشل كامل فقط لو كل المصادر فشلت ومفيش أي عنصر.
    final sourceCount = myEmail != null ? 4 : 3;
    if (items.isEmpty && errors.length >= sourceCount) {
      return Failure(errors.join(' | '));
    }

    items.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return Success(items);
  }

  static DateTime? _date(dynamic v) => v is String ? DateTime.tryParse(v) : null;

  Future<void> _safeSource(String name, List<String> errors, Future<void> Function() load) async {
    try {
      await load();
    } catch (e) {
      // print (وليس debugPrint) حتى يظهر في Terminal الخاص بـ flutter run وفي console المتصفح.
      // ignore: avoid_print
      print('🔴 INBOX SOURCE FAILED [$name]: $e');
      errors.add('$name: $e');
    }
  }

  void _safeRow(String source, dynamic row, void Function() parse) {
    try {
      parse();
    } catch (e) {
      final id = row is Map ? row['id'] : null;
      // ignore: avoid_print
      print('🔴 INBOX ROW SKIPPED [$source id=$id]: $e');
    }
  }
}