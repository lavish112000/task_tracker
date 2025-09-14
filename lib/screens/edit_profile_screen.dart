import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:task_tracker/models/user.dart';
import 'package:task_tracker/utils/app_colors.dart';

class EditProfileScreen extends StatefulWidget {
  final User user;

  const EditProfileScreen({super.key, required this.user});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  String? _avatarPath;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.user.name);
    _emailController = TextEditingController(text: widget.user.email);
    _phoneController = TextEditingController(text: widget.user.phoneNumber ?? '');
    _avatarPath = widget.user.profileImagePath;
    _loadLocalData();
  }

  Future<void> _loadLocalData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _nameController.text = prefs.getString('user_name') ?? widget.user.name;
      _emailController.text = prefs.getString('user_email') ?? widget.user.email;
      _phoneController.text = prefs.getString('user_phone') ?? widget.user.phoneNumber ?? '';
      _avatarPath = prefs.getString('user_avatar') ?? widget.user.profileImagePath;
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _avatarPath = pickedFile.path;
      });
    }
  }

  Future<void> _saveProfile() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_name', _nameController.text);
    await prefs.setString('user_email', _emailController.text);
    await prefs.setString('user_phone', _phoneController.text);
    if (_avatarPath != null) {
      await prefs.setString('user_avatar', _avatarPath!);
    }

    final updatedUser = User(
      id: widget.user.id, // Add missing required id parameter
      name: _nameController.text,
      email: _emailController.text,
      phoneNumber: _phoneController.text,
      profileImagePath: _avatarPath ?? widget.user.profileImagePath,
    );

    if (mounted) {
      Navigator.pop(context, updatedUser);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        backgroundColor: AppColors.backgroundColor,
        elevation: 0,
        foregroundColor: AppColors.textPrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            _buildProfileAvatar(),
            const SizedBox(height: 30),
            _buildTextField(label: 'Full Name', controller: _nameController),
            const SizedBox(height: 20),
            _buildTextField(label: 'Email Address', controller: _emailController),
            const SizedBox(height: 20),
            _buildTextField(label: 'Phone Number', controller: _phoneController),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: _saveProfile,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryColor,
                padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Save Changes', style: TextStyle(fontSize: 16, color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileAvatar() {
    return Stack(
      children: [
        CircleAvatar(
          radius: 60,
          backgroundImage: _avatarPath != null && _avatarPath!.isNotEmpty && !_avatarPath!.startsWith('http')
              ? FileImage(File(_avatarPath!)) as ImageProvider
              : NetworkImage(widget.user.profileImagePath ?? 'https://i.pravatar.cc/150?img=3'),
        ),
        Positioned(
          bottom: 0,
          right: 0,
          child: CircleAvatar(
            radius: 20,
            backgroundColor: AppColors.primaryColor,
            child: IconButton(
              icon: const Icon(Icons.edit, color: Colors.white, size: 20),
              onPressed: _pickImage,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({required String label, required TextEditingController controller}) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      ),
    );
  }
}
