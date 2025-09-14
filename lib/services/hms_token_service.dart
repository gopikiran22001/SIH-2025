import 'dart:convert';
import 'package:http/http.dart' as http;
import 'supabase_service.dart';

class HMSTokenService {
  static Future<String> generateToken({
    required String roomId,
    required String userId,
    required String role,
    String? userName,
  }) async {
    print('DEBUG: Starting HMS token generation');
    print('DEBUG: Parameters - roomId: $roomId, userId: $userId, role: $role, userName: $userName');
    
    try {
      print('DEBUG: Checking Supabase session...');
      final session = SupabaseService.client.auth.currentSession;
      print('DEBUG: Session exists: ${session != null}');
      
      if (session == null) {
        print('DEBUG: No session found, user not authenticated');
        throw Exception('User not authenticated');
      }
      
      final tokenPreview = session.accessToken.length > 20 ? session.accessToken.substring(0, 20) : session.accessToken;
      print('DEBUG: Session access token: $tokenPreview...');
      print('DEBUG: Session expires at: ${session.expiresAt}');
      print('DEBUG: Session is expired: ${session.isExpired}');

      print('DEBUG: Building request URI...');
      final baseUrl = '${SupabaseService.supabaseUrl}/functions/v1/generate-hms-token';
      print('DEBUG: Base URL: $baseUrl');
      
      final queryParams = {
        'roomId': roomId,
        'userId': userId,
        'role': role,
        if (userName != null) 'userName': userName,
      };
      print('DEBUG: Query parameters: $queryParams');
      
      final uri = Uri.parse(baseUrl).replace(queryParameters: queryParams);
      print('DEBUG: Final URI: $uri');

      print('DEBUG: Preparing request headers...');
      final headers = {
        'Authorization': 'Bearer ${session.accessToken}',
        'apikey': SupabaseService.supabaseAnonKey,
        'Content-Type': 'application/json',
      };
      print('DEBUG: Headers prepared (auth token hidden)');
      final keyPreview = SupabaseService.supabaseAnonKey.length > 20 ? SupabaseService.supabaseAnonKey.substring(0, 20) : SupabaseService.supabaseAnonKey;
      print('DEBUG: API Key: $keyPreview...');

      print('DEBUG: Making HTTP GET request...');
      final response = await http.get(uri, headers: headers);
      
      print('DEBUG: Response received');
      print('DEBUG: Status code: ${response.statusCode}');
      print('DEBUG: Response headers: ${response.headers}');
      print('DEBUG: Response body: ${response.body}');
      print('DEBUG: Response body length: ${response.body.length}');
      
      if (response.statusCode == 200) {
        print('DEBUG: Success response, parsing JSON...');
        try {
          final data = jsonDecode(response.body);
          print('DEBUG: Parsed JSON data: $data');
          
          if (data.containsKey('token')) {
            final token = data['token'] as String;
            print('DEBUG: Token extracted successfully');
            print('DEBUG: Token length: ${token.length}');
            print('DEBUG: Token type: ${token.runtimeType}');
            print('DEBUG: Token is empty: ${token.isEmpty}');
            print('DEBUG: Token equals temp_token: ${token == "temp_token"}');
            final previewLength = token.length > 50 ? 50 : token.length;
            print('DEBUG: Token preview: ${token.substring(0, previewLength)}...');
            
            // Validate JWT format (should have 3 parts separated by dots)
            final parts = token.split('.');
            print('DEBUG: Token parts count: ${parts.length}');
            if (parts.length != 3) {
              print('DEBUG: Invalid JWT format - expected 3 parts, got ${parts.length}');
              throw Exception('Invalid JWT token format');
            }
            
            return token;
          } else {
            print('DEBUG: No token field in response');
            throw Exception('No token in response: $data');
          }
        } catch (jsonError) {
          print('DEBUG: JSON parsing error: $jsonError');
          throw Exception('Invalid JSON response: ${response.body}');
        }
      } else {
        print('DEBUG: Error response, status: ${response.statusCode}');
        try {
          final error = jsonDecode(response.body);
          print('DEBUG: Parsed error response: $error');
          final errorMsg = error['error'] ?? error['message'] ?? 'Unknown error';
          final errorDetails = error['details'] ?? '';
          throw Exception('Failed to generate token: $errorMsg $errorDetails');
        } catch (jsonError) {
          print('DEBUG: Could not parse error JSON: $jsonError');
          throw Exception('HTTP ${response.statusCode}: ${response.body}');
        }
      }
    } catch (e) {
      print('DEBUG: Exception caught in generateToken: $e');
      print('DEBUG: Exception type: ${e.runtimeType}');
      if (e is Exception) {
        print('DEBUG: Re-throwing exception: $e');
        rethrow;
      } else {
        print('DEBUG: Converting error to exception: $e');
        throw Exception('HMS token generation failed: $e');
      }
    }
  }

  static String createRoom() {
    return '68c61fbda48ca61c46479c18';
  }
}