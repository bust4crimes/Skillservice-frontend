import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:skillservice_frontend/core/api_service.dart';
import 'package:skillservice_frontend/core/app_theme.dart';
import 'package:skillservice_frontend/widgets/avatar_with_status.dart';
import 'package:skillservice_frontend/views/messages/chat_detail_screen.dart';
import 'package:skillservice_frontend/views/messages/blocked_users_screen.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});
  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  List<dynamic> _conversations = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      final res = await ApiService().dio.get('/chat/conversations/${user.uid}');
      final apiConvs = (res.data is List) ? (res.data as List<dynamic>) : <dynamic>[];
      if (!mounted) return;
      setState(() {
        _conversations = apiConvs;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() {
        _conversations = [];
        _loading = false;
      });
    }
  }

  String _timeAgo(String? iso) {
    if (iso == null) return '';
    final dt = DateTime.tryParse(iso);
    if (dt == null) return '';
    final diff = DateTime.now().toUtc().difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${(diff.inDays / 7).floor()}w ago';
  }

  String _lastSeenLabel(bool? active, String? lastActive) {
    if (active == true) return '';
    if (lastActive == null) return '';
    return _timeAgo(lastActive);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Messages"),
        actions: [
          IconButton(
            icon: const Icon(CupertinoIcons.clear_circled),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BlockedUsersScreen())),
          ),
        ],
      ),
      body: _loading
        ? const Center(child: CircularProgressIndicator())
        : _conversations.isEmpty
            ? const Center(child: Text("No conversations yet"))
            : RefreshIndicator(
                onRefresh: _fetch,
                child: ListView.separated(
                  itemCount: _conversations.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (_, i) {
                    final c = _conversations[i];
                    final otherId = c['other_user_id'] as String? ?? '';
                    final otherName = c['other_user_name'] as String? ?? otherId;
                    final lastMsg = c['last_message'] as String? ?? '';
                    final ts = c['last_timestamp'] as String?;
                    final active = c['active_status'] as bool?;
                    final lastActive = c['last_active'] as String?;
                    return GestureDetector(
                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ChatDetailScreen(
                              chatPartnerId: otherId,
                              chatPartnerName: otherName,
                            ),
                          ),
                        );
                        _fetch();
                      },
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppTheme.border),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          child: Row(
                            children: [
                              AvatarWithStatus(
                                radius: 24,
                                activeStatus: active,
                                lastActiveLabel: _lastSeenLabel(active, lastActive),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(otherName, style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 15, color: AppTheme.textPrimary)),
                                    const SizedBox(height: 2),
                                    Text(lastMsg, maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.inter(color: AppTheme.textSecondary, fontSize: 13)),
                                  ],
                                ),
                              ),
                              if (ts != null) ...[
                                const SizedBox(width: 8),
                                Text(_timeAgo(ts), style: GoogleFonts.inter(color: AppTheme.textSecondary, fontSize: 11)),
                              ],
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
    );
  }
}
