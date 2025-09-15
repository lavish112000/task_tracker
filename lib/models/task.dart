import 'dart:convert';
import 'package:task_tracker/models/priority.dart';
import 'package:task_tracker/models/task_status.dart';
import 'package:task_tracker/models/subtask.dart';
import 'package:task_tracker/models/status_change.dart';

class Task {
  // Core identity
  final String id;
  final String title;
  final String description;

  // Timing
  final DateTime dueDate;
  final DateTime createdAt;
  final DateTime? completedAt;

  // Status
  final bool isCompleted;
  final TaskStatus status;

  // Metadata
  final Priority priority;
  final List<String> tags;
  final String? notes;
  final String? categoryId;
  final String? workspaceId;

  // Recurrence / tracking
  final String? recurrenceRule;
  final DateTime? lastCompletionDate;
  final int streakCount;
  final int totalTrackedSeconds;

  // Related collections (not stored directly in task row)
  final List<SubTask> subtasks;
  final List<StatusChange> statusHistory;

  // AI and automation features
  final String? aiModel;
  final Map<String, dynamic>? aiParameters;
  final bool isAutomated;

  // Gamification and focus tools
  final int focusLevel;
  final int rewardPoints;

  // Location-based features
  final String? locationId;
  final double? latitude;
  final double? longitude;

  // Security features
  final bool isEncrypted;
  final String? encryptionKey;

  // Mind map features
  final String? mindMapId;
  final List<String>? relatedMindMapNodes;

  Task({
    required this.id,
    required this.title,
    required this.description,
    required this.dueDate,
    required this.isCompleted,
    required this.priority,
    DateTime? createdAt,
    this.completedAt,
    this.tags = const [],
    this.notes,
    this.categoryId,
    this.workspaceId,
    this.recurrenceRule,
    this.lastCompletionDate,
    this.streakCount = 0,
    this.totalTrackedSeconds = 0,
    this.status = TaskStatus.todo,
    this.subtasks = const [],
    this.statusHistory = const [],
    this.aiModel,
    this.aiParameters,
    this.isAutomated = false,
    this.focusLevel = 0,
    this.rewardPoints = 0,
    this.locationId,
    this.latitude,
    this.longitude,
    this.isEncrypted = false,
    this.encryptionKey,
    this.mindMapId,
    this.relatedMindMapNodes,
  }) : createdAt = createdAt ?? DateTime.now();

