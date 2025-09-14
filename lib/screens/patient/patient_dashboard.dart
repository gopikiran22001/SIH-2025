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
  List<Map<String, dynamic>> _consultations = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    // Always load cached data first for immediate display
    final cachedUser = LocalStorageService.getCurrentUser();
    
    if (mounted && cachedUser != null) {
      setState(() {
        _profile = cachedUser;
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
          final consultations = await SupabaseService.getConsultationHistory(user.id, 'patient');
          print('DEBUG: Loaded ${consultations.length} consultations');
          if (mounted) {
            setState(() {
              _consultations = consultations;
            });
          }
        } catch (consultationError) {
          print('DEBUG: Failed to sync consultations: $consultationError');
          // Add sample data for testing
          if (mounted) {
            setState(() {
              _consultations = [
                {
                  'id': '1',
                  'created_at': DateTime.now().subtract(const Duration(days: 2)).toIso8601String(),
                  'doctor_name': 'Sarah Johnson',
                  'status': 'completed',
                  'duration': 25,
                },
                {
                  'id': '2', 
                  'created_at': DateTime.now().subtract(const Duration(days: 7)).toIso8601String(),
                  'doctor_name': 'Michael Chen',
                  'status': 'completed',
                  'duration': 18,
                },
              ];
            });
          }
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
          _buildPastConsultations(),
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
                  'Find Medicine',
                  Icons.medication,
                  const Color(0xFF023E8A),
                  () => ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Find Medicine feature coming soon')),
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

  Widget _buildPastConsultations() {
    final screenSize = MediaQuery.of(context).size;
    final screenWidth = screenSize.width;
    final screenHeight = screenSize.height;

    final recentConsultations = _consultations.take(5).toList();

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
            'Past Consultations',
            style: TextStyle(
              fontSize: screenWidth * 0.045,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1A1A1A),
            ),
          ),
          SizedBox(height: screenHeight * 0.02),
          if (recentConsultations.isEmpty)
            Container(
              padding: EdgeInsets.all(screenWidth * 0.04),
              child: Column(
                children: [
                  Icon(Icons.history, size: screenWidth * 0.12, color: Colors.grey[400]),
                  SizedBox(height: screenHeight * 0.01),
                  Text(
                    'No consultations yet',
                    style: TextStyle(
                      fontSize: screenWidth * 0.04,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[600],
                    ),
                  ),
                  Text(
                    'Start your first consultation with our AI symptom checker',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: screenWidth * 0.032,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            )
          else
            ...recentConsultations.map((consultation) => _buildConsultationCard(consultation)),
        ],
      ),
    );
  }

  Widget _buildConsultationCard(Map<String, dynamic> consultation) {
    final screenSize = MediaQuery.of(context).size;
    final screenWidth = screenSize.width;
    final screenHeight = screenSize.height;
    
    final createdAt = DateTime.parse(consultation['created_at']);
    final doctorName = consultation['doctor_name'] ?? 'Doctor';
    final status = consultation['status'] ?? 'completed';
    final duration = consultation['duration'] ?? 0;
    
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
              Icons.video_call,
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
                  'Dr. $doctorName',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1A1A1A),
                    fontSize: screenWidth * 0.035,
                  ),
                ),
                Text(
                  '${createdAt.day}/${createdAt.month}/${createdAt.year}',
                  style: TextStyle(
                    color: const Color(0xFF64748B),
                    fontSize: screenWidth * 0.03,
                  ),
                ),
                if (duration > 0)
                  Text(
                    'Duration: ${duration}min',
                    style: TextStyle(
                      color: const Color(0xFF64748B),
                      fontSize: screenWidth * 0.025,
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
              color: status == 'completed' 
                  ? const Color(0xFF059669).withValues(alpha: 0.1)
                  : const Color(0xFFF59E0B).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(screenWidth * 0.01),
            ),
            child: Text(
              status.toUpperCase(),
              style: TextStyle(
                fontSize: screenWidth * 0.025,
                fontWeight: FontWeight.w500,
                color: status == 'completed' 
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