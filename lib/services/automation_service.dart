import 'package:task_tracker/models/automation_rule.dart';
import 'package:task_tracker/models/task.dart';
import 'package:task_tracker/models/automation_log.dart';
import 'package:task_tracker/services/database_helper.dart';
import 'package:uuid/uuid.dart';

class AutomationService {
  static final AutomationService _instance = AutomationService._internal();
  factory AutomationService() => _instance;
  AutomationService._internal();

  final _uuid = const Uuid();

  Future<List<AutomationRule>> getActiveRules() async {
    final db = await DatabaseHelper().database;
    final rows = await db.query('automation_rules', where: 'isActive = 1');
    return rows.map(AutomationRule.fromDb).toList();
  }

  Future<List<AutomationRule>> getAllRules() async {
    final db = await DatabaseHelper().database;
    final rows = await db.query('automation_rules');
    return rows.map(AutomationRule.fromDb).toList();
  }

  Future<AutomationRule> addRule(AutomationRule rule) async {
    final db = await DatabaseHelper().database;
    final withId = rule.id.isEmpty
        ? rule.copyWith(id: _uuid.v4())
        : rule;
    await db.insert('automation_rules', withId.toDb());
    return withId;
  }

  Future<void> deleteRule(String id) async {
    final db = await DatabaseHelper().database;
    await db.delete('automation_rules', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> toggleRule(String id, bool active) async {
    final db = await DatabaseHelper().database;
    await db.update('automation_rules', {'isActive': active ? 1 : 0}, where: 'id = ?', whereArgs: [id]);
  }

  Future<void> evaluateTaskStatusChange(Task task) async {
    final rules = await getActiveRules();
    for (final r in rules) {
      switch (r.triggerType) {
        case 'task_completed':
          if (task.isCompleted) {
            await _executeAction(r, task);
          }
          break;
        case 'task_overdue':
          if (!task.isCompleted && task.dueDate.isBefore(DateTime.now())) {
            await _executeAction(r, task);
          }
          break;
        default:
          break;
      }
    }
  }

  Future<List<AutomationLog>> getRecentLogs({int limit = 25}) async {
    final db = await DatabaseHelper().database;
    final rows = await db.query('automation_logs', orderBy: 'executedAt DESC', limit: limit);
    return rows.map(AutomationLog.fromDb).toList();
  }

  Future<void> _logAction({required AutomationRule rule, required Task task, required String message}) async {
    final db = await DatabaseHelper().database;
    final log = AutomationLog(
      id: _uuid.v4(),
      ruleId: rule.id,
      taskId: task.id,
      actionType: rule.actionType,
      executedAt: DateTime.now(),
      message: message,
    );
    await db.insert('automation_logs', log.toDb());
  }

  Future<void> _executeAction(AutomationRule rule, Task task) async {
    switch (rule.actionType) {
      case 'escalate_priority':
        // placeholder escalation message
        await _logAction(rule: rule, task: task, message: 'Priority escalation evaluated');
        break;
      case 'notify':
        await _logAction(rule: rule, task: task, message: 'Notification queued');
        break;
      case 'assign_user':
        await _logAction(rule: rule, task: task, message: 'Assignment evaluated');
        break;
      default:
        await _logAction(rule: rule, task: task, message: 'No-op action');
        break;
    }
  }
}
