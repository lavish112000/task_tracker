import 'dart:async';
import 'dart:math';
import 'dart:convert';
import 'dart:typed_data';
import 'package:encrypt/encrypt.dart' as enc;
import 'package:crypto/crypto.dart';
import 'package:task_tracker/models/task.dart';
import 'package:task_tracker/models/priority.dart';
import 'package:task_tracker/models/task_status.dart';
import 'package:task_tracker/models/subtask.dart';
import 'package:task_tracker/models/status_change.dart';
import 'package:task_tracker/services/database_helper.dart';
import 'package:task_tracker/services/recurrence_service.dart';
import 'package:task_tracker/services/automation_service.dart';

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
    final rows = await db.query('tasks', where: 'id = ?', whereArgs: [taskId], limit: 1);
    if (rows.isEmpty) return;
    final current = Task.fromDbJson(rows.first);

    if (newStatus == TaskStatus.completed && (current.recurrenceRule != null && current.recurrenceRule!.isNotEmpty)) {
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

    // Gamification reward for completion
    if (newStatus == TaskStatus.completed) {
      final updated = current.copyWith(rewardPoints: current.rewardPoints + 10, streakCount: current.streakCount + 1);
      await updateTask(updated);
    }
    // Evaluate automation
    await AutomationService().evaluateTaskStatusChange(current.copyWith(status: newStatus, isCompleted: newStatus == TaskStatus.completed));
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

  Future<List<Task>> getTasksByMindMap(String mindMapId) async {
    final db = await DatabaseHelper().database;
    final rows = await db.query('tasks', where: 'mindMapId = ?', whereArgs: [mindMapId]);
    return rows.map(Task.fromDbJson).toList();
  }

  // --- AI Features ---
  Future<Task> addTaskFromNaturalLanguage(String input) async {
    // Very naive parsing: look for 'tomorrow' or date pattern YYYY-MM-DD and time HH:MM
    final lower = input.toLowerCase();
    DateTime due = DateTime.now().add(const Duration(days: 1));
    final now = DateTime.now();
    if (lower.contains('tomorrow')) {
      due = DateTime(now.year, now.month, now.day).add(const Duration(days: 1, hours: 9));
    }
    final dateRegex = RegExp(r'(\d{4})-(\d{2})-(\d{2})');
    final timeRegex = RegExp(r'(\d{1,2}):(\d{2})');
    final dateMatch = dateRegex.firstMatch(input);
    final timeMatch = timeRegex.firstMatch(input);
    if (dateMatch != null) {
      final y = int.tryParse(dateMatch.group(1)!);
      final m = int.tryParse(dateMatch.group(2)!);
      final d = int.tryParse(dateMatch.group(3)!);
      if (y != null && m != null && d != null) {
        due = DateTime(y, m, d, due.hour, due.minute);
      }
    }
    if (timeMatch != null) {
      final h = int.tryParse(timeMatch.group(1)!);
      final min = int.tryParse(timeMatch.group(2)!);
      if (h != null && min != null) {
        due = DateTime(due.year, due.month, due.day, h, min);
      }
    }
    final task = Task(
      id: '',
      title: input.length > 60 ? input.substring(0, 60) : input,
      description: input,
      dueDate: due,
      isCompleted: false,
      priority: Priority.medium,
      aiModel: 'rule-based-v1',
      aiParameters: {'source': 'nlp_basic'},
    );
    return addTask(task);
  }
  Future<List<Task>> getRankedTasks(List<Task> tasks) async {
    tasks.sort((a, b) {
      int score(Task t) {
        int s = 0;
        if (t.isOverdue) s += 1000;
        final diff = t.dueDate.difference(DateTime.now()).inHours;
        s += (168 - diff.clamp(0, 168));
        s += (2 - t.priority.index) * 50; // high priority gives more
        s += t.streakCount;
        return s;
      }
      return score(b).compareTo(score(a));
    });
    return tasks;
  }
  Future<DateTime?> suggestSmartSlot(List<Task> tasks) async {
    // Find a day with fewer than 5 tasks in next 7 days
    final now = DateTime.now();
    for (int i = 0; i < 7; i++) {
      final day = DateTime(now.year, now.month, now.day).add(Duration(days: i));
      final count = tasks.where((t) => t.dueDate.year == day.year && t.dueDate.month == day.month && t.dueDate.day == day.day).length;
      if (count < 5) {
        return day.add(const Duration(hours: 9));
      }
    }
    return now.add(const Duration(hours: 1));
  }
  // --- Gamification ---
  Future<void> awardGamification(Task task, {int points = 5}) async {
    final updated = task.copyWith(rewardPoints: task.rewardPoints + points);
    await updateTask(updated);
  }
  // --- Focus Tools ---
  Future<void> logFocusSession(Task task) async {
    final updated = task.copyWith(focusLevel: task.focusLevel + 1, totalTrackedSeconds: task.totalTrackedSeconds + 1500);
    await updateTask(updated);
  }
  // --- Location-Based Reminders ---
  Future<void> setLocationReminder(Task task, double lat, double lng) async {
    final updated = task.copyWith(latitude: lat, longitude: lng, locationId: 'geo_${lat.toStringAsFixed(3)}_${lng.toStringAsFixed(3)}');
    await updateTask(updated);
  }
  // --- Security ---
  // === Encryption helpers ===
  static const _encPrefix = 'enc:';
  enc.Key _deriveKey(String pass) {
    final hash = sha256.convert(utf8.encode(pass));
    return enc.Key(Uint8List.fromList(hash.bytes)); // 32 bytes
  }
  enc.IV _randomIv() => enc.IV.fromSecureRandom(16);
  String _encryptString(String plain, String pass) {
    if (plain.isEmpty) return plain;
    final key = _deriveKey(pass);
    final iv = _randomIv();
    final cipher = enc.Encrypter(enc.AES(key, mode: enc.AESMode.cbc));
    final encrypted = cipher.encrypt(plain, iv: iv);
    // store iv + ciphertext base64
    final raw = iv.bytes + encrypted.bytes;
    return _encPrefix + base64Encode(raw);
  }
  String _decryptString(String data, String pass) {
    if (!data.startsWith(_encPrefix)) return data;
    final rawB64 = data.substring(_encPrefix.length);
    late List<int> raw;
    try { raw = base64Decode(rawB64); } catch (_) { return data; }
    if (raw.length < 16) return data;
    final ivBytes = Uint8List.fromList(raw.sublist(0,16));
    final cipherBytes = Uint8List.fromList(raw.sublist(16));
    final key = _deriveKey(pass);
    final cipher = enc.Encrypter(enc.AES(key, mode: enc.AESMode.cbc));
    try { return cipher.decrypt(enc.Encrypted(cipherBytes), iv: enc.IV(ivBytes)); } catch (_) { return data; }
  }
  Task encryptOffline(Task task, String pass){
    if (task.isEncrypted) return task;
    final encDesc = _encryptString(task.description, pass);
    final encNotes = task.notes==null? null : _encryptString(task.notes!, pass);
    return task.copyWith(description: encDesc, notes: encNotes, isEncrypted: true, encryptionKey: sha256.convert(utf8.encode(pass)).toString());
  }
  Task decryptOffline(Task task, String pass){
    if (!task.isEncrypted) return task;
    final hashed = sha256.convert(utf8.encode(pass)).toString();
    if (task.encryptionKey != hashed) return task; // wrong key -> return as-is
    final decDesc = _decryptString(task.description, pass);
    final decNotes = task.notes==null? null : _decryptString(task.notes!, pass);
    return task.copyWith(description: decDesc, notes: decNotes, isEncrypted: false);
  }
  // override existing encrypt/decrypt to also transform fields
  Future<Task> encryptTask(Task task, String key) async {
    final dbTask = encryptOffline(task, key);
    await updateTask(dbTask);
    return dbTask;
  }
  Future<Task> decryptTask(Task task, String key) async {
    final dbTask = decryptOffline(task, key);
    await updateTask(dbTask);
    return dbTask;
  }
  // --- Mind Map / Visual Linking ---
  Future<void> linkTasks(String sourceId, String targetId) async {
    final source = await getTask(sourceId, includeSubtasks: false, includeHistory: false);
    if (source == null) return;
    final updatedLinks = (source.relatedMindMapNodes ?? []).toSet();
    if (updatedLinks.add(targetId)) {
      await updateTask(source.copyWith(relatedMindMapNodes: updatedLinks.toList()));
    }
  }
  Future<void> unlinkTask(String sourceId, String targetId) async {
    final source = await getTask(sourceId, includeSubtasks: false, includeHistory: false);
    if (source == null) return;
    final updatedLinks = (source.relatedMindMapNodes ?? []).toList();
    updatedLinks.remove(targetId);
    await updateTask(source.copyWith(relatedMindMapNodes: updatedLinks));
  }
}