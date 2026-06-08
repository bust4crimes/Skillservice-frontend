import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:skillservice_frontend/views/messages/chat_detail_screen.dart';
import 'package:skillservice_frontend/views/profile/user_profile_screen.dart';
import 'package:skillservice_frontend/core/app_theme.dart';
import 'package:flutter/cupertino.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:skillservice_frontend/core/api_service.dart';

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});
  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  List<dynamic> _posts = [];
  Set<String> _appliedPostIds = {};
  bool _loading = true;

  @override
  void initState() { super.initState(); _fetch(); }

  Future _fetch() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      final res = await ApiService().dio.get('/posts/all');
      final apiPosts = (res.data is List) ? (res.data as List) : <dynamic>[];
      if (user != null) {
        try {
          final bookingsRes = await ApiService().dio.get('/bookings/user/${user.uid}');
          final bookings = bookingsRes.data as List? ?? [];
          _appliedPostIds = bookings.map((b) => (b['post_id'] ?? '').toString()).toSet();
        } catch (_) {}
      }
      if (!mounted) return;
      setState(() {
        _posts = apiPosts;
        _loading = false;
      });
    } catch (e) {
      if (mounted) setState(() {
        _posts = [];
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(titleSpacing: 0),
      body: _loading 
        ? const Center(child: CircularProgressIndicator()) 
        : RefreshIndicator(
            onRefresh: _fetch,
          child: ListView.builder(
              itemCount: _posts.length,
              itemBuilder: (context, i) => _buildCard(_posts[i]),
            ),
          ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showPostModal(context),
        child: const Icon(CupertinoIcons.add, color: Colors.white, size: 30),
      ),
    );
  }



  String _postId(dynamic post) => (post['_id'] ?? post['id'] ?? '').toString();

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

  Widget _buildCard(dynamic post) => Card(
    margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
    child: Padding(padding: const EdgeInsets.all(14),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Expanded(
          child: GestureDetector(
            onTap: () => Navigator.push(context, MaterialPageRoute(
              builder: (_) => UserProfileScreen(
                userId: post['owner_id'] ?? '',
                userName: post['owner_name'] ?? post['owner_id'] ?? 'User',
              ),
            )),
            child: Row(children: [
              CircleAvatar(
                radius: 20,
                backgroundImage: (post['owner_avatar'] as String?)?.isNotEmpty == true
                    ? CachedNetworkImageProvider(post['owner_avatar'])
                    : null,
                child: (post['owner_avatar'] as String?)?.isNotEmpty != true
                    ? const Icon(CupertinoIcons.person, size: 20)
                    : null,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(post['owner_name'] ?? post['owner_id'] ?? "User", maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14, color: AppTheme.textPrimary)),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppTheme.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(post['type'] ?? 'Skill', style: GoogleFonts.inter(color: AppTheme.primary, fontSize: 10, fontWeight: FontWeight.w600)),
                        ),
                        if (_timeAgo(post).isNotEmpty) ...[
                          const SizedBox(width: 6),
                          Text('· ${_timeAgo(post)}', style: GoogleFonts.inter(color: AppTheme.textSecondary, fontSize: 11)),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ]),
          ),
        ),
        if (post['owner_id'] == FirebaseAuth.instance.currentUser?.uid)
          PopupMenuButton<String>(
            icon: const Icon(CupertinoIcons.ellipsis, color: AppTheme.textSecondary),
            onSelected: (v) async {
              if (v == 'delete') {
                final confirm = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
                  title: const Text('Delete Post'),
                  content: const Text('Are you sure you want to delete this post?'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                    TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
                  ],
                ));
                if (confirm == true) {
                  try {
                    await ApiService().client.put('/posts/delete/${_postId(post)}');
                    _fetch();
                  } catch (e) {
                    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Delete failed: $e')));
                  }
                }
              }
            },
            itemBuilder: (_) => [const PopupMenuItem(value: 'delete', child: Text('Delete', style: TextStyle(color: Colors.red)))],
          ),
      ]),
      const SizedBox(height: 12),
      if ((post['title'] ?? '').isNotEmpty)
        Text(post['title'] ?? "", maxLines: 2, overflow: TextOverflow.ellipsis, style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 16, color: AppTheme.textPrimary)),
      const SizedBox(height: 4),
      Text(post['description'] ?? "", maxLines: 4, overflow: TextOverflow.ellipsis, style: GoogleFonts.inter(fontSize: 14, color: AppTheme.textSecondary)),
      const SizedBox(height: 10),
      if ((post['media_urls'] ?? []).isNotEmpty)
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: CachedNetworkImage(
            imageUrl: ((post['media_urls'] as List).first as String?) ?? '',
            fit: BoxFit.cover,
            width: double.infinity,
            height: 220,
            placeholder: (_, __) => Container(height: 220, color: AppTheme.surface, child: const Center(child: CircularProgressIndicator(strokeWidth: 2))),
            errorWidget: (_, __, ___) => Container(height: 220, color: AppTheme.surface, child: const Center(child: Icon(CupertinoIcons.photo, color: AppTheme.textSecondary))),
          ),
        ),
      const SizedBox(height: 8),
      const Divider(),
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(children: [
          Expanded(
            child: _ActionButton(
              icon: CupertinoIcons.chat_bubble_text,
              label: 'Comment${(post['comments'] as List?)?.isNotEmpty == true ? " ${(post['comments'] as List).length}" : ""}',
              onTap: () => _openComments(post),
            ),
          ),
          Expanded(
            child: _appliedPostIds.contains(_postId(post))
              ? _ActionButton(
                  icon: CupertinoIcons.checkmark_alt_circle_fill,
                  label: 'Applied',
                  color: Colors.green,
                  onTap: null,
                )
              : _ActionButton(
                  icon: CupertinoIcons.hand_thumbsup,
                  label: 'Apply / Book',
                  onTap: () => _applyToPost(post),
                ),
          ),
          Expanded(
            child: _ActionButton(
              icon: CupertinoIcons.chat_bubble,
              label: 'Chat',
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ChatDetailScreen(chatPartnerId: post['owner_id'] ?? '', chatPartnerName: post['owner_name'] ?? post['owner_id'] ?? 'User'))),
            ),
          ),
        ]),
      ),
    ]),
    ),
  );

  Widget _ActionButton({required IconData icon, required String label, Color? color, VoidCallback? onTap}) {
    final c = color ?? AppTheme.textSecondary;
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: c),
            const SizedBox(width: 4),
            Text(label, style: GoogleFonts.inter(color: c, fontSize: 12, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  void _openComments(dynamic post) {
    final postId = _postId(post);
    final comments = (post['comments'] as List?) ?? [];
    showModalBottomSheet(context: context, isScrollControlled: true, builder: (ctx) {
      final ctrl = TextEditingController();
      return Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
           Padding(padding: const EdgeInsets.all(12), child: const Text('Comments', style: TextStyle(fontWeight: FontWeight.bold))),
          SizedBox(
            height: 200,
            child: comments.isEmpty
              ? const Center(child: Text('No comments yet'))
              : ListView(children: comments.map<Widget>((c) => ListTile(
                  dense: true,
                  title: Text(c['user_name'] ?? 'User', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  subtitle: Text(c['comment_text'] ?? '', style: const TextStyle(fontSize: 14)),
                )).toList()),
          ),
          Padding(padding: const EdgeInsets.all(12), child: Row(children: [
            Expanded(child: TextField(controller: ctrl, decoration: const InputDecoration(hintText: 'Write a comment'))),
            IconButton(icon: const Icon(CupertinoIcons.paperplane), onPressed: () async {
              if (ctrl.text.trim().isEmpty) return;
              try {
                final user = FirebaseAuth.instance.currentUser;
                if (user == null) return;
                final name = user.displayName ?? user.uid;
                final updated = await ApiService().client.post('/posts/$postId/comment', data: {
                  'user_id': user.uid,
                  'user_name': name,
                  'comment_text': ctrl.text.trim(),
                });
                final idx = _posts.indexWhere((p) => _postId(p) == postId);
                if (idx >= 0) {
                  setState(() { _posts[idx] = updated.data; });
                }
                Navigator.pop(ctx);
              } catch (e) {
                if (ctx.mounted) ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text('Comment failed: $e')));
              }
            })])),
        ]),
      );
    });
  }

  Future<void> _applyToPost(dynamic post) async {
     try {
       final user = FirebaseAuth.instance.currentUser;
       if (user == null) throw Exception('Not authenticated');
       final postId = _postId(post);
       if (postId.isEmpty) throw Exception('Post ID missing');
       final scaffold = ScaffoldMessenger.of(context);
       await ApiService().client.post('/bookings/create/${user.uid}', data: {'post_id': postId, 'provider_id': post['owner_id']});
       setState(() => _appliedPostIds.add(postId));
       if (!context.mounted) return;
       scaffold.showSnackBar(const SnackBar(content: Text('Applied / booking request sent')));
     } catch (e) {
       final scaffold = ScaffoldMessenger.of(context);
       if (!context.mounted) return;
       scaffold.showSnackBar(SnackBar(content: Text('Apply failed: $e')));
     }
  }

  Future<Map<String, String?>> _ensureBackendProfile(User user) async {
    try {
      final res = await ApiService().dio.get('/auth/profile/${user.uid}');
      final data = res.data as Map<String, dynamic>?;
      if (data != null) {
        final fn = (data['first_name'] as String?) ?? '';
        final ln = (data['last_name'] as String?) ?? '';
        final fullName = "$fn $ln".trim();
        final avatar = data['profile_picture'] as String?;
        if (fullName.isNotEmpty && fullName != user.displayName) {
          await user.updateDisplayName(fullName);
          await user.reload();
        }
        return {
          'name': fullName.isNotEmpty ? fullName : (user.displayName ?? user.uid),
          'avatar': avatar,
        };
      }
    } catch (_) {}
    final token = await user.getIdToken(true);
    try {
      await ApiService().dio.post('/auth/register', data: {
        "id_token": token,
        "first_name": user.displayName ?? "",
        "last_name": "",
        "birthday": "",
        "location": "",
        "gender": "",
      });
    } catch (_) {}
    return {'name': user.displayName ?? user.uid, 'avatar': user.photoURL};
  }

  void _showPostModal(BuildContext context) {
    final titleC = TextEditingController();
    final descC = TextEditingController();
    String postType = "Skill Service";
    String? selectedCategory;
    XFile? pickedImage;
    final picker = ImagePicker();
    bool posting = false;

    const categories = [
      "Home Service", "Coding", "Education", "Design", "Writing",
      "Marketing", "Photography", "Music", "Fitness", "Consulting",
      "Repair", "Delivery", "Tutoring", "Other",
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
          top: 20,
          left: 20,
          right: 20,
        ),
        child: StatefulBuilder(
          builder: (context, setModalState) => SingleChildScrollView(
            child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("Create Post", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: postType,
                items: const [
                  DropdownMenuItem(value: "Skill Service", child: Text("Skill Service")),
                  DropdownMenuItem(value: "Job Offer", child: Text("Job Offer")),
                ],
                onChanged: (v) => setModalState(() => postType = v ?? postType),
                decoration: const InputDecoration(
                  labelText: "Post Type",
                  prefixIcon: Icon(CupertinoIcons.tag),
                ),
              ),
              const SizedBox(height: 10),
              TextField(controller: titleC, decoration: const InputDecoration(hintText: "Title")),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: categories.map((c) => ChoiceChip(
                  label: Text(c, style: const TextStyle(fontSize: 13)),
                  selected: selectedCategory == c,
                  onSelected: (v) => setModalState(() => selectedCategory = v ? c : null),
                  visualDensity: VisualDensity.compact,
                )).toList(),
              ),
              const SizedBox(height: 10),
              TextField(controller: descC, maxLines: 3, decoration: const InputDecoration(hintText: "Description")),
              const SizedBox(height: 12),
              Row(
                children: [
                  OutlinedButton.icon(
                    onPressed: () async {
                      final image = await picker.pickImage(source: ImageSource.gallery);
                      if (image != null) setModalState(() => pickedImage = image);
                    },
                    icon: const Icon(CupertinoIcons.photo),
                    label: const Text("Add Media"),
                  ),
                  if (pickedImage != null)
                    Padding(
                      padding: const EdgeInsets.only(left: 12),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(
                          File(pickedImage!.path),
                          width: 48,
                          height: 48,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  if (pickedImage != null)
                    IconButton(
                      icon: const Icon(CupertinoIcons.xmark_circle_fill, size: 20),
                      onPressed: () => setModalState(() => pickedImage = null),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  minimumSize: const Size(double.infinity, 50),
                ),
                onPressed: posting
                  ? null
                  : () async {
                      setModalState(() => posting = true);
                      try {
                        final user = FirebaseAuth.instance.currentUser;
                        if (user == null) throw Exception('Not authenticated');

                        final profileInfo = await _ensureBackendProfile(user);
                        await user.reload();

                        final Map<String, dynamic> postData = {
                          "title": titleC.text,
                          "description": descC.text,
                          "type": postType,
                          "owner_id": user.uid,
                          "owner_name": profileInfo['name'] ?? user.displayName,
                          "owner_avatar": profileInfo['avatar'],
                          if (selectedCategory != null) "category": selectedCategory,
                        };
                        if (pickedImage != null) {
                          final bytes = await pickedImage!.readAsBytes();
                          final cloudUrl = 'https://api.cloudinary.com/v1_1/${AppTheme.cloudinaryCloudName}/image/upload';
                          final formData = FormData.fromMap({
                            'file': MultipartFile.fromBytes(bytes, filename: 'post_${user.uid}_${DateTime.now().millisecondsSinceEpoch}'),
                            'upload_preset': AppTheme.cloudinaryUploadPreset,
                          });
                          final cloudRes = await Dio().post(cloudUrl, data: formData);
                          if (cloudRes.statusCode != 200) throw Exception('Image upload failed (${cloudRes.statusCode})');
                          final cloudData = cloudRes.data as Map<String, dynamic>;
                          final mediaUrl = (cloudData['secure_url'] ?? cloudData['url']) as String?;
                          if (mediaUrl == null || mediaUrl.isEmpty) throw Exception('Cloudinary did not return an image URL');
                          postData['media_urls'] = [mediaUrl];
                        }
                        await ApiService().client.post('/posts/', data: postData);

                        if (!ctx.mounted) return;
                        ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(
                          content: Text('Post uploaded!'),
                          duration: Duration(seconds: 2),
                        ));
                        Navigator.pop(ctx);
                        _fetch();
                      } catch (e) {
                        setModalState(() => posting = false);
                        if (!ctx.mounted) return;
                        ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text("Post failed: $e")));
                      }
                    },
                child: posting
                  ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                  : const Text("Post Now", style: TextStyle(color: Colors.white)),
              ),
              const SizedBox(height: 20),
            ],
          ),
          ),
        ),
      ),
    );
  }
}
