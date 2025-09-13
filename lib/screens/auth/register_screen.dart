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
  bool _obscurePassword = true;

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final screenWidth = screenSize.width;
    final screenHeight = screenSize.height;

    return Scaffold(
      body: LoadingOverlay(
        isLoading: _isLoading,
        child: Container(
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
          child: SafeArea(
            child: SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: screenHeight - MediaQuery.of(context).padding.top - MediaQuery.of(context).padding.bottom,
                ),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.06),
                  child: Column(
                  children: [
                    SizedBox(height: screenHeight * 0.04),
                    // Back Button
                    Row(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(screenWidth * 0.03),
                          ),
                          child: IconButton(
                            icon: Icon(
                              Icons.arrow_back,
                              color: Colors.white,
                              size: screenWidth * 0.06,
                            ),
                            onPressed: () => AppRouter.go('/login'),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: screenHeight * 0.02),
                    // Logo/Icon Section
                    Container(
                      width: screenWidth * 0.2,
                      height: screenWidth * 0.2,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(screenWidth * 0.05),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.3),
                          width: 2,
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(screenWidth * 0.03),
                        child: Image.asset(
                          'assets/icons/WhatsApp Image 2025-09-13 at 16.03.16_104a23fc.jpg',
                          width: screenWidth * 0.14,
                          height: screenWidth * 0.14,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Icon(
                              Icons.health_and_safety_rounded,
                              size: screenWidth * 0.1,
                              color: Colors.white,
                            );
                          },
                        ),
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.02),
                    Text(
                      'Join MedVita',
                      style: TextStyle(
                        fontSize: screenWidth * 0.07,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 1.2,
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.01),
                    Text(
                      'Create your healthcare account',
                      style: TextStyle(
                        fontSize: screenWidth * 0.038,
                        color: Colors.white.withOpacity(0.9),
                        fontWeight: FontWeight.w300,
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.04),
                    // Register Form Card
                    Container(
                      padding: EdgeInsets.all(screenWidth * 0.06),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(screenWidth * 0.06),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Create Account',
                              style: TextStyle(
                                fontSize: screenWidth * 0.06,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF1A1A1A),
                              ),
                            ),
                            SizedBox(height: screenHeight * 0.01),
                            Text(
                              'Fill in your details to get started',
                              style: TextStyle(
                                fontSize: screenWidth * 0.036,
                                color: const Color(0xFF6B7280),
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                            SizedBox(height: screenHeight * 0.03),
                            _buildTextField(
                              controller: _fullNameController,
                              label: 'Full Name',
                              icon: Icons.person_outlined,
                              validator: (value) {
                                if (value?.isEmpty ?? true) return 'Full name is required';
                                return null;
                              },
                            ),
                            SizedBox(height: screenHeight * 0.02),
                            _buildTextField(
                              controller: _emailController,
                              label: 'Email Address',
                              icon: Icons.email_outlined,
                              keyboardType: TextInputType.emailAddress,
                              validator: (value) {
                                if (value?.isEmpty ?? true) return 'Email is required';
                                if (!value!.contains('@')) return 'Enter a valid email';
                                return null;
                              },
                            ),
                            SizedBox(height: screenHeight * 0.02),
                            _buildTextField(
                              controller: _phoneController,
                              label: 'Phone Number',
                              icon: Icons.phone_outlined,
                              keyboardType: TextInputType.phone,
                              validator: (value) {
                                if (value?.isEmpty ?? true) return 'Phone number is required';
                                return null;
                              },
                            ),
                            SizedBox(height: screenHeight * 0.02),
                            _buildRoleDropdown(),
                            SizedBox(height: screenHeight * 0.02),
                            _buildTextField(
                              controller: _passwordController,
                              label: 'Password',
                              icon: Icons.lock_outlined,
                              obscureText: _obscurePassword,
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword ? Icons.visibility_off : Icons.visibility,
                                  color: const Color(0xFF6B7280),
                                ),
                                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                              ),
                              validator: (value) {
                                if (value?.isEmpty ?? true) return 'Password is required';
                                if (value!.length < 6) return 'Password must be at least 6 characters';
                                return null;
                              },
                            ),
                            SizedBox(height: screenHeight * 0.035),
                            Container(
                              width: double.infinity,
                              height: screenHeight * 0.065,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFF00B4D8), Color(0xFF0077B6)],
                                ),
                                borderRadius: BorderRadius.circular(screenWidth * 0.03),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF00B4D8).withOpacity(0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: ElevatedButton(
                                onPressed: _isLoading ? null : _signUp,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  shadowColor: Colors.transparent,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(screenWidth * 0.03),
                                  ),
                                ),
                                child: _isLoading
                                    ? SizedBox(
                                        width: screenWidth * 0.05,
                                        height: screenWidth * 0.05,
                                        child: const CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : Text(
                                        'Create Account',
                                        style: TextStyle(
                                          fontSize: screenWidth * 0.045,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white,
                                        ),
                                      ),
                              ),
                            ),
                            SizedBox(height: screenHeight * 0.025),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Already have an account? ',
                                  style: TextStyle(
                                    fontSize: screenWidth * 0.036,
                                    color: const Color(0xFF6B7280),
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () => AppRouter.go('/login'),
                                  child: Text(
                                    'Sign In',
                                    style: TextStyle(
                                      fontSize: screenWidth * 0.036,
                                      color: const Color(0xFF00B4D8),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.03),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool obscureText = false,
    Widget? suffixIcon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;
    
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      style: TextStyle(
        fontSize: screenWidth * 0.04,
        color: const Color(0xFF1A1A1A),
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          fontSize: screenWidth * 0.036,
          color: const Color(0xFF6B7280),
        ),
        prefixIcon: Icon(
          icon,
          color: const Color(0xFF6B7280),
          size: screenWidth * 0.055,
        ),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: const Color(0xFFF9FAFB),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(screenWidth * 0.03),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(screenWidth * 0.03),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(screenWidth * 0.03),
          borderSide: const BorderSide(color: Color(0xFF00B4D8), width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(screenWidth * 0.03),
          borderSide: const BorderSide(color: Color(0xFFEF4444)),
        ),
        contentPadding: EdgeInsets.symmetric(
          horizontal: screenWidth * 0.04,
          vertical: screenWidth * 0.04,
        ),
      ),
      validator: validator,
    );
  }

  Widget _buildRoleDropdown() {
    final screenWidth = MediaQuery.of(context).size.width;
    
    return DropdownButtonFormField<String>(
      value: _selectedRole,
      style: TextStyle(
        fontSize: screenWidth * 0.04,
        color: const Color(0xFF1A1A1A),
      ),
      decoration: InputDecoration(
        labelText: 'Account Type',
        labelStyle: TextStyle(
          fontSize: screenWidth * 0.036,
          color: const Color(0xFF6B7280),
        ),
        prefixIcon: Icon(
          Icons.work_outlined,
          color: const Color(0xFF6B7280),
          size: screenWidth * 0.055,
        ),
        filled: true,
        fillColor: const Color(0xFFF9FAFB),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(screenWidth * 0.03),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(screenWidth * 0.03),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(screenWidth * 0.03),
          borderSide: const BorderSide(color: Color(0xFF00B4D8), width: 2),
        ),
        contentPadding: EdgeInsets.symmetric(
          horizontal: screenWidth * 0.04,
          vertical: screenWidth * 0.04,
        ),
      ),
      items: [
        DropdownMenuItem(
          value: 'patient',
          child: Row(
            children: [
              Icon(
                Icons.person,
                size: screenWidth * 0.045,
                color: const Color(0xFF6B7280),
              ),
              SizedBox(width: screenWidth * 0.02),
              const Text('Patient'),
            ],
          ),
        ),
        DropdownMenuItem(
          value: 'doctor',
          child: Row(
            children: [
              Icon(
                Icons.medical_services,
                size: screenWidth * 0.045,
                color: const Color(0xFF6B7280),
              ),
              SizedBox(width: screenWidth * 0.02),
              const Text('Doctor'),
            ],
          ),
        ),
      ],
      onChanged: (value) => setState(() => _selectedRole = value!),
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