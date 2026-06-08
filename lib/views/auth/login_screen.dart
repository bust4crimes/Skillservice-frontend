import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:skillservice_frontend/core/app_theme.dart';
import 'package:flutter_svg/flutter_svg.dart';
// auth login uses built-in icons where possible
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
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(30),
          child: Column(
            children: [
              SvgPicture.asset('assets/icons/handshake.svg', width: 80, height: 80, color: AppTheme.fbBlue),
              const Text("SkillService", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppTheme.fbBlue)),
              const SizedBox(height: 40),
              TextField(controller: _email, decoration: const InputDecoration(hintText: "Email", prefixIcon: Icon(Icons.email))),
              const SizedBox(height: 12),
              TextField(
                controller: _pass,
                obscureText: _obscure,
                decoration: InputDecoration(
                  hintText: "Password",
                  prefixIcon: const Icon(Icons.lock),
                  suffixIcon: IconButton(
                    icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity, height: 55,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.fbBlue),
                   onPressed: () async {
                   try {
                     final authProvider = Provider.of<SkillAuthProvider>(context, listen: false);
                     await authProvider.login(_email.text, _pass.text);
                   } catch (e) {
                     if (!context.mounted) return;
                     final scaffold = ScaffoldMessenger.of(context);
                     scaffold.showSnackBar(SnackBar(content: Text("Error: ${e.toString()}")));
                   }
                   },
                  child: auth.isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text("Log In", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
                      // close dialog and show snackbar using captured scaffold
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
                  child: const Text('Forgot Password?'),
                ),
              ),
              const Divider(height: 40),
              OutlinedButton(
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterScreen())),
                child: const Text("Create New Account"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
