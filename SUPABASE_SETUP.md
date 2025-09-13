# Supabase Setup Instructions for Meditech App

## 1. Create Supabase Project

1. Go to [supabase.com](https://supabase.com) and create a new project
2. Note down your project URL and anon key
3. Update the constants in `lib/services/supabase_service.dart`:
   ```dart
   static const String supabaseUrl = 'YOUR_SUPABASE_URL';
   static const String supabaseAnonKey = 'YOUR_SUPABASE_ANON_KEY';
   ```

## 2. Database Setup

Run the following SQL commands in your Supabase SQL editor to create the required tables:

### Create Tables

```sql
-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Profiles table (extends auth.users)
CREATE TABLE profiles (
    id UUID REFERENCES auth.users(id) PRIMARY KEY,
    role TEXT NOT NULL CHECK (role IN ('patient', 'doctor', 'pharmacy')),
    full_name TEXT,
    phone TEXT,
    gender TEXT,
    dob DATE,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Patients table
CREATE TABLE patients (
    id UUID REFERENCES profiles(id) PRIMARY KEY,
    blood_group TEXT,
    emergency_contact JSONB
);

-- Doctors table
CREATE TABLE doctors (
    id UUID REFERENCES profiles(id) PRIMARY KEY,
    specialization TEXT,
    clinic_name TEXT,
    qualifications TEXT,
    verified BOOLEAN DEFAULT FALSE,
    rating NUMERIC DEFAULT 0
);

-- Pharmacies table
CREATE TABLE pharmacies (
    id UUID REFERENCES profiles(id) PRIMARY KEY,
    address TEXT,
    license_no TEXT
);

-- Pharmacy inventory table
CREATE TABLE pharmacy_inventory (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    pharmacy_id UUID REFERENCES pharmacies(id),
    drug_name TEXT,
    sku TEXT,
    qty INTEGER DEFAULT 0,
    price NUMERIC
);

-- Appointments table
CREATE TABLE appointments (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    patient_id UUID REFERENCES patients(id),
    doctor_id UUID REFERENCES doctors(id),
    scheduled_at TIMESTAMPTZ NOT NULL,
    status TEXT NOT NULL CHECK (status IN ('pending', 'confirmed', 'completed', 'cancelled')),
    video_session JSONB,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Chats table
CREATE TABLE chats (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    conversation_id TEXT,
    sender_id UUID REFERENCES profiles(id),
    receiver_id UUID REFERENCES profiles(id),
    message TEXT,
    meta JSONB,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Prescriptions table
CREATE TABLE prescriptions (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    appointment_id UUID REFERENCES appointments(id),
    patient_id UUID REFERENCES patients(id),
    doctor_id UUID REFERENCES doctors(id),
    content TEXT,
    file_path TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- AI assessments table
CREATE TABLE ai_assessments (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    patient_id UUID REFERENCES patients(id),
    symptoms JSONB,
    result JSONB,
    created_at TIMESTAMPTZ DEFAULT NOW()
);
```

### Row Level Security (RLS) Policies

```sql
-- Enable RLS on all tables
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE patients ENABLE ROW LEVEL SECURITY;
ALTER TABLE doctors ENABLE ROW LEVEL SECURITY;
ALTER TABLE pharmacies ENABLE ROW LEVEL SECURITY;
ALTER TABLE pharmacy_inventory ENABLE ROW LEVEL SECURITY;
ALTER TABLE appointments ENABLE ROW LEVEL SECURITY;
ALTER TABLE chats ENABLE ROW LEVEL SECURITY;
ALTER TABLE prescriptions ENABLE ROW LEVEL SECURITY;
ALTER TABLE ai_assessments ENABLE ROW LEVEL SECURITY;

-- Profiles policies
CREATE POLICY "Users can view own profile" ON profiles FOR SELECT USING (auth.uid() = id);
CREATE POLICY "Users can update own profile" ON profiles FOR UPDATE USING (auth.uid() = id);
CREATE POLICY "Users can insert own profile" ON profiles FOR INSERT WITH CHECK (auth.uid() = id);

-- Patients policies
CREATE POLICY "Patients can view own data" ON patients FOR SELECT USING (auth.uid() = id);
CREATE POLICY "Patients can update own data" ON patients FOR UPDATE USING (auth.uid() = id);
CREATE POLICY "Patients can insert own data" ON patients FOR INSERT WITH CHECK (auth.uid() = id);
CREATE POLICY "Doctors can view patient data" ON patients FOR SELECT USING (
    EXISTS (
        SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'doctor'
    )
);

-- Doctors policies
CREATE POLICY "Doctors can view own data" ON doctors FOR SELECT USING (auth.uid() = id);
CREATE POLICY "Doctors can update own data" ON doctors FOR UPDATE USING (auth.uid() = id);
CREATE POLICY "Doctors can insert own data" ON doctors FOR INSERT WITH CHECK (auth.uid() = id);
CREATE POLICY "Anyone can view verified doctors" ON doctors FOR SELECT USING (verified = true);

-- Appointments policies
CREATE POLICY "Users can view own appointments" ON appointments FOR SELECT USING (
    auth.uid() = patient_id OR auth.uid() = doctor_id
);
CREATE POLICY "Patients can create appointments" ON appointments FOR INSERT WITH CHECK (
    auth.uid() = patient_id AND EXISTS (
        SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'patient'
    )
);
CREATE POLICY "Users can update own appointments" ON appointments FOR UPDATE USING (
    auth.uid() = patient_id OR auth.uid() = doctor_id
);

-- Chats policies
CREATE POLICY "Users can view own chats" ON chats FOR SELECT USING (
    auth.uid() = sender_id OR auth.uid() = receiver_id
);
CREATE POLICY "Users can send chats" ON chats FOR INSERT WITH CHECK (
    auth.uid() = sender_id
);

-- AI assessments policies
CREATE POLICY "Patients can view own assessments" ON ai_assessments FOR SELECT USING (
    auth.uid() = patient_id
);
CREATE POLICY "Patients can create assessments" ON ai_assessments FOR INSERT WITH CHECK (
    auth.uid() = patient_id
);
CREATE POLICY "Doctors can view patient assessments" ON ai_assessments FOR SELECT USING (
    EXISTS (
        SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'doctor'
    )
);

-- Prescriptions policies
CREATE POLICY "Users can view own prescriptions" ON prescriptions FOR SELECT USING (
    auth.uid() = patient_id OR auth.uid() = doctor_id
);
CREATE POLICY "Doctors can create prescriptions" ON prescriptions FOR INSERT WITH CHECK (
    auth.uid() = doctor_id AND EXISTS (
        SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'doctor'
    )
);
```

### Functions and Triggers

```sql
-- Function to create profile on user signup
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO public.profiles (id, role, full_name, phone)
    VALUES (
        NEW.id,
        COALESCE(NEW.raw_user_meta_data->>'role', 'patient'),
        COALESCE(NEW.raw_user_meta_data->>'full_name', ''),
        COALESCE(NEW.raw_user_meta_data->>'phone', '')
    );
    
    -- Create role-specific record
    IF COALESCE(NEW.raw_user_meta_data->>'role', 'patient') = 'patient' THEN
        INSERT INTO public.patients (id) VALUES (NEW.id);
    ELSIF COALESCE(NEW.raw_user_meta_data->>'role', 'patient') = 'doctor' THEN
        INSERT INTO public.doctors (id) VALUES (NEW.id);
    ELSIF COALESCE(NEW.raw_user_meta_data->>'role', 'patient') = 'pharmacy' THEN
        INSERT INTO public.pharmacies (id) VALUES (NEW.id);
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger for new user signup
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE PROCEDURE public.handle_new_user();
```

## 3. Storage Setup

Create storage buckets for file uploads:

```sql
-- Create storage buckets
INSERT INTO storage.buckets (id, name, public) VALUES 
('documents', 'documents', false),
('prescriptions', 'prescriptions', false),
('profile-images', 'profile-images', true);

-- Storage policies
CREATE POLICY "Users can upload own documents" ON storage.objects FOR INSERT WITH CHECK (
    bucket_id = 'documents' AND auth.uid()::text = (storage.foldername(name))[1]
);

CREATE POLICY "Users can view own documents" ON storage.objects FOR SELECT USING (
    bucket_id = 'documents' AND auth.uid()::text = (storage.foldername(name))[1]
);

CREATE POLICY "Doctors can upload prescriptions" ON storage.objects FOR INSERT WITH CHECK (
    bucket_id = 'prescriptions' AND EXISTS (
        SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'doctor'
    )
);

CREATE POLICY "Users can view prescriptions" ON storage.objects FOR SELECT USING (
    bucket_id = 'prescriptions'
);

CREATE POLICY "Anyone can view profile images" ON storage.objects FOR SELECT USING (
    bucket_id = 'profile-images'
);

CREATE POLICY "Users can upload profile images" ON storage.objects FOR INSERT WITH CHECK (
    bucket_id = 'profile-images'
);
```

## 4. Realtime Setup

Enable realtime for chat functionality:

```sql
-- Enable realtime for chats table
ALTER PUBLICATION supabase_realtime ADD TABLE chats;
```

## 5. Environment Configuration

Update your Flutter app configuration:

1. Update `lib/services/supabase_service.dart` with your Supabase credentials
2. Update `lib/services/ai_service.dart` with your AI service URL
3. Update `lib/services/video_service.dart` with your Agora App ID

## 6. Testing

1. Test user registration and login
2. Test profile creation for different roles
3. Test appointment booking
4. Test chat functionality
5. Test AI symptom analysis
6. Test file uploads

## Notes

- Make sure to replace placeholder URLs and keys with your actual Supabase credentials
- The AI service should be running and accessible from your Flutter app
- For video calling, you'll need to set up Agora.io and get your App ID
- Consider implementing proper error handling and validation in production