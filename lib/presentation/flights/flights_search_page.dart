import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';

enum _TripType { roundtrip, oneWay, multiCity }

/// شاشة بحث رحلات الطيران (نسخة تشخيصية: بدون LayoutBuilder، تخطيط
/// عمودي ثابت طول الوقت) لعزل سبب الكراش.
class FlightsSearchPage extends StatefulWidget {
  const FlightsSearchPage({super.key});

  @override
  State<FlightsSearchPage> createState() => _FlightsSearchPageState();
}

class _FlightsSearchPageState extends State<FlightsSearchPage> {
  _TripType _tripType = _TripType.roundtrip;
  final _fromController = TextEditingController();
  final _toController = TextEditingController();

  @override
  void dispose() {
    _fromController.dispose();
    _toController.dispose();
    super.dispose();
  }

  void _search() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Flight search is coming soon'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    return Scaffold(
      appBar: AppBar(
        title: Text(isArabic ? 'رحلات الطيران' : 'Flights'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSizes.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                isArabic ? 'ذهاب وعودة' : 'Roundtrip',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: AppSizes.md),
              Container(
                height: 56,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                  border: Border.all(color: AppColors.divider),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.location_on_outlined, size: 20, color: AppColors.textSecondary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _fromController,
                        decoration: InputDecoration(
                          hintText: isArabic ? 'المغادرة من' : 'Leaving from',
                          border: InputBorder.none,
                          isDense: true,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSizes.sm),
              Container(
                height: 56,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                  border: Border.all(color: AppColors.divider),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.location_on_outlined, size: 20, color: AppColors.textSecondary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _toController,
                        decoration: InputDecoration(
                          hintText: isArabic ? 'الوجهة' : 'Going to',
                          border: InputBorder.none,
                          isDense: true,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSizes.md),
              ElevatedButton(
                onPressed: _search,
                child: Text(isArabic ? 'بحث' : 'Search'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}