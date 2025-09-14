import 'package:flutter/material.dart';
import '../../services/supabase_service.dart';
import '../../services/local_storage_service.dart';

class DoctorConsultationsTab extends StatefulWidget {
  const DoctorConsultationsTab({super.key});

  @override
  State<DoctorConsultationsTab> createState() => _DoctorConsultationsTabState();
}

class _DoctorConsultationsTabState extends State<DoctorConsultationsTab> {
  List<Map<String, dynamic>> _consultations = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadConsultations();
  }

  Future<void> _loadConsultations() async {
    try {
      final userId = LocalStorageService.getCurrentUserId();
      if (userId == null) return;

      final consultations = await SupabaseService.getConsultationHistory(userId, 'doctor');
      
      // Check for new pending consultations and show notification
      final pendingCount = consultations.where((c) => c['status'] == 'pending').length;
      if (pendingCount > 0 && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('You have $pendingCount new consultation request${pendingCount > 1 ? 's' : ''}'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      }
      
      setState(() {
        _consultations = consultations;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading consultations: $e')),
      );
    }
  }

  Future<void> _joinConsultation(Map<String, dynamic> consultation) async {
    try {
      final currentUser = LocalStorageService.getCurrentUser();
      if (currentUser == null) return;
      
      // Fetch full consultation data including tokens
      final fullConsultation = await SupabaseService.client
          .from('video_consultations')
          .select('*')
          .eq('id', consultation['id'])
          .single();
      
      print('DEBUG: Full consultation data: $fullConsultation');
      print('DEBUG: Doctor token: ${fullConsultation['doctor_token']}');
      
      Navigator.pushNamed(
        context,
        '/video-consultation/${consultation['id']}',
        arguments: {
          'consultationId': consultation['id'],
          'patientId': consultation['patient_id'],
          'doctorId': consultation['doctor_id'],
          'patientName': consultation['patient_name'] ?? 'Patient',
          'doctorName': currentUser['full_name'] ?? 'Doctor',
          'roomId': fullConsultation['channel_name'],
          'authToken': fullConsultation['doctor_token'],
        },
      );
    } catch (e) {
      print('DEBUG: Failed to join consultation: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to join consultation: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _consultations.isEmpty
              ? _buildEmptyState()
              : _buildConsultationsList(),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.video_call_outlined, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'No consultations yet',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text(
            'Patient consultation requests will appear here',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildConsultationsList() {
    // Group consultations by status
    final pendingConsultations = _consultations.where((c) => c['status'] == 'pending').toList();
    final activeConsultations = _consultations.where((c) => c['status'] == 'active').toList();
    final completedConsultations = _consultations.where((c) => c['status'] == 'completed').toList();

    return RefreshIndicator(
      onRefresh: _loadConsultations,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (pendingConsultations.isNotEmpty) ...[
            _buildSectionHeader('Pending Requests', pendingConsultations.length, Colors.orange),
            ...pendingConsultations.map((consultation) => _buildConsultationCard(consultation, 'pending')),
            const SizedBox(height: 16),
          ],
          if (activeConsultations.isNotEmpty) ...[
            _buildSectionHeader('Active Consultations', activeConsultations.length, Colors.green),
            ...activeConsultations.map((consultation) => _buildConsultationCard(consultation, 'active')),
            const SizedBox(height: 16),
          ],
          if (completedConsultations.isNotEmpty) ...[
            _buildSectionHeader('Completed', completedConsultations.length, Colors.grey),
            ...completedConsultations.map((consultation) => _buildConsultationCard(consultation, 'completed')),
          ],
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, int count, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 20,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '$title ($count)',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConsultationCard(Map<String, dynamic> consultation, String status) {
    final patientName = consultation['patient_name'] ?? 'Unknown Patient';
    final symptoms = consultation['symptoms'] ?? 'No symptoms provided';
    final createdAt = DateTime.parse(consultation['created_at']);

    Color statusColor;
    IconData statusIcon;
    String actionText;
    
    switch (status) {
      case 'pending':
        statusColor = Colors.orange;
        statusIcon = Icons.pending;
        actionText = 'Join Consultation';
        break;
      case 'active':
        statusColor = Colors.green;
        statusIcon = Icons.video_call;
        actionText = 'Rejoin Consultation';
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.check_circle;
        actionText = 'View Details';
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: statusColor.withOpacity(0.1),
                  child: Icon(statusIcon, color: statusColor, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        patientName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${createdAt.day}/${createdAt.month}/${createdAt.year} at ${createdAt.hour}:${createdAt.minute.toString().padLeft(2, '0')}',
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
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
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Symptoms:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    symptoms,
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: status == 'completed' ? null : () => _joinConsultation(consultation),
                icon: Icon(status == 'active' ? Icons.video_call : Icons.play_arrow),
                label: Text(actionText),
                style: ElevatedButton.styleFrom(
                  backgroundColor: status == 'active' ? Colors.green : null,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}