// lib/views/auth/verification_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:skillservice_frontend/providers/auth_provider.dart';
import 'package:skillservice_frontend/views/layout/main_layout.dart';
import 'package:skillservice_frontend/core/app_theme.dart';
import 'package:google_fonts/google_fonts.dart';

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
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text("Verify Your Email", style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(28),
              ),
              child: const Icon(Icons.mark_email_unread, size: 56, color: AppTheme.primary),
            ),
            const SizedBox(height: 24),
            Text(
              "Verify Your Email",
              style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 22, color: AppTheme.textPrimary),
            ),
            const SizedBox(height: 12),
            Text(
              "We've sent a verification link to your email. Please click the link to activate your account.",
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(fontSize: 15, color: AppTheme.textSecondary, height: 1.4),
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity, height: 52,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: _isVerifying ? null : _checkVerificationStatus,
                child: _isVerifying
                    ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                    : Text("I have verified my email", style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 16, color: Colors.white)),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity, height: 52,
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.primary,
                  side: BorderSide(color: AppTheme.primary.withValues(alpha: 0.3)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: _isResending ? null : _resendVerificationEmail,
                child: _isResending
                    ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5))
                    : Text("Resend verification email", style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 16)),
              ),
            ),
            const SizedBox(height: 24),
            TextButton(
              onPressed: () {
                final auth = Provider.of<SkillAuthProvider>(context, listen: false);
                auth.logout();
              },
              child: Text("Back to Login", style: GoogleFonts.inter(color: AppTheme.textSecondary, fontWeight: FontWeight.w500)),
            ),
          ],
        ),
      ),
    );
  }
}
