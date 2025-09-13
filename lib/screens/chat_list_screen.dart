import 'package:flutter/material.dart';
import '../services/supabase_service.dart';
import '../services/local_storage_service.dart';
import 'common/chat_screen.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  List<Map<String, dynamic>> _chatList = [];
  bool _isLoading = true;
  String? _userRole;

  @override
  void initState() {
    super.initState();
    _loadChatData();
  }

  void _loadChatData() async {
    final currentUser = LocalStorageService.getCurrentUser();
    final userId = LocalStorageService.getCurrentUserId();
    
    if (currentUser == null || userId == null) return;
    
    setState(() {
      _userRole = currentUser['role'];
    });

    try {
      if (_userRole == 'patient') {
        await _loadPreviousConversations(userId);
      } else if (_userRole == 'doctor') {
        await _loadVerifiedDoctors();
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadPreviousConversations(String userId) async {
    String query;
    if (_userRole == 'doctor') {
      // For doctors, only show messages they received
      query = 'receiver_id.eq.$userId';
    } else {
      // For patients, show all conversations
      query = 'sender_id.eq.$userId,receiver_id.eq.$userId';
    }
    
    final conversations = await SupabaseService.client
        .from('chats')
        .select('receiver_id, sender_id, message, created_at')
        .or(query)
        .order('created_at', ascending: false);

    final uniqueUsers = <String, Map<String, dynamic>>{};
    
    for (final chat in conversations) {
      final otherUserId = chat['sender_id'] == userId ? chat['receiver_id'] : chat['sender_id'];
      
      if (!uniqueUsers.containsKey(otherUserId)) {
        final profile = await SupabaseService.getProfile(otherUserId);
        
        if (profile != null) {
          uniqueUsers[otherUserId] = {
            'id': otherUserId,
            'full_name': profile['full_name'],
            'role': profile['role'],
            'last_message': chat['message'],
            'last_message_time': chat['created_at'],
          };
        } else {
          // Fallback for missing profiles
          uniqueUsers[otherUserId] = {
            'id': otherUserId,
            'full_name': 'Unknown User',
            'role': 'patient',
            'last_message': chat['message'],
            'last_message_time': chat['created_at'],
          };
        }
      }
    }

    setState(() {
      _chatList = uniqueUsers.values.toList();
      _isLoading = false;
    });
  }

  Future<void> _loadVerifiedDoctors() async {
    final userId = LocalStorageService.getCurrentUserId();
    if (userId == null) return;
    
    await _loadPreviousConversations(userId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_userRole == 'patient' ? 'Previous Conversations' : 'Patient Conversations'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _chatList.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.chat, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(_userRole == 'patient' 
                          ? 'No previous conversations' 
                          : 'No patient conversations'),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _chatList.length,
                  itemBuilder: (context, index) {
                    final item = _chatList[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: const Color(0xFF00B4D8).withOpacity(0.1),
                          child: const Icon(Icons.person, color: Color(0xFF00B4D8)),
                        ),
                        title: Text(_getUserName(item)),
                        subtitle: _buildSubtitle(item),
                        trailing: const Icon(Icons.chat),
                        onTap: () => _startChat(item),
                      ),
                    );
                  },
                ),
    );
  }

  String _getUserName(Map<String, dynamic> item) {
    if (_userRole == 'patient') {
      // Patient sees doctor names with Dr. prefix
      return item['role'] == 'doctor' ? 'Dr. ${item['full_name'] ?? 'Doctor'}' : item['full_name'] ?? 'User';
    } else {
      // Doctor sees patient names without prefix
      return item['full_name'] ?? 'Patient';
    }
  }

  Widget _buildSubtitle(Map<String, dynamic> item) {
    if (_userRole == 'patient') {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(item['role']?.toString().toUpperCase() ?? 'USER'),
          if (item['last_message'] != null)
            Text(
              item['last_message'],
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: Colors.grey[600]),
            ),
        ],
      );
    } else {
      final doctorData = item['doctors'];
      String specialization = 'General Medicine';
      String clinic = '';
      
      if (doctorData != null) {
        if (doctorData is List && doctorData.isNotEmpty) {
          specialization = doctorData[0]['specialization'] ?? 'General Medicine';
          clinic = doctorData[0]['clinic_name'] ?? '';
        } else if (doctorData is Map) {
          specialization = doctorData['specialization'] ?? 'General Medicine';
          clinic = doctorData['clinic_name'] ?? '';
        }
      }
      
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(specialization),
          if (clinic.isNotEmpty) Text(clinic),
        ],
      );
    }
  }

  void _startChat(Map<String, dynamic> item) {
    final userId = LocalStorageService.getCurrentUserId();
    final conversationId = '${userId}_${item['id']}';
    
    print('DEBUG: Starting chat with conversation ID: $conversationId');
    print('DEBUG: Current user ID: $userId');
    print('DEBUG: Other user ID: ${item['id']}');
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatScreen(
          conversationId: conversationId,
          otherUserId: item['id'],
          otherUserName: _getUserName(item),
        ),
      ),
    );
  }
}