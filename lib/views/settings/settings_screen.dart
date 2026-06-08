// lib/views/settings/settings_screen.dart
import 'package:flutter/material.dart';
// settings uses only built-in material icons

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Settings")),
      body: ListView(
        children: [
          _section("Account Settings"),
          _tile("Change Gmail", Icons.email),
          _tile("Change Password", Icons.lock),
          _tile("Change Name", Icons.person),
          _section("Personalization"),
          _tile("Font Size", Icons.format_size),
          _tile("Font Style", Icons.font_download),
          SwitchListTile(title: const Text("Dark Mode"), secondary: const Icon(Icons.dark_mode), value: false, onChanged: (v) {}),
          _section("Privacy"),
          ListTile(leading: const Icon(Icons.block), title: const Text('Blocked Users'), trailing: const Icon(Icons.chevron_right), onTap: () { Navigator.push(context, MaterialPageRoute(builder: (_) => const _BlockedRoute())); }),
          _tile("Active Status", Icons.online_prediction),
        ],
      ),
    );
  }

  Widget _section(String t) => Padding(padding: const EdgeInsets.all(16), child: Text(t, style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)));
  Widget _tile(String t, IconData i) => ListTile(leading: Icon(i), title: Text(t), trailing: const Icon(Icons.arrow_forward_ios));
}

class _BlockedRoute extends StatelessWidget {
  const _BlockedRoute({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) => const Scaffold(body: Center(child: Text('Blocked Users screen (open from Messages tab)')));
}
