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
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_patients.isEmpty) {
      return Center(
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
              'Patients will appear here after confirmed appointments',
              style: TextStyle(
                fontSize: screenWidth * 0.035,
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadPatients,
      child: ListView.builder(
        padding: EdgeInsets.all(screenWidth * 0.04),
        itemCount: _patients.length,
        itemBuilder: (context, index) {
          return _buildPatientCard(_patients[index]);
        },
      ),
    );
  }

  Widget _buildPatientCard(Map<String, dynamic> patient) {
    final screenWidth = MediaQuery.of(context).size.width;
    final profile = patient['profiles'];
    final patientData = patient['patients'];

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
                backgroundColor: const Color(0xFF2563EB),
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
                    if (profile?['phone'] != null) ...[
                      SizedBox(height: screenWidth * 0.01),
                      Text(
                        profile['phone'],
                        style: TextStyle(
                          fontSize: screenWidth * 0.03,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                    ],
                    if (patientData?['blood_group'] != null) ...[
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
              Icon(
                Icons.arrow_forward_ios,
                size: screenWidth * 0.04,
                color: const Color(0xFF64748B),
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
                      SizedBox(height: screenWidth * 0.04),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () => _createPrescription(patient),
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
                              onPressed: () => _startChat(patient),
                              icon: Icon(Icons.chat, size: screenWidth * 0.04),
                              label: Text(
                                'Start Chat',
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

  void _createPrescription(Map<String, dynamic> patient) {
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Create prescription feature coming soon')),
    );
  }

  void _startChat(Map<String, dynamic> patient) {
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Chat feature coming soon')),
    );
  }
}