import 'package:flutter/material.dart';
import '../../services/supabase_service.dart';
import '../../services/local_storage_service.dart';
import '../../utils/app_router.dart';

class AiAnalysisTab extends StatefulWidget {
  const AiAnalysisTab({super.key});

  @override
  State<AiAnalysisTab> createState() => _AiAnalysisTabState();
}

class _AiAnalysisTabState extends State<AiAnalysisTab> {
  List<Map<String, dynamic>> _assessments = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAssessments();
  }

  Future<void> _loadAssessments() async {
    try {
      // First load from cache for immediate display
      final localAssessments = LocalStorageService.getCachedAiAssessments();
      if (mounted && localAssessments.isNotEmpty) {
        setState(() {
          _assessments = localAssessments;
          _isLoading = false;
        });
      }
      
      // Then try to sync from server
      final user = SupabaseService.currentUser;
      if (user != null) {
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
          // Already loaded from cache above
          if (mounted && _assessments.isEmpty) {
            setState(() => _isLoading = false);
          }
        }
      } else {
        if (mounted) {
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
    final screenSize = MediaQuery.of(context).size;
    final screenWidth = screenSize.width;

    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(screenWidth * 0.04),
          child: ElevatedButton.icon(
            onPressed: () => AppRouter.go('/symptom-checker'),
            icon: Icon(Icons.psychology, size: screenWidth * 0.05),
            label: Text(
              'New AI Analysis',
              style: TextStyle(fontSize: screenWidth * 0.04),
            ),
            style: ElevatedButton.styleFrom(
              minimumSize: Size(double.infinity, screenWidth * 0.12),
            ),
          ),
        ),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _assessments.isEmpty
                  ? _buildEmptyState()
                  : RefreshIndicator(
                      onRefresh: _loadAssessments,
                      child: ListView.builder(
                        padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04),
                        itemCount: _assessments.length,
                        itemBuilder: (context, index) {
                          return _buildAssessmentCard(_assessments[index]);
                        },
                      ),
                    ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    final screenWidth = MediaQuery.of(context).size.width;
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.psychology_outlined,
            size: screenWidth * 0.2,
            color: Colors.grey[400],
          ),
          SizedBox(height: screenWidth * 0.04),
          Text(
            'No AI analyses yet',
            style: TextStyle(
              fontSize: screenWidth * 0.045,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: screenWidth * 0.02),
          Text(
            'Start your first symptom analysis',
            style: TextStyle(
              fontSize: screenWidth * 0.035,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAssessmentCard(Map<String, dynamic> assessment) {
    final screenSize = MediaQuery.of(context).size;
    final screenWidth = screenSize.width;
    final createdAt = DateTime.parse(assessment['created_at']);
    final symptoms = assessment['symptoms'] is Map ? Map<String, dynamic>.from(assessment['symptoms']) : null;
    final result = assessment['result'] is Map ? Map<String, dynamic>.from(assessment['result']) : null;
    
    String riskLevel = 'Unknown';
    Color riskColor = Colors.grey;
    
    if (result != null && result['risk_assessment'] != null) {
      riskLevel = result['risk_assessment']['risk_level'] ?? 'Unknown';
      switch (riskLevel.toLowerCase()) {
        case 'high':
          riskColor = const Color(0xFFDC2626);
          break;
        case 'medium':
          riskColor = const Color(0xFFF59E0B);
          break;
        case 'low':
          riskColor = const Color(0xFF059669);
          break;
      }
    }

    return Card(
      margin: EdgeInsets.only(bottom: screenWidth * 0.03),
      child: InkWell(
        onTap: () => _showAssessmentDetails(assessment),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.all(screenWidth * 0.04),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
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
                      size: screenWidth * 0.05,
                    ),
                  ),
                  SizedBox(width: screenWidth * 0.03),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'AI Health Analysis',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: screenWidth * 0.04,
                            color: const Color(0xFF1A1A1A),
                          ),
                        ),
                        Text(
                          '${createdAt.day}/${createdAt.month}/${createdAt.year} at ${createdAt.hour}:${createdAt.minute.toString().padLeft(2, '0')}',
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
                      vertical: screenWidth * 0.01,
                    ),
                    decoration: BoxDecoration(
                      color: riskColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(screenWidth * 0.01),
                    ),
                    child: Text(
                      riskLevel.toUpperCase(),
                      style: TextStyle(
                        fontSize: screenWidth * 0.025,
                        fontWeight: FontWeight.w500,
                        color: riskColor,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: screenWidth * 0.03),
              if (symptoms != null && symptoms['text'] != null) ...[
                Text(
                  'Symptoms:',
                  style: TextStyle(
                    fontSize: screenWidth * 0.035,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF374151),
                  ),
                ),
                SizedBox(height: screenWidth * 0.01),
                Text(
                  symptoms['text'],
                  style: TextStyle(
                    fontSize: screenWidth * 0.035,
                    color: const Color(0xFF64748B),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              SizedBox(height: screenWidth * 0.02),
              Row(
                children: [
                  Icon(
                    Icons.visibility,
                    size: screenWidth * 0.04,
                    color: const Color(0xFF00B4D8),
                  ),
                  SizedBox(width: screenWidth * 0.02),
                  Text(
                    'View Details',
                    style: TextStyle(
                      fontSize: screenWidth * 0.035,
                      color: const Color(0xFF00B4D8),
                      fontWeight: FontWeight.w500,
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

  void _showAssessmentDetails(Map<String, dynamic> assessment) {
    final screenWidth = MediaQuery.of(context).size.width;
    final result = assessment['result'] is Map ? Map<String, dynamic>.from(assessment['result']) : null;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(screenWidth * 0.05),
        ),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
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
              Text(
                'AI Analysis Results',
                style: TextStyle(
                  fontSize: screenWidth * 0.05,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: screenWidth * 0.04),
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (result != null) ...[
                        if (result['analysis'] != null) 
                          _buildAnalysisSection(result['analysis']),
                        SizedBox(height: screenWidth * 0.04),
                        if (result['risk_assessment'] != null)
                          _buildRiskSection(result['risk_assessment']),
                      ] else
                        Text(
                          'No detailed results available',
                          style: TextStyle(fontSize: screenWidth * 0.035),
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

  Widget _buildAnalysisSection(Map<String, dynamic> analysis) {
    final screenWidth = MediaQuery.of(context).size.width;
    final conditions = analysis['conditions'] as List<dynamic>? ?? [];
    final recommendations = analysis['recommendations'] as List<dynamic>? ?? [];
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Possible Conditions',
          style: TextStyle(
            fontSize: screenWidth * 0.04,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: screenWidth * 0.02),
        ...conditions.map((condition) => Container(
          margin: EdgeInsets.only(bottom: screenWidth * 0.02),
          padding: EdgeInsets.all(screenWidth * 0.03),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(screenWidth * 0.02),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                condition['condition'] ?? 'Unknown',
                style: TextStyle(
                  fontSize: screenWidth * 0.035,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                'Specialty: ${condition['specialty'] ?? 'General'}',
                style: TextStyle(
                  fontSize: screenWidth * 0.03,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        )),
        SizedBox(height: screenWidth * 0.03),
        Text(
          'Recommendations',
          style: TextStyle(
            fontSize: screenWidth * 0.04,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: screenWidth * 0.02),
        ...recommendations.map((rec) => Padding(
          padding: EdgeInsets.only(bottom: screenWidth * 0.01),
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
    );
  }

  Widget _buildRiskSection(Map<String, dynamic> riskAssessment) {
    final screenWidth = MediaQuery.of(context).size.width;
    final riskLevel = riskAssessment['risk_level'] ?? 'Unknown';
    final confidence = riskAssessment['confidence'] ?? 0.0;
    final recommendations = riskAssessment['recommendations'] as List<dynamic>? ?? [];
    
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
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Risk Assessment',
          style: TextStyle(
            fontSize: screenWidth * 0.04,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: screenWidth * 0.02),
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
              Row(
                children: [
                  Icon(Icons.warning, color: riskColor, size: screenWidth * 0.05),
                  SizedBox(width: screenWidth * 0.02),
                  Text(
                    'Risk Level: ${riskLevel.toUpperCase()}',
                    style: TextStyle(
                      fontSize: screenWidth * 0.035,
                      fontWeight: FontWeight.w600,
                      color: riskColor,
                    ),
                  ),
                ],
              ),
              SizedBox(height: screenWidth * 0.01),
              Text(
                'Confidence: ${(confidence * 100).toInt()}%',
                style: TextStyle(
                  fontSize: screenWidth * 0.03,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: screenWidth * 0.03),
        Text(
          'Risk Recommendations',
          style: TextStyle(
            fontSize: screenWidth * 0.035,
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: screenWidth * 0.01),
        ...recommendations.map((rec) => Padding(
          padding: EdgeInsets.only(bottom: screenWidth * 0.01),
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
    );
  }
}