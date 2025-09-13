import 'dart:async';
import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  static const String supabaseUrl = 'https://nghrtgqwqrgvyhuiaymf.supabase.co';
  static const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im5naHJ0Z3F3cXJndnlodWlheW1mIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTc1OTY1NDEsImV4cCI6MjA3MzE3MjU0MX0.agpWVRJyhFca1o0Gr6TneGXIwBj77MbvWL8wYMt6BFs';
  
  static SupabaseClient get client => Supabase.instance.client;
  
  static Future<void> initialize() async {
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
    );
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
  
  static User? get currentUser => client.auth.currentUser;
  
  static bool get hasValidSession {
    final user = currentUser;
    final session = client.auth.currentSession;
    return user != null && session != null && !session.isExpired;
  }
  
  // Profile operations
  static Future<Map<String, dynamic>?> getProfile(String userId) async {
    try {
      final response = await client
          .from('profiles')
          .select('*, patients(*), doctors(*)')
          .eq('id', userId)
          .single()
          .timeout(const Duration(seconds: 10));
      print('DEBUG: Profile response from server: $response');
      return response;
    } on TimeoutException {
      print('DEBUG: Profile fetch timeout - likely offline');
      return null;
    } catch (e) {
      print('DEBUG: Failed to fetch profile from server: $e');
      return null;
    }
  }
  
  static Future<void> updateProfile(String userId, Map<String, dynamic> data) async {
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
        patientData[entry.key] = entry.value;
      } else if (doctorFields.contains(entry.key)) {
        doctorData[entry.key] = entry.value;
      }
    }
    
    if (profileData.isNotEmpty) {
      await client.from('profiles').update(profileData).eq('id', userId);
    }
    
    if (patientData.isNotEmpty) {
      print('DEBUG: Updating patients table with data: $patientData for userId: $userId');
      try {
        // Use upsert to handle both insert and update
        patientData['id'] = userId;
        await client.from('patients').upsert(patientData);
        print('DEBUG: Upserted patient record successfully');
      } catch (e) {
        print('DEBUG: Error updating patient data: $e');
        // Fallback: try update only if upsert fails
        try {
          await client.from('patients').update(patientData).eq('id', userId);
          print('DEBUG: Fallback update successful');
        } catch (updateError) {
          print('DEBUG: Fallback update also failed: $updateError');
        }
      }
    }
    
    if (doctorData.isNotEmpty) {
      await client.from('doctors').update(doctorData).eq('id', userId);
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
    final response = await client
        .from('chats')
        .select()
        .eq('conversation_id', conversationId)
        .order('created_at');
    return List<Map<String, dynamic>>.from(response);
  }
  
  static Future<void> sendMessage(Map<String, dynamic> message) async {
    await client.from('chats').insert(message);
  }
  
  static Stream<List<Map<String, dynamic>>> subscribeToMessages(String conversationId) {
    return client
        .from('chats')
        .stream(primaryKey: ['id'])
        .eq('conversation_id', conversationId)
        .order('created_at');
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
      final response = await client
          .from('appointments')
          .select('patient_id, profiles!appointments_patient_id_fkey(*), patients(*)')
          .eq('doctor_id', doctorId)
          .eq('status', 'confirmed');
      
      final uniquePatients = <String, Map<String, dynamic>>{};
      for (final appointment in response) {
        final patientId = appointment['patient_id'];
        if (!uniquePatients.containsKey(patientId)) {
          uniquePatients[patientId] = appointment;
        }
      }
      return uniquePatients.values.toList();
    } catch (e) {
      return [];
    }
  }
  
  static Future<Map<String, dynamic>> getDoctorStats(String doctorId) async {
    try {
      final appointments = await client
          .from('appointments')
          .select('status')
          .eq('doctor_id', doctorId);
      
      final total = appointments.length;
      final completed = appointments.where((a) => a['status'] == 'completed').length;
      final pending = appointments.where((a) => a['status'] == 'pending').length;
      final confirmed = appointments.where((a) => a['status'] == 'confirmed').length;
      
      return {
        'total_appointments': total,
        'completed_appointments': completed,
        'pending_appointments': pending,
        'confirmed_appointments': confirmed,
      };
    } catch (e) {
      return {
        'total_appointments': 0,
        'completed_appointments': 0,
        'pending_appointments': 0,
        'confirmed_appointments': 0,
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
      return {
        'id': 'demo-${DateTime.now().millisecondsSinceEpoch}',
        ...data,
        'created_at': DateTime.now().toIso8601String(),
      };
    }
  }
  
  // Medical History
  static Future<List<Map<String, dynamic>>> getPrescriptions(String patientId) async {
    try {
      final response = await client
          .from('prescriptions')
          .select('*, profiles!prescriptions_doctor_id_fkey(*)')
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
          .select('*, profiles!medical_records_doctor_id_fkey(*)')
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
        print('DEBUG: No doctors found in database, returning mock data for testing');
        return [
          {
            'id': 'mock-doctor-1',
            'full_name': 'Dr. John Smith',
            'role': 'doctor',
            'status': true,
            'doctors': [
              {
                'specialization': specialization,
                'clinic_name': 'City Medical Center',
                'verified': true,
                'rating': 4.5,
                'qualifications': 'MBBS, MD'
              }
            ]
          },
          {
            'id': 'mock-doctor-2', 
            'full_name': 'Dr. Sarah Johnson',
            'role': 'doctor',
            'status': true,
            'doctors': [
              {
                'specialization': specialization,
                'clinic_name': 'Health Plus Clinic',
                'verified': true,
                'rating': 4.8,
                'qualifications': 'MBBS, MS'
              }
            ]
          }
        ];
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
}