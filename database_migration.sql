-- Add room_id column to video_consultations table
ALTER TABLE video_consultations 
ADD COLUMN room_id TEXT;

-- Create index for better performance
CREATE INDEX IF NOT EXISTS idx_video_consultations_room_id 
ON video_consultations(room_id);

-- Update existing consultations with unique room IDs (migration script)
-- This will be handled by the migration service in Flutter