  Task copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? dueDate,
    bool? isCompleted,
    Priority? priority,
    DateTime? createdAt,
    DateTime? completedAt,
    List<String>? tags,
    String? notes,
    String? categoryId,
    String? workspaceId,
    TaskStatus? status,
    String? recurrenceRule,
    DateTime? lastCompletionDate,
    int? streakCount,
    int? totalTrackedSeconds,
    List<SubTask>? subtasks,
    List<StatusChange>? statusHistory,
    String? aiModel,
    Map<String, dynamic>? aiParameters,
    bool? isAutomated,
    int? focusLevel,
    int? rewardPoints,
    String? locationId,
    double? latitude,
    double? longitude,
    bool? isEncrypted,
    String? encryptionKey,
    String? mindMapId,
    List<String>? relatedMindMapNodes,
  }) => Task(
        id: id ?? this.id,
        title: title ?? this.title,
        description: description ?? this.description,
        dueDate: dueDate ?? this.dueDate,
        isCompleted: isCompleted ?? this.isCompleted,
        priority: priority ?? this.priority,
        createdAt: createdAt ?? this.createdAt,
        completedAt: completedAt ?? this.completedAt,
        tags: tags ?? this.tags,
        notes: notes ?? this.notes,
        categoryId: categoryId ?? this.categoryId,
        workspaceId: workspaceId ?? this.workspaceId,
        status: status ?? this.status,
        recurrenceRule: recurrenceRule ?? this.recurrenceRule,
        lastCompletionDate: lastCompletionDate ?? this.lastCompletionDate,
        streakCount: streakCount ?? this.streakCount,
        totalTrackedSeconds: totalTrackedSeconds ?? this.totalTrackedSeconds,
        subtasks: subtasks ?? this.subtasks,
        statusHistory: statusHistory ?? this.statusHistory,
        aiModel: aiModel ?? this.aiModel,
        aiParameters: aiParameters ?? this.aiParameters,
        isAutomated: isAutomated ?? this.isAutomated,
        focusLevel: focusLevel ?? this.focusLevel,
        rewardPoints: rewardPoints ?? this.rewardPoints,
        locationId: locationId ?? this.locationId,
        latitude: latitude ?? this.latitude,
        longitude: longitude ?? this.longitude,
        isEncrypted: isEncrypted ?? this.isEncrypted,
        encryptionKey: encryptionKey ?? this.encryptionKey,
        mindMapId: mindMapId ?? this.mindMapId,
        relatedMindMapNodes: relatedMindMapNodes ?? this.relatedMindMapNodes,
      );

  // Derived helpers
  bool get isOverdue => !isCompleted && DateTime.now().isAfter(dueDate);
  bool get isDueToday {
    if (isCompleted) return false;
    final now = DateTime.now();
    return now.year == dueDate.year && now.month == dueDate.month && now.day == dueDate.day;
  }
  bool get isDueSoon {
    if (isCompleted) return false;
    final diff = dueDate.difference(DateTime.now());
    return diff.inDays <= 3 && diff.inDays >= 0;
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'dueDate': dueDate.toIso8601String(),
        'isCompleted': isCompleted,
        'priority': priority.name,
        'createdAt': createdAt.toIso8601String(),
        'completedAt': completedAt?.toIso8601String(),
        'tags': tags,
        'notes': notes,
        'categoryId': categoryId,
        'status': status.name,
        'recurrenceRule': recurrenceRule,
        'lastCompletionDate': lastCompletionDate?.toIso8601String(),
        'streakCount': streakCount,
        'totalTrackedSeconds': totalTrackedSeconds,
        'workspaceId': workspaceId,
        'aiModel': aiModel,
        'aiParameters': aiParameters,
        'isAutomated': isAutomated,
        'focusLevel': focusLevel,
        'rewardPoints': rewardPoints,
        'locationId': locationId,
        'latitude': latitude,
        'longitude': longitude,
        'isEncrypted': isEncrypted,
        'encryptionKey': encryptionKey,
        'mindMapId': mindMapId,
        'relatedMindMapNodes': relatedMindMapNodes,
      };

  Map<String, dynamic> toApiJson({bool includeSubtasks = false, bool includeHistory = false}) => {
        ...toJson(),
        if (includeSubtasks) 'subtasks': subtasks.map((s) => s.toJson()).toList(),
        if (includeHistory) 'statusHistory': statusHistory.map((h) => h.toJson()).toList(),
      };

  Map<String, dynamic> toDbJson() => {
        'id': id,
        'title': title,
        'description': description,
        'dueDate': dueDate.toIso8601String(),
        'isCompleted': isCompleted ? 1 : 0,
        'priority': priority.name,
        'createdAt': createdAt.toIso8601String(),
        'completedAt': completedAt?.toIso8601String(),
        'tags': jsonEncode(tags),
        'notes': notes,
        'categoryId': categoryId,
        'status': status.name,
        'recurrenceRule': recurrenceRule,
        'lastCompletionDate': lastCompletionDate?.toIso8601String(),
        'streakCount': streakCount,
        'totalTrackedSeconds': totalTrackedSeconds,
        'workspaceId': workspaceId,
        'aiModel': aiModel,
        'aiParameters': jsonEncode(aiParameters),
        'isAutomated': isAutomated ? 1 : 0,
        'focusLevel': focusLevel,
        'rewardPoints': rewardPoints,
        'locationId': locationId,
        'latitude': latitude,
        'longitude': longitude,
        'isEncrypted': isEncrypted ? 1 : 0,
        'encryptionKey': encryptionKey,
        'mindMapId': mindMapId,
        'relatedMindMapNodes': jsonEncode(relatedMindMapNodes),
      };

  static Task fromJson(Map<String, dynamic> json) {
    DateTime _parse(dynamic v) => v == null ? DateTime.now() : (v is DateTime ? v : (DateTime.tryParse(v.toString()) ?? DateTime.now()));
    final rawTags = json['tags'];
    List<String> tagList = [];
    if (rawTags is List) {
      tagList = rawTags.map((e) => e.toString()).toList();
    } else if (rawTags is String) {
      try {
        final decoded = jsonDecode(rawTags);
        if (decoded is List) {
          tagList = decoded.map((e) => e.toString()).toList();
        }
      } catch (_) {}
    }
    final statusName = json['status']?.toString();
    final status = TaskStatus.values.firstWhere(
      (s) => s.name == statusName,
      orElse: () => (json['isCompleted'] == true) ? TaskStatus.completed : TaskStatus.todo,
    );
    final completed = status == TaskStatus.completed;
    return Task(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      dueDate: _parse(json['dueDate']),
      isCompleted: completed,
      priority: _priorityFrom(json['priority']),
      createdAt: _parse(json['createdAt']),
      completedAt: json['completedAt'] != null ? DateTime.tryParse(json['completedAt'].toString()) : null,
      tags: tagList,
      notes: json['notes']?.toString(),
      categoryId: json['categoryId']?.toString(),
      workspaceId: json['workspaceId']?.toString(),
      status: status,
      recurrenceRule: json['recurrenceRule']?.toString(),
      lastCompletionDate: json['lastCompletionDate'] != null ? DateTime.tryParse(json['lastCompletionDate'].toString()) : null,
      streakCount: _toInt(json['streakCount']),
      totalTrackedSeconds: _toInt(json['totalTrackedSeconds']),
      aiModel: json['aiModel']?.toString(),
      aiParameters: json['aiParameters'] != null ? jsonDecode(json['aiParameters']) : null,
      isAutomated: json['isAutomated'] == true || json['isAutomated'] == 1,
      focusLevel: _toInt(json['focusLevel']),
      rewardPoints: _toInt(json['rewardPoints']),
      locationId: json['locationId']?.toString(),
      latitude: _toDouble(json['latitude']),
      longitude: _toDouble(json['longitude']),
      isEncrypted: json['isEncrypted'] == true || json['isEncrypted'] == 1,
      encryptionKey: json['encryptionKey']?.toString(),
      mindMapId: json['mindMapId']?.toString(),
      relatedMindMapNodes: json['relatedMindMapNodes'] != null ? List<String>.from(json['relatedMindMapNodes']) : null,
    );
  }

  static Task fromDbJson(Map<String, dynamic> json) {
    DateTime? _try(dynamic v) => v == null ? null : (v is DateTime ? v : DateTime.tryParse(v.toString()));
    // tags as JSON string
    final rawTags = json['tags'];
    List<String> tagList = [];
    if (rawTags is String) {
      try {
        final decoded = jsonDecode(rawTags);
        if (decoded is List) tagList = decoded.map((e) => e.toString()).toList();
      } catch (_) {}
    } else if (rawTags is List) {
      tagList = rawTags.map((e) => e.toString()).toList();
    }
    final rawCompleted = json['isCompleted'];
    final completed = rawCompleted == 1 || rawCompleted == true || rawCompleted == '1';
    final statusName = json['status']?.toString();
    final status = TaskStatus.values.firstWhere(
      (s) => s.name == statusName,
      orElse: () => completed ? TaskStatus.completed : TaskStatus.todo,
    );
    return Task(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      dueDate: _try(json['dueDate']) ?? DateTime.now(),
      isCompleted: completed,
      priority: _priorityFrom(json['priority']),
      createdAt: _try(json['createdAt']) ?? DateTime.now(),
      completedAt: _try(json['completedAt']),
      tags: tagList,
      notes: json['notes']?.toString(),
      categoryId: json['categoryId']?.toString(),
      workspaceId: json['workspaceId']?.toString(),
      status: status,
      recurrenceRule: json['recurrenceRule']?.toString(),
      lastCompletionDate: _try(json['lastCompletionDate']),
      streakCount: _toInt(json['streakCount']),
      totalTrackedSeconds: _toInt(json['totalTrackedSeconds']),
      aiModel: json['aiModel']?.toString(),
      aiParameters: json['aiParameters'] != null ? jsonDecode(json['aiParameters']) : null,
      isAutomated: json['isAutomated'] == true || json['isAutomated'] == 1,
      focusLevel: _toInt(json['focusLevel']),
      rewardPoints: _toInt(json['rewardPoints']),
      locationId: json['locationId']?.toString(),
      latitude: _toDouble(json['latitude']),
      longitude: _toDouble(json['longitude']),
      isEncrypted: json['isEncrypted'] == true || json['isEncrypted'] == 1,
      encryptionKey: json['encryptionKey']?.toString(),
      mindMapId: json['mindMapId']?.toString(),
      relatedMindMapNodes: json['relatedMindMapNodes'] != null ? List<String>.from(json['relatedMindMapNodes']) : null,
    );
  }

  static Priority _priorityFrom(dynamic v) {
    final name = v?.toString();
    return Priority.values.firstWhere(
      (p) => p.name == name,
      orElse: () => Priority.medium,
    );
  }

  static int _toInt(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    if (v is double) return v.toInt();
    return int.tryParse(v.toString()) ?? 0;
  }

  static double _toDouble(dynamic v) {
    if (v == null) return 0.0;
    if (v is double) return v;
    if (v is int) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0.0;
  }
}
