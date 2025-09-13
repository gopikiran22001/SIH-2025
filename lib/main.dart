import 'package:flutter/material.dart';
import 'services/supabase_service.dart';
import 'services/local_storage_service.dart';
import 'services/offline_sync_service.dart';
import 'utils/app_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize services
  await LocalStorageService.initialize();
  await SupabaseService.initialize();
  
  // Initialize and sync offline service
  final syncService = OfflineSyncService();
  await syncService.init();
  
  runApp(const MeditechApp());
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
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}

class MeditechApp extends StatelessWidget {
  const MeditechApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Meditech',
      debugShowCheckedModeBanner: false,
      navigatorKey: AppRouter.navigatorKey,
      onGenerateRoute: AppRouter.generateRoute,
      home: const AuthChecker(),
      theme: ThemeData(
        primarySwatch: Colors.blue,
        primaryColor: const Color(0xFF2563EB),
        scaffoldBackgroundColor: const Color(0xFFF8FAFC),
        fontFamily: 'Inter',
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Color(0xFF1A1A1A),
          elevation: 0,
          centerTitle: false,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF2563EB),
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFF2563EB)),
          ),
          filled: true,
          fillColor: Colors.white,
        ),
        cardTheme: const CardThemeData(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
          ),
          color: Colors.white,
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Colors.white,
          selectedItemColor: Color(0xFF2563EB),
          unselectedItemColor: Color(0xFF64748B),
          type: BottomNavigationBarType.fixed,
          elevation: 8,
        ),
      ),
    );
  }
}