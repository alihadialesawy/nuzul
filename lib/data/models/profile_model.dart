/// يمثل بيانات حساب المستخدم الإضافية (جدول profiles) — الإيميل نفسه
/// بييجي من auth.users مش من هنا.
class ProfileModel {
  final String id;
  final String? fullName; // الاسم القانوني (Legal name)
  final String? displayName;
  final String? bio;
  final DateTime? dateOfBirth;
  final String? gender;
  final String? phone;
  final String? emergencyContact;
  final String? address;
  final String? nationality;
  final String? cityOfResidence;
  final String? frequentlyVisitedCity;
  final String role; // 'user' أو 'admin' — يحدد صلاحية الوصول للوحة الأدمن

  const ProfileModel({
    required this.id,
    this.fullName,
    this.displayName,
    this.bio,
    this.dateOfBirth,
    this.gender,
    this.phone,
    this.emergencyContact,
    this.address,
    this.nationality,
    this.cityOfResidence,
    this.frequentlyVisitedCity,
    this.role = 'user',
  });

  bool get isAdmin => role == 'admin';

  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    return ProfileModel(
      id: json['id'] as String,
      fullName: json['full_name'] as String?,
      displayName: json['display_name'] as String?,
      bio: json['bio'] as String?,
      dateOfBirth: json['date_of_birth'] == null
          ? null
          : DateTime.parse(json['date_of_birth'] as String),
      gender: json['gender'] as String?,
      phone: json['phone'] as String?,
      emergencyContact: json['emergency_contact'] as String?,
      address: json['address'] as String?,
      nationality: json['nationality'] as String?,
      cityOfResidence: json['city_of_residence'] as String?,
      frequentlyVisitedCity: json['frequently_visited_city'] as String?,
      role: json['role'] as String? ?? 'user',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'full_name': fullName,
      'display_name': displayName,
      'bio': bio,
      'date_of_birth': dateOfBirth == null
          ? null
          : '${dateOfBirth!.year.toString().padLeft(4, '0')}-${dateOfBirth!.month.toString().padLeft(2, '0')}-${dateOfBirth!.day.toString().padLeft(2, '0')}',
      'gender': gender,
      'phone': phone,
      'emergency_contact': emergencyContact,
      'address': address,
      'nationality': nationality,
      'city_of_residence': cityOfResidence,
      'frequently_visited_city': frequentlyVisitedCity,
      // ملاحظة: role عمدًا مش متضمّن هنا — تحديث الصلاحية لازم يصير من
      // لوحة الأدمن أو قاعدة البيانات مباشرة، مش من upsertMyProfile
      // العادي اللي بيستخدمه أي مستخدم لتحديث بياناته الشخصية.
    };
  }

  ProfileModel copyWith({
    String? fullName,
    String? displayName,
    String? bio,
    DateTime? dateOfBirth,
    String? gender,
    String? phone,
    String? emergencyContact,
    String? address,
    String? nationality,
    String? cityOfResidence,
    String? frequentlyVisitedCity,
    String? role,
  }) {
    return ProfileModel(
      id: id,
      fullName: fullName ?? this.fullName,
      displayName: displayName ?? this.displayName,
      bio: bio ?? this.bio,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      gender: gender ?? this.gender,
      phone: phone ?? this.phone,
      emergencyContact: emergencyContact ?? this.emergencyContact,
      address: address ?? this.address,
      nationality: nationality ?? this.nationality,
      cityOfResidence: cityOfResidence ?? this.cityOfResidence,
      frequentlyVisitedCity: frequentlyVisitedCity ?? this.frequentlyVisitedCity,
      role: role ?? this.role,
    );
  }
}