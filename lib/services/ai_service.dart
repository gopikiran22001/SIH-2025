import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class AiService {
  static const String baseUrl = 'http://192.168.31.230:8000';
  
  static Future<Map<String, dynamic>> analyzeSymptoms(String symptoms, {int? age, String? gender}) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/symptom-analysis'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'symptoms': symptoms,
          'age': age,
          'gender': gender,
        }),
      ).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        debugPrint('AI service returned status: ${response.statusCode}');
        return _getMockSymptomAnalysis(symptoms);
      }
    } on TimeoutException {
      debugPrint('AI service timeout - using offline analysis');
      return _getMockSymptomAnalysis(symptoms);
    } catch (e) {
      debugPrint('AI service error: $e - using offline analysis');
      return _getMockSymptomAnalysis(symptoms);
    }
  }
  
  static Future<Map<String, dynamic>> assessRisk(String symptoms, {int? age, String? gender}) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/risk-assessment'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'symptoms': symptoms,
          'age': age,
          'gender': gender,
        }),
      ).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        debugPrint('Risk assessment service returned status: ${response.statusCode}');
        return _getMockRiskAssessment(symptoms);
      }
    } on TimeoutException {
      debugPrint('Risk assessment timeout - using offline assessment');
      return _getMockRiskAssessment(symptoms);
    } catch (e) {
      debugPrint('Risk assessment error: $e - using offline assessment');
      return _getMockRiskAssessment(symptoms);
    }
  }
  
  static Future<Map<String, dynamic>> findDoctors(String condition, {String? location}) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/find-doctor'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'condition': condition,
          'location': location,
        }),
      ).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return _getMockDoctorRecommendations(condition);
      }
    } catch (e) {
      return _getMockDoctorRecommendations(condition);
    }
  }
  
  static Map<String, dynamic> _getMockSymptomAnalysis(String symptoms) {
    final lowerSymptoms = symptoms.toLowerCase();
    
    if (lowerSymptoms.contains('fever') || lowerSymptoms.contains('cough')) {
      return {
        'conditions': [
          {
            'condition': 'Respiratory Infection',
            'specialty': 'General Medicine',
            'severity': 'medium',
            'confidence': 0.75
          },
          {
            'condition': 'Common Cold',
            'specialty': 'General Medicine', 
            'severity': 'low',
            'confidence': 0.65
          }
        ],
        'recommendations': [
          'Consult a general practitioner',
          'Stay hydrated and rest',
          'Monitor temperature regularly'
        ]
      };
    } else if (lowerSymptoms.contains('headache') || lowerSymptoms.contains('pain')) {
      return {
        'conditions': [
          {
            'condition': 'Tension Headache',
            'specialty': 'Neurology',
            'severity': 'low',
            'confidence': 0.70
          }
        ],
        'recommendations': [
          'Consider pain management',
          'Ensure adequate sleep',
          'Consult if symptoms persist'
        ]
      };
    } else {
      return {
        'conditions': [
          {
            'condition': 'General Health Concern',
            'specialty': 'General Medicine',
            'severity': 'low',
            'confidence': 0.50
          }
        ],
        'recommendations': [
          'Consult a healthcare provider',
          'Monitor symptoms',
          'Maintain healthy lifestyle'
        ]
      };
    }
  }
  
  static Map<String, dynamic> _getMockRiskAssessment(String symptoms) {
    final lowerSymptoms = symptoms.toLowerCase();
    
    if (lowerSymptoms.contains('chest pain') || lowerSymptoms.contains('difficulty breathing')) {
      return {
        'risk_level': 'high',
        'confidence': 0.85,
        'recommendations': [
          'Seek immediate medical attention',
          'Visit emergency department',
          'Do not delay treatment'
        ]
      };
    } else if (lowerSymptoms.contains('fever') || lowerSymptoms.contains('severe')) {
      return {
        'risk_level': 'medium',
        'confidence': 0.70,
        'recommendations': [
          'Schedule appointment within 24 hours',
          'Monitor symptoms closely',
          'Seek care if worsening'
        ]
      };
    } else {
      return {
        'risk_level': 'low',
        'confidence': 0.60,
        'recommendations': [
          'Monitor symptoms',
          'Consider consultation if persistent',
          'Maintain good health practices'
        ]
      };
    }
  }
  
  static Map<String, dynamic> _getMockDoctorRecommendations(String condition) {
    return {
      'doctors': [
        {
          'name': 'Dr. Sarah Johnson',
          'specialty': 'General Medicine',
          'rating': 4.8,
          'availability': 'Available today'
        },
        {
          'name': 'Dr. Michael Chen',
          'specialty': 'Internal Medicine',
          'rating': 4.7,
          'availability': 'Available tomorrow'
        }
      ],
      'message': 'Based on your condition, these specialists are recommended'
    };
  }
}