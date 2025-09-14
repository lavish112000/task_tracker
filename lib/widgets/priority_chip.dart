import 'package:flutter/material.dart';
import 'package:task_tracker/models/priority.dart';
import 'package:task_tracker/utils/app_colors.dart';
import 'package:task_tracker/utils/color_utils.dart';

class PriorityChip extends StatelessWidget {
  final Priority priority;
  final bool small;

  const PriorityChip({
    super.key,
    required this.priority,
    this.small = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = _getPriorityColor();
    final text = _getPriorityText();
    final icon = _getPriorityIcon();

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: small ? 8 : 10,
        vertical: small ? 3 : 5,
      ),
      decoration: BoxDecoration(
        color: ColorUtils.withOpacity(color, 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: small ? 12 : 14,
            color: color,
          ),
          if (!small) const SizedBox(width: 4),
          if (!small)
            Text(
              text,
              style: theme.textTheme.labelSmall?.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
        ],
      ),
    );
  }

  Color _getPriorityColor() {
    switch (priority) {
      case Priority.urgent:
        return Colors.red.shade800; // Dark red for urgent
      case Priority.high:
        return AppColors.errorColor;
      case Priority.medium:
        return AppColors.warningColor;
      case Priority.low:
        return AppColors.successColor;
    }
  }

  String _getPriorityText() {
    switch (priority) {
      case Priority.urgent:
        return 'Urgent';
      case Priority.high:
        return 'High';
      case Priority.medium:
        return 'Medium';
      case Priority.low:
        return 'Low';
    }
  }

  IconData _getPriorityIcon() {
    switch (priority) {
      case Priority.urgent:
        return Icons.priority_high_rounded;
      case Priority.high:
        return Icons.keyboard_arrow_up_rounded;
      case Priority.medium:
        return Icons.remove_rounded;
      case Priority.low:
        return Icons.keyboard_arrow_down_rounded;
    }
  }
}
