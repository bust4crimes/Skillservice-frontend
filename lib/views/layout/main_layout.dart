// lib/views/layout/main_layout.dart
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:skillservice_frontend/core/app_theme.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:skillservice_frontend/views/feed/feed_screen.dart';
import 'package:skillservice_frontend/views/messages/chat_list.dart';
import 'package:skillservice_frontend/views/notifications/notifications_screen.dart';
import 'package:skillservice_frontend/views/search/search_screen.dart';
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
          title: _searchExpanded
            ? TextField(
                autofocus: true,
                style: GoogleFonts.inter(fontSize: 16, color: AppTheme.textPrimary),
                decoration: InputDecoration(
                  hintText: "Search skills...",
                  hintStyle: GoogleFonts.inter(color: AppTheme.textSecondary),
                  border: InputBorder.none,
                  filled: false,
                  contentPadding: EdgeInsets.zero,
                ),
                onSubmitted: (val) {
                  setState(() => _searchExpanded = false);
                  Navigator.push(context, MaterialPageRoute(builder: (_) => SearchScreen(initialQuery: val)));
                },
              )
            : Text("SkillService", style: GoogleFonts.inter(color: AppTheme.primary, fontWeight: FontWeight.w800, fontSize: 20)),
          actions: [
            Container(
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: IconButton(
                icon: Icon(_searchExpanded ? CupertinoIcons.xmark : CupertinoIcons.search, color: AppTheme.primary),
                onPressed: () => setState(() => _searchExpanded = !_searchExpanded),
              ),
            ),
          ],
          bottom: TabBar(
            labelColor: AppTheme.primary,
            unselectedLabelColor: AppTheme.textSecondary,
            indicatorColor: AppTheme.primary,
            indicatorWeight: 3,
            indicatorSize: TabBarIndicatorSize.tab,
            tabs: const [
              Tab(icon: Icon(CupertinoIcons.house_alt)),
              Tab(icon: Icon(CupertinoIcons.chat_bubble_2_fill)),
              Tab(icon: Icon(CupertinoIcons.bell_fill)),
              Tab(icon: Icon(CupertinoIcons.person_circle_fill)),
              Tab(icon: Icon(CupertinoIcons.line_horizontal_3)),
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
