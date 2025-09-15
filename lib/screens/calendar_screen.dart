import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:task_tracker/models/task.dart';
import 'package:task_tracker/models/task_status.dart';
import 'package:task_tracker/services/task_service.dart';
import 'package:task_tracker/widgets/kanban_board.dart';

enum CalendarViewMode { month, week, day }

class CalendarScreen extends StatefulWidget {
  final VoidCallback? onTasksChanged; // notify parent when tasks mutate
  const CalendarScreen({super.key, this.onTasksChanged});
  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  final TaskService _taskService = TaskService();
  Map<DateTime, List<Task>> _events = {};
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();
  CalendarViewMode _mode = CalendarViewMode.month;
  bool _loading = true;
  bool _showKanban = false;
  List<Task> _allTasks = [];
  bool _rankedView = false; // show ranked tasks for the selected day
  bool _focusMode = false; // focus mode hides completed + non-urgent tasks

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final tasks = await _taskService.getTasks();
    final map = <DateTime, List<Task>>{};
    for (final t in tasks) {
      final key = DateTime(t.dueDate.year, t.dueDate.month, t.dueDate.day);
      map.putIfAbsent(key, () => []).add(t);
    }
    if (!mounted) return;
    setState(() {
      _allTasks = tasks;
      _events = map;
      _loading = false;
    });
  }

  Future<void> _quickAddNaturalLanguage() async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Quick Add (Natural Language)'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: "e.g. 'Remind me to call John tomorrow at 5 PM'"),
          onSubmitted: (_) => Navigator.of(ctx).pop(controller.text.trim()),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.of(ctx).pop(controller.text.trim()), child: const Text('Add')),
        ],
      ),
    );
    if (result != null && result.isNotEmpty) {
      setState(() => _loading = true);
      try {
        await _taskService.addTaskFromNaturalLanguage(result);
        await _load();
        widget.onTasksChanged?.call();
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to parse: $e')));
        setState(() => _loading = false);
      }
    }
  }

  List<Task> _tasksFor(DateTime day) {
    final key = DateTime(day.year, day.month, day.day);
    var list = List<Task>.from(_events[key] ?? []);
    if (_focusMode) {
      list = list.where((t) => !t.isCompleted && (t.isDueToday || t.isOverdue || t.isDueSoon)).toList();
    }
    if (_rankedView) {
      // simple ranking using TaskService helper
      list.sort((a, b) {
        // Overdue first
        final aOver = a.isOverdue ? 1 : 0;
        final bOver = b.isOverdue ? 1 : 0;
        if (aOver != bOver) return bOver.compareTo(aOver);
        // Then due date
        final dateCmp = a.dueDate.compareTo(b.dueDate);
        if (dateCmp != 0) return dateCmp;
        // Then priority
        return b.priority.index.compareTo(a.priority.index);
      });
    }
    return list;
  }

  Future<void> _onStatusChanged(Task task, TaskStatus newStatus) async {
    await _taskService.updateStatus(task.id, newStatus);
    await _load();
    widget.onTasksChanged?.call();
  }

  Widget _buildCalendar() {
    return TableCalendar<Task>(
      firstDay: DateTime.utc(2020, 1, 1),
      lastDay: DateTime.utc(2100, 12, 31),
      focusedDay: _focusedDay,
      calendarFormat: _mode == CalendarViewMode.month ? CalendarFormat.month : CalendarFormat.week,
      startingDayOfWeek: StartingDayOfWeek.monday,
      selectedDayPredicate: (day) => isSameDay(day, _selectedDay),
      eventLoader: _tasksFor,
      onDaySelected: (selected, focused) {
        setState(() { _selectedDay = selected; _focusedDay = focused; });
      },
      onPageChanged: (focused) => _focusedDay = focused,
      calendarStyle: const CalendarStyle(outsideDaysVisible: false),
      headerStyle: const HeaderStyle(formatButtonVisible: false, titleCentered: true),
    );
  }

  Widget _buildTaskList() {
    final list = _tasksFor(_selectedDay);
    if (list.isEmpty) {
      return const Center(child: Text('No tasks'));
    }
    return ListView.builder(
      itemCount: list.length,
      itemBuilder: (context, i) {
        final t = list[i];
        return ListTile(
          leading: Icon(t.isCompleted ? Icons.check_circle : Icons.radio_button_unchecked, color: t.isCompleted ? Colors.green : Colors.grey),
          title: Text(t.title),
          subtitle: Text('${t.dueDate.toLocal()}'),
          trailing: PopupMenuButton<String>(
            onSelected: (v) {
              final status = TaskStatus.values.firstWhere((s) => s.name == v, orElse: () => t.status);
              _onStatusChanged(t, status);
            },
            itemBuilder: (c) => TaskStatus.values.map((s) => PopupMenuItem(value: s.name, child: Text(s.label))).toList(),
          ),
        );
      },
    );
  }

  Widget _buildKanban() {
    return KanbanBoard(
      tasks: _allTasks,
      onStatusChanged: (task, status) => _onStatusChanged(task, status),
      onRefresh: _load,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Calendar & Board'),
        actions: [
          IconButton(
            tooltip: 'Toggle Kanban',
            icon: Icon(_showKanban ? Icons.calendar_month : Icons.view_kanban),
            onPressed: () => setState(() => _showKanban = !_showKanban),
          ),
          IconButton(
            tooltip: _focusMode ? 'Exit Focus Mode' : 'Enter Focus Mode',
            icon: Icon(_focusMode ? Icons.visibility : Icons.visibility_off),
            onPressed: () => setState(() => _focusMode = !_focusMode),
          ),
          IconButton(
            tooltip: _rankedView ? 'Unrank Tasks' : 'Rank Tasks',
            icon: Icon(_rankedView ? Icons.format_list_bulleted : Icons.trending_up),
            onPressed: () => setState(() => _rankedView = !_rankedView),
          ),
          PopupMenuButton<CalendarViewMode>(
            icon: const Icon(Icons.view_agenda),
            onSelected: (m) => setState(() => _mode = m),
            itemBuilder: (c) => const [
              PopupMenuItem(value: CalendarViewMode.month, child: Text('Month View')),
              PopupMenuItem(value: CalendarViewMode.week, child: Text('Week View')),
              PopupMenuItem(value: CalendarViewMode.day, child: Text('Day Focus')),
            ],
          ),
          IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
        ],
      ),
      floatingActionButton: !_showKanban
          ? FloatingActionButton.extended(
              onPressed: _quickAddNaturalLanguage,
              icon: const Icon(Icons.auto_awesome),
              label: const Text('NL Task'),
            )
          : null,
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _showKanban
              ? _buildKanban()
              : Column(
                  children: [
                    _buildCalendar(),
                    const Divider(height: 1),
                    Expanded(child: _buildTaskList()),
                  ],
                ),
    );
  }
}
