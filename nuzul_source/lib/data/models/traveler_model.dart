/// مسافر محفوظ في ملف المستخدم، يُستخدم لملء بيانات المسافرين تلقائيًا
/// وقت الحجز بدل إدخالها من الصفر كل مرة.
class TravelerModel {
  final String id;
  final String fullName;
  final DateTime? dateOfBirth;
  final String? passportNumber;
  final String? passportIssuingCountry;
  final DateTime? passportExpiry;

  const TravelerModel({
    required this.id,
    required this.fullName,
    this.dateOfBirth,
    this.passportNumber,
    this.passportIssuingCountry,
    this.passportExpiry,
  });

  factory TravelerModel.fromJson(Map<String, dynamic> json) {
    return TravelerModel(
      id: json['id'] as String,
      fullName: json['full_name'] as String? ?? '',
      dateOfBirth: json['date_of_birth'] != null ? DateTime.parse(json['date_of_birth'] as String) : null,
      passportNumber: json['passport_number'] as String?,
      passportIssuingCountry: json['passport_issuing_country'] as String?,
      passportExpiry: json['passport_expiry'] != null ? DateTime.parse(json['passport_expiry'] as String) : null,
    );
  }

  Map<String, dynamic> toInsertJson(String userId) {
    return {
      'user_id': userId,
      'full_name': fullName,
      'date_of_birth': dateOfBirth != null ? _formatDate(dateOfBirth!) : null,
      'passport_number': passportNumber,
      'passport_issuing_country': passportIssuingCountry,
      'passport_expiry': passportExpiry != null ? _formatDate(passportExpiry!) : null,
    };
  }

  static String _formatDate(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}