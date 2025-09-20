import 'package:flutter/material.dart';
import 'package:task_tracker/screens/calendar_screen.dart';
import 'package:task_tracker/screens/dashboard_screen.dart';
import 'package:task_tracker/screens/home_screen.dart';
import 'package:task_tracker/screens/mind_map_screen.dart';
import 'package:task_tracker/screens/notifications_screen.dart';
import 'package:task_tracker/screens/pomodoro_screen.dart';
import 'package:task_tracker/screens/profile_screen.dart';
import 'package:task_tracker/screens/statistics_screen.dart';
import 'package:task_tracker/screens/automation_rules_screen.dart';
import 'package:task_tracker/utils/app_colors.dart';
import 'package:task_tracker/widgets/task_details_dialog.dart';

class CustomDrawer extends StatefulWidget {
  final int selectedIndex;
  final Function(int) onItemTapped;

  const CustomDrawer({
    super.key,
    required this.selectedIndex,
    required this.onItemTapped,
  });

  @override
  State<CustomDrawer> createState() => _CustomDrawerState();
}

class _CustomDrawerState extends State<CustomDrawer> {
  bool _isExpanded = true;
  final double _collapsedWidth = 70.0;
  final double _expandedWidth = 250.0;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: _isExpanded ? _expandedWidth : _collapsedWidth,
      color: Theme.of(context).colorScheme.surface,
      child: Column(
        children: [
          // App Logo and Toggle Button
          Container(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (_isExpanded)
                  const Text(
                    'Task Tracker',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryColor,
                    ),
                  )
                else
                  const Icon(
                    Icons.check_circle_outline,
                    color: AppColors.primaryColor,
                    size: 28,
                  ),
                IconButton(
                  icon: Icon(
                    _isExpanded ? Icons.chevron_left : Icons.chevron_right,
                    color: Theme.of(context).iconTheme.color,
                  ),
                  onPressed: () {
                    setState(() {
                      _isExpanded = !_isExpanded;
                    });
                  },
                ),
              ],
            ),
          ),
          const Divider(height: 1, thickness: 1),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _buildListTile(
                  context,
                  icon: Icons.dashboard,
                  title: 'Dashboard',
                  index: 0,
                ),
                _buildListTile(
                  context,
                  icon: Icons.home,
                  title: 'Home',
                  index: 1,
                ),
                _buildListTile(
                  context,
                  icon: Icons.calendar_today,
                  title: 'Calendar',
                  index: 2,
                ),
                _buildListTile(
                  context,
                  icon: Icons.bar_chart,
                  title: 'Statistics',
                  index: 3,
                ),
                _buildListTile(
                  context,
                  icon: Icons.psychology,
                  title: 'Mind Map',
                  index: 4,
                ),
                _buildListTile(
                  context,
                  icon: Icons.timer,
                  title: 'Pomodoro',
                  index: 5,
                ),
                _buildListTile(
                  context,
                  icon: Icons.notifications,
                  title: 'Notifications',
                  index: 6,
                ),
                _buildListTile(
                  context,
                  icon: Icons.auto_awesome_motion,
                  title: 'Automation',
                  index: 7,
                ),
                _buildListTile(
                  context,
                  icon: Icons.person,
                  title: 'Profile',
                  index: 8,
                ),
              ],
            ),
          ),
          const Divider(height: 1, thickness: 1),
          // Theme Toggle and Settings
          ListTile(
            leading: const Icon(Icons.brightness_6),
            title: _isExpanded ? const Text('Dark Mode') : null,
            trailing: _isExpanded
                ? Switch(
                    value: Theme.of(context).brightness == Brightness.dark,
                    onChanged: (value) {
                      // Implement theme toggle
                    },
                    activeColor: AppColors.primaryColor,
                  )
                : null,
            onTap: () {
              // Toggle theme
            },
          ),
        ],
      ),
    );
  }

  Widget _buildListTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required int index,
  }) {
    final isSelected = widget.selectedIndex == index;
    final colorScheme = Theme.of(context).colorScheme;
    final primaryColor = colorScheme.primary;
    
    // Convert color to RGB and apply opacity
    final selectedColor = primaryColor.withOpacity(0.1);
    
    return ListTile(
      leading: Icon(
        icon,
        color: isSelected ? AppColors.primaryColor : Theme.of(context).iconTheme.color,
      ),
      title: _isExpanded
          ? Text(
              title,
              style: TextStyle(
                color: isSelected
                    ? AppColors.primaryColor
                    : Theme.of(context).textTheme.bodyLarge?.color,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            )
          : null,
      selected: isSelected,
      selectedTileColor: selectedColor,
      onTap: () => widget.onItemTapped(index),
    );
  }
}

class NavigationDestination {
  final String title;
  final IconData icon;
  final Widget screen;

  const NavigationDestination({
    required this.title,
    required this.icon,
    required this.screen,
  });
}

List<NavigationDestination> navigationDestinations = [
  NavigationDestination(
    title: 'Dashboard',
    icon: Icons.dashboard,
    screen: const DashboardScreen(),
  ),
  NavigationDestination(
    title: 'Home',
    icon: Icons.home,
    screen: Builder(
      builder: (context) => HomeScreen(
        tasks: const [],
        isLoading: false,
        onAddTask: () {},
        onTaskTap: (task) {
          showDialog(
            context: context,
            builder: (context) => TaskDetailsDialog(task: task),
          );
        },
        onTasksChanged: () {},
      ),
    ),
  ),
  NavigationDestination(
    title: 'Calendar',
    icon: Icons.calendar_today,
    screen: const CalendarScreen(),
  ),
  NavigationDestination(
    title: 'Statistics',
    icon: Icons.bar_chart,
    screen: const StatisticsScreen(priorityBoxes: []),
  ),
  NavigationDestination(
    title: 'Mind Map',
    icon: Icons.psychology,
    screen: const MindMapScreen(),
  ),
  NavigationDestination(
    title: 'Pomodoro',
    icon: Icons.timer,
    screen: const PomodoroScreen(),
  ),
  NavigationDestination(
    title: 'Notifications',
    icon: Icons.notifications,
    screen: const NotificationsScreen(),
  ),
  NavigationDestination(
    title: 'Automation',
    icon: Icons.auto_awesome_motion,
    screen: const AutomationRulesScreen(),
  ),
  NavigationDestination(
    title: 'Profile',
    icon: Icons.person,
    screen: const ProfileScreen(priorityBoxes: []),
  ),
];
