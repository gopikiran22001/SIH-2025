import 'package:flutter/material.dart';
import 'appointments_history_screen.dart';
import 'prescriptions_screen.dart';
import 'ai_assessments_screen.dart';
import 'reports_screen.dart';

class MedicalHistoryScreen extends StatefulWidget {
  const MedicalHistoryScreen({super.key});

  @override
  State<MedicalHistoryScreen> createState() => _MedicalHistoryScreenState();
}

class _MedicalHistoryScreenState extends State<MedicalHistoryScreen> {
  @override
  void initState() {
    super.initState();
  }



  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Medical History'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Padding(
        padding: EdgeInsets.all(screenWidth * 0.04),
        child: Column(
          children: [
            _buildNavigationCard(
              'Past Consultations',
              Icons.video_call,
              const Color(0xFF00B4D8),
              () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AppointmentsHistoryScreen()),
              ),
            ),
            SizedBox(height: screenWidth * 0.04),
            _buildNavigationCard(
              'Prescriptions',
              Icons.medication,
              const Color(0xFF0077B6),
              () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const PrescriptionsScreen()),
              ),
            ),
            SizedBox(height: screenWidth * 0.04),
            _buildNavigationCard(
              'Medical Reports',
              Icons.description,
              const Color(0xFF023E8A),
              () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ReportsScreen()),
              ),
            ),
            SizedBox(height: screenWidth * 0.04),
            _buildNavigationCard(
              'AI Health Assessments',
              Icons.psychology,
              const Color(0xFF0096C7),
              () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AiAssessmentsScreen()),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavigationCard(String title, IconData icon, Color color, VoidCallback onTap) {
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
          color: color,
          size: screenWidth * 0.06,
        ),
        title: Text(
          title,
          style: TextStyle(
            fontSize: screenWidth * 0.045,
            fontWeight: FontWeight.w600,
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


}