import 'dart:math';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_service.dart';
import 'notification_service.dart';
import 'agora_token_service.dart';

class VideoConsultationService {
  static Future<Map<String, dynamic>> createConsultation({
    required String patientId,
    required String doctorId,
    required String symptoms,
  }) async {
    print('DEBUG: Starting consultation creation');
    print('DEBUG: Patient ID: $patientId');
    print('DEBUG: Doctor ID: $doctorId');
    print('DEBUG: Symptoms: $symptoms');
    
    try {
      final channelName = 'consultation_${DateTime.now().millisecondsSinceEpoch}';
      
      // Use empty tokens for Agora testing mode
      final patientToken = '';
      final doctorToken = '';
      
      print('DEBUG: Generated channel name: $channelName');
      print('DEBUG: Using empty tokens for testing mode');
      
      final consultationData = {
        'patient_id': patientId,
        'doctor_id': doctorId,
        'channel_name': channelName,
        'patient_token': patientToken,
        'doctor_token': doctorToken,
        'symptoms': symptoms,
        'status': 'pending',
      };
      
      print('DEBUG: Consultation data to insert: $consultationData');
      print('DEBUG: About to insert into video_consultations table');

      final response = await SupabaseService.client
          .from('video_consultations')
          .insert(consultationData)
          .select()
          .single();
          
      print('DEBUG: Insert successful, response: $response');
      
      // Send notification to doctor
      try {
        final patientProfile = await SupabaseService.getProfile(patientId);
        await _sendConsultationNotification(
          doctorId: doctorId,
          patientName: patientProfile?['full_name'] ?? 'Patient',
          symptoms: symptoms,
          consultationId: response['id'],
        );
        print('DEBUG: Notification sent successfully');
      } catch (notificationError) {
        print('DEBUG: Notification failed but continuing: $notificationError');
      }

      print('DEBUG: Consultation creation completed successfully');
      return response;
    } catch (e) {
      print('DEBUG: Consultation creation failed with error: $e');
      print('DEBUG: Error type: ${e.runtimeType}');
      if (e is PostgrestException) {
        print('DEBUG: PostgrestException details:');
        print('DEBUG: - Code: ${e.code}');
        print('DEBUG: - Message: ${e.message}');
        print('DEBUG: - Details: ${e.details}');
        print('DEBUG: - Hint: ${e.hint}');
      }
      throw Exception('Failed to create consultation: $e');
    }
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
    await SupabaseService.client
        .from('video_consultations')
        .update({
          'status': 'active',
          'started_at': DateTime.now().toIso8601String(),
        })
        .eq('id', consultationId);
  }

  static Future<void> endConsultation(String consultationId) async {
    await SupabaseService.client
        .from('video_consultations')
        .update({
          'status': 'completed',
          'ended_at': DateTime.now().toIso8601String(),
        })
        .eq('id', consultationId);
  }

  static Future<List<Map<String, dynamic>>> getConsultations(String userId, String role) async {
    try {
      final column = role == 'patient' ? 'patient_id' : 'doctor_id';
      
      final consultations = await SupabaseService.client
          .from('video_consultations')
          .select('*')
          .eq(column, userId)
          .order('created_at', ascending: false);
      
      // Add patient names directly
      for (final consultation in consultations) {
        if (role == 'doctor') {
          final patientId = consultation['patient_id'];
          try {
            final patientProfile = await SupabaseService.client
                .from('profiles')
                .select('full_name')
                .eq('id', patientId)
                .single();
            consultation['patient_name'] = patientProfile['full_name'];
          } catch (e) {
            consultation['patient_name'] = 'Unknown Patient';
          }
        }
      }
      
      return List<Map<String, dynamic>>.from(consultations);
    } catch (e) {
      print('DEBUG: Error fetching consultations: $e');
      return [];
    }
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
    return SupabaseService.client
        .from('video_consultations')
        .stream(primaryKey: ['id'])
        .eq('id', consultationId)
        .map((data) => data.isNotEmpty ? data.first : null);
  }



  static Future<Map<String, dynamic>> createPrescriptionFromConsultation({
    required String consultationId,
    required String patientId,
    required String doctorId,
    required String content,
  }) async {
    try {
      final prescriptionData = {
        'consultation_id': consultationId,
        'patient_id': patientId,
        'doctor_id': doctorId,
        'content': content,
      };

      final response = await SupabaseService.client
          .from('prescriptions')
          .insert(prescriptionData)
          .select()
          .single();

      return response;
    } catch (e) {
      throw Exception('Failed to create prescription: $e');
    }
  }
}