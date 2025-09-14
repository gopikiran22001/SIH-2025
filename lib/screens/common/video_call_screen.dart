import 'package:flutter/material.dart';
import 'hms_video_call_screen.dart';

class VideoCallScreen extends StatelessWidget {
  final Map<String, dynamic> consultation;
  final String userRole;

  const VideoCallScreen({
    super.key,
    required this.consultation,
    required this.userRole,
  });

  @override
  Widget build(BuildContext context) {
    // Redirect to HMS implementation
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => HMSVideoCallScreen(
            consultationId: consultation['id'],
            patientId: consultation['patient_id'],
            doctorId: consultation['doctor_id'],
            patientName: consultation['patient_name'] ?? 'Patient',
            doctorName: consultation['doctor_name'] ?? 'Doctor',
            roomId: consultation['channel_name'] ?? consultation['id'],
            authToken: userRole == 'doctor' ? consultation['doctor_token'] : consultation['patient_token'],
          ),
        ),
      );
    });

    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}

