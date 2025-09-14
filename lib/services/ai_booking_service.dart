import 'dart:convert';
import 'package:http/http.dart' as http;
import '../services/supabase_service.dart';

class AiBookingService {
  static const String _baseUrl = 'https://sih-medvita.onrender.com';

  static Future<Map<String, dynamic>> getSpecializationSuggestion(String symptoms) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/recommend-doctor'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'symptoms': symptoms}),
      );
      
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
    } catch (e) {
      print('AI service error: $e');
    }
    
    return {'specialization': 'General Medicine', 'confidence': 0.6};
  }

  static Future<Map<String, dynamic>> analyzeSymptoms(String symptoms) async {
    print('DEBUG: Analyzing symptoms: $symptoms');
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/analyze-symptoms'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'symptoms': symptoms}),
      );
      
      print('DEBUG: Symptom analysis response status: ${response.statusCode}');
      print('DEBUG: Symptom analysis response body: ${response.body}');
      
      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        print('DEBUG: Parsed symptom analysis result: $result');
        return result;
      }
    } catch (e) {
      print('DEBUG: Symptom analysis error: $e');
    }
    
    final fallback = {'condition': 'Unknown', 'confidence': 0.0};
    print('DEBUG: Using fallback symptom analysis: $fallback');
    return fallback;
  }

  static Future<Map<String, dynamic>> assessRisk(int age, bool chestPain, bool shortnessOfBreath) async {
    print('DEBUG: Assessing risk - Age: $age, Chest pain: $chestPain, SOB: $shortnessOfBreath');
    try {
      final requestBody = {
        'age': age,
        'chest_pain': chestPain,
        'shortness_of_breath': shortnessOfBreath,
      };
      print('DEBUG: Risk assessment request body: $requestBody');
      
      final response = await http.post(
        Uri.parse('$_baseUrl/assess-risk'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(requestBody),
      );
      
      print('DEBUG: Risk assessment response status: ${response.statusCode}');
      print('DEBUG: Risk assessment response body: ${response.body}');
      
      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        print('DEBUG: Parsed risk assessment result: $result');
        return result;
      }
    } catch (e) {
      print('DEBUG: Risk assessment error: $e');
    }
    
    final fallback = {'risk_level': 'low', 'risk_score': 0.0};
    print('DEBUG: Using fallback risk assessment: $fallback');
    return fallback;
  }

  static Future<List<Map<String, dynamic>>> findAvailableDoctors(String specialization) async {
    try {
      return await SupabaseService.searchAvailableDoctors(specialization);
    } catch (e) {
      return [];
    }
  }
}