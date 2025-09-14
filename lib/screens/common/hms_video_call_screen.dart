import 'package:flutter/material.dart';
import 'package:hmssdk_flutter/hmssdk_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../services/hms_consultation_service.dart';
import '../../services/local_storage_service.dart';

class HMSVideoCallScreen extends StatefulWidget {
  final String consultationId;
  final String patientId;
  final String doctorId;
  final String patientName;
  final String doctorName;
  const HMSVideoCallScreen({
    super.key,
    required this.consultationId,
    required this.patientId,
    required this.doctorId,
    required this.patientName,
    required this.doctorName,
  });

  @override
  State<HMSVideoCallScreen> createState() => _HMSVideoCallScreenState();
}

class _HMSVideoCallScreenState extends State<HMSVideoCallScreen> {
  bool _isAudioMuted = false;
  bool _isVideoMuted = false;
  bool _isConnected = false;
  bool _showPrescriptionDialog = false;
  final TextEditingController _prescriptionController = TextEditingController();
  
  HMSVideoTrack? _localVideoTrack;
  HMSVideoTrack? _remoteVideoTrack;
  HMSAudioTrack? _localAudioTrack;
  HMSAudioTrack? _remoteAudioTrack;
  List<HMSPeer> _peers = [];

  @override
  void initState() {
    super.initState();
    _joinConsultation();
  }

