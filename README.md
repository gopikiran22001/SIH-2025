# MedVita Flutter App

## Quick Start
```bash
flutter pub get
flutter run
```

## Features
- 🎥 Video consultations with HMS SDK
- 🤖 AI-powered symptom analysis
- 💬 Real-time chat with doctors
- 📱 Offline support with auto-sync
- 🔒 Secure healthcare data handling

## Architecture
- **Frontend**: Flutter with Provider state management
- **Backend**: Supabase (PostgreSQL + Real-time)
- **Video**: HMS SDK for consultations
- **AI**: Flask API with ML models
- **Storage**: Hive for offline data

## Configuration
1. Setup Supabase project and run migrations
2. Configure HMS for video calling
3. Add Firebase for push notifications
4. Update API endpoints in services

## Project Structure
```
lib/
├── screens/     # Patient & Doctor UI
├── services/    # API & Business logic
├── models/      # Data models
└── widgets/     # Reusable components
```

See main README.md for detailed setup instructions.