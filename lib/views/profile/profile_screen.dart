import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:skillservice_frontend/core/app_theme.dart';
import 'package:flutter/cupertino.dart';
import 'package:dio/dio.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:skillservice_frontend/providers/auth_provider.dart';
import 'package:skillservice_frontend/core/api_service.dart';
import 'package:skillservice_frontend/widgets/avatar_with_status.dart';
import 'package:skillservice_frontend/views/profile/edit_profile_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  List<dynamic> _posts = [];
  Map<String, dynamic>? _profile;
  bool _loading = true;



  @override
  void initState() { super.initState(); _fetch(); }

  Future _fetch() async {
    if (_profile == null) setState(() => _loading = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      Map<String, dynamic>? profile;
      try {
        final profileRes = await ApiService().dio.get('/auth/profile/${user.uid}');
        profile = profileRes.data as Map<String, dynamic>?;
      } on DioException catch (e) {
        if (e.response?.statusCode == 404) {
          final token = await user.getIdToken(true);
          await ApiService().client.post('/auth/register', data: {
            'id_token': token,
            'first_name': user.displayName?.split(' ').first ?? '',
            'last_name': user.displayName?.split(' ').last ?? '',
            'birthday': '',
            'location': '',
            'gender': '',
          });
          final profileRes = await ApiService().dio.get('/auth/profile/${user.uid}');
          profile = profileRes.data as Map<String, dynamic>?;
        } else {
          rethrow;
        }
      }

      List<dynamic> posts = [];
      try {
        final postsRes = await ApiService().dio.get('/posts/my/${user.uid}');
        posts = postsRes.data as List<dynamic>? ?? [];
      } catch (_) {}

      if (profile != null) {
        final fn = (profile['first_name'] as String?) ?? '';
        final ln = (profile['last_name'] as String?) ?? '';
        final fullName = "$fn $ln".trim();
        if (fullName.isNotEmpty && fullName != user.displayName) {
          await user.updateDisplayName(fullName);
          await user.reload();
        }
      }

      if (!mounted) return;
      setState(() {
        _profile = profile;
        _posts = posts;
        _loading = false;
      });
    } catch (e) {
      debugPrint("Profile fetch error: $e");
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    return Scaffold(
      drawer: _buildDrawer(context),
      appBar: AppBar(
        title: const Text("My Profile"),
        actions: [
          IconButton(
            icon: const Icon(CupertinoIcons.pencil),
            onPressed: () async {
              final result = await Navigator.push(context, MaterialPageRoute(builder: (_) => const EditProfileScreen()));
              await _fetch();
              if (result != null && result is Map && result.containsKey('skills')) {
                setState(() => _profile?['skills'] = result['skills']);
              }
            },
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _fetch,
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    _buildProfileHeader(user),
                    _buildSkillsSection(),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text("My Posts", style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 18, color: AppTheme.textPrimary)),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppTheme.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text("${_posts.length} posts", style: GoogleFonts.inter(color: AppTheme.primary, fontSize: 12, fontWeight: FontWeight.w600)),
                          ),
                        ],
                      ),
                    ),
                    _posts.isEmpty
                        ? const Padding(
                            padding: EdgeInsets.all(40),
                            child: Center(child: Text("No posts yet.")),
                          )
                        : ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _posts.length,
                            itemBuilder: (context, i) => _buildCard(_posts[i]),
                          ),
                  ],
                ),
              ),
            ),
    );
  }

  String _lastSeen(Map<String, dynamic>? profile) {
    if (profile?['active_status'] == true) return '';
    final ts = profile?['last_active'] as String?;
    if (ts == null || ts.isEmpty) return '';
    final dt = DateTime.tryParse(ts);
    if (dt == null) return '';
    final diff = DateTime.now().toUtc().difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return 'Last seen ${diff.inMinutes}m ago';
    if (diff.inHours < 24) return 'Last seen ${diff.inHours}h ago';
    if (diff.inDays < 7) return 'Last seen ${diff.inDays}d ago';
    return 'Last seen ${(diff.inDays / 7).floor()}w ago';
  }

  Widget _buildProfileHeader(User? user) {
    final firstName = _profile?['first_name'] ?? '';
    final lastName = _profile?['last_name'] ?? '';
    final fullName = "$firstName $lastName".trim();
    final location = _profile?['location'] ?? '';
    final bio = _profile?['bio'] ?? '';
    final followers = (_profile?['follower_ids'] as List?)?.length ?? 0;
    final following = (_profile?['following_ids'] as List?)?.length ?? 0;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 32, 20, 24),
      color: Colors.white,
      child: Column(
        children: [
          AvatarWithStatus(
            imageUrl: _profile?['profile_picture'] as String?,
            radius: 52,
            activeStatus: _profile?['active_status'] as bool?,
            lastActiveLabel: _lastSeen(_profile),
          ),
          const SizedBox(height: 16),
          Text(fullName.isNotEmpty ? fullName : (user?.displayName ?? "User"),
              style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 22, color: AppTheme.textPrimary)),
          if (bio.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(bio, textAlign: TextAlign.center, style: GoogleFonts.inter(color: AppTheme.textSecondary, fontSize: 14)),
          ],
          if (location.isNotEmpty) ...[
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(CupertinoIcons.location, size: 16, color: AppTheme.primary),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(location, style: GoogleFonts.inter(color: AppTheme.primary, fontSize: 14), maxLines: 2, overflow: TextOverflow.ellipsis),
                ),
              ],
            ),
          ],
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(child: Column(children: [Text('$followers', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 17, color: AppTheme.textPrimary)), const SizedBox(height: 2), Text('Followers', style: GoogleFonts.inter(color: AppTheme.textSecondary, fontSize: 12))])),
                Container(width: 1, height: 32, color: AppTheme.border),
                Expanded(child: Column(children: [Text('$following', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 17, color: AppTheme.textPrimary)), const SizedBox(height: 2), Text('Following', style: GoogleFonts.inter(color: AppTheme.textSecondary, fontSize: 12))])),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSkillsSection() {
    final skills = (_profile?['skills'] as List?) ?? [];
    if (skills.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text("Skills & Ratings", style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 18, color: AppTheme.textPrimary)),
        ),
        const SizedBox(height: 12),
        ...skills.map((s) {
          final name = s['name'] ?? '';
          final ratings = (s['ratings'] as List?) ?? [];
          final avg = ratings.isEmpty
              ? 0.0
              : ratings.map((r) => (r['rating'] as num?)?.toDouble() ?? 0.0).reduce((a, b) => a + b) / ratings.length;
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.border),
            ),
            child: Row(
              children: [
                Expanded(child: Text(name, style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14, color: AppTheme.textPrimary))),
                Row(children: [
                  ...List.generate(5, (i) => Icon(
                    i < avg.round() ? CupertinoIcons.star_fill : CupertinoIcons.star,
                    size: 16,
                    color: i < avg.round() ? Colors.amber : AppTheme.border,
                  )),
                  const SizedBox(width: 6),
                  Text('${ratings.length}', style: GoogleFonts.inter(color: AppTheme.textSecondary, fontSize: 12)),
                ]),
              ],
            ),
          );
        }),
      ]),
    );
  }

  Widget _buildCard(dynamic post) => Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(post['type'] ?? 'Skill', style: GoogleFonts.inter(color: AppTheme.primary, fontSize: 11, fontWeight: FontWeight.w600)),
                ),
                const Spacer(),
                Text(_timeAgo(post), style: GoogleFonts.inter(color: AppTheme.textSecondary, fontSize: 12)),
              ],
            ),
            const SizedBox(height: 8),
            Text(post['title'] ?? "Untitled", maxLines: 2, overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 16, color: AppTheme.textPrimary)),
            const SizedBox(height: 4),
            Text(post['description'] ?? "", maxLines: 4, overflow: TextOverflow.ellipsis, style: GoogleFonts.inter(fontSize: 14, color: AppTheme.textSecondary)),
            if ((post['media_urls'] ?? []).isNotEmpty) ...[
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: CachedNetworkImage(
                  imageUrl: ((post['media_urls'] as List).first as String?) ?? '',
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: 200,
                  placeholder: (_, __) => Container(height: 200, color: AppTheme.surface, child: const Center(child: CircularProgressIndicator(strokeWidth: 2))),
                  errorWidget: (_, __, ___) => Container(height: 200, color: AppTheme.surface, child: const Center(child: Icon(CupertinoIcons.photo, color: AppTheme.textSecondary))),
                ),
              ),
            ],
          ]),
        ),
      );

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

  String _buildDrawerName() {
    final display = FirebaseAuth.instance.currentUser?.displayName;
    if (display != null && display.isNotEmpty) return display;
    final first = _profile?['first_name'] ?? '';
    final last = _profile?['last_name'] ?? '';
    final full = "$first $last".trim();
    return full.isNotEmpty ? full : "User";
  }

  Widget _buildDrawer(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final name = _buildDrawerName();
    final location = (_profile?['location'] ?? '') as String;
    final avatarUrl = _profile?['profile_picture'] as String?;

    return Drawer(
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [const Color(0xFF1B5E20), const Color(0xFF2E7D32)]
                    : [const Color(0xFF2E7D32), const Color(0xFF4CAF50)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 36,
                      backgroundColor: Colors.white.withValues(alpha: 0.3),
                      backgroundImage: avatarUrl != null && avatarUrl.isNotEmpty
                          ? NetworkImage(avatarUrl)
                          : null,
                      child: avatarUrl == null || avatarUrl.isEmpty
                          ? const Icon(CupertinoIcons.person_fill, size: 36, color: Colors.white)
                          : null,
                    ),
                    const SizedBox(height: 12),
                    Text(name, style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 18, color: Colors.white)),
                    if (location.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(CupertinoIcons.location, size: 14, color: Colors.white70),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(location, style: GoogleFonts.inter(fontSize: 13, color: Colors.white70), maxLines: 1, overflow: TextOverflow.ellipsis),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                const SizedBox(height: 8),
                _drawerTile(CupertinoIcons.person_fill, 'My Profile', () {
                  Navigator.pop(context);
                }),
                _drawerTile(CupertinoIcons.pencil, 'Edit Profile', () async {
                  Navigator.pop(context);
                  final result = await Navigator.push(context, MaterialPageRoute(builder: (_) => const EditProfileScreen()));
                  await _fetch();
                  if (result != null && result is Map && result.containsKey('skills')) {
                    setState(() => _profile?['skills'] = result['skills']);
                  }
                }),
                _drawerTile(CupertinoIcons.settings, 'Settings', () {
                  Navigator.pop(context);
                }),
                _drawerTile(CupertinoIcons.doc_text, 'Terms & Privacy', () {
                  Navigator.pop(context);
                }),
                const SizedBox(height: 8),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Divider(),
                ),
                const SizedBox(height: 8),
                _drawerTile(CupertinoIcons.square_arrow_right, 'Log Out', () {
                  context.read<SkillAuthProvider>().logout();
                }, isDestructive: true),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _drawerTile(IconData icon, String title, VoidCallback onTap, {bool isDestructive = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: isDestructive ? Colors.red.withValues(alpha: 0.1) : AppTheme.surface,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, size: 20, color: isDestructive ? AppTheme.danger : AppTheme.textPrimary),
        ),
        title: Text(title, style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w500, color: isDestructive ? AppTheme.danger : AppTheme.textPrimary)),
        trailing: Icon(CupertinoIcons.chevron_right, size: 18, color: AppTheme.textSecondary),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        onTap: onTap,
      ),
    );
  }

}
