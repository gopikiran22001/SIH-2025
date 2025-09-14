import 'dart:async';
import 'package:uuid/uuid.dart';
import 'package:hmssdk_flutter/hmssdk_flutter.dart';
import 'supabase_service.dart';
import 'hms_token_service.dart';
import 'notification_service.dart';

class HMSConsultationService extends HMSUpdateListener {
  static const Uuid _uuid = Uuid();
  static HMSSDK? _hmsSDK;
  static String? _currentRoomId;
  static String? _currentConsultationId;
  static HMSConsultationService? _instance;
  static Function(String, {dynamic data})? _onUpdate;

  static Future<void> initialize() async {
    if (_hmsSDK == null) {
      _hmsSDK = HMSSDK();
      await _hmsSDK!.build();
    }
    if (_instance == null) {
      _instance = HMSConsultationService();
    }
  }

  @override
  void onJoin({required HMSRoom room}) {
    _onUpdate?.call('ON_JOIN', data: room);
  }

  @override
  void onPeerUpdate({required HMSPeer peer, required HMSPeerUpdate update}) {
    _onUpdate?.call('ON_PEER_UPDATE', data: {'peer': peer, 'update': update});
  }

  @override
  void onTrackUpdate({required HMSTrack track, required HMSTrackUpdate trackUpdate, required HMSPeer peer}) {
    _onUpdate?.call('ON_TRACK_UPDATE', data: {'track': track, 'update': trackUpdate, 'peer': peer});
  }

  @override
  void onHMSError({required HMSException error}) {
    _onUpdate?.call('ON_ERROR', data: error);
  }

  @override
  void onRoomUpdate({required HMSRoom room, required HMSRoomUpdate update}) {}

  @override
  void onMessage({required HMSMessage message}) {}

  @override
  void onRoleChangeRequest({required HMSRoleChangeRequest roleChangeRequest}) {}

  @override
  void onUpdateSpeakers({required List<HMSSpeaker> updateSpeakers}) {}

  @override
  void onReconnecting() {}

  @override
  void onReconnected() {}

  @override
  void onAudioDeviceChanged({HMSAudioDevice? currentAudioDevice, List<HMSAudioDevice>? availableAudioDevice}) {}

  @override
  void onChangeTrackStateRequest({required HMSTrackChangeRequest hmsTrackChangeRequest}) {}

  @override
  void onPeerListUpdate({required List<HMSPeer> addedPeers, required List<HMSPeer> removedPeers}) {}

  @override
  void onRemovedFromRoom({required HMSPeerRemovedFromPeer hmsPeerRemovedFromPeer}) {}

  @override
  void onSessionStoreAvailable({HMSSessionStore? hmsSessionStore}) {}

