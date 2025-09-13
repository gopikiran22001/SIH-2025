import 'package:flutter/material.dart';

import '../../services/ai_service.dart';
import '../../services/supabase_service.dart';
import '../../services/local_storage_service.dart';
import '../../services/offline_sync_service.dart';

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
        title: Text(
          'AI Symptom Checker',
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
      body: SingleChildScrollView(
        padding: EdgeInsets.all(screenWidth * 0.04),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInputForm(),
            SizedBox(height: screenHeight * 0.03),
            if (_analysisResult != null) _buildAnalysisResults(),
            if (_riskAssessment != null) _buildRiskAssessment(),
          ],
        ),
      ),
    );
  }

  Widget _buildInputForm() {
    final screenSize = MediaQuery.of(context).size;
    final screenWidth = screenSize.width;
    final screenHeight = screenSize.height;
    
    return Container(
      padding: EdgeInsets.all(screenWidth * 0.05),
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
            'Describe Your Symptoms',
            style: TextStyle(
              fontSize: screenWidth * 0.045,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1A1A1A),
            ),
          ),
          SizedBox(height: screenHeight * 0.02),
          TextFormField(
            controller: _symptomsController,
            maxLines: 4,
            style: TextStyle(fontSize: screenWidth * 0.04),
            decoration: InputDecoration(
              hintText: 'Describe your symptoms in detail...',
              hintStyle: TextStyle(fontSize: screenWidth * 0.035),
              border: const OutlineInputBorder(),
              alignLabelWithHint: true,
              contentPadding: EdgeInsets.all(screenWidth * 0.04),
            ),
          ),
          SizedBox(height: screenHeight * 0.02),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _ageController,
                  keyboardType: TextInputType.number,
                  style: TextStyle(fontSize: screenWidth * 0.04),
                  decoration: InputDecoration(
                    labelText: 'Age (optional)',
                    labelStyle: TextStyle(fontSize: screenWidth * 0.035),
                    border: const OutlineInputBorder(),
                    contentPadding: EdgeInsets.all(screenWidth * 0.04),
                  ),
                ),
              ),
              SizedBox(width: screenWidth * 0.04),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedGender,
                  style: TextStyle(
                    fontSize: screenWidth * 0.04,
                    color: Colors.black,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Gender (optional)',
                    labelStyle: TextStyle(fontSize: screenWidth * 0.035),
                    border: const OutlineInputBorder(),
                    contentPadding: EdgeInsets.all(screenWidth * 0.04),
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
          SizedBox(height: screenHeight * 0.03),
          SizedBox(
            width: double.infinity,
            height: screenHeight * 0.06,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _analyzeSymptoms,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00B4D8),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(screenWidth * 0.02),
                ),
              ),
              child: _isLoading
                  ? SizedBox(
                      width: screenWidth * 0.05,
                      height: screenWidth * 0.05,
                      child: const CircularProgressIndicator(color: Colors.white),
                    )
                  : Text(
                      'Analyze Symptoms',
                      style: TextStyle(fontSize: screenWidth * 0.04),
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
      padding: EdgeInsets.all(screenWidth * 0.05),
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
            'Analysis Results',
            style: TextStyle(
              fontSize: screenWidth * 0.045,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1A1A1A),
            ),
          ),
          SizedBox(height: screenHeight * 0.02),
          Text(
            'Possible Conditions:',
            style: TextStyle(
              fontSize: screenWidth * 0.035,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF374151),
            ),
          ),
          SizedBox(height: screenHeight * 0.01),
          ...conditions.map((condition) => _buildConditionCard(condition)),
          SizedBox(height: screenHeight * 0.02),
          Text(
            'Recommendations:',
            style: TextStyle(
              fontSize: screenWidth * 0.035,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF374151),
            ),
          ),
          SizedBox(height: screenHeight * 0.01),
          ...recommendations.map((rec) => Padding(
            padding: EdgeInsets.only(bottom: screenHeight * 0.005),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '• ',
                  style: TextStyle(
                    color: const Color(0xFF2563EB),
                    fontSize: screenWidth * 0.035,
                  ),
                ),
                Expanded(
                  child: Text(
                    rec.toString(),
                    style: TextStyle(
                      color: const Color(0xFF64748B),
                      fontSize: screenWidth * 0.035,
                    ),
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
        severityColor = const Color(0xFFDC2626);
        break;
      case 'medium':
        severityColor = const Color(0xFFF59E0B);
        break;
      default:
        severityColor = const Color(0xFF059669);
    }

    return Container(
      margin: EdgeInsets.only(bottom: screenHeight * 0.01),
      padding: EdgeInsets.all(screenWidth * 0.03),
      decoration: BoxDecoration(
        color: severityColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(screenWidth * 0.02),
        border: Border.all(color: severityColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  condition['condition'],
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: severityColor,
                    fontSize: screenWidth * 0.035,
                  ),
                ),
                Text(
                  'Specialty: ${condition['specialty']}',
                  style: TextStyle(
                    fontSize: screenWidth * 0.03,
                    color: const Color(0xFF64748B),
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
              borderRadius: BorderRadius.circular(screenWidth * 0.01),
            ),
            child: Text(
              '${(condition['confidence'] * 100).toInt()}%',
              style: TextStyle(
                color: Colors.white,
                fontSize: screenWidth * 0.03,
                fontWeight: FontWeight.w500,
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
        riskColor = const Color(0xFFDC2626);
        break;
      case 'medium':
        riskColor = const Color(0xFFF59E0B);
        break;
      default:
        riskColor = const Color(0xFF059669);
    }

    return Container(
      padding: EdgeInsets.all(screenWidth * 0.05),
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
            'Risk Assessment',
            style: TextStyle(
              fontSize: screenWidth * 0.045,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1A1A1A),
            ),
          ),
          SizedBox(height: screenHeight * 0.02),
          Container(
            padding: EdgeInsets.all(screenWidth * 0.04),
            decoration: BoxDecoration(
              color: riskColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(screenWidth * 0.02),
              border: Border.all(color: riskColor.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.warning,
                  color: riskColor,
                  size: screenWidth * 0.06,
                ),
                SizedBox(width: screenWidth * 0.03),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Risk Level: ${riskLevel.toUpperCase()}',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: riskColor,
                          fontSize: screenWidth * 0.035,
                        ),
                      ),
                      Text(
                        'Confidence: ${(confidence * 100).toInt()}%',
                        style: TextStyle(
                          fontSize: screenWidth * 0.03,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: screenHeight * 0.02),
          Text(
            'Recommendations:',
            style: TextStyle(
              fontSize: screenWidth * 0.035,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF374151),
            ),
          ),
          SizedBox(height: screenHeight * 0.01),
          ...recommendations.map((rec) => Padding(
            padding: EdgeInsets.only(bottom: screenHeight * 0.005),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '• ',
                  style: TextStyle(
                    color: const Color(0xFF2563EB),
                    fontSize: screenWidth * 0.035,
                  ),
                ),
                Expanded(
                  child: Text(
                    rec.toString(),
                    style: TextStyle(
                      color: const Color(0xFF64748B),
                      fontSize: screenWidth * 0.035,
                    ),
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
      
      final analysisResult = await AiService.analyzeSymptoms(
        _symptomsController.text.trim(),
        age: age,
        gender: _selectedGender,
      );
      
      final riskAssessment = await AiService.assessRisk(
        _symptomsController.text.trim(),
        age: age,
        gender: _selectedGender,
      );

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
          _analysisResult = analysisResult;
          _riskAssessment = riskAssessment;
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

  @override
  void dispose() {
    _symptomsController.dispose();
    _ageController.dispose();
    super.dispose();
  }
}