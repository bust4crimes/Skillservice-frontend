import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dio/dio.dart';
import 'package:skillservice_frontend/core/app_theme.dart';
import 'dart:async';
import 'package:skillservice_frontend/providers/auth_provider.dart';
import 'package:skillservice_frontend/core/api_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _fName = TextEditingController();
  final _lName = TextEditingController();
  final _email = TextEditingController();
  final _pass = TextEditingController();
  final _bDay = TextEditingController();
  final _loc = TextEditingController();
  String _gender = "Male";

  List<String> _addressSuggestions = [];
  bool _addressLoading = false;
  Timer? _addressDebounce;

  void _onAddressChanged(String value) {
    _addressDebounce?.cancel();
    if (value.trim().isEmpty) {
      setState(() => _addressSuggestions = []);
      return;
    }
    _addressDebounce = Timer(const Duration(milliseconds: 300), () => _fetchAddressSuggestions(value.trim()));
  }

  Future<void> _fetchAddressSuggestions(String query) async {
    setState(() => _addressLoading = true);
    try {
      final url = 'https://nominatim.openstreetmap.org/search?q=${Uri.encodeComponent(query)}&format=json&limit=5&addressdetails=1';
      final response = await ApiService().dio.get(url, options: Options(headers: {'User-Agent': 'SkillServiceApp/1.0'}));
      final results = (response.data as List?) ?? [];
      setState(() {
        _addressSuggestions = results.map<String>((r) => (r['display_name'] ?? '').toString()).toList();
      });
    } catch (e) {
      debugPrint('Address autocomplete error: $e');
      setState(() => _addressSuggestions = []);
    } finally {
      setState(() => _addressLoading = false);
    }
  }

  @override
  void dispose() {
    _addressDebounce?.cancel();
    _fName.dispose();
    _lName.dispose();
    _email.dispose();
    _pass.dispose();
    _bDay.dispose();
    _loc.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    DateTime? picked = await showDatePicker(
      context: context, initialDate: DateTime(2000),
      firstDate: DateTime(1950), lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _bDay.text = "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}");
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<SkillAuthProvider>();
    return Scaffold(
      appBar: AppBar(title: const Text("Create Account")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            TextField(controller: _fName, decoration: const InputDecoration(hintText: "First Name", prefixIcon: Icon(Icons.person))),
            const SizedBox(height: 12),
            TextField(controller: _lName, decoration: const InputDecoration(hintText: "Last Name", prefixIcon: Icon(Icons.person))),
            const SizedBox(height: 12),
            TextField(controller: _email, decoration: const InputDecoration(hintText: "Email", prefixIcon: Icon(Icons.email))),
            const SizedBox(height: 12),
            TextField(controller: _pass, obscureText: true, decoration: const InputDecoration(hintText: "Password", prefixIcon: Icon(Icons.lock))),
            const SizedBox(height: 12),
            TextField(controller: _bDay, readOnly: true, onTap: _pickDate, decoration: const InputDecoration(hintText: "Birthday (Click here)", prefixIcon: Icon(Icons.cake))),
            const SizedBox(height: 12),
            TextField(
              controller: _loc,
              onChanged: _onAddressChanged,
              decoration: InputDecoration(
                hintText: "Address",
                prefixIcon: const Icon(Icons.location_on),
                suffixIcon: _addressLoading
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 1.5))
                  : null,
              ),
            ),
            if (_addressSuggestions.isNotEmpty)
              Container(
                constraints: const BoxConstraints(maxHeight: 160),
                margin: const EdgeInsets.only(top: 4),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ListView.builder(
                  shrinkWrap: true,
                  padding: EdgeInsets.zero,
                  itemCount: _addressSuggestions.length,
                  itemBuilder: (context, i) => ListTile(
                    dense: true,
                    title: Text(_addressSuggestions[i], style: const TextStyle(fontSize: 14)),
                    onTap: () {
                      _loc.text = _addressSuggestions[i];
                      _loc.selection = TextSelection.fromPosition(TextPosition(offset: _loc.text.length));
                      setState(() => _addressSuggestions = []);
                    },
                  ),
                ),
              ),
            const SizedBox(height: 20),
            Row(children: [
              const Icon(Icons.transgender, color: AppTheme.textGrey),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: _gender,
                  items: const [
                    DropdownMenuItem(value: 'Male', child: Text('Male')),
                    DropdownMenuItem(value: 'Female', child: Text('Female')),
                    DropdownMenuItem(value: 'Other', child: Text('Other')),
                  ],
                  onChanged: (v) => setState(() => _gender = v ?? _gender),
                  decoration: const InputDecoration(border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10)),
                ),
              )
            ]),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity, height: 55,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.fbBlue),
                onPressed: () async {
                  if (_fName.text.trim().isEmpty || _lName.text.trim().isEmpty || _email.text.trim().isEmpty || _pass.text.trim().isEmpty || _bDay.text.trim().isEmpty || _loc.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please fill in all fields")));
                    return;
                  }
                  try {
                    final authProvider = Provider.of<SkillAuthProvider>(context, listen: false);
                    await authProvider.signUp(
                      email: _email.text, password: _pass.text,
                      profile: {"first_name": _fName.text, "last_name": _lName.text, "birthday": _bDay.text, "location": _loc.text, "gender": _gender}
                    );
                    if (!context.mounted) return;
                    Navigator.pop(context);
                  } catch (e) {
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
                  }
                },
                child: auth.isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text("Sign Up", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
