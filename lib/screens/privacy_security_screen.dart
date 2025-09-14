import 'package:flutter/material.dart';
import 'package:task_tracker/utils/app_colors.dart';

class PrivacySecurityScreen extends StatelessWidget {
  const PrivacySecurityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacy & Security'),
        backgroundColor: AppColors.backgroundColor,
        elevation: 0,
        foregroundColor: AppColors.textPrimary,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildListItem(
            context,
            icon: Icons.lock_outline,
            title: 'Change Password',
            onTap: () => _showComingSoonSnackBar(context),
          ),
          _buildListItem(
            context,
            icon: Icons.phonelink_lock_outlined,
            title: 'Two-Factor Authentication',
            onTap: () => _showComingSoonSnackBar(context),
          ),
          _buildListItem(
            context,
            icon: Icons.devices_other_outlined,
            title: 'Manage Devices',
            onTap: () => _showComingSoonSnackBar(context),
          ),
          const Divider(height: 40),
          _buildListItem(
            context,
            icon: Icons.description_outlined,
            title: 'Privacy Policy',
            onTap: () => _showComingSoonSnackBar(context),
          ),
          _buildListItem(
            context,
            icon: Icons.gavel_outlined,
            title: 'Terms of Service',
            onTap: () => _showComingSoonSnackBar(context),
          ),
        ],
      ),
    );
  }

  void _showComingSoonSnackBar(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Feature coming soon!'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  Widget _buildListItem(BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: AppColors.textSecondary),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: AppColors.textSecondary),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    );
  }
}
