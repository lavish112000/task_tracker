import 'package:flutter/material.dart';
import 'package:task_tracker/utils/app_colors.dart';

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Help & Support'),
        backgroundColor: AppColors.backgroundColor,
        elevation: 0,
        foregroundColor: AppColors.textPrimary,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildListItem(
            context,
            icon: Icons.quiz_outlined,
            title: 'FAQ',
            subtitle: 'Find answers to common questions',
            onTap: () => _showComingSoonSnackBar(context),
          ),
          _buildListItem(
            context,
            icon: Icons.mail_outline,
            title: 'Contact Us',
            subtitle: 'Get in touch with our support team',
            onTap: () => _showComingSoonSnackBar(context),
          ),
          _buildListItem(
            context,
            icon: Icons.bug_report_outlined,
            title: 'Report a Bug',
            subtitle: 'Let us know about a technical issue',
            onTap: () => _showComingSoonSnackBar(context),
          ),
          _buildListItem(
            context,
            icon: Icons.info_outline,
            title: 'About App',
            subtitle: 'View app version and details',
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
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: AppColors.primaryColor.withAlpha((255 * 0.1).round()),
        child: Icon(icon, color: AppColors.primaryColor),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
      subtitle: Text(subtitle, style: const TextStyle(color: AppColors.textSecondary)),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: AppColors.textSecondary),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    );
  }
}
