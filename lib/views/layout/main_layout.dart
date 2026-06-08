// lib/views/layout/main_layout.dart
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:skillservice_frontend/core/app_theme.dart';

import 'package:skillservice_frontend/views/feed/feed_screen.dart';
import 'package:skillservice_frontend/views/messages/chat_list.dart';
import 'package:skillservice_frontend/views/notifications/notifications_screen.dart';
// layout uses built-in icons where possible
import 'package:skillservice_frontend/views/profile/profile_screen.dart';
import 'package:skillservice_frontend/views/settings/settings_screen.dart';

class MainLayout extends StatefulWidget {
  const MainLayout({Key? key}) : super(key: key);
  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  bool _searchExpanded = false;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 5,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 1,
          title: _searchExpanded
            ? TextField(
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: "Search skills...",
                  border: InputBorder.none,
                  filled: false,
                  contentPadding: EdgeInsets.zero,
                ),
                onSubmitted: (val) => setState(() => _searchExpanded = false),
              )
            : const Text("Skillservice", style: TextStyle(color: AppTheme.fbBlue, fontWeight: FontWeight.bold)),
          actions: [
            IconButton(
              icon: Icon(_searchExpanded ? CupertinoIcons.xmark : CupertinoIcons.search),
              onPressed: () => setState(() => _searchExpanded = !_searchExpanded),
            ),
          ],
          bottom: TabBar(
            labelColor: AppTheme.fbBlue,
            unselectedLabelColor: Colors.grey,
            indicatorColor: AppTheme.fbBlue,
            tabs: [
              Tab(icon: const Icon(CupertinoIcons.house_alt)),
              Tab(icon: const Icon(CupertinoIcons.chat_bubble_2_fill)),
              Tab(icon: const Icon(CupertinoIcons.bell_fill)),
              Tab(icon: const Icon(CupertinoIcons.person_circle_fill)),
              Tab(icon: const Icon(CupertinoIcons.line_horizontal_3)),
            ],
          ),
        ),
         body: TabBarView(
           children: [
             const FeedScreen(),
             const ChatListScreen(),
             const NotificationsScreen(),
             const ProfileScreen(),
             const SettingsScreen(),
           ],
         ),
      ),
    );
  }
}
