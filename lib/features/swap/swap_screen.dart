import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SwapScreen extends StatefulWidget {
  const SwapScreen({super.key});

  @override
  State<SwapScreen> createState() => _SwapScreenState();
}

class _SwapScreenState extends State<SwapScreen> {
  final _supabase = Supabase.instance.client;
  List<dynamic> _requests = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchRequests();
  }

  // Fetch requests where the current user is the receiver
  Future<void> _fetchRequests() async {
    setState(() => _isLoading = true);
    try {
      final currentUser = _supabase.auth.currentUser;
      if (currentUser != null) {
        // Supabase foreign table join to get the skill title along with the request
        final data = await _supabase
            .from('swap_requests')
            .select('''
              id,
              status,
              skills ( title )
            ''')
            .eq('receiver_id', currentUser.id)
            .order('created_at', ascending: false);

        if (mounted) {
          setState(() {
            _requests = data;
          });
        }
      }
    } catch (e) {
      debugPrint('Error fetching requests: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Update the status of the request (accepted/rejected)
  Future<void> _updateStatus(int requestId, String newStatus) async {
    try {
      await _supabase
          .from('swap_requests')
          .update({'status': newStatus})
          .eq('id', requestId);
      
      _fetchRequests(); // Refresh the list
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Request $newStatus!')),
        );
      }
    } catch (e) {
      debugPrint('Error updating request: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Swap Requests', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: false,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _requests.isEmpty
              ? const Center(child: Text('No swap requests yet.', style: TextStyle(fontSize: 16)))
              : ListView.builder(
                  itemCount: _requests.length,
                  itemBuilder: (context, index) {
                    final req = _requests[index];
                    final skillTitle = req['skills'] != null ? req['skills']['title'] : 'Unknown Skill';
                    final status = req['status'];

                    return Card(
                      elevation: 2,
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(12),
                        leading: CircleAvatar(
                          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                          child: const Icon(Icons.handshake),
                        ),
                        title: Text(
                          'Request for: $skillTitle',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            'Status: ${status.toUpperCase()}',
                            style: TextStyle(
                              color: status == 'accepted' 
                                  ? Colors.green 
                                  : (status == 'rejected' ? Colors.red : Colors.orange),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        trailing: status == 'pending'
                            ? Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.check_circle, color: Colors.green, size: 30),
                                    onPressed: () => _updateStatus(req['id'], 'accepted'),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.cancel, color: Colors.red, size: 30),
                                    onPressed: () => _updateStatus(req['id'], 'rejected'),
                                  ),
                                ],
                              )
                            : null,
                      ),
                    );
                  },
                ),
    );
  }
}