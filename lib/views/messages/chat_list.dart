import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:skillservice_frontend/views/messages/chat_detail_screen.dart';
import 'package:skillservice_frontend/views/messages/blocked_users_screen.dart';

class ChatListScreen extends StatelessWidget {
  const ChatListScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Messages"), actions: [IconButton(icon: const Icon(CupertinoIcons.clear_circled), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BlockedUsersScreen())))], ),
      body: ListView.separated(
        itemCount: 5,
        separatorBuilder: (context, i) => const Divider(height: 1),
        itemBuilder: (context, i) => ListTile(
          leading: const CircleAvatar(child: Icon(CupertinoIcons.person)),
          title: Text("User $i"),
          subtitle: const Text("Interested in your post!"),
          trailing: const Text("5m ago"),
          onTap: () {
            final id = 'user_$i';
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => ChatDetailScreen(chatPartnerId: id, chatPartnerName: "User $i")),
            );
          },
        ),
      ),
    );
  }
}
