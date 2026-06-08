// lib/views/messages/chat_detail_screen.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:skillservice_frontend/core/app_theme.dart';
// chat detail uses built-in icons where possible
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
  late WebSocketChannel _channel;
  final ScrollController _scrollController = ScrollController();
  bool _connecting = false;
  bool _connected = false;
  String? _connectionError;
  
  @override
  void initState() {
    super.initState();
    _connectWebSocket();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;
      final res = await ApiService().client.get('/chat/history/${user.uid}/${widget.chatPartnerId}');
      if (res.statusCode == 200) {
        final List<dynamic> items = res.data;
        setState(() {
          _messages.clear();
          for (var m in items) {
            _messages.add({"text": m['message'] ?? '', "isMe": m['sender_id'] == user.uid});
          }
        });
        _scrollToBottom();
      }
    } catch (e) {
      // ignore
    }
  }

  Future<void> _connectWebSocket() async {
    if (_connecting || _connected) return;
    setState(() { _connecting = true; _connectionError = null; });

    final user = FirebaseAuth.instance.currentUser;
    final uid = user?.uid;
    if (uid == null) {
      setState(() { _connecting = false; _connectionError = 'Not authenticated'; });
      // Use captured scaffold messenger to avoid using context after async gaps
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Unable to open chat: not authenticated')));
      return;
    }

    try {
      // Construct websocket URL from ApiService baseUrl so it works for local and hosted backends
      // Build websocket URI robustly from ApiService baseUrl so it works for http/https and local/hosted
      final base = ApiService().dio.options.baseUrl;
      // When deployed behind proxies the 'host' may need to include the port and root path.
      // Use the raw base string to preserve host/port/root_path if present.
      final rawBase = base;
      String normalized = rawBase;
      if (normalized.endsWith('/')) normalized = normalized.substring(0, normalized.length - 1);
      // Replace scheme with ws/wss
       if (normalized.startsWith('https://')) {
         normalized = normalized.replaceFirst('https://', 'wss://');
       } else if (normalized.startsWith('http://')) {
         normalized = normalized.replaceFirst('http://', 'ws://');
       }
      final wsUrl = '$normalized/chat/ws/$uid';
      final wsUri = Uri.parse(wsUrl);
      // Backend expects websocket at /chat/ws/{user_id}
      _channel = WebSocketChannel.connect(wsUri);

      _channel.stream.listen((message) {
        try {
          final decoded = (message is String) ? jsonDecode(message) : message;
          // Backend payload uses 'message' and 'sender_id'
          final text = decoded['message'] ?? decoded['msg'] ?? '';
          final sender = decoded['sender_id'] ?? decoded['from'] ?? '';
          final msg = {"text": text ?? '', "isMe": sender == uid, "sender_id": sender};
          setState(() { _messages.add(msg); });
          try { ChatStore.saveMessage('${uid}_${widget.chatPartnerId}', msg); } catch (_) {}
          _scrollToBottom();
        } catch (_) {
          final msg = {"text": message.toString(), "isMe": false};
          setState(() { _messages.add(msg); });
          try { ChatStore.saveMessage('${uid}_${widget.chatPartnerId}', msg); } catch (_) {}
          _scrollToBottom();
        }
         }, onDone: () {
           setState(() { _connected = false; _connecting = false; });
         }, onError: (err) {
           if (!mounted) return;
           setState(() { _connectionError = err.toString(); _connected = false; _connecting = false; });
           ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('WebSocket error: $err')));
         });

      setState(() { _connected = true; _connecting = false; });
    } catch (e) {
        setState(() { _connectionError = e.toString(); _connecting = false; _connected = false; });
       ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to connect: $e')));
    }
  }

  void _sendMessage() {
    if (_msgController.text.trim().isNotEmpty) {
      final text = _msgController.text.trim();
      
      final user = FirebaseAuth.instance.currentUser;
      final uid = user?.uid ?? '';
      final msg = {"text": text, "isMe": true, "sender_id": uid};
      setState(() { _messages.add(msg); _msgController.clear(); });
      _scrollToBottom();
      try { ChatStore.saveMessage('${uid}_${widget.chatPartnerId}', msg); } catch (_) {}

      try {
        if (_connected) {
          _channel.sink.add(jsonEncode({"receiver_id": widget.chatPartnerId, "message": text, "msg_type": "text"}));
        } else {
           final scaffold = ScaffoldMessenger.of(context);
           scaffold.showSnackBar(const SnackBar(content: Text('Not connected. Message not sent.')));
        }
      } catch (e) {
        final scaffold = ScaffoldMessenger.of(context);
        scaffold.showSnackBar(SnackBar(content: Text('Send failed: $e')));
      }
    }
  }

  @override
  void dispose() {
    try { _channel.sink.close(); } catch (_) {}
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
            const CircleAvatar(radius: 15, child: Icon(CupertinoIcons.person, size: 15)),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.chatPartnerName, style: const TextStyle(fontSize: 16), overflow: TextOverflow.ellipsis),
                  if (_connecting) const Text('Connecting...', style: TextStyle(fontSize: 10))
                  else if (_connected) const Text('Connected', style: TextStyle(fontSize: 10))
                  else if (_connectionError != null) Text('Error: ${_connectionError!}', style: const TextStyle(fontSize: 10))
                  else const Text('Disconnected', style: TextStyle(fontSize: 10)),
              ],
            ),
          ),
          ],
        ),
        actions: [
        IconButton(icon: const Icon(CupertinoIcons.refresh), onPressed: _connectWebSocket, tooltip: 'Reconnect'),
          PopupMenuButton<String>(
            onSelected: (val) {},
            itemBuilder: (BuildContext context) {
              return {'Block User'}.map((String choice) {
                return PopupMenuItem<String>(value: choice, child: Text(choice));
              }).toList();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(10),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                return Align(
                  alignment: msg['isMe'] ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 5),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: msg['isMe'] ? AppTheme.fbBlue : Colors.grey[200],
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Text(msg['text'], style: TextStyle(color: msg['isMe'] ? Colors.white : Colors.black)),
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
      color: Colors.white,
      child: Row(
        children: [
          IconButton(icon: const Icon(CupertinoIcons.photo, color: AppTheme.textGrey), onPressed: () {}),
          Expanded(
            child: TextField(
              controller: _msgController,
              decoration: InputDecoration(
                hintText: "Type a message...",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
                filled: true, fillColor: AppTheme.fbBg,
                contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
              ),
            ),
          ),
          IconButton(icon: const Icon(CupertinoIcons.paperplane, color: AppTheme.fbBlue), onPressed: _sendMessage),
        ],
      ),
    );
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
