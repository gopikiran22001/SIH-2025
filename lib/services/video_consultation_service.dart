import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_service.dart';
import 'notification_service.dart';
import 'hms_consultation_service.dart';

class VideoConsultationService {
  static Future<Map<String, dynamic>> createConsultation({
    required String patientId,
    required String doctorId,
    required String symptoms,
  }) async {
    // Delegate to HMS consultation service
    final consultation = await HMSConsultationService.createVideoConsultation(
      patientId: patientId,
      doctorId: doctorId,
      symptoms: symptoms,
    );
    
    if (consultation == null) {
      throw Exception('Failed to create consultation');
    }
    
    return consultation;
  }

  static Future<void> _sendConsultationNotification({
    required String doctorId,
    required String patientName,
    required String symptoms,
    required String consultationId,
  }) async {
    // Disable notifications for now to focus on video connection
    print('DEBUG: Consultation created - Doctor: $doctorId, Patient: $patientName');
  }

  static Future<void> _sendFCMNotification({
    required String token,
    required String title,
    required String body,
    Map<String, String>? data,
  }) async {
    try {
      // FCM Server Key - In production, this should be stored securely on your backend
      const serverKey = 'YOUR_FCM_SERVER_KEY'; // Replace with your actual server key
      
      final response = await http.post(
        Uri.parse('https://fcm.googleapis.com/fcm/send'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'key=$serverKey',
        },
        body: jsonEncode({
          'to': token,
          'notification': {
            'title': title,
            'body': body,
            'sound': 'default',
            'priority': 'high',
          },
          'data': data ?? {},
          'priority': 'high',
        }),
      );
      
      if (response.statusCode == 200) {
        print('DEBUG: FCM notification sent successfully');
      } else {
        print('DEBUG: FCM notification failed: ${response.statusCode} - ${response.body}');
        // Fallback to local notification for testing
        await NotificationService.sendConsultationNotification(
          doctorId: '',
          patientName: data?['patient_name'] ?? 'Patient',
          symptoms: body.split('for: ').last,
          consultationId: data?['consultation_id'] ?? '',
        );
      }
    } catch (e) {
      print('DEBUG: Failed to send FCM notification: $e');
      // Fallback to local notification for testing
      await NotificationService.sendConsultationNotification(
        doctorId: '',
        patientName: data?['patient_name'] ?? 'Patient',
        symptoms: body.split('for: ').last,
        consultationId: data?['consultation_id'] ?? '',
      );
    }
  }

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