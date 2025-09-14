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
        print('DEBUG: Coming back online, syncing data...');
        _syncAllUserData();
        _syncOfflineOperations();
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
    print('DEBUG: Queued offline operation: $type');
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
      
      // Sync appointments
      try {
        final appointments = await SupabaseService.getAppointments(user.id, userRole);
        await LocalStorageService.cacheAppointments(appointments);
        print('DEBUG: Appointments synced: ${appointments.length}');
      } catch (e) {
        print('DEBUG: Failed to sync appointments: $e');
      }
      
      // Sync AI assessments (only for patients)
      if (userRole == 'patient') {
        try {
          final assessments = await SupabaseService.getAiAssessments(user.id);
          await LocalStorageService.cacheAiAssessments(assessments);
          print('DEBUG: AI assessments synced: ${assessments.length}');
        } catch (e) {
          print('DEBUG: Failed to sync AI assessments: $e');
        }
        
        // Sync prescriptions
        try {
          final prescriptions = await SupabaseService.getPrescriptions(user.id);
          await LocalStorageService.cachePrescriptions(prescriptions);
          print('DEBUG: Prescriptions synced: ${prescriptions.length}');
        } catch (e) {
          print('DEBUG: Failed to sync prescriptions: $e');
        }
        
        // Sync medical records
        try {
          final medicalRecords = await SupabaseService.getMedicalRecords(user.id);
          final medicalHistory = {
            'records': medicalRecords,
            'last_updated': DateTime.now().toIso8601String(),
          };
          await LocalStorageService.cacheMedicalHistory(user.id, medicalHistory);
          print('DEBUG: Medical records synced: ${medicalRecords.length}');
        } catch (e) {
          print('DEBUG: Failed to sync medical records: $e');
        }
      }
      
      print('DEBUG: User data sync completed');
    } catch (e) {
      print('DEBUG: Failed to sync user data: $e');
    }
  }

  Future<void> _syncOfflineOperations() async {
    final operations = _offlineBox.values.toList();
    print('DEBUG: Syncing ${operations.length} offline operations');
    
    final keysToDelete = <dynamic>[];
    
    for (int i = 0; i < operations.length; i++) {
      try {
        final operation = Map<String, dynamic>.from(operations[i]);
        await _processOperation(operation);
        keysToDelete.add(_offlineBox.keyAt(i));
        print('DEBUG: Synced operation: ${operation['type']}');
      } catch (e) {
        print('DEBUG: Sync error for operation ${i}: $e');
      }
    }
    
    // Delete successfully synced operations
    for (final key in keysToDelete) {
      await _offlineBox.delete(key);
    }
    
    print('DEBUG: Offline operations sync completed');
  }

  Future<void> _processOperation(Map<String, dynamic> operation) async {
    final type = operation['type'];
    final data = Map<String, dynamic>.from(operation['data']);
    
    switch (type) {
      case 'create_appointment':
        await SupabaseService.createAppointment(data);
        break;
      case 'update_profile':
        await SupabaseService.updateProfile(data['id'], data);
        break;
      case 'send_message':
        await SupabaseService.sendMessage(data);
        break;
      case 'create_ai_assessment':
        await SupabaseService.createAiAssessment(data);
        break;
      case 'create_prescription':
        await SupabaseService.createPrescription(data);
        break;
      default:
        print('DEBUG: Unknown operation type: $type');
    }
  }

  bool get isOnline => _isOnline;
  
  // Manual sync trigger
  Future<void> syncNow() async {
    if (!_isInitialized) {
      await init();
    }
    
    if (_isOnline) {
      print('DEBUG: Manual sync triggered');
      await _syncAllUserData();
      await _syncOfflineOperations();
    } else {
      print('DEBUG: Cannot sync - offline');
    }
  }
  
  // Force sync on login
  Future<void> syncOnLogin() async {
    print('DEBUG: Syncing data on login');
    await _checkInitialConnectivity();
  }
}