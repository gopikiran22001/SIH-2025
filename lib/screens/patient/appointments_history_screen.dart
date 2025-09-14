import 'package:flutter/material.dart';
import '../../services/supabase_service.dart';
import '../../services/local_storage_service.dart';

class AppointmentsHistoryScreen extends StatefulWidget {
  const AppointmentsHistoryScreen({super.key});

  @override
  State<AppointmentsHistoryScreen> createState() => _AppointmentsHistoryScreenState();
}

class _AppointmentsHistoryScreenState extends State<AppointmentsHistoryScreen> {
  List<Map<String, dynamic>> _consultations = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadConsultations();
  }

  Future<void> _loadConsultations() async {
    try {
      final user = SupabaseService.currentUser;
      if (user != null) {
        final consultations = await SupabaseService.getConsultationHistory(user.id, 'patient');
        final completedConsultations = consultations.where((c) => 
          c['status'] == 'completed' || c['status'] == 'declined' || c['status'] == 'timeout'
        ).toList();
        
        // Fetch doctor names for each consultation
        for (final consultation in completedConsultations) {
          final doctorId = consultation['doctor_id'];
          try {
            final doctorProfile = await SupabaseService.getProfile(doctorId);
            consultation['doctor_name'] = doctorProfile?['full_name'] ?? 'Unknown Doctor';
          } catch (e) {
            consultation['doctor_name'] = 'Unknown Doctor';
          }
        }
        
        if (mounted) {
          setState(() {
            _consultations = completedConsultations;
            _isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    } catch (e) {
      print('DEBUG: Failed to load consultations: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Past Consultations'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _consultations.isEmpty
              ? Center(
                  child: Text(
                    'No past consultations yet',
                    style: TextStyle(
                      fontSize: screenWidth * 0.04,
                      color: Colors.grey[600],
                    ),
                  ),
                )
              : ListView.builder(
                  padding: EdgeInsets.all(screenWidth * 0.04),
                  itemCount: _consultations.length,
                  itemBuilder: (context, index) {
                    final consultation = _consultations[index];
                    return _buildConsultationCard(consultation, screenWidth);
                  },
                ),
    );
  }

  Widget _buildConsultationCard(Map<String, dynamic> consultation, double screenWidth) {
    final createdAt = DateTime.parse(consultation['created_at']);
    final startedAt = consultation['started_at'] != null 
        ? DateTime.parse(consultation['started_at']) 
        : null;
    final endedAt = consultation['ended_at'] != null 
        ? DateTime.parse(consultation['ended_at']) 
        : null;
    final doctorName = consultation['doctor_name'] ?? 'Unknown Doctor';
    final status = consultation['status'] ?? 'unknown';
    final symptoms = consultation['symptoms'] ?? 'No symptoms recorded';
    
    Color statusColor;
    IconData statusIcon;
    String statusText;
    
    switch (status) {
      case 'completed':
        statusColor = const Color(0xFF059669);
        statusIcon = Icons.check_circle;
        statusText = 'Completed';
        break;
      case 'declined':
        statusColor = const Color(0xFFDC2626);
        statusIcon = Icons.cancel;
        statusText = 'Declined';
        break;
      case 'timeout':
        statusColor = const Color(0xFFF59E0B);
        statusIcon = Icons.access_time;
        statusText = 'Timeout';
        break;
      default:
        statusColor = const Color(0xFF64748B);
        statusIcon = Icons.help;
        statusText = status.toUpperCase();
    }
    
    return Container(
      margin: EdgeInsets.only(bottom: screenWidth * 0.03),
      padding: EdgeInsets.all(screenWidth * 0.04),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(screenWidth * 0.03),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: screenWidth * 0.025,
            offset: Offset(0, screenWidth * 0.005),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.video_call,
                color: const Color(0xFF00B4D8),
                size: screenWidth * 0.05,
              ),
              SizedBox(width: screenWidth * 0.03),
              Expanded(
                child: Text(
                  'Dr. $doctorName',
                  style: TextStyle(
                    fontSize: screenWidth * 0.04,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: screenWidth * 0.02,
                  vertical: screenWidth * 0.01,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(screenWidth * 0.01),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      statusIcon,
                      size: screenWidth * 0.03,
                      color: statusColor,
                    ),
                    SizedBox(width: screenWidth * 0.01),
                    Text(
                      statusText,
                      style: TextStyle(
                        fontSize: screenWidth * 0.025,
                        fontWeight: FontWeight.w500,
                        color: statusColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: screenWidth * 0.02),
          Text(
            'Symptoms: $symptoms',
            style: TextStyle(
              fontSize: screenWidth * 0.035,
              color: const Color(0xFF374151),
            ),
          ),
          SizedBox(height: screenWidth * 0.02),
          Row(
            children: [
              Icon(
                Icons.calendar_today,
                size: screenWidth * 0.035,
                color: Colors.grey[600],
              ),
              SizedBox(width: screenWidth * 0.01),
              Text(
                'Created: ${createdAt.day}/${createdAt.month}/${createdAt.year} at ${createdAt.hour}:${createdAt.minute.toString().padLeft(2, '0')}',
                style: TextStyle(
                  fontSize: screenWidth * 0.03,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          if (startedAt != null) ...[
            SizedBox(height: screenWidth * 0.01),
            Row(
              children: [
                Icon(
                  Icons.play_circle,
                  size: screenWidth * 0.035,
                  color: Colors.grey[600],
                ),
                SizedBox(width: screenWidth * 0.01),
                Text(
                  'Started: ${startedAt.day}/${startedAt.month}/${startedAt.year} at ${startedAt.hour}:${startedAt.minute.toString().padLeft(2, '0')}',
                  style: TextStyle(
                    fontSize: screenWidth * 0.03,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ],
          if (endedAt != null) ...[
            SizedBox(height: screenWidth * 0.01),
            Row(
              children: [
                Icon(
                  Icons.stop_circle,
                  size: screenWidth * 0.035,
                  color: Colors.grey[600],
                ),
                SizedBox(width: screenWidth * 0.01),
                Text(
                  'Ended: ${endedAt.day}/${endedAt.month}/${endedAt.year} at ${endedAt.hour}:${endedAt.minute.toString().padLeft(2, '0')}',
                  style: TextStyle(
                    fontSize: screenWidth * 0.03,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ],
          if (startedAt != null && endedAt != null) ...[
            SizedBox(height: screenWidth * 0.01),
            Row(
              children: [
                Icon(
                  Icons.timer,
                  size: screenWidth * 0.035,
                  color: Colors.grey[600],
                ),
                SizedBox(width: screenWidth * 0.01),
                Text(
                  'Duration: ${_formatDuration(endedAt.difference(startedAt))}',
                  style: TextStyle(
                    fontSize: screenWidth * 0.03,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes}m ${seconds}s';
  }
}