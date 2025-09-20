import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'dart:async';
import '../utils/app_router.dart';
import '../services/local_storage_service.dart';

class IncomingCallScreen extends StatefulWidget {
  final String callerName;
  final String consultationId;
  final String roomId;

  const IncomingCallScreen({
    super.key,
    required this.callerName,
    required this.consultationId,
    required this.roomId,
  });

  @override
  State<IncomingCallScreen> createState() => _IncomingCallScreenState();
}

class _IncomingCallScreenState extends State<IncomingCallScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _fadeController;
  late AnimationController _rippleController;
  Timer? _ringtoneTimer;
  int _countdown = 3;

  @override
  void initState() {
    super.initState();
    
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat(reverse: true);
    
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _rippleController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat();
    
    _fadeController.forward();
    _keepScreenOn();
    _startCountdown();
    _playRingtone();
  }

  void _startCountdown() {
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted && _countdown > 1) {
        setState(() => _countdown--);
        _startCountdown();
      } else if (mounted) {
        _autoAnswer();
      }
    });
  }

  void _keepScreenOn() async {
    try {
      await WakelockPlus.enable();
      print('DEBUG: Screen wakelock enabled');
    } catch (e) {
      print('DEBUG: Wakelock not available, using alternative method');
      // Fallback: just ensure screen stays interactive
    }
  }
  
  void _playRingtone() async {
    print('DEBUG: Starting basic notification');
    
    // Try multiple notification methods
    try {
      HapticFeedback.vibrate();
      SystemSound.play(SystemSoundType.alert);
    } catch (e) {
      print('DEBUG: Primary notification failed: $e');
    }
    
    // Repeat every 2 seconds
    _ringtoneTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (mounted && _countdown > 0) {
        try {
          HapticFeedback.vibrate();
          SystemSound.play(SystemSoundType.alert);
        } catch (e) {
          print('DEBUG: Notification repeat failed: $e');
        }
      } else {
        timer.cancel();
      }
    });
  }

  void _autoAnswer() {
    if (!mounted) return;
    
    _stopRingtone();
    AppRouter.pushReplacement(
      '/hms-video-call?consultationId=${widget.consultationId}',
      arguments: {
        'consultationId': widget.consultationId,
        'roomId': widget.roomId,
        'callerName': widget.callerName,
      },
    );
  }
  
  void _stopRingtone() {
    _ringtoneTimer?.cancel();
    try {
      WakelockPlus.disable();
    } catch (e) {
      print('DEBUG: Wakelock disable failed: $e');
    }
  }

  void _answerNow() {
    _autoAnswer();
  }

  void _decline() {
    _stopRingtone();
    if (mounted) {
      final currentUser = LocalStorageService.getCurrentUser();
      if (currentUser != null && currentUser['role'] == 'doctor') {
        Navigator.of(context).pushNamedAndRemoveUntil('/doctor-dashboard', (route) => false);
      } else {
        Navigator.of(context).pop();
      }
    }
  }

  @override
  void dispose() {
    _stopRingtone();
    _pulseController.dispose();
    _fadeController.dispose();
    _rippleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    
    return Scaffold(
      backgroundColor: Colors.black87,
      body: FadeTransition(
        opacity: _fadeController,
        child: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFF1A1A2E),
                Color(0xFF16213E),
                Color(0xFF0F3460),
              ],
            ),
          ),
          child: SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(),
                
                // Caller Avatar with Ripple Effect
                Stack(
                  alignment: Alignment.center,
                  children: [
                    AnimatedBuilder(
                      animation: _rippleController,
                      builder: (context, child) {
                        return Stack(
                          alignment: Alignment.center,
                          children: List.generate(3, (index) {
                            final delay = index * 0.3;
                            final animValue = (_rippleController.value - delay).clamp(0.0, 1.0);
                            return Transform.scale(
                              scale: 1.0 + (animValue * 2.0),
                              child: Container(
                                width: 160,
                                height: 160,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: const Color(0xFF00B4D8).withOpacity(1.0 - animValue),
                                    width: 2,
                                  ),
                                ),
                              ),
                            );
                          }),
                        );
                      },
                    ),
                    AnimatedBuilder(
                      animation: _pulseController,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: 1.0 + (_pulseController.value * 0.05),
                          child: Container(
                            width: 140,
                            height: 140,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: const LinearGradient(
                                colors: [Color(0xFF00B4D8), Color(0xFF0077B6)],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF00B4D8).withOpacity(0.4),
                                  blurRadius: 30,
                                  spreadRadius: 10,
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.videocam,
                              size: 70,
                              color: Colors.white,
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
                
                const SizedBox(height: 24),
                
                // Incoming call text
                const Text(
                  'Incoming Video Call',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                
                const SizedBox(height: 8),
                
                // Caller name
                Text(
                  widget.callerName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 32),
                
                // Auto-answer countdown with progress
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: Colors.white.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(0xFF00B4D8),
                        ),
                        child: Center(
                          child: Text(
                            '$_countdown',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Auto-answering...',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                
                const Spacer(),
                
                // Action buttons
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Decline button
                      GestureDetector(
                        onTap: _decline,
                        child: Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(
                              colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFEF4444).withOpacity(0.4),
                                blurRadius: 20,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.call_end,
                            color: Colors.white,
                            size: 36,
                          ),
                        ),
                      ),
                      
                      // Answer now button
                      GestureDetector(
                        onTap: _answerNow,
                        child: Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(
                              colors: [Color(0xFF10B981), Color(0xFF059669)],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF10B981).withOpacity(0.4),
                                blurRadius: 20,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.videocam,
                            color: Colors.white,
                            size: 36,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 50),
              ],
            ),
          ),
        ),
      ),
    );
  }
}