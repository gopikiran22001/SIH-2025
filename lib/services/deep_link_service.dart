import 'dart:async';
import 'package:flutter/services.dart';
import '../utils/app_router.dart';
import '../config/pusher_config.dart';

class DeepLinkService {
  static const MethodChannel _channel = MethodChannel('medvita/deep_links');
  static StreamSubscription<String>? _linkSubscription;
  
  static Future<void> initialize() async {
    try {
      print('DEBUG: Deep link service initialized (native implementation required)');
    } catch (e) {
      print('DEBUG: Error initializing deep link service: $e');
    }
  }
  
  static void _handleDeepLink(String link) {
    try {
      final uri = Uri.parse(link);
      
      if (uri.scheme == PusherConfig.deepLinkScheme) {
        switch (uri.host) {
          case 'video-call':
            _handleVideoCallLink(uri);
            break;
          default:
            print('DEBUG: Unknown deep link host: ${uri.host}');
        }
      }
    } catch (e) {
      print('DEBUG: Error handling deep link: $e');
    }
  }
  
  static void _handleVideoCallLink(Uri uri) {
    final consultationId = uri.queryParameters['consultationId'];
    final roomId = uri.queryParameters['roomId'];
    final callerName = uri.queryParameters['callerName'];
    
    if (consultationId != null && roomId != null) {
      print('DEBUG: Navigating to video call: $consultationId');
      
      AppRouter.push(
        '/hms-video-call?consultationId=$consultationId',
        arguments: {
          'consultationId': consultationId,
          'roomId': roomId,
          'callerName': callerName ?? 'Unknown',
        },
      );
    } else {
      print('DEBUG: Invalid video call deep link parameters');
    }
  }
  
  static void dispose() {
    _linkSubscription?.cancel();
    _linkSubscription = null;
  }
}