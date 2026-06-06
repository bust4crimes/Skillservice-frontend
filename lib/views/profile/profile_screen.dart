// lib/views/profile/profile_screen.dart
import 'package:flutter/material.dart';

class ProfileScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Profile"), actions: [
        IconButton(icon: const Icon(Icons.settings), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => SettingsScreen())))
      ]),
      body: ListView(
        children: [
          const SizedBox(height: 20),
          const CircleAvatar(radius: 50, child: Icon(Icons.person, size: 50)),
          const Center(child: Text("John Doe", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold))),
          _buildDashboard(),
          const Divider(),
          _profileMenu(context),
        ],
      ),
    );
  }

  Widget _buildDashboard() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _stat("1.2k", "Followers"),
          _stat("450", "Following"),
        ],
      ),
    );
  }

  Widget _stat(String c, String l) => Column(children: [Text(c, style: const TextStyle(fontWeight: FontWeight.bold)), Text(l)]);

  Widget _profileMenu(BuildContext context) {
    return Column(
      children: [
        ListTile(leading: const Icon(Icons.edit), title: const Text("Edit Profile"), onTap: () {}),
        ListTile(leading: const Icon(Icons.archive), title: const Text("Archive"), onTap: () {}),
        ListTile(leading: const Icon(Icons.link), title: const Text("Profile Link"), onTap: () {}),
      ],
    );
  }
}