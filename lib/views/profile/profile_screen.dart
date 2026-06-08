import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:skillservice_frontend/core/app_theme.dart';
import 'package:flutter/cupertino.dart';
import 'package:skillservice_frontend/providers/auth_provider.dart';
import 'package:skillservice_frontend/core/api_service.dart';
import 'package:skillservice_frontend/views/profile/edit_profile_screen.dart';
import 'package:skillservice_frontend/views/settings/settings_screen.dart';

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

      final results = await Future.wait([
        ApiService().dio.get('/auth/profile/${user.uid}').then((v) => v.data),
        ApiService().dio.get('/users/${user.uid}/dashboard').then((v) => v.data['active_posts'] ?? []),
      ]);

      if (!mounted) return;
      debugPrint("Profile data: ${results[0]}");
      setState(() {
        _profile = results[0] as Map<String, dynamic>?;
        _posts = results[1] as List<dynamic>? ?? [];
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
              await Navigator.push(context, MaterialPageRoute(builder: (_) => const EditProfileScreen()));
              _fetch();
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
                    const Divider(),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text("My Posts", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          Text("${_posts.length} posts", style: const TextStyle(color: AppTheme.textGrey)),
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

  Widget _buildProfileHeader(User? user) {
    final firstName = _profile?['first_name'] ?? '';
    final lastName = _profile?['last_name'] ?? '';
    final fullName = "$firstName $lastName".trim();
    final location = _profile?['location'] ?? '';

    return Container(
      padding: const EdgeInsets.all(24),
      color: Colors.white,
      child: Column(
        children: [
          const CircleAvatar(radius: 50, child: Icon(CupertinoIcons.person, size: 50)),
          const SizedBox(height: 16),
          Text(fullName.isNotEmpty ? fullName : (user?.displayName ?? "User"),
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          if (location.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(CupertinoIcons.location, size: 14, color: AppTheme.textGrey),
                const SizedBox(width: 4),
                Text(location, style: const TextStyle(color: AppTheme.textGrey, fontSize: 12)),
              ],
            ),
          ],

        ],
      ),
    );
  }

  Widget _buildFilterBar() => Container(
    height: 50, color: Colors.white,
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: ["All", "Skill Service", "Job Offer"].map((t) => const ChoiceChip(label: Text("All"), selected: true, showCheckmark: false)).toList()),
  );

  Widget _buildCard(dynamic post) => Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        color: Colors.white,
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(post['title'] ?? "Untitled",
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 4),
          Text(post['description'] ?? "", style: const TextStyle(fontSize: 14)),
          const SizedBox(height: 8),
          Row(mainAxisAlignment: MainAxisAlignment.end, children: [
            TextButton(
                onPressed: () {},
                child: const Text("Edit", style: TextStyle(color: AppTheme.fbBlue))),
          ])
        ]),
      );

  Widget _btn(IconData i, String l) => TextButton.icon(onPressed: (){}, icon: Icon(i, size: 20, color: AppTheme.textGrey), label: Text(l, style: const TextStyle(color: AppTheme.textGrey)));

  String _buildDrawerName() {
    final display = FirebaseAuth.instance.currentUser?.displayName;
    if (display != null && display.isNotEmpty) return display;
    final first = _profile?['first_name'] ?? '';
    final last = _profile?['last_name'] ?? '';
    final full = "$first $last".trim();
    return full.isNotEmpty ? full : "User";
  }

  Widget _buildDrawer(BuildContext context) => Drawer(
        child: Column(children: [
          UserAccountsDrawerHeader(
            decoration: const BoxDecoration(color: AppTheme.fbBlue),
            accountName: Text(_buildDrawerName()),
            accountEmail: const Text(""),
            currentAccountPicture: const CircleAvatar(backgroundColor: Colors.white, child: Icon(CupertinoIcons.person)),
          ),
          ListTile(
            leading: const Icon(CupertinoIcons.person_fill, color: AppTheme.textGrey),
            title: const Text("Edit Profile"),
            onTap: () async {
              Navigator.pop(context);
              await Navigator.push(context, MaterialPageRoute(builder: (_) => const EditProfileScreen()));
              _fetch();
            },
          ),
          const Spacer(),
          ListTile(
            leading: const Icon(CupertinoIcons.square_arrow_right, color: AppTheme.textGrey),
            title: const Text("Log Out", style: TextStyle(color: Colors.red)),
            onTap: () => context.read<SkillAuthProvider>().logout(),
          ),
        ]),
      );

  void _showPostModal(BuildContext context) {
    final ctrl = TextEditingController();
    showModalBottomSheet(context: context, isScrollControlled: true, builder: (context) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, top: 20, left: 20, right: 20),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Text("Create Post", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        TextField(controller: ctrl, maxLines: 3, decoration: const InputDecoration(hintText: "What skill are you swapping?")),
        const SizedBox(height: 20),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.fbBlue, minimumSize: const Size(double.infinity, 50)),
          onPressed: () async {
            try {
              final user = FirebaseAuth.instance.currentUser;
              if (user == null) throw Exception('Not authenticated');
               await ApiService().dio.post('/posts/', data: {
                 "title": "Post Title",
                 "description": ctrl.text,
                 "type": "Skill Service",
                 "owner_id": user.uid,
               });
               if (!context.mounted) return;
               Navigator.pop(context); 
               _fetch();
             } catch (e) { 
               if (!context.mounted) return;
               ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Failed to post"))); 
             }
          },
          child: const Text("Post Now", style: TextStyle(color: Colors.white)),
        ),
        const SizedBox(height: 20),
      ]),
    ));
  }
}
