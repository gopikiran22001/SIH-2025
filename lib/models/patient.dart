class Patient {
  final String id;
  final String? bloodGroup;
  final Map<String, dynamic>? emergencyContact;

  Patient({
    required this.id,
    this.bloodGroup,
    this.emergencyContact,
  });

  factory Patient.fromJson(Map<String, dynamic> json) {
    return Patient(
      id: json['id'],
      bloodGroup: json['blood_group'],
      emergencyContact: json['emergency_contact'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'blood_group': bloodGroup,
      'emergency_contact': emergencyContact,
    };
  }
}