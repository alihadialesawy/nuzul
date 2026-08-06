import 'dart:convert';
import 'package:http/http.dart' as http;

/// يجلب أسعار الصرف الفعلية (USD مقابل باقي العملات المدعومة) من
/// Frankfurter API نسخة v2 (api.frankfurter.dev)، مجاني بدون مفتاح API.
///
/// ملاحظة: النسخة v1 القديمة (api.frankfurter.app) كانت تدعم فقط عملات
/// البنك المركزي الأوروبي (31 عملة)، وما كانتش تدعم AED/PKR/COP. النسخة
/// v2 تدعم 165 عملة فعلية وتغطي كل العملات المطلوبة هنا.
///
/// الريال السعودي غير مدعوم في مزودي أسعار الصرف (لأنه مربوط بسعر ثابت
/// رسميًا)، لذلك يُستخدم السعر الرسمي الثابت [sarPerUsd] = 3.75 للتحويل
/// من/إلى الريال، ثم تُستخدم الأسعار الفعلية المحدثة لتحويل الدولار إلى
/// باقي العملات.
class CurrencyService {
  /// السعر الرسمي الثابت للريال السعودي مقابل الدولار (منذ 1986)
  static const double sarPerUsd = 3.75;

  static const List<String> _supportedQuotes = [
    'EUR',
    'GBP',
    'CAD',
    'TRY',
    'AED',
    'IDR',
    'JPY',
    'MXN',
    'PKR',
    'INR',
    'COP',
  ];

  static final String _endpoint =
      'https://api.frankfurter.dev/v2/rates?base=USD&quotes=${_supportedQuotes.join(',')}';

  /// أسعار احتياطية تقريبية تُستخدم فقط لو فشل الاتصال بالإنترنت،
  /// عشان التطبيق يفضل شغال بدل ما يتعطل.
  static const Map<String, double> _fallbackRatesPerUsd = {
    'EUR': 0.92,
    'GBP': 0.79,
    'CAD': 1.38,
    'TRY': 40.5,
    'AED': 3.6725,
    'IDR': 16300,
    'JPY': 155,
    'MXN': 18.5,
    'PKR': 278,
    'INR': 86,
    'COP': 4100,
  };

  /// يرجع خريطة أسعار الصرف مقابل الدولار، مثال: {'EUR': 0.92, 'CAD': 1.38, ...}
  Future<Map<String, double>> fetchRatesPerUsd() async {
    try {
      final response = await http
          .get(Uri.parse(_endpoint))
          .timeout(const Duration(seconds: 8));

      if (response.statusCode != 200) return _fallbackRatesPerUsd;

      // v2 API بترجع مصفوفة مسطّحة، صف واحد لكل عملة:
      // [{"date":"...", "base":"USD", "quote":"EUR", "rate":0.92}, ...]
      final data = jsonDecode(response.body) as List<dynamic>;
      final rates = <String, double>{};
      for (final row in data) {
        final map = row as Map<String, dynamic>;
        final quote = map['quote'] as String?;
        final rate = map['rate'];
        if (quote != null && rate != null) {
          rates[quote] = (rate as num).toDouble();
        }
      }

      return rates.isEmpty ? _fallbackRatesPerUsd : rates;
    } catch (_) {
      return _fallbackRatesPerUsd;
    }
  }
}











