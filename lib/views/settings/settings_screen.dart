import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:skillservice_frontend/providers/theme_provider.dart';
import 'package:skillservice_frontend/core/api_service.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:skillservice_frontend/core/app_theme.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();
    final user = FirebaseAuth.instance.currentUser;
    return Scaffold(
      appBar: AppBar(title: Text("Settings", style: GoogleFonts.inter(fontWeight: FontWeight.w600))),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: [
          _section("Account Settings"),
          const SizedBox(height: 4),
          _card(context, [
            _tile(Icons.email_outlined, "Change Gmail", () => _changeEmail(context, user)),
            _divider(),
            _tile(Icons.lock_outline, "Change Password", () => _changePassword(context, user)),
            _divider(),
            _tile(Icons.person_outline, "Change Name", () => _changeName(context, user)),
          ]),
          const SizedBox(height: 20),
          _section("Personalization"),
          const SizedBox(height: 4),
          _card(context, [
            _tile(Icons.format_size, "Font Size", () => _fontSize(context, user)),
            _divider(),
            _tile(Icons.font_download_outlined, "Font Style", () => _fontStyle(context, user)),
            _divider(),
            _switchTile(context, Icons.dark_mode_outlined, "Dark Mode", theme.isDark, (_) => theme.toggle()),
          ]),
          const SizedBox(height: 20),
          _section("Privacy"),
          const SizedBox(height: 4),
          _card(context, [
            _tile(Icons.block_outlined, "Blocked Users", () => Navigator.push(context, MaterialPageRoute(builder: (_) => const _BlockedRoute()))),
            _divider(),
            _switchTile(context, Icons.online_prediction, "Active Status", true, (v) => _toggleStatus(context, user, v)),
          ]),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _section(String t) => Padding(
    padding: const EdgeInsets.only(left: 4, bottom: 4),
    child: Text(t, style: GoogleFonts.inter(color: AppTheme.primary, fontWeight: FontWeight.w700, fontSize: 13, letterSpacing: 0.5)),
  );

  Widget _card(BuildContext context, List<Widget> children) => Container(
    decoration: BoxDecoration(
      color: Theme.of(context).cardColor,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: AppTheme.border),
    ),
    child: Column(children: children),
  );

  Widget _tile(IconData icon, String title, VoidCallback onTap) => ListTile(
    leading: Icon(icon, color: AppTheme.textSecondary),
    title: Text(title, style: GoogleFonts.inter(fontSize: 15, color: AppTheme.textPrimary)),
    trailing: const Icon(Icons.chevron_right, color: AppTheme.textSecondary),
    onTap: onTap,
  );

  Widget _switchTile(BuildContext context, IconData icon, String title, bool value, ValueChanged<bool> onChanged) => SwitchListTile(
    secondary: Icon(icon, color: AppTheme.textSecondary),
    title: Text(title, style: GoogleFonts.inter(fontSize: 15, color: AppTheme.textPrimary)),
    value: value,
    activeThumbColor: AppTheme.primary,
    onChanged: onChanged,
  );

  Widget _divider() => Divider(height: 1, indent: 56, endIndent: 16, color: AppTheme.border);

  Future<void> _changeEmail(BuildContext context, User? user) async {
    if (user == null) return;
    final ctrl = TextEditingController();
    final ok = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text("Change Gmail"),
      content: TextField(controller: ctrl, decoration: const InputDecoration(hintText: "New email"), keyboardType: TextInputType.emailAddress),
      actions: [TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Cancel")), TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text("Change"))]
    ));
    if (ok != true || ctrl.text.isEmpty) return;
    try {
      await user.verifyBeforeUpdateEmail(ctrl.text.trim());
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Verification email sent to new address")));
    } catch (e) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("$e")));
    }
  }

  Future<void> _changePassword(BuildContext context, User? user) async {
    if (user?.email == null) return;
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: user!.email!);
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Password reset email sent")));
    } catch (e) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("$e")));
    }
  }

  Future<void> _changeName(BuildContext context, User? user) async {
    if (user == null) return;
    final firstC = TextEditingController();
    final lastC = TextEditingController();
    final ok = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text("Change Name"),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: firstC, decoration: const InputDecoration(hintText: "First Name")),
        const SizedBox(height: 8),
        TextField(controller: lastC, decoration: const InputDecoration(hintText: "Last Name"))
      ]),
      actions: [TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Cancel")), TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text("Save"))]
    ));
    if (ok != true) return;
    try {
      await ApiService().client.put('/settings/update-profile/${user.uid}', data: {'first_name': firstC.text.trim(), 'last_name': lastC.text.trim()});
      final fullName = "${firstC.text.trim()} ${lastC.text.trim()}".trim();
      if (fullName.isNotEmpty) await user.updateDisplayName(fullName);
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Name updated")));
    } catch (e) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("$e")));
    }
  }

  Future<void> _fontSize(BuildContext context, User? user) async {
    if (user == null) return;
    final sizes = ["small", "medium", "large"];
    final result = await showDialog<String>(context: context, builder: (ctx) => SimpleDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text("Font Size"),
      children: sizes.map((s) => SimpleDialogOption(onPressed: () => Navigator.pop(ctx, s), child: Text(s[0].toUpperCase() + s.substring(1)))).toList()
    ));
    if (result == null) return;
    try {
      await ApiService().client.put('/settings/update-profile/${user.uid}', data: {'font_size': result});
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Font size set to $result")));
    } catch (e) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("$e")));
    }
  }

  Future<void> _fontStyle(BuildContext context, User? user) async {
    if (user == null) return;
    final styles = ["default", "bold", "rounded"];
    final result = await showDialog<String>(context: context, builder: (ctx) => SimpleDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text("Font Style"),
      children: styles.map((s) => SimpleDialogOption(onPressed: () => Navigator.pop(ctx, s), child: Text(s[0].toUpperCase() + s.substring(1)))).toList()
    ));
    if (result == null) return;
    try {
      await ApiService().client.put('/settings/update-profile/${user.uid}', data: {'font_style': result});
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Font style set to $result")));
    } catch (e) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("$e")));
    }
  }

  Future<void> _toggleStatus(BuildContext context, User? user, bool active) async {
    if (user == null) return;
    try {
      await ApiService().client.put('/settings/toggle-status/${user.uid}', queryParameters: {'active': active});
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(active ? "Status set to Active" : "Status set to Inactive")));
    } catch (e) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("$e")));
    }
  }

}

