import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:permission_handler/permission_handler.dart';

class VideoService {
  static const String appId = 'bcaae392e0bf44e48711b636180aeb98';
  RtcEngine? _engine;
  
  static void testAppId() {
    print('DEBUG: Using Agora App ID: $appId');
    if (appId.isEmpty || appId == 'YOUR_APP_ID') {
      print('ERROR: Invalid Agora App ID!');
    }
  }
  
  Future<void> initialize() async {
    print('DEBUG: VideoService - Starting initialization');
    try {
      print('DEBUG: VideoService - Requesting permissions');
      final permissions = await [Permission.microphone, Permission.camera].request();
      
      print('DEBUG: VideoService - Permission results:');
      print('DEBUG: - Microphone: ${permissions[Permission.microphone]}');
      print('DEBUG: - Camera: ${permissions[Permission.camera]}');
      
      if (permissions[Permission.microphone] != PermissionStatus.granted ||
          permissions[Permission.camera] != PermissionStatus.granted) {
        throw Exception('Camera and microphone permissions are required');
      }
      
      print('DEBUG: VideoService - Creating Agora RTC Engine');
      _engine = createAgoraRtcEngine();
      
      print('DEBUG: VideoService - Initializing engine with App ID: $appId');
      await _engine!.initialize(const RtcEngineContext(
        appId: appId,
        channelProfile: ChannelProfileType.channelProfileCommunication,
      ));
      
      print('DEBUG: VideoService - Enabling video');
      await _engine!.enableVideo();
      
      print('DEBUG: VideoService - Enabling audio');
      await _engine!.enableAudio();
      
      print('DEBUG: VideoService - Setting client role to broadcaster');
      await _engine!.setClientRole(role: ClientRoleType.clientRoleBroadcaster);
      
      print('DEBUG: VideoService - Initialization completed successfully');
    } catch (e, stackTrace) {
      print('DEBUG: VideoService - Initialization failed: $e');
      print('DEBUG: VideoService - Stack trace: $stackTrace');
      rethrow;
    }
  }
  
  Future<void> joinChannel(String token, String channelName, int uid) async {
    print('DEBUG: VideoService - joinChannel called');
    print('DEBUG: - Engine available: ${_engine != null}');
    print('DEBUG: - Token: "$token"');
    print('DEBUG: - Channel: "$channelName"');
    print('DEBUG: - UID: $uid');
    
    try {
      if (_engine == null) {
        throw Exception('RTC Engine not initialized');
      }
      
      print('DEBUG: VideoService - Calling engine.joinChannel...');
      await _engine!.joinChannel(
        token: token,
        channelId: channelName,
        uid: uid,
        options: const ChannelMediaOptions(
          clientRoleType: ClientRoleType.clientRoleBroadcaster,
          channelProfile: ChannelProfileType.channelProfileCommunication,
        ),
      );
      print('DEBUG: VideoService - joinChannel completed without error');
    } catch (e, stackTrace) {
      print('DEBUG: VideoService - joinChannel failed: $e');
      print('DEBUG: VideoService - Stack trace: $stackTrace');
      rethrow;
    }
  }
  
  Future<void> leaveChannel() async {
    await _engine?.leaveChannel();
  }
  
  Future<void> dispose() async {
    await _engine?.release();
  }
  
  RtcEngine? get engine => _engine;
  
  void setEventHandler(RtcEngineEventHandler handler) {
    _engine?.registerEventHandler(handler);
  }
  
  Future<void> switchCamera() async {
    await _engine?.switchCamera();
  }
  
  Future<void> muteLocalAudio(bool muted) async {
    await _engine?.muteLocalAudioStream(muted);
  }
  
  Future<void> muteLocalVideo(bool muted) async {
    await _engine?.muteLocalVideoStream(muted);
  }
}