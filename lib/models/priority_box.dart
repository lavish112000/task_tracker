// lib/models/priority_box.dart
import 'package:flutter/material.dart';
import 'package:task_tracker/models/task.dart';

class PriorityBox {
  final String id;
  final String name;
  final Color color;
  final List<Task> tasks;
  final DateTime createdAt;
  final String? description;
  final IconData? icon;

  PriorityBox({
    required this.id,
    required this.name,
    required this.color,
    required this.tasks,
    DateTime? createdAt,
    this.description,
    this.icon,
  }) : createdAt = createdAt ?? DateTime.now();

  PriorityBox copyWith({
    String? id,
    String? name,
    Color? color,
    List<Task>? tasks,
    DateTime? createdAt,
    String? description,
    IconData? icon,
  }) {
    return PriorityBox(
      id: id ?? this.id,
      name: name ?? this.name,
      color: color ?? this.color,
      tasks: tasks ?? this.tasks,
      createdAt: createdAt ?? this.createdAt,
      description: description ?? this.description,
      icon: icon ?? this.icon,
    );
  }

  int get completedTasksCount => tasks.where((task) => task.isCompleted).length;
  int get totalTasksCount => tasks.length;
  int get pendingTasksCount => totalTasksCount - completedTasksCount;

  double get completionPercentage {
    if (totalTasksCount == 0) return 0.0;
    return (completedTasksCount / totalTasksCount) * 100;
  }

  // Add missing completionRate getter for compatibility with priority_box_card.dart
  double get completionRate {
    if (totalTasksCount == 0) return 0.0;
    return completedTasksCount / totalTasksCount;
  }

  List<Task> get completedTasks => tasks.where((task) => task.isCompleted).toList();
  List<Task> get pendingTasks => tasks.where((task) => !task.isCompleted).toList();
  List<Task> get overdueTasks => tasks.where((task) => task.isOverdue).toList();
  List<Task> get dueTodayTasks => tasks.where((task) => task.isDueToday).toList();
  List<Task> get dueSoonTasks => tasks.where((task) => task.isDueSoon).toList();

  bool get hasOverdueTasks => overdueTasks.isNotEmpty;
  bool get hasDueTodayTasks => dueTodayTasks.isNotEmpty;
  bool get hasDueSoonTasks => dueSoonTasks.isNotEmpty;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'color': color.value,
      'tasks': tasks.map((task) => task.toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'description': description,
      'icon': icon?.codePoint,
    };
  }

  static PriorityBox fromJson(Map<String, dynamic> json) {
    return PriorityBox(
      id: json['id'],
      name: json['name'],
      color: Color(json['color']),
      tasks: (json['tasks'] as List<dynamic>)
          .map((taskJson) => Task.fromJson(taskJson))
          .toList(),
      createdAt: DateTime.parse(json['createdAt']),
      description: json['description'],
      icon: json['icon'] != null ? IconData(json['icon'], fontFamily: 'MaterialIcons') : null,
    );
  }

  void addTask(Task task) {
    tasks.add(task);
  }

  void removeTask(String taskId) {
    tasks.removeWhere((task) => task.id == taskId);
  }

  void updateTask(Task updatedTask) {
    final index = tasks.indexWhere((task) => task.id == updatedTask.id);
    if (index != -1) {
      tasks[index] = updatedTask;
    }
  }

  Task? getTaskById(String taskId) {
    try {
      return tasks.firstWhere((task) => task.id == taskId);
    } catch (e) {
      return null;
    }
  }
}
