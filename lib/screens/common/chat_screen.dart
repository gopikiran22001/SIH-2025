import 'dart:async';
import 'package:flutter/material.dart';

import '../../services/supabase_service.dart';
import '../../services/local_storage_service.dart';
import '../../services/hms_consultation_service.dart';
import '../../models/chat.dart';

class ChatScreen extends StatefulWidget {
  final String conversationId;
  final String otherUserId;
  final String otherUserName;

  const ChatScreen({
    super.key,
    required this.conversationId,
    required this.otherUserId,
    required this.otherUserName,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  List<Chat> _messages = [];
  bool _isLoading = true;
  bool _isOtherUserOnline = false;
  Timer? _statusTimer;
  bool _isDoctor = false;

  @override
  void initState() {
    super.initState();
    _checkUserRole();
    _loadMessages();
    _subscribeToMessages();
    _checkOtherUserStatus();
    _startStatusMonitoring();
  }

  Future<void> _checkUserRole() async {
    final user = LocalStorageService.getCurrentUser();
    if (user != null) {
      setState(() {
        _isDoctor = user['role'] == 'doctor';
      });
    }
  }

  Future<void> _loadMessages() async {
    print('DEBUG: Loading messages for conversation: ${widget.conversationId}');
    try {
      final messages = await SupabaseService.getMessages(widget.conversationId);
      print('DEBUG: Messages from server: $messages');
      print('DEBUG: Number of messages: ${messages.length}');
      
      await LocalStorageService.cacheMessages(widget.conversationId, messages);
      if (mounted) {
        setState(() {
          _messages = messages.map((m) => Chat.fromJson(m)).toList();
          _isLoading = false;
        });
        print('DEBUG: Parsed messages: $_messages');
        _scrollToBottom();
      }
    } catch (e) {
      print('DEBUG: Error loading messages from server: $e');
      final cachedMessages = LocalStorageService.getCachedMessages(widget.conversationId);
      print('DEBUG: Cached messages: $cachedMessages');
      if (mounted) {
        setState(() {
          _messages = cachedMessages.map((m) => Chat.fromJson(m)).toList();
          _isLoading = false;
        });
        _scrollToBottom();
      }
    }
  }

  void _subscribeToMessages() {
    print('DEBUG: Subscribing to messages for conversation: ${widget.conversationId}');
    SupabaseService.subscribeToMessages(widget.conversationId).listen((messages) {
      print('DEBUG: Real-time messages received: $messages');
      print('DEBUG: Number of real-time messages: ${messages.length}');
      print('DEBUG: Current user ID: ${SupabaseService.currentUser?.id}');
      
      // Check if we're missing messages by comparing with current state
      if (_messages.isNotEmpty && messages.length < _messages.length) {
        print('DEBUG: WARNING - Message count decreased from ${_messages.length} to ${messages.length}');
        print('DEBUG: Previous messages: ${_messages.map((m) => m.message).toList()}');
        print('DEBUG: New messages: ${messages.map((m) => m['message']).toList()}');
        // Don't update if we're losing messages
        return;
      }
      
      if (mounted) {
        final newMessages = messages.map((m) => Chat.fromJson(m)).toList();
        print('DEBUG: Parsed real-time messages: ${newMessages.map((m) => m.message).toList()}');
        setState(() {
          _messages = newMessages;
        });
        _scrollToBottom();
      }
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients && _messages.isNotEmpty) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final screenWidth = screenSize.width;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: const Color(0xFF00B4D8),
              radius: screenWidth * 0.05,
              child: Icon(
                Icons.person,
                color: Colors.white,
                size: screenWidth * 0.05,
              ),
            ),
            SizedBox(width: screenWidth * 0.03),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.otherUserName,
                    style: TextStyle(
                      color: const Color(0xFF1A1A1A),
                      fontWeight: FontWeight.w600,
                      fontSize: screenWidth * 0.04,
                    ),
                  ),
                  Row(
                    children: [
                      Icon(
                        Icons.circle,
                        color: _isOtherUserOnline ? const Color(0xFF0077B6) : Colors.grey,
                        size: screenWidth * 0.025,
                      ),
                      SizedBox(width: screenWidth * 0.01),
                      Text(
                        _isOtherUserOnline ? 'Online' : 'Offline',
                        style: TextStyle(
                          color: _isOtherUserOnline ? const Color(0xFF0077B6) : Colors.grey,
                          fontSize: screenWidth * 0.03,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          if (_isDoctor)
            IconButton(
              icon: Icon(
                Icons.receipt_long,
                color: const Color(0xFF00B4D8),
                size: screenWidth * 0.06,
              ),
              onPressed: _createPrescription,
            ),
          IconButton(
            icon: Icon(
              Icons.videocam,
              color: const Color(0xFF00B4D8),
              size: screenWidth * 0.06,
            ),
            onPressed: _startVideoCall,
          ),
          IconButton(
            icon: Icon(
              Icons.call,
              color: const Color(0xFF00B4D8),
              size: screenWidth * 0.06,
            ),
            onPressed: _startAudioCall,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    controller: _scrollController,
                    padding: EdgeInsets.all(screenWidth * 0.04),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final message = _messages[index];
                      final isMe = message.senderId == SupabaseService.currentUser?.id;
                      return _buildMessageBubble(message, isMe);
                    },
                  ),
          ),
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(Chat message, bool isMe) {
    final screenSize = MediaQuery.of(context).size;
    final screenWidth = screenSize.width;
    final screenHeight = screenSize.height;

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.only(bottom: screenHeight * 0.01),
        padding: EdgeInsets.symmetric(
          horizontal: screenWidth * 0.04,
          vertical: screenHeight * 0.015,
        ),
        constraints: BoxConstraints(
          maxWidth: screenWidth * 0.75,
        ),
        decoration: BoxDecoration(
          color: isMe ? const Color(0xFF00B4D8) : Colors.white,
          borderRadius: BorderRadius.circular(screenWidth * 0.04).copyWith(
            bottomRight: isMe ? Radius.circular(screenWidth * 0.01) : null,
            bottomLeft: !isMe ? Radius.circular(screenWidth * 0.01) : null,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: screenWidth * 0.0125,
              offset: Offset(0, screenHeight * 0.0025),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message.message ?? '',
              style: TextStyle(
                color: isMe ? Colors.white : const Color(0xFF1A1A1A),
                fontSize: screenWidth * 0.035,
              ),
            ),
            SizedBox(height: screenHeight * 0.005),
            Text(
              _formatTime(message.createdAt),
              style: TextStyle(
                color: isMe ? Colors.white70 : const Color(0xFF64748B),
                fontSize: screenWidth * 0.025,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageInput() {
    final screenSize = MediaQuery.of(context).size;
    final screenWidth = screenSize.width;
    final screenHeight = screenSize.height;

    return Container(
      padding: EdgeInsets.all(screenWidth * 0.04),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Color(0xFFE2E8F0)),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            icon: Icon(
              Icons.attach_file,
              color: const Color(0xFF64748B),
              size: screenWidth * 0.06,
            ),
            onPressed: _attachFile,
          ),
          Expanded(
            child: TextField(
              controller: _messageController,
              style: TextStyle(fontSize: screenWidth * 0.035),
              decoration: InputDecoration(
                hintText: 'Type a message...',
                hintStyle: TextStyle(fontSize: screenWidth * 0.035),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(screenWidth * 0.06)),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: const Color(0xFFF1F5F9),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: screenWidth * 0.04,
                  vertical: screenHeight * 0.01,
                ),
              ),
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          SizedBox(width: screenWidth * 0.02),
          Container(
            width: screenWidth * 0.12,
            height: screenWidth * 0.12,
            decoration: const BoxDecoration(
              color: Color(0xFF00B4D8),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: Icon(
                Icons.send,
                color: Colors.white,
                size: screenWidth * 0.05,
              ),
              onPressed: _sendMessage,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _sendMessage() async {
    final messageText = _messageController.text.trim();
    if (messageText.isEmpty) return;

    _messageController.clear();

    final messageData = {
      'conversation_id': widget.conversationId,
      'sender_id': SupabaseService.currentUser?.id,
      'receiver_id': widget.otherUserId,
      'message': messageText,
      'meta': {},
    };
    
    print('DEBUG: Sending message: $messageData');

    try {
      await SupabaseService.sendMessage(messageData);
      print('DEBUG: Message sent successfully');
      
      // Reload messages after sending to ensure it appears
      await _loadMessages();
    } catch (e) {
      print('DEBUG: Failed to send message: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send message: $e')),
        );
      }
    }
  }

  void _attachFile() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('File attachment coming soon')),
    );
  }

  void _createPrescription() {
    print('DEBUG: Create prescription button pressed');
    print('DEBUG: Is doctor: $_isDoctor');
    print('DEBUG: Other user ID: ${widget.otherUserId}');
    print('DEBUG: Other user name: ${widget.otherUserName}');
    
    if (!_isDoctor) {
      print('DEBUG: User is not a doctor, cannot create prescription');
      return;
    }
    
    final currentUser = LocalStorageService.getCurrentUser();
    print('DEBUG: Current user data: $currentUser');
    
    showDialog(
      context: context,
      builder: (context) => _PrescriptionDialog(
        patientId: widget.otherUserId,
        patientName: widget.otherUserName,
        onPrescriptionCreated: () {
          print('DEBUG: Prescription creation callback triggered');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Prescription created successfully')),
          );
        },
      ),
    );
  }

  void _startVideoCall() async {
    try {
      final currentUser = LocalStorageService.getCurrentUser();
      if (currentUser == null) {
        throw Exception('User not logged in');
      }
      
      final isDoctor = currentUser['role'] == 'doctor';
      final patientId = isDoctor ? widget.otherUserId : currentUser['id'];
      final doctorId = isDoctor ? currentUser['id'] : widget.otherUserId;
      
      // Create video consultation
      final consultation = await HMSConsultationService.createVideoConsultation(
        patientId: patientId,
        doctorId: doctorId,
        symptoms: 'Chat consultation request',
      );
      
      if (consultation != null) {
        // Navigate to WebRTC consultation
        Navigator.pushNamed(
          context,
          '/video-consultation/${consultation['id']}',
          arguments: {
            'consultationId': consultation['id'],
            'patientId': patientId,
            'doctorId': doctorId,
            'patientName': isDoctor ? widget.otherUserName : currentUser['full_name'] ?? 'Patient',
            'doctorName': isDoctor ? currentUser['full_name'] ?? 'Doctor' : widget.otherUserName,
          },
        );
      }
    } catch (e) {
      print('DEBUG: Video consultation error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to start video consultation: $e')),
      );
    }
  }

  void _startAudioCall() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Audio call feature coming soon')),
    );
  }

  Future<void> _checkOtherUserStatus() async {
    try {
      final profile = await SupabaseService.getProfile(widget.otherUserId);
      if (mounted && profile != null) {
        setState(() {
          _isOtherUserOnline = profile['status'] == true;
        });
      }
    } catch (e) {
      print('DEBUG: Failed to check user status: $e');
    }
  }

  String _formatTime(DateTime? dateTime) {
    if (dateTime == null) return '';
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${dateTime.day}/${dateTime.month}';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  void _startStatusMonitoring() {
    _statusTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      _checkOtherUserStatus();
    });
  }

  @override
  void dispose() {
    _statusTimer?.cancel();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}

