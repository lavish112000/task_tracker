import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:task_tracker/models/priority.dart';
import 'package:task_tracker/models/task.dart';
import 'package:task_tracker/theme/app_theme.dart';
import 'package:task_tracker/utils/date_utils.dart' as date_utils;
import 'package:task_tracker/widgets/priority_chip.dart';

class TaskFormScreen extends StatefulWidget {
  final Task? task;
  final Function(Task) onSave;

  const TaskFormScreen({
    super.key,
    this.task,
    required this.onSave,
  });

  @override
  _TaskFormScreenState createState() => _TaskFormScreenState();
}

class _TaskFormScreenState extends State<TaskFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _dueDateController;
  late TextEditingController _tagController;
  late TextEditingController _notesController;
  
  late DateTime _dueDate;
  late Priority _priority;
  final List<String> _tags = [];
  
  final DateFormat _dateFormat = DateFormat('MMM d, yyyy hh:mm a');

  @override
  void initState() {
    super.initState();
    final task = widget.task;
    _titleController = TextEditingController(text: task?.title ?? '');
    _descriptionController = TextEditingController(text: task?.description ?? '');
    _dueDate = task?.dueDate ?? DateTime.now().add(const Duration(days: 1));
    _dueDateController = TextEditingController(
      text: _dateFormat.format(_dueDate),
    );
    _priority = task?.priority ?? Priority.medium;
    _tagController = TextEditingController();
    _notesController = TextEditingController(text: task?.notes ?? '');
    _tags.addAll(task?.tags ?? []);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _dueDateController.dispose();
    _tagController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _selectDateTime(BuildContext context) async {
    final date = await showDatePicker(
      context: context,
      initialDate: _dueDate,
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );

    if (!mounted) return;
    
    if (date != null) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_dueDate),
      );

      if (!mounted) return;
      
      if (time != null) {
        setState(() {
          _dueDate = DateTime(
            date.year,
            date.month,
            date.day,
            time.hour,
            time.minute,
          );
          _dueDateController.text = _dateFormat.format(_dueDate);
        });
      }
    }
  }

  void _addTag() {
    final tag = _tagController.text.trim();
    if (tag.isNotEmpty && !_tags.contains(tag)) {
      setState(() {
        _tags.add(tag);
        _tagController.clear();
      });
    }
  }

  void _removeTag(String tag) {
    setState(() {
      _tags.remove(tag);
    });
  }

  void _saveTask() {
    if (_formKey.currentState?.validate() ?? false) {
      final task = Task(
        id: widget.task?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        title: _titleController.text,
        description: _descriptionController.text,
        dueDate: _dueDate,
        isCompleted: widget.task?.isCompleted ?? false,
        priority: _priority,
        createdAt: widget.task?.createdAt ?? DateTime.now(),
        completedAt: widget.task?.completedAt,
        tags: _tags,
        notes: _notesController.text.isNotEmpty ? _notesController.text : null,
      );

      widget.onSave(task);
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.task == null ? 'New Task' : 'Edit Task'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveTask,
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Title Field
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: 'Title',
                  prefixIcon: const Icon(Icons.title),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a title';
                  }
                  return null;
                },
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 16),
              
              // Description Field
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  labelText: 'Description (Optional)',
                  prefixIcon: const Icon(Icons.description),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                maxLines: 3,
                style: theme.textTheme.bodyLarge,
              ),
              const SizedBox(height: 16),
              
              // Due Date Picker
              TextFormField(
                controller: _dueDateController,
                readOnly: true,
                decoration: InputDecoration(
                  labelText: 'Due Date',
                  prefixIcon: const Icon(Icons.calendar_today),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.edit_calendar),
                    onPressed: () => _selectDateTime(context),
                  ),
                ),
                onTap: () => _selectDateTime(context),
              ),
              const SizedBox(height: 16),
              
              // Priority Selection
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Priority',
                    style: theme.textTheme.labelLarge,
                  ),
                  const SizedBox(height: 8),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: Priority.values.map((priority) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: ChoiceChip(
                            label: Text(
                              priority.toString().split('.').last,
                              style: theme.textTheme.labelLarge?.copyWith(
                                color: priority == _priority
                                    ? theme.colorScheme.onPrimary
                                    : null,
                              ),
                            ),
                            selected: _priority == priority,
                            selectedColor: theme.colorScheme.primary,
                            onSelected: (selected) {
                              if (selected) {
                                setState(() {
                                  _priority = priority;
                                });
                              }
                            },
                            backgroundColor: theme.colorScheme.surfaceVariant,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // Tags
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tags',
                    style: theme.textTheme.labelLarge,
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _tags.map((tag) => Chip(
                      label: Text(tag),
                      deleteIcon: const Icon(Icons.close, size: 16),
                      onDeleted: () => _removeTag(tag),
                    )).toList(),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _tagController,
                          decoration: InputDecoration(
                            hintText: 'Add a tag',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onFieldSubmitted: (_) => _addTag(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.add),
                        onPressed: _addTag,
                        style: IconButton.styleFrom(
                          backgroundColor: theme.colorScheme.primary,
                          foregroundColor: theme.colorScheme.onPrimary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // Notes
              TextFormField(
                controller: _notesController,
                decoration: InputDecoration(
                  labelText: 'Notes (Optional)',
                  prefixIcon: const Icon(Icons.notes),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                maxLines: 4,
                style: theme.textTheme.bodyLarge,
              ),
              const SizedBox(height: 24),
              
              // Save Button
              ElevatedButton(
                onPressed: _saveTask,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  widget.task == null ? 'Create Task' : 'Update Task',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.onPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
