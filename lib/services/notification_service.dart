import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';
import 'supabase_service.dart';
import 'local_storage_service.dart';

class NotificationService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  
  static Future<void> initialize() async {
    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);
    FirebaseMessaging.onBackgroundMessage(_handleBackgroundMessage);
  }

  static Future<String?> getToken() async {
    return await _messaging.getToken();
  }

  static Future<void> saveTokenToDatabase() async {
    final token = await getToken();
    final userId = LocalStorageService.getCurrentUserId();
    
    if (token != null && userId != null) {
      await SupabaseService.client
          .from('profiles')
          .update({'fcm_token': token})
          .eq('id', userId);
    }
  }

  static Future<void> sendConsultationNotification({
    required String doctorId,
    required String patientName,
    required String symptoms,
    required String consultationId,
  }) async {
    try {
      // Always show notification - FCM will handle device targeting
      await _showLocalNotification(
        title: 'New Video Consultation Request',
        body: '$patientName is requesting a consultation for: $symptoms',
        payload: consultationId,
      );
      print('DEBUG: Local notification shown for consultation: $consultationId');
    } catch (e) {
      print('Failed to send notification: $e');
    }
  }

  static Future<void> sendLocalNotification({
    required String title,
    required String body,
    Map<String, String>? data,
  }) async {
    // Only show notification if user is a doctor
    final currentUser = LocalStorageService.getCurrentUser();
    if (currentUser != null && currentUser['role'] == 'doctor') {
      await _showLocalNotification(
        title: title,
        body: body,
        payload: data?['consultation_id'],
      );
    }
  }

  static Future<void> _showLocalNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'consultation_channel',
      'Video Consultations',
      channelDescription: 'Notifications for video consultation requests',
      importance: Importance.high,
      priority: Priority.high,
      fullScreenIntent: true,
      category: AndroidNotificationCategory.call,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(0, title, body, details, payload: payload);
  }

  static void _handleForegroundMessage(RemoteMessage message) {
    print('DEBUG: Received foreground message: ${message.notification?.title}');
    _showLocalNotification(
      title: message.notification?.title ?? 'New Notification',
      body: message.notification?.body ?? '',
      payload: message.data['consultation_id'],
    );
  }

  static void _handleNotificationTap(RemoteMessage message) {
    final consultationId = message.data['consultation_id'];
    if (consultationId != null) {
      _navigateToConsultation(consultationId);
    }
  }

  static void _onNotificationTap(NotificationResponse response) {
    if (response.payload != null) {
      _navigateToConsultation(response.payload!);
    }
  }

  static void _navigateToConsultation(String consultationId) {
    // Navigate to consultation screen
    // This would need to be implemented with your navigation system
  }
}

@pragma('vm:entry-point')
Future<void> _handleBackgroundMessage(RemoteMessage message) async {
  print('Background message: ${message.messageId}');
}