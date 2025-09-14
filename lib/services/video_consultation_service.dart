import 'supabase_service.dart';
import 'hms_consultation_service.dart';

class VideoConsultationService {
  static Future<Map<String, dynamic>> createConsultation({
    required String patientId,
    required String doctorId,
    required String symptoms,
    bool isPatientInitiated = true, // Default to patient calling doctor
  }) async {
    // Delegate to HMS consultation service
    final consultation = await HMSConsultationService.createVideoConsultation(
      patientId: patientId,
      doctorId: doctorId,
      symptoms: symptoms,
      isPatientInitiated: isPatientInitiated,
    );
    
    if (consultation == null) {
      throw Exception('Failed to create consultation');
    }
    
    return consultation;
  }

  // Removed old FCM logic - now handled by NotificationService

  static Future<void> startConsultation(String consultationId) async {
    // Handled by Zoom consultation service
  }

  static Future<void> endConsultation(String consultationId) async {
    await HMSConsultationService.endConsultation();
  }

  static Future<List<Map<String, dynamic>>> getConsultations(String userId, String role) async {
    return await HMSConsultationService.getConsultations(userId, role);
  }

  static Future<Map<String, dynamic>?> getActiveConsultation(String userId) async {
    try {
      final response = await SupabaseService.client
          .from('video_consultations')
          .select('*, profiles!video_consultations_patient_id_fkey(*), profiles!video_consultations_doctor_id_fkey(*)')
          .or('patient_id.eq.$userId,doctor_id.eq.$userId')
          .eq('status', 'active')
          .maybeSingle();
      
      return response;
    } catch (e) {
      return null;
    }
  }

  static Stream<Map<String, dynamic>?> subscribeToConsultationUpdates(String consultationId) {
    return HMSConsultationService.subscribeToConsultationUpdates(consultationId);
  }



  static Future<Map<String, dynamic>> createPrescriptionFromConsultation({
    required String consultationId,
    required String patientId,
    required String doctorId,
    required String content,
  }) async {
    await HMSConsultationService.createPrescriptionFromConsultation(
      consultationId: consultationId,
      patientId: patientId,
      doctorId: doctorId,
      content: content,
    );
    
    // Return a basic response for compatibility
    return {
      'id': consultationId,
      'consultation_id': consultationId,
      'patient_id': patientId,
      'doctor_id': doctorId,
      'content': content,
      'created_at': DateTime.now().toIso8601String(),
    };
  }
}