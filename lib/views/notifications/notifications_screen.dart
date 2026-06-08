// lib/views/notifications/notifications_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:skillservice_frontend/core/api_service.dart';
import 'package:skillservice_frontend/core/app_theme.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({Key? key}) : super(key: key);

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<dynamic> _notifications = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchNotifications();
  }

  Future<void> _fetchNotifications() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        if (mounted) setState(() => _loading = false);
        return;
      }
      final res = await ApiService().client.get('/notifications/user/${user.uid}');
      if (!mounted) return;
      setState(() {
        _notifications = res.data is List ? res.data : [];
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _loading
        ? const Center(child: CircularProgressIndicator())
        : RefreshIndicator(
          onRefresh: _fetchNotifications,
          child: ListView.separated(
        itemCount: _notifications.length,
        separatorBuilder: (_, __) => const Divider(height: 1, indent: 70),
        itemBuilder: (context, i) {
          final notif = _notifications[i] as Map<String, dynamic>;
          final type = (notif['type'] ?? '').toString();
          final isBooking = type.toLowerCase() == 'booking';
          
          return ListTile(
            leading: CircleAvatar(
              backgroundColor: isBooking ? AppTheme.fbBlue : Colors.green,
              child: Icon(isBooking ? Icons.work : Icons.person_add, color: Colors.white),
            ),
            title: Text((notif['sender_name'] ?? 'SkillService').toString(), style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text((notif['message'] ?? '').toString(), style: const TextStyle(color: AppTheme.textGrey, fontSize: 12)),
            trailing: isBooking ? _buildActionButtons() : null,
            onTap: () {}, 
          );
        },
      ),
        ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(icon: const Icon(Icons.check_circle, color: AppTheme.fbBlue), onPressed: () {}),
        IconButton(icon: const Icon(Icons.cancel, color: Colors.red), onPressed: () {}),
      ],
    );
  }
}
