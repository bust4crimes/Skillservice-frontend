// lib/views/profile/edit_profile_screen.dart
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:skillservice_frontend/core/app_theme.dart';
import 'package:dio/dio.dart';
import 'package:skillservice_frontend/core/api_service.dart';
import 'package:path/path.dart' as p;
import 'package:firebase_auth/firebase_auth.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({Key? key}) : super(key: key);

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  File? _imageFile;
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _bioController = TextEditingController();
  final _addressController = TextEditingController();
  bool _saving = false;
  bool _loadingProfile = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;
      final response = await ApiService().dio.get('/auth/profile/${user.uid}');
      final data = response.data as Map<String, dynamic>?;
      if (data != null) {
        _firstNameController.text = data['first_name'] ?? '';
        _lastNameController.text = data['last_name'] ?? '';
        _bioController.text = data['bio'] ?? '';
        _addressController.text = data['location'] ?? '';
      }
    } catch (_) {}
    setState(() => _loadingProfile = false);
  }

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() => _imageFile = File(pickedFile.path));
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _bioController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Edit Profile"),
        actions: [
          TextButton(
            onPressed: _saving ? null : _saveProfile,
            child: _saving
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
              : const Text("Save", style: TextStyle(color: AppTheme.fbBlue, fontWeight: FontWeight.bold, fontSize: 16)),
          )
        ],
      ),
      body: _loadingProfile
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                GestureDetector(
                  onTap: _pickImage,
                  child: Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      CircleAvatar(radius: 50, backgroundColor: Colors.grey[300], foregroundImage: _imageFile != null ? FileImage(_imageFile!) : null, child: _imageFile == null ? const Icon(Icons.person_outline, size: 50, color: Colors.white) : null),
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(color: AppTheme.fbBlue, shape: BoxShape.circle),
                        child: const Icon(Icons.edit, color: Colors.white, size: 16),
                      )
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                TextField(controller: _firstNameController, decoration: const InputDecoration(hintText: "First Name", border: OutlineInputBorder())),
                const SizedBox(height: 10),
                TextField(controller: _lastNameController, decoration: const InputDecoration(hintText: "Last Name", border: OutlineInputBorder())),
                const SizedBox(height: 10),
                TextField(controller: _bioController, maxLines: 3, decoration: const InputDecoration(hintText: "Bio", border: OutlineInputBorder())),
                const SizedBox(height: 10),
                TextField(controller: _addressController, decoration: const InputDecoration(hintText: "Address", border: OutlineInputBorder())),
              ],
            ),
          ),
    );
  }

  Future<void> _saveProfile() async {
    setState(() => _saving = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('Not authenticated');

      final fullName = "${_firstNameController.text.trim()} ${_lastNameController.text.trim()}".trim();
      if (fullName.isNotEmpty) {
        await user.updateDisplayName(fullName);
        await user.reload();
      }

      try {
        await ApiService().client.put('/settings/update-profile/${user.uid}', data: {
          'first_name': _firstNameController.text.trim(),
          'last_name': _lastNameController.text.trim(),
          'bio': _bioController.text,
          'location': _addressController.text.trim(),
        });
      } on DioException catch (e) {
        if (e.response?.statusCode == 404) {
          final token = await user.getIdToken(true);
          await ApiService().client.post('/auth/register', data: {
            'id_token': token,
            'first_name': _firstNameController.text.trim(),
            'last_name': _lastNameController.text.trim(),
            'bio': _bioController.text,
            'location': _addressController.text.trim(),
          });
        } else {
          rethrow;
        }
      }

      if (_imageFile != null) {
        final filename = p.basename(_imageFile!.path);
        final form = FormData.fromMap({
          'file': await MultipartFile.fromFile(_imageFile!.path, filename: filename),
        });
        await ApiService().client.post('/settings/update-avatar/${user.uid}', data: form);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile updated')));
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to update profile: $e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}
