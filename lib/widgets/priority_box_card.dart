// lib/widgets/priority_box_card.dart
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:task_tracker/models/priority_box.dart';
import 'package:task_tracker/utils/animations.dart';
import 'package:task_tracker/utils/design_system.dart';
import 'package:task_tracker/utils/color_utils.dart';

class PriorityBoxCard extends StatefulWidget {
  final PriorityBox box;
  final VoidCallback? onTap;

  const PriorityBoxCard({
    super.key,
    required this.box,
    this.onTap,
  });

  @override
  State<PriorityBoxCard> createState() => _PriorityBoxCardState();
}

class _PriorityBoxCardState extends State<PriorityBoxCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _progressController;
  late Animation<double> _progressAnimation;

  @override
  void initState() {
    super.initState();
    _progressController = AnimationController(
      duration: AppAnimations.slow,
      vsync: this,
    );

    _progressAnimation = Tween<double>(
      begin: 0.0,
      end: widget.box.completionRate,
    ).animate(CurvedAnimation(
      parent: _progressController,
      curve: AppAnimations.elasticCurve,
    ));

    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _progressController.forward();
    });
  }

  @override
  void dispose() {
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final totalTasks = widget.box.tasks.length;

    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              ColorUtils.withOpacity(widget.box.color, isDark ? 0.3 : 0.1),
              ColorUtils.withOpacity(widget.box.color, isDark ? 0.2 : 0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(AppRadius.xl),
          border: Border.all(
            color: ColorUtils.withOpacity(widget.box.color, 0.3),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: ColorUtils.withOpacity(widget.box.color, 0.2),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.all(AppSpacing.md), // Reduced padding
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min, // Important: Don't expand to full height
          children: [
            // Header with icon and menu
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: ColorUtils.withOpacity(widget.box.color, 0.2),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: Icon(
                    _getIconForBox(),
                    color: widget.box.color,
                    size: 20, // Reduced icon size
                  ),
                ),
                Icon(
                  Icons.more_vert_rounded,
                  color: isDark ? AppColors.darkOnSurfaceVariant : AppColors.lightOnSurfaceVariant,
                  size: 18, // Reduced icon size
                ),
              ],
            ),

            const SizedBox(height: AppSpacing.sm), // Reduced spacing

            // Box name
            Flexible(
              child: Text(
                widget.box.name,
                style: GoogleFonts.poppins(
                  fontSize: 14, // Reduced font size
                  fontWeight: FontWeight.bold,
                  color: isDark ? AppColors.darkOnSurface : AppColors.lightOnSurface,
                ),
                maxLines: 1, // Limit to 1 line
                overflow: TextOverflow.ellipsis,
              ),
            ),

            const SizedBox(height: AppSpacing.xs), // Reduced spacing

            // Task count
            Text(
              '$totalTasks ${totalTasks == 1 ? 'task' : 'tasks'}',
              style: GoogleFonts.poppins(
                fontSize: 12, // Reduced font size
                color: isDark ? AppColors.darkOnSurfaceVariant : AppColors.lightOnSurfaceVariant,
              ),
            ),

            const SizedBox(height: AppSpacing.sm), // Added specific spacing instead of Spacer

            // Progress section - made more compact
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Progress',
                      style: GoogleFonts.poppins(
                        fontSize: 11, // Reduced font size
                        color: isDark ? AppColors.darkOnSurfaceVariant : AppColors.lightOnSurfaceVariant,
                      ),
                    ),
                    Text(
                      '${(_progressAnimation.value * 100).round()}%',
                      style: GoogleFonts.poppins(
                        fontSize: 11, // Reduced font size
                        fontWeight: FontWeight.w600,
                        color: widget.box.color,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  child: LinearProgressIndicator(
                    value: _progressAnimation.value,
                    backgroundColor: ColorUtils.withOpacity(widget.box.color, 0.2),
                    valueColor: AlwaysStoppedAnimation<Color>(widget.box.color),
                    minHeight: 4, // Reduced height
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ).animate(effects: AppAnimations.heroCardAnimation());
  }

  IconData _getIconForBox() {
    final name = widget.box.name.toLowerCase();
    if (name.contains('high') || name.contains('urgent')) {
      return Icons.priority_high_rounded;
    } else if (name.contains('medium')) {
      return Icons.schedule_rounded;
    } else if (name.contains('low')) {
      return Icons.low_priority_rounded;
    } else if (name.contains('personal')) {
      return Icons.person_rounded;
    } else if (name.contains('work')) {
      return Icons.work_rounded;
    } else {
      return Icons.folder_rounded;
    }
  }
}
