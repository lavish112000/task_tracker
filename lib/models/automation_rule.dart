// Defines automation rule model
class AutomationRule {
  final String id;
  final String name;
  final String triggerType; // e.g. task_completed, due_missed
  final Map<String, dynamic>? triggerData;
  final String actionType; // e.g. notify, escalate_priority
  final Map<String, dynamic>? actionData;
  final bool isActive;
  final DateTime createdAt;

  AutomationRule({
    required this.id,
    required this.name,
    required this.triggerType,
    required this.actionType,
    this.triggerData,
    this.actionData,
    this.isActive = true,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  AutomationRule copyWith({
    String? id,
    String? name,
    String? triggerType,
    Map<String, dynamic>? triggerData,
    String? actionType,
    Map<String, dynamic>? actionData,
    bool? isActive,
    DateTime? createdAt,
  }) => AutomationRule(
        id: id ?? this.id,
        name: name ?? this.name,
        triggerType: triggerType ?? this.triggerType,
        triggerData: triggerData ?? this.triggerData,
        actionType: actionType ?? this.actionType,
        actionData: actionData ?? this.actionData,
        isActive: isActive ?? this.isActive,
        createdAt: createdAt ?? this.createdAt,
      );

  Map<String, dynamic> toDb() => {
        'id': id,
        'name': name,
        'triggerType': triggerType,
        'triggerData': triggerData == null ? null : triggerData.toString(),
        'actionType': actionType,
        'actionData': actionData == null ? null : actionData.toString(),
        'isActive': isActive ? 1 : 0,
        'createdAt': createdAt.toIso8601String(),
      };

  static AutomationRule fromDb(Map<String, dynamic> row) {
    Map<String, dynamic>? parseMap(dynamic raw) {
      if (raw == null) return null;
      final s = raw.toString();
      // naive parse: expect {k: v, k2: v2}
      if (!s.startsWith('{') || !s.endsWith('}')) return null;
      final inner = s.substring(1, s.length - 1).trim();
      if (inner.isEmpty) return {};
      final map = <String, dynamic>{};
      for (final part in inner.split(',')) {
        final kv = part.split(':');
        if (kv.length >= 2) {
          final k = kv.first.trim();
          final v = kv.sublist(1).join(':').trim();
          map[k] = v;
        }
      }
      return map;
    }
    return AutomationRule(
      id: row['id'] as String,
      name: row['name'] as String,
      triggerType: row['triggerType'] as String,
      triggerData: parseMap(row['triggerData']),
      actionType: row['actionType'] as String,
      actionData: parseMap(row['actionData']),
      isActive: row['isActive'] == 1 || row['isActive'] == true,
      createdAt: DateTime.tryParse(row['createdAt'].toString()) ?? DateTime.now(),
    );
  }
}

