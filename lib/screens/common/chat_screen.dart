import 'package:flutter/material.dart';

import '../../services/supabase_service.dart';
import '../../services/local_storage_service.dart';
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

  @override
  void initState() {
    super.initState();
    _loadMessages();
    _subscribeToMessages();
  }

  Future<void> _loadMessages() async {
    try {
      final messages = await SupabaseService.getMessages(widget.conversationId);
      await LocalStorageService.cacheMessages(widget.conversationId, messages);
      if (mounted) {
        setState(() {
          _messages = messages.map((m) => Chat.fromJson(m)).toList();
          _isLoading = false;
        });
        _scrollToBottom();
      }
    } catch (e) {
      final cachedMessages = LocalStorageService.getCachedMessages(widget.conversationId);
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
    SupabaseService.subscribeToMessages(widget.conversationId).listen((messages) {
      if (mounted) {
        setState(() {
          _messages = messages.map((m) => Chat.fromJson(m)).toList();
        });
        _scrollToBottom();
      }
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
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
              backgroundColor: const Color(0xFF2563EB),
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
                  Text(
                    'Online',
                    style: TextStyle(
                      color: const Color(0xFF059669),
                      fontSize: screenWidth * 0.03,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.videocam,
              color: const Color(0xFF2563EB),
              size: screenWidth * 0.06,
            ),
            onPressed: _startVideoCall,
          ),
          IconButton(
            icon: Icon(
              Icons.call,
              color: const Color(0xFF2563EB),
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
          color: isMe ? const Color(0xFF2563EB) : Colors.white,
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
              color: Color(0xFF2563EB),
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

    try {
      await SupabaseService.sendMessage({
        'conversation_id': widget.conversationId,
        'sender_id': SupabaseService.currentUser?.id,
        'receiver_id': widget.otherUserId,
        'message': messageText,
        'meta': {},
      });
    } catch (e) {
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

  void _startVideoCall() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Video call feature coming soon')),
    );
  }

  void _startAudioCall() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Audio call feature coming soon')),
    );
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

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}