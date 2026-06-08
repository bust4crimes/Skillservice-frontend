import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:skillservice_frontend/core/api_service.dart';
import 'package:skillservice_frontend/views/profile/user_profile_screen.dart';
import 'package:skillservice_frontend/core/app_theme.dart';
import 'package:google_fonts/google_fonts.dart';

class SearchScreen extends StatefulWidget {
  final String initialQuery;
  const SearchScreen({Key? key, this.initialQuery = ''}) : super(key: key);
  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _ctrl = TextEditingController();
  List<dynamic> _results = [];
  bool _loading = false;
  bool _searched = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _ctrl.text = widget.initialQuery;
    if (widget.initialQuery.isNotEmpty) _search();
  }

  Future _search() async {
    final q = _ctrl.text.trim();
    if (q.isEmpty) return;
    setState(() { _loading = true; _searched = true; _error = null; });
    try {
      final res = await ApiService().dio.get('/auth/search', queryParameters: {'q': q});
      if (!mounted) return;
      final data = res.data;
      final List<dynamic> results;
      if (data is List) {
        results = data;
      } else if (data is Map && data.containsKey('users')) {
        results = data['users'] as List<dynamic>;
      } else if (data is Map && data.containsKey('results')) {
        results = data['results'] as List<dynamic>;
      } else {
        results = [];
      }
      setState(() { _results = results; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _results = []; _loading = false; _error = 'Search failed. Please try again.'; });
    }
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _ctrl,
          autofocus: widget.initialQuery.isEmpty,
          style: GoogleFonts.inter(fontSize: 16, color: AppTheme.textPrimary),
          decoration: InputDecoration(
            hintText: 'Search users by name...',
            hintStyle: GoogleFonts.inter(color: AppTheme.textSecondary),
            border: InputBorder.none,
            filled: false,
            contentPadding: EdgeInsets.zero,
          ),
          onSubmitted: (_) => _search(),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 4),
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: const Icon(CupertinoIcons.search, color: AppTheme.primary),
              onPressed: _search,
            ),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : !_searched
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.search, size: 64, color: AppTheme.textSecondary.withValues(alpha: 0.4)),
                      const SizedBox(height: 16),
                      Text('Enter a name to search', style: GoogleFonts.inter(color: AppTheme.textSecondary, fontSize: 16)),
                    ],
                  ),
                )
              : _error != null
                  ? Center(child: Text(_error!, style: GoogleFonts.inter(color: Colors.red)))
                  : _results.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.person_search, size: 64, color: AppTheme.textSecondary.withValues(alpha: 0.4)),
                              const SizedBox(height: 16),
                              Text('No users found', style: GoogleFonts.inter(color: AppTheme.textSecondary, fontSize: 16)),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          itemCount: _results.length,
                          itemBuilder: (context, i) {
                            final u = _results[i];
                            final fn = u['first_name'] ?? '';
                            final ln = u['last_name'] ?? '';
                            final name = "$fn $ln".trim();
                            final location = u['location'] ?? '';
                            final avatar = u['profile_picture'] as String?;
                            return Container(
                              margin: const EdgeInsets.symmetric(vertical: 4),
                              decoration: BoxDecoration(
                                color: Theme.of(context).cardColor,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: AppTheme.border),
                              ),
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                leading: CircleAvatar(
                                  radius: 24,
                                  backgroundImage: avatar != null && avatar.isNotEmpty
                                      ? CachedNetworkImageProvider(avatar)
                                      : null,
                                  child: avatar == null || avatar.isEmpty
                                      ? const Icon(CupertinoIcons.person, size: 24)
                                      : null,
                                ),
                                title: Text(name.isNotEmpty ? name : u['email'] ?? 'User',
                                    style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 15, color: AppTheme.textPrimary)),
                                subtitle: location.isNotEmpty
                                    ? Text(location, style: GoogleFonts.inter(color: AppTheme.textSecondary, fontSize: 13))
                                    : null,
                                trailing: const Icon(CupertinoIcons.chevron_right, color: AppTheme.textSecondary, size: 18),
                                onTap: () => Navigator.push(context, MaterialPageRoute(
                                  builder: (_) => UserProfileScreen(
                                    userId: u['id'] ?? '',
                                    userName: name.isNotEmpty ? name : u['email'] ?? 'User',
                                  ),
                                )),
                              ),
                            );
                          },
                        ),
    );
  }
}
