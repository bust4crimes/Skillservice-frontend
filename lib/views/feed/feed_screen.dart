import 'package:flutter/material.dart';
import 'package:skillservice_frontend/core/app_theme.dart';

class FeedScreen extends StatefulWidget {
  @override
  _FeedScreenState createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  String selectedType = "All";

  void _showCreatePostModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          top: 20, left: 20, right: 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Create New Post", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            TextField(decoration: InputDecoration(hintText: "Post Title", border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)))),
            const SizedBox(height: 10),
            TextField(maxLines: 3, decoration: InputDecoration(hintText: "Description & Skills needed...", border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)))),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.fbBlue, padding: const EdgeInsets.symmetric(vertical: 15)),
                onPressed: () => Navigator.pop(context),
                child: const Text("Post to Community", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _buildSearchBar(),
        actions: [
          IconButton(icon: const Icon(Icons.notifications_none), onPressed: () {}),
        ],
      ),
      body: Column(
        children: [
          _buildFilters(),
          Expanded(child: ListView.builder(itemCount: 8, itemBuilder: (context, index) => _buildPostCard())),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppTheme.fbBlue,
        onPressed: () => _showCreatePostModal(context),
        child: const Icon(Icons.add, color: Colors.white, size: 30),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      height: 40,
      decoration: BoxDecoration(color: AppTheme.fbBg, borderRadius: BorderRadius.circular(20)),
      child: const TextField(
        decoration: InputDecoration(
          hintText: "Search for skills or services...", 
          prefixIcon: Icon(Icons.search, size: 20), 
          border: InputBorder.none,
          contentPadding: EdgeInsets.only(top: 5)
        ),
      ),
    );
  }

  Widget _buildFilters() {
    return Container(
      height: 60, color: Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: ["All", "Skill Service", "Job Offer"].map((t) => ChoiceChip(
          label: Text(t), 
          selected: selectedType == t,
          onSelected: (s) => setState(() => selectedType = t),
          selectedColor: AppTheme.fbBlue.withOpacity(0.2),
        )).toList(),
      ),
    );
  }

  Widget _buildPostCard() {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 0),
      elevation: 0,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(backgroundColor: Colors.grey[300], child: const Icon(Icons.person, color: Colors.white)),
                const SizedBox(width: 12),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Skill Provider", style: TextStyle(fontWeight: FontWeight.bold)),
                    Text("Manila • 3h ago", style: TextStyle(color: AppTheme.textGrey, fontSize: 12)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text("Offering Flutter Mobile Development lessons in exchange for Advanced UI/UX Design tutoring.", style: TextStyle(fontSize: 15)),
            const SizedBox(height: 12),
            const Divider(height: 1),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _actionBtn(Icons.comment_outlined, "Comment"),
                _actionBtn(Icons.handshake_outlined, "Apply / Book"),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _actionBtn(IconData i, String l) => TextButton.icon(
    onPressed: () {}, 
    icon: Icon(i, size: 20, color: AppTheme.textGrey), 
    label: Text(l, style: const TextStyle(color: AppTheme.textGrey))
  );
}