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
  List<Map<String, dynamic>> _doctors = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDoctors();
  }

  void _loadDoctors() async {
    try {
      final doctors = await SupabaseService.client
          .from('doctors')
          .select('id, specialization, clinic_name, profiles!doctors_id_fkey(full_name)')
          .eq('verified', true)
          .limit(20);

      setState(() {
        _doctors = List<Map<String, dynamic>>.from(doctors);
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chat with Doctors'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _doctors.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.chat, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text('No doctors available for chat'),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _doctors.length,
                  itemBuilder: (context, index) {
                    final doctor = _doctors[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.blue[100],
                          child: const Icon(Icons.person, color: Colors.blue),
                        ),
                        title: Text(doctor['profiles']['full_name'] ?? 'Doctor'),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(doctor['specialization'] ?? 'General'),
                            if (doctor['clinic_name'] != null)
                              Text(doctor['clinic_name']),
                          ],
                        ),
                        trailing: const Icon(Icons.chat),
                        onTap: () => _startChat(doctor),
                      ),
                    );
                  },
                ),
    );
  }

  void _startChat(Map<String, dynamic> doctor) {
    final userId = LocalStorageService.getCurrentUserId();
    final conversationId = '${userId}_${doctor['id']}';
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatScreen(
          conversationId: conversationId,
          otherUserId: doctor['id'],
          otherUserName: doctor['profiles']['full_name'] ?? 'Doctor',
        ),
      ),
    );
  }
}