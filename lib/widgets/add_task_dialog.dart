import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:task_tracker/models/task.dart';
import 'package:task_tracker/models/priority.dart';
import 'package:task_tracker/utils/app_colors.dart';
import 'package:task_tracker/utils/color_utils.dart';
import 'package:task_tracker/models/category.dart';
import 'package:task_tracker/models/task_status.dart';
import 'package:task_tracker/models/subtask.dart';
import 'package:task_tracker/services/category_service.dart';
import 'package:task_tracker/services/task_service.dart';

class AddTaskDialog extends StatefulWidget {
  final Task? editingTask;
  final Function(Task) onTaskSaved;

  const AddTaskDialog({
    super.key,
    this.editingTask,
    required this.onTaskSaved,
  });

  static Future<void> show(
    BuildContext context, {
    Task? editingTask,
    required Function(Task) onTaskSaved,
  }) {
    return showDialog(
      context: context,
      builder: (context) => AddTaskDialog(
        editingTask: editingTask,
        onTaskSaved: onTaskSaved,
      ),
      barrierColor: ColorUtils.withOpacity(Colors.black, 0.4),
    );
  }

  @override
  State<AddTaskDialog> createState() => _AddTaskDialogState();
}

class _AddTaskDialogState extends State<AddTaskDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _notesController = TextEditingController();
  Priority _selectedPriority = Priority.medium;
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _selectedTime = const TimeOfDay(hour: 9, minute: 0);
  List<String> _tags = [];
  final _tagController = TextEditingController();
  String? _selectedCategoryId;
  final _newCategoryController = TextEditingController();
  final List<SubTask> _subTasks = [];
  final _subTaskController = TextEditingController();
  TaskStatus _status = TaskStatus.todo;
  final _taskService = TaskService();
  bool _suggestingSlot = false;

  @override
  void initState() {
    super.initState();
    if (widget.editingTask != null) {
      _titleController.text = widget.editingTask!.title;
      _descriptionController.text = widget.editingTask!.description;
      _notesController.text = widget.editingTask!.notes ?? '';
      _selectedPriority = widget.editingTask!.priority;
      _selectedDate = widget.editingTask!.dueDate;
      _selectedTime = TimeOfDay.fromDateTime(widget.editingTask!.dueDate);
      _tags = List.from(widget.editingTask!.tags);
      _selectedCategoryId = widget.editingTask!.categoryId;
      _status = widget.editingTask!.status;
    }
    _loadCategories();
  }

  List<Category> _categories = [];
  bool _loadingCategories = false;

  Future<void> _loadCategories() async {
    setState(() => _loadingCategories = true);
    final svc = CategoryService();
    final cats = await svc.getCategories();
    setState(() {
      _categories = cats;
      _loadingCategories = false;
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _notesController.dispose();
    _tagController.dispose();
    _newCategoryController.dispose();
    _subTaskController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
      elevation: 0,
      backgroundColor: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue.shade50, Colors.blue.shade200],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(32),
          boxShadow: [
            BoxShadow(
              color: ColorUtils.withOpacity(AppColors.primaryColor, 0.1),
              blurRadius: 24,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(32),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.editingTask == null ? 'Add Task' : 'Edit Task',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade900,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _titleController,
                        decoration: InputDecoration(
                          labelText: 'Title',
                          filled: true,
                          fillColor: const Color.fromRGBO(255, 255, 255, 0.8),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        validator: (value) => value == null || value.isEmpty ? 'Enter a title' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _descriptionController,
                        decoration: InputDecoration(
                          labelText: 'Description',
                          filled: true,
                          fillColor: const Color.fromRGBO(255, 255, 255, 0.8),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        maxLines: 2,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _notesController,
                        decoration: InputDecoration(
                          labelText: 'Notes',
                          filled: true,
                          fillColor: const Color.fromRGBO(255, 255, 255, 0.8),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        maxLines: 2,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<Priority>(
                              value: _selectedPriority,
                              decoration: InputDecoration(
                                labelText: 'Priority',
                                filled: true,
                                fillColor: const Color.fromRGBO(255, 255, 255, 0.8),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              items: Priority.values.map((priority) {
                                return DropdownMenuItem(
                                  value: priority,
                                  child: Text(priority.name),
                                );
                              }).toList(),
                              onChanged: (value) {
                                if (value != null) setState(() => _selectedPriority = value);
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: InkWell(
                              onTap: () async {
                                final date = await showDatePicker(
                                  context: context,
                                  initialDate: _selectedDate,
                                  firstDate: DateTime.now(),
                                  lastDate: DateTime(2100),
                                );
                                if (date != null) setState(() => _selectedDate = date);
                              },
                              child: InputDecorator(
                                decoration: InputDecoration(
                                  labelText: 'Due Date',
                                  filled: true,
                                  fillColor: ColorUtils.withOpacity(Colors.white, 0.8),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                child: Text(
                                  '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2,'0')}-${_selectedDate.day.toString().padLeft(2,'0')}',
                                  style: const TextStyle(fontSize: 16),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: InkWell(
                              onTap: () async {
                                final time = await showTimePicker(
                                  context: context,
                                  initialTime: _selectedTime,
                                );
                                if (time != null) setState(() => _selectedTime = time);
                              },
                              child: InputDecorator(
                                decoration: InputDecoration(
                                  labelText: 'Due Time',
                                  filled: true,
                                  fillColor: const Color.fromRGBO(255, 255, 255, 0.8),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                child: Text(_selectedTime.format(context), style: const TextStyle(fontSize: 16)),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerRight,
                        child: OutlinedButton.icon(
                          onPressed: _suggestingSlot ? null : _handleSuggestSlot,
                          icon: _suggestingSlot ? const SizedBox(height:16,width:16,child: CircularProgressIndicator(strokeWidth:2)) : const Icon(Icons.lightbulb_outline),
                          label: Text(_suggestingSlot ? 'Suggesting...' : 'Suggest Slot'),
                        ),
                      ),
                      DropdownButtonFormField<String>(
                        value: _selectedCategoryId,
                        decoration: InputDecoration(
                          labelText: 'Category',
                          filled: true,
                          fillColor: const Color.fromRGBO(255, 255, 255, 0.8),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        items: [
                          ..._categories.map((c) => DropdownMenuItem(
                                value: c.id,
                                child: Text(c.name),
                              )),
                        ],
                        onChanged: (val) => setState(() => _selectedCategoryId = val),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _newCategoryController,
                              decoration: InputDecoration(
                                labelText: 'New Category',
                                filled: true,
                                fillColor: const Color.fromRGBO(255, 255, 255, 0.8),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: () async {
                              if (_newCategoryController.text.trim().isEmpty) return;
                              final svc = CategoryService();
                              final cat = await svc.addCategory(_newCategoryController.text.trim());
                              _newCategoryController.clear();
                              await _loadCategories();
                              setState(() => _selectedCategoryId = cat.id);
                            },
                            child: const Text('Add'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<TaskStatus>(
                        value: _status,
                        decoration: InputDecoration(
                          labelText: 'Status',
                          filled: true,
                          fillColor: const Color.fromRGBO(255, 255, 255, 0.8),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        items: TaskStatus.values.map((s) => DropdownMenuItem(value: s, child: Text(s.label))).toList(),
                        onChanged: (val) => setState(() => _status = val ?? TaskStatus.todo),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _tagController,
                        decoration: InputDecoration(
                          labelText: 'Add Tag',
                          filled: true,
                          fillColor: const Color.fromRGBO(255, 255, 255, 0.8),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        onFieldSubmitted: (value) {
                          if (value.isNotEmpty) {
                            setState(() {
                              _tags.add(value);
                              _tagController.clear();
                            });
                          }
                        },
                      ),
                      Wrap(
                        spacing: 8,
                        children: _tags.map((tag) => Chip(
                          label: Text(tag),
                          backgroundColor: Colors.blue.shade100,
                          deleteIcon: Icon(Icons.close, size: 18),
                          onDeleted: () {
                            setState(() => _tags.remove(tag));
                          },
                        )).toList(),
                      ),
                      const SizedBox(height: 12),
                      Text('Subtasks', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.blue.shade900)),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _subTaskController,
                              decoration: InputDecoration(
                                labelText: 'Add subtask',
                                filled: true,
                                fillColor: const Color.fromRGBO(255, 255, 255, 0.8),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              onSubmitted: (_) => _addSubTask(),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(Icons.add_circle_outline),
                            onPressed: _addSubTask,
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      ..._subTasks.map((st) => ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: const Icon(Icons.drag_indicator, size: 18),
                            title: Text(st.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                            trailing: IconButton(
                              icon: const Icon(Icons.close, size: 18),
                              onPressed: () => setState(() => _subTasks.removeWhere((s) => s.id == st.id)),
                            ),
                          )),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: const Text('Cancel'),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              backgroundColor: Colors.blueAccent,
                              elevation: 8,
                            ),
                            onPressed: () {
                              if (_formKey.currentState!.validate()) {
                                final dueDate = DateTime(
                                  _selectedDate.year,
                                  _selectedDate.month,
                                  _selectedDate.day,
                                  _selectedTime.hour,
                                  _selectedTime.minute,
                                );
                                final newTask = Task(
                                  id: widget.editingTask?.id ?? '',
                                  title: _titleController.text,
                                  description: _descriptionController.text,
                                  notes: _notesController.text.isEmpty ? null : _notesController.text,
                                  priority: _selectedPriority,
                                  dueDate: dueDate,
                                  tags: _tags,
                                  isCompleted: _status == TaskStatus.completed,
                                  categoryId: _selectedCategoryId,
                                  status: _status,
                                  subtasks: _subTasks,
                                );
                                widget.onTaskSaved(newTask);
                                Navigator.of(context).pop();
                              }
                            },
                            child: Text(widget.editingTask == null ? 'Add Task' : 'Save'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _addSubTask() {
    if (_subTaskController.text.trim().isEmpty) return;
    setState(() {
      _subTasks.add(SubTask(taskId: widget.editingTask?.id ?? '', title: _subTaskController.text.trim()));
      _subTaskController.clear();
    });
  }

  Future<void> _handleSuggestSlot() async {
    setState(()=> _suggestingSlot = true);
    try {
      final tasks = await _taskService.getTasks();
      final slot = await _taskService.suggestSmartSlot(tasks);
      if (slot != null && mounted) {
        setState(() {
          _selectedDate = DateTime(slot.year, slot.month, slot.day);
          _selectedTime = TimeOfDay(hour: slot.hour, minute: slot.minute);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Suggested: ${slot.toLocal()}')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Suggestion failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(()=> _suggestingSlot = false);
    }
  }
}
