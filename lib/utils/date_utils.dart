import 'package:intl/intl.dart';

class TaskDateUtils {
  static String formatTaskDate(DateTime date) {
    final now = DateTime.now();
    final difference = date.difference(DateTime(now.year, now.month, now.day));
    
    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Tomorrow';
    } else if (difference.inDays == -1) {
      return 'Yesterday';
    } else if (difference.inDays > 1 && difference.inDays < 7) {
      return DateFormat('EEEE').format(date); // Full weekday name
    } else if (difference.inDays >= -7 && difference.inDays < 0) {
      return 'Last ${DateFormat('EEEE').format(date)}';
    } else {
      return DateFormat('MMM d, y').format(date);
    }
  }
  
  static String formatTime(DateTime time) {
    return DateFormat('h:mm a').format(time);
  }
  
  static String formatFullDateTime(DateTime dateTime) {
    return '${formatTaskDate(dateTime)} at ${formatTime(dateTime)}';
  }
  
  static String getRelativeTime(DateTime date) {
    final now = DateTime.now();
    final difference = date.difference(now);
    
    if (difference.inDays.abs() > 0) {
      final days = difference.inDays.abs();
      return '${days}d ${difference.isNegative ? 'ago' : 'left'}';
    } else if (difference.inHours.abs() > 0) {
      final hours = difference.inHours.abs();
      return '${hours}h ${difference.isNegative ? 'ago' : 'left'}';
    } else {
      final minutes = difference.inMinutes.abs();
      return '${minutes}m ${difference.isNegative ? 'ago' : 'left'}';
    }
  }
  
  static bool isSameDay(DateTime? a, DateTime? b) {
    if (a == null || b == null) return false;
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
  
  static bool isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && 
           date.month == now.month && 
           date.day == now.day;
  }
  
  static bool isTomorrow(DateTime date) {
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    return date.year == tomorrow.year && 
           date.month == tomorrow.month && 
           date.day == tomorrow.day;
  }
  
  static bool isOverdue(DateTime date) {
    return date.isBefore(DateTime.now());
  }
}
