class PusherConfig {
  // Replace with your actual Pusher Beams Instance ID
  static const String instanceId = 'adbdf788-3dd4-4a9a-a1c2-c653e2bf0386';
  
  // Deep link scheme for the app
  static const String deepLinkScheme = 'medvita';
  
  // Notification interests
  static const String generalInterest = 'general';
  
  static String userInterest(String userId) => 'user-$userId';
}