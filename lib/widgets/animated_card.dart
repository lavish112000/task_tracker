// lib/widgets/animated_card.dart
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:task_tracker/utils/animations.dart';
import 'package:task_tracker/utils/color_utils.dart';
import 'package:task_tracker/utils/design_system.dart';
import 'package:task_tracker/widgets/glass_container.dart';

class AnimatedCard extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double? width;
  final double? height;
  final bool enableHover;
  final Duration? animationDelay;
  final Color? backgroundColor;
  final List<BoxShadow>? boxShadow;
  final BorderRadius? borderRadius;
  final bool useGlass;
  final bool enableFlutterAnimate;

  const AnimatedCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding,
    this.margin,
    this.width,
    this.height,
    this.enableHover = true,
    this.animationDelay,
    this.backgroundColor,
    this.boxShadow,
    this.borderRadius,
    this.useGlass = false,
    this.enableFlutterAnimate = true,
  });

  @override
  State<AnimatedCard> createState() => _AnimatedCardState();
}

class _AnimatedCardState extends State<AnimatedCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _hoverController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _elevationAnimation;

  @override
  void initState() {
    super.initState();
    _hoverController = AnimationController(
      duration: AppAnimations.ultraFast,
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.02,
    ).animate(CurvedAnimation(
      parent: _hoverController,
      curve: AppAnimations.enterpriseCurve,
    ));

    _elevationAnimation = Tween<double>(
      begin: 4.0,
      end: 12.0,
    ).animate(CurvedAnimation(
      parent: _hoverController,
      curve: AppAnimations.enterpriseCurve,
    ));
  }

  @override
  void dispose() {
    _hoverController.dispose();
    super.dispose();
  }

  void _onHover(bool isHovered) {
    if (!widget.enableHover) return;

    if (isHovered) {
      _hoverController.forward();
    } else {
      _hoverController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Widget cardContent = widget.useGlass
        ? GlassContainer(
            width: widget.width,
            height: widget.height,
            padding: widget.padding ?? const EdgeInsets.all(AppSpacing.md),
            margin: widget.margin,
            borderRadius: widget.borderRadius,
            child: widget.child,
          )
        : AnimatedBuilder(
            animation: _elevationAnimation,
            builder: (context, child) {
              return Container(
                width: widget.width,
                height: widget.height,
                margin: widget.margin,
                decoration: BoxDecoration(
                  color: widget.backgroundColor ??
                         (isDark ? AppColors.darkSurface : AppColors.lightSurface),
                  borderRadius: widget.borderRadius ??
                                BorderRadius.circular(AppRadius.lg),
                  boxShadow: widget.boxShadow ?? [
                    BoxShadow(
                      color: ColorUtils.withOpacity(Colors.black, isDark ? 0.3 : 0.1),
                      blurRadius: _elevationAnimation.value,
                      offset: Offset(0, _elevationAnimation.value / 3),
                    ),
                  ],
                ),
                padding: widget.padding ?? const EdgeInsets.all(AppSpacing.md),
                child: widget.child,
              );
            },
          );

    Widget finalWidget = MouseRegion(
      onEnter: (_) => _onHover(true),
      onExit: (_) => _onHover(false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedBuilder(
          animation: _scaleAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: cardContent,
            );
          },
        ),
      ),
    );

    // Only apply flutter_animate effects if enabled
    if (widget.enableFlutterAnimate) {
      return finalWidget.animate(effects: AppAnimations.premiumFadeIn(
        delay: widget.animationDelay,
      ));
    }

    return finalWidget;
  }
}
