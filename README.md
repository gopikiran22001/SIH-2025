# Meditech - Complete Telemedicine Flutter App

A comprehensive telemedicine mobile application built with Flutter and Supabase, featuring AI-powered symptom analysis, real-time chat, video calling, and complete healthcare management.

## Features

### 🏥 Core Telemedicine Features
- **User Authentication** - Secure login/signup for patients, doctors, and pharmacies
- **Role-based Dashboards** - Customized interfaces for different user types
- **Appointment Booking** - Schedule and manage medical appointments
- **Real-time Chat** - Instant messaging between patients and doctors
- **Video Calling** - High-quality video consultations using Agora SDK
- **Prescription Management** - Digital prescriptions and medication tracking

### 🤖 AI-Powered Features
- **Symptom Analysis** - AI-powered symptom checker and condition prediction
- **Risk Assessment** - Intelligent health risk evaluation
- **Doctor Recommendations** - AI-suggested specialist matching
- **Pharmacy Mapping** - Find nearby pharmacies with required medications

### 📱 Mobile-First Design
- **Responsive UI** - Optimized for mobile screens
- **Professional Design** - Clean, medical-grade interface
- **Accessibility** - Compliant with accessibility standards
- **Offline Support** - Basic functionality works offline

### 🔒 Security & Privacy
- **Row Level Security** - Database-level access control
- **HIPAA Compliance Ready** - Healthcare data protection
- **Encrypted Communications** - Secure chat and video calls
- **Audit Trails** - Complete activity logging

## Tech Stack

### Frontend
- **Flutter** - Cross-platform mobile development
- **Provider** - State management
- **Go Router** - Navigation and routing
- **Agora SDK** - Video calling functionality

### Backend
- **Supabase** - Backend-as-a-Service
- **PostgreSQL** - Primary database
- **Supabase Auth** - User authentication
- **Supabase Realtime** - Real-time features
- **Supabase Storage** - File and document storage

### AI Services
- **FastAPI** - AI service backend
- **Scikit-learn** - Machine learning models
- **TF-IDF** - Text analysis for symptoms
- **Custom Models** - Healthcare-specific AI

## Project Structure

```
meditech_app/
├── lib/
│   ├── models/           # Data models
│   │   ├── profile.dart
│   │   ├── patient.dart
│   │   ├── doctor.dart
│   │   ├── appointment.dart
│   │   ├── chat.dart
│   │   ├── prescription.dart
│   │   └── ai_assessment.dart
│   ├── services/         # Business logic
│   │   ├── supabase_service.dart
│   │   ├── ai_service.dart
│   │   └── video_service.dart
│   ├── screens/          # UI screens
│   │   ├── auth/
│   │   ├── patient/
│   │   ├── doctor/
│   │   └── common/
│   ├── widgets/          # Reusable components
│   ├── utils/            # Utilities
│   │   └── app_router.dart
│   └── main.dart         # App entry point
├── assets/               # Static assets
├── SUPABASE_SETUP.md    # Database setup guide
└── README.md            # This file
```

## Getting Started

### Prerequisites
- Flutter SDK (>=3.8.1)
- Dart SDK
- Android Studio / VS Code
- Supabase account
- Agora.io account (for video calling)

### Installation

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd meditech_app
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Setup Supabase**
   - Follow instructions in `SUPABASE_SETUP.md`
   - Update credentials in `lib/services/supabase_service.dart`

4. **Configure AI Service**
   - Ensure the AI service is running (from `../ai-service/`)
   - Update the base URL in `lib/services/ai_service.dart`

5. **Setup Video Calling**
   - Get Agora App ID from agora.io
   - Update App ID in `lib/services/video_service.dart`

6. **Run the app**
   ```bash
   flutter run
   ```

## Configuration

### Supabase Configuration
Update `lib/services/supabase_service.dart`:
```dart
static const String supabaseUrl = 'YOUR_SUPABASE_URL';
static const String supabaseAnonKey = 'YOUR_SUPABASE_ANON_KEY';
```

