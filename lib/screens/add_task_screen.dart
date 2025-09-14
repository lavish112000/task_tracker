import 'package:flutter/material.dart';
import 'package:task_tracker/models/priority.dart';
import 'package:task_tracker/models/task.dart';
import 'package:task_tracker/utils/app_colors.dart';

class AddTaskScreen extends StatefulWidget {
  final Function(Task) onAddTask;

  const AddTaskScreen({super.key, required this.onAddTask});

  @override
  State<AddTaskScreen> createState() => _AddTaskScreenState();
}

class _AddTaskScreenState extends State<AddTaskScreen> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  Priority _selectedPriority = Priority.medium;

  void _submitTask() {
    if (_titleController.text.isEmpty) {
      return; // Don't add empty tasks
    }
    final newTask = Task(
      id: DateTime.now().toString(),
      title: _titleController.text,
      description: _descriptionController.text,
      dueDate: DateTime.now().add(const Duration(days: 1)), // Add required dueDate
      priority: _selectedPriority,
      isCompleted: false,
    );
    widget.onAddTask(newTask);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add New Task'),
        backgroundColor: AppColors.backgroundColor,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Title',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description (Optional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 4,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<Priority>(
              value: _selectedPriority,
              decoration: const InputDecoration(
                labelText: 'Priority',
                border: OutlineInputBorder(),
              ),
              items: Priority.values.map((Priority priority) {
                return DropdownMenuItem<Priority>(
                  value: priority,
                  child: Text(priority.toString().split('.').last.toUpperCase()),
                );
              }).toList(),
              onChanged: (Priority? newValue) {
                if (newValue != null) {
                  setState(() {
                    _selectedPriority = newValue;
                  });
                }
              },
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _submitTask,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryColor,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Add Task', style: TextStyle(color: Colors.white, fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }
}
