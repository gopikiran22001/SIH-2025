import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:permission_handler/permission_handler.dart';

class VideoService {
  static const String appId = 'bcaae392e0bf44e48711b636180aeb98'; // Replace with your Agora App ID
  RtcEngine? _engine;
  
  Future<void> initialize() async {
    await [Permission.microphone, Permission.camera].request();
    
    _engine = createAgoraRtcEngine();
    await _engine!.initialize(const RtcEngineContext(
      appId: appId,
      channelProfile: ChannelProfileType.channelProfileLiveBroadcasting,
    ));
    
    await _engine!.enableVideo();
    await _engine!.setClientRole(role: ClientRoleType.clientRoleBroadcaster);
  }
  
  Future<void> joinChannel(String token, String channelName, int uid) async {
    await _engine?.joinChannel(
      token: token,
      channelId: channelName,
      uid: uid,
      options: const ChannelMediaOptions(),
    );
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