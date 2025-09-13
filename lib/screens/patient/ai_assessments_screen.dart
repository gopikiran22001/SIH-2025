import 'package:flutter/material.dart';
import '../../services/supabase_service.dart';
import '../../services/local_storage_service.dart';
import '../../services/local_storage_service.dart';



class AiAssessmentsScreen extends StatefulWidget {
  const AiAssessmentsScreen({super.key});

  @override
  State<AiAssessmentsScreen> createState() => _AiAssessmentsScreenState();
}

class _AiAssessmentsScreenState extends State<AiAssessmentsScreen> {
  List<Map<String, dynamic>> _assessments = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAssessments();
  }

  Future<void> _loadAssessments() async {
    final user = SupabaseService.currentUser;
    if (user == null) return;

    try {
      // First load from cache
      final localAssessments = LocalStorageService.getCachedAiAssessments();
      if (mounted && localAssessments.isNotEmpty) {
        setState(() {
          _assessments = localAssessments;
          _isLoading = false;
        });
      }
      
      // Then try to sync from server
      try {
        final assessments = await SupabaseService.getAiAssessments(user.id);
        await LocalStorageService.cacheAiAssessments(assessments);
        
        if (mounted) {
          setState(() {
            _assessments = assessments;
            _isLoading = false;
          });
        }
      } catch (e) {
        print('DEBUG: Failed to load from server, using cached data: $e');
        if (mounted && _assessments.isEmpty) {
          setState(() => _isLoading = false);
        }
      }
    } catch (e) {
      print('DEBUG: Error loading assessments: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Health Assessments'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _assessments.isEmpty
              ? Center(
                  child: Text(
                    'No AI assessments yet',
                    style: TextStyle(
                      fontSize: screenWidth * 0.04,
                      color: Colors.grey[600],
                    ),
                  ),
                )
              : ListView.builder(
                  padding: EdgeInsets.all(screenWidth * 0.04),
                  itemCount: _assessments.length,
                  itemBuilder: (context, index) {
                    final assessment = _assessments[index];
                    final date = DateTime.parse(assessment['created_at']);
                    
                    return Container(
                      margin: EdgeInsets.only(bottom: screenWidth * 0.03),
                      padding: EdgeInsets.all(screenWidth * 0.04),
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
                            children: [
                              Icon(
                                Icons.psychology,
                                color: const Color(0xFF10B981),
                                size: screenWidth * 0.05,
                              ),
                              SizedBox(width: screenWidth * 0.03),
                              Expanded(
                                child: Text(
                                  'AI Health Assessment',
                                  style: TextStyle(
                                    fontSize: screenWidth * 0.04,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: screenWidth * 0.02),
                          Text(
                            '${date.day}/${date.month}/${date.year} at ${date.hour}:${date.minute.toString().padLeft(2, '0')}',
                            style: TextStyle(
                              fontSize: screenWidth * 0.035,
                              color: Colors.grey[600],
                            ),
                          ),
                          SizedBox(height: screenWidth * 0.03),
                          _buildSymptomsSection(assessment['symptoms'], screenWidth),
                          SizedBox(height: screenWidth * 0.03),
                          _buildResultSection(assessment['result'], screenWidth),
                        ],
                      ),
                    );
                  },
                ),
    );
  }

  Widget _buildSymptomsSection(dynamic symptoms, double screenWidth) {
    final symptomsData = _extractSymptomsData(symptoms);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Patient Information & Symptoms',
          style: TextStyle(
            fontSize: screenWidth * 0.035,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF374151),
          ),
        ),
        SizedBox(height: screenWidth * 0.02),
        
        // Patient details row
        if (symptomsData['age'] != null || symptomsData['gender'] != null)
          Container(
            margin: EdgeInsets.only(bottom: screenWidth * 0.02),
            child: Row(
              children: [
                if (symptomsData['age'] != null) ...[
                  _buildInfoChip('Age: ${symptomsData['age']}', Icons.cake, screenWidth),
                  SizedBox(width: screenWidth * 0.02),
                ],
                if (symptomsData['gender'] != null)
                  _buildInfoChip('Gender: ${symptomsData['gender']}', Icons.person, screenWidth),
              ],
            ),
          ),
        
        // Symptoms description
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(screenWidth * 0.03),
          decoration: BoxDecoration(
            color: Colors.blue.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(screenWidth * 0.02),
            border: Border.all(color: Colors.blue.withValues(alpha: 0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.medical_information,
                    size: screenWidth * 0.04,
                    color: Colors.blue[700],
                  ),
                  SizedBox(width: screenWidth * 0.02),
                  Text(
                    'Reported Symptoms:',
                    style: TextStyle(
                      fontSize: screenWidth * 0.03,
                      fontWeight: FontWeight.w600,
                      color: Colors.blue[700],
                    ),
                  ),
                ],
              ),
              SizedBox(height: screenWidth * 0.02),
              Text(
                symptomsData['text'] ?? 'No symptoms recorded',
                style: TextStyle(
                  fontSize: screenWidth * 0.035,
                  color: const Color(0xFF1A1A1A),
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
  
  Widget _buildInfoChip(String text, IconData icon, double screenWidth) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: screenWidth * 0.025,
        vertical: screenWidth * 0.015,
      ),
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(screenWidth * 0.04),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: screenWidth * 0.03,
            color: Colors.grey[600],
          ),
          SizedBox(width: screenWidth * 0.01),
          Text(
            text,
            style: TextStyle(
              fontSize: screenWidth * 0.03,
              color: Colors.grey[700],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultSection(dynamic result, double screenWidth) {
    final analysis = _extractAnalysis(result);
    final conditions = _extractConditions(result);
    final recommendations = _extractRecommendations(result);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'AI Analysis',
          style: TextStyle(
            fontSize: screenWidth * 0.035,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF374151),
          ),
        ),
        SizedBox(height: screenWidth * 0.02),
        if (conditions.isNotEmpty) ...[
          Text(
            'Possible Conditions:',
            style: TextStyle(
              fontSize: screenWidth * 0.03,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF6B7280),
            ),
          ),
          SizedBox(height: screenWidth * 0.01),
          ...conditions.take(3).map((condition) => Container(
            margin: EdgeInsets.only(bottom: screenWidth * 0.01),
            padding: EdgeInsets.all(screenWidth * 0.025),
            decoration: BoxDecoration(
              color: Colors.orange.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(screenWidth * 0.015),
              border: Border.all(color: Colors.orange.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    condition['condition'] ?? condition.toString(),
                    style: TextStyle(
                      fontSize: screenWidth * 0.03,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                if (condition is Map && condition['confidence'] != null)
                  Text(
                    '${(condition['confidence'] * 100).toInt()}%',
                    style: TextStyle(
                      fontSize: screenWidth * 0.025,
                      color: Colors.orange[700],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
              ],
            ),
          )),
          SizedBox(height: screenWidth * 0.02),
        ],
        if (recommendations.isNotEmpty) ...[
          Text(
            'Recommendations:',
            style: TextStyle(
              fontSize: screenWidth * 0.03,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF6B7280),
            ),
          ),
          SizedBox(height: screenWidth * 0.01),
          ...recommendations.take(3).map((rec) => Padding(
            padding: EdgeInsets.only(bottom: screenWidth * 0.005),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '• ',
                  style: TextStyle(
                    color: const Color(0xFF10B981),
                    fontSize: screenWidth * 0.03,
                  ),
                ),
                Expanded(
                  child: Text(
                    rec.toString(),
                    style: TextStyle(
                      fontSize: screenWidth * 0.03,
                      color: const Color(0xFF4B5563),
                    ),
                  ),
                ),
              ],
            ),
          )),
        ],
      ],
    );
  }

  Map<String, dynamic> _extractSymptomsData(dynamic symptoms) {
    if (symptoms == null) return {'text': 'No symptoms recorded'};
    
    if (symptoms is Map) {
      return {
        'text': symptoms['text'] ?? 'No symptoms recorded',
        'age': symptoms['age'],
        'gender': symptoms['gender'] != null ? _capitalizeString(symptoms['gender'].toString()) : null,
      };
    }
    
    if (symptoms is String) {
      return {'text': symptoms};
    }
    
    return {'text': symptoms.toString()};
  }

  List<dynamic> _extractConditions(dynamic result) {
    if (result == null) return [];
    if (result is Map) {
      final resultMap = Map<String, dynamic>.from(result);
      if (resultMap['analysis'] is Map && resultMap['analysis']['conditions'] is List) {
        return resultMap['analysis']['conditions'];
      }
      if (resultMap['conditions'] is List) {
        return resultMap['conditions'];
      }
    }
    return [];
  }

  List<dynamic> _extractRecommendations(dynamic result) {
    if (result == null) return [];
    if (result is Map) {
      final resultMap = Map<String, dynamic>.from(result);
      if (resultMap['analysis'] is Map && resultMap['analysis']['recommendations'] is List) {
        return resultMap['analysis']['recommendations'];
      }
      if (resultMap['recommendations'] is List) {
        return resultMap['recommendations'];
      }
      if (resultMap['risk_assessment'] is Map && resultMap['risk_assessment']['recommendations'] is List) {
        return resultMap['risk_assessment']['recommendations'];
      }
    }
    return [];
  }

  Map<String, dynamic> _extractAnalysis(dynamic result) {
    if (result == null) return {};
    if (result is Map) {
      final analysis = result['analysis'];
      if (analysis is Map) {
        return Map<String, dynamic>.from(analysis);
      }
      return Map<String, dynamic>.from(result);
    }
    return {};
  }

  String _capitalizeString(String text) {
    if (text.isEmpty) return text;
    return '${text[0].toUpperCase()}${text.substring(1).toLowerCase()}';
  }
}