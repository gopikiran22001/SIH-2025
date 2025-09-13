import 'package:flutter/material.dart';
import '../../services/supabase_service.dart';
import '../../services/local_storage_service.dart';

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
  
  // Backward compatibility getters
  String get doctorId => otherUserId;
  String get doctorName => otherUserName;

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  List<Map<String, dynamic>> _messages = [];
  bool _isLoading = true;
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _loadMessages();
    _subscribeToMessages();
  }

  Future<void> _loadMessages() async {
    try {
      // Load cached messages first
      final cachedMessages = LocalStorageService.getCachedMessages(widget.conversationId);
      if (cachedMessages.isNotEmpty && mounted) {
        setState(() {
          _messages = cachedMessages;
          _isLoading = false;
        });
        _scrollToBottom();
      }

      // Load fresh messages from database
      final messages = await SupabaseService.getMessages(widget.conversationId);
      
      // Cache messages
      for (final message in messages) {
        await LocalStorageService.cacheMessage(widget.conversationId, message);
      }
      
      if (mounted) {
        setState(() {
          _messages = messages;
          _isLoading = false;
        });
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _subscribeToMessages() {
    SupabaseService.subscribeToMessages(widget.conversationId).listen((messages) {
      if (mounted) {
        setState(() {
          _messages = messages;
        });
        _scrollToBottom();
        
        // Cache new messages
        for (final message in messages) {
          LocalStorageService.cacheMessage(widget.conversationId, message);
        }
      }
    });
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty || _isSending) return;

    final user = SupabaseService.currentUser;
    if (user == null) return;

    setState(() => _isSending = true);

    final messageText = _messageController.text.trim();
    _messageController.clear();

    final message = {
      'conversation_id': widget.conversationId,
      'sender_id': user.id,
      'receiver_id': widget.otherUserId,
      'message': messageText,
      'created_at': DateTime.now().toIso8601String(),
    };

    try {
      await SupabaseService.sendMessage(message);
    } catch (e) {
      // Handle offline mode - message will be sent when online
      await LocalStorageService.cacheMessage(widget.conversationId, {
        ...message,
        'id': 'temp_${DateTime.now().millisecondsSinceEpoch}',
        'offline': true,
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Message will be sent when online')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
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
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              radius: screenWidth * 0.04,
              backgroundColor: const Color(0xFF00B4D8),
              child: Icon(
                Icons.person,
                color: Colors.white,
                size: screenWidth * 0.035,
              ),
            ),
            SizedBox(width: screenWidth * 0.03),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Dr. ${widget.otherUserName}',
                    style: TextStyle(
                      fontSize: screenWidth * 0.04,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    'Online',
                    style: TextStyle(
                      fontSize: screenWidth * 0.03,
                      color: const Color(0xFF0077B6),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: Column(
        children: [
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _messages.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.chat_bubble_outline,
                              size: screenWidth * 0.15,
                              color: Colors.grey[400],
                            ),
                            SizedBox(height: screenWidth * 0.04),
                            Text(
                              'Start your conversation',
                              style: TextStyle(
                                fontSize: screenWidth * 0.04,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        padding: EdgeInsets.all(screenWidth * 0.04),
                        itemCount: _messages.length,
                        itemBuilder: (context, index) {
                          final message = _messages[index];
                          return _buildMessageBubble(message, screenWidth);
                        },
                      ),
          ),
          _buildMessageInput(screenWidth),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(Map<String, dynamic> message, double screenWidth) {
    final user = SupabaseService.currentUser;
    final isMe = message['sender_id'] == user?.id;
    final isOffline = message['offline'] == true;
    
    return Container(
      margin: EdgeInsets.only(bottom: screenWidth * 0.02),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isMe) ...[
            CircleAvatar(
              radius: screenWidth * 0.04,
              backgroundColor: const Color(0xFF00B4D8),
              child: Icon(
                Icons.person,
                color: Colors.white,
                size: screenWidth * 0.03,
              ),
            ),
            SizedBox(width: screenWidth * 0.02),
          ],
          Flexible(
            child: Container(
              padding: EdgeInsets.all(screenWidth * 0.03),
              decoration: BoxDecoration(
                color: isMe ? const Color(0xFF00B4D8) : Colors.grey[200],
                borderRadius: BorderRadius.circular(screenWidth * 0.04),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message['message'] ?? '',
                    style: TextStyle(
                      fontSize: screenWidth * 0.035,
                      color: isMe ? Colors.white : Colors.black,
                    ),
                  ),
                  SizedBox(height: screenWidth * 0.01),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _formatTime(message['created_at']),
                        style: TextStyle(
                          fontSize: screenWidth * 0.025,
                          color: isMe ? Colors.white70 : Colors.grey[600],
                        ),
                      ),
                      if (isMe && isOffline) ...[
                        SizedBox(width: screenWidth * 0.01),
                        Icon(
                          Icons.schedule,
                          size: screenWidth * 0.03,
                          color: Colors.white70,
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (isMe) ...[
            SizedBox(width: screenWidth * 0.02),
            CircleAvatar(
              radius: screenWidth * 0.04,
              backgroundColor: Colors.grey[300],
              child: Icon(
                Icons.person,
                color: Colors.grey[600],
                size: screenWidth * 0.03,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMessageInput(double screenWidth) {
    return Container(
      padding: EdgeInsets.all(screenWidth * 0.04),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Colors.grey[300]!),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: InputDecoration(
                hintText: 'Type a message...',
                hintStyle: TextStyle(fontSize: screenWidth * 0.035),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(screenWidth * 0.06),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey[100],
                contentPadding: EdgeInsets.symmetric(
                  horizontal: screenWidth * 0.04,
                  vertical: screenWidth * 0.025,
                ),
              ),
              style: TextStyle(fontSize: screenWidth * 0.035),
              maxLines: null,
              textCapitalization: TextCapitalization.sentences,
            ),
          ),
          SizedBox(width: screenWidth * 0.02),
          Container(
            decoration: const BoxDecoration(
              color: Color(0xFF00B4D8),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              onPressed: _isSending ? null : _sendMessage,
              icon: _isSending
                  ? SizedBox(
                      width: screenWidth * 0.04,
                      height: screenWidth * 0.04,
                      child: const CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Icon(
                      Icons.send,
                      color: Colors.white,
                      size: screenWidth * 0.05,
                    ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(String? timestamp) {
    if (timestamp == null) return '';
    
    try {
      final dateTime = DateTime.parse(timestamp);
      final now = DateTime.now();
      final difference = now.difference(dateTime);
      
      if (difference.inDays > 0) {
        return '${dateTime.day}/${dateTime.month}';
      } else {
        return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
      }
    } catch (e) {
      return '';
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}