import 'package:flutter/material.dart';
import '../../services/supabase_service.dart';
import '../../services/local_storage_service.dart';

class AppointmentsHistoryScreen extends StatefulWidget {
  const AppointmentsHistoryScreen({super.key});

  @override
  State<AppointmentsHistoryScreen> createState() => _AppointmentsHistoryScreenState();
}

class _AppointmentsHistoryScreenState extends State<AppointmentsHistoryScreen> {
  List<Map<String, dynamic>> _appointments = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAppointments();
  }

  Future<void> _loadAppointments() async {
    try {
      // Load cached data first
      final cachedAppointments = LocalStorageService.getCachedAppointments();
      final cachedCompleted = cachedAppointments.where((a) => a['status'] == 'completed').toList();
      
      if (mounted && cachedCompleted.isNotEmpty) {
        setState(() {
          _appointments = cachedCompleted;
          _isLoading = false;
        });
      }
      
      // Then sync from server
      final user = SupabaseService.currentUser;
      if (user != null) {
        try {
          final appointments = await SupabaseService.getAppointments(user.id, 'patient');
          await LocalStorageService.cacheAppointments(appointments);
          final completedAppointments = appointments.where((a) => a['status'] == 'completed').toList();
          
          if (mounted) {
            setState(() {
              _appointments = completedAppointments;
              _isLoading = false;
            });
          }
        } catch (e) {
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
        title: const Text('Past Appointments'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _appointments.isEmpty
              ? Center(
                  child: Text(
                    'No completed appointments yet',
                    style: TextStyle(
                      fontSize: screenWidth * 0.04,
                      color: Colors.grey[600],
                    ),
                  ),
                )
              : ListView.builder(
                  padding: EdgeInsets.all(screenWidth * 0.04),
                  itemCount: _appointments.length,
                  itemBuilder: (context, index) {
                    final appointment = _appointments[index];
                    final date = DateTime.parse(appointment['scheduled_at']);
                    final doctorName = appointment['profiles']?['full_name'] ?? 'Unknown Doctor';
                    
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
                                Icons.medical_services,
                                color: const Color(0xFF2563EB),
                                size: screenWidth * 0.05,
                              ),
                              SizedBox(width: screenWidth * 0.03),
                              Expanded(
                                child: Text(
                                  doctorName,
                                  style: TextStyle(
                                    fontSize: screenWidth * 0.04,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: screenWidth * 0.02),
                          Text(
                            '${date.day}/${date.month}/${date.year} at ${date.hour}:${date.minute.toString().padLeft(2, '0')}',
                            style: TextStyle(
                              fontSize: screenWidth * 0.035,
                              color: Colors.grey[600],
                            ),
                          ),
                          if (appointment['notes'] != null) ...[
                            SizedBox(height: screenWidth * 0.02),
                            Text(
                              appointment['notes'],
                              style: TextStyle(fontSize: screenWidth * 0.035),
                            ),
                          ],
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}