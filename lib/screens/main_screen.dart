import 'package:flutter/material.dart';
import 'package:task_tracker/models/priority.dart';
import 'package:task_tracker/models/task.dart';
import 'package:task_tracker/models/priority_box.dart';
import 'package:task_tracker/services/task_service.dart';
import 'package:task_tracker/screens/calendar_screen.dart';
import 'package:task_tracker/screens/statistics_screen.dart';
import 'package:task_tracker/screens/profile_screen.dart';
import 'package:task_tracker/screens/home_screen.dart';
import 'package:task_tracker/screens/pomodoro_screen.dart';
import 'package:task_tracker/screens/dashboard_screen.dart';
import 'package:task_tracker/screens/mind_map_screen.dart';
import 'package:task_tracker/screens/automation_rules_screen.dart';
import 'package:task_tracker/widgets/add_task_dialog.dart';
import 'package:task_tracker/widgets/task_details_dialog.dart';
import 'package:task_tracker/widgets/custom_bottom_nav_bar.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with TickerProviderStateMixin {
  final TaskService _taskService = TaskService();
  List<Task> _tasks = [];
  List<Task> _filteredTasks = [];
  bool _isLoading = true;
  int _selectedIndex = 0;

  // Filtering and sorting
  String _searchQuery = '';
  Priority? _priorityFilter;
  bool _showCompleted = true;
  String _sortBy = 'dueDate';
  bool _sortAscending = true;

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    setState(() => _isLoading = true);
    try {
      final tasks = await _taskService.getTasks();
      _tasks = tasks;
      _applyFilters();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load tasks: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _applyFilters() {
    _filteredTasks = List<Task>.from(_tasks);

    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      _filteredTasks = _filteredTasks.where((task) =>
        task.title.toLowerCase().contains(q) ||
        task.description.toLowerCase().contains(q) ||
        task.notes?.toLowerCase().contains(q) == true
      ).toList();
    }

    if (_priorityFilter != null) {
      _filteredTasks = _filteredTasks.where((t) => t.priority == _priorityFilter).toList();
    }

    if (!_showCompleted) {
      _filteredTasks = _filteredTasks.where((t) => !t.isCompleted).toList();
    }

    _filteredTasks.sort((a, b) {
      int cmp;
      switch (_sortBy) {
        case 'title':
          cmp = a.title.compareTo(b.title);
          break;
        case 'priority':
          cmp = a.priority.index.compareTo(b.priority.index);
          break;
        case 'dueDate':
        default:
          cmp = a.dueDate.compareTo(b.dueDate);
      }
      return _sortAscending ? cmp : -cmp;
    });
    setState(() {});
  }

  void _onNavBarTap(int index) => setState(() => _selectedIndex = index);

  List<PriorityBox> _getPriorityBoxes() => [
        PriorityBox(
          id: 'high',
          name: 'High',
            color: Colors.red,
          tasks: _tasks.where((t) => t.priority == Priority.high).toList(),
        ),
        PriorityBox(
          id: 'medium',
          name: 'Medium',
          color: Colors.orange,
          tasks: _tasks.where((t) => t.priority == Priority.medium).toList(),
        ),
        PriorityBox(
          id: 'low',
          name: 'Low',
          color: Colors.green,
          tasks: _tasks.where((t) => t.priority == Priority.low).toList(),
        ),
      ];

  Future<void> _showAddTaskDialog({Task? task}) async {
    await AddTaskDialog.show(
      context,
      editingTask: task,
      onTaskSaved: (newTask) async {
        try {
          if (task == null) {
            await _taskService.addTask(newTask);
          } else {
            await _taskService.updateTask(newTask);
          }
          await _loadTasks();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(task == null ? 'Task created!' : 'Task updated!'),
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error saving task: $e')),
            );
          }
        }
      },
    );
  }

  Future<void> _showTaskDetails(Task task) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => TaskDetailsDialog(
        task: task,
        onEdit: () {
          Navigator.pop(context);
          _showAddTaskDialog(task: task);
        },
        onDelete: () {
          Navigator.pop(context);
          _deleteTask(task);
        },
        onToggleComplete: (isCompleted) => _toggleTaskCompletion(task, isCompleted),
      ),
    );
  }

  Future<void> _deleteTask(Task task) async {
    try {
      await _taskService.deleteTask(task.id);
      await _loadTasks();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Task deleted')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error deleting task: $e')));
      }
    }
  }

  Future<void> _toggleTaskCompletion(Task task, bool isCompleted) async {
    try {
      final updated = task.copyWith(
        isCompleted: isCompleted,
        completedAt: isCompleted ? DateTime.now() : null,
      );
      await _taskService.updateTask(updated);
      await _loadTasks();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error updating task: $e')));
      }
    }
  }

  Widget _buildDrawer() {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          const DrawerHeader(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue, Colors.purple],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Icon(Icons.task_alt, color: Colors.white, size: 48),
                SizedBox(height: 8),
                Text(
                  'Task Tracker Pro',
                  style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                ),
                Text('Advanced Features', style: TextStyle(color: Colors.white70, fontSize: 14)),
              ],
            ),
          ),
          _drawerItem(Icons.dashboard, 'Custom Dashboard', () {
            Navigator.pop(context);
            Navigator.push(context, MaterialPageRoute(builder: (_) => const DashboardScreen()));
          }),
          _drawerItem(Icons.timer, 'Pomodoro Focus', () {
            Navigator.pop(context);
            Navigator.push(context, MaterialPageRoute(builder: (_) => const PomodoroScreen()));
          }),
          _drawerItem(Icons.account_tree, 'Mind Map View', () {
            Navigator.pop(context);
            Navigator.push(context, MaterialPageRoute(builder: (_) => const MindMapScreen()));
          }),
          _drawerItem(Icons.smart_toy, 'Automation Rules', () {
            Navigator.pop(context);
            Navigator.push(context, MaterialPageRoute(builder: (_) => const AutomationRulesScreen()));
          }),
          const Divider(),
          _drawerItem(Icons.security, 'Security Settings', () {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Security settings coming soon!')),
            );
          }),
          _drawerItem(Icons.location_on, 'Location Reminders', () {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Location reminders coming soon!')),
            );
          }),
          _drawerItem(Icons.voice_chat, 'Voice Commands', () {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Voice commands coming soon!')),
            );
          }),
          const Divider(),
          _drawerItem(Icons.help, 'Help & Support', () {
            Navigator.pop(context);
            showDialog(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text('Help & Support'),
                content: const Text('Welcome to Task Tracker Pro! Use the drawer to access advanced features like Pomodoro focus sessions, mind mapping, and automation rules.'),
                actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK'))],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _drawerItem(IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      onTap: onTap,
    );
  }

  Widget _buildBody() {
    switch (_selectedIndex) {
      case 0: // Tasks (Home)
        return HomeScreen(
          tasks: _filteredTasks,
          isLoading: _isLoading,
          onTasksChanged: _loadTasks,
          onTaskTap: _showTaskDetails,
          onAddTask: _showAddTaskDialog,
        );
      case 1: // Calendar
        return CalendarScreen(onTasksChanged: _loadTasks);
      case 2: // Dashboard
        return const DashboardScreen();
      case 3: // Focus (Pomodoro)
        return const PomodoroScreen();
      case 4: // Mind Map
        return const MindMapScreen();
      case 5: // Automation Rules
        return const AutomationRulesScreen();
      case 6: // Profile
        return ProfileScreen(priorityBoxes: _getPriorityBoxes());
      default:
        return const SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: _buildDrawer(),
      body: _buildBody(),
      bottomNavigationBar: CustomBottomNavBar(
        selectedIndex: _selectedIndex,
        onItemTapped: (i) => setState(() => _selectedIndex = i),
      ),
      floatingActionButton: _selectedIndex == 0
          ? FloatingActionButton(
              onPressed: () => _showAddTaskDialog(),
              child: const Icon(Icons.add),
            )
          : null,
    );
  }
}
