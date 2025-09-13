import '../services/supabase_service.dart';

class AiBookingService {
  static Future<Map<String, dynamic>> getSpecializationSuggestion(String symptoms) async {
    final lowerSymptoms = symptoms.toLowerCase();
    
    if (lowerSymptoms.contains('heart') || lowerSymptoms.contains('chest')) {
      return {'specialization': 'Cardiology', 'confidence': 0.8};
    } else if (lowerSymptoms.contains('skin') || lowerSymptoms.contains('rash')) {
      return {'specialization': 'Dermatology', 'confidence': 0.7};
    } else if (lowerSymptoms.contains('eye') || lowerSymptoms.contains('vision')) {
      return {'specialization': 'Ophthalmology', 'confidence': 0.8};
    } else if (lowerSymptoms.contains('bone') || lowerSymptoms.contains('joint')) {
      return {'specialization': 'Orthopedics', 'confidence': 0.7};
    } else if (lowerSymptoms.contains('mental') || lowerSymptoms.contains('anxiety')) {
      return {'specialization': 'Psychiatry', 'confidence': 0.8};
    }
    
    return {'specialization': 'General Medicine', 'confidence': 0.6};
  }

  static Future<List<Map<String, dynamic>>> findAvailableDoctors(String specialization) async {
    try {
      return await SupabaseService.searchAvailableDoctors(specialization);
    } catch (e) {
      return [];
    }
  }
}