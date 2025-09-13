class AiAssessment {
  final String id;
  final String? patientId;
  final Map<String, dynamic>? symptoms;
  final Map<String, dynamic>? result;
  final DateTime? createdAt;

  AiAssessment({
    required this.id,
    this.patientId,
    this.symptoms,
    this.result,
    this.createdAt,
  });

  factory AiAssessment.fromJson(Map<String, dynamic> json) {
    return AiAssessment(
      id: json['id'],
      patientId: json['patient_id'],
      symptoms: json['symptoms'],
      result: json['result'],
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'patient_id': patientId,
      'symptoms': symptoms,
      'result': result,
      'created_at': createdAt?.toIso8601String(),
    };
  }
}