import 'dart:async';
import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'local_storage_service.dart';
import 'offline_sync_service.dart';

class SupabaseService {
  static const String supabaseUrl = 'https://nghrtgqwqrgvyhuiaymf.supabase.co';
  static const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im5naHJ0Z3F3cXJndnlodWlheW1mIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTc1OTY1NDEsImV4cCI6MjA3MzE3MjU0MX0.agpWVRJyhFca1o0Gr6TneGXIwBj77MbvWL8wYMt6BFs';
  
  static SupabaseClient get client => Supabase.instance.client;
  
  static Future<void> initialize() async {
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
    );
    await _createVideoSignalingTable();
  }

  static Future<void> _createVideoSignalingTable() async {
    try {
      // Check if table exists by trying to select from it
      await client.from('video_signaling').select('id').limit(1);
    } catch (e) {
      // Table doesn't exist, but we can't create it via client
      // This would need to be done via Supabase dashboard or SQL
      print('DEBUG: video_signaling table may not exist - create it in Supabase dashboard');
    }
  }
  
  // Auth methods
  static Future<AuthResponse> signUp(String email, String password, Map<String, dynamic> metadata) async {
    return await client.auth.signUp(
      email: email,
      password: password,
      data: metadata,
    );
  }
  
  static Future<AuthResponse> signIn(String email, String password) async {
    return await client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }
  
  static Future<void> signOut() async {
    await client.auth.signOut();
  }
  
  static Future<void> signOutAndClearStack() async {
    // Clear all local data before signing out
    await LocalStorageService.logout();
    await OfflineSyncService().clearOfflineData();
    await client.auth.signOut();
  }
  
  static User? get currentUser => client.auth.currentUser;
  
  static bool get hasValidSession {
    final user = currentUser;
    final session = client.auth.currentSession;
    return user != null && session != null && !session.isExpired;
  }
  
  // Profile operations
  static Future<Map<String, dynamic>?> getProfile(String userId) async {
    print('DEBUG: Getting profile for user ID: $userId');
    try {
      print('DEBUG: Executing profile query with LEFT JOINs for patient and doctor data...');
      
      // Use proper SQL LEFT JOIN syntax for PostgreSQL
      final response = await client
          .from('profiles')
          .select('*, patients(blood_group, emergency_contact), doctors(specialization, clinic_name, qualifications, verified, rating)')
          .eq('id', userId)
          .single()
          .timeout(const Duration(seconds: 10));
      
      print('DEBUG: Raw profile response from server: $response');
      print('DEBUG: Response type: ${response.runtimeType}');
      print('DEBUG: Response keys: ${response.keys.toList()}');
      
      // Check what we got for patients and doctors
      if (response['patients'] != null) {
        print('DEBUG: Patients data: ${response['patients']}');
        print('DEBUG: Patients data type: ${response['patients'].runtimeType}');
      } else {
        print('DEBUG: No patients data in response');
      }
      
      if (response['doctors'] != null) {
        print('DEBUG: Doctors data: ${response['doctors']}');
        print('DEBUG: Doctors data type: ${response['doctors'].runtimeType}');
      } else {
        print('DEBUG: No doctors data in response');
      }
      
      return response;
    } on TimeoutException {
      print('DEBUG: Profile fetch timeout - likely offline');
      return null;
    } catch (e) {
      print('DEBUG: Failed to fetch profile from server: $e');
      print('DEBUG: Profile fetch error type: ${e.runtimeType}');
      if (e is PostgrestException) {
        print('DEBUG: Profile PostgrestException details:');
        print('DEBUG: - Code: ${e.code}');
        print('DEBUG: - Message: ${e.message}');
        print('DEBUG: - Details: ${e.details}');
        print('DEBUG: - Hint: ${e.hint}');
      }
      return null;
    }
  }
  
  static Future<void> updateProfile(String userId, Map<String, dynamic> data) async {
    print('DEBUG: Updating profile for user $userId with data: $data');
    
    final profileData = <String, dynamic>{};
    final patientData = <String, dynamic>{};
    final doctorData = <String, dynamic>{};
    
    final profileFields = ['full_name', 'phone', 'gender', 'dob'];
    final patientFields = ['blood_group', 'emergency_contact'];
    final doctorFields = ['specialization', 'clinic_name', 'qualifications'];
    
    for (final entry in data.entries) {
      if (profileFields.contains(entry.key)) {
        profileData[entry.key] = entry.value;
      } else if (patientFields.contains(entry.key)) {
        // Handle emergency_contact as JSONB - convert string to JSON if needed
        if (entry.key == 'emergency_contact' && entry.value is String) {
          // If it's a phone number string, wrap it in JSON format
          patientData[entry.key] = {'phone': entry.value};
        } else {
          patientData[entry.key] = entry.value;
        }
      } else if (doctorFields.contains(entry.key)) {
        doctorData[entry.key] = entry.value;
      }
    }
    
    print('DEBUG: Separated data - Profile: $profileData, Patient: $patientData, Doctor: $doctorData');
    
    if (profileData.isNotEmpty) {
      print('DEBUG: Updating profiles table...');
      await client.from('profiles').update(profileData).eq('id', userId);
      print('DEBUG: Profiles table updated successfully');
    }
    
    if (patientData.isNotEmpty) {
      print('DEBUG: Updating patients table with data: $patientData for userId: $userId');
      try {
        // Use upsert to handle both insert and update
        patientData['id'] = userId;
        await client.from('patients').upsert(patientData);
        print('DEBUG: Upserted patient record successfully');
      } catch (e) {
        print('DEBUG: Error upserting patient data: $e');
        // Fallback: try update only if upsert fails
        try {
          final updateData = Map<String, dynamic>.from(patientData);
          updateData.remove('id'); // Remove id for update
          await client.from('patients').update(updateData).eq('id', userId);
          print('DEBUG: Fallback update successful');
        } catch (updateError) {
          print('DEBUG: Fallback update also failed: $updateError');
          // Last resort: try insert
          try {
            await client.from('patients').insert(patientData);
            print('DEBUG: Insert successful as last resort');
          } catch (insertError) {
            print('DEBUG: All patient update methods failed: $insertError');
          }
        }
      }
    }
    
    if (doctorData.isNotEmpty) {
      print('DEBUG: Updating doctors table with data: $doctorData for userId: $userId');
      try {
        // Use upsert to handle both insert and update
        doctorData['id'] = userId;
        await client.from('doctors').upsert(doctorData);
        print('DEBUG: Upserted doctor record successfully');
      } catch (e) {
        print('DEBUG: Error upserting doctor data: $e');
        // Fallback: try update only if upsert fails
        try {
          final updateData = Map<String, dynamic>.from(doctorData);
          updateData.remove('id'); // Remove id for update
          await client.from('doctors').update(updateData).eq('id', userId);
          print('DEBUG: Fallback doctor update successful');
        } catch (updateError) {
          print('DEBUG: Fallback doctor update also failed: $updateError');
          // Last resort: try insert
          try {
            await client.from('doctors').insert(doctorData);
            print('DEBUG: Doctor insert successful as last resort');
          } catch (insertError) {
            print('DEBUG: All doctor update methods failed: $insertError');
          }
        }
      }
    }
  }
  
  // Appointments
  static Future<List<Map<String, dynamic>>> getAppointments(String userId, String role) async {
    try {
      final column = role == 'patient' ? 'patient_id' : 'doctor_id';
      final response = await client
          .from('appointments')
          .select('*, profiles!appointments_${role == 'patient' ? 'doctor' : 'patient'}_id_fkey(*)')
          .eq(column, userId)
          .order('scheduled_at')
          .timeout(const Duration(seconds: 10));
      return List<Map<String, dynamic>>.from(response);
    } on TimeoutException {
      print('DEBUG: Appointments fetch timeout - using cached data');
      throw Exception('Network timeout');
    } catch (e) {
      print('DEBUG: Failed to fetch appointments: $e');
      throw Exception('Failed to fetch appointments');
    }
  }
  
  static Future<Map<String, dynamic>> createAppointment(Map<String, dynamic> data) async {
    final response = await client
        .from('appointments')
        .insert(data)
        .select()
        .single();
    return response;
  }
  
  static Future<void> updateAppointment(String id, Map<String, dynamic> data) async {
    await client
        .from('appointments')
        .update(data)
        .eq('id', id);
  }
  
  // Chat operations
  static Future<List<Map<String, dynamic>>> getMessages(String conversationId) async {
    print('DEBUG: Fetching messages for conversation: $conversationId');
    
    // Extract user IDs from conversation ID (format: userId_otherUserId)
    final userIds = conversationId.split('_');
    if (userIds.length != 2) {
      print('DEBUG: Invalid conversation ID format');
      return [];
    }
    
    final userId1 = userIds[0];
    final userId2 = userIds[1];
    print('DEBUG: Looking for messages between $userId1 and $userId2');
    
    // Query messages between the two users regardless of conversation_id
    final response = await client
        .from('chats')
        .select()
        .or('and(sender_id.eq.$userId1,receiver_id.eq.$userId2),and(sender_id.eq.$userId2,receiver_id.eq.$userId1)')
        .order('created_at', ascending: true);
    
    print('DEBUG: Raw messages from DB: $response');
    return List<Map<String, dynamic>>.from(response);
  }
  
  static Future<void> sendMessage(Map<String, dynamic> message) async {
    print('DEBUG: Sending message to database: $message');
    await client.from('chats').insert(message);
    print('DEBUG: Message sent successfully');
  }
  
  static Stream<List<Map<String, dynamic>>> subscribeToMessages(String conversationId) {
    return client
        .from('chats')
        .stream(primaryKey: ['id'])
        .eq('conversation_id', conversationId)
        .order('created_at', ascending: true);
  }
  
  // AI Assessments
  static Future<Map<String, dynamic>> createAiAssessment(Map<String, dynamic> data) async {
    try {
      // Prepare data for database insertion
      final insertData = {
        'patient_id': data['patient_id'],
        'symptoms': data['symptoms'],
        'result': data['result'],
      };
      
      print('DEBUG: Inserting AI assessment: $insertData');
      
      final response = await client
          .from('ai_assessments')
          .insert(insertData)
          .select()
          .single();
          
      print('DEBUG: AI assessment inserted successfully: $response');
      return response;
    } catch (e) {
      print('DEBUG: Failed to insert AI assessment: $e');
      return {
        'id': 'demo-${DateTime.now().millisecondsSinceEpoch}',
        'patient_id': data['patient_id'],
        'symptoms': data['symptoms'],
        'result': data['result'],
        'created_at': DateTime.now().toIso8601String(),
      };
    }
  }
  
  static Future<List<Map<String, dynamic>>> getAiAssessments(String patientId) async {
    try {
      final response = await client
          .from('ai_assessments')
          .select()
          .eq('patient_id', patientId)
          .order('created_at', ascending: false)
          .timeout(const Duration(seconds: 10));
      return List<Map<String, dynamic>>.from(response);
    } on TimeoutException {
      print('DEBUG: AI assessments fetch timeout');
      throw Exception('Network timeout');
    } catch (e) {
      print('DEBUG: Failed to fetch AI assessments: $e');
      throw Exception('Failed to fetch AI assessments');
    }
  }
  
  // Doctor specific methods
  static Future<List<Map<String, dynamic>>> getDoctorPatients(String doctorId) async {
    try {
      final consultations = await client
          .from('video_consultations')
          .select('patient_id, created_at')
          .eq('doctor_id', doctorId)
          .eq('status', 'completed')
          .order('created_at', ascending: false);
      
      final Map<String, Map<String, dynamic>> uniquePatients = {};
      
      for (final consultation in consultations) {
        final patientId = consultation['patient_id'];
        if (!uniquePatients.containsKey(patientId)) {
          final profile = await client
              .from('profiles')
              .select('id, full_name, phone, gender')
              .eq('id', patientId)
              .single();
          
          final patientData = await client
              .from('patients')
              .select('blood_group, emergency_contact')
              .eq('id', patientId)
              .maybeSingle();
          
          uniquePatients[patientId] = {
            'patient_id': patientId,
            'created_at': consultation['created_at'],
            'profiles': profile,
            'patients': patientData,
          };
        }
      }
      
      return uniquePatients.values.toList();
    } catch (e) {
      print('DEBUG: Failed to fetch doctor patients: $e');
      return [];
    }
  }
  
  static Future<Map<String, dynamic>> getDoctorStats(String doctorId) async {
    try {
      final consultations = await client
          .from('video_consultations')
          .select('status')
          .eq('doctor_id', doctorId);
      
      final total = consultations.length;
      final completed = consultations.where((c) => c['status'] == 'completed').length;
      final pending = consultations.where((c) => c['status'] == 'pending').length;
      final active = consultations.where((c) => c['status'] == 'active').length;
      
      return {
        'total_consultations': total,
        'completed_consultations': completed,
        'pending_consultations': pending,
        'active_consultations': active,
      };
    } catch (e) {
      return {
        'total_consultations': 0,
        'completed_consultations': 0,
        'pending_consultations': 0,
        'active_consultations': 0,
      };
    }
  }
  
  static Future<Map<String, dynamic>> createPrescription(Map<String, dynamic> data) async {
    try {
      final response = await client
          .from('prescriptions')
          .insert(data)
          .select()
          .single();
      return response;
    } catch (e) {
      print('DEBUG: Failed to create prescription: $e');
      throw e;
    }
  }
  
  // Medical History
  static Future<List<Map<String, dynamic>>> getPrescriptions(String patientId) async {
    try {
      final response = await client
          .from('prescriptions')
          .select('*, profiles!prescriptions_doctor_id_fkey(full_name)')
          .eq('patient_id', patientId)
          .order('created_at', ascending: false)
          .timeout(const Duration(seconds: 10));
      return List<Map<String, dynamic>>.from(response);
    } on TimeoutException {
      print('DEBUG: Prescriptions fetch timeout');
      throw Exception('Network timeout');
    } catch (e) {
      print('DEBUG: Failed to fetch prescriptions: $e');
      throw Exception('Failed to fetch prescriptions');
    }
  }
  
  static Future<List<Map<String, dynamic>>> getMedicalRecords(String patientId) async {
    try {
      final response = await client
          .from('medical_records')
          .select('*, profiles!medical_records_doctor_id_fkey(full_name)')
          .eq('patient_id', patientId)
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      return [];
    }
  }

  // Doctor search
  static Future<List<Map<String, dynamic>>> searchAvailableDoctors(String specialization) async {
    try {
      print('DEBUG: Searching for doctors with specialization: $specialization');
      
      final response = await client
          .from('profiles')
          .select('*, doctors(*)')
          .eq('role', 'doctor')
          .timeout(const Duration(seconds: 10));
      
      print('DEBUG: All doctors in database: $response');
      
      if (response.isEmpty) {
        print('DEBUG: No doctors found in database');
        return [];
      }
      
      final filteredDoctors = List<Map<String, dynamic>>.from(response)
          .where((doctor) {
            final doctorData = doctor['doctors'];
            final status = doctor['status'] == true;
            
            // Handle both List and Map structures for doctors data
            Map<String, dynamic>? doctorInfo;
            if (doctorData is List && doctorData.isNotEmpty) {
              doctorInfo = doctorData[0];
            } else if (doctorData is Map<String, dynamic>) {
              doctorInfo = doctorData;
            }
            
            if (doctorInfo != null) {
              final spec = doctorInfo['specialization']?.toString().toLowerCase() ?? '';
              final verified = doctorInfo['verified'] == true;
              
              print('DEBUG: Doctor ${doctor['full_name']}: status=$status, verified=$verified, spec="$spec", looking for="${specialization.toLowerCase()}"');
              
              return status && verified && spec.contains(specialization.toLowerCase());
            }
            return false;
          })
          .toList();
      
      print('DEBUG: Found ${filteredDoctors.length} doctors matching criteria');
      return filteredDoctors;
    } on TimeoutException {
      print('DEBUG: Doctor search timeout');
      throw Exception('Network timeout');
    } catch (e) {
      print('DEBUG: Failed to search doctors: $e');
      throw Exception('Failed to search doctors');
    }
  }



  // Storage operations
  static Future<String> uploadFile(String bucket, String path, List<int> bytes) async {
    await client.storage.from(bucket).uploadBinary(path, Uint8List.fromList(bytes));
    return client.storage.from(bucket).getPublicUrl(path);
  }
  
  static Future<void> deleteFile(String bucket, String path) async {
    await client.storage.from(bucket).remove([path]);
  }

  // User status management
  static Future<void> updateUserStatus(String userId, bool isOnline) async {
    try {
      await client
          .from('profiles')
          .update({'status': isOnline})
          .eq('id', userId)
          .timeout(const Duration(seconds: 5));
      print('DEBUG: Updated user status to ${isOnline ? "online" : "offline"} for user: $userId');
    } catch (e) {
      // Silently handle status update failures to prevent app disruption
      print('DEBUG: Failed to update user status (non-critical): $e');
    }
  }

  static Future<void> setUserOnline(String userId) async {
    await updateUserStatus(userId, true);
  }

  static Future<void> setUserOffline(String userId) async {
    await updateUserStatus(userId, false);
  }



  // Video consultation methods
  static Future<Map<String, dynamic>?> getActiveConsultation(String userId) async {
    try {
      final response = await client
          .from('video_consultations')
          .select('*')
          .or('patient_id.eq.$userId,doctor_id.eq.$userId')
          .eq('status', 'active')
          .maybeSingle();
      
      return response;
    } catch (e) {
      print('DEBUG: Failed to get active consultation: $e');
      return null;
    }
  }

  static Future<List<Map<String, dynamic>>> getConsultationHistory(String userId, String role) async {
    try {
      final column = role == 'patient' ? 'patient_id' : 'doctor_id';
      
      final response = await client
          .from('video_consultations')
          .select('*')
          .eq(column, userId)
          .order('created_at', ascending: false)
          .timeout(const Duration(seconds: 10));
      
      final consultations = List<Map<String, dynamic>>.from(response);
      
      if (role == 'doctor') {
        for (final consultation in consultations) {
          try {
            final patientProfile = await client
                .from('profiles')
                .select('full_name')
                .eq('id', consultation['patient_id'])
                .single();
            consultation['patient_name'] = patientProfile['full_name'];
          } catch (e) {
            consultation['patient_name'] = 'Unknown Patient';
          }
        }
      } else if (role == 'patient') {
        for (final consultation in consultations) {
          try {
            final doctorProfile = await client
                .from('profiles')
                .select('full_name')
                .eq('id', consultation['doctor_id'])
                .single();
            consultation['doctor_name'] = doctorProfile['full_name'];
          } catch (e) {
            consultation['doctor_name'] = 'Unknown Doctor';
          }
        }
      }
      
      return consultations;
    } on TimeoutException {
      print('DEBUG: Consultation history fetch timeout');
      throw Exception('Network timeout');
    } catch (e) {
      print('DEBUG: Failed to fetch consultation history: $e');
      throw Exception('Failed to fetch consultation history');
    }
  }
  
  // Get conversations for chat sync
  static Future<List<Map<String, dynamic>>> getConversations(String userId) async {
    try {
      final response = await client
          .from('chats')
          .select('sender_id, receiver_id')
          .or('sender_id.eq.$userId,receiver_id.eq.$userId')
          .timeout(const Duration(seconds: 10));
      
      final Set<String> conversationIds = {};
      for (final chat in response) {
        final senderId = chat['sender_id'];
        final receiverId = chat['receiver_id'];
        final conversationId = senderId.compareTo(receiverId) < 0 
            ? '${senderId}_$receiverId' 
            : '${receiverId}_$senderId';
        conversationIds.add(conversationId);
      }
      
      return conversationIds.map((id) => {'id': id}).toList();
    } catch (e) {
      print('DEBUG: Failed to fetch conversations: $e');
      return [];
    }
  }
  
  // Get doctor consultations
  static Future<List<Map<String, dynamic>>> getDoctorConsultations(String doctorId) async {
    try {
      final response = await client
          .from('video_consultations')
          .select('*, profiles!video_consultations_patient_id_fkey(full_name)')
          .eq('doctor_id', doctorId)
          .order('created_at', ascending: false)
          .timeout(const Duration(seconds: 10));
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('DEBUG: Failed to fetch doctor consultations: $e');
      return [];
    }
  }
  
  // Medical Reports operations
  static Future<List<Map<String, dynamic>>> getPatientReports(String patientId) async {
    try {
      final response = await client
          .from('medical_reports')
          .select('*')
          .eq('patient_id', patientId)
          .order('report_date', ascending: false)
          .timeout(const Duration(seconds: 10));
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('DEBUG: Failed to fetch patient reports: $e');
      return [];
    }
  }
  
  static Future<Map<String, dynamic>> createReport(Map<String, dynamic> data) async {
    try {
      final response = await client
          .from('medical_reports')
          .insert(data)
          .select()
          .single();
      return response;
    } catch (e) {
      print('DEBUG: Failed to create report: $e');
      throw e;
    }
  }
  
  static Future<void> updateReport(String reportId, Map<String, dynamic> data) async {
    try {
      await client
          .from('medical_reports')
          .update(data)
          .eq('id', reportId);
    } catch (e) {
      print('DEBUG: Failed to update report: $e');
      throw e;
    }
  }
  
  static Future<void> deleteReport(String reportId) async {
    try {
      await client
          .from('medical_reports')
          .delete()
          .eq('id', reportId);
    } catch (e) {
      print('DEBUG: Failed to delete report: $e');
      throw e;
    }
  }


}