  Future<void> _joinConsultation() async {
    try {
      // Request audio and camera permissions
      final permissions = await [
        Permission.camera,
        Permission.microphone,
      ].request();
      
      if (permissions[Permission.camera] != PermissionStatus.granted ||
          permissions[Permission.microphone] != PermissionStatus.granted) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Camera and microphone permissions are required for video calls'),
              backgroundColor: Colors.red,
            ),
          );
          Navigator.of(context).pop();
        }
        return;
      }
      
      final currentUser = LocalStorageService.getCurrentUser();
      if (currentUser == null) return;

      final isDoctor = currentUser['role'] == 'doctor';
      final userName = isDoctor ? 'Dr. ${widget.doctorName}' : widget.patientName;
      
      await HMSConsultationService.joinConsultation(
        consultationId: widget.consultationId,
        userId: currentUser['id'],
        userName: userName,
        isDoctor: isDoctor,
        onUpdate: _onHMSUpdate,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Video call error: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) Navigator.of(context).pop();
        });
      }
    }
  }

  void _onHMSUpdate(String action, {dynamic data}) {
    switch (action) {
      case 'ON_JOIN':
        setState(() {
          _isConnected = true;
        });
        break;
      case 'ON_PEER_UPDATE':
        final peer = data['peer'] as HMSPeer;
        final update = data['update'] as HMSPeerUpdate;
        
        if (update == HMSPeerUpdate.peerJoined) {
          setState(() {
            _peers.add(peer);
          });
        } else if (update == HMSPeerUpdate.peerLeft) {
          setState(() {
            _peers.removeWhere((p) => p.peerId == peer.peerId);
          });
          // End call when any participant leaves
          print('DEBUG: Participant left - ending call');
          _endCall();
        }
        break;
      case 'ON_TRACK_UPDATE':
        final track = data['track'] as HMSTrack;
        final peer = data['peer'] as HMSPeer;
        final update = data['update'] as HMSTrackUpdate;
        
        print('DEBUG: Track update - Kind: ${track.kind}, Peer: ${peer.name}, Update: $update');
        
        if (track.kind == HMSTrackKind.kHMSTrackKindVideo) {
          setState(() {
            if (peer.isLocal) {
              _localVideoTrack = track as HMSVideoTrack;
            } else {
              _remoteVideoTrack = track as HMSVideoTrack;
            }
          });
        } else if (track.kind == HMSTrackKind.kHMSTrackKindAudio) {
          print('DEBUG: Audio track ${update == HMSTrackUpdate.trackAdded ? "added" : "updated"} for ${peer.isLocal ? "local" : "remote"} peer');
          setState(() {
            if (peer.isLocal) {
              _localAudioTrack = track as HMSAudioTrack;
            } else {
              _remoteAudioTrack = track as HMSAudioTrack;
            }
          });
        }
        break;
      case 'ON_ERROR':
        final error = data as HMSException;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('HMS Error: ${error.message}')),
        );
        break;
      default:
        break;
    }
  }

  Future<void> _toggleAudio() async {
    print('DEBUG: Toggling audio, current state: $_isAudioMuted');
    await HMSConsultationService.toggleAudio();
    setState(() {
      _isAudioMuted = !_isAudioMuted;
    });
    print('DEBUG: Audio toggled, new state: $_isAudioMuted');
  }

  Future<void> _toggleVideo() async {
    await HMSConsultationService.toggleVideo();
    setState(() {
      _isVideoMuted = !_isVideoMuted;
    });
  }

  Future<void> _switchCamera() async {
    await HMSConsultationService.switchCamera();
  }

  Future<void> _endCall() async {
    await HMSConsultationService.endConsultation();
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  void _showCreatePrescription() {
    final currentUser = LocalStorageService.getCurrentUser();
    if (currentUser?['role'] != 'doctor') return;

    setState(() {
      _showPrescriptionDialog = true;
    });
  }

  Future<void> _createPrescription() async {
    if (_prescriptionController.text.trim().isEmpty) return;

    try {
      await HMSConsultationService.createPrescriptionFromConsultation(
        consultationId: widget.consultationId,
        patientId: widget.patientId,
        doctorId: widget.doctorId,
        content: _prescriptionController.text.trim(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Prescription created successfully')),
        );
        setState(() {
          _showPrescriptionDialog = false;
        });
        _prescriptionController.clear();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to create prescription: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _prescriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = LocalStorageService.getCurrentUser();
    final isDoctor = currentUser?['role'] == 'doctor';

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Remote video (full screen)
          if (_remoteVideoTrack != null)
            Positioned.fill(
              child: HMSVideoView(
                track: _remoteVideoTrack!,
                scaleType: ScaleType.SCALE_ASPECT_FILL,
              ),
            )
          else
            Positioned.fill(
              child: Container(
                color: Colors.black87,
                child: const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.person, color: Colors.white, size: 64),
                      SizedBox(height: 16),
                      Text(
                        'Waiting for other participant...',
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // Local video (small overlay)
          if (_localVideoTrack != null)
            Positioned(
              top: 50,
              right: 20,
              child: Container(
                width: 120,
                height: 160,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: HMSVideoView(
                    track: _localVideoTrack!,
                    scaleType: ScaleType.SCALE_ASPECT_FILL,
                  ),
                ),
              ),
            ),

          // Connection status overlay
          if (!_isConnected)
            const Positioned.fill(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: Colors.white),
                    SizedBox(height: 16),
                    Text(
                      'Connecting to video call...',
                      style: TextStyle(color: Colors.white, fontSize: 18),
                    ),
                  ],
                ),
              ),
            ),

          // Top bar with participant info
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 50, 20, 20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.7),
                    Colors.transparent,
                  ],
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.videocam, color: Colors.white),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      isDoctor ? 'Patient: ${widget.patientName}' : 'Dr. ${widget.doctorName}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  if (_isConnected)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${_peers.length + 1} participant${_peers.length == 0 ? '' : 's'}',
                        style: const TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // Bottom controls
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.black.withOpacity(0.8),
                    Colors.transparent,
                  ],
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildControlButton(
                    icon: _isAudioMuted ? Icons.mic_off : Icons.mic,
                    onPressed: _toggleAudio,
                    backgroundColor: _isAudioMuted ? Colors.red : Colors.white.withOpacity(0.2),
                  ),
                  _buildControlButton(
                    icon: _isVideoMuted ? Icons.videocam_off : Icons.videocam,
                    onPressed: _toggleVideo,
                    backgroundColor: _isVideoMuted ? Colors.red : Colors.white.withOpacity(0.2),
                  ),
                  _buildControlButton(
                    icon: Icons.flip_camera_ios,
                    onPressed: _switchCamera,
                    backgroundColor: Colors.white.withOpacity(0.2),
                  ),
                  if (isDoctor)
                    _buildControlButton(
                      icon: Icons.medical_services,
                      onPressed: _showCreatePrescription,
                      backgroundColor: const Color(0xFF00B4D8),
                    ),
                  _buildControlButton(
                    icon: Icons.call_end,
                    onPressed: _endCall,
                    backgroundColor: Colors.red,
                  ),
                ],
              ),
            ),
          ),

          // Prescription dialog overlay
          if (_showPrescriptionDialog)
            Positioned.fill(
              child: Container(
                color: Colors.black.withOpacity(0.8),
                child: Center(
                  child: Container(
                    margin: const EdgeInsets.all(20),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Create Prescription',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1A1A1A),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _prescriptionController,
                          maxLines: 6,
                          decoration: const InputDecoration(
                            hintText: 'Enter prescription details...',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            TextButton(
                              onPressed: () {
                                setState(() {
                                  _showPrescriptionDialog = false;
                                });
                              },
                              child: const Text('Cancel'),
                            ),
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
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required VoidCallback onPressed,
    required Color backgroundColor,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: backgroundColor,
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color: Colors.white,
          size: 24,
        ),
      ),
    );
  }
}