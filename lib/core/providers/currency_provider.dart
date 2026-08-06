import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/currency_service.dart';

/// العملات المدعومة لعرض الأسعار. التخزين والحجز الفعلي في قاعدة
/// البيانات يبقى دائمًا بالريال السعودي (SAR)؛ اختيار العملة هنا
/// تفضيل عرض فقط.
enum AppCurrency {
  usd,
  sar,
  eur,
  gbp,
  cad,
  try_,
  aed,
  idr,
  jpy,
  mxn,
  pkr,
  inr,
  cop,
}

extension AppCurrencySymbol on AppCurrency {
  String get symbol {
    switch (this) {
      case AppCurrency.sar:
        return 'ر.س';
      case AppCurrency.usd:
        return '\$';
      case AppCurrency.eur:
        return '€';
      case AppCurrency.gbp:
        return '£';
      case AppCurrency.cad:
        return 'C\$';
      case AppCurrency.try_:
        return '₺';
      case AppCurrency.aed:
        return 'د.إ';
      case AppCurrency.idr:
        return 'Rp';
      case AppCurrency.jpy:
        return '¥';
      case AppCurrency.mxn:
        return 'Mex\$';
      case AppCurrency.pkr:
        return '₨';
      case AppCurrency.inr:
        return '₹';
      case AppCurrency.cop:
        return 'COL\$';
    }
  }

  String get code {
    switch (this) {
      case AppCurrency.sar:
        return 'SAR';
      case AppCurrency.usd:
        return 'USD';
      case AppCurrency.eur:
        return 'EUR';
      case AppCurrency.gbp:
        return 'GBP';
      case AppCurrency.cad:
        return 'CAD';
      case AppCurrency.try_:
        return 'TRY';
      case AppCurrency.aed:
        return 'AED';
      case AppCurrency.idr:
        return 'IDR';
      case AppCurrency.jpy:
        return 'JPY';
      case AppCurrency.mxn:
        return 'MXN';
      case AppCurrency.pkr:
        return 'PKR';
      case AppCurrency.inr:
        return 'INR';
      case AppCurrency.cop:
        return 'COP';
    }
  }

  /// إيموجي علم الدولة/الاتحاد المرتبط بالعملة
  String get flagEmoji {
    switch (this) {
      case AppCurrency.sar:
        return '🇸🇦';
      case AppCurrency.usd:
        return '🇺🇸';
      case AppCurrency.eur:
        return '🇪🇺';
      case AppCurrency.gbp:
        return '🇬🇧';
      case AppCurrency.cad:
        return '🇨🇦';
      case AppCurrency.try_:
        return '🇹🇷';
      case AppCurrency.aed:
        return '🇦🇪';
      case AppCurrency.idr:
        return '🇮🇩';
      case AppCurrency.jpy:
        return '🇯🇵';
      case AppCurrency.mxn:
        return '🇲🇽';
      case AppCurrency.pkr:
        return '🇵🇰';
      case AppCurrency.inr:
        return '🇮🇳';
      case AppCurrency.cop:
        return '🇨🇴';
    }
  }
}

class CurrencyNotifier extends StateNotifier<AppCurrency> {
  CurrencyNotifier() : super(AppCurrency.usd);

  void select(AppCurrency currency) => state = currency;
}

final selectedCurrencyProvider =
StateNotifierProvider<CurrencyNotifier, AppCurrency>((ref) {
  return CurrencyNotifier();
});

/// أسعار الصرف الفعلية (USD مقابل باقي العملات المدعومة)، تُجلب مرة
/// واحدة وتُخزَّن مؤقتًا (cache) طوال جلسة التطبيق عبر Riverpod's
/// FutureProvider.
final exchangeRatesProvider = FutureProvider<Map<String, double>>((ref) async {
  final service = CurrencyService();
  return service.fetchRatesPerUsd();
});

/// يحوّل مبلغًا بالريال السعودي (SAR) إلى العملة المطلوبة باستخدام
/// السعر الرسمي الثابت لليال (3.75 لكل دولار) وأسعار الصرف الفعلية
/// لباقي العملات مقابل الدولار.
double convertFromSar({
  required double sarAmount,
  required AppCurrency target,
  required Map<String, double> ratesPerUsd,
}) {
  if (target == AppCurrency.sar) return sarAmount;

  final usdAmount = sarAmount / CurrencyService.sarPerUsd;
  if (target == AppCurrency.usd) return usdAmount;

  final rate = ratesPerUsd[target.code] ?? 1.0;
  return usdAmount * rate;
}
double? convertToSar({
  required double amount,
  required String currencyCode,
  required Map<String, double> ratesPerUsd,
}) {
  final code = currencyCode.toUpperCase();
  if (code == 'SAR') return amount;
  if (code == 'USD') return amount * CurrencyService.sarPerUsd;

  final rate = ratesPerUsd[code];
  if (rate == null) return null;

  final usdAmount = amount / rate;
  return usdAmount * CurrencyService.sarPerUsd;
}
