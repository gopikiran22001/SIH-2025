import 'package:flutter/material.dart';
import '../../services/supabase_service.dart';
import '../../services/local_storage_service.dart';

class PrescriptionsScreen extends StatefulWidget {
  const PrescriptionsScreen({super.key});

  @override
  State<PrescriptionsScreen> createState() => _PrescriptionsScreenState();
}

class _PrescriptionsScreenState extends State<PrescriptionsScreen> {
  List<Map<String, dynamic>> _prescriptions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPrescriptions();
  }

  Future<void> _loadPrescriptions() async {
    try {
      // First load from cache for immediate display
      final cachedPrescriptions = LocalStorageService.getCachedPrescriptions();
      if (mounted && cachedPrescriptions.isNotEmpty) {
        setState(() {
          _prescriptions = cachedPrescriptions;
          _isLoading = false;
        });
      }
      
      // Then try to sync from server
      final user = SupabaseService.currentUser;
      if (user != null) {
        try {
          final prescriptions = await SupabaseService.getPrescriptions(user.id);
          await LocalStorageService.cachePrescriptions(prescriptions);
          
          if (mounted) {
            setState(() {
              _prescriptions = prescriptions;
              _isLoading = false;
            });
          }
        } catch (e) {
          print('DEBUG: Failed to load prescriptions from server, using cached data: $e');
          if (mounted && _prescriptions.isEmpty) {
            setState(() => _isLoading = false);
          }
        }
      } else {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    } catch (e) {
      print('DEBUG: Error loading prescriptions: $e');
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
        title: const Text('Prescriptions'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _prescriptions.isEmpty
              ? Center(
                  child: Text(
                    'No prescriptions yet',
                    style: TextStyle(
                      fontSize: screenWidth * 0.04,
                      color: Colors.grey[600],
                    ),
                  ),
                )
              : ListView.builder(
                  padding: EdgeInsets.all(screenWidth * 0.04),
                  itemCount: _prescriptions.length,
                  itemBuilder: (context, index) {
                    final prescription = _prescriptions[index];
                    final date = DateTime.parse(prescription['created_at']);
                    final doctorName = prescription['profiles']?['full_name'] ?? 'Unknown Doctor';
                    
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
                                Icons.medication,
                                color: const Color(0xFFEF4444),
                                size: screenWidth * 0.05,
                              ),
                              SizedBox(width: screenWidth * 0.03),
                              Expanded(
                                child: Text(
                                  'Dr. $doctorName',
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
                            '${date.day}/${date.month}/${date.year}',
                            style: TextStyle(
                              fontSize: screenWidth * 0.035,
                              color: Colors.grey[600],
                            ),
                          ),
                          SizedBox(height: screenWidth * 0.02),
                          Text(
                            prescription['content'] ?? 'No prescription content',
                            style: TextStyle(fontSize: screenWidth * 0.035),
                          ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}