import 'package:flutter/material.dart';
import '../services/ai_booking_service.dart';
import '../services/local_storage_service.dart';
import '../services/hms_consultation_service.dart';
import '../widgets/loading_overlay.dart';
import 'common/hms_video_call_screen.dart';

class BookAppointmentScreen extends StatefulWidget {
  const BookAppointmentScreen({super.key});

  @override
  State<BookAppointmentScreen> createState() => _BookAppointmentScreenState();
}

class _BookAppointmentScreenState extends State<BookAppointmentScreen> {
  final _symptomsController = TextEditingController();
  List<Map<String, dynamic>> _suggestedDoctors = [];
  Map<String, dynamic>? _aiSuggestion;
  bool _isLoading = false;
  String? _selectedDoctorId;

  void _getSuggestions() async {
    if (_symptomsController.text.trim().isEmpty) return;

    setState(() => _isLoading = true);

    try {
      // Get AI suggestion for specialization
      final suggestion = await AiBookingService.getSpecializationSuggestion(_symptomsController.text);
      
      // Find doctors with suggested specialization
      final doctors = await AiBookingService.findAvailableDoctors(suggestion['specialization']);
      
      setState(() {
        _aiSuggestion = suggestion;
        _suggestedDoctors = doctors;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _startVideoConsultation() async {
    if (_selectedDoctorId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a doctor')),
      );
      return;
    }

    final selectedDoctor = _suggestedDoctors.firstWhere(
      (doctor) => doctor['id'] == _selectedDoctorId,
    );

    // Check if doctor is online
    if (selectedDoctor['status'] != true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Doctor is currently offline')),
      );
      return;
    }

    try {
      setState(() => _isLoading = true);
      
      // Create video consultation session
      final consultation = await HMSConsultationService.createVideoConsultation(
        patientId: LocalStorageService.getCurrentUserId()!,
        doctorId: _selectedDoctorId!,
        symptoms: _symptomsController.text.trim(),
        isPatientInitiated: true, // Patient is calling doctor
      );

      if (consultation != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Starting video consultation with Dr. ${selectedDoctor['full_name']}')),
        );
        
        // Debug the consultation data
        print('DEBUG: Consultation data: $consultation');
        print('DEBUG: Patient token from consultation: ${consultation['patient_token']}');
        print('DEBUG: Doctor token from consultation: ${consultation['doctor_token']}');
        
        // Navigate to HMS video consultation screen
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => HMSVideoCallScreen(
              consultationId: consultation['id'],
              patientId: consultation['patient_id'],
              doctorId: consultation['doctor_id'],
              patientName: LocalStorageService.getCurrentUser()?['full_name'] ?? 'Patient',
              doctorName: selectedDoctor['full_name'] ?? 'Doctor',
            ),
          ),
        );
      } else {
        throw Exception('Failed to create consultation');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error starting consultation: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Widget _buildDoctorInfo(Map<String, dynamic> doctor) {
    final doctorData = doctor['doctors'];
    
    // Handle both List and Map structures
    Map<String, dynamic>? doctorInfo;
    if (doctorData is List && doctorData.isNotEmpty) {
      doctorInfo = doctorData[0];
    } else if (doctorData is Map<String, dynamic>) {
      doctorInfo = doctorData;
    }
    
    if (doctorInfo != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('${doctorInfo['specialization'] ?? 'General Medicine'} • ${doctorInfo['clinic_name'] ?? 'Clinic'}'),
          Text('Rating: ${doctorInfo['rating'] ?? 0}/5'),
          if (doctorInfo['qualifications'] != null)
            Text('Qualifications: ${doctorInfo['qualifications']}'),
        ],
      );
    }
    
    return const Text('Doctor information not available');
  }

  bool _getDoctorVerified(Map<String, dynamic> doctor) {
    final doctorData = doctor['doctors'];
    
    if (doctorData is List && doctorData.isNotEmpty) {
      return doctorData[0]['verified'] == true;
    } else if (doctorData is Map<String, dynamic>) {
      return doctorData['verified'] == true;
    }
    
    return false;
  }

