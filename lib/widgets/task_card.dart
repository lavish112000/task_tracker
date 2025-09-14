import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:task_tracker/models/priority.dart';
import 'package:task_tracker/models/task.dart';
import 'package:task_tracker/theme/app_theme.dart';
import 'package:task_tracker/utils/app_colors.dart';
import 'package:task_tracker/utils/color_utils.dart';
import 'package:task_tracker/utils/date_utils.dart' as date_utils;
import 'package:task_tracker/widgets/priority_chip.dart';
import 'package:task_tracker/widgets/task_details_dialog.dart';

class TaskCard extends StatefulWidget {
  final Task task;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final ValueChanged<bool>? onToggleComplete;
  final bool isFirstItem;
  final bool isLastItem;
  final bool showDivider;

  const TaskCard({
    super.key,
    required this.task,
    this.onEdit,
    this.onDelete,
    this.onToggleComplete,
    this.isFirstItem = false,
    this.isLastItem = false,
    this.showDivider = true,
  });

  @override
  State<TaskCard> createState() => _TaskCardState();
}

class _TaskCardState extends State<TaskCard> with TickerProviderStateMixin {
  static const _kAnimationDuration = Duration(milliseconds: 300);
  
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;
  late AnimationController _checkAnimationController;
  late Animation<double> _checkAnimation;
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;
  late AnimationController _borderRadiusController;
  late Animation<double> _borderRadiusAnimation;
  
  bool _isSwiping = false;
  double _dragExtent = 0.0;
  final double _swipeThreshold = 0.3;
  
