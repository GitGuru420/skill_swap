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
  List<Map<String, dynamic>> _mergedChats = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchAndMergeChats();
  }

  Future<void> _fetchAndMergeChats() async {
    setState(() => _isLoading = true);
    try {
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) return;

      final data = await _supabase
          .from('swap_requests')
          .select('*, skills(title)')
          .eq('status', 'accepted')
          .or(
            'sender_id.eq.${currentUser.id},receiver_id.eq.${currentUser.id}',
          );

      final unreadData = await _supabase
          .from('messages')
          .select('sender_id')
          .eq('receiver_id', currentUser.id)
          .eq('is_read', false);

      Map<String, int> unreadCounts = {};
      for (var msg in unreadData) {
        final sender = msg['sender_id'] as String;
        unreadCounts[sender] = (unreadCounts[sender] ?? 0) + 1;
      }

      Map<String, Map<String, dynamic>> groupedChats = {};

      for (var swap in data) {
        final isSender = swap['sender_id'] == currentUser.id;
        final otherUserId = isSender ? swap['receiver_id'] : swap['sender_id'];
        final skillTitle = swap['skills'] != null
            ? swap['skills']['title']
            : 'Skill';

        if (groupedChats.containsKey(otherUserId)) {
          if (!groupedChats[otherUserId]!['skills'].contains(skillTitle)) {
            groupedChats[otherUserId]!['skills'].add(skillTitle);
          }
        } else {
          final profileData = await _supabase
              .from('profiles')
              .select('name, avatar_url')
              .eq('id', otherUserId)
              .maybeSingle();

          groupedChats[otherUserId] = {
            'otherUserId': otherUserId,
            'name': profileData?['name'] ?? 'Unknown User',
            'avatar_url': profileData?['avatar_url'],
            'skills': [skillTitle],
            'unreadCount':
                unreadCounts[otherUserId] ?? 0, 
          };
        }
      }

      if (mounted) {
        setState(() {
          _mergedChats = groupedChats.values.toList();
          _mergedChats.sort(
            (a, b) =>
                (b['unreadCount'] as int).compareTo(a['unreadCount'] as int),
          );
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
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
          'Messages',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        centerTitle: true,
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Colors.blueAccent),
            )
          : _mergedChats.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.chat_bubble_outline,
                    size: 64,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No chats yet. Go swap some skills!',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
                  ),
                ],
              ),
            )
          : ListView.builder(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(12),
              itemCount: _mergedChats.length,
              itemBuilder: (context, index) {
                final chatInfo = _mergedChats[index];
                final String skillsText = (chatInfo['skills'] as List).join(
                  ', ',
                );
                final int unreadCount = chatInfo['unreadCount'];

                return Card(
                  elevation: 0,
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(color: Colors.grey.shade200),
                  ),
                  color: Colors.white,
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    leading: CircleAvatar(
                      radius: 26,
                      backgroundColor: Colors.blue.shade50,
                      backgroundImage: chatInfo['avatar_url'] != null
                          ? NetworkImage(chatInfo['avatar_url'])
                          : null,
                      child: chatInfo['avatar_url'] == null
                          ? const Icon(Icons.person, color: Colors.blueAccent)
                          : null,
                    ),
                    title: Text(
                      chatInfo['name'],
                      style: TextStyle(
                        fontWeight: unreadCount > 0
                            ? FontWeight.w900
                            : FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: Text(
                        unreadCount > 0
                            ? 'New messages waiting!'
                            : 'Tap to start messaging',
                        style: TextStyle(
                          color: unreadCount > 0
                              ? Colors.blueAccent
                              : Colors.grey.shade600,
                          fontSize: 13,
                          fontWeight: unreadCount > 0
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                    ),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        if (unreadCount > 0)
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: const BoxDecoration(
                              color: Colors.redAccent,
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              unreadCount.toString(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          )
                        else
                          Container(
                            constraints: const BoxConstraints(maxWidth: 100),
                            child: Text(
                              skillsText,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey,
                              ),
                            ),
                          ),
                      ],
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ChatDetailScreen(
                            otherUserId: chatInfo['otherUserId'],
                            otherUserName: chatInfo['name'],
                            skillTitle: skillsText,
                          ),
                        ),
                      ).then(
                        (_) => _fetchAndMergeChats(),
                      ); 
                    },
                  ),
                );
              },
            ),
    );
  }
}
