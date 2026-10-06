import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/currency_provider.dart';
import 'currency_flag.dart';

/// زر يفتح قائمة لاختيار عملة العرض.
///
/// له شكلان:
/// - الافتراضي (footerStyle = false): صغير بنص أبيض، مصمَّم للشريط العلوي
///   فوق صورة البانر الداكنة.
/// - footerStyle = true: شريحة (chip) أكبر بخلفية بيضاء وإطار ونص داكن،
///   بنفس ارتفاع أيقونات التواصل الاجتماعي، لتُقرأ بوضوح على خلفية الفوتر
///   الفاتحة.
class CurrencySelectorButton extends ConsumerWidget {
  final bool footerStyle;

  const CurrencySelectorButton({super.key, this.footerStyle = false});

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
      case AppCurrency.bdt:
        return isArabic ? 'تاكا بنغلاديشية' : 'Bangladeshi Taka';
    }
  }

  List<PopupMenuEntry<AppCurrency>> _buildItems(
      AppCurrency current,
      bool isArabic,
      ) {
    return AppCurrency.values.map((currency) {
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
    }).toList();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final current = ref.watch(selectedCurrencyProvider);

    void onSelected(AppCurrency currency) =>
        ref.read(selectedCurrencyProvider.notifier).select(currency);

    if (footerStyle) {
      return PopupMenuButton<AppCurrency>(
        tooltip: '',
        position: PopupMenuPosition.over,
        onSelected: onSelected,
        itemBuilder: (context) => _buildItems(current, isArabic),
        child: Container(
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.black12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CurrencyFlag(currency: current, width: 24, height: 16),
              const SizedBox(width: 8),
              Text(
                current.code,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(width: 4),
              const Icon(
                Icons.keyboard_arrow_down_rounded,
                size: 20,
                color: Colors.black54,
              ),
            ],
          ),
        ),
      );
    }

    return PopupMenuButton<AppCurrency>(
      tooltip: '',
      padding: const EdgeInsets.all(8),
      icon: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CurrencyFlag(currency: current, width: 16, height: 11),
          const SizedBox(width: 3),
          Text(
            current.code,
            style: const TextStyle(fontSize: 10, color: Colors.white),
          ),
        ],
      ),
      onSelected: onSelected,
      itemBuilder: (context) => _buildItems(current, isArabic),
    );
  }
}