class _PrescriptionDialog extends StatefulWidget {
  final String patientId;
  final String patientName;
  final VoidCallback onPrescriptionCreated;

  const _PrescriptionDialog({
    required this.patientId,
    required this.patientName,
    required this.onPrescriptionCreated,
  });

  @override
  State<_PrescriptionDialog> createState() => _PrescriptionDialogState();
}

class _PrescriptionDialogState extends State<_PrescriptionDialog> {
  final _formKey = GlobalKey<FormState>();
  final _medicinesController = TextEditingController();
  final _dosageController = TextEditingController();
  final _instructionsController = TextEditingController();
  final _notesController = TextEditingController();
  bool _isLoading = false;
  
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        padding: EdgeInsets.all(screenWidth * 0.05),
        constraints: BoxConstraints(
          maxHeight: screenHeight * 0.8,
          maxWidth: screenWidth * 0.9,
        ),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.receipt_long,
                    color: const Color(0xFF00B4D8),
                    size: screenWidth * 0.06,
                  ),
                  SizedBox(width: screenWidth * 0.02),
                  Expanded(
                    child: Text(
                      'Create Prescription',
                      style: TextStyle(
                        fontSize: screenWidth * 0.05,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1A1A1A),
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              SizedBox(height: screenHeight * 0.01),
              Text(
                'Patient: ${widget.patientName}',
                style: TextStyle(
                  fontSize: screenWidth * 0.04,
                  color: const Color(0xFF6B7280),
                ),
              ),
              SizedBox(height: screenHeight * 0.03),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _medicinesController,
                        decoration: const InputDecoration(
                          labelText: 'Medicines',
                          hintText: 'Enter medicine names (one per line)',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 3,
                        validator: (value) {
                          if (value?.isEmpty ?? true) return 'Medicines are required';
                          return null;
                        },
                      ),
                      SizedBox(height: screenHeight * 0.02),
                      TextFormField(
                        controller: _dosageController,
                        decoration: const InputDecoration(
                          labelText: 'Dosage',
                          hintText: 'e.g., 1 tablet twice daily',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value?.isEmpty ?? true) return 'Dosage is required';
                          return null;
                        },
                      ),
                      SizedBox(height: screenHeight * 0.02),
                      TextFormField(
                        controller: _instructionsController,
                        decoration: const InputDecoration(
                          labelText: 'Instructions',
                          hintText: 'Take after meals, etc.',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 2,
                        validator: (value) {
                          if (value?.isEmpty ?? true) return 'Instructions are required';
                          return null;
                        },
                      ),
                      SizedBox(height: screenHeight * 0.02),
                      TextFormField(
                        controller: _notesController,
                        decoration: const InputDecoration(
                          labelText: 'Additional Notes (Optional)',
                          hintText: 'Any additional information',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 2,
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: screenHeight * 0.02),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                  ),
                  SizedBox(width: screenWidth * 0.03),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _createPrescription,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00B4D8),
                      ),
                      child: _isLoading
                          ? SizedBox(
                              width: screenWidth * 0.04,
                              height: screenWidth * 0.04,
                              child: const CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text('Create'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _createPrescription() async {
    print('DEBUG: Prescription form validation started');
    
    if (!_formKey.currentState!.validate()) {
      print('DEBUG: Form validation failed');
      return;
    }
    
    print('DEBUG: Form validation passed, starting prescription creation');
    setState(() => _isLoading = true);

    try {
      final doctorUser = LocalStorageService.getCurrentUser();
      print('DEBUG: Current doctor user: $doctorUser');
      
      if (doctorUser == null) {
        print('DEBUG: No doctor user found in local storage');
        throw Exception('Doctor not found');
      }

      final prescriptionData = {
        'patient_id': widget.patientId,
        'doctor_id': doctorUser['id'],
        'content': 'Medicines: ${_medicinesController.text.trim()}\n\nDosage: ${_dosageController.text.trim()}\n\nInstructions: ${_instructionsController.text.trim()}\n\nNotes: ${_notesController.text.trim()}',
      };
      
      print('DEBUG: Prescription data prepared: $prescriptionData');
      print('DEBUG: Patient ID: ${widget.patientId}');
      print('DEBUG: Doctor ID: ${doctorUser['id']}');
      print('DEBUG: Medicines: ${_medicinesController.text.trim()}');
      print('DEBUG: Combined Instructions: ${prescriptionData['instructions']}');
      print('DEBUG: Notes: ${_notesController.text.trim()}');
      
      // Ready to send prescription data
      print('DEBUG: Prescription data structure validated');

      print('DEBUG: Calling SupabaseService.createPrescription...');
      try {
        final result = await SupabaseService.createPrescription(prescriptionData);
        print('DEBUG: Prescription creation result: $result');
        
        // Check if it's a real database result or mock data
        if (result['id'].toString().startsWith('demo-')) {
          print('DEBUG: WARNING - Received mock data, database insertion failed');
        } else {
          print('DEBUG: SUCCESS - Real database insertion successful');
        }
      } catch (e) {
        print('DEBUG: Exception caught in dialog: $e');
        rethrow;
      }
      
      if (mounted) {
        print('DEBUG: Prescription created successfully, closing dialog');
        Navigator.pop(context);
        widget.onPrescriptionCreated();
      }
    } catch (e) {
      print('DEBUG: Exception during prescription creation: $e');
      print('DEBUG: Exception stack trace: ${StackTrace.current}');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to create prescription: $e')),
        );
      }
    } finally {
      print('DEBUG: Prescription creation process completed');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _medicinesController.dispose();
    _dosageController.dispose();
    _instructionsController.dispose();
    _notesController.dispose();
    super.dispose();
  }
}