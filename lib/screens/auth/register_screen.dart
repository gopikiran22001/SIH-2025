import 'package:flutter/material.dart';
import '../../services/supabase_service.dart';
import '../../utils/app_router.dart';
import '../../widgets/loading_overlay.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  String _selectedRole = 'patient';
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final screenWidth = screenSize.width;
    final screenHeight = screenSize.height;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: Colors.black,
            size: screenWidth * 0.06,
          ),
          onPressed: () => AppRouter.go('/login'),
        ),
      ),
      body: LoadingOverlay(
        isLoading: _isLoading,
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.all(screenWidth * 0.05),
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Create Account',
                    style: TextStyle(
                      fontSize: screenWidth * 0.08,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1A1A1A),
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.01),
                  Text(
                    'Join Meditech today',
                    style: TextStyle(
                      fontSize: screenWidth * 0.04,
                      color: const Color(0xFF666666),
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.04),
                  TextFormField(
                    controller: _fullNameController,
                    style: TextStyle(fontSize: screenWidth * 0.04),
                    decoration: InputDecoration(
                      labelText: 'Full Name',
                      labelStyle: TextStyle(fontSize: screenWidth * 0.035),
                      border: const OutlineInputBorder(),
                      prefixIcon: Icon(
                        Icons.person_outlined,
                        size: screenWidth * 0.05,
                      ),
                      contentPadding: EdgeInsets.all(screenWidth * 0.04),
                    ),
                    validator: (value) {
                      if (value?.isEmpty ?? true) return 'Full name is required';
                      return null;
                    },
                  ),
                  SizedBox(height: screenHeight * 0.02),
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
                    controller: _phoneController,
                    style: TextStyle(fontSize: screenWidth * 0.04),
                    decoration: InputDecoration(
                      labelText: 'Phone Number',
                      labelStyle: TextStyle(fontSize: screenWidth * 0.035),
                      border: const OutlineInputBorder(),
                      prefixIcon: Icon(
                        Icons.phone_outlined,
                        size: screenWidth * 0.05,
                      ),
                      contentPadding: EdgeInsets.all(screenWidth * 0.04),
                    ),
                    validator: (value) {
                      if (value?.isEmpty ?? true) return 'Phone number is required';
                      return null;
                    },
                  ),
                  SizedBox(height: screenHeight * 0.02),
                  DropdownButtonFormField<String>(
                    value: _selectedRole,
                    style: TextStyle(
                      fontSize: screenWidth * 0.04,
                      color: Colors.black,
                    ),
                    decoration: InputDecoration(
                      labelText: 'Role',
                      labelStyle: TextStyle(fontSize: screenWidth * 0.035),
                      border: const OutlineInputBorder(),
                      prefixIcon: Icon(
                        Icons.work_outlined,
                        size: screenWidth * 0.05,
                      ),
                      contentPadding: EdgeInsets.all(screenWidth * 0.04),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'patient', child: Text('Patient')),
                      DropdownMenuItem(value: 'doctor', child: Text('Doctor')),
                    ],
                    onChanged: (value) => setState(() => _selectedRole = value!),
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
                      onPressed: _isLoading ? null : _signUp,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2563EB),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(screenWidth * 0.02),
                        ),
                      ),
                      child: Text(
                        'Create Account',
                        style: TextStyle(fontSize: screenWidth * 0.04),
                      ),
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.02),
                  Center(
                    child: TextButton(
                      onPressed: () => AppRouter.go('/login'),
                      child: Text(
                        'Already have an account? Sign In',
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
      ),
    );
  }

  Future<void> _signUp() async {
    if (!_formKey.currentState!.validate() || _isLoading) return;

    setState(() => _isLoading = true);

    try {
      final response = await SupabaseService.signUp(
        _emailController.text.trim(),
        _passwordController.text,
        {
          'full_name': _fullNameController.text.trim(),
          'phone': _phoneController.text.trim(),
          'role': _selectedRole,
        },
      );

      if (response.user != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Account created successfully! Please check your email.')),
        );
        if (mounted) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              AppRouter.go('/login');
            }
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Registration failed: $e')),
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
    _fullNameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }
}