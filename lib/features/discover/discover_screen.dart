import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DiscoverScreen extends StatefulWidget {
  const DiscoverScreen({super.key});

  @override
  State<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends State<DiscoverScreen> {
  final _supabase = Supabase.instance.client;
  final TextEditingController _searchController = TextEditingController();
  
  List<dynamic> _allSkills = [];
  List<dynamic> _filteredSkills = [];
  bool _isLoading = true;

  // --- Premium Pastel Colors for Skill Cards ---
  final List<Color> _cardColors = [
    const Color(0xFFE3F2FD), // Light Blue
    const Color(0xFFF3E5F5), // Light Purple
    const Color(0xFFE8F5E9), // Light Green
    const Color(0xFFFFF3E0), // Light Orange
    const Color(0xFFFFEBEE), // Light Pink
    const Color(0xFFFFF9C4), // Light Yellow
  ];

  @override
  void initState() {
    super.initState();
    _fetchRealSkills();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Fetch all skills (except current user's)
  Future<void> _fetchRealSkills() async {
    setState(() => _isLoading = true);
    try {
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) return;

      final data = await _supabase
          .from('skills')
          .select('*, profiles(name, avatar_url)')
          .neq('user_id', currentUser.id)
          .order('created_at', ascending: false);

      if (mounted) {
        setState(() {
          _allSkills = data;
          _filteredSkills = data; 
        });
      }
    } catch (error) {
      debugPrint("Error fetching skills: $error");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to load skills'), backgroundColor: Colors.redAccent),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Real-time Search Filter
  void _filterSkills(String query) {
    if (query.isEmpty) {
      setState(() {
        _filteredSkills = _allSkills;
      });
      return;
    }

    final lowerCaseQuery = query.toLowerCase();
    setState(() {
      _filteredSkills = _allSkills.where((skill) {
        final title = (skill['title'] ?? '').toString().toLowerCase();
        final description = (skill['description'] ?? '').toString().toLowerCase();
        return title.contains(lowerCaseQuery) || description.contains(lowerCaseQuery);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA), // Light background
      appBar: AppBar(
        title: const Text(
          'Explore Skills',
          style: TextStyle(fontWeight: FontWeight.w700, letterSpacing: 0.5),
        ),
        centerTitle: true,
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Search Bar ---
            TextField(
              controller: _searchController,
              onChanged: _filterSkills, 
              decoration: InputDecoration(
                hintText: 'Search for skills...',
                hintStyle: TextStyle(color: Colors.grey.shade500),
                prefixIcon: const Icon(Icons.search, color: Colors.blueAccent),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: Colors.grey),
                        onPressed: () {
                          _searchController.clear();
                          _filterSkills('');
                          FocusScope.of(context).unfocus(); 
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: Colors.grey.shade200, width: 1.5),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: Colors.blueAccent, width: 2),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // --- Header & Refresh Button ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Available to Swap',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh, color: Colors.blueAccent),
                  onPressed: () {
                    _searchController.clear();
                    _fetchRealSkills();
                  },
                  tooltip: 'Refresh List',
                ),
              ],
            ),
            const SizedBox(height: 12),

            // --- List of Skills ---
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _filteredSkills.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.search_off, size: 64, color: Colors.grey.shade400),
                              const SizedBox(height: 16),
                              Text(
                                _allSkills.isEmpty
                                    ? 'No skills available yet.'
                                    : 'No skills found matching your search.',
                                style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          physics: const BouncingScrollPhysics(),
                          itemCount: _filteredSkills.length,
                          itemBuilder: (context, index) {
                            final skill = _filteredSkills[index];
                            final profile = skill['profiles'] ?? {};
                            final avatarUrl = profile['avatar_url'];
                            final userName = profile['name'] ?? 'Anonymous';
                            
                            // Dynamic background color selection based on index
                            final cardColor = _cardColors[index % _cardColors.length];

                            return Container(
                              margin: const EdgeInsets.only(bottom: 14),
                              decoration: BoxDecoration(
                                color: cardColor, // Applied Dynamic Color Here!
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Colors.white, width: 2), // Gives a clean outline
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.05),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: ListTile(
                                contentPadding: const EdgeInsets.all(16),
                                leading: CircleAvatar(
                                  radius: 26,
                                  backgroundColor: Colors.white,
                                  backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
                                  child: avatarUrl == null
                                      ? Icon(Icons.person, size: 30, color: Colors.grey.shade600)
                                      : null,
                                ),
                                title: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        skill['title'] ?? 'Unknown Skill',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 17,
                                          color: Colors.black87,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 4),
                                    Text(
                                      skill['description'] ?? 'No description available',
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(color: Colors.black54, fontSize: 14),
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        Icon(Icons.account_circle, size: 14, color: Colors.grey.shade700),
                                        const SizedBox(width: 4),
                                        Text(
                                          'by $userName',
                                          style: TextStyle(
                                            color: Colors.grey.shade700,
                                            fontSize: 12,
                                            fontStyle: FontStyle.italic,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                trailing: ElevatedButton(
                                  onPressed: () async {
                                    final currentUser = _supabase.auth.currentUser;
                                    if (currentUser == null) return;

                                    try {
                                      final existingRequest = await _supabase
                                          .from('swap_requests')
                                          .select()
                                          .eq('sender_id', currentUser.id)
                                          .eq('skill_id', skill['id'])
                                          .maybeSingle();

                                      if (existingRequest != null) {
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(content: Text('Request already sent!'), backgroundColor: Colors.orange),
                                          );
                                        }
                                        return;
                                      }

                                      await _supabase.from('swap_requests').insert({
                                        'sender_id': currentUser.id,
                                        'receiver_id': skill['user_id'],
                                        'skill_id': skill['id'],
                                      });

                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text('Swap request sent successfully!'), backgroundColor: Colors.green),
                                        );
                                      }
                                    } catch (error) {
                                      debugPrint("Error sending request: $error");
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text('Failed to send request'), backgroundColor: Colors.red),
                                        );
                                      }
                                    }
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.black87, // Dark button for contrast on light cards
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  ),
                                  child: const Text('Swap', style: TextStyle(fontWeight: FontWeight.bold)),
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