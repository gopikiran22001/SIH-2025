import 'package:flutter/material.dart';
import '../services/ai_booking_service.dart';
import '../services/local_storage_service.dart';
import '../services/hms_consultation_service.dart';
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
              roomId: consultation['channel_name'],
              authToken: consultation['patient_token'],
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Video Consultation')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Describe your symptoms:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(
              controller: _symptomsController,
              decoration: const InputDecoration(
                hintText: 'e.g., headache, fever, chest pain...',
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _getSuggestions,
                child: _isLoading 
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Find Online Doctors'),
              ),
            ),
            if (_aiSuggestion != null) ...[
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF00B4D8).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('AI Recommendation:', style: TextStyle(fontWeight: FontWeight.bold)),
                    Text('Specialization: ${_aiSuggestion!['specialization']}'),
                    Text('Confidence: ${(_aiSuggestion!['confidence'] * 100).toInt()}%'),
                  ],
                ),
              ),
            ],
            if (_suggestedDoctors.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text('Online Doctors:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Expanded(
                child: ListView.builder(
                  itemCount: _suggestedDoctors.length,
                  itemBuilder: (context, index) {
                    final doctor = _suggestedDoctors[index];
                    final isOnline = doctor['status'] == true;
                    return Card(
                      child: RadioListTile<String>(
                        value: doctor['id'],
                        groupValue: _selectedDoctorId,
                        onChanged: isOnline ? (value) => setState(() => _selectedDoctorId = value) : null,
                        title: Text('Dr. ${doctor['full_name'] ?? 'Unknown'}'),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildDoctorInfo(doctor),
                            Row(
                              children: [
                                Icon(
                                  isOnline ? Icons.circle : Icons.circle_outlined,
                                  color: isOnline ? Colors.green : Colors.grey,
                                  size: 12,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  isOnline ? 'Online • Available Now' : 'Offline',
                                  style: TextStyle(color: isOnline ? Colors.green : Colors.grey),
                                ),
                                const SizedBox(width: 8),
                                if (_getDoctorVerified(doctor))
                                  const Icon(Icons.verified, color: Color(0xFF00B4D8), size: 16),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _selectedDoctorId != null ? _startVideoConsultation : null,
                  child: const Text('Start Video Consultation'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}