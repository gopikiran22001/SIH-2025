
import 'supabase_service.dart';
import 'hms_token_service.dart';

class ConsultationMigrationService {
  /// Migrates existing consultations to use unique room IDs
  static Future<void> migrateExistingConsultations() async {
    print('DEBUG: ConsultationMigrationService.migrateExistingConsultations called');
    
    try {
      print('DEBUG: Starting consultation migration...');
      
      // Get all consultations without room_id
      print('DEBUG: Fetching consultations without room_id...');
      final consultations = await SupabaseService.client
          .from('video_consultations')
          .select('*')
          .isFilter('room_id', null);
      
      print('DEBUG: Found ${consultations.length} consultations to migrate');
      
      if (consultations.isEmpty) {
        print('DEBUG: No consultations need migration');
        return;
      }
      
      for (int i = 0; i < consultations.length; i++) {
        final consultation = consultations[i];
        try {
          final consultationId = consultation['id'];
          final doctorId = consultation['doctor_id'];
          final patientId = consultation['patient_id'];
          
          print('DEBUG: Migrating consultation ${i + 1}/${consultations.length}: $consultationId');
          print('DEBUG: Doctor ID: $doctorId, Patient ID: $patientId');
          
          // Create unique room for this consultation
          print('DEBUG: Creating room for consultation $consultationId...');
          final roomId = await HMSTokenService.createRoom(
            doctorId: doctorId,
            patientId: patientId,
          );
          print('DEBUG: Room created: $roomId');
          
          // Update consultation with room_id
          print('DEBUG: Updating consultation with room_id...');
          await SupabaseService.client
              .from('video_consultations')
              .update({'room_id': roomId})
              .eq('id', consultationId);
          
          print('DEBUG: Successfully migrated consultation $consultationId to room $roomId');
          
        } catch (e) {
          print('DEBUG: Failed to migrate consultation ${consultation['id']}: $e');
          print('DEBUG: Error type: ${e.runtimeType}');
          // Continue with next consultation
        }
      }
      
      print('DEBUG: Migration completed successfully');
      
    } catch (e) {
      print('DEBUG: Migration failed: $e');
      print('DEBUG: Error type: ${e.runtimeType}');
      throw Exception('Failed to migrate consultations: $e');
    }
  }
  
  /// Checks if migration is needed
  static Future<bool> isMigrationNeeded() async {
    print('DEBUG: ConsultationMigrationService.isMigrationNeeded called');
    
    try {
      print('DEBUG: Checking for consultations without room_id...');
      final consultations = await SupabaseService.client
          .from('video_consultations')
          .select('id')
          .isFilter('room_id', null);
      
      final needsMigration = consultations.isNotEmpty;
      print('DEBUG: Migration needed: $needsMigration (${consultations.length} consultations)');
      return needsMigration;
    } catch (e) {
      print('DEBUG: Error checking migration status: $e');
      print('DEBUG: Error type: ${e.runtimeType}');
      return false;
    }
  }
  
  /// Runs migration if needed
  static Future<void> runMigrationIfNeeded() async {
    print('DEBUG: ConsultationMigrationService.runMigrationIfNeeded called');
    
    try {
      print('DEBUG: Checking if migration is needed...');
      final needsMigration = await isMigrationNeeded();
      
      if (needsMigration) {
        print('DEBUG: Migration needed, starting migration process...');
        await migrateExistingConsultations();
        print('DEBUG: Migration process completed');
      } else {
        print('DEBUG: No migration needed - all consultations have room_id');
      }
    } catch (e) {
      print('DEBUG: Migration check/run failed: $e');
      print('DEBUG: Error type: ${e.runtimeType}');
      // Don't throw - app should continue to work even if migration fails
      print('DEBUG: App will continue despite migration failure');
    }
  }
}