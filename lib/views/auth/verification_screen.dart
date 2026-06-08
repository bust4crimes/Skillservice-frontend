// lib/views/auth/verification_screen.dart
import 'package:flutter/material.dart';
// firebase auth is accessed via provider where needed
import 'package:provider/provider.dart';
import 'package:skillservice_frontend/providers/auth_provider.dart';
import 'package:skillservice_frontend/views/layout/main_layout.dart';
import 'package:skillservice_frontend/core/app_theme.dart';

class VerificationScreen extends StatefulWidget {
  const VerificationScreen({Key? key}) : super(key: key);

  @override
  State<VerificationScreen> createState() => _VerificationScreenState();
}

class _VerificationScreenState extends State<VerificationScreen> {
  bool _isVerifying = false;
  bool _isResending = false;

  Future<void> _checkVerificationStatus() async {
    setState(() => _isVerifying = true);
    try {
      final auth = Provider.of<SkillAuthProvider>(context, listen: false);
      final ok = await auth.checkManualVerification();
      if (!mounted) return;
      if (ok) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const MainLayout()),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text("Email not verified yet. Please check your inbox.")));
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) {
        setState(() => _isVerifying = false);
      }
    }
  }

  Future<void> _resendVerificationEmail() async {
    setState(() => _isResending = true);
    try {
      final auth = Provider.of<SkillAuthProvider>(context, listen: false);
      await auth.resendVerificationEmail();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Verification email sent.")));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) {
        setState(() => _isResending = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Verify Your Email")),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.mark_email_unread,
                size: 100, color: AppTheme.fbBlue),
            const SizedBox(height: 20),
            const Text(
              "We've sent a verification link to your email. Please click the link to activate your account.",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.fbBlue,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                ),
                onPressed: _isVerifying ? null : _checkVerificationStatus,
                child: _isVerifying
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("I have verified my email",
                        style: TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: _isResending ? null : _resendVerificationEmail,
              child: _isResending
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text("Resend verification email"),
            ),
          ],
        ),
      ),
    );
  }
}
