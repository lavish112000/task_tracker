import 'package:task_tracker/models/task_status.dart';
import 'package:uuid/uuid.dart';

class StatusChange {
  final String id;
  final String taskId;
  final TaskStatus status;
  final DateTime changedAt;

  StatusChange({
    String? id,
    required this.taskId,
    required this.status,
    DateTime? changedAt,
  })  : id = id ?? const Uuid().v4(),
        changedAt = changedAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'id': id,
        'taskId': taskId,
        'status': status.name,
        'changedAt': changedAt.millisecondsSinceEpoch,
      };

  static StatusChange fromJson(Map<String, dynamic> json) => StatusChange(
        id: json['id'],
        taskId: json['taskId'],
        status: TaskStatusX.fromString(json['status']),
        changedAt: DateTime.fromMillisecondsSinceEpoch(json['changedAt']),
      );
}

