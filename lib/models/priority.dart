import 'package:flutter/material.dart';

enum Priority {
  low,
  medium,
  high,
  urgent;

  String get displayName {
    switch (this) {
      case Priority.low:
        return 'Low';
      case Priority.medium:
        return 'Medium';
      case Priority.high:
        return 'High';
      case Priority.urgent:
        return 'Urgent';
    }
  }

  Color get color {
    switch (this) {
      case Priority.low:
        return Colors.green;
      case Priority.medium:
        return Colors.orange;
      case Priority.high:
        return Colors.red;
      case Priority.urgent:
        return Colors.purple;
    }
  }

  IconData get icon {
    switch (this) {
      case Priority.low:
        return Icons.low_priority;
      case Priority.medium:
        return Icons.remove;
      case Priority.high:
        return Icons.priority_high;
      case Priority.urgent:
        return Icons.warning;
    }
  }

  int get value {
    switch (this) {
      case Priority.low:
        return 1;
      case Priority.medium:
        return 2;
      case Priority.high:
        return 3;
      case Priority.urgent:
        return 4;
    }
  }
}
