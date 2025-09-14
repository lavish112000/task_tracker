import 'dart:ui';

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:task_tracker/models/priority.dart';
import 'package:task_tracker/models/task.dart';
import 'package:task_tracker/theme/app_theme.dart';
import 'package:task_tracker/utils/app_colors.dart';
import 'package:task_tracker/utils/color_utils.dart';
import 'package:task_tracker/utils/date_utils.dart' as task_date_utils;
import 'package:task_tracker/widgets/priority_chip.dart';

class TaskDetailsDialog extends StatefulWidget {
  final Task task;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final ValueChanged<bool>? onToggleComplete;
  final ValueChanged<Task>? onTaskUpdated; // Added parameter

  const TaskDetailsDialog({
    super.key,
    required this.task,
    this.onEdit,
    this.onDelete,
    this.onToggleComplete,
    this.onTaskUpdated, // Added parameter
  });

  static Future<void> show(
    BuildContext context,
    Task task, {
    VoidCallback? onEdit,
    VoidCallback? onDelete,
    ValueChanged<bool>? onToggleComplete,
    ValueChanged<Task>? onTaskUpdated, // Added parameter
  }) {
    return showDialog(
      context: context,
      builder: (context) => TaskDetailsDialog(
        task: task,
        onEdit: onEdit,
        onDelete: onDelete,
        onToggleComplete: onToggleComplete,
        onTaskUpdated: onTaskUpdated, // Added parameter
      ),
    );
  }

  @override
  State<TaskDetailsDialog> createState() => _TaskDetailsDialogState();
}

class _TaskDetailsDialogState extends State<TaskDetailsDialog>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutBack,
    ));
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    ));
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) _animationController.forward();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
      elevation: 0,
      backgroundColor: Colors.transparent,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: FadeTransition(
          opacity: _fadeAnimation,
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
                  color: ColorUtils.withOpacity(Colors.blueAccent, 0.15),
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
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          GestureDetector(
                            onTap: () {
                              if (widget.onToggleComplete != null) {
                                widget.onToggleComplete!(!widget.task.isCompleted);
                                Navigator.of(context).pop();
                              }
                            },
                            child: Icon(
                              widget.task.isCompleted ? Icons.check_circle : Icons.radio_button_unchecked,
                              color: widget.task.isCompleted ? Colors.green : Colors.grey,
                              size: 32,
                            ),
                          ),
                          const SizedBox(width: 12),
                          PriorityChip(priority: widget.task.priority),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          TextButton(
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.blueAccent,
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            onPressed: () => Navigator.of(context).pop(),
                            child: const Text('Close'),
                          ),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: widget.task.isCompleted ? Colors.orange : Colors.green,
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            onPressed: () {
                              if (widget.onToggleComplete != null) {
                                widget.onToggleComplete!(!widget.task.isCompleted);
                                Navigator.of(context).pop();
                              }
                            },
                            child: Text(widget.task.isCompleted ? 'Mark Incomplete' : 'Mark Complete'),
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
}