  static Future<Map<String, dynamic>?> createVideoConsultation({
    required String patientId,
    required String doctorId,
    required String symptoms,
    required bool isPatientInitiated,
  }) async {
    print('DEBUG: HMSConsultationService.createVideoConsultation called');
    print('DEBUG: Parameters - patientId: $patientId, doctorId: $doctorId');
    print('DEBUG: Symptoms: $symptoms');
    
    try {
      final consultationId = _uuid.v4();
      print('DEBUG: Generated consultation ID: $consultationId');
      
      // Create unique HMS room for this consultation
      print('DEBUG: Creating HMS room...');
      final roomId = await HMSTokenService.createRoom(
        doctorId: doctorId,
        patientId: patientId,
      );
      
      print('DEBUG: HMS room created successfully: $roomId');
      
      // Store consultation with room_id (tokens will be generated on-demand)
      print('DEBUG: Inserting consultation into database...');
      final consultation = await SupabaseService.client
          .from('video_consultations')
          .insert({
            'id': consultationId,
            'patient_id': patientId,
            'doctor_id': doctorId,
            'room_id': roomId,
            'channel_name': roomId, // Keep for backward compatibility
            'symptoms': symptoms,
            'status': 'pending',
            'created_at': DateTime.now().toIso8601String(),
          })
          .select()
          .single();

      print('DEBUG: Consultation created successfully in database');
      print('DEBUG: Consultation data: ${consultation.toString()}');
      
      // Get patient and doctor names for incoming call
      final patientProfile = await SupabaseService.getProfile(patientId);
      final doctorProfile = await SupabaseService.getProfile(doctorId);
      
      final patientName = patientProfile?['full_name'] ?? 'Patient';
      final doctorName = doctorProfile?['full_name'] ?? 'Doctor';
      
      // Send FCM notification to the receiving party ONLY
      print('DEBUG: isPatientInitiated: $isPatientInitiated');
      print('DEBUG: Patient ID: $patientId, Doctor ID: $doctorId');
      print('DEBUG: Patient Name: $patientName, Doctor Name: $doctorName');
      
      if (isPatientInitiated) {
        // Patient is calling doctor - send notification to doctor ONLY
        print('DEBUG: Patient initiated call - sending notification to doctor: $doctorId');
        print('DEBUG: Caller name will be: $patientName');
        await _sendConsultationNotification(
          targetUserId: doctorId,
          callerName: patientName,
          symptoms: symptoms,
          consultationId: consultationId,
        );
      } else {
        // Doctor is calling patient - send notification to patient ONLY
        print('DEBUG: Doctor initiated call - sending notification to patient: $patientId');
        print('DEBUG: Caller name will be: $doctorName');
        await _sendConsultationNotification(
          targetUserId: patientId,
          callerName: doctorName,
          symptoms: symptoms,
          consultationId: consultationId,
        );
      }
      
      // Set 1 minute 15 second timeout to auto-end call if no one connects
      Timer(const Duration(seconds: 75), () async {
        try {
          final currentConsultation = await SupabaseService.client
              .from('video_consultations')
              .select('status')
              .eq('id', consultationId)
              .single();
          
          if (currentConsultation['status'] == 'pending' || currentConsultation['status'] == 'active') {
            print('DEBUG: Auto-ending consultation after 75 seconds timeout');
            await SupabaseService.client
                .from('video_consultations')
                .update({
                  'status': 'timeout',
                  'ended_at': DateTime.now().toIso8601String(),
                })
                .eq('id', consultationId);
            
            // Cancel any remaining notifications
            await NotificationService.cancelNotification(consultationId);
          }
        } catch (e) {
          print('DEBUG: Error in timeout handler: $e');
        }
      });
      
      return consultation;
    } catch (e) {
      print('DEBUG: Error creating video consultation: $e');
      print('DEBUG: Error type: ${e.runtimeType}');
      if (e is Exception) {
        print('DEBUG: Exception message: ${e.toString()}');
      }
      return null;
    }
  }

  static Future<void> joinConsultation({
    required String consultationId,
    required String userId,
    required String userName,
    required bool isDoctor,
    required Function(String, {dynamic data}) onUpdate,
  }) async {
    print('DEBUG: HMSConsultationService.joinConsultation called');
    print('DEBUG: Parameters - consultationId: $consultationId, userId: $userId');
    print('DEBUG: userName: $userName, isDoctor: $isDoctor');
    
    try {
      // Ensure initialization
      print('DEBUG: Initializing HMS SDK...');
      await initialize();
      
      _currentConsultationId = consultationId;
      _onUpdate = onUpdate;
      print('DEBUG: Set current consultation ID and update callback');

      // Generate token for this specific consultation
      print('DEBUG: Generating token for consultation...');
      final authToken = await HMSTokenService.generateTokenForConsultation(
        consultationId: consultationId,
        userId: userId,
      );
      print('DEBUG: Token generated successfully');
      
      // Get room_id from consultation
      print('DEBUG: Fetching consultation details from database...');
      final consultation = await SupabaseService.client
          .from('video_consultations')
          .select('room_id, status, doctor_id, patient_id')
          .eq('id', consultationId)
          .single();
      
      _currentRoomId = consultation['room_id'];
      print('DEBUG: Consultation details:');
      print('DEBUG: - Room ID: $_currentRoomId');
      print('DEBUG: - Status: ${consultation['status']}');
      print('DEBUG: - Doctor ID: ${consultation['doctor_id']}');
      print('DEBUG: - Patient ID: ${consultation['patient_id']}');

      // Add update listener
      if (_instance != null) {
        print('DEBUG: Adding HMS update listener...');
        _hmsSDK!.addUpdateListener(listener: _instance!);
      } else {
        print('DEBUG: WARNING - HMS instance is null');
      }

      final tokenPreview = authToken.length > 50 ? authToken.substring(0, 50) : authToken;
      print('DEBUG: HMS joining with token: $tokenPreview...');
      print('DEBUG: HMS joining room: $_currentRoomId');
      print('DEBUG: HMS joining with userName: $userName');
      
      // Configure HMS config
      print('DEBUG: Creating HMS config...');
      final config = HMSConfig(
        authToken: authToken,
        userName: userName,
      );
      print('DEBUG: HMS config created successfully');

      print('DEBUG: Joining HMS room...');
      await _hmsSDK!.join(config: config);
      print('DEBUG: HMS join request sent');
      
      // Update consultation status
      print('DEBUG: Updating consultation status to active...');
      await SupabaseService.client
          .from('video_consultations')
          .update({
            'status': 'active',
            'started_at': DateTime.now().toIso8601String(),
          })
          .eq('id', consultationId);
      print('DEBUG: Consultation status updated successfully');
          
    } catch (e) {
      print('DEBUG: Error joining consultation: $e');
      print('DEBUG: Error type: ${e.runtimeType}');
      if (e is Exception) {
        print('DEBUG: Exception details: ${e.toString()}');
      }
      throw Exception('Failed to join video consultation: $e');
    }
  }

