import 'package:flutter/material.dart';
import '../../services/supabase_service.dart';
import '../../services/local_storage_service.dart';
import '../../services/offline_sync_service.dart';
import '../../utils/app_router.dart';
import '../../widgets/loading_overlay.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final screenWidth = screenSize.width;
    final screenHeight = screenSize.height;

    return Scaffold(
      backgroundColor: Colors.white,
      body: LoadingOverlay(
        isLoading: _isLoading,
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.all(screenWidth * 0.05),
            child: Form(
              key: _formKey,
              child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: screenHeight * 0.08),
                Text(
                  'Welcome!',
                  style: TextStyle(
                    fontSize: screenWidth * 0.08,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1A1A1A),
                  ),
                ),
                SizedBox(height: screenHeight * 0.01),
                Text(
                  'Sign in to continue',
                  style: TextStyle(
                    fontSize: screenWidth * 0.04,
                    color: const Color(0xFF666666),
                  ),
                ),
                SizedBox(height: screenHeight * 0.05),
                TextFormField(
                  controller: _emailController,
                  style: TextStyle(fontSize: screenWidth * 0.04),
                  decoration: InputDecoration(
                    labelText: 'Email',
                    labelStyle: TextStyle(fontSize: screenWidth * 0.035),
                    border: const OutlineInputBorder(),
                    prefixIcon: Icon(
                      Icons.email_outlined,
                      size: screenWidth * 0.05,
                    ),
                    contentPadding: EdgeInsets.all(screenWidth * 0.04),
                  ),
                  validator: (value) {
                    if (value?.isEmpty ?? true) return 'Email is required';
                    if (!value!.contains('@')) return 'Invalid email';
                    return null;
                  },
                ),
                SizedBox(height: screenHeight * 0.02),
                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  style: TextStyle(fontSize: screenWidth * 0.04),
                  decoration: InputDecoration(
                    labelText: 'Password',
                    labelStyle: TextStyle(fontSize: screenWidth * 0.035),
                    border: const OutlineInputBorder(),
                    prefixIcon: Icon(
                      Icons.lock_outlined,
                      size: screenWidth * 0.05,
                    ),
                    contentPadding: EdgeInsets.all(screenWidth * 0.04),
                  ),
                  validator: (value) {
                    if (value?.isEmpty ?? true) return 'Password is required';
                    if (value!.length < 6) return 'Password must be at least 6 characters';
                    return null;
                  },
                ),
                SizedBox(height: screenHeight * 0.03),
                SizedBox(
                  width: double.infinity,
                  height: screenHeight * 0.06,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _signIn,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(screenWidth * 0.02),
                      ),
                    ),
                    child: Text(
                      'Sign In',
                      style: TextStyle(fontSize: screenWidth * 0.04),
                    ),
                  ),
                ),
                SizedBox(height: screenHeight * 0.02),
                Center(
                  child: TextButton(
                    onPressed: () => AppRouter.go('/register'),
                    child: Text(
                      'Don\'t have an account? Sign Up',
                      style: TextStyle(fontSize: screenWidth * 0.035),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
    );
  }

  Future<void> _signIn() async {
    if (!_formKey.currentState!.validate() || _isLoading) return;

    setState(() => _isLoading = true);

    try {
      final response = await SupabaseService.signIn(
        _emailController.text.trim(),
        _passwordController.text,
      );

      if (response.user != null && mounted) {
        print('DEBUG: Login successful, user: ${response.user!.id}');
        final profile = await SupabaseService.getProfile(response.user!.id);
        final role = profile?['role'] ?? 'patient';
        print('DEBUG: Profile retrieved: $profile');
        
        // Save complete profile data to local storage
        if (profile != null) {
          print('DEBUG: Saving complete profile: $profile');
          await LocalStorageService.saveCurrentUser(profile);
        } else {
          print('DEBUG: No profile found, user needs to complete registration');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Please complete your profile setup')),
            );
            AppRouter.replace('/register');
            return;
          }
        }
        
        // Trigger initial data sync
        OfflineSyncService().syncNow();
        
        if (mounted) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              AppRouter.replace(role == 'doctor' ? '/doctor-dashboard' : '/patient-dashboard');
            }
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Login failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}