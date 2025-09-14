# 100ms Flutter SDK Integration Setup

## Overview
This app uses 100ms Flutter SDK for 1:1 doctor-patient video consultations with proper authentication and session management.

## Prerequisites

### 1. 100ms Account Setup
- Create account at [100ms.live](https://100ms.live)
- Create a new app in the dashboard
- Note down your App ID and App Secret
- Set up templates for doctor and patient roles

### 2. Flutter Dependencies
Added to `pubspec.yaml`:
```yaml
hmssdk_flutter: ^1.10.0
```

## Configuration

### 1. Backend Token Generation
Create a backend service to generate 100ms room tokens:

```javascript
// Example Node.js backend
const jwt = require('jsonwebtoken');

function generateHMSToken(roomId, userId, role) {
  const payload = {
    access_key: 'YOUR_ACCESS_KEY',
    room_id: roomId,
    user_id: userId,
    role: role, // 'doctor' or 'patient'
    type: 'app',
    version: 2,
    iat: Math.floor(Date.now() / 1000),
    nbf: Math.floor(Date.now() / 1000)
  };
  
  return jwt.sign(payload, 'YOUR_APP_SECRET', {
    algorithm: 'HS256',
    expiresIn: '24h',
    jwtid: uuid.v4()
  });
}
```

### 2. Android Configuration
Add to `android/app/src/main/AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.CAMERA" />
<uses-permission android:name="android.permission.RECORD_AUDIO" />
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
<uses-permission android:name="android.permission.CHANGE_NETWORK_STATE" />
<uses-permission android:name="android.permission.MODIFY_AUDIO_SETTINGS" />
```

### 3. iOS Configuration
Add to `ios/Runner/Info.plist`:

```xml
<key>NSCameraUsageDescription</key>
<string>This app needs camera access for video consultations</string>
<key>NSMicrophoneUsageDescription</key>
<string>This app needs microphone access for video consultations</string>
```

## Features Implemented

### 1. HMS Consultation Service
- **Room Creation**: Creates unique room for each consultation
- **Token Management**: Handles authentication tokens for participants
- **Session Management**: Join, leave, and manage video sessions
- **Audio/Video Controls**: Mute/unmute, camera toggle, camera switch
- **Event Handling**: Peer join/leave, track updates, error handling

### 2. Video Call UI
- **Full-screen remote video**: Main participant view
- **Picture-in-picture local video**: Small overlay for self-view
- **Call controls**: Audio, video, camera switch, end call
- **Prescription creation**: Doctors can create prescriptions during calls
- **Connection status**: Real-time connection and participant count

### 3. Database Integration
- Uses existing `video_consultations` table
- Stores room IDs and auth tokens
- Maintains consultation lifecycle (pending → active → completed)
- Compatible with existing appointment system

## Authentication Flow

### 1. Consultation Creation
1. Patient books appointment with doctor
2. System creates consultation record in database
3. Backend generates 100ms room and auth tokens
4. Tokens stored in `patient_token` and `doctor_token` fields

### 2. Joining Session
1. Participant clicks "Join Consultation"
2. App retrieves auth token from database
3. HMS SDK joins room with token and user details
4. Video call begins with proper role-based permissions

### 3. Session Management
- **Doctor Role**: Can control room settings, create prescriptions
- **Patient Role**: Standard participant with video/audio controls
- **1:1 Limitation**: Room configured for maximum 2 participants

## Event Handling

### Implemented Callbacks
- `onJoin`: User successfully joins room
- `onPeerUpdate`: Other participant joins/leaves
- `onTrackUpdate`: Video/audio tracks added/removed
- `onError`: Handle connection and SDK errors

### UI Updates
- Connection status indicators
- Participant count display
- Video track rendering
- Error message display

## Security Features

### 1. Token-based Authentication
- JWT tokens with expiration
- Role-based access control
- Secure room access

### 2. Session Isolation
- Unique room per consultation
- Automatic cleanup after session ends
- No cross-consultation access

## Testing

### Development Testing
1. Test with two devices/emulators
2. Verify camera and microphone permissions
3. Test all call controls (mute, video, camera switch)
4. Test prescription creation flow
5. Verify proper session cleanup

### Production Checklist
- [ ] Backend token generation service deployed
- [ ] 100ms dashboard configured with proper templates
- [ ] Camera/microphone permissions working
- [ ] Network connectivity handling
- [ ] Error scenarios tested
- [ ] HIPAA compliance verified (if required)

## Troubleshooting

### Common Issues
1. **Token Invalid**: Check backend token generation
2. **Permission Denied**: Verify camera/microphone permissions
3. **Connection Failed**: Check network and 100ms service status
4. **Video Not Showing**: Verify track updates and rendering

### Debug Logs
Enable HMS SDK logging for troubleshooting:
```dart
// Add to HMS initialization
HMSLogSettings logSettings = HMSLogSettings(
  level: HMSLogLevel.VERBOSE,
  isLogStorageEnabled: true
);
```

## Migration Benefits

### From Previous Solutions
- **Reliability**: Enterprise-grade 100ms infrastructure
- **Scalability**: Handles high-quality video at scale
- **Features**: Advanced video controls and customization
- **Compliance**: Built-in security and privacy features
- **Maintenance**: Reduced complexity compared to WebRTC

### Maintained Compatibility
- All existing consultation history preserved
- Database schema unchanged
- User authentication system intact
- Appointment booking flow maintained

## Next Steps

1. **Backend Integration**: Implement token generation service
2. **100ms Dashboard**: Configure room templates and roles
3. **Testing**: Comprehensive testing on physical devices
4. **Deployment**: Production deployment with proper credentials
5. **Monitoring**: Set up logging and error tracking

## Support Resources
- [100ms Flutter Documentation](https://www.100ms.live/docs/flutter/v2/foundation/basics)
- [100ms Dashboard](https://dashboard.100ms.live)
- [HMS SDK GitHub](https://github.com/100mslive/100ms-flutter)