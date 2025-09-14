// lib/models/user.dart
class User {
  final String id;
  final String name;
  final String email;
  final String? profileImagePath;
  final DateTime createdAt;
  final DateTime? lastLoginAt;
  final Map<String, dynamic> preferences;
  final bool notificationsEnabled;
  final String? phoneNumber;
  final String? department;
  final String? jobTitle;

  User({
    required this.id,
    required this.name,
    required this.email,
    this.profileImagePath,
    DateTime? createdAt,
    this.lastLoginAt,
    this.preferences = const {},
    this.notificationsEnabled = true,
    this.phoneNumber,
    this.department,
    this.jobTitle,
  }) : createdAt = createdAt ?? DateTime.now();

  User copyWith({
    String? id,
    String? name,
    String? email,
    String? profileImagePath,
    DateTime? createdAt,
    DateTime? lastLoginAt,
    Map<String, dynamic>? preferences,
    bool? notificationsEnabled,
    String? phoneNumber,
    String? department,
    String? jobTitle,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      profileImagePath: profileImagePath ?? this.profileImagePath,
      createdAt: createdAt ?? this.createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      preferences: preferences ?? this.preferences,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      department: department ?? this.department,
      jobTitle: jobTitle ?? this.jobTitle,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'profileImagePath': profileImagePath,
      'createdAt': createdAt.toIso8601String(),
      'lastLoginAt': lastLoginAt?.toIso8601String(),
      'preferences': preferences,
      'notificationsEnabled': notificationsEnabled,
      'phoneNumber': phoneNumber,
      'department': department,
      'jobTitle': jobTitle,
    };
  }

  static User fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      profileImagePath: json['profileImagePath'],
      createdAt: DateTime.parse(json['createdAt']),
      lastLoginAt: json['lastLoginAt'] != null
          ? DateTime.parse(json['lastLoginAt'])
          : null,
      preferences: Map<String, dynamic>.from(json['preferences'] ?? {}),
      notificationsEnabled: json['notificationsEnabled'] ?? true,
      phoneNumber: json['phoneNumber'],
      department: json['department'],
      jobTitle: json['jobTitle'],
    );
  }

  String get initials {
    final nameParts = name.split(' ');
    if (nameParts.length >= 2) {
      return '${nameParts[0][0]}${nameParts[1][0]}'.toUpperCase();
    } else if (nameParts.isNotEmpty) {
      return nameParts[0][0].toUpperCase();
    }
    return 'U';
  }

  String get displayName => name.isNotEmpty ? name : email;
}
