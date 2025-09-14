import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../screens/common/hms_video_call_screen.dart';
import '../utils/app_router.dart';

class IncomingCallService {
  static Future<void> initialize() async {
    // Initialize with notification service
  }

  static Future<void> showIncomingCall({
    required String consultationId,
    required String callerName,
    required String callerType,
    required String patientId,
    required String doctorId,
    required String patientName,
    required String doctorName,
  }) async {
    // Show full-screen notification for incoming call
    await _showFullScreenNotification(
      consultationId: consultationId,
      callerName: callerName,
      callerType: callerType,
      patientId: patientId,
      doctorId: doctorId,
      patientName: patientName,
      doctorName: doctorName,
    );
  }

  static Future<void> _showFullScreenNotification({
    required String consultationId,
    required String callerName,
    required String callerType,
    required String patientId,
    required String doctorId,
    required String patientName,
    required String doctorName,
  }) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'incoming_call_channel',
      'Incoming Calls',
      channelDescription: 'Notifications for incoming video calls',
      importance: Importance.max,
      priority: Priority.high,
      fullScreenIntent: true,
      category: AndroidNotificationCategory.call,
      ongoing: true,
      autoCancel: false,
      actions: <AndroidNotificationAction>[
        AndroidNotificationAction(
          'accept_call',
          'Accept',
          icon: DrawableResourceAndroidBitmap('ic_call_accept'),
        ),
        AndroidNotificationAction(
          'decline_call',
          'Decline',
          icon: DrawableResourceAndroidBitmap('ic_call_decline'),
        ),
      ],
    );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
    );

    // This will be handled by NotificationService directly
    print('DEBUG: Incoming call notification handled by NotificationService');
  }

  static Future<void> handleNotificationAction(String action, String? payload) async {
    if (payload == null) return;
    
    final parts = payload.split('|');
    if (parts.length != 5) return;
    
    final consultationId = parts[0];
    final patientId = parts[1];
    final doctorId = parts[2];
    final patientName = parts[3];
    final doctorName = parts[4];

    if (action == 'accept_call') {
      // Navigate to video call screen
      final context = navigatorKey.currentContext;
      if (context != null) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => HMSVideoCallScreen(
              consultationId: consultationId,
              patientId: patientId,
              doctorId: doctorId,
              patientName: patientName,
              doctorName: doctorName,
            ),
          ),
        );
      }
    } else if (action == 'decline_call') {
      // Cancel handled by NotificationService
      print('DEBUG: Call declined');
    }
  }

  static Future<void> endCall(String callUUID) async {
    // Cancel handled by NotificationService
    print('DEBUG: Call ended: $callUUID');
  }
}

// Use the same navigator key as AppRouter
GlobalKey<NavigatorState> get navigatorKey => AppRouter.navigatorKey;