  @override
  void initState() {
    super.initState();
    
    // Scale animation for tap effect
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.98,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.easeInOut,
    ));
    
    // Checkmark animation
    _checkAnimationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    
    _checkAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _checkAnimationController,
      curve: Curves.easeInOut,
    ));
    
    // Slide animation for swipe actions
    _slideController = AnimationController(
      duration: _kAnimationDuration,
      vsync: this,
    );
    
    _slideAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(-0.5, 0.0), // Reduced from -1.0 to -0.5 for less aggressive slide
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutQuart,
    ));
    
    // Border radius animation for swipe
    _borderRadiusController = AnimationController(
      duration: _kAnimationDuration,
      vsync: this,
    );
    
    _borderRadiusAnimation = Tween<double>(
      begin: 12.0,
      end: 8.0,
    ).animate(CurvedAnimation(
      parent: _borderRadiusController,
      curve: Curves.easeInOut,
    ));
    
    // Initialize checkmark state
    if (widget.task.isCompleted) {
      _checkAnimationController.value = 1.0;
    }
  }
  
  @override
  void didUpdateWidget(TaskCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.task.isCompleted != widget.task.isCompleted) {
      if (widget.task.isCompleted) {
        _checkAnimationController.forward();
      } else {
        _checkAnimationController.reverse();
      }
    }
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _checkAnimationController.dispose();
    _slideController.dispose();
    _borderRadiusController.dispose();
    super.dispose();
  }
  
  void _onHorizontalDragStart(DragStartDetails details) {
    _isSwiping = true;
  }
  
  void _onHorizontalDragUpdate(DragUpdateDetails details) {
    if (!_isSwiping) return;
    
    final dragDistance = details.primaryDelta ?? 0;
    _dragExtent += dragDistance;
    
    _dragExtent = _dragExtent.clamp(0.0, context.size!.width * 0.7);
    
    // Calculate progress for animations
    final maxDrag = context.size!.width * _swipeThreshold;
    final progress = (_dragExtent / maxDrag).clamp(0.0, 1.0);
    
    _borderRadiusController.value = progress;
    _slideController.value = progress * 0.5; // Only slide up to 50% of the width
  }
  
  Future<void> _onHorizontalDragEnd(DragEndDetails details) async {
    if (!_isSwiping) return;
    
    final maxDrag = context.size!.width * _swipeThreshold;
    final shouldComplete = _dragExtent > maxDrag * 0.5;
    
    if (shouldComplete && widget.onToggleComplete != null) {
      HapticFeedback.mediumImpact();
      await _slideController.animateTo(1.0, duration: _kAnimationDuration);
      widget.onToggleComplete!(!widget.task.isCompleted);
      await Future.delayed(const Duration(milliseconds: 100));
      _slideController.value = 0.0;
    } else {
      await _slideController.animateBack(0.0, duration: _kAnimationDuration);
    }
    
    _isSwiping = false;
    _dragExtent = 0.0;
    _borderRadiusController.reverse();
  }

  void _onTapDown(TapDownDetails details) {
    _scaleController.forward();
  }

  void _onTapUp(TapUpDetails details) {
    _scaleController.reverse();
  }

  void _onTapCancel() {
    _scaleController.reverse();
  }

  void _showTaskDetails() {
    TaskDetailsDialog.show(
      context,
      widget.task,
      onEdit: widget.onEdit,
      onDelete: widget.onDelete,
      onToggleComplete: widget.onToggleComplete,
    );
  }

  Widget _buildTaskCard() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final dueInDays = widget.task.dueDate.difference(DateTime.now()).inDays;
    
    return Material(
      color: isDark ? AppColors.surfaceColorDark : Colors.white,
      elevation: 2,
      borderRadius: BorderRadius.circular(_borderRadiusAnimation.value),
      child: InkWell(
        borderRadius: BorderRadius.circular(_borderRadiusAnimation.value),
        onTap: _showTaskDetails,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(_borderRadiusAnimation.value),
            border: Border.all(
              color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with priority and due date
              Row(
                children: [
                  // Priority chip
                  PriorityChip(priority: widget.task.priority),
                  
                  const Spacer(),
                  
                  // Due date
                  if (!widget.task.isCompleted && dueInDays <= 7)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: ColorUtils.withOpacity(_getDueDateColor(dueInDays), 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _formatDueDate(dueInDays),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: _getDueDateColor(dueInDays),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // Task title and completion checkbox
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Checkbox with animation
                  AnimatedBuilder(
                    animation: _checkAnimation,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: 1.0 - (_checkAnimation.value * 0.2),
                        child: Checkbox(
                          value: widget.task.isCompleted,
                          onChanged: (value) {
                            if (widget.onToggleComplete != null) {
                              widget.onToggleComplete!(value ?? false);
                            }
                          },
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                          activeColor: AppColors.primaryColor,
                          checkColor: Colors.white,
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      );
                    },
                  ),
                  
                  const SizedBox(width: 8),
                  
                  // Task title and description
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Task title with strike-through when completed
                        AnimatedDefaultTextStyle(
                          duration: const Duration(milliseconds: 200),
                          style: theme.textTheme.titleMedium!.copyWith(
                            color: widget.task.isCompleted
                                ? theme.hintColor
                                : theme.textTheme.titleMedium?.color,
                            decoration: widget.task.isCompleted
                                ? TextDecoration.lineThrough
                                : TextDecoration.none,
                            fontWeight: FontWeight.w600,
                          ),
                          child: Text(widget.task.title),
                        ),
                        
                        if (widget.task.description.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            widget.task.description,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.textTheme.bodySmall?.color,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              
              // Tags
              if (widget.task.tags.isNotEmpty) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: widget.task.tags.map((tag) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: ColorUtils.withOpacity(_getTagColor(tag), 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '#$tag',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: _getTagColor(tag),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
              
              // Completed indicator
              if (widget.task.isCompleted) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(
                      Icons.check_circle_outline,
                      size: 16,
                      color: theme.hintColor,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Completed',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.hintColor,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        _slideAnimation,
        _borderRadiusAnimation,
      ]),
      builder: (context, child) {
        return Padding(
          padding: EdgeInsets.only(
            top: widget.isFirstItem ? 16 : 8,
            bottom: widget.isLastItem ? 16 : 8,
            left: 16,
            right: 16,
          ),
          child: Transform.translate(
            offset: Offset(_slideAnimation.value.dx * context.size!.width, 0),
            child: Transform.scale(
              scale: _scaleAnimation.value,
              child: GestureDetector(
                onTapDown: (_) => _scaleController.forward(),
                onTapUp: (_) {
                  _scaleController.reverse();
                  _showTaskDetails();
                },
                onTapCancel: () => _scaleController.reverse(),
                onHorizontalDragStart: _onHorizontalDragStart,
                onHorizontalDragUpdate: _onHorizontalDragUpdate,
                onHorizontalDragEnd: _onHorizontalDragEnd,
                behavior: HitTestBehavior.opaque,
                child: _buildTaskCard(),
              ),
            ),
          ),
        );
      },
    );
  }

  Color _getDueDateColor(int daysUntilDue) {
    if (daysUntilDue < 0) {
      return Colors.red;
    } else if (daysUntilDue == 0) {
      return Colors.orange;
    } else if (daysUntilDue <= 3) {
      return Colors.yellow.shade700;
    } else {
      return Colors.green;
    }
  }

  String _formatDueDate(int daysUntilDue) {
    if (daysUntilDue < 0) {
      return 'Overdue';
    } else if (daysUntilDue == 0) {
      return 'Due today';
    } else if (daysUntilDue == 1) {
      return 'Due tomorrow';
    } else {
      return 'Due in $daysUntilDue days';
    }
  }

  Color _getTagColor(String tag) {
    final colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.red,
      Colors.teal,
      Colors.indigo,
      Colors.pink,
    ];
    return colors[tag.hashCode % colors.length];
  }
}
