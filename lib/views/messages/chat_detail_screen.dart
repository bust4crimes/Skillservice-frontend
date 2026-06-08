// lib/views/messages/chat_detail_screen.dart
import 'package:google_fonts/google_fonts.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:skillservice_frontend/core/app_theme.dart';
import 'package:skillservice_frontend/widgets/avatar_with_status.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:skillservice_frontend/core/api_service.dart';
import 'package:skillservice_frontend/core/chat_store.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';

class ChatDetailScreen extends StatefulWidget {
  final String chatPartnerId;
  final String chatPartnerName;
  const ChatDetailScreen({Key? key, required this.chatPartnerId, required this.chatPartnerName}) : super(key: key);

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final TextEditingController _msgController = TextEditingController();
  final List<Map<String, dynamic>> _messages = [];
  final ScrollController _scrollController = ScrollController();
  String? _partnerAvatar;
  Timer? _pollTimer;
  bool _loading = true;
  String? _statusText;

  @override
  void initState() {
    super.initState();
    _loadHistory();
    _loadPartnerProfile();
    _startPolling();
  }

  Future<void> _loadPartnerProfile() async {
    try {
      final res = await ApiService().dio.get('/auth/profile/${widget.chatPartnerId}');
      final data = res.data as Map<String, dynamic>?;
      if (data != null) {
        setState(() => _partnerAvatar = data['profile_picture'] as String?);
      }
    } catch (_) {}
  }

  String _buildConversationId() {
    final user = FirebaseAuth.instance.currentUser;
    final uid = user?.uid ?? '';
    final ids = [uid, widget.chatPartnerId]..sort();
    return '${ids[0]}_${ids[1]}';
  }

