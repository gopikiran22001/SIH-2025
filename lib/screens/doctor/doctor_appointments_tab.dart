import 'package:flutter/material.dart';
import '../../services/supabase_service.dart';

class DoctorAppointmentsTab extends StatefulWidget {
  const DoctorAppointmentsTab({super.key});

  @override
  State<DoctorAppointmentsTab> createState() => _DoctorAppointmentsTabState();
}

class _DoctorAppointmentsTabState extends State<DoctorAppointmentsTab> {
  List<Map<String, dynamic>> _appointments = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAppointments();
  }

  Future<void> _loadAppointments() async {
    try {
      final user = SupabaseService.currentUser;
      if (user != null) {
        final appointments = await SupabaseService.getAppointments(user.id, 'doctor');
        if (mounted) {
          setState(() {
            _appointments = appointments;
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

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
          return _buildAppointmentCard(_appointments[index]);
        },
      ),
    );
  }

  Widget _buildAppointmentCard(Map<String, dynamic> appointment) {
    final screenWidth = MediaQuery.of(context).size.width;
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
                        appointment['patient_profile']?['full_name'] ?? 'Patient',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: screenWidth * 0.04,
                          color: const Color(0xFF1A1A1A),
                        ),
                      ),
                      Text(
                        appointment['patient_profile']?['phone'] ?? 'No phone',
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
            if (status == 'pending') ...[
              SizedBox(height: screenWidth * 0.03),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _updateAppointmentStatus(appointment['id'], 'cancelled'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFDC2626),
                        side: const BorderSide(color: Color(0xFFDC2626)),
                      ),
                      child: Text(
                        'Decline',
                        style: TextStyle(fontSize: screenWidth * 0.03),
                      ),
                    ),
                  ),
                  SizedBox(width: screenWidth * 0.02),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _updateAppointmentStatus(appointment['id'], 'confirmed'),
                      child: Text(
                        'Confirm',
                        style: TextStyle(fontSize: screenWidth * 0.03),
                      ),
                    ),
                  ),
                ],
              ),
            ],
            if (status == 'confirmed') ...[
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
                    child: ElevatedButton(
                      onPressed: () => _updateAppointmentStatus(appointment['id'], 'completed'),
                      child: Text(
                        'Complete',
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
    );
  }

  Future<void> _updateAppointmentStatus(String appointmentId, String status) async {
    try {
      await SupabaseService.updateAppointment(appointmentId, {'status': status});
      _loadAppointments();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Appointment ${status.toLowerCase()} successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update appointment: $e')),
        );
      }
    }
  }

  void _startChat(Map<String, dynamic> appointment) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Chat feature coming soon')),
    );
  }
}