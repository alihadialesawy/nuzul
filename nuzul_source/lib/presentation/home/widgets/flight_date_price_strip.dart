import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../controllers/duffel_flight_search_controller.dart';

/// شريط أفقي بيعرض أرخص سعر رحلة فعلي (من Duffel) لكل يوم من 5 أيام
/// حوالين تاريخ المغادرة الحالي (يومين قبل، اليوم المختار، يومين بعد).
/// الهدف إن المستخدم ياخد فكرة سريعة عن أرخص وقت للسفر من غير ما يعمل
/// بحث يدوي منفصل لكل تاريخ. الضغط على أي تاريخ بيحدّثه كتاريخ مغادرة
/// جديد ويعيد البحث تلقائيًا (عبر onDateSelected).
class FlightDatePriceStrip extends StatelessWidget {
  final String origin;
  final String destination;
  final DateTime centerDate;
  final DateTime selectedDate;
  final int travelers;
  final String cabinClass;
  final bool nonstopOnly;
  final void Function(DateTime date) onDateSelected;

  const FlightDatePriceStrip({
    super.key,
    required this.origin,
    required this.destination,
    required this.centerDate,
    required this.selectedDate,
    required this.travelers,
    required this.cabinClass,
    required this.nonstopOnly,
    required this.onDateSelected,
  });

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final base = DateTime(centerDate.year, centerDate.month, centerDate.day);
    final dates = List.generate(5, (i) => base.add(Duration(days: i - 2)))
        .where((d) => !d.isBefore(DateTime(today.year, today.month, today.day)))
        .toList();

    return Container(
      color: Colors.white,
      height: 72,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSizes.md, vertical: 8),
        itemCount: dates.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final date = dates[index];
          final isSelected = date.year == selectedDate.year &&
              date.month == selectedDate.month &&
              date.day == selectedDate.day;

          return _DatePricePill(
            date: date,
            origin: origin,
            destination: destination,
            travelers: travelers,
            cabinClass: cabinClass,
            nonstopOnly: nonstopOnly,
            isSelected: isSelected,
            onTap: () => onDateSelected(date),
          );
        },
      ),
    );
  }
}

class _DatePricePill extends ConsumerWidget {
  final DateTime date;
  final String origin;
  final String destination;
  final int travelers;
  final String cabinClass;
  final bool nonstopOnly;
  final bool isSelected;
  final VoidCallback onTap;

  const _DatePricePill({
    required this.date,
    required this.origin,
    required this.destination,
    required this.travelers,
    required this.cabinClass,
    required this.nonstopOnly,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final params = {
      'origin': origin,
      'destination': destination,
      'departureDate': date,
      'travelers': travelers,
      'cabinClass': cabinClass,
      'nonstopOnly': nonstopOnly,
    };
    final resultsAsync = ref.watch(duffelFlightSearchResultsProvider(params));

    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    final dateLabel = '${months[date.month - 1]} ${date.day}';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 96,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: isSelected ? AppColors.primary : AppColors.divider),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              dateLabel,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? Colors.white : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 3),
            resultsAsync.when(
              loading: () => SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: isSelected ? Colors.white : AppColors.primary,
                ),
              ),
              error: (_, __) => Text(
                '—',
                style: TextStyle(fontSize: 12, color: isSelected ? Colors.white70 : AppColors.textHint),
              ),
              data: (offers) {
                if (offers.isEmpty) {
                  return Text(
                    '—',
                    style: TextStyle(fontSize: 12, color: isSelected ? Colors.white70 : AppColors.textHint),
                  );
                }
                final cheapest = offers.reduce(
                      (a, b) => a.totalAmount < b.totalAmount ? a : b,
                );
                return Text(
                  '${cheapest.totalAmount.toStringAsFixed(0)} ${cheapest.totalCurrency}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? Colors.white : AppColors.primary,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}