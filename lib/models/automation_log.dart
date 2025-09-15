class AutomationLog {
  final String id;
  final String ruleId;
  final String taskId;
  final String actionType;
  final DateTime executedAt;
  final String? message;

  AutomationLog({
    required this.id,
    required this.ruleId,
    required this.taskId,
    required this.actionType,
    required this.executedAt,
    this.message,
  });

  Map<String, dynamic> toDb() => {
        'id': id,
        'ruleId': ruleId,
        'taskId': taskId,
        'actionType': actionType,
        'executedAt': executedAt.toIso8601String(),
        'message': message,
      };

  static AutomationLog fromDb(Map<String, dynamic> row) => AutomationLog(
        id: row['id'] as String,
        ruleId: row['ruleId'] as String,
        taskId: row['taskId'] as String,
        actionType: row['actionType'] as String,
        executedAt: DateTime.tryParse(row['executedAt'].toString()) ?? DateTime.now(),
        message: row['message'] as String?,
      );
}

