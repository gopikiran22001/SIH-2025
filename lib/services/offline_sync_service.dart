import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:hive/hive.dart';
import 'supabase_service.dart';
import 'local_storage_service.dart';

class OfflineSyncService {
  static final OfflineSyncService _instance = OfflineSyncService._internal();
  factory OfflineSyncService() => _instance;
  OfflineSyncService._internal();

  late Box _offlineBox;
  bool _isOnline = true;
  bool _isInitialized = false;

  Future<void> init() async {
    if (_isInitialized) return;
    
    _offlineBox = await Hive.openBox('offline_operations');
    await _checkInitialConnectivity();
    _monitorConnectivity();
    _isInitialized = true;
    
    print('DEBUG: OfflineSyncService initialized, isOnline: $_isOnline');
  }

  Future<void> _checkInitialConnectivity() async {
    try {
      final result = await Connectivity().checkConnectivity().timeout(const Duration(seconds: 5));
      _isOnline = !result.contains(ConnectivityResult.none);
      
      if (_isOnline) {
        await _syncAllUserData();
      }
    } on TimeoutException {
      _isOnline = false;
      print('DEBUG: Connectivity check timeout - assuming offline');
    } catch (e) {
      _isOnline = false;
      print('DEBUG: Failed to check connectivity: $e');
    }
  }

  void _monitorConnectivity() {
    Connectivity().onConnectivityChanged.listen((result) {
      final wasOffline = !_isOnline;
      _isOnline = !result.contains(ConnectivityResult.none);
      
      print('DEBUG: Connectivity changed - isOnline: $_isOnline');
      
      if (wasOffline && _isOnline) {
        print('DEBUG: Coming back online, syncing data and offline operations...');
        Future.delayed(const Duration(seconds: 2), () async {
          try {
            await _syncAllUserData();
            await _syncOfflineOperations();
          } catch (e) {
            print('DEBUG: Error during connectivity sync: $e');
          }
        });
      }
    });
  }

  Future<void> queueOperation(String type, Map<String, dynamic> data) async {
    final operation = {
      'type': type,
      'data': data,
      'timestamp': DateTime.now().toIso8601String(),
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
    };
    
    await _offlineBox.add(operation);
    print('DEBUG: Queued offline operation: $type with data: $data');
    print('DEBUG: Total offline operations in queue: ${_offlineBox.length}');
  }

