// Defines task statuses and helpers
enum TaskStatus { todo, inProgress, completed }

extension TaskStatusX on TaskStatus {
  String get label {
    switch (this) {
      case TaskStatus.todo:
        return 'To-Do';
      case TaskStatus.inProgress:
        return 'In Progress';
      case TaskStatus.completed:
        return 'Completed';
    }
  }

  static TaskStatus fromString(String value) {
    return TaskStatus.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase() || e.label.toLowerCase() == value.toLowerCase(),
      orElse: () => TaskStatus.todo,
    );
  }
}

