# MedVita - Complete Telemedicine Flutter App

[![Flutter](https://img.shields.io/badge/Flutter-3.8.1-blue.svg)](https://flutter.dev/)
[![Dart](https://img.shields.io/badge/Dart-3.0+-blue.svg)](https://dart.dev/)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

**MedVita** is a comprehensive telemedicine platform built with Flutter, providing seamless healthcare delivery through video consultations, AI-powered symptom analysis, and real-time communication between patients and doctors.

## 🚀 Quick Start

```bash
# Clone the repository
git clone https://github.com/your-repo/medvita-app.git
cd medvita-app

# Install dependencies
flutter pub get

# Run the app
flutter run
```

## ✨ Features

### 🎥 **Video Consultations**
- HD video calls using HMS SDK
- Real-time audio/video streaming
- Screen sharing and recording capabilities
- Automatic call quality optimization

### 🤖 **AI-Powered Health Assistant**
- Intelligent symptom analysis
- Risk assessment based on patient data
- Doctor specialization recommendations
- ML-driven health insights

### 💬 **Real-time Communication**
- Instant messaging with doctors
- Push notifications for appointments
- Message history and file sharing
- Online/offline status indicators

### 📱 **Offline-First Architecture**
- Works without internet connection
- Automatic data synchronization
- Local data caching with Hive
- Queue offline operations

### 🔒 **Security & Privacy**
- HIPAA-compliant data handling
- End-to-end encryption
- Secure authentication with Supabase
- Protected health information (PHI) compliance

### 📊 **Comprehensive Health Records**
- Digital prescriptions
- Medical history tracking
- AI assessment records
- Appointment scheduling

## 🏗️ Architecture

### **Tech Stack**
- **Frontend**: Flutter 3.8.1 with Provider state management
- **Backend**: Supabase (PostgreSQL + Real-time subscriptions)
- **Video Calling**: HMS SDK for WebRTC
- **AI Services**: Flask API with ML models (hosted on Render)
- **Local Storage**: Hive for offline data persistence
- **Push Notifications**: Firebase Cloud Messaging
- **Authentication**: Supabase Auth with JWT tokens

### **System Architecture**
```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Flutter App   │◄──►│   Supabase      │◄──►│   PostgreSQL    │
│   (Frontend)    │    │   (Backend)     │    │   (Database)    │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                       │
         ▼                       ▼
┌─────────────────┐    ┌─────────────────┐
│   HMS SDK       │    │   Firebase      │
│   (Video)       │    │   (Notifications)│
└─────────────────┘    └─────────────────┘
         │
         ▼
┌─────────────────┐    ┌─────────────────┐
│   Hive DB       │    │   Flask ML API  │
│   (Offline)     │    │   (AI Services) │
└─────────────────┘    └─────────────────┘
```

## 📁 Project Structure

```
lib/
├── main.dart                 # App entry point
├── models/                   # Data models
│   ├── patient.dart
│   ├── doctor.dart
│   ├── appointment.dart
│   ├── prescription.dart
│   └── ai_assessment.dart
├── screens/                  # UI Screens
│   ├── auth/                # Authentication
│   │   ├── login_screen.dart
│   │   └── register_screen.dart
│   ├── patient/             # Patient Interface
│   │   ├── patient_dashboard.dart
│   │   ├── symptom_checker_screen.dart
│   │   ├── appointments_tab.dart
│   │   └── profile_tab.dart
│   ├── doctor/              # Doctor Interface
│   │   ├── doctor_dashboard.dart
│   │   ├── doctor_consultations_tab.dart
│   │   └── doctor_profile_tab.dart
│   └── common/              # Shared Screens
│       ├── chat_screen.dart
│       └── hms_video_call_screen.dart
├── services/                # Business Logic
│   ├── supabase_service.dart
│   ├── hms_consultation_service.dart
│   ├── ai_booking_service.dart
│   ├── notification_service.dart
│   ├── local_storage_service.dart
│   └── offline_sync_service.dart
├── utils/                   # Utilities
│   ├── app_router.dart
│   └── error_handler.dart
└── widgets/                 # Reusable Components
    ├── app_bottom_navigation.dart
    ├── loading_overlay.dart
    └── offline_indicator.dart
```

## 🛠️ Setup & Configuration

### **Prerequisites**
- Flutter SDK 3.8.1 or higher
- Dart 3.0+
- Android Studio / VS Code
- Git

### **1. Supabase Setup**
```sql
-- Run database migrations
-- Create tables: profiles, patients, doctors, appointments, 
-- video_consultations, chats, ai_assessments, prescriptions

-- Add RLS policies for data security
-- Configure real-time subscriptions
```

### **2. HMS SDK Configuration**
```dart
// Add HMS credentials in hms_token_service.dart
static const String HMS_APP_ID = 'your_hms_app_id';
static const String HMS_APP_SECRET = 'your_hms_app_secret';
```

### **3. Firebase Setup**
```bash
# Install Firebase CLI
npm install -g firebase-tools

# Configure Firebase project
flutter pub add firebase_core firebase_messaging
flutter pub get
```

### **4. Environment Variables**
```dart
// Update supabase_service.dart
static const String supabaseUrl = 'your_supabase_url';
static const String supabaseAnonKey = 'your_supabase_anon_key';

// Update ai_booking_service.dart
static const String _baseUrl = 'your_ml_api_endpoint';
```

## 🔄 User Workflows

### **Patient Journey**
1. **Registration** → Profile setup → Health information
2. **Symptom Analysis** → AI assessment → Doctor recommendation
3. **Appointment Booking** → Doctor selection → Video consultation
4. **Consultation** → Video call → Prescription → Follow-up

### **Doctor Journey**
1. **Registration** → Professional verification → Profile setup
2. **Patient Management** → View requests → Accept consultations
3. **Video Consultation** → Diagnosis → Prescription creation
4. **Follow-up** → Patient history → Treatment tracking

## 📊 Database Schema

### **Core Tables**
- `profiles` - User information (patients & doctors)
- `patients` - Patient-specific data (blood group, emergency contact)
- `doctors` - Doctor-specific data (specialization, qualifications)
- `video_consultations` - Video call records with HMS room_id
- `appointments` - Scheduled appointments
- `chats` - Real-time messaging
- `ai_assessments` - AI symptom analysis results
- `prescriptions` - Doctor prescriptions
- `medical_records` - Patient medical history

## 🚀 Deployment

### **Android**
```bash
flutter build apk --release
# or
flutter build appbundle --release
```

### **iOS**
```bash
flutter build ios --release
```

### **Web**
```bash
flutter build web --release
```

## 🧪 Testing

```bash
# Run unit tests
flutter test

# Run integration tests
flutter drive --target=test_driver/app.dart

# Run widget tests
flutter test test/widget_test.dart
```

## 📱 Supported Platforms

- ✅ Android (API 21+)
- ✅ iOS (12.0+)
- ✅ Web (Chrome, Firefox, Safari)
- 🔄 Windows (Coming Soon)
- 🔄 macOS (Coming Soon)

## 🤝 Contributing

1. Fork the repository
2. Create feature branch (`git checkout -b feature/amazing-feature`)
3. Commit changes (`git commit -m 'Add amazing feature'`)
4. Push to branch (`git push origin feature/amazing-feature`)
5. Open Pull Request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🆘 Support

- 📧 Email: support@medvita.com
- 💬 Discord: [MedVita Community](https://discord.gg/medvita)
- 📖 Documentation: [docs.medvita.com](https://docs.medvita.com)
- 🐛 Issues: [GitHub Issues](https://github.com/your-repo/medvita-app/issues)

## 🙏 Acknowledgments

- [Flutter Team](https://flutter.dev/) for the amazing framework
- [Supabase](https://supabase.com/) for backend infrastructure
- [HMS SDK](https://developer.huawei.com/consumer/en/hms/) for video calling
- [Firebase](https://firebase.google.com/) for push notifications

---

**Made with ❤️ for better healthcare accessibility**