# Pusher Beams Setup Guide for MedVita

## Overview
This guide explains how to complete the Pusher Beams integration for MedVita after migrating from OneSignal.

## 1. Pusher Beams Dashboard Setup

### Create Pusher Beams Instance
1. Go to [Pusher Beams Dashboard](https://dashboard.pusher.com/beams)
2. Create a new Beams instance
3. Note your **Instance ID** (e.g., `12345678-1234-1234-1234-123456789012`)
4. Get your **Secret Key** from the instance settings

### Configure FCM for Android
1. In your Pusher Beams instance, go to "Settings" → "FCM"
2. Upload your `google-services.json` file or enter your FCM Server Key
3. Enable FCM for Android notifications

### Configure APNs for iOS (if needed)
1. In your Pusher Beams instance, go to "Settings" → "APNs"
2. Upload your APNs certificate or configure APNs key
3. Enable APNs for iOS notifications

## 2. Update Configuration Files

### Update Pusher Config
Edit `lib/config/pusher_config.dart`:
```dart
class PusherConfig {
  // Replace with your actual Pusher Beams Instance ID
  static const String instanceId = 'YOUR_ACTUAL_INSTANCE_ID_HERE';
  
  // Deep link scheme for the app
  static const String deepLinkScheme = 'medvita';
  
  // Notification interests
  static const String generalInterest = 'general';
  
  static String userInterest(String userId) => 'user-$userId';
}
```

### Update Pusher Beams Service
Edit `lib/services/pusher_beams_service.dart` and update the auth URL:
```dart
BeamsAuthProvider()..authUrl = 'YOUR_SUPABASE_URL/functions/v1/pusher-auth'
```

## 3. Supabase Configuration

### Set Environment Variables
In your Supabase project, go to Settings → Edge Functions and add these secrets:
```
PUSHER_BEAMS_INSTANCE_ID=your_instance_id_here
PUSHER_BEAMS_SECRET_KEY=your_secret_key_here
```

### Deploy Edge Functions
Deploy the Pusher Beams functions:
```bash
# Deploy notification sender
supabase functions deploy send-pusher-notification

# Deploy auth endpoint
supabase functions deploy pusher-auth
```

## 4. Android Configuration

### Add FCM Configuration
1. Download `google-services.json` from Firebase Console
2. Place it in `android/app/` directory
3. Update `android/app/build.gradle.kts`:
```kotlin
plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services") // Add this line
}
```

### Update Dependencies
Add to `android/app/build.gradle.kts`:
```kotlin
dependencies {
    implementation("com.google.firebase:firebase-messaging:23.0.0")
}
```

## 5. iOS Configuration (if supporting iOS)

### Add APNs Entitlements
Create `ios/Runner/Runner.entitlements`:
```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>aps-environment</key>
    <string>development</string> <!-- Use 'production' for release -->
</dict>
</plist>
```

### Update iOS Project Settings
1. Open `ios/Runner.xcworkspace` in Xcode
2. Select Runner target → Signing & Capabilities
3. Add "Push Notifications" capability
4. Add "Background Modes" capability with "Background processing" and "Remote notifications"

## 6. Testing the Integration

### Test Notification Flow
1. Run the app and login as a user
2. Check logs for successful Pusher Beams initialization
3. Create a video consultation to trigger notifications
4. Verify notifications appear and deep links work

### Debug Common Issues
- **No notifications received**: Check FCM configuration and Pusher Beams instance settings
- **Deep links not working**: Verify AndroidManifest.xml intent filters
- **Auth errors**: Check Supabase Edge Function deployment and secrets

## 7. Production Deployment

### Update Build Configuration
1. Change APNs environment to 'production' for iOS
2. Use release FCM configuration for Android
3. Update Pusher Beams instance settings for production

### Security Considerations
- Keep Pusher Beams Secret Key secure in Supabase secrets
- Use HTTPS for all API endpoints
- Validate user authentication in pusher-auth function

## 8. Monitoring and Analytics

### Pusher Beams Dashboard
- Monitor notification delivery rates
- Track user engagement with notifications
- Debug failed notifications

### Application Logs
- Monitor deep link handling
- Track notification reception
- Log authentication issues

## Migration Complete ✅

Your MedVita app now uses Pusher Beams instead of OneSignal for:
- ✅ Push notifications for video calls
- ✅ Deep link handling for notification taps
- ✅ User-specific notification targeting
- ✅ Background notification delivery
- ✅ Cross-platform support (Android/iOS)

## Support

For issues with this integration:
1. Check Pusher Beams documentation
2. Verify Supabase Edge Function logs
3. Test notification delivery in Pusher dashboard
4. Review Flutter app logs for errors