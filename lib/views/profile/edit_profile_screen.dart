// lib/views/profile/edit_profile_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';
import 'package:skillservice_frontend/core/app_theme.dart';
import 'package:dio/dio.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:skillservice_frontend/core/api_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({Key? key}) : super(key: key);

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  XFile? _imageFile;
  Uint8List? _imageBytes;
  String? _currentAvatarUrl;
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _bioController = TextEditingController();
  final _addressController = TextEditingController();
  final _skillController = TextEditingController();
  double _skillRating = 3;
  List<Map<String, dynamic>> _skills = [];
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
        _currentAvatarUrl = data['profile_picture'] as String?;
        final existing = data['skills'] as List? ?? [];
        _skills = existing.map((s) => Map<String, dynamic>.from(s as Map)).toList();
      }
    } catch (_) {}
    setState(() => _loadingProfile = false);
  }

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes();
      setState(() {
        _imageFile = pickedFile;
        _imageBytes = bytes;
      });
    }
  }

  void _addSkill() {
    final name = _skillController.text.trim();
    if (name.isEmpty) return;
    setState(() {
      _skills.add({'name': name, 'ratings': [{'rating': _skillRating.round()}]});
      _skillController.clear();
      _skillRating = 3;
    });
  }

  void _removeSkill(int index) {
    setState(() => _skills.removeAt(index));
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _bioController.dispose();
    _addressController.dispose();
    _skillController.dispose();
    super.dispose();
  }

  ImageProvider<Object>? _getForegroundImage() {
    if (_imageBytes != null) return MemoryImage(_imageBytes!);
    if (_currentAvatarUrl != null && _currentAvatarUrl!.isNotEmpty) return NetworkImage(_currentAvatarUrl!);
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Edit Profile", style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
        actions: [
          TextButton(
            onPressed: _saving ? null : _saveProfile,
            child: _saving
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
              : Text("Save", style: GoogleFonts.inter(color: AppTheme.primary, fontWeight: FontWeight.w600, fontSize: 16)),
          )
        ],
      ),
      body: _loadingProfile
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                GestureDetector(
                  onTap: _pickImage,
                  child: Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      CircleAvatar(
                        radius: 55,
                        backgroundColor: Colors.grey[200],
                        foregroundImage: _getForegroundImage(),
                        child: _imageBytes == null && (_currentAvatarUrl == null || _currentAvatarUrl!.isEmpty)
                            ? const Icon(Icons.person_outline, size: 50, color: Colors.white)
                            : null,
                      ),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: AppTheme.primary, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2)),
                        child: const Icon(Icons.edit, color: Colors.white, size: 16),
                      )
                    ],
                  ),
                ),
                const SizedBox(height: 30),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.border),
                  ),
                  child: Column(
                    children: [
                      TextField(controller: _firstNameController, decoration: const InputDecoration(hintText: "First Name")),
                      const SizedBox(height: 16),
                      TextField(controller: _lastNameController, decoration: const InputDecoration(hintText: "Last Name")),
                      const SizedBox(height: 16),
                      TextField(controller: _bioController, maxLines: 3, decoration: const InputDecoration(hintText: "Bio")),
                      const SizedBox(height: 16),
                      TextField(controller: _addressController, decoration: const InputDecoration(hintText: "Address")),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Skills", style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 16, color: AppTheme.textPrimary)),
                      const SizedBox(height: 12),
                      if (_skills.isNotEmpty)
                        ..._skills.asMap().entries.map((e) => Container(
                          margin: const EdgeInsets.only(bottom: 6),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppTheme.surface,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(e.value['name'] ?? '', style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14, color: AppTheme.textPrimary)),
                                    const SizedBox(height: 2),
                                    Row(children: [
                                      ...List.generate(5, (i) {
                                        final ratingList = (e.value['ratings'] as List?) ?? [];
                                        final avg = ratingList.isEmpty ? 0.0 : ratingList.map((r) => (r['rating'] as num?)?.toDouble() ?? 0.0).reduce((a, b) => a + b) / ratingList.length;
                                        return Icon(i < avg.round() ? CupertinoIcons.star_fill : CupertinoIcons.star, size: 14, color: i < avg.round() ? Colors.amber : AppTheme.border);
                                      }),
                                    ]),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(CupertinoIcons.trash, size: 16, color: AppTheme.danger),
                                onPressed: () => _removeSkill(e.key),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              ),
                            ],
                          ),
                        )),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _skillController,
                              decoration: const InputDecoration(hintText: "Skill name", contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10)),
                              onSubmitted: (_) => _addSkill(),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Column(
                            children: [
                              Text('${_skillRating.round()}', style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13, color: AppTheme.textPrimary)),
                              SizedBox(
                                width: 80,
                                child: Slider(
                                  value: _skillRating,
                                  min: 1, max: 5, divisions: 4,
                                  activeColor: AppTheme.primary,
                                  onChanged: (v) => setState(() => _skillRating = v),
                                ),
                              ),
                            ],
                          ),
                          Container(
                            decoration: BoxDecoration(
                              color: AppTheme.primary,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: IconButton(
                              icon: const Icon(CupertinoIcons.plus, color: Colors.white, size: 18),
                              onPressed: _addSkill,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),
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
          'skills': _skills,
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
            'skills': _skills,
          });
        } else {
          rethrow;
        }
      }

      if (_imageBytes != null) {
        final cloudUrl = 'https://api.cloudinary.com/v1_1/${AppTheme.cloudinaryCloudName}/image/upload';
        final formData = FormData.fromMap({
          'file': MultipartFile.fromBytes(_imageBytes!, filename: 'avatar_${user.uid}'),
          'upload_preset': AppTheme.cloudinaryUploadPreset,
        });
        final cloudRes = await Dio().post(cloudUrl, data: formData);
        if (cloudRes.statusCode != 200) throw Exception('Image upload failed (${cloudRes.statusCode})');
        final cloudData = cloudRes.data as Map<String, dynamic>;
        final imageUrl = (cloudData['secure_url'] ?? cloudData['url']) as String?;
        if (imageUrl == null || imageUrl.isEmpty) throw Exception('Cloudinary did not return an image URL');
        await ApiService().client.post('/settings/update-avatar/${user.uid}', data: {
          'avatar_url': imageUrl,
        });
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile updated')));
      Navigator.pop(context, {'skills': _skills});
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to update profile: $e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}
