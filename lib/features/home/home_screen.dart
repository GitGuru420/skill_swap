import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../discover/discover_screen.dart';
import '../profile/profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  int _tokens = 0;
  final _supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    _fetchUserTokens();
  }

  // Fetch tokens from Supabase profiles table
  Future<void> _fetchUserTokens() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId != null) {
        final data = await _supabase
            .from('profiles')
            .select('tokens')
            .eq('id', userId)
            .single();
        
        if (mounted) {
          setState(() {
            _tokens = data['tokens'] ?? 0;
          });
        }
      }
    } catch (error) {
      debugPrint("Error fetching tokens: $error");
    }
  }

  // Handle user logout
  Future<void> _handleLogout() async {
    await _supabase.auth.signOut();
    if (mounted) {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  // Placeholder screens for your existing feature folders
  final List<Widget> _screens = [
    const DiscoverScreen(),
    const Center(child: Text('Swap Requests Placeholder', style: TextStyle(fontSize: 20))),
    const Center(child: Text('Chat Placeholder', style: TextStyle(fontSize: 20))),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Skill Swap'),
        actions: [
          // Display Wallet Tokens in AppBar
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                children: [
                  const Icon(Icons.stars, color: Colors.amber),
                  const SizedBox(width: 4),
                  Text(
                    '$_tokens',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _handleLogout,
            tooltip: 'Logout',
          ),
        ],
      ),
      // Display the selected screen based on BottomNavigationBar index
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        type: BottomNavigationBarType.fixed,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.explore), label: 'Discover'),
          BottomNavigationBarItem(icon: Icon(Icons.swap_horiz), label: 'Swap'),
          BottomNavigationBarItem(icon: Icon(Icons.chat), label: 'Chat'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}