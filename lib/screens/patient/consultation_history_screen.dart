import 'package:flutter/material.dart';
import '../../services/video_consultation_service.dart';
import '../../services/supabase_service.dart';
import '../../services/local_storage_service.dart';

class ConsultationHistoryScreen extends StatefulWidget {
  const ConsultationHistoryScreen({super.key});

  @override
  State<ConsultationHistoryScreen> createState() => _ConsultationHistoryScreenState();
}

class _ConsultationHistoryScreenState extends State<ConsultationHistoryScreen> {
  List<Map<String, dynamic>> _consultations = [];
  List<Map<String, dynamic>> _prescriptions = [];
  bool _isLoading = true;
  int _selectedTab = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final userId = LocalStorageService.getCurrentUserId();
      if (userId == null) return;

      final consultations = await VideoConsultationService.getConsultations(userId, 'patient');
      final prescriptions = await SupabaseService.getPrescriptions(userId);

      setState(() {
        _consultations = consultations;
        _prescriptions = prescriptions;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading data: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Consultation History'),
        bottom: TabBar(
          controller: TabController(length: 2, vsync: Scaffold.of(context)),
          tabs: const [
            Tab(text: 'Consultations'),
            Tab(text: 'Prescriptions'),
          ],
          onTap: (index) => setState(() => _selectedTab = index),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: TabController(length: 2, vsync: Scaffold.of(context)),
              children: [
                _buildConsultationsTab(),
                _buildPrescriptionsTab(),
              ],
            ),
    );
  }

  Widget _buildConsultationsTab() {
    if (_consultations.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.video_call_outlined, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('No consultations yet'),
            Text('Start your first video consultation with a doctor'),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _consultations.length,
      itemBuilder: (context, index) {
        final consultation = _consultations[index];
        return _buildConsultationCard(consultation);
      },
    );
  }

  Widget _buildConsultationCard(Map<String, dynamic> consultation) {
    final doctorName = consultation['profiles']?['full_name'] ?? 'Unknown Doctor';
    final status = consultation['status'];
    final createdAt = DateTime.parse(consultation['created_at']);
    final symptoms = consultation['symptoms'] ?? 'No symptoms recorded';

    Color statusColor;
    IconData statusIcon;
    switch (status) {
      case 'completed':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      case 'active':
        statusColor = Colors.blue;
        statusIcon = Icons.video_call;
        break;
      default:
        statusColor = Colors.orange;
        statusIcon = Icons.pending;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(statusIcon, color: statusColor, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Dr. $doctorName',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Text(
                  status.toUpperCase(),
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Date: ${createdAt.day}/${createdAt.month}/${createdAt.year} at ${createdAt.hour}:${createdAt.minute.toString().padLeft(2, '0')}',
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 8),
            Text(
              'Symptoms: $symptoms',
              style: const TextStyle(fontSize: 14),
            ),
            if (consultation['started_at'] != null && consultation['ended_at'] != null) ...[
              const SizedBox(height: 8),
              Text(
                'Duration: ${_calculateDuration(consultation['started_at'], consultation['ended_at'])}',
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPrescriptionsTab() {
    if (_prescriptions.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.medical_services_outlined, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('No prescriptions yet'),
            Text('Prescriptions from consultations will appear here'),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _prescriptions.length,
      itemBuilder: (context, index) {
        final prescription = _prescriptions[index];
        return _buildPrescriptionCard(prescription);
      },
    );
  }

  Widget _buildPrescriptionCard(Map<String, dynamic> prescription) {
    final doctorName = prescription['profiles']?['full_name'] ?? 'Unknown Doctor';
    final content = prescription['content'] ?? 'No prescription details';
    final createdAt = DateTime.parse(prescription['created_at']);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.medical_services, color: Colors.blue, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Dr. $doctorName',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Text(
                  '${createdAt.day}/${createdAt.month}/${createdAt.year}',
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
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
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Text(
                content,
                style: const TextStyle(fontSize: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _calculateDuration(String startTime, String endTime) {
    final start = DateTime.parse(startTime);
    final end = DateTime.parse(endTime);
    final duration = end.difference(start);
    
    final minutes = duration.inMinutes;
    if (minutes < 60) {
      return '${minutes}m';
    } else {
      final hours = duration.inHours;
      final remainingMinutes = minutes % 60;
      return '${hours}h ${remainingMinutes}m';
    }
  }
}