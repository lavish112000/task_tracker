import 'package:uuid/uuid.dart';

class SubTask {
  final String id;
  final String taskId; // parent task id
  final String title;
  final bool isCompleted;
  final DateTime? dueDate;

  SubTask({
    String? id,
    required this.taskId,
    required this.title,
    this.isCompleted = false,
    this.dueDate,
  }) : id = id ?? const Uuid().v4();

  SubTask copyWith({
    String? id,
    String? taskId,
    String? title,
    bool? isCompleted,
    DateTime? dueDate,
  }) => SubTask(
        id: id ?? this.id,
        taskId: taskId ?? this.taskId,
        title: title ?? this.title,
        isCompleted: isCompleted ?? this.isCompleted,
        dueDate: dueDate ?? this.dueDate,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'taskId': taskId,
        'title': title,
        'isCompleted': isCompleted ? 1 : 0,
        'dueDate': dueDate?.millisecondsSinceEpoch,
      };

  static SubTask fromJson(Map<String, dynamic> json) => SubTask(
        id: json['id'],
        taskId: json['taskId'],
        title: json['title'],
        isCompleted: (json['isCompleted'] ?? 0) == 1,
        dueDate: json['dueDate'] != null ? DateTime.fromMillisecondsSinceEpoch(json['dueDate']) : null,
      );
}

