import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _supabase = Supabase.instance.client;
  bool _isLoading = true;
  String _userEmail = '';
  int _tokens = 0;
  List<dynamic> _mySkills = [];

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  // Fetch user profile and their skills from Supabase
  Future<void> _loadProfileData() async {
    setState(() => _isLoading = true);
    try {
      final user = _supabase.auth.currentUser;
      if (user != null) {
        _userEmail = user.email ?? 'Unknown Email';

        // Fetch user tokens from profiles table
        final profileData = await _supabase
            .from('profiles')
            .select('tokens')
            .eq('id', user.id)
            .single();

        // Fetch user's skills from skills table
        final skillsData = await _supabase
            .from('skills')
            .select()
            .eq('user_id', user.id)
            .order('created_at', ascending: false);

        if (mounted) {
          setState(() {
            _tokens = profileData['tokens'] ?? 0;
            _mySkills = skillsData;
          });
        }
      }
    } catch (error) {
      debugPrint("Error loading profile: $error");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Show a dialog to add a new skill
  void _showAddSkillDialog() {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    bool isSaving = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Add New Skill'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(
                      labelText: 'Skill Title',
                      hintText: 'e.g., Flutter Development',
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Description',
                      hintText: 'Short details about your skill',
                    ),
                    maxLines: 3,
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: isSaving ? null : () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: isSaving
                      ? null
                      : () async {
                          final title = titleController.text.trim();
                          final description = descriptionController.text.trim();

                          if (title.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Title is required')),
                            );
                            return;
                          }

                          setDialogState(() => isSaving = true);

                          try {
                            final user = _supabase.auth.currentUser;
                            if (user != null) {
                              // Insert the new skill into Supabase
                              await _supabase.from('skills').insert({
                                'user_id': user.id,
                                'title': title,
                                'description': description,
                              });

                              if (mounted) {
                                Navigator.pop(context);
                                _loadProfileData(); // Reload the list
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Skill added successfully!')),
                                );
                              }
                            }
                          } catch (error) {
                            debugPrint("Error saving skill: $error");
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Failed to add skill')),
                            );
                            setDialogState(() => isSaving = false);
                          }
                        },
                  child: isSaving
                      ? const SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Save Skill'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // The floating action button allows the user to add a new skill
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddSkillDialog,
        icon: const Icon(Icons.add),
        label: const Text('Add Skill'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Profile Header
                  Center(
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 50,
                          backgroundColor: Theme.of(context).colorScheme.primary,
                          child: const Icon(Icons.person, size: 50, color: Colors.white),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _userEmail,
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Chip(
                          avatar: const Icon(Icons.stars, color: Colors.amber, size: 20),
                          label: Text('$_tokens Tokens'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  const Divider(),
                  const SizedBox(height: 16),
                  
                  // Skills Section Title
                  const Text(
                    'My Offered Skills',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),

                  // User's Skills List
                  Expanded(
                    child: _mySkills.isEmpty
                        ? Center(
                            child: Text(
                              'You haven\'t added any skills yet.\nTap the button below to add one!',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.grey.shade600),
                            ),
                          )
                        : ListView.builder(
                            itemCount: _mySkills.length,
                            itemBuilder: (context, index) {
                              final skill = _mySkills[index];
                              return Card(
                                margin: const EdgeInsets.only(bottom: 12),
                                child: ListTile(
                                  title: Text(
                                    skill['title'] ?? 'No Title',
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  subtitle: Text(skill['description'] ?? 'No Description'),
                                  trailing: IconButton(
                                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                                    onPressed: () {
                                      // TODO: Implement delete skill logic later
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('Delete feature coming soon!')),
                                      );
                                    },
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