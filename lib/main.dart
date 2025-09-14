import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

import 'services/supabase_service.dart';
import 'services/local_storage_service.dart';
import 'services/offline_sync_service.dart';
import 'services/notification_service.dart';
import 'services/hms_consultation_service.dart';
import 'utils/app_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  await Firebase.initializeApp();
  

  // Initialize services
  await LocalStorageService.initialize();
  await SupabaseService.initialize();
  await NotificationService.initialize();
  await HMSConsultationService.initialize();
  
  // Initialize and sync offline service
  final syncService = OfflineSyncService();
  await syncService.init();
  
  // Save FCM token after initialization
  await NotificationService.saveTokenToDatabase();
  
  runApp(const MedVitaApp());
}

class AuthChecker extends StatefulWidget {
  const AuthChecker({super.key});

  @override
  State<AuthChecker> createState() => _AuthCheckerState();
}

class _AuthCheckerState extends State<AuthChecker> {
  @override
  void initState() {
    super.initState();
    _checkAuthStatus();
  }

  void _checkAuthStatus() async {
    // Add small delay to ensure Hive is fully initialized
    await Future.delayed(const Duration(milliseconds: 100));
    
    // Check if there's a valid Supabase session first
    final hasValidSession = SupabaseService.hasValidSession;
    final supabaseUser = SupabaseService.currentUser;
    final localUser = LocalStorageService.getCurrentUser();
    
    print('DEBUG: Has valid session: $hasValidSession');
    print('DEBUG: Supabase user: ${supabaseUser?.id}');
    print('DEBUG: Local user: ${localUser?['id']}');
    
    // If no valid Supabase session, clear local data and go to login
    if (!hasValidSession || supabaseUser == null) {
      print('DEBUG: No Supabase session, clearing local data');
      if (localUser != null) {
        await LocalStorageService.logout();
      }
      WidgetsBinding.instance.addPostFrameCallback((_) {
        AppRouter.replace('/login');
      });
      return;
    }
    
    // If Supabase session exists but no local user or ID mismatch, sync data
    if (localUser == null || localUser['id'] != supabaseUser.id) {
      print('DEBUG: Session/local data mismatch, syncing user data');
      try {
        final profile = await SupabaseService.getProfile(supabaseUser.id);
        if (profile != null) {
          await LocalStorageService.saveCurrentUser(profile);
          final role = profile['role'];
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (role == 'patient') {
              AppRouter.replace('/patient-dashboard');
            } else if (role == 'doctor') {
              AppRouter.replace('/doctor-dashboard');
            } else {
              AppRouter.replace('/login');
            }
          });
        } else {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            AppRouter.replace('/login');
          });
        }
      } catch (e) {
        print('DEBUG: Failed to sync user data: $e');
        WidgetsBinding.instance.addPostFrameCallback((_) {
          AppRouter.replace('/login');
        });
      }
      return;
    }
    
    // Valid session and matching local data
    print('DEBUG: Valid session found, role: ${localUser['role']}');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final role = localUser['role'];
      if (role == 'patient') {
        AppRouter.replace('/patient-dashboard');
      } else if (role == 'doctor') {
        AppRouter.replace('/doctor-dashboard');
      } else {
        AppRouter.replace('/login');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF00B4D8),
              Color(0xFF0077B6),
              Color(0xFF023E8A),
            ],
          ),
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 3,
              ),
              SizedBox(height: 16),
              Text(
                'MedVita',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class MedVitaApp extends StatefulWidget {
  const MedVitaApp({super.key});

  @override
  State<MedVitaApp> createState() => _MedVitaAppState();
}

class _MedVitaAppState extends State<MedVitaApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _setUserOnline();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _setUserOffline();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    switch (state) {
      case AppLifecycleState.resumed:
        _setUserOnline();
        break;
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
        _setUserOffline();
        break;
      case AppLifecycleState.hidden:
        _setUserOffline();
        break;
    }
  }

  void _setUserOnline() {
    final user = SupabaseService.currentUser;
    if (user != null) {
      _updatePatientStatus(user.id, true);
    }
  }

  void _setUserOffline() {
    final user = SupabaseService.currentUser;
    if (user != null) {
      _updatePatientStatus(user.id, false);
    }
  }

  void _updatePatientStatus(String userId, bool isOnline) async {
    try {
      final profile = await SupabaseService.getProfile(userId);
      if (profile != null && profile['role'] == 'patient') {
        SupabaseService.updateUserStatus(userId, isOnline);
      }
    } catch (e) {
      print('DEBUG: Failed to check user role for status update: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MedVita',
      debugShowCheckedModeBanner: false,
      navigatorKey: AppRouter.navigatorKey,
      onGenerateRoute: AppRouter.generateRoute,
      home: const AuthChecker(),
      theme: ThemeData(
        primarySwatch: Colors.blue,
        primaryColor: const Color(0xFF00B4D8),
        scaffoldBackgroundColor: const Color(0xFFF8FAFC),
        fontFamily: 'Inter',
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF00B4D8),
          primary: const Color(0xFF00B4D8),
          secondary: const Color(0xFF0077B6),
          tertiary: const Color(0xFF023E8A),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Color(0xFF1A1A1A),
          elevation: 0,
          centerTitle: false,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF00B4D8),
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: const Color(0xFF00B4D8),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF00B4D8), width: 2),
          ),
          filled: true,
          fillColor: const Color(0xFFF9FAFB),
        ),
        cardTheme: const CardThemeData(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(16)),
          ),
          color: Colors.white,
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Colors.white,
          selectedItemColor: Color(0xFF00B4D8),
          unselectedItemColor: Color(0xFF64748B),
          type: BottomNavigationBarType.fixed,
          elevation: 8,
        ),
      ),
    );
  }
}