  void _startChatWithDoctor() async {
    if (_selectedDoctorId == null) return;

    final selectedDoctor = _suggestedDoctors.firstWhere(
      (doctor) => doctor['id'] == _selectedDoctorId,
    );

    final user = LocalStorageService.getCurrentUser();
    if (user == null) return;

    final conversationId = '${user['id']}_$_selectedDoctorId';
    final doctorName = selectedDoctor['full_name'] ?? 'Doctor';

    Navigator.pushNamed(
      context,
      '/chat',
      arguments: {
        'conversationId': conversationId,
        'otherUserId': _selectedDoctorId,
        'otherUserName': doctorName,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final screenWidth = screenSize.width;
    final screenHeight = screenSize.height;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Video Consultation',
          style: TextStyle(
            color: const Color(0xFF1A1A1A),
            fontWeight: FontWeight.w600,
            fontSize: screenWidth * 0.045,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, 
            color: const Color(0xFF1A1A1A),
            size: screenWidth * 0.06,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: LoadingOverlay(
        isLoading: _isLoading,
        child: SingleChildScrollView(
        padding: EdgeInsets.all(screenWidth * 0.04),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
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
                  Text(
                    'Describe your symptoms:',
                    style: TextStyle(
                      fontSize: screenWidth * 0.04,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF1A1A1A),
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.015),
                  TextField(
                    controller: _symptomsController,
                    style: TextStyle(fontSize: screenWidth * 0.035),
                    decoration: InputDecoration(
                      hintText: 'e.g., headache, fever, chest pain...',
                      hintStyle: TextStyle(fontSize: screenWidth * 0.032),
                      border: const OutlineInputBorder(),
                    ),
                    maxLines: 3,
                  ),
                  SizedBox(height: screenHeight * 0.02),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _getSuggestions,
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: screenHeight * 0.015),
                      ),
                      child: Text(
                        'Find Online Doctors',
                        style: TextStyle(fontSize: screenWidth * 0.04),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (_aiSuggestion != null) ...[
              SizedBox(height: screenHeight * 0.025),
              Container(
                padding: EdgeInsets.all(screenWidth * 0.04),
                decoration: BoxDecoration(
                  color: const Color(0xFF00B4D8).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(screenWidth * 0.03),
                  border: Border.all(color: const Color(0xFF00B4D8).withValues(alpha: 0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'AI Recommendation:',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: screenWidth * 0.04,
                        color: const Color(0xFF00B4D8),
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.01),
                    Text(
                      'Specialization: ${_aiSuggestion!['specialization']}',
                      style: TextStyle(fontSize: screenWidth * 0.035),
                    ),
                    Text(
                      'Confidence: ${(_aiSuggestion!['confidence'] * 100).toInt()}%',
                      style: TextStyle(fontSize: screenWidth * 0.035),
                    ),
                  ],
                ),
              ),
            ],
            if (_suggestedDoctors.isNotEmpty) ...[
              SizedBox(height: screenHeight * 0.025),
              Text(
                'Online Doctors:',
                style: TextStyle(
                  fontSize: screenWidth * 0.045,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1A1A1A),
                ),
              ),
              SizedBox(height: screenHeight * 0.015),
              Container(
                height: screenHeight * 0.4,
                child: ListView.builder(
                  itemCount: _suggestedDoctors.length,
                  itemBuilder: (context, index) {
                    final doctor = _suggestedDoctors[index];
                    final isOnline = doctor['status'] == true;
                    return Container(
                      margin: EdgeInsets.only(bottom: screenHeight * 0.015),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(screenWidth * 0.03),
                        border: Border.all(
                          color: _selectedDoctorId == doctor['id'] 
                              ? const Color(0xFF00B4D8) 
                              : Colors.grey.shade200,
                          width: _selectedDoctorId == doctor['id'] ? 2 : 1,
                        ),
                      ),
                      child: RadioListTile<String>(
                        value: doctor['id'],
                        groupValue: _selectedDoctorId,
                        onChanged: isOnline ? (value) => setState(() => _selectedDoctorId = value) : null,
                        title: Text(
                          'Dr. ${doctor['full_name'] ?? 'Unknown'}',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: screenWidth * 0.04,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildDoctorInfo(doctor),
                            SizedBox(height: screenHeight * 0.005),
                            Row(
                              children: [
                                Icon(
                                  isOnline ? Icons.circle : Icons.circle_outlined,
                                  color: isOnline ? Colors.green : Colors.grey,
                                  size: screenWidth * 0.03,
                                ),
                                SizedBox(width: screenWidth * 0.01),
                                Text(
                                  isOnline ? 'Online • Available Now' : 'Offline',
                                  style: TextStyle(
                                    color: isOnline ? Colors.green : Colors.grey,
                                    fontSize: screenWidth * 0.032,
                                  ),
                                ),
                                SizedBox(width: screenWidth * 0.02),
                                if (_getDoctorVerified(doctor))
                                  Icon(
                                    Icons.verified,
                                    color: const Color(0xFF00B4D8),
                                    size: screenWidth * 0.04,
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              SizedBox(height: screenHeight * 0.02),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _selectedDoctorId != null ? _startChatWithDoctor : null,
                      icon: Icon(Icons.chat, size: screenWidth * 0.045),
                      label: Text(
                        'Chat with Doctor',
                        style: TextStyle(fontSize: screenWidth * 0.035),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00B4D8),
                        padding: EdgeInsets.symmetric(vertical: screenHeight * 0.015),
                      ),
                    ),
                  ),
                  SizedBox(width: screenWidth * 0.03),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _selectedDoctorId != null ? _startVideoConsultation : null,
                      icon: Icon(Icons.video_call, size: screenWidth * 0.045),
                      label: Text(
                        'Video Call',
                        style: TextStyle(fontSize: screenWidth * 0.035),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0077B6),
                        padding: EdgeInsets.symmetric(vertical: screenHeight * 0.015),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    ),
    );
  }
}