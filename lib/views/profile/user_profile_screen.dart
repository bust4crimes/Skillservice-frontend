import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:skillservice_frontend/core/app_theme.dart';
import 'package:skillservice_frontend/core/api_service.dart';
import 'package:skillservice_frontend/views/messages/chat_detail_screen.dart';
import 'package:skillservice_frontend/widgets/avatar_with_status.dart';
import 'package:google_fonts/google_fonts.dart';

class UserProfileScreen extends StatefulWidget {
  final String userId;
  final String userName;
  const UserProfileScreen({Key? key, required this.userId, required this.userName}) : super(key: key);
  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  Map<String, dynamic>? _profile;
  List<dynamic> _posts = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _fetch(); }

  Future _fetch() async {
    try {
      final profileRes = await ApiService().dio.get('/auth/profile/${widget.userId}');
      final postsRes = await ApiService().dio.get('/posts/my/${widget.userId}');
      if (!mounted) return;
      setState(() {
        _profile = profileRes.data as Map<String, dynamic>?;
        _posts = postsRes.data as List<dynamic>? ?? [];
        _loading = false;
      });
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _timeAgo(dynamic post) {
    final ts = post['timestamp'] as String?;
    if (ts == null || ts.isEmpty) return '';
    final dt = DateTime.tryParse(ts);
    if (dt == null) return '';
    final diff = DateTime.now().toUtc().difference(dt);
    if (diff.inSeconds < 60) return '${diff.inSeconds}s';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    if (diff.inDays < 7) return '${diff.inDays}d';
    return '${(diff.inDays / 7).floor()}w';
  }

  String _lastSeen(Map<String, dynamic>? profile) {
    if (profile?['active_status'] == true) return '';
    final ts = profile?['last_active'] as String?;
    if (ts == null || ts.isEmpty) return '';
    final dt = DateTime.tryParse(ts);
    if (dt == null) return '';
    final diff = DateTime.now().toUtc().difference(dt);
    if (diff.inMinutes < 1) return 'Last seen Just now';
    if (diff.inMinutes < 60) return 'Last seen ${diff.inMinutes}m ago';
    if (diff.inHours < 24) return 'Last seen ${diff.inHours}h ago';
    if (diff.inDays < 7) return 'Last seen ${diff.inDays}d ago';
    return 'Last seen ${(diff.inDays / 7).floor()}w ago';
  }

  @override
  Widget build(BuildContext context) {
    final fn = _profile?['first_name'] ?? '';
    final ln = _profile?['last_name'] ?? '';
    final fullName = "$fn $ln".trim();
    final location = _profile?['location'] ?? '';
    final bio = _profile?['bio'] ?? '';

    return Scaffold(
      appBar: AppBar(
        title: Text(fullName.isNotEmpty ? fullName : widget.userName, style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _fetch,
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          AvatarWithStatus(
                            imageUrl: _profile?['profile_picture'] as String?,
                            radius: 50,
                            activeStatus: _profile?['active_status'] as bool?,
                            lastActiveLabel: _lastSeen(_profile),
                          ),
                          const SizedBox(height: 16),
                          Text(fullName.isNotEmpty ? fullName : widget.userName,
                              style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
                          if (location.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(CupertinoIcons.location, size: 14, color: AppTheme.textSecondary),
                                const SizedBox(width: 4),
                                Flexible(
                                  child: Text(location, style: GoogleFonts.inter(color: AppTheme.textSecondary, fontSize: 13), maxLines: 2, overflow: TextOverflow.ellipsis),
                                ),
                              ],
                            ),
                          ],
                          if (bio.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            Text(bio, textAlign: TextAlign.center, style: GoogleFonts.inter(fontSize: 14, color: AppTheme.textPrimary)),
                          ],
                          const SizedBox(height: 20),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () => Navigator.push(context, MaterialPageRoute(
                                builder: (_) => ChatDetailScreen(
                                  chatPartnerId: widget.userId,
                                  chatPartnerName: fullName.isNotEmpty ? fullName : widget.userName,
                                ),
                              )),
                              icon: const Icon(CupertinoIcons.chat_bubble, size: 18),
                              label: Text('Chat', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primary,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                padding: const EdgeInsets.symmetric(vertical: 14),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text("Posts", style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppTheme.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text("${_posts.length} posts", style: GoogleFonts.inter(color: AppTheme.primary, fontSize: 12, fontWeight: FontWeight.w500)),
                          ),
                        ],
                      ),
                    ),
                    if (_posts.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(40),
                        child: Center(child: Text("No posts yet.")),
                      )
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _posts.length,
                        itemBuilder: (context, i) => _buildCard(_posts[i]),
                      ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildCard(dynamic post) => Container(
    margin: const EdgeInsets.only(bottom: 16),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Theme.of(context).cardColor,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: AppTheme.border),
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: AppTheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(post['type'] ?? 'Skill', style: GoogleFonts.inter(color: AppTheme.primary, fontSize: 11, fontWeight: FontWeight.w500)),
        ),
        const Spacer(),
        Text(_timeAgo(post), style: GoogleFonts.inter(color: AppTheme.textSecondary, fontSize: 12)),
      ]),
      const SizedBox(height: 10),
      if ((post['title'] ?? '').isNotEmpty)
        Text(post['title'] ?? '', maxLines: 2, overflow: TextOverflow.ellipsis, style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 16, color: AppTheme.textPrimary)),
      const SizedBox(height: 6),
      Text(post['description'] ?? '', maxLines: 4, overflow: TextOverflow.ellipsis, style: GoogleFonts.inter(fontSize: 14, color: AppTheme.textSecondary)),
      if ((post['media_urls'] ?? []).isNotEmpty) ...[
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: CachedNetworkImage(
            imageUrl: ((post['media_urls'] as List).first as String?) ?? '',
            fit: BoxFit.cover,
            width: double.infinity,
            height: 200,
            placeholder: (_, __) => Container(height: 200, color: Colors.grey[200], child: const Center(child: CircularProgressIndicator(strokeWidth: 2))),
            errorWidget: (_, __, ___) => Container(height: 200, color: Colors.grey[200], child: const Center(child: Icon(CupertinoIcons.photo, color: Colors.grey))),
          ),
        ),
      ],
    ]),
  );
}