  static Future<void> endConsultation() async {
    try {
      if (_hmsSDK != null && _instance != null) {
        await _hmsSDK!.leave();
        _hmsSDK!.removeUpdateListener(listener: _instance!);
      }
      
      if (_currentConsultationId != null) {
        await SupabaseService.client
            .from('video_consultations')
            .update({
              'status': 'completed',
              'ended_at': DateTime.now().toIso8601String(),
            })
            .eq('id', _currentConsultationId!);
      }
          
      _currentRoomId = null;
      _currentConsultationId = null;
      _onUpdate = null;
    } catch (e) {
      print('Error ending consultation: $e');
    }
  }

  static Future<void> toggleAudio() async {
    if (_hmsSDK != null) {
      try {
        await _hmsSDK!.toggleMicMuteState();
        print('DEBUG: Audio toggled successfully');
      } catch (e) {
        print('DEBUG: Error toggling audio: $e');
      }
    }
  }

  static Future<void> toggleVideo() async {
    if (_hmsSDK != null) {
      await _hmsSDK!.toggleCameraMuteState();
    }
  }

  static Future<void> switchCamera() async {
    if (_hmsSDK != null) {
      await _hmsSDK!.switchCamera();
    }
  }

  static Future<void> createPrescriptionFromConsultation({
    required String consultationId,
    required String patientId,
    required String doctorId,
    required String content,
  }) async {
    try {
      await SupabaseService.client.from('prescriptions').insert({
        'id': _uuid.v4(),
        'patient_id': patientId,
        'doctor_id': doctorId,
        'consultation_id': consultationId,
        'content': content,
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print('Error creating prescription: $e');
      throw Exception('Failed to create prescription: $e');
    }
  }

  static Future<List<Map<String, dynamic>>> getConsultations(String userId, String role) async {
    try {
      final column = role == 'patient' ? 'patient_id' : 'doctor_id';
      
      final consultations = await SupabaseService.client
          .from('video_consultations')
          .select('*')
          .eq(column, userId)
          .order('created_at', ascending: false);
      
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
      print('Error fetching consultations: $e');
      return [];
    }
  }

  static Stream<Map<String, dynamic>?> subscribeToConsultationUpdates(String consultationId) {
    return SupabaseService.client
        .from('video_consultations')
        .stream(primaryKey: ['id'])
        .eq('id', consultationId)
        .map((data) => data.isNotEmpty ? data.first : null);
  }
  
  static Future<void> _sendConsultationNotification({
    required String targetUserId,
    required String callerName,
    required String symptoms,
    required String consultationId,
  }) async {
    await NotificationService.sendConsultationNotification(
      targetUserId: targetUserId,
      callerName: callerName,
      symptoms: symptoms,
      consultationId: consultationId,
    );
  }

  static HMSSDK? get hmsSDK => _hmsSDK;
  static String? get currentRoomId => _currentRoomId;
  static String? get currentConsultationId => _currentConsultationId;
}