// lib/views/feed/feed_screen.dart
import 'package:flutter/material.dart';
import '../../core/app_theme.dart';

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
            const Text("Create Post", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            TextField(decoration: InputDecoration(hintText: "What skill are you offering?", border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)))),
            const SizedBox(height: 10),
            TextField(maxLines: 3, decoration: InputDecoration(hintText: "Description...", border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)))),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.fbBlue),
                onPressed: () => Navigator.pop(context),
                child: const Text("Post", style: TextStyle(color: Colors.white)),
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
      ),
      body: Column(
        children: [
          _buildFilters(),
          Expanded(child: ListView.builder(itemCount: 5, itemBuilder: (context, index) => _buildPostCard())),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppTheme.fbBlue,
        onPressed: () => _showCreatePostModal(context),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      height: 40,
      decoration: BoxDecoration(color: AppTheme.fbBg, borderRadius: BorderRadius.circular(20)),
      child: const TextField(
        decoration: InputDecoration(hintText: "Search skills...", prefixIcon: Icon(Icons.search), border: InputBorder.none),
      ),
    );
  }

  Widget _buildFilters() {
    return Container(
      height: 50, color: Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: ["All", "Skill Service", "Job Offer"].map((t) => ChoiceChip(
          label: Text(t), selected: selectedType == t,
          onSelected: (s) => setState(() => selectedType = t),
        )).toList(),
      ),
    );
  }

  Widget _buildPostCard() {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("User Name", style: TextStyle(fontWeight: FontWeight.bold)),
            const Text("Location • 2h ago", style: TextStyle(color: AppTheme.textGrey, fontSize: 12)),
            const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Text("I am looking for a web developer to help with a project.")),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                TextButton.icon(onPressed: () {}, icon: const Icon(Icons.comment_outlined, size: 18), label: const Text("Comment")),
                TextButton.icon(onPressed: () {}, icon: const Icon(Icons.handshake_outlined, size: 18), label: const Text("Apply")),
              ],
            )
          ],
        ),
      ),
    );
  }
}