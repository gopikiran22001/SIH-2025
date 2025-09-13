class Prescription {
  final String id;
  final String? appointmentId;
  final String? patientId;
  final String? doctorId;
  final String? content;
  final String? filePath;
  final DateTime? createdAt;

  Prescription({
    required this.id,
    this.appointmentId,
    this.patientId,
    this.doctorId,
    this.content,
    this.filePath,
    this.createdAt,
  });

  factory Prescription.fromJson(Map<String, dynamic> json) {
    return Prescription(
      id: json['id'],
      appointmentId: json['appointment_id'],
      patientId: json['patient_id'],
      doctorId: json['doctor_id'],
      content: json['content'],
      filePath: json['file_path'],
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'appointment_id': appointmentId,
      'patient_id': patientId,
      'doctor_id': doctorId,
      'content': content,
      'file_path': filePath,
      'created_at': createdAt?.toIso8601String(),
    };
  }
}