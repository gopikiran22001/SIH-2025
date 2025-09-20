import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class FirebaseNotificationService {
  static const String _serverKey = 'YOUR_FIREBASE_SERVER_KEY'; // Replace with actual server key
  static const String _fcmUrl = 'https://fcm.googleapis.com/fcm/send';
  
  static Future<void> sendCallNotification({
    required String targetUserId,
    required String callerName,
    required String consultationId,
    required String roomId,
  }) async {
    try {
      print('DEBUG: FirebaseNotificationService.sendCallNotification called');
      print('DEBUG: Target User: $targetUserId, Caller: $callerName');
      
      // Send to topic instead of individual token for simplicity
      final topicName = 'user_$targetUserId';
      
      final notification = {
        'to': '/topics/$topicName',
        'notification': {
          'title': 'Incoming Video Call',
          'body': '$callerName is calling you',
          'sound': 'default',
          'click_action': 'FLUTTER_NOTIFICATION_CLICK',
        },
        'data': {
          'type': 'call',
          'consultation_id': consultationId,
          'room_id': roomId,
          'caller_name': callerName,
        },
        'priority': 'high',
        'android': {
          'priority': 'high',
          'notification': {
            'channel_id': 'video_calls',
            'sound': 'default',
          }
        },
        'apns': {
          'payload': {
            'aps': {
              'alert': {
                'title': 'Incoming Video Call',
                'body': '$callerName is calling you',
              },
              'sound': 'default',
              'badge': 1,
            }
          }
        }
      };
      
      // For now, just log the notification that would be sent
      print('DEBUG: Would send FCM notification:');
      print('DEBUG: Topic: $topicName');
      print('DEBUG: Title: Incoming Video Call');
      print('DEBUG: Body: $callerName is calling you');
      print('DEBUG: Data: ${notification['data']}');
      
      // TODO: Implement actual FCM server-side sending when server key is available
      // This requires a backend service or Supabase Edge Function with proper FCM credentials
      
      print('DEBUG: Notification logged successfully (server implementation needed)');
      
    } catch (e) {
      print('DEBUG: Error in FirebaseNotificationService: $e');
    }
  }
  
  static Future<void> sendTestNotification(String targetUserId) async {
    await sendCallNotification(
      targetUserId: targetUserId,
      callerName: 'Test Doctor',
      consultationId: 'test-consultation-id',
      roomId: 'test-room-id',
    );
  }
}