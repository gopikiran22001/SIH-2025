// Run this script to manually migrate existing consultations
// Usage: dart run migration_script.dart

import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'lib/services/consultation_migration_service.dart';
import 'lib/services/supabase_service.dart';

void main() async {
  print('🚀 Starting consultation migration...');
  
  try {
    // Initialize Supabase
    await SupabaseService.initialize();
    
    // Check if migration is needed
    final needsMigration = await ConsultationMigrationService.isMigrationNeeded();
    
    if (!needsMigration) {
      print('✅ No migration needed - all consultations already have room_id');
      return;
    }
    
    print('📊 Migration needed - starting process...');
    
    // Run migration
    await ConsultationMigrationService.migrateExistingConsultations();
    
    print('✅ Migration completed successfully!');
    
  } catch (e) {
    print('❌ Migration failed: $e');
    exit(1);
  }
}