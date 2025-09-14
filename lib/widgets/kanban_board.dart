import 'package:flutter/material.dart';
import 'package:task_tracker/models/task.dart';
import 'package:task_tracker/models/task_status.dart';

class KanbanBoard extends StatelessWidget {
  final List<Task> tasks;
  final Future<void> Function(Task, TaskStatus) onStatusChanged;
  final Future<void> Function() onRefresh;
  const KanbanBoard({super.key, required this.tasks, required this.onStatusChanged, required this.onRefresh});

  List<Task> _byStatus(TaskStatus s) => tasks.where((t) => t.status == s).toList();

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final columnWidth = constraints.maxWidth / 3;
          return SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildColumn(context, TaskStatus.todo, columnWidth),
                _buildColumn(context, TaskStatus.inProgress, columnWidth),
                _buildColumn(context, TaskStatus.completed, columnWidth),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildColumn(BuildContext context, TaskStatus status, double width) {
    final list = _byStatus(status);
    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      child: Card(
        elevation: 2,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                color: _statusColor(status).withOpacity(.15),
                child: Text('${status.label} (${list.length})', style: TextStyle(fontWeight: FontWeight.bold, color: _statusColor(status))),
              ),
              if (list.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(12.0),
                  child: Text('No tasks', style: TextStyle(fontSize: 12, color: Colors.grey)),
                )
              else
                ...list.map((t) => _taskCard(context, t)).toList(),
            ],
        ),
      ),
    );
  }

  Widget _taskCard(BuildContext context, Task task) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: ListTile(
        dense: true,
        leading: Icon(task.isCompleted ? Icons.check_circle : Icons.radio_button_unchecked, color: task.isCompleted ? Colors.green : Colors.grey),
        title: Text(task.title, maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Text(_dueLabel(task), style: const TextStyle(fontSize: 11)),
        trailing: PopupMenuButton<TaskStatus>(
          onSelected: (s) => onStatusChanged(task, s),
          itemBuilder: (c) => TaskStatus.values.map((s) => PopupMenuItem(value: s, child: Text(s.label))).toList(),
        ),
      ),
    );
  }

  String _dueLabel(Task t) {
    final d = t.dueDate;
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

  Color _statusColor(TaskStatus s) {
    switch (s) {
      case TaskStatus.todo:
        return Colors.blue;
      case TaskStatus.inProgress:
        return Colors.orange;
      case TaskStatus.completed:
        return Colors.green;
    }
  }
}