class _BlockedRoute extends StatefulWidget {
  const _BlockedRoute({Key? key}) : super(key: key);
  @override
  State<_BlockedRoute> createState() => _BlockedRouteState();
}

class _BlockedRouteState extends State<_BlockedRoute> {
  List<dynamic> _blocked = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      final res = await ApiService().dio.get('/auth/profile/${user.uid}');
      final ids = (res.data['blocked_user_ids'] as List?)?.cast<String>() ?? <String>[];
      setState(() { _blocked = ids; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Blocked Users", style: GoogleFonts.inter(fontWeight: FontWeight.w600))),
      body: _loading
        ? const Center(child: CircularProgressIndicator())
        : _blocked.isEmpty
            ? Center(child: Text("No blocked users", style: GoogleFonts.inter(color: AppTheme.textSecondary)))
            : ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                itemCount: _blocked.length,
                itemBuilder: (_, i) => Container(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppTheme.border),
                  ),
                  child: ListTile(
                    leading: const Icon(Icons.person_outline, color: AppTheme.textSecondary),
                    title: Text(_blocked[i], style: GoogleFonts.inter(fontSize: 15, color: AppTheme.textPrimary)),
                    trailing: TextButton(
                      style: TextButton.styleFrom(
                        backgroundColor: AppTheme.primary.withValues(alpha: 0.1),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () async {
                        final user = FirebaseAuth.instance.currentUser;
                        if (user == null) return;
                        try {
                          await ApiService().client.put('/settings/toggle-block/${_blocked[i]}', queryParameters: {'user_id': user.uid});
                          setState(() => _blocked.removeAt(i));
                          if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("User unblocked")));
                        } catch (e) {
                          if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("$e")));
                        }
                      },
                      child: Text("Unblock", style: GoogleFonts.inter(fontWeight: FontWeight.w500)),
                    ),
                  ),
                ),
              ),
    );
  }
}
