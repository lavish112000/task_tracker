import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:task_tracker/models/priority.dart';
import 'package:task_tracker/models/priority_box.dart';
import 'package:task_tracker/models/task.dart';
import 'package:task_tracker/widgets/task_card.dart';
import 'package:task_tracker/widgets/task_details_dialog.dart';
import 'package:task_tracker/utils/animations.dart';
import 'package:task_tracker/utils/design_system.dart';
import 'package:task_tracker/widgets/glass_container.dart';
import 'package:task_tracker/widgets/animated_button.dart';
import 'package:task_tracker/widgets/animated_card.dart';

class TaskListScreen extends StatefulWidget {
  final PriorityBox box;
  final VoidCallback onBack;

  const TaskListScreen({super.key, required this.box, required this.onBack});

  @override
  State<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> with TickerProviderStateMixin {
  late AnimationController _headerAnimationController;
  late Animation<double> _headerSlideAnimation;

  @override
  void initState() {
    super.initState();
    _headerAnimationController = AnimationController(
      duration: AppAnimations.medium,
      vsync: this,
    );

    _headerSlideAnimation = Tween<double>(
      begin: -50.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _headerAnimationController,
      curve: AppAnimations.smoothCurve,
    ));

    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) _headerAnimationController.forward();
    });
  }

  @override
  void dispose() {
    _headerAnimationController.dispose();
    super.dispose();
  }

  void _showTaskDetails(Task task) {
    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.6),
      builder: (context) => TaskDetailsDialog(
        task: task,
        onEdit: () {
          Navigator.of(context).pop();
          // Add edit functionality here if needed
        },
        onToggleComplete: (isCompleted) {
          setState(() {
            final index = widget.box.tasks.indexWhere((t) => t.id == task.id);
            if (index != -1) {
              widget.box.tasks[index] = task.copyWith(isCompleted: isCompleted);
            }
          });
        },
        onDelete: () {
          setState(() {
            widget.box.tasks.removeWhere((t) => t.id == task.id);
          });
        },
      ),
    );
  }

  void _showAddTaskDialog() {
    final titleController = TextEditingController();
    DateTime? selectedDate;
    Priority selectedPriority = Priority.medium;

    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.6),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final isDark = Theme.of(context).brightness == Brightness.dark;

            return Dialog(
              backgroundColor: Colors.transparent,
              child: GlassContainer(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Add New Task',
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: isDark ? AppColors.darkOnSurface : AppColors.lightOnSurface,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    TextField(
                      controller: titleController,
                      decoration: InputDecoration(
                        labelText: 'Task Name',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppRadius.md),
                        ),
                      ),
                      autofocus: true,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    DropdownButtonFormField<Priority>(
                      value: selectedPriority,
                      decoration: InputDecoration(
                        labelText: 'Priority',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppRadius.md),
                        ),
                      ),
                      items: Priority.values.map((priority) {
                        return DropdownMenuItem(
                          value: priority,
                          child: Text(priority.name.toUpperCase()),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setDialogState(() {
                          selectedPriority = value!;
                        });
                      },
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            selectedDate == null
                                ? 'No due date'
                                : 'Due: ${DateFormat.yMd().format(selectedDate!)}',
                            style: GoogleFonts.poppins(fontSize: 14),
                          ),
                        ),
                        AnimatedButton(
                          text: 'Set Date',
                          onPressed: () async {
                            final date = await showDatePicker(
                              context: context,
                              initialDate: DateTime.now(),
                              firstDate: DateTime.now(),
                              lastDate: DateTime.now().add(const Duration(days: 365)),
                            );
                            if (date != null) {
                              setDialogState(() {
                                selectedDate = date;
                              });
                            }
                          },
                          variant: ButtonVariant.ghost,
                          size: ButtonSize.small,
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    Row(
                      children: [
                        Expanded(
                          child: AnimatedButton(
                            text: 'Cancel',
                            onPressed: () => Navigator.pop(context),
                            variant: ButtonVariant.ghost,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: AnimatedButton(
                            text: 'Add Task',
                            onPressed: () {
                              if (titleController.text.trim().isNotEmpty) {
                                final newTask = Task(
                                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                                  title: titleController.text.trim(),
                                  description: '', // Add required description parameter
                                  priority: selectedPriority,
                                  isCompleted: false,
                                  dueDate: selectedDate ?? DateTime.now().add(const Duration(days: 1)), // Fix nullable dueDate
                                );

                                setState(() {
                                  widget.box.tasks.add(newTask);
                                });

                                Navigator.pop(context);
                              }
                            },
                            variant: ButtonVariant.primary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      body: Container(
        decoration: BoxDecoration(
          gradient: isDark ? AppColors.darkSurfaceGradient : AppColors.surfaceGradient,
        ),
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            _buildAnimatedAppBar(isDark),
            SliverPadding(
              padding: const EdgeInsets.all(AppSpacing.md),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    if (index >= widget.box.tasks.length) return null;
                    final task = widget.box.tasks[index];

                    return AnimatedCard(
                      useGlass: true,
                      margin: const EdgeInsets.only(bottom: AppSpacing.md),
                      animationDelay: AppAnimations.staggerDelay(index),
                      enableFlutterAnimate: false, // Disable flutter_animate for Sliver compatibility
                      child: GestureDetector(
                        onTap: () => _showTaskDetails(task),
                        child: TaskCard(
                          task: task,
                          onToggleComplete: (isCompleted) {
                            setState(() {
                              final updatedTask = task.copyWith(isCompleted: isCompleted);
                              final taskIndex = widget.box.tasks.indexWhere((t) => t.id == updatedTask.id);
                              if (taskIndex != -1) {
                                widget.box.tasks[taskIndex] = updatedTask;
                              }
                            });
                          },
                          onEdit: () => _showTaskDetails(task),
                          onDelete: () {
                            setState(() {
                              widget.box.tasks.removeWhere((t) => t.id == task.id);
                            });
                          },
                        ),
                      ),
                    );
                  },
                  childCount: widget.box.tasks.length,
                ),
              ),
            ),
            const SliverToBoxAdapter(
              child: SizedBox(height: 120), // Bottom padding for navigation
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddTaskDialog,
        backgroundColor: isDark ? AppColors.primaryLight : AppColors.primaryBlue,
        foregroundColor: isDark ? Colors.black : Colors.white,
        icon: const Icon(Icons.add),
        label: Text(
          'Add Task',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
      ).animate(effects: AppAnimations.fabAnimation(
        delay: const Duration(milliseconds: 800),
      )),
    );
  }

  Widget _buildAnimatedAppBar(bool isDark) {
    return SliverAppBar(
      expandedHeight: 140,
      floating: true,
      pinned: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: IconButton(
        onPressed: widget.onBack, // This ensures back navigation works
        icon: Icon(
          Icons.arrow_back_rounded,
          color: isDark ? AppColors.darkOnSurface : AppColors.lightOnSurface,
        ),
      ),
      flexibleSpace: AnimatedBuilder(
        animation: _headerSlideAnimation,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(0, _headerSlideAnimation.value),
            child: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: isDark ? AppColors.darkSurfaceGradient : AppColors.surfaceGradient,
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Row(
                          children: [
                            const SizedBox(width: 56), // Space for back button
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    widget.box.name,
                                    style: GoogleFonts.poppins(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: isDark ? AppColors.darkOnSurface : AppColors.lightOnSurface,
                                    ),
                                  ),
                                  Text(
                                    '${widget.box.tasks.length} tasks • ${widget.box.completedTasksCount} completed',
                                    style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      color: isDark ? AppColors.darkOnSurfaceVariant : AppColors.lightOnSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              width: 8,
                              height: 40,
                              decoration: BoxDecoration(
                                color: widget.box.color,
                                borderRadius: BorderRadius.circular(AppRadius.sm),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    ).animate(effects: AppAnimations.premiumFadeIn());
  }
}
