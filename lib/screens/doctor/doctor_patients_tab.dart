import 'package:flutter/material.dart';
import '../../services/supabase_service.dart';

class DoctorPatientsTab extends StatefulWidget {
  const DoctorPatientsTab({super.key});

  @override
  State<DoctorPatientsTab> createState() => _DoctorPatientsTabState();
}

class _DoctorPatientsTabState extends State<DoctorPatientsTab> {
  List<Map<String, dynamic>> _patients = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPatients();
  }

  Future<void> _loadPatients() async {
    try {
      final user = SupabaseService.currentUser;
      if (user != null) {
        final patients = await SupabaseService.getDoctorPatients(user.id);
        if (mounted) {
          setState(() {
            _patients = patients;
            _isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    print('DEBUG: DoctorPatientsTab build called');
    print('DEBUG: _isLoading: $_isLoading');
    print('DEBUG: _patients.length: ${_patients.length}');
    print('DEBUG: _patients data: $_patients');
    
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _patients.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.people_outlined,
                        size: screenWidth * 0.2,
                        color: Colors.grey[400],
                      ),
                      SizedBox(height: screenWidth * 0.04),
                      Text(
                        'No patients yet',
                        style: TextStyle(
                          fontSize: screenWidth * 0.045,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(height: screenWidth * 0.02),
                      Text(
                        'Patients will appear here after consultations',
                        style: TextStyle(
                          fontSize: screenWidth * 0.035,
                          color: Colors.grey[500],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadPatients,
                  child: ListView.builder(
                    padding: EdgeInsets.all(screenWidth * 0.04),
                    itemCount: _patients.length,
                    itemBuilder: (context, index) {
                      print('DEBUG: Building patient card for index: $index');
                      return _buildPatientCard(_patients[index]);
                    },
                  ),
                ),
    );
  }

  Widget _buildPatientCard(Map<String, dynamic> patient) {
    final screenWidth = MediaQuery.of(context).size.width;
    final profile = patient['profiles'];
    final patientData = patient['patients'];
    final lastConsultation = DateTime.parse(patient['created_at']);

    return Card(
      margin: EdgeInsets.only(bottom: screenWidth * 0.03),
      child: InkWell(
        onTap: () => _showPatientDetails(patient),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.all(screenWidth * 0.04),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: const Color(0xFF00B4D8),
                radius: screenWidth * 0.06,
                child: Icon(
                  Icons.person,
                  color: Colors.white,
                  size: screenWidth * 0.05,
                ),
              ),
              SizedBox(width: screenWidth * 0.03),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      profile?['full_name'] ?? 'Patient',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: screenWidth * 0.04,
                        color: const Color(0xFF1A1A1A),
                      ),
                    ),
                    SizedBox(height: screenWidth * 0.01),
                    Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          size: screenWidth * 0.03,
                          color: const Color(0xFF64748B),
                        ),
                        SizedBox(width: screenWidth * 0.01),
                        Text(
                          'Last consultation: ${lastConsultation.day}/${lastConsultation.month}/${lastConsultation.year}',
                          style: TextStyle(
                            fontSize: screenWidth * 0.03,
                            color: const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                    if (profile?['phone'] != null) ...[
                      SizedBox(height: screenWidth * 0.005),
                      Row(
                        children: [
                          Icon(
                            Icons.phone,
                            size: screenWidth * 0.03,
                            color: const Color(0xFF64748B),
                          ),
                          SizedBox(width: screenWidth * 0.01),
                          Text(
                            profile['phone'],
                            style: TextStyle(
                              fontSize: screenWidth * 0.03,
                              color: const Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (patientData != null && patientData['blood_group'] != null) ...[
                      SizedBox(height: screenWidth * 0.01),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: screenWidth * 0.02,
                          vertical: screenWidth * 0.005,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFDC2626).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(screenWidth * 0.01),
                        ),
                        child: Text(
                          'Blood Group: ${patientData['blood_group']}',
                          style: TextStyle(
                            fontSize: screenWidth * 0.025,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFFDC2626),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Column(
                children: [
                  IconButton(
                    onPressed: () => _showPrescriptionDialog(patient),
                    icon: Icon(
                      Icons.receipt,
                      color: const Color(0xFF00B4D8),
                      size: screenWidth * 0.05,
                    ),
                  ),
                  Text(
                    'Prescribe',
                    style: TextStyle(
                      fontSize: screenWidth * 0.025,
                      color: const Color(0xFF00B4D8),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showPatientDetails(Map<String, dynamic> patient) {
    final screenWidth = MediaQuery.of(context).size.width;
    final profile = patient['profiles'];
    final patientData = patient['patients'];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(screenWidth * 0.05),
        ),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        minChildSize: 0.4,
        expand: false,
        builder: (context, scrollController) => Container(
          padding: EdgeInsets.all(screenWidth * 0.04),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: screenWidth * 0.1,
                  height: screenWidth * 0.01,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(screenWidth * 0.005),
                  ),
                ),
              ),
              SizedBox(height: screenWidth * 0.04),
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: const Color(0xFF2563EB),
                    radius: screenWidth * 0.08,
                    child: Icon(
                      Icons.person,
                      color: Colors.white,
                      size: screenWidth * 0.08,
                    ),
                  ),
                  SizedBox(width: screenWidth * 0.04),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          profile?['full_name'] ?? 'Patient',
                          style: TextStyle(
                            fontSize: screenWidth * 0.05,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Patient',
                          style: TextStyle(
                            fontSize: screenWidth * 0.035,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: screenWidth * 0.06),
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Patient Information',
                        style: TextStyle(
                          fontSize: screenWidth * 0.04,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: screenWidth * 0.03),
                      _buildInfoRow('Phone', profile?['phone'] ?? 'Not provided'),
                      _buildInfoRow('Gender', profile?['gender'] ?? 'Not specified'),
                      _buildInfoRow('Date of Birth', profile?['dob'] ?? 'Not provided'),
                      _buildInfoRow('Blood Group', patientData?['blood_group'] ?? 'Not provided'),
                      _buildInfoRow('Last Consultation', DateTime.parse(patient['created_at']).day.toString() + '/' + DateTime.parse(patient['created_at']).month.toString() + '/' + DateTime.parse(patient['created_at']).year.toString()),
                      SizedBox(height: screenWidth * 0.04),
                      Text(
                        'Actions',
                        style: TextStyle(
                          fontSize: screenWidth * 0.04,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: screenWidth * 0.02),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () {
                                Navigator.pop(context);
                                _showPrescriptionDialog(patient);
                              },
                              icon: Icon(Icons.receipt, size: screenWidth * 0.04),
                              label: Text(
                                'Create Prescription',
                                style: TextStyle(fontSize: screenWidth * 0.035),
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: screenWidth * 0.02),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => _viewConsultationHistory(patient),
                              icon: Icon(Icons.history, size: screenWidth * 0.04),
                              label: Text(
                                'View Consultation History',
                                style: TextStyle(fontSize: screenWidth * 0.035),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
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

  void _showPrescriptionDialog(Map<String, dynamic> patient) {
    final prescriptionController = TextEditingController();
    final medicineController = TextEditingController();
    final dosageController = TextEditingController();
    final instructionsController = TextEditingController();
    final profile = patient['profiles'];
    final screenWidth = MediaQuery.of(context).size.width;
    
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(screenWidth * 0.04),
        ),
        child: Container(
          width: screenWidth * 0.9,
          padding: EdgeInsets.all(screenWidth * 0.05),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(screenWidth * 0.04),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.white, Color(0xFFF8FAFC)],
            ),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(screenWidth * 0.025),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF00B4D8), Color(0xFF0077B6)],
                        ),
                        borderRadius: BorderRadius.circular(screenWidth * 0.02),
                      ),
                      child: Icon(
                        Icons.receipt_long,
                        color: Colors.white,
                        size: screenWidth * 0.05,
                      ),
                    ),
                    SizedBox(width: screenWidth * 0.03),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Create Prescription',
                            style: TextStyle(
                              fontSize: screenWidth * 0.045,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF1A1A1A),
                            ),
                          ),
                          Text(
                            'For ${profile?['full_name'] ?? 'Patient'}',
                            style: TextStyle(
                              fontSize: screenWidth * 0.035,
                              color: const Color(0xFF6B7280),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: screenWidth * 0.05),
                Container(
                  padding: EdgeInsets.all(screenWidth * 0.04),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00B4D8).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(screenWidth * 0.03),
                    border: Border.all(
                      color: const Color(0xFF00B4D8).withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.person,
                        color: const Color(0xFF00B4D8),
                        size: screenWidth * 0.04,
                      ),
                      SizedBox(width: screenWidth * 0.02),
                      Text(
                        'Patient: ${profile?['full_name'] ?? 'Unknown'}',
                        style: TextStyle(
                          fontSize: screenWidth * 0.035,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF00B4D8),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: screenWidth * 0.04),
                _buildPrescriptionField(
                  'Medicine Name',
                  medicineController,
                  Icons.medication,
                  'e.g., Paracetamol, Amoxicillin',
                ),
                SizedBox(height: screenWidth * 0.03),
                _buildPrescriptionField(
                  'Dosage',
                  dosageController,
                  Icons.schedule,
                  'e.g., 500mg twice daily',
                ),
                SizedBox(height: screenWidth * 0.03),
                _buildPrescriptionField(
                  'Instructions',
                  instructionsController,
                  Icons.info_outline,
                  'e.g., Take after meals, avoid alcohol',
                  maxLines: 3,
                ),
                SizedBox(height: screenWidth * 0.03),
                _buildPrescriptionField(
                  'Additional Notes',
                  prescriptionController,
                  Icons.note_add,
                  'Any additional medical advice or notes...',
                  maxLines: 4,
                ),
                SizedBox(height: screenWidth * 0.05),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: screenWidth * 0.035),
                          side: const BorderSide(color: Color(0xFF6B7280)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(screenWidth * 0.02),
                          ),
                        ),
                        child: Text(
                          'Cancel',
                          style: TextStyle(
                            fontSize: screenWidth * 0.035,
                            color: const Color(0xFF6B7280),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: screenWidth * 0.03),
                    Expanded(
                      flex: 2,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF00B4D8), Color(0xFF0077B6)],
                          ),
                          borderRadius: BorderRadius.circular(screenWidth * 0.02),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF00B4D8).withValues(alpha: 0.3),
                              blurRadius: screenWidth * 0.02,
                              offset: Offset(0, screenWidth * 0.01),
                            ),
                          ],
                        ),
                        child: ElevatedButton.icon(
                          onPressed: () => _createPrescription(
                            patient,
                            _buildPrescriptionContent(
                              medicineController.text,
                              dosageController.text,
                              instructionsController.text,
                              prescriptionController.text,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            padding: EdgeInsets.symmetric(vertical: screenWidth * 0.035),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(screenWidth * 0.02),
                            ),
                          ),
                          icon: Icon(
                            Icons.check_circle,
                            color: Colors.white,
                            size: screenWidth * 0.04,
                          ),
                          label: Text(
                            'Create Prescription',
                            style: TextStyle(
                              fontSize: screenWidth * 0.035,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPrescriptionField(
    String label,
    TextEditingController controller,
    IconData icon,
    String hint, {
    int maxLines = 1,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              icon,
              color: const Color(0xFF00B4D8),
              size: screenWidth * 0.04,
            ),
            SizedBox(width: screenWidth * 0.02),
            Text(
              label,
              style: TextStyle(
                fontSize: screenWidth * 0.035,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF374151),
              ),
            ),
          ],
        ),
        SizedBox(height: screenWidth * 0.02),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(screenWidth * 0.025),
            border: Border.all(color: const Color(0xFFE5E7EB)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: screenWidth * 0.01,
                offset: Offset(0, screenWidth * 0.005),
              ),
            ],
          ),
          child: TextField(
            controller: controller,
            maxLines: maxLines,
            style: TextStyle(fontSize: screenWidth * 0.035),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(
                fontSize: screenWidth * 0.032,
                color: const Color(0xFF9CA3AF),
              ),
              border: InputBorder.none,
              contentPadding: EdgeInsets.all(screenWidth * 0.035),
            ),
          ),
        ),
      ],
    );
  }

  String _buildPrescriptionContent(
    String medicine,
    String dosage,
    String instructions,
    String notes,
  ) {
    final content = StringBuffer();
    
    if (medicine.trim().isNotEmpty) {
      content.writeln('Medicine: ${medicine.trim()}');
    }
    if (dosage.trim().isNotEmpty) {
      content.writeln('Dosage: ${dosage.trim()}');
    }
    if (instructions.trim().isNotEmpty) {
      content.writeln('Instructions: ${instructions.trim()}');
    }
    if (notes.trim().isNotEmpty) {
      content.writeln('\nAdditional Notes: ${notes.trim()}');
    }
    
    return content.toString();
  }

  Future<void> _createPrescription(Map<String, dynamic> patient, String content) async {
    if (content.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter prescription details')),
      );
      return;
    }

    try {
      final user = SupabaseService.currentUser;
      if (user == null) return;

      await SupabaseService.createPrescription({
        'patient_id': patient['patient_id'],
        'doctor_id': user.id,
        'content': content.trim(),
      });

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Prescription created successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to create prescription: $e')),
        );
      }
    }
  }

  void _viewConsultationHistory(Map<String, dynamic> patient) async {
    try {
      final user = SupabaseService.currentUser;
      if (user == null) return;

      final consultations = await SupabaseService.client
          .from('video_consultations')
          .select('*')
          .eq('doctor_id', user.id)
          .eq('patient_id', patient['patient_id'])
          .order('created_at', ascending: false);

      if (mounted) {
        Navigator.pop(context);
        _showConsultationHistoryDialog(patient, consultations);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load consultation history: $e')),
      );
    }
  }

  void _showConsultationHistoryDialog(Map<String, dynamic> patient, List<dynamic> consultations) {
    final profile = patient['profiles'];
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Consultation History - ${profile?['full_name'] ?? 'Patient'}'),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: consultations.isEmpty
              ? const Center(child: Text('No consultation history found'))
              : ListView.builder(
                  itemCount: consultations.length,
                  itemBuilder: (context, index) {
                    final consultation = consultations[index];
                    final createdAt = DateTime.parse(consultation['created_at']);
                    final status = consultation['status'];
                    final symptoms = consultation['symptoms'] ?? 'No symptoms recorded';
                    
                    Color statusColor;
                    switch (status) {
                      case 'completed':
                        statusColor = Colors.green;
                        break;
                      case 'declined':
                        statusColor = Colors.red;
                        break;
                      case 'timeout':
                        statusColor = Colors.orange;
                        break;
                      default:
                        statusColor = Colors.grey;
                    }
                    
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '${createdAt.day}/${createdAt.month}/${createdAt.year}',
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: statusColor.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    status.toUpperCase(),
                                    style: TextStyle(
                                      color: statusColor,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Symptoms: $symptoms',
                              style: const TextStyle(fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _startChat(Map<String, dynamic> patient) {
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Chat feature coming soon')),
    );
  }
}