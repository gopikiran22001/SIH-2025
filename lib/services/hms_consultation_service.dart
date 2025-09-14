import 'package:uuid/uuid.dart';
import 'package:hmssdk_flutter/hmssdk_flutter.dart';
import 'supabase_service.dart';
import 'hms_token_service.dart';

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
  }) async {
    try {
      final consultationId = _uuid.v4();
      final roomId = HMSTokenService.createRoom();
      
      final patientToken = await HMSTokenService.generateToken(
        roomId: roomId,
        userId: patientId,
        role: 'guest',
      );
      
      final doctorToken = await HMSTokenService.generateToken(
        roomId: roomId,
        userId: doctorId,
        role: 'host',
      );
      
      print('DEBUG: Created consultation with roomId: $roomId');
      final patientPreview = patientToken.length > 50 ? patientToken.substring(0, 50) : patientToken;
      final doctorPreview = doctorToken.length > 50 ? doctorToken.substring(0, 50) : doctorToken;
      print('DEBUG: Patient token: $patientPreview...');
      print('DEBUG: Doctor token: $doctorPreview...');
      
      final consultation = await SupabaseService.client
          .from('video_consultations')
          .insert({
            'id': consultationId,
            'patient_id': patientId,
            'doctor_id': doctorId,
            'channel_name': roomId,
            'patient_token': patientToken,
            'doctor_token': doctorToken,
            'symptoms': symptoms,
            'status': 'pending',
            'created_at': DateTime.now().toIso8601String(),
          })
          .select()
          .single();

      return consultation;
    } catch (e) {
      print('Error creating video consultation: $e');
      return null;
    }
  }

  static Future<void> joinConsultation({
    required String consultationId,
    required String roomId,
    required String authToken,
    required String userName,
    required bool isDoctor,
    required Function(String, {dynamic data}) onUpdate,
  }) async {
    try {
      // Ensure initialization
      await initialize();
      
      _currentRoomId = roomId;
      _currentConsultationId = consultationId;
      _onUpdate = onUpdate;

      // Add update listener
      if (_instance != null) {
        _hmsSDK!.addUpdateListener(listener: _instance!);
      }

      final tokenPreview = authToken.length > 50 ? authToken.substring(0, 50) : authToken;
      print('DEBUG: HMS joining with token: $tokenPreview...');
      print('DEBUG: HMS joining with userName: $userName');
      
      // Configure audio settings
      await _hmsSDK!.toggleMicMuteState(); // Ensure mic is unmuted
      await _hmsSDK!.toggleMicMuteState(); // Toggle twice to ensure proper state
      
      final config = HMSConfig(
        authToken: authToken,
        userName: userName,
      );

      await _hmsSDK!.join(config: config);
      
      // Update consultation status
      await SupabaseService.client
          .from('video_consultations')
          .update({
            'status': 'active',
            'started_at': DateTime.now().toIso8601String(),
          })
          .eq('id', consultationId);
          
    } catch (e) {
      print('Error joining consultation: $e');
      throw Exception('Failed to join video consultation');
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

  static HMSSDK? get hmsSDK => _hmsSDK;
  static String? get currentRoomId => _currentRoomId;
  static String? get currentConsultationId => _currentConsultationId;
}