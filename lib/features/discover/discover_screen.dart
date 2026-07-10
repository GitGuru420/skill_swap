import 'package:flutter/material.dart';

class DiscoverScreen extends StatefulWidget {
  const DiscoverScreen({super.key});

  @override
  State<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends State<DiscoverScreen> {
  // Mock data representing skills offered by other users
  final List<Map<String, dynamic>> _mockSkills = [
    {'title': 'Flutter Development', 'user': 'John Doe', 'rating': 4.8},
    {'title': 'UI/UX Design', 'user': 'Jane Smith', 'rating': 4.9},
    {'title': 'Spoken English', 'user': 'Rahim Ali', 'rating': 4.5},
    {'title': 'Digital Marketing', 'user': 'Sara Khan', 'rating': 4.7},
    {'title': 'Python Programming', 'user': 'Alex Johnson', 'rating': 4.6},
  ];

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
                fillColor: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.3),
              ),
            ),
            const SizedBox(height: 24),
            
            const Text(
              'Trending Skills',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            
            // List of Skills
            Expanded(
              child: ListView.builder(
                itemCount: _mockSkills.length,
                itemBuilder: (context, index) {
                  final skill = _mockSkills[index];
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
                        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                        child: const Icon(Icons.person, size: 28),
                      ),
                      title: Text(
                        skill['title'], 
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 4.0),
                        child: Text('Offered by: ${skill['user']}'),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.star, color: Colors.amber, size: 20),
                          const SizedBox(width: 4),
                          Text(
                            skill['rating'].toString(),
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                        ],
                      ),
                      onTap: () {
                        // Action when a skill is tapped
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Tapped on ${skill['title']}')),
                        );
                      },
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