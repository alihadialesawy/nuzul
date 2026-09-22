/// يمثّل وجهة HotelBeds مخزّنة محليًا في جدول hotelbeds_destinations
/// (اتملى عن طريق `hotelbeds-sync-destinations` Edge Function).
/// `code` هو كود الوجهة الرسمي المطلوب لاستدعاء `hotelbeds-search`
/// (زي BCN، RUH)، مش اسم حر.
class DestinationModel {
  final String code;
  final String name;
  final String? countryCode;

  DestinationModel({
    required this.code,
    required this.name,
    this.countryCode,
  });

  factory DestinationModel.fromJson(Map<String, dynamic> json) {
    return DestinationModel(
      code: json['code'] as String,
      name: json['name'] as String,
      countryCode: json['country_code'] as String?,
    );
  }
}

/// ملخّص دولة واحدة لعرضها في شاشة "تصفح حسب الدولة" — كود الدولة
/// وعدد المدن المزامنة منها في hotelbeds_destinations.
class CountrySummary {
  final String countryCode;
  final int cityCount;

  CountrySummary({required this.countryCode, required this.cityCount});
}