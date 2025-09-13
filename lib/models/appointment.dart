class Appointment {
  final String id;
  final String? patientId;
  final String? doctorId;
  final DateTime scheduledAt;
  final String status;
  final Map<String, dynamic>? videoSession;
  final DateTime? createdAt;

  Appointment({
    required this.id,
    this.patientId,
    this.doctorId,
    required this.scheduledAt,
    required this.status,
    this.videoSession,
    this.createdAt,
  });

  factory Appointment.fromJson(Map<String, dynamic> json) {
    return Appointment(
      id: json['id'],
      patientId: json['patient_id'],
      doctorId: json['doctor_id'],
      scheduledAt: DateTime.parse(json['scheduled_at']),
      status: json['status'],
      videoSession: json['video_session'],
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'patient_id': patientId,
      'doctor_id': doctorId,
      'scheduled_at': scheduledAt.toIso8601String(),
      'status': status,
      'video_session': videoSession,
      'created_at': createdAt?.toIso8601String(),
    };
  }
}