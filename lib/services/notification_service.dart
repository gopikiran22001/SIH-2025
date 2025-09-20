import 'supabase_service.dart';

import 'pusher_beams_service.dart';

// Notification service using Pusher Beams
class NotificationService {
  
  static Future<void> initialize() async {
    // Pusher Beams is initialized in main.dart
    print('DEBUG: NotificationService (Pusher Beams) initialized');
  }

  static Future<List<String>> getDeviceInterests() async {
    return await PusherBeamsService.getDeviceInterests();
  }

  static Future<void> subscribeToUserInterests(String userId) async {
    // Pusher Beams interests are managed automatically
    print('DEBUG: Pusher Beams interests managed via PusherBeamsService');
  }

  static Future<void> sendConsultationNotification({
    required String targetUserId,
    required String callerName,
    required String symptoms,
    required String consultationId,
  }) async {
    print('DEBUG: NotificationService.sendConsultationNotification called');
    print('DEBUG: Target User: $targetUserId, Caller: $callerName');
    print('DEBUG: Consultation ID: $consultationId, Symptoms: $symptoms');
    
    try {
      print('DEBUG: Fetching consultation room_id from database...');
      final consultation = await SupabaseService.client
          .from('video_consultations')
          .select('room_id')
          .eq('id', consultationId)
          .single();
      
      final roomId = consultation['room_id'] ?? '';
      print('DEBUG: Retrieved room_id: $roomId');
      
      if (roomId.isEmpty) {
        print('DEBUG: ERROR - Empty room_id for consultation: $consultationId');
        return;
      }
      
      print('DEBUG: Calling PusherBeamsService.sendCallNotification...');
      await PusherBeamsService.sendCallNotification(
        targetUserId: targetUserId,
        callerName: callerName,
        consultationId: consultationId,
        roomId: roomId,
      );
      print('DEBUG: PusherBeamsService.sendCallNotification completed');
    } catch (e) {
      print('DEBUG: EXCEPTION in sendConsultationNotification: $e');
      print('DEBUG: Exception type: ${e.runtimeType}');
    }
  }

  // Legacy method for backward compatibility
  static Future<void> sendConsultationNotificationLegacy({
    required String doctorId,
    required String patientName,
    required String symptoms,
    required String consultationId,
  }) async {
    await sendConsultationNotification(
      targetUserId: doctorId,
      callerName: patientName,
      symptoms: symptoms,
      consultationId: consultationId,
    );
  }

  static Future<void> cancelNotification(String consultationId) async {
    await PusherBeamsService.endCall(consultationId);
  }

  static Future<void> cancelAllNotifications() async {
    print('DEBUG: Cancel all notifications (Pusher Beams)');
  }
}