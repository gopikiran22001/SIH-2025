import 'package:flutter/material.dart';
import '../../services/supabase_service.dart';
import '../../services/local_storage_service.dart';
import '../../services/offline_sync_service.dart';
import '../../services/pusher_beams_service.dart';
import '../../utils/app_router.dart';
import '../../widgets/loading_overlay.dart';
import 'medical_history_screen.dart';

class ProfileTab extends StatefulWidget {
  const ProfileTab({super.key});

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  Map<String, dynamic>? _profile;
  bool _isLoading = true;
  bool _isEditing = false;
  bool _isSaving = false;
  bool _isSigningOut = false;
  
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _bloodGroupController = TextEditingController();
  final _emergencyContactController = TextEditingController();
  String? _selectedGender;
  DateTime? _selectedDob;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    // First try to load from local storage
    final localProfile = LocalStorageService.getCurrentUser();
    print('DEBUG: Local profile loaded: $localProfile');
    
    if (localProfile != null && mounted) {
      setState(() {
        _profile = localProfile;
        _populateControllers();
        _isLoading = false;
      });
    }
    
    // Then try to update from server
    try {
      final user = SupabaseService.currentUser;
      if (user != null) {
        final profile = await SupabaseService.getProfile(user.id);
        if (profile != null) {
          print('DEBUG: Server profile loaded: $profile');
          await LocalStorageService.saveCurrentUser(profile);
          if (mounted) {
            setState(() {
              _profile = profile;
              _populateControllers();
            });
          }
        }
      }
    } catch (e) {
      print('DEBUG: Failed to load profile from server: $e');
      // If we don't have local profile either, show error
      if (localProfile == null && mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _populateControllers() {
    if (_profile != null) {
      print('DEBUG: Profile data: $_profile');
      _nameController.text = _profile!['full_name'] ?? '';
      _phoneController.text = _profile!['phone'] ?? '';
      _selectedGender = _profile!['gender'];
      if (_profile!['dob'] != null) {
        _selectedDob = DateTime.parse(_profile!['dob']);
      }
      
      // Get blood group from patients table
      final patientData = _profile!['patients'];
      print('DEBUG: Patient data: $patientData');
      if (patientData != null && patientData is Map) {
        final bloodGroup = patientData['blood_group'];
        final emergencyContact = patientData['emergency_contact'];
        
        print('DEBUG: Blood group from DB: $bloodGroup');
        print('DEBUG: Emergency contact from DB: $emergencyContact');
        
        _bloodGroupController.text = bloodGroup?.toString() ?? '';
        
        // Handle JSONB emergency contact format
        String emergencyContactText = '';
        if (emergencyContact != null) {
          if (emergencyContact is Map && emergencyContact['phone'] != null) {
            emergencyContactText = emergencyContact['phone'].toString();
          } else if (emergencyContact is String) {
            emergencyContactText = emergencyContact;
          }
        }
        _emergencyContactController.text = emergencyContactText;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final screenWidth = screenSize.width;

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return LoadingOverlay(
      isLoading: _isSaving || _isSigningOut,
      child: SingleChildScrollView(
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
            backgroundImage: const AssetImage('assets/icons/WhatsApp Image 2025-09-13 at 16.03.16_104a23fc.png'),
          ),
          SizedBox(height: screenWidth * 0.03),
          Text(
            _profile?['full_name'] ?? 'User',
            style: TextStyle(
              fontSize: screenWidth * 0.05,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1A1A1A),
            ),
          ),
          Text(
            _profile?['role']?.toString().toUpperCase() ?? 'PATIENT',
            style: TextStyle(
              fontSize: screenWidth * 0.03,
              color: const Color(0xFF64748B),
              fontWeight: FontWeight.w500,
            ),
          ),
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
                'Personal Information',
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
          if (_isEditing) ...[
            _buildEditableField('Full Name', _nameController),
            SizedBox(height: screenWidth * 0.03),
            _buildEditableField('Phone', _phoneController),
            SizedBox(height: screenWidth * 0.03),
            _buildEditableField('Blood Group', _bloodGroupController),
            SizedBox(height: screenWidth * 0.03),
            _buildEditableField('Emergency Contact', _emergencyContactController),
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
          ] else ...[
            _buildInfoRow('Email', SupabaseService.currentUser?.email ?? 'Not available'),
            _buildInfoRow('Phone', _profile?['phone'] ?? 'Not provided'),
            _buildInfoRow('Gender', _profile?['gender'] ?? 'Not specified'),
            _buildInfoRow('Date of Birth', _selectedDob != null 
                ? '${_selectedDob!.day}/${_selectedDob!.month}/${_selectedDob!.year}'
                : 'Not provided'),
            _buildInfoRow('Blood Group', _getPatientBloodGroup()),
            _buildInfoRow('Emergency Contact', _getPatientEmergencyContact()),
            _buildInfoRow('Member Since', _profile?['created_at'] != null
                ? DateTime.parse(_profile!['created_at']).year.toString()
                : 'Unknown'),
          ],
        ],
      ),
    );
  }

  Widget _buildEditableField(String label, TextEditingController controller) {
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
              initialDate: _selectedDob ?? DateTime.now().subtract(const Duration(days: 365 * 25)),
              firstDate: DateTime(1900),
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
          'Medical History',
          Icons.history,
          () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const MedicalHistoryScreen(),
            ),
          ),
        ),
        SizedBox(height: screenWidth * 0.03),
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

  Future<void> _saveProfile() async {
    setState(() => _isSaving = true);
    
    try {
      final user = SupabaseService.currentUser;
      if (user != null) {
        final updatedProfile = {
          'full_name': _nameController.text,
          'phone': _phoneController.text,
          'gender': _selectedGender,
          'dob': _selectedDob?.toIso8601String().split('T')[0],
        };
        
        // Add blood group and emergency contact for patients table
        if (_bloodGroupController.text.isNotEmpty) {
          updatedProfile['blood_group'] = _bloodGroupController.text;
          print('DEBUG: Saving blood group: ${_bloodGroupController.text}');
        }
        if (_emergencyContactController.text.isNotEmpty) {
          // Store emergency contact as JSONB format
          updatedProfile['emergency_contact'] = _emergencyContactController.text;
          print('DEBUG: Saving emergency contact: ${_emergencyContactController.text}');
        }
        
        print('DEBUG: Updated profile data: $updatedProfile');
        
        final syncService = OfflineSyncService();
        
        print('DEBUG: Saving patient profile - isOnline: ${syncService.isOnline}');
        print('DEBUG: Profile data to save: $updatedProfile');
        
        if (syncService.isOnline) {
          print('DEBUG: Device online - updating profile directly to database');
          await SupabaseService.updateProfile(user.id, updatedProfile);
          print('DEBUG: Profile updated successfully in database');
        } else {
          print('DEBUG: Device offline - queueing profile update for later sync');
          await syncService.queueProfileUpdate(user.id, updatedProfile);
          print('DEBUG: Profile update queued for offline sync');
        }
        
        // Update local profile with new data
        final newProfile = Map<String, dynamic>.from(_profile!);
        newProfile.addAll(updatedProfile);
        
        // Update patients data if blood group or emergency contact changed
        if (_bloodGroupController.text.isNotEmpty || _emergencyContactController.text.isNotEmpty) {
          print('DEBUG: Updating local profile with patient data');
          if (newProfile['patients'] == null) {
            newProfile['patients'] = {};
          }
          if (newProfile['patients'] is List && newProfile['patients'].isNotEmpty) {
            if (_bloodGroupController.text.isNotEmpty) {
              newProfile['patients'][0]['blood_group'] = _bloodGroupController.text;
            }
            if (_emergencyContactController.text.isNotEmpty) {
              newProfile['patients'][0]['emergency_contact'] = _emergencyContactController.text;
            }
          } else if (newProfile['patients'] is Map) {
            if (_bloodGroupController.text.isNotEmpty) {
              newProfile['patients']['blood_group'] = _bloodGroupController.text;
            }
            if (_emergencyContactController.text.isNotEmpty) {
              newProfile['patients']['emergency_contact'] = _emergencyContactController.text;
            }
          }
          print('DEBUG: Updated patients data: ${newProfile['patients']}');
        }
        
        await LocalStorageService.saveCurrentUser(newProfile);
        
        setState(() {
          _profile = newProfile;
          _isEditing = false;
        });
        
        if (mounted) {
          final message = syncService.isOnline 
              ? 'Profile updated successfully' 
              : 'Profile saved offline. Will sync when connected.';
          print('DEBUG: Showing user message: $message');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(message)),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update profile: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _signOut() async {
    setState(() => _isSigningOut = true);
    
    try {
      // Set patient offline before signing out (doctors control their own status)
      final user = SupabaseService.currentUser;
      if (user != null) {
        // Clear Pusher Beams user session
        await PusherBeamsService.onUserLogout(user.id);
        
        if (_profile?['role'] == 'patient') {
          await SupabaseService.setUserOffline(user.id);
        }
      }
      
      await SupabaseService.signOutAndClearStack();
      await LocalStorageService.logout();
      if (mounted) {
        AppRouter.clearStackAndGoToLogin();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Sign out failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSigningOut = false);
    }
  }

  String _getPatientBloodGroup() {
    final patientData = _profile?['patients'];
    if (patientData != null && patientData is Map) {
      final bloodGroup = patientData['blood_group'];
      if (bloodGroup != null && bloodGroup.toString().isNotEmpty) {
        return bloodGroup.toString();
      }
    }
    return _bloodGroupController.text.isNotEmpty ? _bloodGroupController.text : 'Not provided';
  }

  String _getPatientEmergencyContact() {
    final patientData = _profile?['patients'];
    if (patientData != null && patientData is Map) {
      final emergencyContact = patientData['emergency_contact'];
      if (emergencyContact != null) {
        // Handle JSONB format {phone: "number"} or direct string
        if (emergencyContact is Map && emergencyContact['phone'] != null) {
          return emergencyContact['phone'].toString();
        } else if (emergencyContact is String && emergencyContact.isNotEmpty) {
          return emergencyContact;
        }
      }
    }
    return _emergencyContactController.text.isNotEmpty ? _emergencyContactController.text : 'Not provided';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _bloodGroupController.dispose();
    _emergencyContactController.dispose();
    super.dispose();
  }
}