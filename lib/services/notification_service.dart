import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';
import '../utils/app_router.dart';
import 'supabase_service.dart';
import 'local_storage_service.dart';

class NotificationService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  static FlutterLocalNotificationsPlugin get flutterLocalNotificationsPlugin => _localNotifications;
  
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

    // Create notification channel for incoming calls
    const androidChannel = AndroidNotificationChannel(
      'incoming_call_channel',
      'Incoming Calls',
      description: 'Notifications for incoming video calls',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(androidChannel);

    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);
    FirebaseMessaging.onBackgroundMessage(_handleBackgroundMessage);
  }

  static Future<String?> getToken() async {
    return await _messaging.getToken();
  }

  static Future<void> saveTokenToDatabase() async {
    try {
      print('DEBUG: Getting FCM token...');
      final token = await getToken();
      final userId = LocalStorageService.getCurrentUserId();
      
      print('DEBUG: FCM token: ${token?.substring(0, 50)}...');
      print('DEBUG: Current user ID: $userId');
      
      if (token != null && userId != null) {
        print('DEBUG: Saving FCM token to database...');
        await SupabaseService.client
            .from('profiles')
            .update({'fcm_token': token})
            .eq('id', userId);
        print('DEBUG: FCM token saved successfully to database');
        
        // Verify token was saved
        final profile = await SupabaseService.client
            .from('profiles')
            .select('fcm_token')
            .eq('id', userId)
            .single();
        print('DEBUG: Verified FCM token in database: ${profile['fcm_token']?.substring(0, 50)}...');
      } else {
        print('DEBUG: Cannot save FCM token - token: ${token != null}, userId: ${userId != null}');
      }
    } catch (e) {
      print('DEBUG: Error saving FCM token: $e');
      throw e;
    }
  }

  // New unified method to send notifications via FCM v1 Edge Function
  static Future<void> sendNotification({
    required String token,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    try {
      print('DEBUG: Sending FCM notification via Edge Function');
      print('DEBUG: Token: ${token.substring(0, 20)}...');
      print('DEBUG: Title: $title');
      print('DEBUG: Body: $body');
      print('DEBUG: Data: $data');
      
      await SupabaseService.client.functions.invoke(
        'send-push-notification',
        body: {
          'token': token,
          'title': title,
          'body': body,
          'data': data ?? {},
        },
      );
      print('DEBUG: FCM notification sent successfully');
    } catch (e) {
      print('DEBUG: Failed to send FCM notification: $e');
      throw e;
    }
  }

  static Future<void> sendConsultationNotification({
    required String targetUserId,
    required String callerName,
    required String symptoms,
    required String consultationId,
  }) async {
    try {
      print('DEBUG: Sending consultation notification to user: $targetUserId');
      
      // Prevent sending notification to current user (caller)
      final currentUser = LocalStorageService.getCurrentUser();
      if (currentUser != null && currentUser['id'] == targetUserId) {
        print('DEBUG: Skipping notification - target is current user (caller)');
        return;
      }
      
      // Get target user's FCM token
      print('DEBUG: Fetching FCM token from database for user: $targetUserId');
      final userProfile = await SupabaseService.client
          .from('profiles')
          .select('fcm_token, full_name')
          .eq('id', targetUserId)
          .single();
      
      final fcmToken = userProfile['fcm_token'];
      final userName = userProfile['full_name'];
      print('DEBUG: Target user name: $userName');
      print('DEBUG: FCM token found: ${fcmToken != null}');
      if (fcmToken != null) {
        print('DEBUG: FCM token preview: ${fcmToken.substring(0, 50)}...');
      }
      
      if (fcmToken != null && fcmToken.isNotEmpty) {
        print('DEBUG: Sending FCM notification via Edge Function...');
        await sendNotification(
          token: fcmToken,
          title: 'Incoming Video Call',
          body: '$callerName is calling you',
          data: {
            'consultation_id': consultationId,
            'type': 'video_call',
            'caller_name': callerName,
            'symptoms': symptoms,
          },
        );
        print('DEBUG: FCM notification sent successfully');
      } else {
        print('DEBUG: No FCM token found for user $targetUserId');
        print('DEBUG: User profile data: $userProfile');
      }
    } catch (e) {
      print('DEBUG: Failed to send consultation notification: $e');
      print('DEBUG: Error details: ${e.toString()}');
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

  static Future<void> _showIncomingCallNotification({
    required String callerName,
    required String symptoms,
    required String consultationId,
  }) async {
    final androidDetails = AndroidNotificationDetails(
      'incoming_call_channel',
      'Incoming Calls',
      channelDescription: 'Notifications for incoming video calls',
      importance: Importance.max,
      priority: Priority.high,
      fullScreenIntent: true,
      category: AndroidNotificationCategory.call,
      ongoing: true,
      autoCancel: false,
      showWhen: false,
      usesChronometer: false,
      timeoutAfter: 75000, // 75 seconds timeout
      playSound: true,
      enableVibration: true,
      actions: <AndroidNotificationAction>[
        AndroidNotificationAction(
          'accept_call',
          'Accept',
          showsUserInterface: true,
        ),
        AndroidNotificationAction(
          'decline_call',
          'Decline',
          showsUserInterface: false,
        ),
      ],
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      categoryIdentifier: 'incoming_call',
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      consultationId.hashCode,
      'Incoming Video Call',
      '$callerName is calling you',
      details,
      payload: consultationId,
    );
    
    print('DEBUG: Incoming call notification shown for consultation: $consultationId');
  }

  static void _handleForegroundMessage(RemoteMessage message) {
    print('DEBUG: Received foreground message: ${message.notification?.title}');
    print('DEBUG: Message data: ${message.data}');
    
    if (message.data['type'] == 'video_call') {
      final consultationId = message.data['consultation_id'] ?? '';
      final callerName = message.data['caller_name'] ?? 'Unknown';
      
      // Check if current user is the caller (prevent self-notification)
      final currentUser = LocalStorageService.getCurrentUser();
      if (currentUser != null) {
        final currentUserName = currentUser['full_name'] ?? '';
        print('DEBUG: Current user: $currentUserName, Caller: $callerName');
        
        if (currentUserName == callerName) {
          print('DEBUG: Skipping notification - user is the caller');
          return;
        }
      }
      
      if (consultationId.isNotEmpty) {
        _showIncomingCallNotification(
          callerName: callerName,
          symptoms: message.data['symptoms'] ?? 'Medical consultation',
          consultationId: consultationId,
        );
      }
    }
  }

  static void _handleNotificationTap(RemoteMessage message) {
    final consultationId = message.data['consultation_id'];
    if (consultationId != null) {
      _navigateToConsultation(consultationId);
    }
  }

  static void _onNotificationTap(NotificationResponse response) {
    print('DEBUG: Notification action: ${response.actionId}, payload: ${response.payload}');
    
    final consultationId = response.payload;
    if (consultationId == null) {
      print('DEBUG: No consultation ID in payload');
      return;
    }
    
    // Always cancel notification first
    _localNotifications.cancel(consultationId.hashCode);
    _localNotifications.cancelAll(); // Cancel all notifications as backup
    
    if (response.actionId == 'accept_call') {
      print('DEBUG: Accept call action triggered');
      _navigateToConsultation(consultationId);
    } else if (response.actionId == 'decline_call') {
      print('DEBUG: Decline call action triggered');
      _declineCall(consultationId);
    } else {
      print('DEBUG: Default notification tap - navigating to consultation');
      _navigateToConsultation(consultationId);
    }
  }

  static Future<void> cancelNotification(String consultationId) async {
    await _localNotifications.cancel(consultationId.hashCode);
    print('DEBUG: Cancelled notification for consultation: $consultationId');
  }

  static Future<void> cancelAllNotifications() async {
    await _localNotifications.cancelAll();
    print('DEBUG: Cancelled all notifications');
  }

  static Future<void> _declineCall(String consultationId) async {
    print('DEBUG: Declining call for consultation: $consultationId');
    
    try {
      // Update consultation status to declined
      await SupabaseService.client
          .from('video_consultations')
          .update({
            'status': 'declined',
            'ended_at': DateTime.now().toIso8601String(),
          })
          .eq('id', consultationId);
      
      print('DEBUG: Call declined successfully in database');
    } catch (e) {
      print('DEBUG: Failed to update declined status: $e');
    }
  }



  static void _navigateToConsultation(String consultationId) async {
    print('DEBUG: Navigating to consultation: $consultationId');
    
    try {
      // Fetch consultation details to get participant info
      final consultation = await SupabaseService.client
          .from('video_consultations')
          .select('*, patient_profile:profiles!video_consultations_patient_id_fkey(full_name), doctor_profile:profiles!video_consultations_doctor_id_fkey(full_name)')
          .eq('id', consultationId)
          .single();
      
      final patientName = consultation['patient_profile']?['full_name'] ?? 'Patient';
      final doctorName = consultation['doctor_profile']?['full_name'] ?? 'Doctor';
      
      AppRouter.push(
        '/hms-video-call?consultationId=$consultationId',
        arguments: {
          'patientId': consultation['patient_id'],
          'doctorId': consultation['doctor_id'],
          'patientName': patientName,
          'doctorName': doctorName,
        },
      );
    } catch (e) {
      print('DEBUG: Failed to navigate to consultation: $e');
      // Fallback navigation with minimal data
      AppRouter.push(
        '/hms-video-call?consultationId=$consultationId',
        arguments: {
          'patientId': '',
          'doctorId': '',
          'patientName': 'Patient',
          'doctorName': 'Doctor',
        },
      );
    }
  }
}

@pragma('vm:entry-point')
Future<void> _handleBackgroundMessage(RemoteMessage message) async {
  print('Background message: ${message.messageId}');
}