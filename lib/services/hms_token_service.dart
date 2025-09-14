import 'dart:convert';
import 'package:http/http.dart' as http;
import 'supabase_service.dart';

class HMSTokenService {
  /// Creates a new 100ms room for a consultation using Edge Function
  static Future<String> createRoom({
    required String doctorId,
    required String patientId,
  }) async {
    print('DEBUG: HMSTokenService.createRoom called');
    print('DEBUG: Parameters - doctorId: $doctorId, patientId: $patientId');
    
    try {
      final session = SupabaseService.client.auth.currentSession;
      if (session == null) {
        print('DEBUG: No session found');
        throw Exception('User not authenticated');
      }
      
      print('DEBUG: Session found, calling Edge Function for room creation');
      
      final uri = Uri.parse('${SupabaseService.supabaseUrl}/functions/v1/generate-hms-token')
          .replace(queryParameters: {
        'action': 'create_room',
        'doctorId': doctorId,
        'patientId': patientId,
      });
      
      print('DEBUG: Request URI: $uri');
      
      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer ${session.accessToken}',
          'apikey': SupabaseService.supabaseAnonKey,
          'Content-Type': 'application/json',
        },
      );
      
      print('DEBUG: Room creation response status: ${response.statusCode}');
      print('DEBUG: Room creation response body: ${response.body}');
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final roomId = data['room_id'] as String;
        print('DEBUG: Room created successfully: $roomId');
        return roomId;
      } else {
        final error = jsonDecode(response.body);
        print('DEBUG: Room creation failed: ${error['error']}');
        throw Exception('Failed to create room: ${error['error']}');
      }
    } catch (e) {
      print('DEBUG: Room creation error: $e');
      rethrow;
    }
  }
  
  /// Generates a JWT token for a specific consultation using Edge Function
  static Future<String> generateTokenForConsultation({
    required String consultationId,
    required String userId,
  }) async {
    print('DEBUG: HMSTokenService.generateTokenForConsultation called');
    print('DEBUG: Parameters - consultationId: $consultationId, userId: $userId');
    
    try {
      final session = SupabaseService.client.auth.currentSession;
      if (session == null) {
        print('DEBUG: No session found');
        throw Exception('User not authenticated');
      }
      
      print('DEBUG: Session found, calling Edge Function for token generation');
      
      final uri = Uri.parse('${SupabaseService.supabaseUrl}/functions/v1/generate-hms-token')
          .replace(queryParameters: {
        'consultationId': consultationId,
        'userId': userId,
      });
      
      print('DEBUG: Request URI: $uri');
      
      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer ${session.accessToken}',
          'apikey': SupabaseService.supabaseAnonKey,
          'Content-Type': 'application/json',
        },
      );
      
      print('DEBUG: Token generation response status: ${response.statusCode}');
      print('DEBUG: Token generation response body: ${response.body}');
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final token = data['token'] as String;
        final roomId = data['room_id'] as String;
        final role = data['role'] as String;
        
        print('DEBUG: Token generated successfully');
        print('DEBUG: Room ID: $roomId');
        print('DEBUG: Role: $role');
        print('DEBUG: Token length: ${token.length}');
        
        return token;
      } else {
        final error = jsonDecode(response.body);
        print('DEBUG: Token generation failed: ${error['error']}');
        throw Exception('Failed to generate token: ${error['error']}');
      }
    } catch (e) {
      print('DEBUG: Token generation error: $e');
      rethrow;
    }
  }
}