  Future<void> _syncAllUserData() async {
    try {
      final user = SupabaseService.currentUser;
      if (user == null) {
        print('DEBUG: No user found for sync');
        return;
      }
      
      print('DEBUG: Syncing all user data for ${user.id}');
      
      // Sync profile data
      try {
        final profile = await SupabaseService.getProfile(user.id);
        if (profile != null) {
          await LocalStorageService.saveCurrentUser(profile);
          print('DEBUG: Profile synced successfully');
        }
      } catch (e) {
        print('DEBUG: Failed to sync profile: $e');
      }
      
      // Determine user role for appointments
      final currentUser = LocalStorageService.getCurrentUser();
      final userRole = currentUser?['role'] ?? 'patient';
      
      // Sync ALL appointments for complete offline access
      try {
        final appointments = await SupabaseService.getAppointments(user.id, userRole);
        await LocalStorageService.cacheAppointments(appointments);
        print('DEBUG: All appointments synced: ${appointments.length}');
      } catch (e) {
        print('DEBUG: Failed to sync appointments: $e');
      }
      
      // Sync ALL chat conversations and messages
      try {
        final conversations = await SupabaseService.getConversations(user.id);
        for (final conversation in conversations) {
          final conversationId = conversation['id'];
          final messages = await SupabaseService.getMessages(conversationId);
          await LocalStorageService.cacheMessages(conversationId, messages);
        }
        print('DEBUG: All conversations and messages synced');
      } catch (e) {
        print('DEBUG: Failed to sync messages: $e');
      }
      
      // Sync data based on user role
      if (userRole == 'patient') {
        // Sync ALL AI assessments
        try {
          final assessments = await SupabaseService.getAiAssessments(user.id);
          await LocalStorageService.cacheAiAssessments(assessments);
          print('DEBUG: All AI assessments synced: ${assessments.length}');
        } catch (e) {
          print('DEBUG: Failed to sync AI assessments: $e');
        }
        
        // Sync ALL prescriptions
        try {
          final prescriptions = await SupabaseService.getPrescriptions(user.id);
          await LocalStorageService.cachePrescriptions(prescriptions);
          print('DEBUG: All prescriptions synced: ${prescriptions.length}');
        } catch (e) {
          print('DEBUG: Failed to sync prescriptions: $e');
        }
        
        // Sync ALL medical records
        try {
          final medicalRecords = await SupabaseService.getMedicalRecords(user.id);
          final medicalHistory = {
            'records': medicalRecords,
            'last_updated': DateTime.now().toIso8601String(),
          };
          await LocalStorageService.cacheMedicalHistory(user.id, medicalHistory);
          print('DEBUG: All medical records synced: ${medicalRecords.length}');
        } catch (e) {
          print('DEBUG: Failed to sync medical records: $e');
        }
        
        // Sync ALL medical reports
        try {
          final reports = await SupabaseService.getPatientReports(user.id);
          await LocalStorageService.cacheReports(reports);
          print('DEBUG: All medical reports synced: ${reports.length}');
        } catch (e) {
          print('DEBUG: Failed to sync medical reports: $e');
        }
      } else if (userRole == 'doctor') {
        // Sync doctor-specific data like patient lists, consultations
        try {
          final consultations = await SupabaseService.getDoctorConsultations(user.id);
          // Cache consultations as appointments for doctors
          await LocalStorageService.cacheAppointments(consultations);
          print('DEBUG: All doctor consultations synced: ${consultations.length}');
        } catch (e) {
          print('DEBUG: Failed to sync doctor consultations: $e');
        }
      }
      
      print('DEBUG: Complete user data sync finished');
    } catch (e) {
      print('DEBUG: Failed to sync user data: $e');
    }
  }

  Future<void> _syncOfflineOperations() async {
    final operations = _offlineBox.values.toList();
    print('DEBUG: Syncing ${operations.length} offline operations');
    
    if (operations.isEmpty) {
      print('DEBUG: No offline operations to sync');
      return;
    }
    
    final keysToDelete = <dynamic>[];
    
    for (int i = 0; i < operations.length; i++) {
      try {
        final operation = Map<String, dynamic>.from(operations[i]);
        print('DEBUG: Processing offline operation: ${operation['type']} with data: ${operation['data']}');
        await _processOperation(operation);
        keysToDelete.add(_offlineBox.keyAt(i));
        print('DEBUG: Successfully synced operation: ${operation['type']}');
      } catch (e) {
        print('DEBUG: Sync error for operation ${i} (${operations[i]['type']}): $e');
        // Don't delete failed operations, they will be retried next time
      }
    }
    
    // Delete successfully synced operations
    for (final key in keysToDelete) {
      await _offlineBox.delete(key);
    }
    
    print('DEBUG: Offline operations sync completed. Synced: ${keysToDelete.length}, Failed: ${operations.length - keysToDelete.length}');
  }

