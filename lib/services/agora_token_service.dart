import 'dart:convert';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';class AgoraTokenService {
  static const String appId = 'bcaae392e0bf44e48711b636180aeb98';
  static const String appCertificate = 'c909aefb5a884d44b9a026c4c88990d5';
  
  // For now, use empty tokens for testing - Agora allows this for development
  static String generateRtcToken({
    required String channelName,
    required int uid,
    int expireTime = 3600,
  }) {
    return '';
  }
