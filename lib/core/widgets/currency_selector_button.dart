import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/currency_provider.dart';
import 'currency_flag.dart';

/// زر في شريط التطبيق يفتح قائمة لاختيار عملة العرض.
class CurrencySelectorButton extends ConsumerWidget {
  const CurrencySelectorButton({super.key});

  static String _label(AppCurrency currency, bool isArabic) {
    switch (currency) {
      case AppCurrency.sar:
        return isArabic ? 'ريال سعودي' : 'Saudi Riyal';
      case AppCurrency.usd:
        return isArabic ? 'دولار أمريكي' : 'US Dollar';
      case AppCurrency.eur:
        return isArabic ? 'يورو' : 'Euro';
      case AppCurrency.gbp:
        return isArabic ? 'جنيه إسترليني' : 'British Pound';
      case AppCurrency.cad:
        return isArabic ? 'دولار كندي' : 'Canadian Dollar';
      case AppCurrency.try_:
        return isArabic ? 'ليرة تركية' : 'Turkish Lira';
      case AppCurrency.aed:
        return isArabic ? 'درهم إماراتي' : 'UAE Dirham';
      case AppCurrency.idr:
        return isArabic ? 'روبية إندونيسية' : 'Indonesian Rupiah';
      case AppCurrency.jpy:
        return isArabic ? 'ين ياباني' : 'Japanese Yen';
      case AppCurrency.mxn:
        return isArabic ? 'بيزو مكسيكي' : 'Mexican Peso';
      case AppCurrency.pkr:
        return isArabic ? 'روبية باكستانية' : 'Pakistani Rupee';
      case AppCurrency.inr:
        return isArabic ? 'روبية هندية' : 'Indian Rupee';
      case AppCurrency.cop:
        return isArabic ? 'بيزو كولومبي' : 'Colombian Peso';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final current = ref.watch(selectedCurrencyProvider);

    return PopupMenuButton<AppCurrency>(
      tooltip: '',
      icon: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CurrencyFlag(currency: current),
          const SizedBox(width: 4),
          Text(
            current.code,
            style: const TextStyle(fontSize: 12, color: Colors.white),
          ),
        ],
      ),
      onSelected: (currency) =>
          ref.read(selectedCurrencyProvider.notifier).select(currency),
      itemBuilder: (context) => AppCurrency.values.map((currency) {
        return PopupMenuItem(
          value: currency,
          child: Row(
            children: [
              if (currency == current)
                const Icon(Icons.check, size: 18)
              else
                const SizedBox(width: 18),
              const SizedBox(width: 8),
              CurrencyFlag(currency: currency),
              const SizedBox(width: 8),
              Text(_label(currency, isArabic)),
            ],
          ),
        );
      }).toList(),
    );
  }
}