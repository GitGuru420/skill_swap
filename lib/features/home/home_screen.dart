import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../discover/discover_screen.dart';
import '../profile/profile_screen.dart';
import '../swap/swap_screen.dart';
import '../chat/chat_list_screen.dart';

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
    const SwapScreen(),
    const ChatListScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      
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