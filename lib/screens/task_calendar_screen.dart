// lib/screens/task_calendar_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:task_tracker/models/priority.dart';
import 'package:task_tracker/models/task.dart';
import 'package:task_tracker/utils/app_colors.dart';
import 'package:task_tracker/models/priority_box.dart';
import 'package:task_tracker/utils/color_utils.dart';
import 'package:task_tracker/utils/date_utils.dart' as task_date_utils;
import 'package:task_tracker/widgets/glass_container.dart';
import 'package:task_tracker/widgets/task_details_dialog.dart';

class TaskCalendarScreen extends StatefulWidget {
  final List<PriorityBox> priorityBoxes;

  const TaskCalendarScreen({super.key, required this.priorityBoxes});

  @override
  TaskCalendarScreenState createState() => TaskCalendarScreenState();
}

class TaskCalendarScreenState extends State<TaskCalendarScreen> {
  late DateTime _focusedDay;
  DateTime? _selectedDay;
  Map<DateTime, List<Task>> _tasksByDate = {};

  @override
  void initState() {
    super.initState();
    _focusedDay = DateTime.now();
    _selectedDay = _focusedDay;
    _groupTasksByDate();
  }

  void _groupTasksByDate() {
    final Map<DateTime, List<Task>> tasksMap = {};

    for (var box in widget.priorityBoxes) {
      for (var task in box.tasks) {
        // Normalize the date to remove time part for grouping
        final date = DateTime(
          task.dueDate.year,
          task.dueDate.month,
          task.dueDate.day,
        );

        if (tasksMap[date] == null) {
          tasksMap[date] = [];
        }
        tasksMap[date]!.add(task);
            }
    }

    setState(() {
      _tasksByDate = tasksMap;
    });
  }

  List<Task> _getTasksForDay(DateTime day) {
    final normalizedDay = DateTime(day.year, day.month, day.day);
    return _tasksByDate[normalizedDay] ?? [];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Task Calendar'),
        backgroundColor: AppColors.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Container(
            margin: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: ColorUtils.withOpacity(Colors.grey, 0.2),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TableCalendar(
              firstDay: DateTime.utc(2020, 1, 1),
              lastDay: DateTime.utc(2030, 12, 31),
              focusedDay: _focusedDay,
              selectedDayPredicate: (day) {
                return isSameDay(_selectedDay, day);
              },
              eventLoader: _getTasksForDay,
              onDaySelected: (selectedDay, focusedDay) {
                if (!isSameDay(_selectedDay, selectedDay)) {
                  setState(() {
                    _selectedDay = selectedDay;
                    _focusedDay = focusedDay;
                  });
                }
              },
              onPageChanged: (focusedDay) {
                _focusedDay = focusedDay;
              },
              calendarStyle: CalendarStyle(
                outsideDaysVisible: false,
                todayDecoration: BoxDecoration(
                  color: ColorUtils.withOpacity(AppColors.primaryColor, 0.7),
                  shape: BoxShape.circle,
                ),
                selectedDecoration: BoxDecoration(
                  color: AppColors.primaryColor,
                  shape: BoxShape.circle,
                ),
                markerDecoration: BoxDecoration(
                  color: AppColors.accentColor,
                  shape: BoxShape.circle,
                ),
                markersMaxCount: 3,
              ),
              headerStyle: HeaderStyle(
                formatButtonVisible: false,
                titleCentered: true,
                titleTextStyle: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _buildTasksForSelectedDay(),
          ),
        ],
      ),
    );
  }

  Widget _buildTasksForSelectedDay() {
    final selectedTasks = _selectedDay != null ? _getTasksForDay(_selectedDay!) : [];

    if (selectedTasks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.event_available,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No tasks for this day',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
              ),
            ),
            if (_selectedDay != null)
              Text(
                DateFormat('MMMM d, y').format(_selectedDay!),
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[500],
                ),
              ),
          ],
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tasks for ${DateFormat('MMMM d').format(_selectedDay!)}',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: ListView.builder(
              itemCount: selectedTasks.length,
              itemBuilder: (context, index) {
                final task = selectedTasks[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: Icon(
                      task.isCompleted
                          ? Icons.check_circle
                          : Icons.circle_outlined,
                      color: task.isCompleted
                          ? Colors.green
                          : _getPriorityColor(task.priority),
                    ),
                    title: Text(
                      task.title,
                      style: TextStyle(
                        decoration: task.isCompleted
                            ? TextDecoration.lineThrough
                            : null,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Priority: ${task.priority.name}'),
                        if (task.dueDate != null)
                          Text('Due: ${DateFormat('h:mm a').format(task.dueDate!)}'),
                      ],
                    ),
                    trailing: Container(
                      width: 4,
                      height: 40,
                      decoration: BoxDecoration(
                        color: _getPriorityColor(task.priority),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    onTap: () => _showTaskDetails(task),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Color _getPriorityColor(Priority priority) {
    switch (priority) {
      case Priority.urgent:
        return Colors.red.shade700; // Dark red for urgent
      case Priority.high:
        return Colors.red;
      case Priority.medium:
        return Colors.orange;
      case Priority.low:
        return Colors.green;
    }
  }

  void _showTaskDetails(Task task) {
    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: ColorUtils.withOpacity(Colors.black, 0.6),
      builder: (context) => TaskDetailsDialog(
        task: task,
        onEdit: () {
          Navigator.of(context).pop();
          // Add edit functionality here
        },
        onToggleComplete: (isCompleted) {
          setState(() {
            // Update the task in the original data structure
            for (var box in widget.priorityBoxes) {
              final taskIndex = box.tasks.indexWhere((t) => t.id == task.id);
              if (taskIndex != -1) {
                box.tasks[taskIndex] = task.copyWith(isCompleted: isCompleted);
                break;
              }
            }
            _groupTasksByDate(); // Refresh the calendar data
          });
          Navigator.of(context).pop();
        },
        onDelete: () {
          setState(() {
            // Remove the task from the original data structure
            for (var box in widget.priorityBoxes) {
              box.tasks.removeWhere((t) => t.id == task.id);
            }
            _groupTasksByDate(); // Refresh the calendar data
          });
        },
      ),
    );
  }
}
