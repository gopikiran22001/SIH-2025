import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../../services/supabase_service.dart';
import '../../services/local_storage_service.dart';
import '../../services/offline_sync_service.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  List<Map<String, dynamic>> _reports = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadReports();
  }

  Future<void> _loadReports() async {
    try {
      final userId = LocalStorageService.getCurrentUserId();
      if (userId == null) return;

      // Always load from cache first for immediate display
      final cachedReports = LocalStorageService.getCachedReports();
      if (mounted) {
        setState(() {
          _reports = cachedReports;
          _isLoading = false;
        });
      }

      // Try to sync from server if online
      final syncService = OfflineSyncService();
      if (syncService.isOnline) {
        try {
          final reports = await SupabaseService.getPatientReports(userId);
          await LocalStorageService.cacheReports(reports);
          
          if (mounted) {
            setState(() {
              _reports = reports;
            });
          }
        } catch (e) {
          print('DEBUG: Failed to sync reports from server: $e');
        }
      }
    } catch (e) {
      print('DEBUG: Error loading reports: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _addReport() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => const AddReportDialog(),
    );

    if (result != null) {
      try {
        final userId = LocalStorageService.getCurrentUserId();
        if (userId == null) return;

        final reportData = {
          'patient_id': userId,
          'title': result['title'],
          'description': result['description'],
          'report_type': result['report_type'],
          'report_date': result['report_date'],
          'file_name': result['file_name'],
        };

        final syncService = OfflineSyncService();
        
        if (syncService.isOnline) {
          try {
            final createdReport = await SupabaseService.createReport(reportData);
            await LocalStorageService.cacheReport(createdReport);
          } catch (e) {
            // If online creation fails, save offline
            final localReport = Map<String, dynamic>.from(reportData);
            localReport['id'] = 'offline_${DateTime.now().millisecondsSinceEpoch}';
            localReport['created_at'] = DateTime.now().toIso8601String();
            await LocalStorageService.cacheReport(localReport);
            await syncService.queueReportCreate(reportData);
          }
        } else {
          // Create local report with offline ID
          final localReport = Map<String, dynamic>.from(reportData);
          localReport['id'] = 'offline_${DateTime.now().millisecondsSinceEpoch}';
          localReport['created_at'] = DateTime.now().toIso8601String();
          await LocalStorageService.cacheReport(localReport);
          await syncService.queueReportCreate(reportData);
        }
        
        _loadReports();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(syncService.isOnline 
                  ? 'Report added successfully' 
                  : 'Report saved offline. Will sync when connected.'),
              backgroundColor: syncService.isOnline ? Colors.green : Colors.orange,
            ),
          );
        }
      } catch (e) {
        print('DEBUG: Failed to add report: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Unable to save report. Please try again.')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final syncService = OfflineSyncService();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Medical Reports'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          if (!syncService.isOnline)
            Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.orange,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.cloud_off, color: Colors.white, size: 16),
                  SizedBox(width: 4),
                  Text('Offline', style: TextStyle(color: Colors.white, fontSize: 12)),
                ],
              ),
            ),
          IconButton(
            onPressed: _addReport,
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _reports.isEmpty
              ? _buildEmptyState()
              : _buildReportsList(),
    );
  }

  Widget _buildEmptyState() {
    final screenWidth = MediaQuery.of(context).size.width;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.description_outlined,
            size: screenWidth * 0.15,
            color: Colors.grey[400],
          ),
          SizedBox(height: screenWidth * 0.04),
          Text(
            'No Reports Yet',
            style: TextStyle(
              fontSize: screenWidth * 0.05,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: screenWidth * 0.02),
          Text(
            'Add your medical reports to keep track of your health records',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: screenWidth * 0.035,
              color: Colors.grey[500],
            ),
          ),
          SizedBox(height: screenWidth * 0.06),
          ElevatedButton.icon(
            onPressed: _addReport,
            icon: const Icon(Icons.add),
            label: const Text('Add Report'),
          ),
        ],
      ),
    );
  }

  Widget _buildReportsList() {
    final screenWidth = MediaQuery.of(context).size.width;

    return RefreshIndicator(
      onRefresh: _loadReports,
      child: ListView.builder(
        padding: EdgeInsets.all(screenWidth * 0.04),
        itemCount: _reports.length,
        itemBuilder: (context, index) {
          final report = _reports[index];
          return _buildReportCard(report, screenWidth);
        },
      ),
    );
  }

  Widget _buildReportCard(Map<String, dynamic> report, double screenWidth) {
    final reportDate = DateTime.parse(report['report_date']);
    final createdAt = DateTime.parse(report['created_at']);
    final isOfflineReport = report['id'].toString().startsWith('offline_');

    return Card(
      margin: EdgeInsets.only(bottom: screenWidth * 0.03),
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(screenWidth * 0.04),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _getReportTypeIcon(report['report_type']),
                SizedBox(width: screenWidth * 0.03),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              report['title'] ?? 'Untitled Report',
                              style: TextStyle(
                                fontSize: screenWidth * 0.04,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          if (isOfflineReport)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.orange,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'Offline',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: screenWidth * 0.025,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                        ],
                      ),
                      Text(
                        _formatReportType(report['report_type']),
                        style: TextStyle(
                          fontSize: screenWidth * 0.03,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton(
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'view',
                      child: Row(
                        children: [
                          Icon(Icons.visibility),
                          SizedBox(width: 8),
                          Text('View'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Delete', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                  onSelected: (value) => _handleReportAction(value, report),
                ),
              ],
            ),
            if (report['description'] != null && report['description'].isNotEmpty) ...[
              SizedBox(height: screenWidth * 0.02),
              Text(
                report['description'],
                style: TextStyle(
                  fontSize: screenWidth * 0.035,
                  color: Colors.grey[700],
                ),
              ),
            ],
            SizedBox(height: screenWidth * 0.03),
            Row(
              children: [
                Icon(Icons.calendar_today, size: screenWidth * 0.035, color: Colors.grey[600]),
                SizedBox(width: screenWidth * 0.01),
                Text(
                  'Report Date: ${reportDate.day}/${reportDate.month}/${reportDate.year}',
                  style: TextStyle(
                    fontSize: screenWidth * 0.03,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            if (report['file_name'] != null) ...[
              SizedBox(height: screenWidth * 0.01),
              Row(
                children: [
                  Icon(Icons.attach_file, size: screenWidth * 0.035, color: Colors.grey[600]),
                  SizedBox(width: screenWidth * 0.01),
                  Expanded(
                    child: Text(
                      report['file_name'],
                      style: TextStyle(
                        fontSize: screenWidth * 0.03,
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _getReportTypeIcon(String? type) {
    final screenWidth = MediaQuery.of(context).size.width;
    
    IconData icon;
    Color color;
    
    switch (type) {
      case 'lab_test':
        icon = Icons.science;
        color = Colors.blue;
        break;
      case 'imaging':
        icon = Icons.medical_services;
        color = Colors.green;
        break;
      case 'prescription':
        icon = Icons.medication;
        color = Colors.orange;
        break;
      case 'consultation':
        icon = Icons.person_outline;
        color = Colors.purple;
        break;
      default:
        icon = Icons.description;
        color = Colors.grey;
    }

    return CircleAvatar(
      radius: screenWidth * 0.04,
      backgroundColor: color.withOpacity(0.1),
      child: Icon(icon, color: color, size: screenWidth * 0.04),
    );
  }

  String _formatReportType(String? type) {
    switch (type) {
      case 'lab_test':
        return 'Lab Test';
      case 'imaging':
        return 'Imaging';
      case 'prescription':
        return 'Prescription';
      case 'consultation':
        return 'Consultation';
      default:
        return 'Other';
    }
  }

  void _handleReportAction(String action, Map<String, dynamic> report) {
    switch (action) {
      case 'view':
        _viewReport(report);
        break;
      case 'delete':
        _deleteReport(report);
        break;
    }
  }

  void _viewReport(Map<String, dynamic> report) {
    showDialog(
      context: context,
      builder: (context) => ReportDetailsDialog(report: report),
    );
  }

  Future<void> _deleteReport(Map<String, dynamic> report) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Report'),
        content: const Text('Are you sure you want to delete this report?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final syncService = OfflineSyncService();
        final reportId = report['id'];
        
        // Remove from local cache immediately
        final userId = LocalStorageService.getCurrentUserId();
        if (userId != null) {
          final reports = LocalStorageService.getCachedReports();
          reports.removeWhere((r) => r['id'] == reportId);
          await LocalStorageService.cacheReports(reports);
        }
        
        if (syncService.isOnline && !reportId.startsWith('offline_')) {
          try {
            await SupabaseService.deleteReport(reportId);
          } catch (e) {
            // If online deletion fails, queue it
            await syncService.queueReportDelete(reportId);
          }
        } else if (!reportId.startsWith('offline_')) {
          // Queue for deletion when online
          await syncService.queueReportDelete(reportId);
        }
        
        _loadReports();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(syncService.isOnline && !reportId.startsWith('offline_')
                  ? 'Report deleted successfully' 
                  : 'Report deleted locally. Will sync when connected.'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        print('DEBUG: Failed to delete report: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Unable to delete report. Please try again.')),
          );
        }
      }
    }
  }
}

class AddReportDialog extends StatefulWidget {
  const AddReportDialog({super.key});

  @override
  State<AddReportDialog> createState() => _AddReportDialogState();
}

class _AddReportDialogState extends State<AddReportDialog> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  String _selectedType = 'lab_test';
  DateTime _selectedDate = DateTime.now();
  String? _selectedFileName;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: screenWidth * 0.9,
        constraints: BoxConstraints(maxHeight: screenHeight * 0.8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white,
              const Color(0xFFF8FAFC),
            ],
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: EdgeInsets.all(screenWidth * 0.05),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF00B4D8), Color(0xFF0077B6)],
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.add_circle_outline, color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Add Medical Report',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            // Content
            Flexible(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(screenWidth * 0.05),
                child: Column(
                  children: [
                    _buildInputField(
                      controller: _titleController,
                      label: 'Report Title',
                      icon: Icons.title,
                      hint: 'Enter report title',
                    ),
                    SizedBox(height: screenWidth * 0.04),
                    _buildInputField(
                      controller: _descriptionController,
                      label: 'Description',
                      icon: Icons.description,
                      hint: 'Add description (optional)',
                      maxLines: 3,
                    ),
                    SizedBox(height: screenWidth * 0.04),
                    _buildTypeSelector(),
                    SizedBox(height: screenWidth * 0.04),
                    _buildDateSelector(),
                    SizedBox(height: screenWidth * 0.04),
                    _buildFileAttachment(),
                  ],
                ),
              ),
            ),
            // Actions
            Container(
              padding: EdgeInsets.all(screenWidth * 0.05),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side: const BorderSide(color: Color(0xFF64748B)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text('Cancel', style: TextStyle(color: Color(0xFF64748B))),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _saveReport,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00B4D8),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        elevation: 2,
                      ),
                      child: const Text('Save Report', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required String hint,
    int maxLines = 1,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: Icon(icon, color: const Color(0xFF00B4D8)),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }

  Widget _buildTypeSelector() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: DropdownButtonFormField<String>(
        value: _selectedType,
        isExpanded: true,
        decoration: InputDecoration(
          labelText: 'Report Type',
          prefixIcon: const Icon(Icons.category, color: Color(0xFF00B4D8)),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
        items: [
          _buildDropdownItem('lab_test', 'Lab Test', Icons.science, Colors.blue),
          _buildDropdownItem('imaging', 'Imaging', Icons.medical_services, Colors.green),
          _buildDropdownItem('prescription', 'Prescription', Icons.medication, Colors.orange),
          _buildDropdownItem('consultation', 'Consultation', Icons.person_outline, Colors.purple),
          _buildDropdownItem('other', 'Other', Icons.description, Colors.grey),
        ],
        onChanged: (value) => setState(() => _selectedType = value!),
      ),
    );
  }

  DropdownMenuItem<String> _buildDropdownItem(String value, String label, IconData icon, Color color) {
    final screenWidth = MediaQuery.of(context).size.width;
    
    return DropdownMenuItem(
      value: value,
      child: Row(
        children: [
          Icon(icon, color: color, size: screenWidth * 0.045),
          SizedBox(width: screenWidth * 0.025),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: screenWidth * 0.035,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateSelector() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: _selectDate,
        borderRadius: BorderRadius.circular(12),
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: 'Report Date',
            prefixIcon: const Icon(Icons.calendar_today, color: Color(0xFF00B4D8)),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}'),
              const Icon(Icons.arrow_drop_down, color: Color(0xFF64748B)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFileAttachment() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _selectedFileName != null ? const Color(0xFF00B4D8) : const Color(0xFFE2E8F0),
          width: 2,
        ),
      ),
      child: InkWell(
        onTap: _pickFile,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(
                _selectedFileName != null ? Icons.attach_file : Icons.cloud_upload_outlined,
                color: _selectedFileName != null ? const Color(0xFF00B4D8) : const Color(0xFF64748B),
                size: 32,
              ),
              const SizedBox(height: 8),
              Text(
                _selectedFileName ?? 'Attach File (Optional)',
                style: TextStyle(
                  color: _selectedFileName != null ? const Color(0xFF00B4D8) : const Color(0xFF64748B),
                  fontWeight: _selectedFileName != null ? FontWeight.w600 : FontWeight.normal,
                ),
                textAlign: TextAlign.center,
              ),
              if (_selectedFileName == null) ...[
                const SizedBox(height: 4),
                const Text(
                  'PDF, JPG, PNG, DOC files supported',
                  style: TextStyle(
                    color: Color(0xFF94A3B8),
                    fontSize: 12,
                  ),
                ),
              ]
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF00B4D8),
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    if (date != null) {
      setState(() => _selectedDate = date);
    }
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png', 'doc', 'docx'],
    );

    if (result != null) {
      setState(() => _selectedFileName = result.files.first.name);
    }
  }

  void _saveReport() {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a report title')),
      );
      return;
    }

    Navigator.pop(context, {
      'title': _titleController.text.trim(),
      'description': _descriptionController.text.trim(),
      'report_type': _selectedType,
      'report_date': _selectedDate.toIso8601String().split('T')[0],
      'file_name': _selectedFileName,
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
}

class ReportDetailsDialog extends StatelessWidget {
  final Map<String, dynamic> report;

  const ReportDetailsDialog({super.key, required this.report});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final reportDate = DateTime.parse(report['report_date']);
    final createdAt = DateTime.parse(report['created_at']);

    return AlertDialog(
      title: Text(report['title'] ?? 'Report Details'),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('Type', _formatReportType(report['report_type'])),
            _buildDetailRow('Report Date', '${reportDate.day}/${reportDate.month}/${reportDate.year}'),
            if (report['description'] != null && report['description'].isNotEmpty)
              _buildDetailRow('Description', report['description']),
            if (report['file_name'] != null)
              _buildDetailRow('Attached File', report['file_name']),
            _buildDetailRow('Added On', '${createdAt.day}/${createdAt.month}/${createdAt.year}'),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label:',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(value),
        ],
      ),
    );
  }

  String _formatReportType(String? type) {
    switch (type) {
      case 'lab_test':
        return 'Lab Test';
      case 'imaging':
        return 'Imaging';
      case 'prescription':
        return 'Prescription';
      case 'consultation':
        return 'Consultation';
      default:
        return 'Other';
    }
  }
}