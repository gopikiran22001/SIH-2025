import 'package:hive_flutter/hive_flutter.dart';

class LocalStorageService {
  static late Box _userBox;
  static late Box _appointmentsBox;
  static late Box _assessmentsBox;
  static late Box _messagesBox;
  static late Box _medicalHistoryBox;
  static late Box _reportsBox;

  static Future<void> initialize() async {
    await Hive.initFlutter();
    _userBox = await Hive.openBox('user_data');
    _appointmentsBox = await Hive.openBox('appointments');
    _assessmentsBox = await Hive.openBox('ai_assessments');
    _messagesBox = await Hive.openBox('messages');
    _medicalHistoryBox = await Hive.openBox('medical_history');
    _reportsBox = await Hive.openBox('medical_reports');
  }

  // User data
  static Future<void> saveCurrentUser(Map<String, dynamic> user) async {
    print('DEBUG: Saving user to local storage: $user');
    await _userBox.put('current_user', user);
    print('DEBUG: User saved successfully');
  }

  static Map<String, dynamic>? getCurrentUser() {
    final user = _userBox.get('current_user')?.cast<String, dynamic>();
    print('DEBUG: Retrieved user from local storage: $user');
    return user;
  }

  static String? getCurrentUserId() {
    final user = getCurrentUser();
    return user?['id'];
  }

  // Appointments
  static Future<void> cacheAppointment(Map<String, dynamic> appointment) async {
    final userId = getCurrentUserId();
    if (appointment['id'] != null && userId != null) {
      await _appointmentsBox.put('${userId}_${appointment['id']}', appointment);
    }
  }

  static Future<void> cacheAppointments(List<Map<String, dynamic>> appointments) async {
    final userId = getCurrentUserId();
    if (userId == null) return;
    
    // Clear existing appointments for this user
    final keysToDelete = _appointmentsBox.keys
        .where((key) => key.toString().startsWith('${userId}_'))
        .toList();
    for (final key in keysToDelete) {
      await _appointmentsBox.delete(key);
    }
    
    for (final appointment in appointments) {
      await cacheAppointment(appointment);
    }
  }

  static List<Map<String, dynamic>> getCachedAppointments() {
    final userId = getCurrentUserId();
    if (userId == null) return [];
    
    return _appointmentsBox.keys
        .where((key) => key.toString().startsWith('${userId}_'))
        .map((key) => Map<String, dynamic>.from(_appointmentsBox.get(key)))
        .toList()
        ..sort((a, b) => DateTime.parse(b['created_at'] ?? b['scheduled_at'])
            .compareTo(DateTime.parse(a['created_at'] ?? a['scheduled_at'])));
  }

  // AI Assessments
  static Future<void> cacheAiAssessment(Map<String, dynamic> assessment) async {
    final userId = getCurrentUserId();
    if (assessment['id'] != null && userId != null) {
      await _assessmentsBox.put('${userId}_${assessment['id']}', assessment);
    }
  }

  static Future<void> cacheAiAssessments(List<Map<String, dynamic>> assessments) async {
    final userId = getCurrentUserId();
    if (userId == null) return;
    
    // Clear existing assessments for this user
    final keysToDelete = _assessmentsBox.keys
        .where((key) => key.toString().startsWith('${userId}_'))
        .toList();
    for (final key in keysToDelete) {
      await _assessmentsBox.delete(key);
    }
    
    for (final assessment in assessments) {
      await cacheAiAssessment(assessment);
    }
  }

  static List<Map<String, dynamic>> getCachedAiAssessments() {
    final userId = getCurrentUserId();
    if (userId == null) return [];
    
    return _assessmentsBox.keys
        .where((key) => key.toString().startsWith('${userId}_'))
        .map((key) => Map<String, dynamic>.from(_assessmentsBox.get(key)))
        .toList()
        ..sort((a, b) => DateTime.parse(b['created_at'])
            .compareTo(DateTime.parse(a['created_at'])));
  }

  // Messages
  static Future<void> cacheMessage(String conversationId, Map<String, dynamic> message) async {
    final userId = getCurrentUserId();
    if (message['id'] != null && userId != null) {
      final key = '${userId}_${conversationId}_${message['id']}';
      await _messagesBox.put(key, message);
    }
  }

