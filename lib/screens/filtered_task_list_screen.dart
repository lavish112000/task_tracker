import 'package:flutter/material.dart';
import 'package:task_tracker/models/task.dart';
import 'package:task_tracker/widgets/task_card.dart';

class FilteredTaskListScreen extends StatelessWidget {
  final String title;
  final List<Task> tasks;
  final Function(Task) onToggle;

  const FilteredTaskListScreen({
    super.key,
    required this.title,
    required this.tasks,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        automaticallyImplyLeading: false, // No back button needed
        centerTitle: true,
      ),
      body: tasks.isEmpty
          ? Center(
              child: Text(
                'No tasks in this category.',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            )
          : ListView.builder(
              itemCount: tasks.length,
              itemBuilder: (context, index) {
                final task = tasks[index];
                return TaskCard(
                  task: task,
                  onToggleComplete: (isCompleted) => onToggle(task),
                  onEdit: () {
                    // Note: Editing from this screen is not supported yet.
                    // This could be a future enhancement.
                  },
                );
              },
            ),
    );
  }
}
