import 'dart:async';
import 'package:flutter/material.dart';
import '../../services/supabase_service.dart';
import '../../services/local_storage_service.dart';
import '../../utils/app_router.dart';

class AppointmentsTab extends StatefulWidget {
  const AppointmentsTab({super.key});

  @override
  State<AppointmentsTab> createState() => _AppointmentsTabState();
}

class _AppointmentsTabState extends State<AppointmentsTab> {
  List<Map<String, dynamic>> _appointments = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAppointments();
  }

  Future<void> _loadAppointments() async {
    try {
      // First load from cache for immediate display
      final localAppointments = LocalStorageService.getCachedAppointments();
      if (mounted && localAppointments.isNotEmpty) {
        setState(() {
          _appointments = localAppointments;
          _isLoading = false;
        });
      }
      
      // Then try to sync from server
      final user = SupabaseService.currentUser;
      if (user != null) {
        try {
          final appointments = await SupabaseService.getAppointments(user.id, 'patient');
          await LocalStorageService.cacheAppointments(appointments);
          if (mounted) {
            setState(() {
              _appointments = appointments;
              _isLoading = false;
            });
          }
        } on TimeoutException {
          print('DEBUG: Appointments sync timeout - using cached data');
          if (mounted && _appointments.isEmpty) {
            setState(() => _isLoading = false);
          }
        } catch (e) {
          print('DEBUG: Failed to load appointments from server: $e');
          if (mounted && _appointments.isEmpty) {
            setState(() => _isLoading = false);
          }
        }
      } else {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    } catch (e) {
      print('DEBUG: Error loading appointments: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final screenWidth = screenSize.width;

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_appointments.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.calendar_today_outlined,
              size: screenWidth * 0.2,
              color: Colors.grey[400],
            ),
            SizedBox(height: screenWidth * 0.04),
            Text(
              'No appointments yet',
              style: TextStyle(
                fontSize: screenWidth * 0.045,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: screenWidth * 0.02),
            Text(
              'Book your first appointment to get started',
              style: TextStyle(
                fontSize: screenWidth * 0.035,
                color: Colors.grey[500],
              ),
            ),
            SizedBox(height: screenWidth * 0.08),
            ElevatedButton(
              onPressed: () => AppRouter.go('/book-appointment'),
              child: Text(
                'Book Appointment',
                style: TextStyle(fontSize: screenWidth * 0.04),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadAppointments,
      child: ListView.builder(
        padding: EdgeInsets.all(screenWidth * 0.04),
        itemCount: _appointments.length,
        itemBuilder: (context, index) {
          final appointment = _appointments[index];
          return _buildAppointmentCard(appointment);
        },
      ),
    );
  }

  Widget _buildAppointmentCard(Map<String, dynamic> appointment) {
    final screenSize = MediaQuery.of(context).size;
    final screenWidth = screenSize.width;
    final scheduledAt = DateTime.parse(appointment['scheduled_at']);
    final status = appointment['status'] ?? 'pending';
    
    Color statusColor;
    switch (status) {
      case 'confirmed':
        statusColor = const Color(0xFF059669);
        break;
      case 'completed':
        statusColor = const Color(0xFF2563EB);
        break;
      case 'cancelled':
        statusColor = const Color(0xFFDC2626);
        break;
      default:
        statusColor = const Color(0xFFF59E0B);
    }

    return Card(
      margin: EdgeInsets.only(bottom: screenWidth * 0.03),
      child: InkWell(
        onTap: () => AppRouter.go('/appointment-details/${appointment['id']}'),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.all(screenWidth * 0.04),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: const Color(0xFF2563EB),
                    radius: screenWidth * 0.06,
                    child: Icon(
                      Icons.person,
                      color: Colors.white,
                      size: screenWidth * 0.05,
                    ),
                  ),
                  SizedBox(width: screenWidth * 0.03),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Dr. ${appointment['profiles']?['full_name'] ?? 'Doctor'}',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: screenWidth * 0.04,
                            color: const Color(0xFF1A1A1A),
                          ),
                        ),
                        Text(
                          appointment['profiles']?['specialization'] ?? 'General Medicine',
                          style: TextStyle(
                            fontSize: screenWidth * 0.03,
                            color: const Color(0xFF64748B),
                          ),
                        ),
                      ],
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
                    child: Text(
                      status.toUpperCase(),
                      style: TextStyle(
                        fontSize: screenWidth * 0.025,
                        fontWeight: FontWeight.w500,
                        color: statusColor,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: screenWidth * 0.03),
              Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: screenWidth * 0.04,
                    color: const Color(0xFF64748B),
                  ),
                  SizedBox(width: screenWidth * 0.02),
                  Text(
                    '${scheduledAt.day}/${scheduledAt.month}/${scheduledAt.year}',
                    style: TextStyle(
                      fontSize: screenWidth * 0.035,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                  SizedBox(width: screenWidth * 0.04),
                  Icon(
                    Icons.access_time,
                    size: screenWidth * 0.04,
                    color: const Color(0xFF64748B),
                  ),
                  SizedBox(width: screenWidth * 0.02),
                  Text(
                    '${scheduledAt.hour}:${scheduledAt.minute.toString().padLeft(2, '0')}',
                    style: TextStyle(
                      fontSize: screenWidth * 0.035,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
              if (status == 'confirmed' && scheduledAt.isAfter(DateTime.now())) ...[
                SizedBox(height: screenWidth * 0.03),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _startChat(appointment),
                        icon: Icon(Icons.chat, size: screenWidth * 0.04),
                        label: Text(
                          'Chat',
                          style: TextStyle(fontSize: screenWidth * 0.03),
                        ),
                      ),
                    ),
                    SizedBox(width: screenWidth * 0.02),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _startVideoCall(appointment),
                        icon: Icon(Icons.videocam, size: screenWidth * 0.04),
                        label: Text(
                          'Video Call',
                          style: TextStyle(fontSize: screenWidth * 0.03),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _startChat(Map<String, dynamic> appointment) {
    final doctorId = appointment['doctor_id'];
    final doctorName = appointment['profiles']?['full_name'] ?? 'Doctor';
    final conversationId = '${appointment['patient_id']}_$doctorId';
    
    AppRouter.go('/chat/$conversationId/$doctorId/$doctorName');
  }

  void _startVideoCall(Map<String, dynamic> appointment) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Video call feature coming soon')),
    );
  }
}