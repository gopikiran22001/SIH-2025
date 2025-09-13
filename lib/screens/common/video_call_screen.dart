import 'package:flutter/material.dart';

import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import '../../services/video_service.dart';

class VideoCallScreen extends StatefulWidget {
  final String channelName;
  final String token;
  final int uid;
  final String otherUserName;

  const VideoCallScreen({
    super.key,
    required this.channelName,
    required this.token,
    required this.uid,
    required this.otherUserName,
  });

  @override
  State<VideoCallScreen> createState() => _VideoCallScreenState();
}

class _VideoCallScreenState extends State<VideoCallScreen> {
  final VideoService _videoService = VideoService();
  bool _localUserJoined = false;
  int? _remoteUid;
  bool _muted = false;
  bool _videoDisabled = false;
  bool _speakerEnabled = true;

  @override
  void initState() {
    super.initState();
    _initAgora();
  }

  Future<void> _initAgora() async {
    await _videoService.initialize();
    
    _videoService.setEventHandler(
      RtcEngineEventHandler(
        onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
          setState(() {
            _localUserJoined = true;
          });
        },
        onUserJoined: (RtcConnection connection, int uid, int elapsed) {
          setState(() {
            _remoteUid = uid;
          });
        },
        onUserOffline: (RtcConnection connection, int uid, UserOfflineReasonType reason) {
          setState(() {
            _remoteUid = null;
          });
        },
        onLeaveChannel: (RtcConnection connection, RtcStats stats) {
          setState(() {
            _localUserJoined = false;
            _remoteUid = null;
          });
        },
      ),
    );

    await _videoService.joinChannel(widget.token, widget.channelName, widget.uid);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Remote video view
          _remoteVideo(),
          // Local video view
          Positioned(
            top: 50,
            right: 20,
            child: SizedBox(
              width: 120,
              height: 160,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: _localUserJoined
                    ? AgoraVideoView(
                        controller: VideoViewController(
                          rtcEngine: _videoService.engine!,
                          canvas: const VideoCanvas(uid: 0),
                        ),
                      )
                    : Container(
                        color: Colors.grey[800],
                        child: const Center(
                          child: CircularProgressIndicator(color: Colors.white),
                        ),
                      ),
              ),
            ),
          ),
          // User info
          Positioned(
            top: 60,
            left: 20,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.otherUserName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  _remoteUid != null ? 'Connected' : 'Connecting...',
                  style: TextStyle(
                    color: _remoteUid != null ? Colors.green : Colors.orange,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          // Control buttons
          Positioned(
            bottom: 50,
            left: 0,
            right: 0,
            child: _buildControlButtons(),
          ),
        ],
      ),
    );
  }

  Widget _remoteVideo() {
    if (_remoteUid != null) {
      return AgoraVideoView(
        controller: VideoViewController.remote(
          rtcEngine: _videoService.engine!,
          canvas: VideoCanvas(uid: _remoteUid),
          connection: RtcConnection(channelId: widget.channelName),
        ),
      );
    } else {
      return Container(
        color: Colors.grey[900],
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.person,
                size: 80,
                color: Colors.white54,
              ),
              SizedBox(height: 16),
              Text(
                'Waiting for other participant...',
                style: TextStyle(
                  color: Colors.white54,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      );
    }
  }

  Widget _buildControlButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        // Mute/Unmute
        _buildControlButton(
          icon: _muted ? Icons.mic_off : Icons.mic,
          color: _muted ? Colors.red : Colors.white,
          backgroundColor: _muted ? Colors.white : Colors.black54,
          onPressed: _toggleMute,
        ),
        // Video on/off
        _buildControlButton(
          icon: _videoDisabled ? Icons.videocam_off : Icons.videocam,
          color: _videoDisabled ? Colors.red : Colors.white,
          backgroundColor: _videoDisabled ? Colors.white : Colors.black54,
          onPressed: _toggleVideo,
        ),
        // Switch camera
        _buildControlButton(
          icon: Icons.switch_camera,
          color: Colors.white,
          backgroundColor: Colors.black54,
          onPressed: _switchCamera,
        ),
        // Speaker on/off
        _buildControlButton(
          icon: _speakerEnabled ? Icons.volume_up : Icons.volume_off,
          color: Colors.white,
          backgroundColor: Colors.black54,
          onPressed: _toggleSpeaker,
        ),
        // End call
        _buildControlButton(
          icon: Icons.call_end,
          color: Colors.white,
          backgroundColor: Colors.red,
          onPressed: _endCall,
        ),
      ],
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required Color color,
    required Color backgroundColor,
    required VoidCallback onPressed,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        shape: BoxShape.circle,
      ),
      child: IconButton(
        icon: Icon(icon, color: color),
        iconSize: 28,
        onPressed: onPressed,
      ),
    );
  }

  Future<void> _toggleMute() async {
    setState(() {
      _muted = !_muted;
    });
    await _videoService.muteLocalAudio(_muted);
  }

  Future<void> _toggleVideo() async {
    setState(() {
      _videoDisabled = !_videoDisabled;
    });
    await _videoService.muteLocalVideo(_videoDisabled);
  }

  Future<void> _switchCamera() async {
    await _videoService.switchCamera();
  }

  void _toggleSpeaker() {
    setState(() {
      _speakerEnabled = !_speakerEnabled;
    });
    // Implement speaker toggle logic
  }

  Future<void> _endCall() async {
    await _videoService.leaveChannel();
    if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  void dispose() {
    _videoService.dispose();
    super.dispose();
  }
}