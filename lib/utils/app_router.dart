import 'package:flutter/material.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/patient/patient_dashboard.dart';
import '../screens/patient/symptom_checker_screen.dart';
import '../screens/patient/chat_screen.dart';
import '../screens/common/hms_video_call_screen.dart';
import '../screens/doctor/doctor_dashboard.dart';
import '../screens/book_appointment_screen.dart';
import '../screens/chat_list_screen.dart';
import '../screens/profile_screen.dart';
import '../widgets/app_bottom_navigation.dart';
import '../services/supabase_service.dart';
import '../services/local_storage_service.dart';


class AppRouter {
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  
  static bool _isAuthenticated() {
    final hasValidSession = SupabaseService.hasValidSession;
    final localUser = LocalStorageService.getCurrentUser();
    return hasValidSession && localUser != null;
  }
  
  static String _getAuthenticatedUserDashboard() {
    final localUser = LocalStorageService.getCurrentUser();
    if (localUser != null) {
      final role = localUser['role'];
      if (role == 'patient') {
        return '/patient-dashboard';
      } else if (role == 'doctor') {
        return '/doctor-dashboard';
      }
    }
    return '/login';
  }
  
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case '/login':
        if (_isAuthenticated()) {
          return MaterialPageRoute(
            builder: (_) => _RedirectScreen(_getAuthenticatedUserDashboard()),
          );
        }
        return MaterialPageRoute(builder: (_) => const LoginScreen());
      case '/register':
        if (_isAuthenticated()) {
          return MaterialPageRoute(
            builder: (_) => _RedirectScreen(_getAuthenticatedUserDashboard()),
          );
        }
        return MaterialPageRoute(builder: (_) => const RegisterScreen());
      case '/patient-dashboard':
        return MaterialPageRoute(builder: (_) => const PatientDashboard());
      case '/doctor-dashboard':
        return MaterialPageRoute(builder: (_) => const DoctorDashboard());
      case '/symptom-checker':
        return MaterialPageRoute(builder: (_) => const SymptomCheckerScreen());
      case '/ai-assessment':
        return MaterialPageRoute(builder: (_) => const SymptomCheckerScreen());
      case '/book-appointment':
        return MaterialPageRoute(builder: (_) => const BookAppointmentScreen());
      case '/chat-list':
        return MaterialPageRoute(builder: (_) => const ChatListScreen());
      case '/profile':
        return MaterialPageRoute(builder: (_) => const ProfileScreen());
      case '/chat':
        final args = settings.arguments as Map<String, dynamic>?;
        if (args != null) {
          return MaterialPageRoute(
            builder: (_) => ChatScreen(
              conversationId: args['conversationId'],
              otherUserId: args['otherUserId'],
              otherUserName: args['otherUserName'],
            ),
          );
        }
        return MaterialPageRoute(builder: (_) => const LoginScreen());
      case '/documents':
        return MaterialPageRoute(builder: (_) => const DocumentsScreen());
      case '/profile':
        return MaterialPageRoute(builder: (_) => const ProfileScreen());
      default:
        if (settings.name?.startsWith('/chat/') == true) {
          final parts = settings.name!.split('/');
          if (parts.length >= 5) {
            return MaterialPageRoute(
              builder: (_) => ChatScreen(
                conversationId: parts[2],
                otherUserId: parts[3],
                otherUserName: parts[4],
              ),
            );
          }
        }
        if (settings.name?.startsWith('/hms-video-call') == true) {
          final uri = Uri.parse(settings.name!);
          final consultationId = uri.queryParameters['consultationId'];
          final args = settings.arguments as Map<String, dynamic>?;
          
          if (consultationId != null && args != null) {
            return MaterialPageRoute(
              builder: (_) => HMSVideoCallScreen(
                consultationId: consultationId,
                patientId: args['patientId'] ?? '',
                doctorId: args['doctorId'] ?? '',
                patientName: args['patientName'] ?? 'Patient',
                doctorName: args['doctorName'] ?? 'Doctor',
              ),
            );
          }
        }
        if (settings.name?.startsWith('/video-consultation/') == true) {
          final args = settings.arguments as Map<String, dynamic>?;
          if (args != null) {
            return MaterialPageRoute(
              builder: (_) => HMSVideoCallScreen(
                consultationId: args['consultationId'],
                patientId: args['patientId'],
                doctorId: args['doctorId'],
                patientName: args['patientName'],
                doctorName: args['doctorName'],
              ),
            );
          }
        }
        if (settings.name?.startsWith('/appointment-details/') == true) {
          final appointmentId = settings.name!.split('/').last;
          return MaterialPageRoute(
            builder: (_) => AppointmentDetailsScreen(appointmentId: appointmentId),
          );
        }
        return MaterialPageRoute(builder: (_) => const LoginScreen());
    }
  }
  
  static void go(String route) {
    navigatorKey.currentState?.pushNamed(route);
  }
  
  static void push(String route, {Object? arguments}) {
    navigatorKey.currentState?.pushNamed(route, arguments: arguments);
  }
  
  static void replace(String route) {
    navigatorKey.currentState?.pushReplacementNamed(route);
  }
  
  static void pop() {
    navigatorKey.currentState?.pop();
  }
}

// Placeholder screens - implement these based on your needs

class DocumentsScreen extends StatelessWidget {
  const DocumentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Documents'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else {
              AppRouter.replace('/patient-dashboard');
            }
          },
        ),
      ),
      body: const Center(child: Text('Documents Screen - Coming Soon')),
      bottomNavigationBar: const AppBottomNavigation(currentRoute: '/documents'),
    );
  }
}



class AppointmentDetailsScreen extends StatelessWidget {
  final String appointmentId;
  
  const AppointmentDetailsScreen({super.key, required this.appointmentId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Appointment Details'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else {
              AppRouter.replace('/patient-dashboard');
            }
          },
        ),
      ),
      body: Center(child: Text('Appointment Details for $appointmentId - Coming Soon')),
      bottomNavigationBar: const AppBottomNavigation(currentRoute: '/appointment-details'),
    );
  }
}

class _RedirectScreen extends StatefulWidget {
  final String targetRoute;
  
  const _RedirectScreen(this.targetRoute);

  @override
  State<_RedirectScreen> createState() => _RedirectScreenState();
}

class _RedirectScreenState extends State<_RedirectScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AppRouter.replace(widget.targetRoute);
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}