  Future<void> _loadHistory() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;
      final res = await ApiService().client.get('/chat/history/${user.uid}/${widget.chatPartnerId}');
      if (res.statusCode == 200) {
        final List<dynamic> items = res.data is List ? res.data : [];
        setState(() {
          _messages.clear();
          for (var m in items) {
            final msgId = (m['id'] ?? m['_id'] ?? '').toString();
            _messages.add({
              "id": msgId,
              "text": m['message'] ?? m['msg'] ?? '',
              "isMe": m['sender_id'] == user.uid,
              "sender_id": m['sender_id'] ?? '',
              "timestamp": m['timestamp'] ?? '',
            });
          }
          _loading = false;
        });
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _startPolling() {
    _pollTimer = Timer.periodic(const Duration(seconds: 3), (_) => _pollMessages());
  }

  Future<void> _pollMessages() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;
      final res = await ApiService().client.get('/chat/history/${user.uid}/${widget.chatPartnerId}');
      if (res.statusCode == 200 && res.data is List) {
        final List<dynamic> items = res.data;
        bool hasNew = false;
        for (var m in items) {
          final msgId = (m['id'] ?? m['_id'] ?? '').toString();
          final exists = _messages.any((msg) => msg['id'] == msgId);
          if (!exists) {
            hasNew = true;
            _messages.add({
              "id": msgId,
              "text": m['message'] ?? m['msg'] ?? '',
              "isMe": m['sender_id'] == user.uid,
              "sender_id": m['sender_id'] ?? '',
              "timestamp": m['timestamp'] ?? '',
            });
          }
        }
        if (hasNew && mounted) {
          setState(() {});
          _scrollToBottom();
        }
      }
    } catch (_) {}
  }

  Future<void> _sendMessage() async {
    final text = _msgController.text.trim();
    if (text.isEmpty) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    _setStatus('Sending...');
    final msg = {
      "text": text,
      "isMe": true,
      "sender_id": user.uid,
      "id": 'temp_${DateTime.now().millisecondsSinceEpoch}',
    };
    setState(() {
      _messages.add(msg);
      _msgController.clear();
    });
    _scrollToBottom();
    try { ChatStore.saveMessage(_buildConversationId(), msg); } catch (_) {}

    try {
      final response = await ApiService().client.post(
        '/chat/send',
        data: {
          "receiver_id": widget.chatPartnerId,
          "message": text,
          "msg_type": "text",
        },
      );
      if (response.statusCode == 200 && response.data is Map) {
        final sentId = (response.data['id'] ?? response.data['_id'] ?? '').toString();
        if (sentId.isNotEmpty) {
          setState(() {
            msg['id'] = sentId;
          });
        }
      }
      _setStatus(null);
    } catch (e) {
      _setStatus('Send failed. Retrying...');
      await _sendViaFallback(user, text);
    }
  }

  Future<void> _sendViaFallback(User user, String text) async {
    try {
      final response = await ApiService().client.post(
        '/chat/message',
        data: {
          "receiver_id": widget.chatPartnerId,
          "message": text,
          "msg_type": "text",
        },
      );
      if (response.statusCode == 200 && response.data is Map) {
        final sentId = (response.data['id'] ?? response.data['_id'] ?? '').toString();
        if (sentId.isNotEmpty) {
          setState(() {
            _messages.last['id'] = sentId;
          });
        }
      }
      _setStatus(null);
    } catch (e) {
      _setStatus('Message saved locally');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Message will be sent when connection is restored')),
        );
      }
    }
  }

  void _setStatus(String? text) {
    if (mounted) setState(() => _statusText = text);
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _msgController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const AvatarWithStatus(radius: 15),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.chatPartnerName, style: GoogleFonts.inter(fontSize: 16, color: AppTheme.textPrimary), overflow: TextOverflow.ellipsis),
                  if (_statusText != null)
                    Text(_statusText!, style: GoogleFonts.inter(fontSize: 10, color: Colors.orange))
                  else
                    Text('Online', style: GoogleFonts.inter(fontSize: 10, color: AppTheme.textSecondary)),
                ],
              ),
            ),
          ],
        ),
        actions: [
          PopupMenuButton<String>(
            onSelected: (val) async {
              if (val == 'clear') {
                final confirm = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
                  title: const Text('Clear Chat'),
                  content: const Text('Delete all messages in this conversation?'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                    TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Clear', style: TextStyle(color: Colors.red))),
                  ],
                ));
                if (confirm == true) {
                  try {
                    final user = FirebaseAuth.instance.currentUser;
                    if (user == null) return;
                    await ApiService().client.delete('/chat/clear-conversation', queryParameters: {'user_a': user.uid, 'user_b': widget.chatPartnerId});
                    setState(() => _messages.clear());
                  } catch (e) {
                    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Clear failed: $e')));
                  }
                }
              }
            },
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'clear', child: Text('Clear Chat', style: TextStyle(color: Colors.red))),
            ],
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(10),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final msg = _messages[index];
                      final isMe = msg['isMe'] == true;
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 3),
                        child: Row(
                          mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            if (!isMe)
                              Padding(
                                padding: const EdgeInsets.only(right: 6),
                                child: CircleAvatar(
                                  radius: 14,
                                  backgroundImage: (_partnerAvatar != null && _partnerAvatar!.isNotEmpty)
                                      ? CachedNetworkImageProvider(_partnerAvatar!)
                                      : null,
                                  child: (_partnerAvatar == null || _partnerAvatar!.isEmpty)
                                      ? const Icon(CupertinoIcons.person, size: 14)
                                      : null,
                                ),
                              ),
                            Flexible(
                              child: GestureDetector(
                                onLongPress: isMe ? () => _deleteMessage(index) : null,
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: isMe ? AppTheme.primary : Colors.grey[200],
                                    borderRadius: BorderRadius.circular(15),
                                  ),
                                  child: Text(msg['text'], style: GoogleFonts.inter(color: isMe ? Colors.white : AppTheme.textPrimary, fontSize: 14)),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                _buildMessageInput(),
              ],
            ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      color: Theme.of(context).cardColor,
      child: Row(
        children: [
          IconButton(icon: Icon(CupertinoIcons.photo, color: AppTheme.textSecondary), onPressed: () {}),
          Expanded(
            child: TextField(
              controller: _msgController,
              decoration: InputDecoration(
                hintText: "Type a message...",
                hintStyle: GoogleFonts.inter(color: AppTheme.textSecondary, fontSize: 14),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
                filled: true, fillColor: Theme.of(context).scaffoldBackgroundColor,
                contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
              ),
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          IconButton(icon: const Icon(CupertinoIcons.paperplane, fill: 1, color: AppTheme.primary), onPressed: _sendMessage),
        ],
      ),
    );
  }

  Future<void> _deleteMessage(int index) async {
    final msg = _messages[index];
    final msgId = msg['id'] as String?;
    if (msgId == null || msgId.isEmpty || msgId.startsWith('temp_')) return;
    final confirm = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
      title: const Text('Delete Message'),
      content: const Text('Delete this message?'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
        TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
      ],
    ));
    if (confirm == true) {
      try {
        final user = FirebaseAuth.instance.currentUser;
        if (user == null) return;
        await ApiService().client.delete('/chat/delete-message/$msgId', queryParameters: {'user_id': user.uid});
        setState(() => _messages.removeAt(index));
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Delete failed: $e')));
      }
    }
  }

  void _scrollToBottom() {
    if (!_scrollController.hasClients) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      } catch (_) {}
    });
  }
}
