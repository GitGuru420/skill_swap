import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';

class ChatDetailScreen extends StatefulWidget {
  final String otherUserId;
  final String otherUserName;
  final String skillTitle;

  const ChatDetailScreen({
    super.key,
    required this.otherUserId,
    required this.otherUserName,
    required this.skillTitle,
  });

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final _supabase = Supabase.instance.client;
  final _messageController = TextEditingController();
  bool _showEmoji = false;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _markMessagesAsRead();
  }

  Future<void> _markMessagesAsRead() async {
    final currentUser = _supabase.auth.currentUser;
    if (currentUser == null) return;

    try {
      await _supabase
          .from('messages')
          .update({'is_read': true})
          .eq('receiver_id', currentUser.id)
          .eq('sender_id', widget.otherUserId)
          .eq('is_read', false);
    } catch (e) {
      debugPrint("Error marking messages as read: $e");
    }
  }

  Future<void> _sendMessage({
    String? fileUrl,
    String? fileType,
    String? fileName,
  }) async {
    final text = _messageController.text.trim();
    if (text.isEmpty && fileUrl == null) return;

    final currentUser = _supabase.auth.currentUser;
    if (currentUser == null) return;

    _messageController.clear();
    setState(() => _showEmoji = false);

    try {
      await _supabase.from('messages').insert({
        'sender_id': currentUser.id,
        'receiver_id': widget.otherUserId,
        'content': text.isEmpty ? null : text,
        'file_url': fileUrl,
        'file_type': fileType,
        'file_name': fileName,
        'is_read': false,
      });
    } catch (e) {
      debugPrint('Error sending message: $e');
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes();
      _uploadFileBytes(bytes, 'image', pickedFile.name);
    }
  }


  Future<void> _pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx'],
      withData: true, 
    );

    if (result != null && result.files.single.bytes != null) {
      final bytes = result.files.single.bytes!;
      _uploadFileBytes(bytes, 'pdf', result.files.single.name);
    }
  }

  // Supabase Storage Bytes upload
  Future<void> _uploadFileBytes(
    Uint8List bytes,
    String type,
    String fileName,
  ) async {
    setState(() => _isUploading = true);
    try {
      final String filePath =
          '${DateTime.now().millisecondsSinceEpoch}_$fileName';

      await _supabase.storage
          .from('chat_attachments')
          .uploadBinary(filePath, bytes);

      final String publicUrl = _supabase.storage
          .from('chat_attachments')
          .getPublicUrl(filePath);
      await _sendMessage(
        fileUrl: publicUrl,
        fileType: type,
        fileName: fileName,
      );
    } catch (e) {
      debugPrint("File upload error: $e");
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Upload failed')));
    } finally {
      setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = _supabase.auth.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFFEFEFEF),
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.otherUserName,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            Text(
              'Swap: ${widget.skillTitle}',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w400),
            ),
          ],
        ),
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
        elevation: 1,
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: _supabase
                  .from('messages')
                  .stream(primaryKey: ['id'])
                  .order('created_at', ascending: true),
              builder: (context, snapshot) {
                if (!snapshot.hasData)
                  return const Center(child: CircularProgressIndicator());

                final messages = snapshot.data!.where((msg) {
                  final isMeToOther =
                      msg['sender_id'] == currentUser?.id &&
                      msg['receiver_id'] == widget.otherUserId;
                  final isOtherToMe =
                      msg['sender_id'] == widget.otherUserId &&
                      msg['receiver_id'] == currentUser?.id;
                  return isMeToOther || isOtherToMe;
                }).toList();

                if (messages.isEmpty)
                  return const Center(
                    child: Text(
                      'Say hi! 👋',
                      style: TextStyle(color: Colors.grey),
                    ),
                  );

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index];
                    final isMine = msg['sender_id'] == currentUser?.id;
                    final isRead = msg['is_read'] == true;


                    return Align(
                      alignment: isMine
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(
                          vertical: 4,
                          horizontal: 12,
                        ),
                        padding: const EdgeInsets.symmetric(
                          vertical: 10,
                          horizontal: 14,
                        ),
                        constraints: BoxConstraints(
                          maxWidth: MediaQuery.of(context).size.width * 0.75,
                        ),
                        decoration: BoxDecoration(
                          color: isMine ? Colors.blueAccent : Colors.white,
                          borderRadius: BorderRadius.only(
                            topLeft: const Radius.circular(16),
                            topRight: const Radius.circular(16),
                            bottomLeft: isMine
                                ? const Radius.circular(16)
                                : const Radius.circular(0),
                            bottomRight: isMine
                                ? const Radius.circular(0)
                                : const Radius.circular(16),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 5,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: isMine
                              ? CrossAxisAlignment.end
                              : CrossAxisAlignment.start,
                          children: [
                            if (msg['file_type'] == 'image' &&
                                msg['file_url'] != null)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 8.0),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.network(
                                    msg['file_url'],
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),

                            if (msg['file_type'] == 'pdf' &&
                                msg['file_name'] != null)
                              Container(
                                padding: const EdgeInsets.all(8),
                                margin: const EdgeInsets.only(bottom: 8),
                                decoration: BoxDecoration(
                                  color: Colors.black12,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.picture_as_pdf,
                                      color: Colors.redAccent,
                                    ),
                                    const SizedBox(width: 8),
                                    Flexible(
                                      child: Text(
                                        msg['file_name'],
                                        style: TextStyle(
                                          color: isMine
                                              ? Colors.white
                                              : Colors.black87,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                            if (msg['content'] != null)
                              Text(
                                msg['content'],
                                style: TextStyle(
                                  color: isMine ? Colors.white : Colors.black87,
                                  fontSize: 16,
                                ),
                              ),

                            if (isMine)
                              Padding(
                                padding: const EdgeInsets.only(top: 4.0),
                                child: Icon(
                                  isRead
                                      ? Icons.done_all
                                      : Icons.check, // Seen double tikk
                                  size: 14,
                                  color: isRead ? Colors.white : Colors.white70,
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),

          if (_isUploading)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: LinearProgressIndicator(),
            ),

          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: SafeArea(
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.emoji_emotions_outlined,
                      color: Colors.grey,
                    ),
                    onPressed: () {
                      FocusScope.of(context).unfocus();
                      setState(() => _showEmoji = !_showEmoji);
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.attach_file, color: Colors.grey),
                    onPressed: () {
                      showModalBottomSheet(
                        context: context,
                        builder: (context) => Wrap(
                          children: [
                            ListTile(
                              leading: const Icon(
                                Icons.image,
                                color: Colors.blue,
                              ),
                              title: const Text('Send Photo'),
                              onTap: () {
                                Navigator.pop(context);
                                _pickImage();
                              },
                            ),
                            ListTile(
                              leading: const Icon(
                                Icons.picture_as_pdf,
                                color: Colors.red,
                              ),
                              title: const Text('Send Document'),
                              onTap: () {
                                Navigator.pop(context);
                                _pickFile();
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      onTap: () => setState(() => _showEmoji = false),
                      decoration: InputDecoration(
                        hintText: 'Type a message...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Colors.grey.shade100,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: Colors.blueAccent,
                    child: IconButton(
                      icon: const Icon(
                        Icons.send,
                        color: Colors.white,
                        size: 20,
                      ),
                      onPressed: () => _sendMessage(),
                    ),
                  ),
                ],
              ),
            ),
          ),

          if (_showEmoji)
            SizedBox(
              height: 250,
              child: EmojiPicker(
                onEmojiSelected: (category, emoji) {
                  _messageController.text =
                      _messageController.text + emoji.emoji;
                },
              ),
            ),
        ],
      ),
    );
  }
}
