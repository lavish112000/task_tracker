// lib/utils/animations.dart
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'color_utils.dart';

class AppAnimations {
  // Enterprise-level animation durations
  static const Duration ultraFast = Duration(milliseconds: 150);
  static const Duration fast = Duration(milliseconds: 300);
  static const Duration medium = Duration(milliseconds: 500);
  static const Duration slow = Duration(milliseconds: 800);
  static const Duration ultraSlow = Duration(milliseconds: 1200);

  // Sophisticated easing curves
  static const Curve enterpriseCurve = Curves.easeInOutCubic;
  static const Curve elasticCurve = Curves.elasticOut;
  static const Curve bounceCurve = Curves.bounceOut;
  static const Curve smoothCurve = Curves.easeOutQuart;

  // Stagger delays for list animations
  static Duration staggerDelay(int index) => Duration(milliseconds: 50 * index);

  // Premium fade in animation
  static List<Effect> premiumFadeIn({
    Duration? delay,
    Duration duration = medium,
  }) => [
    FadeEffect(
      delay: delay ?? Duration.zero,
      duration: duration,
      curve: enterpriseCurve,
    ),
    SlideEffect(
      delay: delay ?? Duration.zero,
      duration: duration,
      begin: const Offset(0, 0.3),
      end: Offset.zero,
      curve: enterpriseCurve,
    ),
    ScaleEffect(
      delay: delay ?? Duration.zero,
      duration: duration,
      begin: const Offset(0.8, 0.8),
      end: const Offset(1.0, 1.0),
      curve: enterpriseCurve,
    ),
  ];

  // Hero card animation
  static List<Effect> heroCardAnimation({
    Duration? delay,
    Duration duration = medium,
  }) => [
    FadeEffect(
      delay: delay ?? Duration.zero,
      duration: duration,
    ),
    SlideEffect(
      delay: delay ?? Duration.zero,
      duration: duration,
      begin: const Offset(0, 0.5),
      end: Offset.zero,
      curve: elasticCurve,
    ),
    ScaleEffect(
      delay: delay ?? Duration.zero,
      duration: duration,
      begin: const Offset(0.3, 0.3),
      end: const Offset(1.0, 1.0),
      curve: elasticCurve,
    ),
  ];

  // Floating action button animation
  static List<Effect> fabAnimation({
    Duration? delay,
    Duration duration = fast,
  }) => [
    ScaleEffect(
      delay: delay ?? Duration.zero,
      duration: duration,
      begin: const Offset(0.0, 0.0),
      end: const Offset(1.0, 1.0),
      curve: elasticCurve,
    ),
    RotateEffect(
      delay: delay ?? Duration.zero,
      duration: duration,
      begin: -0.5,
      end: 0.0,
      curve: elasticCurve,
    ),
  ];

  // Shimmer loading effect
  static List<Effect> shimmerEffect({
    Duration duration = const Duration(milliseconds: 1500),
  }) => [
    ShimmerEffect(
      duration: duration,
      color: ColorUtils.withOpacity(Colors.white, 0.3),
    ),
  ];

  // Statistics counter animation
  static List<Effect> counterAnimation({
    Duration? delay,
    Duration duration = slow,
  }) => [
    FadeEffect(
      delay: delay ?? Duration.zero,
      duration: duration,
    ),
    SlideEffect(
      delay: delay ?? Duration.zero,
      duration: duration,
      begin: const Offset(0, 1),
      end: Offset.zero,
      curve: bounceCurve,
    ),
  ];

  // Navigation bar animation
  static List<Effect> navBarAnimation({
    Duration? delay,
    Duration duration = medium,
  }) => [
    SlideEffect(
      delay: delay ?? Duration.zero,
      duration: duration,
      begin: const Offset(0, 1),
      end: Offset.zero,
      curve: smoothCurve,
    ),
    FadeEffect(
      delay: delay ?? Duration.zero,
      duration: duration,
    ),
  ];

  // Card hover animation
  static List<Effect> cardHoverAnimation() => [
    ScaleEffect(
      duration: ultraFast,
      begin: const Offset(1.0, 1.0),
      end: const Offset(1.05, 1.05),
      curve: enterpriseCurve,
    ),
    ElevationEffect(
      duration: ultraFast,
      begin: 4.0,
      end: 16.0,
      curve: enterpriseCurve,
    ),
  ];

  // Ripple effect for buttons
  static List<Effect> rippleEffect({
    Color? color,
    Duration duration = fast,
  }) => [
    ScaleEffect(
      duration: duration,
      begin: const Offset(0.95, 0.95),
      end: const Offset(1.0, 1.0),
      curve: elasticCurve,
    ),
    ColorEffect(
      duration: duration,
      begin: color != null ? ColorUtils.withOpacity(color, 0.1) : ColorUtils.withOpacity(Colors.blue, 0.1),
      end: Colors.transparent,
    ),
  ];

  // Page transition animation
  static List<Effect> pageTransition({
    Duration duration = medium,
  }) => [
    FadeEffect(duration: duration),
    SlideEffect(
      duration: duration,
      begin: const Offset(1, 0),
      end: Offset.zero,
      curve: smoothCurve,
    ),
  ];

  // Success animation
  static List<Effect> successAnimation({
    Duration duration = medium,
  }) => [
    ScaleEffect(
      duration: duration,
      begin: const Offset(0.5, 0.5),
      end: const Offset(1.0, 1.0),
      curve: elasticCurve,
    ),
    ColorEffect(
      duration: duration,
      begin: ColorUtils.withOpacity(Colors.green, 0.3),
      end: Colors.transparent,
    ),
  ];

  // Error shake animation
  static List<Effect> errorShakeAnimation({
    Duration duration = fast,
  }) => [
    ShakeEffect(
      duration: duration,
      hz: 5,
      offset: const Offset(10, 0),
    ),
    ColorEffect(
      duration: duration,
      begin: ColorUtils.withOpacity(Colors.red, 0.3),
      end: Colors.transparent,
    ),
  ];

  // Loading pulse animation
  static List<Effect> loadingPulse({
    Duration duration = const Duration(milliseconds: 1000),
  }) => [
    ScaleEffect(
      duration: duration,
      begin: const Offset(1.0, 1.0),
      end: const Offset(1.1, 1.1),
      curve: Curves.easeInOut,
    ),
    ScaleEffect(
      duration: duration,
      begin: const Offset(1.1, 1.1),
      end: const Offset(1.0, 1.0),
      curve: Curves.easeInOut,
    ),
  ];
}
