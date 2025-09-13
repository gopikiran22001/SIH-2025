import 'package:flutter/material.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import '../../services/video_service.dart';
import '../../services/video_consultation_service.dart';
import '../../services/supabase_service.dart';
import '../../services/local_storage_service.dart';

class VideoConsultationScreen extends StatefulWidget {
  final Map<String, dynamic> consultation;
  final String userRole;

  const VideoConsultationScreen({
    super.key,
    required this.consultation,
    required this.userRole,
  });

  @override
  State<VideoConsultationScreen> createState() => _VideoConsultationScreenState();
}

class _VideoConsultationScreenState extends State<VideoConsultationScreen> {
  final VideoService _videoService = VideoService();
  bool _localUserJoined = false;
  int? _remoteUid;
  bool _muted = false;
  bool _videoDisabled = false;
  bool _speakerEnabled = true;
  bool _consultationStarted = false;
  bool _showPrescriptionDialog = false;
  final _prescriptionController = TextEditingController();

  String get _otherUserName {
    if (widget.userRole == 'patient') {
      return 'Dr. ${widget.consultation['profiles']?['full_name'] ?? 'Doctor'}';
    } else {
      return widget.consultation['profiles']?['full_name'] ?? 'Patient';
    }
  }

  @override
  void initState() {
    super.initState();
    _initAgora();
    _listenToConsultationUpdates();
  }

  void _listenToConsultationUpdates() {
    VideoConsultationService.subscribeToConsultationUpdates(widget.consultation['id'])
        .listen((consultation) {
      if (consultation != null && mounted) {
        setState(() {
          _consultationStarted = consultation['status'] == 'active';
        });
      }
    });
  }

