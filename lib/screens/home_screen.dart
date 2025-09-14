// lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:task_tracker/models/task.dart';
import 'package:task_tracker/utils/color_utils.dart';
import 'package:task_tracker/widgets/animated_card.dart';
import 'package:task_tracker/utils/design_system.dart';

class HomeScreen extends StatefulWidget {
  final List<Task> tasks;
  final bool isLoading;
  final Function() onTasksChanged;
  final Function(Task) onTaskTap;
  final Function() onAddTask;

  const HomeScreen({
    super.key,
    required this.tasks,
    required this.isLoading,
    required this.onTasksChanged,
    required this.onTaskTap,
    required this.onAddTask,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late AnimationController _headerAnimationController;
  late AnimationController _statsAnimationController;
  late Animation<double> _statsCounterAnimation;

  @override
  void initState() {
    super.initState();
    _headerAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _statsAnimationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _statsCounterAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _statsAnimationController,
      curve: Curves.easeInOut,
    ));

    // Start animations with delays
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) _headerAnimationController.forward();
    });
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) _statsAnimationController.forward();
    });
  }

  @override
  void dispose() {
    _headerAnimationController.dispose();
    _statsAnimationController.dispose();
    super.dispose();
  }

  int get totalTasks => widget.tasks.length;

  int get completedTasks => widget.tasks.where((task) => task.isCompleted).length;

  int get pendingTasks => totalTasks - completedTasks;

  double get completionRate => totalTasks > 0 ? (completedTasks / totalTasks) : 0.0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: widget.isLoading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: () async => widget.onTasksChanged(),
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(theme),
                      const SizedBox(height: 24),
                      _buildStatsOverview(theme),
                      const SizedBox(height: 24),
                      _buildTaskList(theme),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: widget.onAddTask,
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.add, size: 28),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Welcome back!',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Your Tasks Overview',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ],
        ),
        _buildProfileButton(theme),
      ],
    );
  }

  Widget _buildProfileButton(ThemeData theme) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        Icons.person_outline,
        color: theme.colorScheme.onSurface,
      ),
    );
  }

  Widget _buildStatsOverview(ThemeData theme) {
    return AnimatedBuilder(
      animation: _statsCounterAnimation,
      builder: (context, child) {
        final animatedTotal = (totalTasks * _statsCounterAnimation.value).round();
        final animatedCompleted = (completedTasks * _statsCounterAnimation.value).round();

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                theme.colorScheme.primaryContainer,
                theme.colorScheme.secondaryContainer,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: ColorUtils.withOpacity(theme.colorScheme.shadow, 0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Performance Analytics',
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: ColorUtils.withOpacity(AppColors.success, 0.2),
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                    ),
                    child: Text(
                      'This Week',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.success,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),

              // Progress Ring
              Center(
                child: SizedBox(
                  width: 120,
                  height: 120,
                  child: Stack(
                    children: [
                      CircularProgressIndicator(
                        value: 1.0,
                        strokeWidth: 12,
                        color: theme.colorScheme.outline,
                      ),
                      CircularProgressIndicator(
                        value: completionRate * _statsCounterAnimation.value,
                        strokeWidth: 12,
                        color: AppColors.success,
                      ),
                      Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '${(completionRate * 100 * _statsCounterAnimation.value).round()}%',
                              style: GoogleFonts.poppins(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.onSurface,
                              ),
                            ),
                            Text(
                              'Complete',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: AppSpacing.xl),

              // Stats Grid
              Row(
                children: [
                  Expanded(
                    child: _buildStatItem(
                      theme: theme,
                      value: animatedTotal.toString(),
                      label: 'Total',
                      icon: Icons.assignment_outlined,
                      color: AppColors.info,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: _buildStatItem(
                      theme: theme,
                      value: animatedCompleted.toString(),
                      label: 'Completed',
                      icon: Icons.check_circle_outline,
                      color: AppColors.success,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: _buildStatItem(
                      theme: theme,
                      value: (animatedTotal - animatedCompleted).toString(),
                      label: 'Pending',
                      icon: Icons.schedule_outlined,
                      color: AppColors.warning,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatItem({
    required ThemeData theme,
    required String value,
    required String label,
    required IconData icon,
    required Color color,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: ColorUtils.withOpacity(color, 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildTaskList(ThemeData theme) {
    if (widget.tasks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.task_alt_outlined,
              size: 64,
              color: ColorUtils.withOpacity(theme.colorScheme.outline, 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No tasks yet!',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tap the + button to create your first task',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.outline,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recent Tasks',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 16),
        ...widget.tasks.take(5).map((task) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: AnimatedCard(
                onTap: () => widget.onTaskTap(task),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  leading: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: task.isCompleted
                          ? theme.colorScheme.primaryContainer
                          : theme.colorScheme.surfaceContainerHighest,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      task.isCompleted ? Icons.check_circle : Icons.circle_outlined,
                      color: task.isCompleted
                          ? theme.colorScheme.primary
                          : theme.colorScheme.outline,
                    ),
                  ),
                  title: Text(
                    task.title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      decoration: task.isCompleted
                          ? TextDecoration.lineThrough
                          : null,
                      color: task.isCompleted
                          ? theme.colorScheme.onSurfaceVariant
                          : theme.colorScheme.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: task.dueDate != null
                      ? Text(
                          'Due: ${task.dueDate.toString().substring(0, 10)}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.outline,
                          ),
                        )
                      : null,
                  trailing: Icon(
                    Icons.chevron_right_rounded,
                    color: theme.colorScheme.outline,
                  ),
                ),
              ),
            )),
        if (widget.tasks.length > 5)
          Center(
            child: TextButton(
              onPressed: () {
                // Navigate to all tasks
              },
              child: const Text('View All Tasks'),
            ),
          ),
      ],
    );
  }
}
