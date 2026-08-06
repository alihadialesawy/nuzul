import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/currency_provider.dart';

/// يعرض مبلغًا مخزَّنًا بالريال السعودي (SAR) محوّلًا تلقائيًا للعملة
/// المختارة حاليًا في التطبيق (ريال / دولار / يورو / جنيه إسترليني).
///
/// مثال الاستخدام:
/// ```dart
/// PriceText(sarAmount: hotel.pricePerNight, style: myTextStyle)
/// ```
class PriceText extends ConsumerWidget {
  final double sarAmount;
  final TextStyle? style;

  const PriceText({super.key, required this.sarAmount, this.style});

  static String _format(double amount) {
    // فاصلة الآلاف: 1234.5 -> 1,234.50 (لو عدد كسري) أو 1,234 (لو صحيح)
    final isWhole = amount == amount.roundToDouble();
    final decimals = isWhole ? 0 : 2;
    final fixed = amount.toStringAsFixed(decimals);
    final parts = fixed.split('.');
    final intPart = parts[0];
    final buffer = StringBuffer();
    for (int i = 0; i < intPart.length; i++) {
      if (i != 0 && (intPart.length - i) % 3 == 0) buffer.write(',');
      buffer.write(intPart[i]);
    }
    return parts.length > 1 ? '${buffer.toString()}.${parts[1]}' : buffer.toString();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currency = ref.watch(selectedCurrencyProvider);
    final ratesAsync = ref.watch(exchangeRatesProvider);

    final ratesPerUsd = ratesAsync.value ?? const {};
    final converted = convertFromSar(
      sarAmount: sarAmount,
      target: currency,
      ratesPerUsd: ratesPerUsd,
    );

    return Text('${_format(converted)} ${currency.symbol}', style: style);
  }
}