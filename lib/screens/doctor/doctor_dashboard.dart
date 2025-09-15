import 'package:flutter/material.dart';
import '../../services/supabase_service.dart';
import '../../services/offline_sync_service.dart';
import '../../utils/app_router.dart';
import 'doctor_appointments_tab.dart';
import 'doctor_patients_tab.dart';
import 'doctor_profile_tab.dart';
import 'doctor_consultations_tab.dart';
import '../patient/symptom_checker_screen.dart';

class DoctorDashboard extends StatefulWidget {
  const DoctorDashboard({super.key});

  @override
  State<DoctorDashboard> createState() => _DoctorDashboardState();
}

class _DoctorDashboardState extends State<DoctorDashboard> {
  int _currentIndex = 0;
  Map<String, dynamic>? _profile;
  Map<String, dynamic> _stats = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final user = SupabaseService.currentUser;
    if (user != null) {
      try {
        final profile = await SupabaseService.getProfile(user.id);
        final stats = await SupabaseService.getDoctorStats(user.id);
        
        if (mounted) {
          setState(() {
            _profile = profile;
            _stats = stats;
          });
        }
      } catch (e) {
        print('DEBUG: Failed to load doctor data: $e');
      }
    }
  }

  Future<List<Map<String, dynamic>>> _getRecentConsultations() async {
    final user = SupabaseService.currentUser;
    if (user != null) {
      try {
        return await SupabaseService.getConsultationHistory(user.id, 'doctor');
      } catch (e) {
        return [];
      }
    }
    return [];
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Dr. ${_profile?['full_name'] ?? 'Doctor'}',
          style: TextStyle(
            color: const Color(0xFF1A1A1A),
            fontWeight: FontWeight.w600,
            fontSize: screenWidth * 0.045,
          ),
        ),
        actions: [
          _buildStatusToggle(),
          IconButton(
            icon: Icon(
              Icons.sync,
              color: const Color(0xFF1A1A1A),
              size: screenWidth * 0.06,
            ),
            onPressed: _testSync,
          ),
        ],
      ),
      body: PopScope(
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
            _buildConsultationsTab(),
            _buildPatientsTab(),
            _buildProfileTab(),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          print('DEBUG: Doctor dashboard tab tapped: $index');
          setState(() => _currentIndex = index);
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFF00B4D8),
        unselectedItemColor: const Color(0xFF64748B),
        selectedFontSize: screenWidth * 0.03,
        unselectedFontSize: screenWidth * 0.025,
        iconSize: screenWidth * 0.06,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Dashboard'),
          BottomNavigationBarItem(icon: Icon(Icons.video_call), label: 'Consultations'),
          BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Patients'),
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
          _buildStatsCards(),
          SizedBox(height: screenHeight * 0.03),
          _buildQuickActions(),
          SizedBox(height: screenHeight * 0.03),
          _buildRecentConsultations(),
        ],
      ),
    );
  }

  Widget _buildStatsCards() {
    final screenWidth = MediaQuery.of(context).size.width;

    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'Total Consultations',
            _stats['total_consultations']?.toString() ?? '0',
            Icons.video_call,
            const Color(0xFF00B4D8),
          ),
        ),
        SizedBox(width: screenWidth * 0.03),
        Expanded(
          child: _buildStatCard(
            'Completed',
            _stats['completed_consultations']?.toString() ?? '0',
            Icons.check_circle,
            const Color(0xFF0077B6),
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    final screenSize = MediaQuery.of(context).size;
    final screenWidth = screenSize.width;
    final screenHeight = screenSize.height;

    return Container(
      padding: EdgeInsets.all(screenWidth * 0.04),
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
          Icon(icon, color: color, size: screenWidth * 0.06),
          SizedBox(height: screenHeight * 0.01),
          Text(
            value,
            style: TextStyle(
              fontSize: screenWidth * 0.06,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1A1A1A),
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: screenWidth * 0.03,
              color: const Color(0xFF64748B),
            ),
          ),
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
                  'Consultations',
                  Icons.video_call,
                  const Color(0xFF00B4D8),
                  () => setState(() => _currentIndex = 1),
                ),
              ),
              SizedBox(width: screenWidth * 0.03),
              Expanded(
                child: _buildActionCard(
                  'AI Symptom Analyzer',
                  Icons.psychology,
                  const Color(0xFF0077B6),
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SymptomCheckerScreen(),
                    ),
                  ),
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
                  'Chat Messages',
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

  Widget _buildRecentConsultations() {
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recent Consultations',
                style: TextStyle(
                  fontSize: screenWidth * 0.045,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1A1A1A),
                ),
              ),
              TextButton(
                onPressed: () => setState(() => _currentIndex = 1),
                child: Text(
                  'View All',
                  style: TextStyle(
                    fontSize: screenWidth * 0.035,
                    color: const Color(0xFF00B4D8),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: screenHeight * 0.02),
          FutureBuilder<List<Map<String, dynamic>>>(
            future: _getRecentConsultations(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return Text(
                  'No recent consultations',
                  style: TextStyle(
                    fontSize: screenWidth * 0.035,
                    color: const Color(0xFF64748B),
                  ),
                );
              }
              
              return Column(
                children: snapshot.data!.take(5).map((consultation) {
                  final createdAt = DateTime.parse(consultation['created_at']);
                  final patientName = consultation['patient_name'] ?? 'Unknown Patient';
                  final status = consultation['status'];
                  
                  return Container(
                    margin: EdgeInsets.only(bottom: screenHeight * 0.01),
                    padding: EdgeInsets.all(screenWidth * 0.03),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(screenWidth * 0.02),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.video_call,
                          color: const Color(0xFF00B4D8),
                          size: screenWidth * 0.04,
                        ),
                        SizedBox(width: screenWidth * 0.03),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                patientName,
                                style: TextStyle(
                                  fontSize: screenWidth * 0.035,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                '${createdAt.day}/${createdAt.month}/${createdAt.year}',
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
                            vertical: screenWidth * 0.005,
                          ),
                          decoration: BoxDecoration(
                            color: status == 'completed' ? Colors.green : Colors.orange,
                            borderRadius: BorderRadius.circular(screenWidth * 0.01),
                          ),
                          child: Text(
                            status.toUpperCase(),
                            style: TextStyle(
                              fontSize: screenWidth * 0.025,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildConsultationsTab() {
    return const DoctorConsultationsTab();
  }

  Widget _buildAppointmentsTab() {
    return const DoctorAppointmentsTab();
  }

  Widget _buildPatientsTab() {
    print('DEBUG: Building patients tab');
    return DoctorPatientsTab(key: ValueKey(_currentIndex));
  }

  Widget _buildProfileTab() {
    return const DoctorProfileTab();
  }



  Widget _buildStatusToggle() {
    final isOnline = _profile?['status'] == true;
    
    return GestureDetector(
      onTap: () => _toggleOnlineStatus(!isOnline),
      child: Container(
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isOnline ? Colors.green : Colors.grey[400],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.circle,
              color: Colors.white,
              size: 8,
            ),
            const SizedBox(width: 4),
            Text(
              isOnline ? 'Online' : 'Offline',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _toggleOnlineStatus(bool value) async {
    try {
      final user = SupabaseService.currentUser;
      if (user != null) {
        print('DEBUG: Updating status for user ${user.id} to $value');
        
        // Direct database update
        await SupabaseService.client
            .from('profiles')
            .update({'status': value})
            .eq('id', user.id);
        
        print('DEBUG: Status updated successfully');
        
        setState(() {
          _profile?['status'] = value;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(value ? 'You are now online' : 'You are now offline'),
            backgroundColor: value ? Colors.green : Colors.grey,
          ),
        );
      }
    } catch (e) {
      print('DEBUG: Failed to update status: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to update status. Please try again.')),
      );
    }
  }

  Future<void> _testSync() async {
    try {
      final syncService = OfflineSyncService();
      
      // Debug offline operations
      await syncService.debugOfflineOperations();
      
      // Manual sync
      await syncService.syncNow();
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Manual sync completed! Check console logs.')),
      );
    } catch (e) {
      print('DEBUG: Manual sync failed: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sync failed. Please check your connection.')),
      );
    }
  }

  Future<void> _signOut() async {
    try {
      await SupabaseService.signOut();
      if (mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            AppRouter.replace('/login');
          }
        });
      }
    } catch (e) {
      print('DEBUG: Sign out failed: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to sign out. Please try again.')),
        );
      }
    }
  }
}