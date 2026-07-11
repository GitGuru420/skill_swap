import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'chat_detail_screen.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  final _supabase = Supabase.instance.client;
  List<dynamic> _chatPartners = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchAcceptedRequests();
  }

  // Fetch only swap requests that are 'accepted'
  Future<void> _fetchAcceptedRequests() async {
    setState(() => _isLoading = true);
    try {
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) return;

      final data = await _supabase
          .from('swap_requests')
          .select('*, skills(title)')
          .eq('status', 'accepted')
          .or('sender_id.eq.${currentUser.id},receiver_id.eq.${currentUser.id}');

      if (mounted) {
        setState(() {
          _chatPartners = data;
        });
      }
    } catch (e) {
      debugPrint('Error fetching chats: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = _supabase.auth.currentUser;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Messages', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: false,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _chatPartners.isEmpty
              ? const Center(child: Text('No accepted swaps yet. Go swap some skills!'))
              : ListView.builder(
                  itemCount: _chatPartners.length,
                  itemBuilder: (context, index) {
                    final swap = _chatPartners[index];
                    final isSender = swap['sender_id'] == currentUser?.id;
                    final otherUserId = isSender ? swap['receiver_id'] : swap['sender_id'];
                    final skillTitle = swap['skills'] != null ? swap['skills']['title'] : 'Skill';

                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                          child: const Icon(Icons.person),
                        ),
                        title: Text('Chat about: $skillTitle', style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: const Text('Tap to start messaging'),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ChatDetailScreen(
                                otherUserId: otherUserId,
                                skillTitle: skillTitle,
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
    );
  }
}