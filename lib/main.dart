import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:skillservice_frontend/firebase_options.dart';
import 'package:skillservice_frontend/core/app_theme.dart';
import 'package:flutter_svg/flutter_svg.dart';
// main uses only built-in icons where possible
import 'package:skillservice_frontend/providers/auth_provider.dart';
import 'package:skillservice_frontend/providers/theme_provider.dart';
import 'package:skillservice_frontend/views/auth/login_screen.dart';
import 'package:skillservice_frontend/views/auth/verification_screen.dart';
import 'package:skillservice_frontend/views/feed/feed_screen.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:skillservice_frontend/views/layout/main_layout.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await Hive.initFlutter();
  await Hive.openBox('chat_messages');
  runApp(MultiProvider(providers: [
    ChangeNotifierProvider(create: (_) => ThemeProvider()),
    ChangeNotifierProvider(create: (_) => SkillAuthProvider()),
  ], child: const SkillServiceApp()));
}

class SkillServiceApp extends StatelessWidget {
  const SkillServiceApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: context.watch<ThemeProvider>().isDark ? ThemeMode.dark : ThemeMode.light,
      home: Consumer<SkillAuthProvider>(
        builder: (context, auth, _) {
          if (auth.user == null) return const LoginScreen();
          if (!auth.user!.emailVerified) return const VerificationScreen();
          return const MainLayout();
        },
      ),
    );
  }
}

class MainNavHub extends StatefulWidget {
  const MainNavHub({super.key});
  @override
  State<MainNavHub> createState() => _MainNavHubState();
}

class _MainNavHubState extends State<MainNavHub> {
  int _idx = 0;
  final List<Widget> _tabs = [const FeedScreen(), const Center(child: Text("Messages")), const Center(child: Text("Portfolio"))];
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _idx, children: _tabs),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _idx, onTap: (v) => setState(() => _idx = v),
        items: [
          BottomNavigationBarItem(icon: SvgPicture.asset('assets/icons/home.svg', width: 24, height: 24, color: Colors.black), label: "Feed"),
          BottomNavigationBarItem(icon: SvgPicture.asset('assets/icons/mail.svg', width: 24, height: 24, color: Colors.black), label: "Messages"),
          BottomNavigationBarItem(icon: SvgPicture.asset('assets/icons/user.svg', width: 24, height: 24, color: Colors.black), label: "Portfolio"),
        ],
      ),
    );
  }
}
