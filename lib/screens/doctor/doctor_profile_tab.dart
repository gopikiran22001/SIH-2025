import 'package:flutter/material.dart';
import '../../services/supabase_service.dart';
import '../../services/local_storage_service.dart';
import '../../utils/app_router.dart';

class DoctorProfileTab extends StatefulWidget {
  const DoctorProfileTab({super.key});

  @override
  State<DoctorProfileTab> createState() => _DoctorProfileTabState();
}

class _DoctorProfileTabState extends State<DoctorProfileTab> {
  Map<String, dynamic>? _profile;
  bool _isLoading = true;
  bool _isEditing = false;
  
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _specializationController = TextEditingController();
  final _clinicController = TextEditingController();
  final _qualificationsController = TextEditingController();
  String? _selectedGender;
  DateTime? _selectedDob;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final user = SupabaseService.currentUser;
      if (user != null) {
        final profile = await SupabaseService.getProfile(user.id);
        if (mounted) {
          setState(() {
            _profile = profile;
            _populateControllers();
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _populateControllers() {
    if (_profile != null) {
      _nameController.text = _profile!['full_name'] ?? '';
      _phoneController.text = _profile!['phone'] ?? '';
      _selectedGender = _profile!['gender'];
      if (_profile!['dob'] != null) {
        _selectedDob = DateTime.parse(_profile!['dob']);
      }
      
      // Doctor specific fields
      final doctorData = _profile!['doctors'];
      print('DEBUG: Doctor data in _populateControllers: $doctorData');
      if (doctorData != null && doctorData is Map) {
        _specializationController.text = doctorData['specialization']?.toString() ?? '';
        _clinicController.text = doctorData['clinic_name']?.toString() ?? '';
        _qualificationsController.text = doctorData['qualifications']?.toString() ?? '';
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: EdgeInsets.all(screenWidth * 0.04),
      child: Column(
        children: [
          _buildProfileHeader(),
          SizedBox(height: screenWidth * 0.06),
          _buildProfileInfo(),
          SizedBox(height: screenWidth * 0.06),
          _buildActionButtons(),
        ],
      ),
    );
  }

  Widget _buildProfileHeader() {
    final screenWidth = MediaQuery.of(context).size.width;
    
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(screenWidth * 0.05),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(screenWidth * 0.03),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: screenWidth * 0.025,
            offset: Offset(0, screenWidth * 0.005),
          ),
        ],
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: screenWidth * 0.12,
            backgroundColor: const Color(0xFF00B4D8),
            backgroundImage: const AssetImage('assets/icons/WhatsApp Image 2025-09-13 at 16.03.16_104a23fc.jpg'),
            onBackgroundImageError: (exception, stackTrace) {},
            child: const SizedBox(),
          ),
          SizedBox(height: screenWidth * 0.03),
          Text(
            'Dr. ${_profile?['full_name'] ?? 'Doctor'}',
            style: TextStyle(
              fontSize: screenWidth * 0.05,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1A1A1A),
            ),
          ),
          Text(
            _getDoctorSpecialization(),
            style: TextStyle(
              fontSize: screenWidth * 0.03,
              color: const Color(0xFF64748B),
              fontWeight: FontWeight.w500,
            ),
          ),
          if (_getDoctorRating() > 0) ...[
            SizedBox(height: screenWidth * 0.02),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.star,
                  color: Colors.amber,
                  size: screenWidth * 0.04,
                ),
                SizedBox(width: screenWidth * 0.01),
                Text(
                  _getDoctorRating().toStringAsFixed(1),
                  style: TextStyle(
                    fontSize: screenWidth * 0.035,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildProfileInfo() {
    final screenWidth = MediaQuery.of(context).size.width;
    
    return Container(
      padding: EdgeInsets.all(screenWidth * 0.05),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(screenWidth * 0.03),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: screenWidth * 0.025,
            offset: Offset(0, screenWidth * 0.005),
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
                'Professional Information',
                style: TextStyle(
                  fontSize: screenWidth * 0.045,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1A1A1A),
                ),
              ),
              IconButton(
                onPressed: () => setState(() => _isEditing = !_isEditing),
                icon: Icon(
                  _isEditing ? Icons.close : Icons.edit,
                  size: screenWidth * 0.05,
                  color: const Color(0xFF00B4D8),
                ),
              ),
            ],
          ),
          SizedBox(height: screenWidth * 0.04),
          if (_isEditing) ...{
            _buildEditableField('Full Name', _nameController),
            SizedBox(height: screenWidth * 0.03),
            _buildEditableField('Phone', _phoneController),
            SizedBox(height: screenWidth * 0.03),
            _buildEditableField('Specialization', _specializationController),
            SizedBox(height: screenWidth * 0.03),
            _buildEditableField('Clinic Name', _clinicController),
            SizedBox(height: screenWidth * 0.03),
            _buildEditableField('Qualifications', _qualificationsController, maxLines: 3),
            SizedBox(height: screenWidth * 0.03),
            _buildGenderDropdown(),
            SizedBox(height: screenWidth * 0.03),
            _buildDatePicker(),
            SizedBox(height: screenWidth * 0.04),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      setState(() => _isEditing = false);
                      _populateControllers();
                    },
                    child: Text(
                      'Cancel',
                      style: TextStyle(fontSize: screenWidth * 0.035),
                    ),
                  ),
                ),
                SizedBox(width: screenWidth * 0.03),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _saveProfile,
                    child: Text(
                      'Save',
                      style: TextStyle(fontSize: screenWidth * 0.035),
                    ),
                  ),
                ),
              ],
            ),
          } else ...{
            _buildInfoRow('Email', SupabaseService.currentUser?.email ?? 'Not available'),
            _buildInfoRow('Phone', _profile?['phone'] ?? 'Not provided'),
            _buildInfoRow('Specialization', _getDoctorSpecialization()),
            _buildInfoRow('Clinic', _getDoctorClinic()),
            _buildInfoRow('Qualifications', _getDoctorQualifications()),
            _buildInfoRow('Gender', _profile?['gender'] ?? 'Not specified'),
            _buildInfoRow('Date of Birth', _selectedDob != null 
                ? '${_selectedDob!.day}/${_selectedDob!.month}/${_selectedDob!.year}'
                : 'Not provided'),
            _buildInfoRow('Verified', _getDoctorVerified() ? 'Yes' : 'Pending'),
            _buildInfoRow('Member Since', _profile?['created_at'] != null
                ? DateTime.parse(_profile!['created_at']).year.toString()
                : 'Unknown'),
          },
        ],
      ),
    );
  }

  Widget _buildEditableField(String label, TextEditingController controller, {int maxLines = 1}) {
    final screenWidth = MediaQuery.of(context).size.width;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: screenWidth * 0.035,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF374151),
          ),
        ),
        SizedBox(height: screenWidth * 0.01),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          style: TextStyle(fontSize: screenWidth * 0.035),
          decoration: InputDecoration(
            border: const OutlineInputBorder(),
            contentPadding: EdgeInsets.all(screenWidth * 0.03),
          ),
        ),
      ],
    );
  }

  Widget _buildGenderDropdown() {
    final screenWidth = MediaQuery.of(context).size.width;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Gender',
          style: TextStyle(
            fontSize: screenWidth * 0.035,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF374151),
          ),
        ),
        SizedBox(height: screenWidth * 0.01),
        DropdownButtonFormField<String>(
          value: _selectedGender,
          style: TextStyle(fontSize: screenWidth * 0.035, color: Colors.black),
          decoration: InputDecoration(
            border: const OutlineInputBorder(),
            contentPadding: EdgeInsets.all(screenWidth * 0.03),
          ),
          items: const [
            DropdownMenuItem(value: 'male', child: Text('Male')),
            DropdownMenuItem(value: 'female', child: Text('Female')),
            DropdownMenuItem(value: 'other', child: Text('Other')),
          ],
          onChanged: (value) => setState(() => _selectedGender = value),
        ),
      ],
    );
  }

  Widget _buildDatePicker() {
    final screenWidth = MediaQuery.of(context).size.width;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Date of Birth',
          style: TextStyle(
            fontSize: screenWidth * 0.035,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF374151),
          ),
        ),
        SizedBox(height: screenWidth * 0.01),
        InkWell(
          onTap: () async {
            final date = await showDatePicker(
              context: context,
              initialDate: _selectedDob ?? DateTime.now().subtract(const Duration(days: 365 * 30)),
              firstDate: DateTime(1950),
              lastDate: DateTime.now(),
            );
            if (date != null) {
              setState(() => _selectedDob = date);
            }
          },
          child: Container(
            padding: EdgeInsets.all(screenWidth * 0.03),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[400]!),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _selectedDob != null
                      ? '${_selectedDob!.day}/${_selectedDob!.month}/${_selectedDob!.year}'
                      : 'Select date',
                  style: TextStyle(fontSize: screenWidth * 0.035),
                ),
                Icon(Icons.calendar_today, size: screenWidth * 0.04),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    final screenWidth = MediaQuery.of(context).size.width;
    
    return Padding(
      padding: EdgeInsets.only(bottom: screenWidth * 0.03),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: screenWidth * 0.25,
            child: Text(
              label,
              style: TextStyle(
                fontSize: screenWidth * 0.035,
                color: const Color(0xFF64748B),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: screenWidth * 0.035,
                color: const Color(0xFF1A1A1A),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    final screenWidth = MediaQuery.of(context).size.width;
    
    return Column(
      children: [

        _buildActionButton(
          'Settings',
          Icons.settings,
          () => ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Settings feature coming soon')),
          ),
        ),
        SizedBox(height: screenWidth * 0.06),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _signOut,
            icon: Icon(Icons.logout, size: screenWidth * 0.04),
            label: Text(
              'Sign Out',
              style: TextStyle(fontSize: screenWidth * 0.04),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFFDC2626),
              side: const BorderSide(color: Color(0xFFDC2626)),
              padding: EdgeInsets.symmetric(vertical: screenWidth * 0.03),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton(String title, IconData icon, VoidCallback onTap) {
    final screenWidth = MediaQuery.of(context).size.width;
    
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(screenWidth * 0.03),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: screenWidth * 0.025,
            offset: Offset(0, screenWidth * 0.005),
          ),
        ],
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: const Color(0xFF00B4D8),
          size: screenWidth * 0.05,
        ),
        title: Text(
          title,
          style: TextStyle(
            fontSize: screenWidth * 0.04,
            fontWeight: FontWeight.w500,
          ),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          size: screenWidth * 0.04,
          color: const Color(0xFF64748B),
        ),
        onTap: onTap,
      ),
    );
  }

  Map<String, dynamic>? _getDoctorInfo() {
    final doctorData = _profile?['doctors'];
    print('DEBUG: Doctor data in _getDoctorInfo: $doctorData');
    if (doctorData != null && doctorData is Map<String, dynamic>) {
      return doctorData;
    }
    return null;
  }

  String _getDoctorSpecialization() {
    final doctorInfo = _getDoctorInfo();
    return doctorInfo?['specialization'] ?? 'General Medicine';
  }

  String _getDoctorClinic() {
    final doctorInfo = _getDoctorInfo();
    return doctorInfo?['clinic_name'] ?? 'Not provided';
  }

  String _getDoctorQualifications() {
    final doctorInfo = _getDoctorInfo();
    return doctorInfo?['qualifications'] ?? 'Not provided';
  }

  bool _getDoctorVerified() {
    final doctorInfo = _getDoctorInfo();
    return doctorInfo?['verified'] ?? false;
  }

  double _getDoctorRating() {
    final doctorInfo = _getDoctorInfo();
    return (doctorInfo?['rating'] ?? 0.0).toDouble();
  }

  Future<void> _saveProfile() async {
    try {
      final user = SupabaseService.currentUser;
      if (user != null) {
        final updatedProfile = {
          'full_name': _nameController.text,
          'phone': _phoneController.text,
          'gender': _selectedGender,
          'dob': _selectedDob?.toIso8601String().split('T')[0],
          'specialization': _specializationController.text,
          'clinic_name': _clinicController.text,
          'qualifications': _qualificationsController.text,
        };
        
        await SupabaseService.updateProfile(user.id, updatedProfile);
        
        setState(() => _isEditing = false);
        _loadProfile();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profile updated successfully')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update profile: $e')),
        );
      }
    }
  }

  Future<void> _signOut() async {
    try {
      // Doctors control their own status, don't auto-set offline
      await SupabaseService.signOut();
      await LocalStorageService.logout();
      if (mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            AppRouter.replace('/login');
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Sign out failed: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _specializationController.dispose();
    _clinicController.dispose();
    _qualificationsController.dispose();
    super.dispose();
  }
}