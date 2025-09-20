import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'dart:typed_data';
import '../utils/app_router.dart';
import 'pusher_beams_service.dart';

class LocalNotificationService {
  static final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  static Future<void> initialize() async {
    if (_initialized) return;

    const androidSettings = AndroidInitializationSettings('@mipmap/launcher_icon');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    await _createNotificationChannels();
    _initialized = true;
    print('DEBUG: Local notifications initialized');
  }

  static Future<void> _createNotificationChannels() async {
    const incomingCallChannel = AndroidNotificationChannel(
      'incoming_calls',
      'Incoming Calls',
      description: 'Notifications for incoming video calls',
      importance: Importance.max,
      showBadge: true,
      playSound: true,
      enableVibration: true,
      enableLights: true,
    );

    await _notifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(incomingCallChannel);

    print('DEBUG: Notification channels created');
  }

  static Future<void> showIncomingCallNotification({
    required String callerName,
    required String consultationId,
    required String roomId,
  }) async {
    if (!_initialized) await initialize();

    final androidDetails = AndroidNotificationDetails(
      'incoming_calls',
      'Incoming Calls',
      channelDescription: 'Notifications for incoming video calls',
      importance: Importance.max,
      priority: Priority.high,
      category: AndroidNotificationCategory.call,
      fullScreenIntent: true,
      showWhen: true,
      ongoing: true,
      autoCancel: false,
      visibility: NotificationVisibility.public,
      playSound: true,
      sound: const RawResourceAndroidNotificationSound('notification'),
      enableVibration: true,
      vibrationPattern: Int64List.fromList([0, 1000, 500, 1000]),
      enableLights: true,
      ledColor: const Color(0xFF00B4D8),
      ledOnMs: 1000,
      ledOffMs: 500,
      actions: const [
        AndroidNotificationAction(
          'accept_call',
          'Accept',
          showsUserInterface: true,
        ),
        AndroidNotificationAction(
          'decline_call',
          'Decline',
          cancelNotification: true,
        ),
      ],
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      sound: 'default',
      categoryIdentifier: 'incoming_call',
    );

    final notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    final payload = '$consultationId|$roomId|$callerName';

    await _notifications.show(
      consultationId.hashCode,
      'Incoming Video Call',
      '$callerName is calling you',
      notificationDetails,
      payload: payload,
    );

    print('DEBUG: Local notification shown for incoming call from $callerName');
  }

  static void _onNotificationTapped(NotificationResponse response) {
    print('DEBUG: Notification tapped: ${response.payload}');
    
    if (response.payload != null) {
      final parts = response.payload!.split('|');
      if (parts.length >= 3) {
        final consultationId = parts[0];
        final roomId = parts[1];
        final callerName = parts[2];

        if (response.actionId == 'accept_call' || response.actionId == null) {
          // Accept call or tap notification
          _navigateToIncomingCall(consultationId, roomId, callerName);
        } else if (response.actionId == 'decline_call') {
          // Decline call
          _declineCall(consultationId);
        }
      }
    }
  }

  static void _navigateToIncomingCall(String consultationId, String roomId, String callerName) {
    print('DEBUG: Navigating to incoming call screen');
    
    // Use PusherBeamsService to handle navigation
    PusherBeamsService.handleNotificationTap({
      'consultation_id': consultationId,
      'room_id': roomId,
      'caller_name': callerName,
      'type': 'call',
    });
  }

  static void _declineCall(String consultationId) {
    print('DEBUG: Call declined from notification');
    // Cancel the notification
    cancelNotification(consultationId.hashCode);
  }

  static Future<void> cancelNotification(int id) async {
    await _notifications.cancel(id);
    print('DEBUG: Notification cancelled: $id');
  }

  static Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
    print('DEBUG: All notifications cancelled');
  }

  // Handle Firebase message and show local notification
  static Future<void> handleFirebaseMessage(RemoteMessage message) async {
    print('DEBUG: Handling Firebase message for local notification');
    
    if (message.data['type'] == 'call') {
      final callerName = message.data['caller_name'] ?? 'Unknown';
      final consultationId = message.data['consultation_id'] ?? '';
      final roomId = message.data['room_id'] ?? '';

      if (consultationId.isNotEmpty && roomId.isNotEmpty) {
        await showIncomingCallNotification(
          callerName: callerName,
          consultationId: consultationId,
          roomId: roomId,
        );
      }
    }
  }
}