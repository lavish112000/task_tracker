import 'package:flutter/material.dart';

/// Utility class for color operations
class ColorUtils {
  /// Creates a color with the given opacity (0.0 to 1.0)
  /// Replaces the deprecated withOpacity method
  static Color withAlphaValue(Color color, double opacity) {
    assert(opacity >= 0.0 && opacity <= 1.0);
    return color.withAlpha((opacity * 255).round());
  }

  /// Creates a color with the given opacity using withAlpha
  /// Alternative to withOpacity that avoids precision loss
  static Color withOpacity(Color color, double opacity) {
    return color.withAlpha((color.a * 255 * opacity).round());
  }
}
