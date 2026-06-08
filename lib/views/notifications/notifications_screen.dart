// lib/views/notifications/notifications_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:skillservice_frontend/core/api_service.dart';
import 'package:skillservice_frontend/core/app_theme.dart';
import 'package:google_fonts/google_fonts.dart';

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
        : _notifications.isEmpty
            ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.notifications_off_outlined, size: 64, color: AppTheme.textSecondary.withValues(alpha: 0.4)),
                    const SizedBox(height: 16),
                    Text("No notifications yet", style: GoogleFonts.inter(color: AppTheme.textSecondary, fontSize: 16)),
                  ],
                ),
              )
            : RefreshIndicator(
                onRefresh: _fetchNotifications,
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: _notifications.length,
                  itemBuilder: (context, i) {
                    final notif = _notifications[i] as Map<String, dynamic>;
                    final type = (notif['type'] ?? '').toString();
                    final isBooking = type.toLowerCase() == 'booking';
                    final notifId = (notif['id'] ?? '').toString();

                    return Dismissible(
                      key: Key(notifId),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        decoration: BoxDecoration(
                          color: Colors.red.shade400,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(Icons.delete_outline, color: Colors.white),
                      ),
                      onDismissed: (_) async {
                        try {
                          await ApiService().client.delete('/notifications/$notifId');
                        } catch (_) {}
                        setState(() => _notifications.removeAt(i));
                      },
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppTheme.border),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                          leading: CircleAvatar(
                            backgroundColor: isBooking
                              ? AppTheme.primary.withValues(alpha: 0.15)
                              : Colors.green.withValues(alpha: 0.15),
                            child: Icon(
                              isBooking ? Icons.work_outline : Icons.person_add_outlined,
                              color: isBooking ? AppTheme.primary : Colors.green,
                            ),
                          ),
                          title: Text(
                            (notif['sender_name'] ?? 'SkillService').toString(),
                            style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14, color: AppTheme.textPrimary),
                          ),
                          subtitle: Text(
                            (notif['message'] ?? '').toString(),
                            style: GoogleFonts.inter(color: AppTheme.textSecondary, fontSize: 12),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: isBooking ? _buildActionButtons() : null,
                          onTap: () {},
                        ),
                      ),
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
        Container(
          decoration: BoxDecoration(color: AppTheme.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
          child: IconButton(icon: const Icon(Icons.check_circle, color: AppTheme.primary), iconSize: 22, onPressed: () {}),
        ),
        const SizedBox(width: 4),
        Container(
          decoration: BoxDecoration(color: Colors.red.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
          child: IconButton(icon: const Icon(Icons.cancel, color: Colors.red), iconSize: 22, onPressed: () {}),
        ),
      ],
    );
  }
}