  static Future<void> cacheMessages(String conversationId, List<Map<String, dynamic>> messages) async {
    final userId = getCurrentUserId();
    if (userId == null) return;
    
    // Clear existing messages for this user and conversation
    final keysToDelete = _messagesBox.keys
        .where((key) => key.toString().startsWith('${userId}_${conversationId}'))
        .toList();
    for (final key in keysToDelete) {
      await _messagesBox.delete(key);
    }
    
    for (final message in messages) {
      await cacheMessage(conversationId, message);
    }
  }

  static List<Map<String, dynamic>> getCachedMessages(String conversationId) {
    final userId = getCurrentUserId();
    if (userId == null) return [];
    
    return _messagesBox.keys
        .where((key) => key.toString().startsWith('${userId}_${conversationId}'))
        .map((key) => Map<String, dynamic>.from(_messagesBox.get(key)))
        .toList()
        ..sort((a, b) => DateTime.parse(a['created_at'])
            .compareTo(DateTime.parse(b['created_at'])));
  }

  // Medical History
  static Future<void> cacheMedicalHistory(String userId, Map<String, dynamic> data) async {
    await _medicalHistoryBox.put('medical_history_$userId', data);
  }
  
  static Map<String, dynamic>? getCachedMedicalHistory(String userId) {
    return _medicalHistoryBox.get('medical_history_$userId')?.cast<String, dynamic>();
  }

  // Prescriptions
  static Future<void> cachePrescription(Map<String, dynamic> prescription) async {
    final userId = getCurrentUserId();
    if (prescription['id'] != null && userId != null) {
      await _medicalHistoryBox.put('${userId}_prescription_${prescription['id']}', prescription);
    }
  }

  static Future<void> cachePrescriptions(List<Map<String, dynamic>> prescriptions) async {
    final userId = getCurrentUserId();
    if (userId == null) return;
    
    // Clear existing prescriptions for this user
    final keysToDelete = _medicalHistoryBox.keys
        .where((key) => key.toString().startsWith('${userId}_prescription_'))
        .toList();
    for (final key in keysToDelete) {
      await _medicalHistoryBox.delete(key);
    }
    
    for (final prescription in prescriptions) {
      await cachePrescription(prescription);
    }
  }

  static List<Map<String, dynamic>> getCachedPrescriptions() {
    final userId = getCurrentUserId();
    if (userId == null) return [];
    
    return _medicalHistoryBox.keys
        .where((key) => key.toString().startsWith('${userId}_prescription_'))
        .map((key) => Map<String, dynamic>.from(_medicalHistoryBox.get(key)))
        .toList()
        ..sort((a, b) => DateTime.parse(b['created_at'])
            .compareTo(DateTime.parse(a['created_at'])));
  }

  // Medical Reports
  static Future<void> cacheReport(Map<String, dynamic> report) async {
    final userId = getCurrentUserId();
    if (report['id'] != null && userId != null) {
      await _reportsBox.put('${userId}_${report['id']}', report);
    }
  }

  static Future<void> cacheReports(List<Map<String, dynamic>> reports) async {
    final userId = getCurrentUserId();
    if (userId == null) return;
    
    // Clear existing reports for this user
    final keysToDelete = _reportsBox.keys
        .where((key) => key.toString().startsWith('${userId}_'))
        .toList();
    for (final key in keysToDelete) {
      await _reportsBox.delete(key);
    }
    
    for (final report in reports) {
      await cacheReport(report);
    }
  }

  static List<Map<String, dynamic>> getCachedReports() {
    final userId = getCurrentUserId();
    if (userId == null) return [];
    
    return _reportsBox.keys
        .where((key) => key.toString().startsWith('${userId}_'))
        .map((key) => Map<String, dynamic>.from(_reportsBox.get(key)))
        .toList()
        ..sort((a, b) => DateTime.parse(b['report_date'])
            .compareTo(DateTime.parse(a['report_date'])));
  }

  // Logout - clear ALL user data completely
  static Future<void> logout() async {
    print('DEBUG: Logging out user - clearing all data');
    
    // Clear all boxes completely to ensure no data remains
    await _userBox.clear();
    await _appointmentsBox.clear();
    await _assessmentsBox.clear();
    await _messagesBox.clear();
    await _medicalHistoryBox.clear();
    await _reportsBox.clear();
    
    print('DEBUG: All user data cleared on logout');
  }

  // Clear all cache (for complete reset)
  static Future<void> clearAllCache() async {
    await _userBox.clear();
    await _appointmentsBox.clear();
    await _assessmentsBox.clear();
    await _messagesBox.clear();
    await _medicalHistoryBox.clear();
    await _reportsBox.clear();
  }
}