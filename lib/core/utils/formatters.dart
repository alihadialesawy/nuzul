import 'package:intl/intl.dart';

/// دوال تنسيق مشتركة (تواريخ، عملة) تستخدم بشاشات الحجوزات والفنادق
class Formatters {
  Formatters._();

  static final DateFormat _dateFormat = DateFormat('dd/MM/yyyy', 'ar');
  static final DateFormat _dateTimeFormat = DateFormat('dd/MM/yyyy - hh:mm a', 'ar');

  static String date(DateTime date) => _dateFormat.format(date);

  static String dateTime(DateTime date) => _dateTimeFormat.format(date);

  static String currency(double amount, {String symbol = 'ر.س'}) {
    final formatted = NumberFormat('#,##0.00', 'en').format(amount);
    return '$formatted $symbol';
  }

  static String nights(DateTime checkIn, DateTime checkOut) {
    final count = checkOut.difference(checkIn).inDays;
    return count == 1 ? 'ليلة واحدة' : '$count ليالٍ';
  }
}