### AI Service Configuration
Update `lib/services/ai_service.dart`:
```dart
static const String baseUrl = 'YOUR_AI_SERVICE_URL';
```

### Agora Configuration
Update `lib/services/video_service.dart`:
```dart
static const String appId = 'YOUR_AGORA_APP_ID';
```

## Database Schema

The app uses the following main tables:
- `profiles` - User profiles (patients, doctors, pharmacies)
- `patients` - Patient-specific data
- `doctors` - Doctor-specific data
- `appointments` - Medical appointments
- `chats` - Real-time messaging
- `prescriptions` - Digital prescriptions
- `ai_assessments` - AI analysis results

See `SUPABASE_SETUP.md` for complete schema and setup instructions.

## Key Features Implementation

### Authentication Flow
1. User registers with role selection (patient/doctor/pharmacy)
2. Profile created automatically via database trigger
3. Role-specific dashboard redirect
4. Secure session management

### AI Symptom Analysis
1. Patient describes symptoms in natural language
2. Text processed using TF-IDF vectorization
3. Similarity matching against medical knowledge base
4. Risk assessment and specialist recommendations
5. Results stored for doctor review

### Real-time Chat
1. WebSocket connection via Supabase Realtime
2. Message encryption and delivery confirmation
3. File attachment support
4. Online status indicators

### Video Calling
1. Agora SDK integration for high-quality video
2. Call controls (mute, camera, speaker)
3. Screen sharing capabilities
4. Call recording (optional)

### Appointment Management
1. Doctor availability scheduling
2. Patient booking with conflict detection
3. Automated reminders
4. Status tracking and updates

## API Integration

### AI Service Endpoints
- `POST /symptom-analysis` - Analyze symptoms
- `POST /risk-assessment` - Assess health risks
- `POST /find-doctor` - Get specialist recommendations
- `POST /find-pharmacy` - Locate pharmacies

### Supabase Integration
- Authentication via Supabase Auth
- Real-time data via Supabase Realtime
- File storage via Supabase Storage
- Database operations via Supabase Client

## Security Features

### Data Protection
- Row Level Security (RLS) policies
- Encrypted data transmission
- Secure file storage
- HIPAA compliance ready

### Access Control
- Role-based permissions
- API rate limiting
- Session management
- Audit logging

## Testing

### Unit Tests
```bash
flutter test
```

### Integration Tests
```bash
flutter test integration_test/
```

### Manual Testing Checklist
- [ ] User registration and login
- [ ] Profile creation for all roles
- [ ] Appointment booking flow
- [ ] Chat functionality
- [ ] Video calling
- [ ] AI symptom analysis
- [ ] File upload/download
- [ ] Offline functionality

## Deployment

### Android
```bash
flutter build apk --release
```

### iOS
```bash
flutter build ios --release
```

### Web (Optional)
```bash
flutter build web
```

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Submit a pull request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Support

For support and questions:
- Create an issue in the repository
- Check the documentation in `SUPABASE_SETUP.md`
- Review the AI service documentation in `../ai-service/README.md`

## Roadmap

### Phase 1 (Current)
- [x] Basic authentication
- [x] Patient dashboard
- [x] AI symptom analysis
- [x] Real-time chat
- [x] Video calling setup

### Phase 2 (Upcoming)
- [ ] Doctor dashboard completion
- [ ] Prescription management
- [ ] Payment integration
- [ ] Push notifications
- [ ] Advanced AI features

### Phase 3 (Future)
- [ ] Wearable device integration
- [ ] Telemedicine analytics
- [ ] Multi-language support
- [ ] Advanced reporting
- [ ] API for third-party integrations

## Acknowledgments

- Flutter team for the amazing framework
- Supabase for the backend infrastructure
- Agora.io for video calling capabilities
- The open-source community for various packages used