import 'dart:async';
import 'dart:math';
import 'package:task_tracker/models/task.dart';
import 'package:task_tracker/models/priority.dart';
import 'package:task_tracker/models/task_status.dart';
import 'package:task_tracker/models/subtask.dart';
import 'package:task_tracker/models/status_change.dart';
import 'package:task_tracker/services/database_helper.dart';
import 'package:task_tracker/services/recurrence_service.dart';

String _genId() {
  final rnd = Random();
  final millis = DateTime.now().millisecondsSinceEpoch;
  final rand = rnd.nextInt(1 << 32).toRadixString(16);
  return 'tsk_${millis}_$rand';
}

class TaskQueryOptions {
  final TaskStatus? status;
  final Priority? priority;
  final String? categoryId;
  final DateTime? dueBefore;
  final DateTime? dueAfter;
  final String? search;
  final bool includeSubtasks;
  final bool includeHistory;
  const TaskQueryOptions({
    this.status,
    this.priority,
    this.categoryId,
    this.dueBefore,
    this.dueAfter,
    this.search,
    this.includeSubtasks = true,
    this.includeHistory = false,
  });
}

class TaskService {
  Future<Task> addTask(Task task) async {
    final db = await DatabaseHelper().database;
    final id = (task.id.isEmpty) ? _genId() : task.id;
    final status = task.status;
    final isCompleted = status == TaskStatus.completed;
    final stored = task.copyWith(
      id: id,
      isCompleted: isCompleted,
      completedAt: isCompleted ? (task.completedAt ?? DateTime.now()) : null,
      status: status,
    );
    await db.insert('tasks', stored.toDbJson());
    await db.insert('status_changes', StatusChange(taskId: id, status: stored.status).toJson());
    for (final st in task.subtasks) {
      final sub = st.copyWith(taskId: id);
      await db.insert('subtasks', {
        'id': sub.id,
        'taskId': sub.taskId,
        'title': sub.title,
        'isCompleted': sub.isCompleted ? 1 : 0,
        'dueDate': sub.dueDate?.toIso8601String(),
      });
    }
    return stored;
  }

  Future<List<Task>> getTasks({TaskQueryOptions options = const TaskQueryOptions()}) async {
    final db = await DatabaseHelper().database;
    final where = <String>[];
    final args = <Object?>[];

    if (options.status != null) { where.add('status = ?'); args.add(options.status!.name); }
    if (options.priority != null) { where.add('priority = ?'); args.add(options.priority!.name); }
    if (options.categoryId != null) { where.add('categoryId = ?'); args.add(options.categoryId); }
    if (options.dueBefore != null) { where.add('dueDate <= ?'); args.add(options.dueBefore!.toIso8601String()); }
    if (options.dueAfter != null) { where.add('dueDate >= ?'); args.add(options.dueAfter!.toIso8601String()); }
    if (options.search != null && options.search!.trim().isNotEmpty) {
      where.add('(title LIKE ? OR description LIKE ? OR notes LIKE ?)');
      final pattern = '%${options.search!.trim()}%';
      args.addAll([pattern, pattern, pattern]);
    }

    final rows = await db.query(
      'tasks',
      where: where.isEmpty ? null : where.join(' AND '),
      whereArgs: args,
      orderBy: 'dueDate ASC, priority DESC',
    );
    final tasks = rows.map(Task.fromDbJson).toList();

    if (options.includeSubtasks || options.includeHistory) {
      for (var i = 0; i < tasks.length; i++) {
        final t = tasks[i];
        tasks[i] = t.copyWith(
          subtasks: options.includeSubtasks ? await _getSubtasks(t.id) : t.subtasks,
          statusHistory: options.includeHistory ? await _getStatusHistory(t.id) : t.statusHistory,
        );
      }
    }
    return tasks;
  }

