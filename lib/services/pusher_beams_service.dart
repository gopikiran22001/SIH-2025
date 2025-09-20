import 'package:firebase_messaging/firebase_messaging.dart';
import 'supabase_service.dart';
import 'firebase_notification_service.dart';

import '../utils/app_router.dart';
import '../config/pusher_config.dart';

class PusherBeamsService {
  static FirebaseMessaging? _messaging;
  
  static Future<void> initialize() async {
    try {
      _messaging = FirebaseMessaging.instance;
      await _messaging!.requestPermission();
      print('DEBUG: Firebase Messaging initialized');
    } catch (e) {
      print('DEBUG: Error initializing Firebase Messaging: $e');
    }
  }
  
  static Future<void> onUserLogin(String userId) async {
    try {
      if (_messaging == null) return;
      
      // Subscribe to topic
      await _messaging!.subscribeToTopic('user_$userId');
      print('DEBUG: Subscribed to topic: user_$userId');
      
      // Save FCM token to database
      final token = await _messaging!.getToken();
      if (token != null) {
        await SupabaseService.saveFcmToken(userId, token);
        print('DEBUG: FCM token saved to database');
      }
    } catch (e) {
      print('DEBUG: Error in onUserLogin: $e');
    }
  }
  
  static Future<void> onUserLogout(String userId) async {
    print('DEBUG: Pusher Beams user logout temporarily disabled for: $userId');
  }
  
  static Future<void> sendCallNotification({
    required String targetUserId,
    required String callerName,
    required String consultationId,
    required String roomId,
  }) async {
    try {
      print('DEBUG: sendCallNotification called for user: $targetUserId');
      print('DEBUG: Caller: $callerName, ConsultationId: $consultationId, RoomId: $roomId');
      
      final notificationPayload = {
        'interests': [PusherConfig.userInterest(targetUserId)],
        'web': {
          'notification': {
            'title': 'Incoming Video Call',
            'body': '$callerName is calling you',
            'deep_link': '${PusherConfig.deepLinkScheme}://video-call?consultationId=$consultationId&roomId=$roomId&callerName=$callerName',
            'icon': 'https://your-app-icon-url.com/icon.png',
          }
        },
        'apns': {
          'aps': {
            'alert': {
              'title': 'Incoming Video Call',
              'body': '$callerName is calling you',
            },
            'sound': 'default',
            'badge': 1,
          },
          'data': {
            'type': 'call',
            'consultation_id': consultationId,
            'room_id': roomId,
            'caller_name': callerName,
          }
        },
        'fcm': {
          'notification': {
            'title': 'Incoming Video Call',
            'body': '$callerName is calling you',
          },
          'data': {
            'type': 'call',
            'consultation_id': consultationId,
            'room_id': roomId,
            'caller_name': callerName,
            'click_action': 'FLUTTER_NOTIFICATION_CLICK',
          },
          'android': {
            'priority': 'high',
            'notification': {
              'channel_id': 'incoming_calls',
              'priority': 'high',
              'visibility': 'public',
              'show_when': true,
              'ongoing': true,
              'auto_cancel': false,
              'full_screen_intent': true,
              'category': 'call'
            }
          }
        }
      };
      
      print('DEBUG: Getting FCM token for target user...');
      
      // Get FCM token for the target user from database
      final targetToken = await SupabaseService.getFcmToken(targetUserId);
      
      if (targetToken == null) {
        print('DEBUG: No FCM token found for user: $targetUserId');
        return;
      }
      
      print('DEBUG: Found FCM token for user: ${targetToken.substring(0, 20)}...');
      print('DEBUG: Calling Supabase Edge Function: send-push-notification');
      
      final response = await SupabaseService.client.functions.invoke(
        'send-push-notification',
        body: {
          'token': targetToken,
          'title': 'Incoming Video Call',
          'body': '$callerName is calling you',
          'data': {
            'type': 'call',
            'consultation_id': consultationId,
            'room_id': roomId,
            'caller_name': callerName,
          },
          'android': {
            'priority': 'high',
            'ttl': '30s',
            'notification': {
              'channel_id': 'incoming_calls',
              'priority': 'high',
              'visibility': 'public',
              'show_when': true,
              'ongoing': true,
              'auto_cancel': false,
              'category': 'call',
              'full_screen_intent': {
                'click_action': 'FLUTTER_NOTIFICATION_CLICK'
              }
            }
          }
        },
      );
      
      print('DEBUG: Edge Function response status: ${response.status}');
      print('DEBUG: Edge Function response data: ${response.data}');
      
      if (response.status == 200) {
        print('DEBUG: FCM notification sent successfully');
      } else {
        print('DEBUG: FCM notification failed: ${response.data}');
      }
      
    } catch (e) {
      print('DEBUG: EXCEPTION in sendCallNotification: $e');
    }
  }
  
  static Future<void> _handleForegroundMessage(Map<Object?, Object?> data) async {
    print('DEBUG: Foreground notification received: $data');
    
    final notificationData = data['data'] as Map<Object?, Object?>?;
    if (notificationData?['type'] == 'call') {
      await _showIncomingCallUI(notificationData);
    }
  }
  
  static Future<void> _showIncomingCallUI(Map<Object?, Object?>? data) async {
    if (data == null) return;
    
    final consultationId = data['consultation_id']?.toString() ?? '';
    final roomId = data['room_id']?.toString() ?? '';
    final callerName = data['caller_name']?.toString() ?? 'Unknown';
    
    if (consultationId.isEmpty || roomId.isEmpty) return;
    
    print('DEBUG: Showing incoming call screen for: $callerName');
    
    // Navigate to incoming call screen first
    AppRouter.pushReplacement(
      '/incoming-call',
      arguments: {
        'consultationId': consultationId,
        'roomId': roomId,
        'callerName': callerName,
      },
    );
  }
  
  static Future<void> handleNotificationTap(Map<String, dynamic> data) async {
    print('DEBUG: Notification tapped with data: $data');
    
    if (data['type'] == 'call') {
      await _showIncomingCallUI(data);
    }
  }
  
  static Future<List<String>> getDeviceInterests() async {
    try {
      final token = await _messaging?.getToken();
      return token != null ? [token] : [];
    } catch (e) {
      print('DEBUG: Error getting FCM token: $e');
      return [];
    }
  }
  
  static Future<void> endCall(String callId) async {
    print('DEBUG: Call ended: $callId');
  }
}