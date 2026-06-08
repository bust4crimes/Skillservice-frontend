// lib/views/messages/blocked_users_screen.dart
import 'package:flutter/material.dart';
// minimal blocked users screen

class BlockedUsersScreen extends StatelessWidget {
  const BlockedUsersScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final blocked = <Map<String, String>>[
      {"id": "u1", "name": "Spammer"},
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Blocked Users')),
      body: ListView.separated(
        itemCount: blocked.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, i) {
          final b = blocked[i];
          return ListTile(
            leading: const CircleAvatar(child: Icon(Icons.block)),
            title: Text(b['name']!),
            trailing: TextButton(onPressed: () { final scaffold = ScaffoldMessenger.of(context); scaffold.showSnackBar(const SnackBar(content: Text('Unblocked'))); }, child: const Text('Unblock')),
          );
        },
      ),
    );
  }
}
