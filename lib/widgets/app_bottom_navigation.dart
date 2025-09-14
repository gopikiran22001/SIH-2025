import 'package:flutter/material.dart';
import '../services/local_storage_service.dart';
import '../utils/app_router.dart';

class AppBottomNavigation extends StatelessWidget {
  final String currentRoute;
  
  const AppBottomNavigation({super.key, required this.currentRoute});

  @override
  Widget build(BuildContext context) {
    final currentUser = LocalStorageService.getCurrentUser();
    final userRole = currentUser?['role'];
    final screenWidth = MediaQuery.of(context).size.width;
    
    if (userRole == 'doctor') {
      return _buildDoctorNavigation(context, screenWidth);
    } else {
      return _buildPatientNavigation(context, screenWidth);
    }
  }

  Widget _buildPatientNavigation(BuildContext context, double screenWidth) {
    int currentIndex = _getPatientCurrentIndex();
    
    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: (index) => _handlePatientNavigation(index),
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
    );
  }

  Widget _buildDoctorNavigation(BuildContext context, double screenWidth) {
    int currentIndex = _getDoctorCurrentIndex();
    
    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: (index) => _handleDoctorNavigation(index),
      type: BottomNavigationBarType.fixed,
      selectedItemColor: const Color(0xFF00B4D8),
      unselectedItemColor: const Color(0xFF64748B),
      selectedFontSize: screenWidth * 0.03,
      unselectedFontSize: screenWidth * 0.025,
      iconSize: screenWidth * 0.06,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Dashboard'),
        BottomNavigationBarItem(icon: Icon(Icons.calendar_today), label: 'Appointments'),
        BottomNavigationBarItem(icon: Icon(Icons.chat), label: 'Chat'),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
      ],
    );
  }

  int _getPatientCurrentIndex() {
    switch (currentRoute) {
      case '/patient-dashboard':
        return 0;
      case '/symptom-checker':
      case '/ai-assessment':
        return 1;
      case '/chat-list':
        return 2;
      case '/profile':
        return 3;
      default:
        return 0;
    }
  }

  int _getDoctorCurrentIndex() {
    switch (currentRoute) {
      case '/doctor-dashboard':
        return 0;
      case '/appointments':
        return 1;
      case '/chat-list':
        return 2;
      case '/profile':
        return 3;
      default:
        return 0;
    }
  }

  void _handlePatientNavigation(int index) {
    switch (index) {
      case 0:
        if (currentRoute != '/patient-dashboard') {
          AppRouter.replace('/patient-dashboard');
        }
        break;
      case 1:
        if (currentRoute != '/symptom-checker') {
          AppRouter.go('/symptom-checker');
        }
        break;
      case 2:
        if (currentRoute != '/chat-list') {
          AppRouter.go('/chat-list');
        }
        break;
      case 3:
        if (currentRoute != '/profile') {
          AppRouter.go('/profile');
        }
        break;
    }
  }

  void _handleDoctorNavigation(int index) {
    switch (index) {
      case 0:
        if (currentRoute != '/doctor-dashboard') {
          AppRouter.replace('/doctor-dashboard');
        }
        break;
      case 1:
        if (currentRoute != '/doctor-dashboard') {
          AppRouter.replace('/doctor-dashboard');
        }
        break;
      case 2:
        if (currentRoute != '/chat-list') {
          AppRouter.go('/chat-list');
        }
        break;
      case 3:
        if (currentRoute != '/profile') {
          AppRouter.go('/profile');
        }
        break;
    }
  }
}