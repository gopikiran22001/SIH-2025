import 'dart:async';
import 'package:flutter/material.dart';
import 'supabase_service.dart';
import 'local_storage_service.dart';
import '../utils/app_router.dart';

class RealtimeCallService {
  static StreamSubscription? _subscription;
  static bool _isListening = false;

  static Future<void> startListening() async {
    if (_isListening) return;
    
    final currentUser = LocalStorageService.getCurrentUser();
    if (currentUser == null) {
      print('DEBUG: Cannot start realtime listener - no current user');
      return;
    }
    
    print('DEBUG: Starting realtime call listener for user: ${currentUser['id']}, role: ${currentUser['role']}');
    
    final channel = currentUser['role'] == 'doctor' ? 'doctor_id' : 'patient_id';
    print('DEBUG: Listening on channel: $channel');
    
    try {
      _subscription = SupabaseService.client
          .from('video_consultations')
          .stream(primaryKey: ['id'])
          .listen(
            (data) {
              print('DEBUG: Raw realtime data received: $data');
              print('DEBUG: Data length: ${data.length}');
              
              // Log each consultation record
              for (final consultation in data) {
                print('DEBUG: Consultation record:');
                print('  - ID: ${consultation['id']}');
                print('  - Patient ID: ${consultation['patient_id']}');
                print('  - Doctor ID: ${consultation['doctor_id']}');
                print('  - Status: ${consultation['status']}');
                print('  - Channel: ${consultation['channel_name']}');
              }
              
              // Filter for current user and pending/active status
              final pendingData = data.where((consultation) => 
                consultation[channel] == currentUser['id'] && 
                consultation['status'] == 'pending'
              ).toList();
              
              final activeData = data.where((consultation) => 
                consultation[channel] == currentUser['id'] && 
                consultation['status'] == 'active'
              ).toList();
              
              print('DEBUG: Pending consultations for ${currentUser['id']}: $pendingData');
              print('DEBUG: Active consultations for ${currentUser['id']}: $activeData');
              
              // Show notification for pending consultations
              if (pendingData.isNotEmpty) {
                final consultation = pendingData.first;
                print('DEBUG: Found pending consultation, showing dialog');
                _showIncomingCallDialog(consultation);
              }
              // Also show notification for newly active consultations (someone else joined first)
              else if (activeData.isNotEmpty) {
                final consultation = activeData.first;
                print('DEBUG: Found active consultation, showing join dialog');
                _showJoinActiveCallDialog(consultation);
              } else {
                print('DEBUG: No pending or active consultations found for current user');
              }
            },
            onError: (error) {
              print('DEBUG: Realtime subscription error: $error');
            },
          );
      
      _isListening = true;
      print('DEBUG: Realtime call listener started successfully');
    } catch (e) {
      print('DEBUG: Error starting realtime listener: $e');
    }
  }

  static void stopListening() {
    _subscription?.cancel();
    _subscription = null;
    _isListening = false;
    print('DEBUG: Realtime call listener stopped');
  }

  static void _showIncomingCallDialog(Map<String, dynamic> consultation) async {
    final currentUser = LocalStorageService.getCurrentUser();
    if (currentUser == null) return;
    
    final isDoctor = currentUser['role'] == 'doctor';
    final callerName = isDoctor ? 'Patient' : 'Doctor';
    
    print('DEBUG: Showing incoming call dialog for consultation: ${consultation['id']}');
    
    final context = AppRouter.navigatorKey.currentContext;
    if (context == null) return;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text('Incoming Video Call'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.video_call, size: 64, color: Colors.green),
            SizedBox(height: 16),
            Text('$callerName is calling you'),
            if (consultation['symptoms'] != null)
              Text('Symptoms: ${consultation['symptoms']}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => _declineCall(context, consultation['id']),
            child: Text('Decline', style: TextStyle(color: Colors.red)),
          ),
          ElevatedButton(
            onPressed: () => _acceptCall(context, consultation),
            child: Text('Accept'),
          ),
        ],
      ),
    );
  }

  static void _acceptCall(BuildContext context, Map<String, dynamic> consultation) {
    Navigator.of(context).pop();
    
    final currentUser = LocalStorageService.getCurrentUser();
    if (currentUser == null) return;
    
    final isDoctor = currentUser['role'] == 'doctor';
    final token = isDoctor ? consultation['doctor_token'] : consultation['patient_token'];
    
    Navigator.pushNamed(
      context,
      '/video-consultation/${consultation['id']}',
      arguments: {
        'consultationId': consultation['id'],
        'patientId': consultation['patient_id'],
        'doctorId': consultation['doctor_id'],
        'patientName': 'Patient',
        'doctorName': 'Doctor',
        'roomId': consultation['channel_name'],
        'authToken': token,
      },
    );
  }

  static void _declineCall(BuildContext context, String consultationId) async {
    Navigator.of(context).pop();
    
    await SupabaseService.client
        .from('video_consultations')
        .update({'status': 'declined'})
        .eq('id', consultationId);
  }

  static void _showJoinActiveCallDialog(Map<String, dynamic> consultation) async {
    final currentUser = LocalStorageService.getCurrentUser();
    if (currentUser == null) return;
    
    final isDoctor = currentUser['role'] == 'doctor';
    final otherParty = isDoctor ? 'Patient' : 'Doctor';
    
    print('DEBUG: Showing join active call dialog for consultation: ${consultation['id']}');
    
    final context = AppRouter.navigatorKey.currentContext;
    if (context == null) return;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text('Video Call in Progress'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.video_call, size: 64, color: Colors.blue),
            SizedBox(height: 16),
            Text('$otherParty is in the consultation room'),
            Text('Would you like to join?'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Later', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => _acceptCall(context, consultation),
            child: Text('Join Call'),
          ),
        ],
      ),
    );
  }
}