  Future<void> _processOperation(Map<String, dynamic> operation) async {
    final type = operation['type'];
    final data = Map<String, dynamic>.from(operation['data']);
    
    print('DEBUG: Processing operation type: $type');
    
    switch (type) {
      case 'create_appointment':
        print('DEBUG: Syncing appointment creation');
        await SupabaseService.createAppointment(data);
        break;
      case 'send_message':
        print('DEBUG: Syncing message');
        await SupabaseService.sendMessage(data);
        break;
      case 'create_ai_assessment':
        print('DEBUG: Syncing AI assessment');
        await SupabaseService.createAiAssessment(data);
        break;
      case 'create_prescription':
        print('DEBUG: Syncing prescription');
        await SupabaseService.createPrescription(data);
        break;
      case 'create_report':
        print('DEBUG: Syncing medical report');
        await SupabaseService.createReport(data);
        break;
      case 'update_report':
        print('DEBUG: Syncing report update');
        final reportId = data['report_id'];
        final reportData = Map<String, dynamic>.from(data);
        reportData.remove('report_id');
        await SupabaseService.updateReport(reportId, reportData);
        break;
      case 'delete_report':
        print('DEBUG: Syncing report deletion');
        await SupabaseService.deleteReport(data['report_id']);
        break;
      case 'update_profile':
        print('DEBUG: Syncing profile update for user: ${data['user_id']}');
        final userId = data['user_id'];
        final profileData = Map<String, dynamic>.from(data);
        profileData.remove('user_id'); // Remove user_id from data before update
        await SupabaseService.updateProfile(userId, profileData);
        print('DEBUG: Profile update synced successfully');
        break;
      default:
        print('DEBUG: Unknown operation type: $type');
        throw Exception('Unknown operation type: $type');
    }
  }

  bool get isOnline => _isOnline;
  
  // Queue profile update for offline sync
  Future<void> queueProfileUpdate(String userId, Map<String, dynamic> data) async {
    final updateData = Map<String, dynamic>.from(data);
    updateData['user_id'] = userId;
    print('DEBUG: Queueing profile update for user: $userId');
    print('DEBUG: Profile update data: $updateData');
    await queueOperation('update_profile', updateData);
    print('DEBUG: Profile update queued successfully');
  }
  
  // Queue report operations for offline sync
  Future<void> queueReportCreate(Map<String, dynamic> data) async {
    print('DEBUG: Queueing report creation');
    await queueOperation('create_report', data);
  }
  
  Future<void> queueReportUpdate(String reportId, Map<String, dynamic> data) async {
    final updateData = Map<String, dynamic>.from(data);
    updateData['report_id'] = reportId;
    print('DEBUG: Queueing report update for ID: $reportId');
    await queueOperation('update_report', updateData);
  }
  
  Future<void> queueReportDelete(String reportId) async {
    print('DEBUG: Queueing report deletion for ID: $reportId');
    await queueOperation('delete_report', {'report_id': reportId});
  }
  
  // Manual sync trigger
  Future<void> syncNow() async {
    if (!_isInitialized) {
      print('DEBUG: Initializing sync service before manual sync');
      await init();
    }
    
    print('DEBUG: Manual sync triggered - isOnline: $_isOnline');
    print('DEBUG: Offline operations count before sync: ${_offlineBox.length}');
    
    if (_isOnline) {
      print('DEBUG: Starting manual sync - syncing user data and offline operations');
      await _syncAllUserData();
      await _syncOfflineOperations();
      print('DEBUG: Manual sync completed');
    } else {
      print('DEBUG: Cannot sync - device is offline');
    }
  }
  
  // Force sync on login
  Future<void> syncOnLogin() async {
    print('DEBUG: Syncing data on login');
    await _checkInitialConnectivity();
  }
  
  // Clear offline operations on logout
  Future<void> clearOfflineData() async {
    if (!_isInitialized) return;
    
    await _offlineBox.clear();
    print('DEBUG: Offline operations cleared on logout');
  }
  
  // Debug method to check offline operations
  Future<void> debugOfflineOperations() async {
    if (!_isInitialized) {
      print('DEBUG: Offline sync not initialized');
      return;
    }
    
    final operations = _offlineBox.values.toList();
    print('DEBUG: Current offline operations count: ${operations.length}');
    
    for (int i = 0; i < operations.length; i++) {
      final operation = operations[i];
      print('DEBUG: Operation $i: ${operation['type']} - ${operation['timestamp']}');
    }
  }
}