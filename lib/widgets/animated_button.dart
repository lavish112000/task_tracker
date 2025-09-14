// lib/widgets/animated_button.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:task_tracker/utils/animations.dart';
import 'package:task_tracker/utils/design_system.dart';
import 'package:task_tracker/utils/color_utils.dart';

enum ButtonVariant { primary, secondary, ghost, danger }
enum ButtonSize { small, medium, large }

class AnimatedButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final IconData? icon;
  final ButtonVariant variant;
  final ButtonSize size;
  final bool isLoading;
  final bool isExpanded;
  final Color? customColor;
  final Duration? animationDelay;

  const AnimatedButton({
    super.key,
    required this.text,
    this.onPressed,
    this.icon,
    this.variant = ButtonVariant.primary,
    this.size = ButtonSize.medium,
    this.isLoading = false,
    this.isExpanded = false,
    this.customColor,
    this.animationDelay,
  });

  @override
  State<AnimatedButton> createState() => _AnimatedButtonState();
}

class _AnimatedButtonState extends State<AnimatedButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: AppAnimations.ultraFast,
      vsync: this,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  EdgeInsets get _padding {
    switch (widget.size) {
      case ButtonSize.small:
        return const EdgeInsets.symmetric(horizontal: 16, vertical: 8);
      case ButtonSize.medium:
        return const EdgeInsets.symmetric(horizontal: 24, vertical: 12);
      case ButtonSize.large:
        return const EdgeInsets.symmetric(horizontal: 32, vertical: 16);
    }
  }

  double get _fontSize {
    switch (widget.size) {
      case ButtonSize.small:
        return 14;
      case ButtonSize.medium:
        return 16;
      case ButtonSize.large:
        return 18;
    }
  }

  Color _getBackgroundColor(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (widget.customColor != null) return widget.customColor!;

    switch (widget.variant) {
      case ButtonVariant.primary:
        return isDark ? AppColors.primaryLight : AppColors.primaryBlue;
      case ButtonVariant.secondary:
        return isDark ? AppColors.darkSurfaceVariant : AppColors.lightSurfaceVariant;
      case ButtonVariant.ghost:
        return Colors.transparent;
      case ButtonVariant.danger:
        return AppColors.error;
    }
  }

  Color _getTextColor(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    switch (widget.variant) {
      case ButtonVariant.primary:
        return isDark ? Colors.black : Colors.white;
      case ButtonVariant.secondary:
        return isDark ? AppColors.darkOnSurface : AppColors.lightOnSurface;
      case ButtonVariant.ghost:
        return isDark ? AppColors.primaryLight : AppColors.primaryBlue;
      case ButtonVariant.danger:
        return Colors.white;
    }
  }

  void _onTapDown(TapDownDetails details) {
    setState(() => _isPressed = true);
    _controller.forward();
    HapticFeedback.lightImpact();
  }

  void _onTapUp(TapUpDetails details) {
    setState(() => _isPressed = false);
    _controller.reverse();
  }

  void _onTapCancel() {
    setState(() => _isPressed = false);
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final backgroundColor = _getBackgroundColor(context);
    final textColor = _getTextColor(context);

    return GestureDetector(
      onTapDown: widget.onPressed != null ? _onTapDown : null,
      onTapUp: widget.onPressed != null ? _onTapUp : null,
      onTapCancel: _onTapCancel,
      onTap: widget.onPressed,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final scale = 1.0 - (_controller.value * 0.05);

          return Transform.scale(
            scale: scale,
            child: Container(
              width: widget.isExpanded ? double.infinity : null,
              padding: _padding,
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: widget.variant == ButtonVariant.ghost
                    ? Border.all(color: ColorUtils.withOpacity(textColor, 0.3))
                    : null,
                boxShadow: widget.variant != ButtonVariant.ghost
                    ? [
                        BoxShadow(
                          color: ColorUtils.withOpacity(backgroundColor, 0.3),
                          blurRadius: _isPressed ? 8 : 16,
                          offset: Offset(0, _isPressed ? 2 : 4),
                        ),
                      ]
                    : null,
              ),
              child: widget.isLoading
                  ? SizedBox(
                      height: _fontSize + 4,
                      width: _fontSize + 4,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(textColor),
                      ),
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (widget.icon != null) ...[
                          Icon(
                            widget.icon,
                            color: textColor,
                            size: _fontSize + 2,
                          ),
                          const SizedBox(width: AppSpacing.sm),
                        ],
                        Text(
                          widget.text,
                          style: GoogleFonts.poppins(
                            color: textColor,
                            fontSize: _fontSize,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
            ),
          );
        },
      ),
    ).animate(effects: AppAnimations.premiumFadeIn(
      delay: widget.animationDelay,
    ));
  }
}
