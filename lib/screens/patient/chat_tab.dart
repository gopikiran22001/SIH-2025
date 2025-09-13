import 'package:flutter/material.dart';
import '../../services/supabase_service.dart';
import 'chat_screen.dart';

class ChatTab extends StatefulWidget {
  const ChatTab({super.key});

  @override
  State<ChatTab> createState() => _ChatTabState();
}

class _ChatTabState extends State<ChatTab> {
  List<Map<String, dynamic>> _doctors = [];
  List<Map<String, dynamic>> _conversations = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDoctorsAndConversations();
  }

  Future<void> _loadDoctorsAndConversations() async {
    try {
      final user = SupabaseService.currentUser;
      if (user != null) {
        // Get all doctors
        final doctors = await _getAllDoctors();
        
        // Get existing conversations
        final conversations = await _getConversations(user.id);
        
        if (mounted) {
          setState(() {
            _doctors = doctors;
            _conversations = conversations;
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<List<Map<String, dynamic>>> _getAllDoctors() async {
    try {
      final response = await SupabaseService.client
          .from('profiles')
          .select('*, doctors(*)')
          .eq('role', 'doctor');
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> _getConversations(String userId) async {
    try {
      final response = await SupabaseService.client
          .from('chats')
          .select('conversation_id, receiver_id, profiles!chats_receiver_id_fkey(*)')
          .eq('sender_id', userId)
          .order('created_at', ascending: false);
      
      // Get unique conversations
      final uniqueConversations = <String, Map<String, dynamic>>{};
      for (final chat in response) {
        final conversationId = chat['conversation_id'];
        if (!uniqueConversations.containsKey(conversationId)) {
          uniqueConversations[conversationId] = chat;
        }
      }
      
      return uniqueConversations.values.toList();
    } catch (e) {
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          TabBar(
            labelColor: const Color(0xFF00B4D8),
            unselectedLabelColor: Colors.grey[600],
            indicatorColor: const Color(0xFF00B4D8),
            tabs: const [
              Tab(text: 'Conversations'),
              Tab(text: 'Doctors'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                _buildConversationsList(),
                _buildDoctorsList(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConversationsList() {
    final screenWidth = MediaQuery.of(context).size.width;

    if (_conversations.isEmpty) {
      return Center(
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
              'No conversations yet',
              style: TextStyle(
                fontSize: screenWidth * 0.04,
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: screenWidth * 0.02),
            Text(
              'Start chatting with a doctor',
              style: TextStyle(
                fontSize: screenWidth * 0.035,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(screenWidth * 0.04),
      itemCount: _conversations.length,
      itemBuilder: (context, index) {
        final conversation = _conversations[index];
        final doctor = conversation['profiles'];
        
        return _buildConversationCard(conversation, doctor, screenWidth);
      },
    );
  }

  Widget _buildDoctorsList() {
    final screenWidth = MediaQuery.of(context).size.width;

    return ListView.builder(
      padding: EdgeInsets.all(screenWidth * 0.04),
      itemCount: _doctors.length,
      itemBuilder: (context, index) {
        final doctor = _doctors[index];
        return _buildDoctorCard(doctor, screenWidth);
      },
    );
  }

  Widget _buildConversationCard(Map<String, dynamic> conversation, Map<String, dynamic> doctor, double screenWidth) {
    return Container(
      margin: EdgeInsets.only(bottom: screenWidth * 0.03),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(screenWidth * 0.03),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: screenWidth * 0.025,
            offset: Offset(0, screenWidth * 0.005),
          ),
        ],
      ),
      child: ListTile(
        leading: CircleAvatar(
          radius: screenWidth * 0.06,
          backgroundColor: const Color(0xFF00B4D8),
          child: Icon(
            Icons.person,
            color: Colors.white,
            size: screenWidth * 0.05,
          ),
        ),
        title: Text(
          'Dr. ${doctor['full_name'] ?? 'Unknown'}',
          style: TextStyle(
            fontSize: screenWidth * 0.04,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          doctor['doctors']?[0]?['specialization'] ?? 'General Medicine',
          style: TextStyle(
            fontSize: screenWidth * 0.035,
            color: Colors.grey[600],
          ),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          size: screenWidth * 0.04,
          color: Colors.grey[400],
        ),
        onTap: () => _openChat(doctor['id'], doctor['full_name']),
      ),
    );
  }

  Widget _buildDoctorCard(Map<String, dynamic> doctor, double screenWidth) {
    final doctorsData = doctor['doctors'];
    final doctorData = <String, dynamic>{};
    
    if (doctorsData != null) {
      if (doctorsData is List && doctorsData.isNotEmpty) {
        doctorData.addAll(doctorsData[0] ?? {});
      } else if (doctorsData is Map<String, dynamic>) {
        doctorData.addAll(doctorsData);
      }
    }
    
    return Container(
      margin: EdgeInsets.only(bottom: screenWidth * 0.03),
      padding: EdgeInsets.all(screenWidth * 0.04),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(screenWidth * 0.03),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: screenWidth * 0.025,
            offset: Offset(0, screenWidth * 0.005),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: screenWidth * 0.06,
                backgroundColor: const Color(0xFF00B4D8),
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
                      'Dr. ${doctor['full_name'] ?? 'Unknown'}',
                      style: TextStyle(
                        fontSize: screenWidth * 0.04,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      doctorData['specialization'] ?? 'General Medicine',
                      style: TextStyle(
                        fontSize: screenWidth * 0.035,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              if (doctorData['verified'] == true)
                Icon(
                  Icons.verified,
                  color: const Color(0xFF0077B6),
                  size: screenWidth * 0.04,
                ),
            ],
          ),
          if (doctorData['clinic_name'] != null) ...[
            SizedBox(height: screenWidth * 0.02),
            Row(
              children: [
                Icon(
                  Icons.location_on,
                  size: screenWidth * 0.035,
                  color: Colors.grey[500],
                ),
                SizedBox(width: screenWidth * 0.01),
                Text(
                  doctorData['clinic_name'],
                  style: TextStyle(
                    fontSize: screenWidth * 0.03,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ],
          SizedBox(height: screenWidth * 0.03),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _openChat(doctor['id'], doctor['full_name']),
              icon: Icon(Icons.chat, size: screenWidth * 0.04),
              label: Text(
                'Start Chat',
                style: TextStyle(fontSize: screenWidth * 0.035),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00B4D8),
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: screenWidth * 0.025),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _openChat(String doctorId, String doctorName) {
    final user = SupabaseService.currentUser;
    if (user != null) {
      final conversationId = '${user.id}_$doctorId';
      
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ChatScreen(
            conversationId: conversationId,
            otherUserId: doctorId,
            otherUserName: doctorName,
          ),
        ),
      );
    }
  }
}