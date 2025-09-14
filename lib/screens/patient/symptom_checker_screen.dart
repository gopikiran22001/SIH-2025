import 'package:flutter/material.dart';

import '../../services/ai_booking_service.dart';
import '../../services/supabase_service.dart';
import '../../services/local_storage_service.dart';
import '../../services/offline_sync_service.dart';
import '../../widgets/loading_overlay.dart';

class SymptomCheckerScreen extends StatefulWidget {
  const SymptomCheckerScreen({super.key});

  @override
  State<SymptomCheckerScreen> createState() => _SymptomCheckerScreenState();
}

class _SymptomCheckerScreenState extends State<SymptomCheckerScreen> {
  final _symptomsController = TextEditingController();
  final _ageController = TextEditingController();
  String? _selectedGender;
  bool _isLoading = false;
  Map<String, dynamic>? _analysisResult;
  Map<String, dynamic>? _riskAssessment;

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
        title: Row(
          children: [
            Container(
              padding: EdgeInsets.all(screenWidth * 0.02),
              decoration: BoxDecoration(
                color: const Color(0xFF00B4D8).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(screenWidth * 0.02),
              ),
              child: Icon(
                Icons.psychology,
                color: const Color(0xFF00B4D8),
                size: screenWidth * 0.06,
              ),
            ),
            SizedBox(width: screenWidth * 0.03),
            Text(
              'AI Symptom Analyzer',
              style: TextStyle(
                color: const Color(0xFF1A1A1A),
                fontWeight: FontWeight.w600,
                fontSize: screenWidth * 0.045,
              ),
            ),
          ],
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
        padding: EdgeInsets.all(MediaQuery.of(context).size.width * 0.04),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeaderCard(),
            SizedBox(height: MediaQuery.of(context).size.height * 0.02),
            _buildInputForm(),
            SizedBox(height: MediaQuery.of(context).size.height * 0.025),
            if (_analysisResult != null) _buildAnalysisResults(),
            if (_riskAssessment != null) _buildRiskAssessment(),
          ],
        ),
      ),
      )
    );
  }

  Widget _buildHeaderCard() {
    final screenWidth = MediaQuery.of(context).size.width;
    
    return Container(
      padding: EdgeInsets.all(screenWidth * 0.04),
      decoration: BoxDecoration(
        color: const Color(0xFF00B4D8),
        borderRadius: BorderRadius.circular(screenWidth * 0.03),
      ),
      child: Row(
        children: [
          Icon(Icons.psychology, color: Colors.white, size: screenWidth * 0.08),
          SizedBox(width: screenWidth * 0.03),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AI Symptom Analyzer',
                  style: TextStyle(
                    fontSize: screenWidth * 0.045,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'Describe your symptoms for AI analysis',
                  style: TextStyle(
                    fontSize: screenWidth * 0.035,
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputForm() {
    final screenSize = MediaQuery.of(context).size;
    final screenWidth = screenSize.width;
    final screenHeight = screenSize.height;
    
    return Container(
      padding: EdgeInsets.all(screenWidth * 0.04),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(screenWidth * 0.03),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Describe Your Symptoms',
            style: TextStyle(
              fontSize: screenWidth * 0.04,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: screenHeight * 0.015),
          TextField(
            controller: _symptomsController,
            maxLines: 4,
            style: TextStyle(fontSize: screenWidth * 0.035),
            decoration: InputDecoration(
              hintText: 'Example: headache, fever, fatigue for 2 days...',
              hintStyle: TextStyle(fontSize: screenWidth * 0.032),
              border: const OutlineInputBorder(),
            ),
          ),
          SizedBox(height: screenHeight * 0.02),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _ageController,
                  keyboardType: TextInputType.number,
                  style: TextStyle(fontSize: screenWidth * 0.035),
                  decoration: InputDecoration(
                    labelText: 'Age',
                    labelStyle: TextStyle(fontSize: screenWidth * 0.032),
                    border: const OutlineInputBorder(),
                  ),
                ),
              ),
              SizedBox(width: screenWidth * 0.03),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedGender,
                  style: TextStyle(fontSize: screenWidth * 0.035, color: Colors.black),
                  decoration: InputDecoration(
                    labelText: 'Gender',
                    labelStyle: TextStyle(fontSize: screenWidth * 0.032),
                    border: const OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'male', child: Text('Male')),
                    DropdownMenuItem(value: 'female', child: Text('Female')),
                    DropdownMenuItem(value: 'other', child: Text('Other')),
                  ],
                  onChanged: (value) => setState(() => _selectedGender = value),
                ),
              ),
            ],
          ),
          SizedBox(height: screenHeight * 0.025),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isLoading ? null : _analyzeSymptoms,
              icon: Icon(Icons.psychology, size: screenWidth * 0.045),
              label: Text(
                'Analyze Symptoms',
                style: TextStyle(fontSize: screenWidth * 0.04),
              ),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: screenHeight * 0.015),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalysisResults() {
    final screenSize = MediaQuery.of(context).size;
    final screenWidth = screenSize.width;
    final screenHeight = screenSize.height;
    
    final conditions = _analysisResult!['conditions'] as List<dynamic>;
    final recommendations = _analysisResult!['recommendations'] as List<dynamic>;

    return Container(
      margin: EdgeInsets.only(bottom: screenHeight * 0.02),
      padding: EdgeInsets.all(screenWidth * 0.04),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(screenWidth * 0.03),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.analytics, color: const Color(0xFF10B981), size: screenWidth * 0.05),
              SizedBox(width: screenWidth * 0.02),
              Text(
                'Analysis Results',
                style: TextStyle(
                  fontSize: screenWidth * 0.045,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          SizedBox(height: screenHeight * 0.02),
          Text(
            'Possible Conditions:',
            style: TextStyle(
              fontSize: screenWidth * 0.04,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF10B981),
            ),
          ),
          SizedBox(height: screenHeight * 0.01),
          ...conditions.map((condition) => _buildConditionCard(condition)),
          SizedBox(height: screenHeight * 0.02),
          Text(
            'Recommendations:',
            style: TextStyle(
              fontSize: screenWidth * 0.04,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF3B82F6),
            ),
          ),
          SizedBox(height: screenHeight * 0.01),
          ...recommendations.map((rec) => Padding(
            padding: EdgeInsets.only(bottom: screenHeight * 0.005),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('• ', style: TextStyle(fontSize: screenWidth * 0.035)),
                Expanded(
                  child: Text(
                    rec.toString(),
                    style: TextStyle(fontSize: screenWidth * 0.035),
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildConditionCard(Map<String, dynamic> condition) {
    final screenSize = MediaQuery.of(context).size;
    final screenWidth = screenSize.width;
    final screenHeight = screenSize.height;
    
    Color severityColor;
    switch (condition['severity']) {
      case 'high':
        severityColor = Colors.red;
        break;
      case 'medium':
        severityColor = Colors.orange;
        break;
      default:
        severityColor = Colors.green;
    }

    return Container(
      margin: EdgeInsets.only(bottom: screenHeight * 0.01),
      padding: EdgeInsets.all(screenWidth * 0.03),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(screenWidth * 0.02),
        border: Border.all(color: severityColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      condition['condition'],
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: screenWidth * 0.04,
                      ),
                    ),
                    Text(
                      condition['specialty'],
                      style: TextStyle(
                        fontSize: screenWidth * 0.035,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: screenWidth * 0.02,
                  vertical: screenHeight * 0.005,
                ),
                decoration: BoxDecoration(
                  color: severityColor,
                  borderRadius: BorderRadius.circular(screenWidth * 0.03),
                ),
                child: Text(
                  '${(condition['confidence'] * 100).toInt()}%',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: screenWidth * 0.03,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: screenHeight * 0.01),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _consultDoctor(condition['specialty']),
              icon: Icon(Icons.chat, size: screenWidth * 0.04),
              label: Text(
                'Consult ${condition['specialty']} Doctor',
                style: TextStyle(fontSize: screenWidth * 0.035),
              ),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: screenHeight * 0.01),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRiskAssessment() {
    final screenSize = MediaQuery.of(context).size;
    final screenWidth = screenSize.width;
    final screenHeight = screenSize.height;
    
    final riskLevel = _riskAssessment!['risk_level'];
    final confidence = _riskAssessment!['confidence'];
    final recommendations = _riskAssessment!['recommendations'] as List<dynamic>;

    Color riskColor;
    switch (riskLevel.toLowerCase()) {
      case 'high':
        riskColor = Colors.red;
        break;
      case 'medium':
        riskColor = Colors.orange;
        break;
      default:
        riskColor = Colors.green;
    }

    return Container(
      padding: EdgeInsets.all(screenWidth * 0.04),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(screenWidth * 0.03),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.security, color: riskColor, size: screenWidth * 0.05),
              SizedBox(width: screenWidth * 0.02),
              Text(
                'Risk Assessment',
                style: TextStyle(
                  fontSize: screenWidth * 0.045,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          SizedBox(height: screenHeight * 0.015),
          Container(
            padding: EdgeInsets.all(screenWidth * 0.03),
            decoration: BoxDecoration(
              color: riskColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(screenWidth * 0.02),
              border: Border.all(color: riskColor.withValues(alpha: 0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Risk Level: ${riskLevel.toUpperCase()}',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: riskColor,
                    fontSize: screenWidth * 0.04,
                  ),
                ),
                Text(
                  'Confidence: ${(confidence * 100).toInt()}%',
                  style: TextStyle(
                    fontSize: screenWidth * 0.035,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: screenHeight * 0.015),
          Text(
            'Recommendations:',
            style: TextStyle(
              fontSize: screenWidth * 0.04,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: screenHeight * 0.01),
          ...recommendations.map((rec) => Padding(
            padding: EdgeInsets.only(bottom: screenHeight * 0.005),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('• ', style: TextStyle(fontSize: screenWidth * 0.035)),
                Expanded(
                  child: Text(
                    rec.toString(),
                    style: TextStyle(fontSize: screenWidth * 0.035),
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Future<void> _analyzeSymptoms() async {
    if (_symptomsController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please describe your symptoms')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final age = _ageController.text.isNotEmpty ? int.tryParse(_ageController.text) : null;
      
      final analysisResult = await AiBookingService.analyzeSymptoms(
        _symptomsController.text.trim(),
      );
      
      final riskAssessment = await AiBookingService.assessRisk(
        age ?? 25,
        _symptomsController.text.toLowerCase().contains('chest'),
        _symptomsController.text.toLowerCase().contains('breath'),
      );
      
      // Format results to match expected structure
      final formattedAnalysis = {
        'conditions': [{
          'condition': analysisResult['condition'],
          'confidence': analysisResult['confidence'],
          'severity': analysisResult['confidence'] > 0.8 ? 'high' : 
                     analysisResult['confidence'] > 0.5 ? 'medium' : 'low',
          'specialty': 'General Medicine',
        }],
        'recommendations': [
          'Monitor symptoms closely',
          'Stay hydrated and rest',
          'Consult a doctor if symptoms worsen',
        ],
      };
      
      final formattedRisk = {
        'risk_level': riskAssessment['risk_level'],
        'confidence': riskAssessment['risk_score'],
        'recommendations': [
          riskAssessment['risk_level'] == 'high' 
            ? 'Seek immediate medical attention'
            : 'Monitor symptoms and consult doctor if needed',
        ],
      };

      final user = SupabaseService.currentUser;
      if (user != null) {
        final assessment = {
          'id': 'local-${DateTime.now().millisecondsSinceEpoch}',
          'patient_id': user.id,
          'symptoms': {
            'text': _symptomsController.text.trim(),
            'age': age,
            'gender': _selectedGender,
          },
          'result': {
            'analysis': analysisResult,
            'risk_assessment': riskAssessment,
          },
          'created_at': DateTime.now().toIso8601String(),
        };
        
        // Always save locally first
        await LocalStorageService.cacheAiAssessment(assessment);
        
        try {
          // Try to save to server
          final serverAssessment = await SupabaseService.createAiAssessment(assessment);
          // Update local cache with server ID if successful
          if (serverAssessment['id'] != null) {
            assessment['id'] = serverAssessment['id'];
            await LocalStorageService.cacheAiAssessment(assessment);
          }
        } catch (e) {
          // Queue for offline sync
          final syncService = OfflineSyncService();
          await syncService.queueOperation('create_ai_assessment', assessment);
          print('DEBUG: Queued AI assessment for offline sync');
        }
      }

      if (mounted) {
        setState(() {
          _analysisResult = formattedAnalysis;
          _riskAssessment = formattedRisk;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Analysis failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _consultDoctor(String specialty) async {
    try {
      setState(() => _isLoading = true);
      
      final doctors = await SupabaseService.searchAvailableDoctors(specialty);
      
      if (mounted) {
        setState(() => _isLoading = false);
        
        if (doctors.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('No $specialty doctors available right now')),
          );
          return;
        }
        
        _showDoctorSelectionDialog(doctors, specialty);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to find doctors: $e')),
        );
      }
    }
  }
  
  void _showDoctorSelectionDialog(List<Map<String, dynamic>> doctors, String specialty) {
    final screenWidth = MediaQuery.of(context).size.width;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(screenWidth * 0.05)),
      ),
      builder: (context) => Container(
        padding: EdgeInsets.all(screenWidth * 0.04),
        height: MediaQuery.of(context).size.height * 0.6,
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
            Text(
              'Available $specialty Doctors',
              style: TextStyle(
                fontSize: screenWidth * 0.05,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: screenWidth * 0.04),
            Expanded(
              child: ListView.builder(
                itemCount: doctors.length,
                itemBuilder: (context, index) {
                  final doctor = doctors[index];
                  final doctorData = doctor['doctors'];
                  Map<String, dynamic>? doctorInfo;
                  
                  if (doctorData is List && doctorData.isNotEmpty) {
                    doctorInfo = doctorData[0];
                  } else if (doctorData is Map<String, dynamic>) {
                    doctorInfo = doctorData;
                  }
                  
                  return Card(
                    margin: EdgeInsets.only(bottom: screenWidth * 0.03),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: const Color(0xFF00B4D8),
                        child: Icon(Icons.person, color: Colors.white),
                      ),
                      title: Text(
                        doctor['full_name'] ?? 'Unknown Doctor',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: screenWidth * 0.04,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (doctorInfo != null) ...[
                            Text('${doctorInfo['specialization'] ?? specialty}'),
                            Text('${doctorInfo['clinic_name'] ?? 'Private Practice'}'),
                            Row(
                              children: [
                                Icon(Icons.star, color: Colors.amber, size: screenWidth * 0.04),
                                Text(' ${doctorInfo['rating'] ?? 4.5}'),
                              ],
                            ),
                          ],
                        ],
                      ),
                      trailing: ElevatedButton(
                        onPressed: () => _startChatWithDoctor(doctor),
                        child: Text('Chat', style: TextStyle(fontSize: screenWidth * 0.032)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF00B4D8),
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(
                            horizontal: screenWidth * 0.04,
                            vertical: screenWidth * 0.02,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Future<void> _startChatWithDoctor(Map<String, dynamic> doctor) async {
    final user = SupabaseService.currentUser;
    if (user == null) return;
    
    Navigator.pop(context); // Close doctor selection dialog
    
    final conversationId = '${user.id}_${doctor['id']}';
    final doctorName = doctor['full_name'] ?? 'Doctor';
    
    // Navigate to chat screen
    Navigator.pushNamed(
      context,
      '/chat',
      arguments: {
        'conversationId': conversationId,
        'otherUserId': doctor['id'],
        'otherUserName': doctorName,
      },
    );
  }

  @override
  void dispose() {
    _symptomsController.dispose();
    _ageController.dispose();
    super.dispose();
  }
}