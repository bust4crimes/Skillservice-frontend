import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart'; 
import 'package:skillservice_frontend/core/app_theme.dart';
import 'package:skillservice_frontend/views/feed/feed_screen.dart';
import 'package:skillservice_frontend/providers/auth_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
      ],
      child: const SkillServiceApp(),
    ),
  );
}

class SkillServiceApp extends StatelessWidget {
  const SkillServiceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'SkillService',
      theme: AppTheme.lightTheme,
      home: FeedScreen(),
    );
  }
}