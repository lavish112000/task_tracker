import 'package:flutter/material.dart';
import 'package:task_tracker/utils/color_utils.dart';
import 'package:task_tracker/widgets/glass_container.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  bool _taskReminders = true;
  bool _deadlineAlerts = true;
  bool _appUpdates = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      appBar: AppBar(
        title: const Text('Notifications'),
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
              Icon(Icons.notifications, size: 64, color: Colors.blueAccent),
              const SizedBox(height: 16),
              Text(
                'Notifications',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade900,
                ),
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text('Task Reminders'),
                subtitle: const Text('Get notified for upcoming tasks'),
                value: _taskReminders,
                onChanged: (value) => setState(() => _taskReminders = value),
                activeColor: Colors.blueAccent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              SwitchListTile(
                title: const Text('Deadline Alerts'),
                subtitle: const Text('Get notified when a deadline is near'),
                value: _deadlineAlerts,
                onChanged: (value) => setState(() => _deadlineAlerts = value),
                activeColor: Colors.blueAccent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              const Divider(height: 40),
              SwitchListTile(
                title: const Text('App Updates'),
                subtitle: const Text('Get notified about new features and updates'),
                value: _appUpdates,
                onChanged: (value) => setState(() => _appUpdates = value),
                activeColor: Colors.blueAccent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ],
          ),
        ),
      ),
      backgroundColor: Colors.blue.shade50,
    );
  }
}
