// lib/views/messages/chat_list.dart
class MessagesHub extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Messages"), backgroundColor: Colors.white, elevation: 0.5),
      body: ListView.separated(
        itemCount: 10, // Dynamic from backend
        separatorBuilder: (_, __) => const Divider(height: 1, indent: 70),
        itemBuilder: (context, i) => ListTile(
          leading: const CircleAvatar(backgroundColor: Color(0xFF1877F2), child: Icon(Icons.person, color: Colors.white)),
          title: const Text("John Doe"),
          subtitle: const Text("I'm interested in your Flutter skill..."),
          trailing: const Text("2m ago", style: TextStyle(fontSize: 12)),
          onTap: () {},
        ),
      ),
    );
  }
}