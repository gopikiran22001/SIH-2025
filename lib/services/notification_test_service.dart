import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'notification_service.dart';
import 'pusher_beams_service.dart';
import 'supabase_service.dart';
import 'local_notification_service.dart';

class NotificationTestService {
  static Future<void> testNotificationFlow() async {
    print('=== Notification Service Test Started ===');
    
    try {
      // Ensure Firebase is initialized first
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp();
        print('Firebase initialized in test service');
      }
      
      // Test 1: Check Firebase Messaging initialization
      print('1. Testing Firebase Messaging initialization...');
      await PusherBeamsService.initialize();
      
      // Test 2: Get FCM token
      print('2. Getting FCM token...');
      final token = await FirebaseMessaging.instance.getToken();
      print('FCM Token: ${token?.substring(0, 50)}...');
      
      // Test 3: Test topic subscription
      print('3. Testing topic subscription...');
      final currentUser = SupabaseService.currentUser;
      if (currentUser != null) {
        await PusherBeamsService.onUserLogin(currentUser.id);
        print('Successfully subscribed to user topic');
      }
      
      // Test 4: Test notification sending (mock)
      print('4. Testing notification sending...');
      if (currentUser != null) {
        await _testSendNotification(currentUser.id);
      }
      
      // Test 5: Check device interests/token
      print('5. Checking device interests...');
      final interests = await PusherBeamsService.getDeviceInterests();
      print('Device interests count: ${interests.length}');
      
      print('=== Notification Service Test Completed Successfully ===');
      
    } catch (e) {
      print('=== Notification Service Test Failed ===');
      print('Error: $e');
    }
  }
  
  static Future<void> _testSendNotification(String userId) async {
    try {
      // Create a test consultation entry
      final testConsultation = await SupabaseService.client
          .from('video_consultations')
          .insert({
            'patient_id': userId,
            'doctor_id': userId, // Self for testing
            'room_id': 'test-room-${DateTime.now().millisecondsSinceEpoch}',
            'symptoms': 'Test notification',
            'status': 'pending',
          })
          .select()
          .single();
      
      print('Created test consultation: ${testConsultation['id']}');
      
      // Test notification sending
      await NotificationService.sendConsultationNotification(
        targetUserId: userId,
        callerName: 'Test Caller',
        symptoms: 'Test notification',
        consultationId: testConsultation['id'],
      );
      
      print('Test notification sent successfully');
      
      // Clean up test consultation
      await SupabaseService.client
          .from('video_consultations')
          .delete()
          .eq('id', testConsultation['id']);
      
      print('Test consultation cleaned up');
      
    } catch (e) {
      print('Error in test notification: $e');
    }
  }
  
  static Future<void> testForegroundNotificationHandling() async {
    print('=== Testing Notification Handling ===');
    
    try {
      // Ensure Firebase is initialized
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp();
      }
      
      // Set up foreground message handler (app open)
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        print('Foreground message received:');
        print('Title: ${message.notification?.title}');
        print('Body: ${message.notification?.body}');
        print('Data: ${message.data}');
        
        // Handle call notifications in foreground
        if (message.data['type'] == 'call') {
          print('DEBUG: Showing incoming call screen for foreground message');
          PusherBeamsService.handleNotificationTap(message.data);
        }
      });
      
      // Set up background message handler (app in background, user taps notification)
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        print('Background message opened app:');
        print('Data: ${message.data}');
        
        if (message.data['type'] == 'call') {
          // Delay navigation to ensure app is fully initialized
          Future.delayed(const Duration(milliseconds: 1500), () {
            PusherBeamsService.handleNotificationTap(message.data);
          });
        }
      });
      
      // Check if app was opened from terminated state by notification
      final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
      if (initialMessage != null) {
        print('App opened from terminated state by notification:');
        print('Data: ${initialMessage.data}');
        
        if (initialMessage.data['type'] == 'call') {
          // Longer delay for terminated state to ensure full app initialization
          Future.delayed(const Duration(milliseconds: 3000), () {
            PusherBeamsService.handleNotificationTap(initialMessage.data);
          });
        }
      }
      
      print('All notification handlers set up successfully');
      
    } catch (e) {
      print('Error setting up notification handlers: $e');
    }
  }
  
  static Future<Map<String, dynamic>> getNotificationStatus() async {
    try {
      // Ensure Firebase is initialized
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp();
      }
      
      final messaging = FirebaseMessaging.instance;
      
      // Check permission status
      final settings = await messaging.getNotificationSettings();
      
      // Get FCM token
      final token = await messaging.getToken();
      
      // Get device interests
      final interests = await PusherBeamsService.getDeviceInterests();
      
      return {
        'permission_status': settings.authorizationStatus.name,
        'fcm_token_available': token != null,
        'token_length': token?.length ?? 0,
        'interests_count': interests.length,
        'messaging_initialized': true,
      };
      
    } catch (e) {
      return {
        'error': e.toString(),
        'messaging_initialized': false,
      };
    }
  }
}