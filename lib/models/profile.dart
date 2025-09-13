class Profile {
  final String id;
  final String role;
  final String? fullName;
  final String? phone;
  final String? gender;
  final DateTime? dob;
  final DateTime? createdAt;

  Profile({
    required this.id,
    required this.role,
    this.fullName,
    this.phone,
    this.gender,
    this.dob,
    this.createdAt,
  });

  factory Profile.fromJson(Map<String, dynamic> json) {
    return Profile(
      id: json['id'],
      role: json['role'],
      fullName: json['full_name'],
      phone: json['phone'],
      gender: json['gender'],
      dob: json['dob'] != null ? DateTime.parse(json['dob']) : null,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'role': role,
      'full_name': fullName,
      'phone': phone,
      'gender': gender,
      'dob': dob?.toIso8601String().split('T')[0],
      'created_at': createdAt?.toIso8601String(),
    };
  }
}