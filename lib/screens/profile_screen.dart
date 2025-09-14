import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart' show SharedPreferences;
import 'package:task_tracker/models/priority_box.dart';
import 'package:task_tracker/models/user.dart';
import 'package:task_tracker/screens/edit_profile_screen.dart';
import 'package:task_tracker/utils/color_utils.dart';

class ProfileScreen extends StatefulWidget {
  final List<PriorityBox> priorityBoxes;
  const ProfileScreen({super.key, required this.priorityBoxes});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late User _user;

  @override
  void initState() {
    super.initState();
    _user = User(
      id: '1',
      name: 'Lavish Kumar',
      email: 'lavish.kumar@tasktracker.com',
      profileImagePath: 'https://i.pravatar.cc/150?img=3',
      phoneNumber: '+1 234 567 890',
    );
    _loadUserFromLocal();
  }

  Future<void> _loadUserFromLocal() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _user = User(
        id: '1',
        name: prefs.getString('user_name') ?? _user.name,
        email: prefs.getString('user_email') ?? _user.email,
        phoneNumber: prefs.getString('user_phone') ?? _user.phoneNumber,
        profileImagePath: prefs.getString('user_avatar') ??
            _user.profileImagePath,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.blue.shade900,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue.shade700, Colors.blueAccent],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: Center(
        child: Container(
          margin: const EdgeInsets.all(24),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue.shade50, Colors.blue.shade200],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(32),
            boxShadow: [
              BoxShadow(
                color: ColorUtils.withOpacity(Colors.blueAccent, 0.15),
                blurRadius: 24,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 48,
                backgroundImage: NetworkImage(_user.profileImagePath ?? ''),
              ),
              const SizedBox(height: 16),
              Text(
                _user.name,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade900,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _user.email,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.blueGrey,
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 32, vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  backgroundColor: Colors.blueAccent,
                  elevation: 8,
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => EditProfileScreen(user: _user)),
                  );
                },
                child: const Text('Edit Profile'),
              ),
            ],
          ),
        ),
      ),
      backgroundColor: Colors.blue.shade50,
    );
  }
}
