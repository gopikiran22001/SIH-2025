class Doctor {
  final String id;
  final String? specialization;
  final String? clinicName;
  final String? qualifications;
  final bool? verified;
  final double? rating;

  Doctor({
    required this.id,
    this.specialization,
    this.clinicName,
    this.qualifications,
    this.verified,
    this.rating,
  });

  factory Doctor.fromJson(Map<String, dynamic> json) {
    return Doctor(
      id: json['id'],
      specialization: json['specialization'],
      clinicName: json['clinic_name'],
      qualifications: json['qualifications'],
      verified: json['verified'],
      rating: json['rating']?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'specialization': specialization,
      'clinic_name': clinicName,
      'qualifications': qualifications,
      'verified': verified,
      'rating': rating,
    };
  }
}