import 'package:flutter/material.dart';
import '../../services/supabase_service.dart';
import '../../services/local_storage_service.dart';
import '../../services/offline_sync_service.dart';
import '../../utils/app_router.dart';
import '../../widgets/offline_indicator.dart';
import 'appointments_tab.dart';
import 'ai_analysis_tab.dart';
import 'chat_tab.dart';
import 'profile_tab.dart';
import 'consultation_history_screen.dart';

class PatientDashboard extends StatefulWidget {
  const PatientDashboard({super.key});

  @override
  State<PatientDashboard> createState() => _PatientDashboardState();
}

class _PatientDashboardState extends State<PatientDashboard> {
  int _currentIndex = 0;
  Map<String, dynamic>? _profile;
  List<Map<String, dynamic>> _appointments = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    // Always load cached data first for immediate display
    final cachedUser = LocalStorageService.getCurrentUser();
    final cachedAppointments = LocalStorageService.getCachedAppointments();
    
    if (mounted && cachedUser != null) {
      setState(() {
        _profile = cachedUser;
        _appointments = cachedAppointments;
      });
    }
    
    // Then try to sync from server if user session exists
    final user = SupabaseService.currentUser;
    if (user != null) {
      try {
        final profile = await SupabaseService.getProfile(user.id);
        if (profile != null) {
          await LocalStorageService.saveCurrentUser(profile);
          if (mounted) {
            setState(() {
              _profile = profile;
            });
          }
        }
        
        try {
          final appointments = await SupabaseService.getAppointments(user.id, 'patient');
          await LocalStorageService.cacheAppointments(appointments);
          if (mounted) {
            setState(() {
              _appointments = appointments;
            });
          }
        } catch (appointmentError) {
          print('DEBUG: Failed to sync appointments, using cached: $appointmentError');
        }
      } catch (e) {
        print('DEBUG: Failed to sync profile data: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final screenWidth = screenSize.width;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Hello, ${_profile?['full_name'] ?? 'Patient'}',
          style: TextStyle(
            color: const Color(0xFF1A1A1A),
            fontWeight: FontWeight.w600,
            fontSize: screenWidth * 0.045,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.sync,
              color: const Color(0xFF1A1A1A),
              size: screenWidth * 0.06,
            ),
            onPressed: () async {
              final syncService = OfflineSyncService();
              await syncService.syncNow();
              _loadData();
            },
          ),
          IconButton(
            icon: Icon(
              Icons.notifications_outlined,
              color: const Color(0xFF1A1A1A),
              size: screenWidth * 0.06,
            ),
            onPressed: () {},
          ),
        ],
      ),
      body: OfflineIndicator(
        child: PopScope(
          canPop: _currentIndex == 0,
          onPopInvoked: (didPop) {
            if (!didPop && _currentIndex != 0) {
              setState(() => _currentIndex = 0);
            }
          },
          child: IndexedStack(
            index: _currentIndex,
            children: [
              _buildHomeTab(),
              _buildAiAnalysisTab(),
              _buildChatTab(),
              _buildProfileTab(),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          if (index == 2) { // Chat tab
            AppRouter.go('/chat-list');
          } else {
            setState(() => _currentIndex = index);
          }
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFF00B4D8),
        unselectedItemColor: const Color(0xFF64748B),
        selectedFontSize: screenWidth * 0.03,
        unselectedFontSize: screenWidth * 0.025,
        iconSize: screenWidth * 0.06,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.psychology), label: 'AI Analysis'),
          BottomNavigationBarItem(icon: Icon(Icons.chat), label: 'Chat'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }

  Widget _buildHomeTab() {
    final screenSize = MediaQuery.of(context).size;
    final screenWidth = screenSize.width;
    final screenHeight = screenSize.height;

    return SingleChildScrollView(
      padding: EdgeInsets.all(screenWidth * 0.04),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildQuickActions(),
          SizedBox(height: screenHeight * 0.03),
          _buildUpcomingAppointments(),
          SizedBox(height: screenHeight * 0.03),
          _buildHealthTips(),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    final screenSize = MediaQuery.of(context).size;
    final screenWidth = screenSize.width;
    final screenHeight = screenSize.height;

    return Container(
      padding: EdgeInsets.all(screenWidth * 0.05),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(screenWidth * 0.03),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: screenWidth * 0.025,
            offset: Offset(0, screenHeight * 0.0025),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quick Actions',
            style: TextStyle(
              fontSize: screenWidth * 0.045,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1A1A1A),
            ),
          ),
          SizedBox(height: screenHeight * 0.02),
          Row(
            children: [
              Expanded(
                child: _buildActionCard(
                  'Video Consultation',
                  Icons.video_call,
                  const Color(0xFF00B4D8),
                  () => AppRouter.go('/book-appointment'),
                ),
              ),
              SizedBox(width: screenWidth * 0.03),
              Expanded(
                child: _buildActionCard(
                  'AI Symptom Check',
                  Icons.psychology,
                  const Color(0xFF0077B6),
                  () => AppRouter.go('/symptom-checker'),
                ),
              ),
            ],
          ),
          SizedBox(height: screenHeight * 0.015),
          Row(
            children: [
              Expanded(
                child: _buildActionCard(
                  'Consultation History',
                  Icons.history,
                  const Color(0xFF023E8A),
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ConsultationHistoryScreen(),
                    ),
                  ),
                ),
              ),
              SizedBox(width: screenWidth * 0.03),
              Expanded(
                child: _buildActionCard(
                  'Chat with Doctor',
                  Icons.chat,
                  const Color(0xFF0096C7),
                  () => AppRouter.go('/chat-list'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard(String title, IconData icon, Color color, VoidCallback onTap) {
    final screenSize = MediaQuery.of(context).size;
    final screenWidth = screenSize.width;
    final screenHeight = screenSize.height;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(screenWidth * 0.04),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(screenWidth * 0.02),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: screenWidth * 0.06),
            SizedBox(height: screenHeight * 0.01),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: screenWidth * 0.03,
                fontWeight: FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUpcomingAppointments() {
    final screenSize = MediaQuery.of(context).size;
    final screenWidth = screenSize.width;
    final screenHeight = screenSize.height;

    final upcomingAppointments = _appointments
        .where((apt) => DateTime.parse(apt['scheduled_at']).isAfter(DateTime.now()))
        .take(3)
        .toList();

    return Container(
      padding: EdgeInsets.all(screenWidth * 0.05),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(screenWidth * 0.03),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: screenWidth * 0.025,
            offset: Offset(0, screenHeight * 0.0025),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Upcoming Appointments',
                style: TextStyle(
                  fontSize: screenWidth * 0.045,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1A1A1A),
                ),
              ),
              TextButton(
                onPressed: () => AppRouter.go('/appointments'),
                child: Text(
                  'View All',
                  style: TextStyle(fontSize: screenWidth * 0.035),
                ),
              ),
            ],
          ),
          SizedBox(height: screenHeight * 0.02),
          if (upcomingAppointments.isEmpty)
            Text(
              'No upcoming appointments',
              style: TextStyle(fontSize: screenWidth * 0.035),
            )
          else
            ...upcomingAppointments.map((apt) => _buildAppointmentCard(apt)),
        ],
      ),
    );
  }

  Widget _buildAppointmentCard(Map<String, dynamic> appointment) {
    final screenSize = MediaQuery.of(context).size;
    final screenWidth = screenSize.width;
    final screenHeight = screenSize.height;
    
    final scheduledAt = DateTime.parse(appointment['scheduled_at']);
    
    return Container(
      margin: EdgeInsets.only(bottom: screenHeight * 0.015),
      padding: EdgeInsets.all(screenWidth * 0.04),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(screenWidth * 0.02),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            width: screenWidth * 0.12,
            height: screenWidth * 0.12,
            decoration: const BoxDecoration(
              color: Color(0xFF00B4D8),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.person,
              color: Colors.white,
              size: screenWidth * 0.06,
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
                    color: const Color(0xFF1A1A1A),
                    fontSize: screenWidth * 0.035,
                  ),
                ),
                Text(
                  '${scheduledAt.day}/${scheduledAt.month}/${scheduledAt.year} at ${scheduledAt.hour}:${scheduledAt.minute.toString().padLeft(2, '0')}',
                  style: TextStyle(
                    color: const Color(0xFF64748B),
                    fontSize: screenWidth * 0.03,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: screenWidth * 0.02,
              vertical: screenHeight * 0.005,
            ),
            decoration: BoxDecoration(
              color: appointment['status'] == 'confirmed' 
                  ? const Color(0xFF059669).withValues(alpha: 0.1)
                  : const Color(0xFFF59E0B).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(screenWidth * 0.01),
            ),
            child: Text(
              appointment['status'].toString().toUpperCase(),
              style: TextStyle(
                fontSize: screenWidth * 0.025,
                fontWeight: FontWeight.w500,
                color: appointment['status'] == 'confirmed' 
                    ? const Color(0xFF059669)
                    : const Color(0xFFF59E0B),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHealthTips() {
    final screenSize = MediaQuery.of(context).size;
    final screenWidth = screenSize.width;
    final screenHeight = screenSize.height;

    return Container(
      padding: EdgeInsets.all(screenWidth * 0.05),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(screenWidth * 0.03),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: screenWidth * 0.025,
            offset: Offset(0, screenHeight * 0.0025),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Health Tips',
            style: TextStyle(
              fontSize: screenWidth * 0.045,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1A1A1A),
            ),
          ),
          SizedBox(height: screenHeight * 0.02),
          Text(
            '• Drink at least 8 glasses of water daily\n'
            '• Get 7-9 hours of sleep each night\n'
            '• Exercise for at least 30 minutes daily\n'
            '• Eat a balanced diet with fruits and vegetables',
            style: TextStyle(
              color: const Color(0xFF64748B),
              height: 1.5,
              fontSize: screenWidth * 0.035,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppointmentsTab() {
    return const AppointmentsTab();
  }

  Widget _buildAiAnalysisTab() {
    return const AiAnalysisTab();
  }

  Widget _buildChatTab() {
    return const ChatTab();
  }

  Widget _buildProfileTab() {
    return const ProfileTab();
  }
}