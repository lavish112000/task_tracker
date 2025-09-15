import 'package:flutter/material.dart';
import 'package:task_tracker/models/task.dart';
import 'package:task_tracker/services/task_service.dart';
import 'package:reorderables/reorderables.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final TaskService _taskService = TaskService();
  List<Task> _tasks = [];
  bool _loading = true;
  List<String> _widgetOrder = ['today_tasks', 'calendar_widget', 'stats_widget', 'focus_widget', 'habits_widget'];

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    final tasks = await _taskService.getTasks();
    if (!mounted) return;
    setState(() { _tasks = tasks; _loading = false; });
  }

  Widget _buildWidget(String widgetType) {
    switch (widgetType) {
      case 'today_tasks':
        return _buildTodayTasksWidget();
      case 'calendar_widget':
        return _buildCalendarWidget();
      case 'stats_widget':
        return _buildStatsWidget();
      case 'focus_widget':
        return _buildFocusWidget();
      case 'habits_widget':
        return _buildHabitsWidget();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildTodayTasksWidget() {
    final today = DateTime.now();
    final todayTasks = _tasks.where((t) =>
      t.dueDate.year == today.year &&
      t.dueDate.month == today.month &&
      t.dueDate.day == today.day
    ).toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.today),
                const SizedBox(width: 8),
                Text('Today\'s Tasks', style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
            const SizedBox(height: 12),
            if (todayTasks.isEmpty)
              const Text('No tasks for today')
            else
              ...todayTasks.take(3).map((task) => ListTile(
                dense: true,
                leading: Icon(task.isCompleted ? Icons.check_circle : Icons.radio_button_unchecked),
                title: Text(task.title),
                subtitle: Text(task.priority.name.toUpperCase()),
              )),
          ],
        ),
      ),
    );
  }

  Widget _buildCalendarWidget() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.calendar_month),
                const SizedBox(width: 8),
                Text('Calendar Preview', style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              height: 120,
              width: double.infinity,
              decoration: BoxDecoration(
                border: Border.all(color: Theme.of(context).dividerColor),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Center(child: Text('Mini Calendar View\n(Future Implementation)')),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsWidget() {
    final completedCount = _tasks.where((t) => t.isCompleted).length;
    final totalCount = _tasks.length;
    final completionRate = totalCount > 0 ? (completedCount / totalCount) : 0.0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.analytics),
                const SizedBox(width: 8),
                Text('Quick Stats', style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _statItem('Total', totalCount.toString(), Icons.assignment),
                _statItem('Done', completedCount.toString(), Icons.check),
                _statItem('Rate', '${(completionRate * 100).toInt()}%', Icons.trending_up),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFocusWidget() {
    final totalSessions = _tasks.fold<int>(0, (p, t) => p + t.focusLevel);
    final totalSeconds = _tasks.fold<int>(0, (p, t) => p + t.totalTrackedSeconds);
    final avgSeconds = totalSessions > 0 ? (totalSeconds / totalSessions).round() : 0;
    String fmt(int secs) {
      final h = (secs ~/ 3600).toString().padLeft(2, '0');
      final m = ((secs % 3600) ~/ 60).toString().padLeft(2, '0');
      final s = (secs % 60).toString().padLeft(2, '0');
      return '$h:$m:$s';
    }
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children:[const Icon(Icons.timer_outlined), const SizedBox(width:8), Text('Focus Productivity', style: Theme.of(context).textTheme.titleMedium)]),
            const SizedBox(height:12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _statItem('Sessions', totalSessions.toString(), Icons.timelapse),
                _statItem('Tracked', fmt(totalSeconds), Icons.schedule),
                _statItem('Avg', avgSeconds==0?'-':fmt(avgSeconds), Icons.speed),
              ],
            ),
            const SizedBox(height:12),
            LinearProgressIndicator(
              value: totalSessions==0?0: (avgSeconds / 1500).clamp(0,1),
              minHeight: 6,
              backgroundColor: Theme.of(context).dividerColor,
            ),
            const SizedBox(height:4),
            Text('Avg vs 25m session', style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }

  Widget _buildHabitsWidget() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.repeat),
                const SizedBox(width: 8),
                Text('Habits Tracker', style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
            const SizedBox(height: 12),
            const Text('Habit tracking coming soon...', style: TextStyle(fontStyle: FontStyle.italic)),
          ],
        ),
      ),
    );
  }

  Widget _statItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 24),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Custom Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Widget reordering: Drag to rearrange')),
              );
            },
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadTasks,
              child: ReorderableColumn(
                padding: const EdgeInsets.all(16),
                onReorder: (oldIndex, newIndex) {
                  setState(() {
                    final item = _widgetOrder.removeAt(oldIndex);
                    _widgetOrder.insert(newIndex, item);
                  });
                },
                children: _widgetOrder.map((widgetType) =>
                  Container(
                    key: ValueKey(widgetType),
                    margin: const EdgeInsets.only(bottom: 16),
                    child: _buildWidget(widgetType),
                  )
                ).toList(),
              ),
            ),
    );
  }
}