  Future<void> _initAgora() async {
    print('DEBUG: ========== STARTING VIDEO CONSULTATION INIT ==========');
    print('DEBUG: User role: ${widget.userRole}');
    print('DEBUG: Consultation data: ${widget.consultation}');
    
    try {
      print('DEBUG: Step 1 - Testing App ID');
      VideoService.testAppId();
      
      print('DEBUG: Step 2 - Initializing video service');
      await _videoService.initialize();
      print('DEBUG: Video service initialized successfully');
      
      print('DEBUG: Step 3 - Starting local video preview');
      await _videoService.engine?.startPreview();
      print('DEBUG: Local video preview started successfully');
      
      print('DEBUG: Step 4 - Setting up event handlers');
      _videoService.setEventHandler(
        RtcEngineEventHandler(
          onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
            print('DEBUG: ✅ JOIN SUCCESS - ${widget.userRole} joined channel successfully');
            print('DEBUG: - Channel ID: ${connection.channelId}');
            print('DEBUG: - Local UID: ${connection.localUid}');
            print('DEBUG: - Elapsed time: ${elapsed}ms');
            if (mounted) {
              setState(() {
                _localUserJoined = true;
              });
              print('DEBUG: - Local user joined state updated to true');
              if (widget.userRole == 'doctor') {
                print('DEBUG: - Doctor starting consultation');
                _startConsultation();
              }
            }
          },
          onUserJoined: (RtcConnection connection, int uid, int elapsed) {
            print('DEBUG: 🎉 REMOTE USER JOINED!');
            print('DEBUG: - Remote UID: $uid');
            print('DEBUG: - Channel: ${connection.channelId}');
            print('DEBUG: - Elapsed: ${elapsed}ms');
            print('DEBUG: - Current remote UID before update: $_remoteUid');
            if (mounted) {
              setState(() {
                _remoteUid = uid;
              });
              print('DEBUG: - Remote UID updated to: $_remoteUid');
              print('DEBUG: - Both users now connected!');
            }
          },
          onUserOffline: (RtcConnection connection, int uid, UserOfflineReasonType reason) {
            print('DEBUG: ❌ USER OFFLINE - UID: $uid, Reason: $reason');
            if (mounted) {
              setState(() {
                _remoteUid = null;
              });
              _endConsultationOnUserLeave();
            }
          },
          onLeaveChannel: (RtcConnection connection, RtcStats stats) {
            print('DEBUG: 🚪 LEFT CHANNEL - ${widget.userRole}');
            print('DEBUG: - Stats: ${stats.toString()}');
            if (mounted) {
              setState(() {
                _localUserJoined = false;
                _remoteUid = null;
              });
            }
          },
          onError: (ErrorCodeType err, String msg) {
            print('DEBUG: ⚠️ AGORA ERROR: $err - $msg');
            if (mounted && err != ErrorCodeType.errInvalidToken) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Video call error: $msg')),
              );
            }
          },
          onConnectionStateChanged: (RtcConnection connection, ConnectionStateType state, ConnectionChangedReasonType reason) {
            print('DEBUG: 🔗 CONNECTION STATE CHANGED: $state, Reason: $reason');
          },
          onNetworkTypeChanged: (RtcConnection connection, NetworkType type) {
            print('DEBUG: 📶 NETWORK TYPE CHANGED: $type');
          },
        ),
      );
      print('DEBUG: Event handlers set successfully');

      print('DEBUG: Step 5 - Preparing to join channel');
      final uid = widget.userRole == 'doctor' ? 1001 : 2002;
      final token = widget.userRole == 'doctor' 
          ? widget.consultation['doctor_token'] ?? ''
          : widget.consultation['patient_token'] ?? '';
      final channelName = widget.consultation['channel_name'] ?? '';
      
      print('DEBUG: - User role: ${widget.userRole}');
      print('DEBUG: - Assigned UID: $uid');
      print('DEBUG: - Token: ${token.isNotEmpty ? '${token.substring(0, 20)}...' : 'empty'}');
      print('DEBUG: - Channel name: "$channelName"');
      print('DEBUG: - Channel name length: ${channelName.length}');
      
      if (channelName.isEmpty) {
        throw Exception('Invalid channel name - empty string');
      }
      
      print('DEBUG: Step 6 - Joining channel now...');
      await _videoService.joinChannel(token, channelName, uid);
      print('DEBUG: ✅ Join channel call completed successfully');
      print('DEBUG: ========== VIDEO CONSULTATION INIT COMPLETED ==========');
    } catch (e, stackTrace) {
      print('DEBUG: ❌ FAILED TO INITIALIZE VIDEO CONSULTATION');
      print('DEBUG: Error: $e');
      print('DEBUG: Stack trace: $stackTrace');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to start video consultation: $e')),
        );
        Navigator.pop(context);
      }
    }
  }

  Future<void> _startConsultation() async {
    try {
      await VideoConsultationService.startConsultation(widget.consultation['id']);
      setState(() {
        _consultationStarted = true;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error starting consultation: $e')),
      );
    }
  }

  Future<void> _endConsultation() async {
    try {
      await VideoConsultationService.endConsultation(widget.consultation['id']);
      await _videoService.leaveChannel();
      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error ending consultation: $e')),
      );
    }
  }

  void _showPrescriptionForm() {
    setState(() {
      _showPrescriptionDialog = true;
    });
  }

  Future<void> _createPrescription() async {
    if (_prescriptionController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter prescription details')),
      );
      return;
    }

    try {
      await VideoConsultationService.createPrescriptionFromConsultation(
        consultationId: widget.consultation['id'],
        patientId: widget.consultation['patient_id'],
        doctorId: widget.consultation['doctor_id'],
        content: _prescriptionController.text.trim(),
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Prescription created successfully')),
      );

      setState(() {
        _showPrescriptionDialog = false;
      });
      _prescriptionController.clear();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error creating prescription: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    print('DEBUG: UI BUILD - Local joined: $_localUserJoined, Remote UID: $_remoteUid');
    print('DEBUG: UI BUILD - Engine available: ${_videoService.engine != null}');
    print('DEBUG: UI BUILD - Consultation started: $_consultationStarted');
    
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
                child: Container(
                  color: Colors.grey[800],
                  child: _videoService.engine != null
                      ? AgoraVideoView(
                          controller: VideoViewController(
                            rtcEngine: _videoService.engine!,
                            canvas: const VideoCanvas(uid: 0),
                          ),
                        )
                      : const Center(
                          child: CircularProgressIndicator(color: Colors.white),
                        ),
                ),
              ),
            ),
          ),
          // User info and consultation status
          Positioned(
            top: 60,
            left: 20,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _otherUserName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  _consultationStarted 
                      ? (_remoteUid != null ? 'Connected' : 'Waiting for participant...')
                      : 'Consultation not started',
                  style: TextStyle(
                    color: _consultationStarted 
                        ? (_remoteUid != null ? Colors.green : Colors.orange)
                        : Colors.red,
                    fontSize: 14,
                  ),
                ),
                if (widget.consultation['symptoms'] != null)
                  Container(
                    margin: const EdgeInsets.only(top: 8),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Symptoms:',
                          style: TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                        Text(
                          widget.consultation['symptoms'],
                          style: const TextStyle(color: Colors.white, fontSize: 14),
                        ),
                      ],
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
          // Prescription dialog
          if (_showPrescriptionDialog)
            _buildPrescriptionDialog(),
        ],
      ),
    );
  }

  Widget _remoteVideo() {
    print('DEBUG: _remoteVideo - Remote UID: $_remoteUid');
    print('DEBUG: _remoteVideo - Engine available: ${_videoService.engine != null}');
    
    if (_remoteUid != null) {
      print('DEBUG: _remoteVideo - Showing remote video for UID: $_remoteUid');
      return AgoraVideoView(
        controller: VideoViewController(
          rtcEngine: _videoService.engine!,
          canvas: VideoCanvas(uid: _remoteUid),
        ),
      );
    } else {
      print('DEBUG: _remoteVideo - Showing waiting screen (no remote user)');
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
        // Prescription (doctor only)
        if (widget.userRole == 'doctor' && _consultationStarted)
          _buildControlButton(
            icon: Icons.medical_services,
            color: Colors.white,
            backgroundColor: Colors.green,
            onPressed: _showPrescriptionForm,
          ),
        // End call / Leave call
        _buildControlButton(
          icon: Icons.call_end,
          color: Colors.white,
          backgroundColor: Colors.red,
          onPressed: _endConsultation,
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

  Widget _buildPrescriptionDialog() {
    return Container(
      color: Colors.black54,
      child: Center(
        child: Container(
          margin: const EdgeInsets.all(20),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Create Prescription',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _prescriptionController,
                decoration: const InputDecoration(
                  hintText: 'Enter prescription details...',
                  border: OutlineInputBorder(),
                ),
                maxLines: 5,
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _showPrescriptionDialog = false;
                      });
                    },
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _createPrescription,
                    child: const Text('Create'),
                  ),
                ],
              ),
            ],
          ),
        ),
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

  Future<void> _endConsultationOnUserLeave() async {
    try {
      await VideoConsultationService.endConsultation(widget.consultation['id']);
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      print('DEBUG: Error ending consultation on user leave: $e');
    }
  }

  @override
  void dispose() {
    _videoService.leaveChannel();
    _videoService.dispose();
    _prescriptionController.dispose();
    super.dispose();
  }
}