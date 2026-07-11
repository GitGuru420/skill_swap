import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DiscoverScreen extends StatefulWidget {
  const DiscoverScreen({super.key});

  @override
  State<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends State<DiscoverScreen> {
  final _supabase = Supabase.instance.client;
  List<dynamic> _skills = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchRealSkills();
  }

  // Fetch all skills from Supabase
  Future<void> _fetchRealSkills() async {
    setState(() => _isLoading = true);
    try {
      // Fetching all data from the 'skills' table, newest first
      final data = await _supabase
          .from('skills')
          .select()
          .order('created_at', ascending: false);

      if (mounted) {
        setState(() {
          _skills = data;
        });
      }
    } catch (error) {
      debugPrint("Error fetching skills: $error");
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Failed to load skills')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search Bar
            TextField(
              decoration: InputDecoration(
                hintText: 'Search for skills...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Theme.of(
                  context,
                ).colorScheme.surfaceContainerHighest.withOpacity(0.3),
              ),
            ),
            const SizedBox(height: 24),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Available Skills',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: _fetchRealSkills,
                  tooltip: 'Refresh List',
                ),
              ],
            ),
            const SizedBox(height: 16),

            // List of Real Skills
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _skills.isEmpty
                  ? const Center(
                      child: Text(
                        'No skills available yet. Be the first to add one!',
                      ),
                    )
                  : ListView.builder(
                      itemCount: _skills.length,
                      itemBuilder: (context, index) {
                        final skill = _skills[index];
                        return Card(
                          elevation: 2,
                          margin: const EdgeInsets.only(bottom: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.all(12),
                            leading: CircleAvatar(
                              radius: 24,
                              backgroundColor: Theme.of(
                                context,
                              ).colorScheme.primaryContainer,
                              child: const Icon(Icons.person, size: 28),
                            ),
                            title: Text(
                              skill['title'] ?? 'Unknown Skill',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            subtitle: Padding(
                              padding: const EdgeInsets.only(top: 4.0),
                              child: Text(
                                skill['description'] ??
                                    'No description available',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            trailing: ElevatedButton(
                              onPressed: () async {
                                final currentUser = _supabase.auth.currentUser;
                                if (currentUser == null) return;

                                // 1. nijer skill e requqest pathano jabe na
                                if (skill['user_id'] == currentUser.id) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'You cannot swap your own skill!',
                                      ),
                                    ),
                                  );
                                  return;
                                }

                                try {
                                  // 2. aage theke e request pathano ache kina check kora
                                  final existingRequest = await _supabase
                                      .from('swap_requests')
                                      .select()
                                      .eq('sender_id', currentUser.id)
                                      .eq('skill_id', skill['id'])
                                      .maybeSingle();

                                  if (existingRequest != null) {
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'Request already sent!',
                                          ),
                                        ),
                                      );
                                    }
                                    return;
                                  }

                                  // 3. new swap request insert kora
                                  await _supabase.from('swap_requests').insert({
                                    'sender_id': currentUser.id,
                                    'receiver_id': skill['user_id'],
                                    'skill_id': skill['id'],
                                  });

                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Swap request sent successfully!',
                                        ),
                                      ),
                                    );
                                  }
                                } catch (error) {
                                  debugPrint("Error sending request: $error");
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Failed to send request'),
                                      ),
                                    );
                                  }
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                ),
                                minimumSize: const Size(0, 36),
                              ),
                              child: const Text('Swap'),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