  Future<Task?> getTask(String id, {bool includeSubtasks = true, bool includeHistory = true}) async {
    final db = await DatabaseHelper().database;
    final rows = await db.query('tasks', where: 'id = ?', whereArgs: [id], limit: 1);
    if (rows.isEmpty) return null;
    var task = Task.fromDbJson(rows.first);
    if (includeSubtasks) task = task.copyWith(subtasks: await _getSubtasks(id));
    if (includeHistory) task = task.copyWith(statusHistory: await _getStatusHistory(id));
    return task;
  }

  Future<void> updateTask(Task task) async {
    final db = await DatabaseHelper().database;
    final fixed = task.copyWith(
      isCompleted: task.status == TaskStatus.completed,
      completedAt: task.status == TaskStatus.completed ? (task.completedAt ?? DateTime.now()) : null,
    );
    await db.update('tasks', fixed.toDbJson(), where: 'id = ?', whereArgs: [fixed.id]);
  }

  Future<void> updateStatus(String taskId, TaskStatus newStatus) async {
    final db = await DatabaseHelper().database;
    // Load task first to check recurrence
    final rows = await db.query('tasks', where: 'id = ?', whereArgs: [taskId], limit: 1);
    if (rows.isEmpty) return;
    final current = Task.fromDbJson(rows.first);

    if (newStatus == TaskStatus.completed && (current.recurrenceRule != null && current.recurrenceRule!.isNotEmpty)) {
      // Use recurrence service to advance; it handles DB + history logging.
      await RecurrenceService().recordCompletionAndAdvance(current, logStatusTransitions: true);
      return;
    }

    final now = DateTime.now();
    await db.update('tasks', {
      'status': newStatus.name,
      'isCompleted': newStatus == TaskStatus.completed ? 1 : 0,
      'completedAt': newStatus == TaskStatus.completed ? now.toIso8601String() : null,
    }, where: 'id = ?', whereArgs: [taskId]);
    await db.insert('status_changes', StatusChange(taskId: taskId, status: newStatus, changedAt: now).toJson());
  }

  Future<void> deleteTask(String id) async {
    final db = await DatabaseHelper().database;
    await db.delete('tasks', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<SubTask>> _getSubtasks(String taskId) async {
    final db = await DatabaseHelper().database;
    final rows = await db.query('subtasks', where: 'taskId = ?', whereArgs: [taskId]);
    return rows.map((r) => SubTask.fromJson({
      'id': r['id'],
      'taskId': r['taskId'],
      'title': r['title'],
      'isCompleted': r['isCompleted'],
      'dueDate': r['dueDate'] != null ? DateTime.parse(r['dueDate'] as String).millisecondsSinceEpoch : null,
    })).toList();
  }

  Future<List<StatusChange>> _getStatusHistory(String taskId) async {
    final db = await DatabaseHelper().database;
    final rows = await db.query('status_changes', where: 'taskId = ?', whereArgs: [taskId], orderBy: 'changedAt ASC');
    return rows.map((r) => StatusChange.fromJson({
      'id': r['id'],
      'taskId': r['taskId'],
      'status': r['status'],
      'changedAt': DateTime.parse(r['changedAt'] as String).millisecondsSinceEpoch,
    })).toList();
  }

  Future<SubTask> addSubTask(String taskId, String title, {DateTime? dueDate}) async {
    final db = await DatabaseHelper().database;
    final sub = SubTask(taskId: taskId, title: title, dueDate: dueDate);
    await db.insert('subtasks', {
      'id': sub.id,
      'taskId': sub.taskId,
      'title': sub.title,
      'isCompleted': sub.isCompleted ? 1 : 0,
      'dueDate': sub.dueDate?.toIso8601String(),
    });
    return sub;
  }

  Future<void> toggleSubTask(String subTaskId, bool isCompleted) async {
    final db = await DatabaseHelper().database;
    await db.update('subtasks', {'isCompleted': isCompleted ? 1 : 0}, where: 'id = ?', whereArgs: [subTaskId]);
  }

  Future<void> deleteSubTask(String subTaskId) async {
    final db = await DatabaseHelper().database;
    await db.delete('subtasks', where: 'id = ?', whereArgs: [subTaskId]);
  }
}