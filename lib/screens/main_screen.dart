import 'package:flutter/material.dart';
import 'package:task_tracker/models/priority.dart';
import 'package:task_tracker/models/task.dart';
import 'package:task_tracker/models/priority_box.dart';
import 'package:task_tracker/screens/calendar_screen.dart';
import 'package:task_tracker/screens/dashboard_screen.dart';
import 'package:task_tracker/screens/home_screen.dart';
import 'package:task_tracker/screens/mind_map_screen.dart';
import 'package:task_tracker/screens/notifications_screen.dart';
import 'package:task_tracker/screens/pomodoro_screen.dart';
import 'package:task_tracker/screens/profile_screen.dart';
import 'package:task_tracker/screens/statistics_screen.dart';
import 'package:task_tracker/screens/automation_rules_screen.dart';
import 'package:task_tracker/services/task_service.dart';
import 'package:task_tracker/widgets/custom_drawer.dart';
import 'package:task_tracker/widgets/custom_bottom_nav_bar.dart';
import 'package:task_tracker/widgets/add_task_dialog.dart';
import 'package:task_tracker/widgets/task_details_dialog.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with TickerProviderStateMixin, RestorationMixin {
  final TaskService _taskService = TaskService();
  List<Task> _tasks = [];
  List<Task> _filteredTasks = [];
  bool _isLoading = true;
  int _selectedIndex = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  
  // Restorable state for navigation
  final RestorableInt _currentPageIndex = RestorableInt(1); // Default to Home
  
  @override
  String get restorationId => 'main_screen';
  
  @override
  void restoreState(RestorationBucket? oldBucket, bool initialRestore) {
    registerForRestoration(_currentPageIndex, 'page_index');
  }

  // Filtering and sorting
  final String _searchQuery = '';
  final bool _showCompleted = true;
  final String _sortBy = 'dueDate';
  final bool _sortAscending = true;
  Priority? _priorityFilter; // Added missing filter state

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

  Widget _buildCurrentScreen() {
    // Prefer drawer index when present, else fall back to bottom nav mapping
    final idx = (_currentPageIndex.value >= 0) ? _currentPageIndex.value : _selectedIndex;

    switch (idx) {
      case 0:
        return const DashboardScreen();
      case 1:
        return HomeScreen(
          tasks: _filteredTasks,
          isLoading: _isLoading,
          onAddTask: () => _showAddTaskDialog(),
          onTaskTap: (task) => _showTaskDetails(task),
          onTasksChanged: () async {
            await _loadTasks();
          },
        );
      case 2:
        return const CalendarScreen();
      case 3:
        return StatisticsScreen(priorityBoxes: _getPriorityBoxes());
      case 4:
        return const MindMapScreen();
      case 5:
        return const PomodoroScreen();
      case 6:
        return const NotificationsScreen();
      case 7:
        return const AutomationRulesScreen();
      case 8:
        return ProfileScreen(priorityBoxes: _getPriorityBoxes());
      default:
        // Map bottom nav (0..3) to Home/Calendar/Statistics/Profile if needed
        switch (_selectedIndex) {
          case 0:
            return HomeScreen(
              tasks: _filteredTasks,
              isLoading: _isLoading,
              onAddTask: () => _showAddTaskDialog(),
              onTaskTap: (task) => _showTaskDetails(task),
              onTasksChanged: () async {
                await _loadTasks();
              },
            );
          case 1:
            return const CalendarScreen();
          case 2:
            return StatisticsScreen(priorityBoxes: _getPriorityBoxes());
          case 3:
            return ProfileScreen(priorityBoxes: _getPriorityBoxes());
          default:
            return const Center(child: Text('Screen not found'));
        }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      drawer: CustomDrawer(
        selectedIndex: _currentPageIndex.value,
        onItemTapped: (index) {
          setState(() {
            _currentPageIndex.value = index;
            _selectedIndex = index;
          });
          // Close drawer after selection if on mobile
          if (MediaQuery.of(context).size.width < 800) {
            Navigator.pop(context);
          }
        },
      ),
      body: Row(
        children: [
          // Show drawer as sidebar on larger screens
          if (MediaQuery.of(context).size.width >= 800)
            CustomDrawer(
              selectedIndex: _currentPageIndex.value,
              onItemTapped: (index) {
                setState(() {
                  _currentPageIndex.value = index;
                  _selectedIndex = index;
                });
              },
            ),
          // Main content
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _buildCurrentScreen(),
          ),
        ],
      ),
      floatingActionButton: _selectedIndex == 0 || _selectedIndex == 1
          ? FloatingActionButton(
              onPressed: () => _showAddTaskDialog(),
              backgroundColor: Theme.of(context).colorScheme.primary,
              child: Icon(
                Icons.add,
                color: Theme.of(context).colorScheme.onPrimary,
              ),
            )
          : null,
      // Show bottom navigation only on mobile
      bottomNavigationBar: MediaQuery.of(context).size.width < 800
          ? CustomBottomNavBar(
              selectedIndex: _selectedIndex,
              onItemTapped: (index) {
                setState(() {
                  _selectedIndex = index;
                  // Map bottom nav (0..3) to drawer indices [1,2,3,8]
                  const mapping = [1, 2, 3, 8];
                  _currentPageIndex.value = mapping[index];
                });
              },
            )
          : null,
    );
  }
}
