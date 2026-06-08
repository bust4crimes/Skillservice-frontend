import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:skillservice_frontend/core/app_theme.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:skillservice_frontend/providers/auth_provider.dart';
import 'package:skillservice_frontend/views/auth/register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _email = TextEditingController();
  final _pass = TextEditingController();
  bool _obscure = true;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<SkillAuthProvider>();
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            children: [
              const SizedBox(height: 60),
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(28),
                ),
                child: Center(
                  child: SvgPicture.asset('assets/icons/handshake.svg', width: 56, height: 56, color: AppTheme.primary),
                ),
              ),
              const SizedBox(height: 24),
              Text("SkillService", style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 32, color: AppTheme.primary)),
              const SizedBox(height: 8),
              Text("Connect. Learn. Grow together.", style: GoogleFonts.inter(color: AppTheme.textSecondary, fontSize: 15)),
              const SizedBox(height: 48),
              TextField(
                controller: _email,
                decoration: const InputDecoration(
                  hintText: "Email",
                  prefixIcon: Icon(Icons.email_outlined),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _pass,
                obscureText: _obscure,
                decoration: InputDecoration(
                  hintText: "Password",
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(_obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () async {
                    final emailController = TextEditingController(text: _email.text);
                    await showDialog(context: context, builder: (dialogContext) {
                      return AlertDialog(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        title: const Text('Reset Password'),
                        content: TextField(controller: emailController, decoration: const InputDecoration(hintText: 'Enter your email')),
                        actions: [
                          TextButton(onPressed: () { Navigator.of(dialogContext).pop(); }, child: const Text('Cancel')),
                          TextButton(onPressed: () async {
                            final e = emailController.text.trim();
                            if (e.isEmpty) return;
                            final scaffold = ScaffoldMessenger.of(context);
                            final dialogNav = Navigator.of(dialogContext);
                            try {
                              final authProvider = Provider.of<SkillAuthProvider>(context, listen: false);
                              await authProvider.sendPasswordReset(e);
                              dialogNav.pop();
                              scaffold.showSnackBar(const SnackBar(content: Text('Password reset email sent')));
                            } catch (err) {
                              scaffold.showSnackBar(SnackBar(content: Text('Reset failed: $err')));
                            }
                          }, child: const Text('Send')),
                        ],
                      );
                    });
                  },
                  child: Text('Forgot Password?', style: GoogleFonts.inter(color: AppTheme.primary, fontWeight: FontWeight.w500)),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity, height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: () async {
                    try {
                      final authProvider = Provider.of<SkillAuthProvider>(context, listen: false);
                      await authProvider.login(_email.text, _pass.text);
                    } catch (e) {
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: ${e.toString()}")));
                    }
                  },
                  child: auth.isLoading
                      ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                      : Text("Log In", style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 16, color: Colors.white)),
                ),
              ),
              const SizedBox(height: 32),
              Row(
                children: [
                  const Expanded(child: Divider()),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text("or", style: GoogleFonts.inter(color: AppTheme.textSecondary, fontSize: 14)),
                  ),
                  const Expanded(child: Divider()),
                ],
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity, height: 52,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.primary,
                    side: BorderSide(color: AppTheme.primary.withValues(alpha: 0.3)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterScreen())),
                  child: Text("Create New Account", style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 16)),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
