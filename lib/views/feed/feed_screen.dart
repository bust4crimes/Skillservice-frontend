import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';
import 'package:skillservice_frontend/views/messages/chat_detail_screen.dart';
import 'package:skillservice_frontend/core/app_theme.dart';
import 'package:flutter/cupertino.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:skillservice_frontend/core/api_service.dart';

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});
  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  List<dynamic> _posts = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _fetch(); }

  Future _fetch() async {
    try {
      final res = await ApiService().dio.get('/posts/all');
      if (!mounted) return;
      setState(() { _posts = res.data; _loading = false; });
    } catch (e) { if (mounted) setState(() => _loading = false); }
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

  Widget _buildCard(dynamic post) => Container(
    margin: const EdgeInsets.only(top: 8), color: Colors.white, padding: const EdgeInsets.all(15),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
        const CircleAvatar(child: Icon(CupertinoIcons.person)),
        const SizedBox(width: 10),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(post['owner_id'] ?? "User", style: const TextStyle(fontWeight: FontWeight.bold)),
          Text("${post['type'] ?? 'Skill'}", style: const TextStyle(color: AppTheme.textGrey, fontSize: 12)),
        ]),
      ]),
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 12), 
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if ((post['title'] ?? '').isNotEmpty) Text(post['title'] ?? "", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 4),
            Text(post['description'] ?? "", style: const TextStyle(fontSize: 15)),
            const SizedBox(height: 8),
            if ((post['media_urls'] ?? []).isNotEmpty)
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 260),
                child: ClipRRect(borderRadius: BorderRadius.circular(8), child: CachedNetworkImage(imageUrl: (post['media_urls'] as List).first, fit: BoxFit.cover, width: double.infinity)),
              ),
          ],
        )
      ),
      const Divider(),
      Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
        TextButton.icon(onPressed: () => _openComments(post), icon: const Icon(CupertinoIcons.chat_bubble_text, color: AppTheme.textGrey), label: const Text('Comment', style: TextStyle(color: AppTheme.textGrey))),
        TextButton.icon(onPressed: () => _applyToPost(post), icon: const Icon(CupertinoIcons.hand_thumbsup, color: AppTheme.textGrey), label: const Text('Apply / Book', style: TextStyle(color: AppTheme.textGrey))),
        TextButton.icon(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ChatDetailScreen(chatPartnerId: post['owner_id'] ?? '', chatPartnerName: post['owner_id'] ?? 'User'))), icon: const Icon(CupertinoIcons.chat_bubble, color: AppTheme.textGrey), label: const Text('Chat', style: TextStyle(color: AppTheme.textGrey))),
      ])
    ]),
  );

  void _openComments(dynamic post) {
    showModalBottomSheet(context: context, isScrollControlled: true, builder: (context) {
      final ctrl = TextEditingController();
      return Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
           Padding(padding: const EdgeInsets.all(12), child: const Text('Comments', style: TextStyle(fontWeight: FontWeight.bold))),
          // Placeholder list
          SizedBox(height: 200, child: ListView(children: const [ListTile(title: Text('Nice post')), ListTile(title: Text('Interested'))])),
               Padding(padding: const EdgeInsets.all(12), child: Row(children: [Expanded(child: TextField(controller: ctrl, decoration: const InputDecoration(hintText: 'Write a comment'))), IconButton(icon: const Icon(CupertinoIcons.paperplane), onPressed: () async {
                        if (ctrl.text.trim().isEmpty) return;
                        final nav = Navigator.of(context);
                        final scaffold = ScaffoldMessenger.of(context);
                        nav.pop();
                        scaffold.showSnackBar(const SnackBar(content: Text('Comments are not supported by the current backend yet.')));
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
       if (!context.mounted) return;
       scaffold.showSnackBar(const SnackBar(content: Text('Applied / booking request sent')));
     } catch (e) {
       final scaffold = ScaffoldMessenger.of(context);
       if (!context.mounted) return;
       scaffold.showSnackBar(SnackBar(content: Text('Apply failed: $e')));
     }
  }

  Future<void> _ensureBackendProfile(User user) async {
    try {
      await ApiService().dio.get('/auth/profile/${user.uid}');
      return;
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
  }

  void _showPostModal(BuildContext context) {
    final titleC = TextEditingController();
    final descC = TextEditingController();
    String postType = "Skill Service";
    String? selectedCategory;
    XFile? pickedImage;
    final picker = ImagePicker();

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
                  backgroundColor: AppTheme.fbBlue,
                  minimumSize: const Size(double.infinity, 50),
                ),
                onPressed: () async {
                  try {
                    final user = FirebaseAuth.instance.currentUser;
                    if (user == null) throw Exception('Not authenticated');

                    await _ensureBackendProfile(user);

                    final postData = {
                      "title": titleC.text,
                      "description": descC.text,
                      "type": postType,
                      "owner_id": user.uid,
                      if (selectedCategory != null) "category": selectedCategory,
                    };
                    if (pickedImage != null) {
                      final formData = FormData.fromMap({
                        ...postData,
                        "media": await MultipartFile.fromFile(pickedImage!.path, filename: pickedImage!.name),
                      });
                      await ApiService().client.post('/posts/', data: formData);
                    } else {
                      await ApiService().client.post('/posts/', data: postData);
                    }

                    if (!ctx.mounted) return;
                    Navigator.pop(ctx);
                    _fetch();
                  } catch (e) {
                    if (!ctx.mounted) return;
                    ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text("Post failed: $e")));
                  }
                },
                child: const Text("Post Now", style: TextStyle(color: Colors.white)),
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
