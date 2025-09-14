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
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/analyze-symptoms'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'symptoms': symptoms}),
      );
      
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
    } catch (e) {
      print('Symptom analysis error: $e');
    }
    
    return {'condition': 'Unknown', 'confidence': 0.0};
  }

  static Future<Map<String, dynamic>> assessRisk(int age, bool chestPain, bool shortnessOfBreath) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/assess-risk'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'age': age,
          'chest_pain': chestPain,
          'shortness_of_breath': shortnessOfBreath,
        }),
      );
      
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
    } catch (e) {
      print('Risk assessment error: $e');
    }
    
    return {'risk_level': 'low', 'risk_score': 0.0};
  }

  static Future<List<Map<String, dynamic>>> findAvailableDoctors(String specialization) async {
    try {
      return await SupabaseService.searchAvailableDoctors(specialization);
    } catch (e) {
      return [];
    }
  }
}