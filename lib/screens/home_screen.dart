// lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:task_tracker/models/task.dart';
import 'package:task_tracker/utils/color_utils.dart';
import 'package:task_tracker/widgets/animated_card.dart';
import 'package:task_tracker/widgets/glass_container.dart';
import 'package:task_tracker/utils/design_system.dart';
import 'package:task_tracker/services/task_service.dart';
import 'package:task_tracker/screens/pomodoro_screen.dart';
import 'package:task_tracker/screens/dashboard_screen.dart';
import 'package:task_tracker/screens/mind_map_screen.dart';
import 'package:task_tracker/screens/automation_rules_screen.dart';
import 'package:task_tracker/widgets/hover_wrapper.dart';

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
  final TaskService _taskService = TaskService();
  bool _addingNlTask = false;
  bool _showOnboarding = false;

  int get totalTasks => widget.tasks.length;

  int get completedTasks => widget.tasks.where((task) => task.isCompleted).length;

  int get pendingTasks => totalTasks - completedTasks;

  double get completionRate => totalTasks > 0 ? (completedTasks / totalTasks) : 0.0;

  int get totalXP => widget.tasks.fold(0, (p, t) => p + t.rewardPoints);
  int get maxStreak => widget.tasks.fold(0, (p, t) => t.streakCount > p ? t.streakCount : p);

  int get level => 1 + (totalXP ~/ 250);

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
    _loadOnboardingFlag();
  }

  Future<void> _loadOnboardingFlag() async {
    final prefs = await SharedPreferences.getInstance();
    final dismissed = prefs.getBool('onboarding_dismissed') ?? false;
    if (mounted) setState(()=> _showOnboarding = !dismissed);
  }

  Future<void> _dismissOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_dismissed', true);
    if (mounted) setState(()=> _showOnboarding = false);
  }

  @override
  void dispose() {
    _headerAnimationController.dispose();
    _statsAnimationController.dispose();
    super.dispose();
  }

  Future<void> _showNaturalLanguageAdd() async {
    if (_addingNlTask) return; // debounce
    final controller = TextEditingController();
    final result = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.auto_awesome, color: Colors.amber),
                  const SizedBox(width: 8),
                  Text('Natural Language Task', style: Theme.of(ctx).textTheme.titleMedium),
                  const Spacer(),
                  IconButton(onPressed: () => Navigator.pop(ctx), icon: const Icon(Icons.close)),
                ],
              ),
              const SizedBox(height: 8),
              TextField(
                controller: controller,
                autofocus: true,
                textInputAction: TextInputAction.done,
                decoration: const InputDecoration(
                  hintText: "e.g. 'Remind me to call John tomorrow at 5 PM'",
                  border: OutlineInputBorder(),
                ),
                onSubmitted: (v) => Navigator.pop(ctx, v.trim()),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                children: [
                  _suggestionChip("Plan sprint review Friday 10 AM"),
                  _suggestionChip("Pay electricity bill tomorrow 9 AM"),
                  _suggestionChip("Follow up with Sarah next Monday 2 PM"),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.pop(ctx, controller.text.trim()),
                  icon: const Icon(Icons.add_task),
                  label: const Text('Add Task'),
                ),
              ),
            ],
          ),
        );
      },
    );
    if (result != null && result.isNotEmpty) {
      setState(() => _addingNlTask = true);
      try {
        await _taskService.addTaskFromNaturalLanguage(result);
        await widget.onTasksChanged();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Task added: ${result.length > 40 ? result.substring(0,40)+'…' : result}')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to parse: $e')),
          );
        }
      } finally {
        if (mounted) setState(() => _addingNlTask = false);
      }
    }
  }

  Widget _suggestionChip(String text) => ActionChip(
        label: Text(text, maxLines: 1, overflow: TextOverflow.ellipsis),
        onPressed: () => Navigator.pop(context, text),
      );

  Widget _buildGamificationBar(ThemeData theme) {
    final badges = <Widget>[];
    if (totalXP >= 100) { badges.add(_badge(theme, 'Rookie')); }
    if (totalXP >= 500) { badges.add(_badge(theme, 'Achiever')); }
    if (maxStreak >= 5) { badges.add(_badge(theme, 'Streak 5')); }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      margin: const EdgeInsets.only(top: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: [theme.colorScheme.primaryContainer, theme.colorScheme.secondaryContainer],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.stars_rounded, color: Colors.amber, size: 32),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Progress & Streak', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text('XP: $totalXP  •  Level: $level  •  Max Streak: $maxStreak', style: theme.textTheme.bodySmall),
                if (badges.isNotEmpty) Padding(
                  padding: const EdgeInsets.only(top:4.0),
                  child: Wrap(spacing:6, runSpacing:4, children: badges),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: _showNaturalLanguageAdd,
            style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10)),
            child: Row(children: [
              if (_addingNlTask) const SizedBox(height:16,width:16,child: CircularProgressIndicator(strokeWidth:2)),
              if (_addingNlTask) const SizedBox(width:8),
              const Icon(Icons.auto_fix_high, size: 18),
              const SizedBox(width: 6),
              Text(_addingNlTask ? 'Adding...' : 'NL Add'),
            ]),
          )
        ],
      ),
    );
  }
  Widget _badge(ThemeData theme, String label) => Container(
    padding: const EdgeInsets.symmetric(horizontal:8, vertical:4),
    decoration: BoxDecoration(
      color: theme.colorScheme.secondaryContainer.withOpacity(.6),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Text(label, style: theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w600)),
  );
  Widget _buildQuickActions(ThemeData theme) {
    final actions = <_QuickAction>[
      _QuickAction(icon: Icons.timer, label: 'Pomodoro', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PomodoroScreen()))),
      _QuickAction(icon: Icons.dashboard_customize, label: 'Dashboard', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DashboardScreen()))),
      _QuickAction(icon: Icons.account_tree, label: 'Mind Map', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MindMapScreen()))),
      _QuickAction(icon: Icons.smart_toy, label: 'Automation', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AutomationRulesScreen()))),
    ];
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: SizedBox(
        height: 84,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: actions.length,
          separatorBuilder: (_, __) => const SizedBox(width: 12),
          itemBuilder: (ctx, i) {
            final a = actions[i];
            return HoverWrapper(
              onTap: a.onTap,
              padding: const EdgeInsets.all(12),
              child: SizedBox(
                width: 120,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(a.icon, color: theme.colorScheme.primary),
                    const Spacer(),
                    Text(a.label, style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

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
                      if (_showOnboarding) _onboardingBanner(theme),
                      _buildHeader(theme),
                      _buildQuickActions(theme),
                      _buildGamificationBar(theme),
                      const SizedBox(height: 16),
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
  Widget _onboardingBanner(ThemeData theme) => HoverWrapper(
    onTap: _dismissOnboarding,
    padding: const EdgeInsets.all(16),
    child: Row(
      children: [
        const Icon(Icons.rocket_launch, color: Colors.deepPurple),
        const SizedBox(width:12),
        Expanded(child: Text('Welcome! Explore Dashboard, Focus, Mind Map & Automation via bottom nav.', style: theme.textTheme.bodySmall)),
        TextButton(onPressed: _dismissOnboarding, child: const Text('Dismiss')),
      ],
    ),
  );
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
    bool isDark = false,
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
              child: HoverWrapper(
                onTap: () => widget.onTaskTap(task),
                padding: EdgeInsets.zero,
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  leading: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: task.isCompleted ? theme.colorScheme.primaryContainer : theme.colorScheme.surfaceContainerHighest,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      task.isCompleted ? Icons.check_circle : Icons.circle_outlined,
                      color: task.isCompleted ? theme.colorScheme.primary : theme.colorScheme.outline,
                    ),
                  ),
                  title: Text(
                    task.title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                      color: task.isCompleted ? theme.colorScheme.onSurfaceVariant : theme.colorScheme.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    'Due: ${task.dueDate.toString().substring(0, 10)}',
                    style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline),
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded),
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

class _QuickAction {
  final IconData icon; final String label; final VoidCallback onTap;
  _QuickAction({required this.icon, required this.label, required this.onTap});
}
