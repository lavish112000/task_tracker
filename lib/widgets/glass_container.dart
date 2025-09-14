// lib/widgets/glass_container.dart
import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:task_tracker/utils/design_system.dart';
import 'package:task_tracker/utils/color_utils.dart';

class GlassContainer extends StatelessWidget {
  final Widget child;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final BorderRadius? borderRadius;
  final double blur;
  final double opacity;
  final Border? border;
  final List<BoxShadow>? boxShadow;

  const GlassContainer({
    super.key,
    required this.child,
    this.width,
    this.height,
    this.padding,
    this.margin,
    this.borderRadius,
    this.blur = 10.0,
    this.opacity = 0.1,
    this.border,
    this.boxShadow,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: width,
      height: height,
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: borderRadius ?? BorderRadius.circular(AppRadius.lg),
        border: border ?? Border.all(
          color: ColorUtils.withOpacity(Colors.white, isDark ? 0.1 : 0.2),
          width: 1,
        ),
        boxShadow: boxShadow ?? AppShadows.medium,
      ),
      child: ClipRRect(
        borderRadius: borderRadius ?? BorderRadius.circular(AppRadius.lg),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  ColorUtils.withOpacity(Colors.white, isDark ? opacity * 0.5 : opacity),
                  ColorUtils.withOpacity(Colors.white, isDark ? opacity * 0.2 : opacity * 0.8),
                ],
              ),
            ),
            padding: padding,
            child: child,
          ),
        ),
      ),
    );
  }
}
