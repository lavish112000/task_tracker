import 'package:task_tracker/models/task.dart';
import 'package:task_tracker/models/task_status.dart';
import 'package:task_tracker/models/status_change.dart';
import 'package:task_tracker/services/database_helper.dart';

/// Simple recurrence handler (minimal subset) supporting DAILY / WEEKLY / MONTHLY / YEARLY rules with INTERVAL.
class RecurrenceService {
  static final RecurrenceService _instance = RecurrenceService._();
  factory RecurrenceService() => _instance;
  RecurrenceService._();

  DateTime? computeNextDueDate(Task task, {DateTime? after}) {
    final rule = task.recurrenceRule;
    if (rule == null || rule.isEmpty) return null;
    final freqMatch = RegExp(r'FREQ=([A-Z]+)').firstMatch(rule);
    if (freqMatch == null) return null;
    final freq = freqMatch.group(1);
    final intervalMatch = RegExp(r'INTERVAL=(\d+)').firstMatch(rule);
    final interval = intervalMatch != null ? int.parse(intervalMatch.group(1)!) : 1;
    final base = task.dueDate;
    final anchor = after != null && after.isAfter(base) ? after : base;

    switch (freq) {
      case 'DAILY':
        return anchor.add(Duration(days: interval));
      case 'WEEKLY':
        return anchor.add(Duration(days: 7 * interval));
      case 'MONTHLY':
        return DateTime(anchor.year, anchor.month + interval, anchor.day, anchor.hour, anchor.minute, anchor.second, anchor.millisecond, anchor.microsecond);
      case 'YEARLY':
        return DateTime(anchor.year + interval, anchor.month, anchor.day, anchor.hour, anchor.minute, anchor.second, anchor.millisecond, anchor.microsecond);
    }
    return null;
  }

  Future<Task> recordCompletionAndAdvance(Task task, {DateTime? completionDate, bool logStatusTransitions = true}) async {
    final db = await DatabaseHelper().database;
    final now = completionDate ?? DateTime.now();
    final next = computeNextDueDate(task, after: task.dueDate);

    if (next == null) {
      // No further recurrence; mark completed.
      final done = task.copyWith(
        isCompleted: true,
        status: TaskStatus.completed,
        completedAt: now,
        lastCompletionDate: now,
        streakCount: task.streakCount + 1,
      );
      await db.update('tasks', done.toDbJson(), where: 'id = ?', whereArgs: [done.id]);
      if (logStatusTransitions) {
        await db.insert('status_changes', StatusChange(taskId: done.id, status: TaskStatus.completed, changedAt: now).toJson());
      }
      return done;
    }

    // Advance to next cycle.
    final advanced = task.copyWith(
      lastCompletionDate: now,
      streakCount: task.streakCount + 1,
      isCompleted: false,
      status: TaskStatus.todo,
      completedAt: null,
      dueDate: next,
    );
    if (logStatusTransitions) {
      await db.insert('status_changes', StatusChange(taskId: task.id, status: TaskStatus.completed, changedAt: now).toJson());
      await db.insert('status_changes', StatusChange(taskId: task.id, status: TaskStatus.todo, changedAt: now.add(const Duration(milliseconds: 1))).toJson());
    }
    await db.update('tasks', advanced.toDbJson(), where: 'id = ?', whereArgs: [advanced.id]);
    return advanced;
  }
}
