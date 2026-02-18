import 'subtask.dart';
import 'tag.dart';

class Task {
  final String id;
  final String userId;
  final String title;
  final String? description;
  final DateTime? dueDate;
  final int? estimatedMinutes;
  final int priority; // 0: none, 1: low, 2: medium, 3: high
  final bool isCompleted;
  final DateTime? completedAt;
  final int sortOrder;
  final DateTime? reminderAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<SubTask> subtasks;
  final List<Tag> tags;

  const Task({
    required this.id,
    required this.userId,
    required this.title,
    this.description,
    this.dueDate,
    this.estimatedMinutes,
    this.priority = 0,
    this.isCompleted = false,
    this.completedAt,
    this.sortOrder = 0,
    this.reminderAt,
    required this.createdAt,
    required this.updatedAt,
    this.subtasks = const [],
    this.tags = const [],
  });

  String get priorityLabel {
    switch (priority) {
      case 1:
        return '低';
      case 2:
        return '中';
      case 3:
        return '高';
      default:
        return 'なし';
    }
  }

  String? get estimatedTimeLabel {
    if (estimatedMinutes == null) return null;
    final hours = estimatedMinutes! ~/ 60;
    final minutes = estimatedMinutes! % 60;
    if (hours > 0 && minutes > 0) return '${hours}時間${minutes}分';
    if (hours > 0) return '${hours}時間';
    return '${minutes}分';
  }

  double get completionRate {
    if (subtasks.isEmpty) return isCompleted ? 1.0 : 0.0;
    final completed = subtasks.where((s) => s.isCompleted).length;
    return completed / subtasks.length;
  }

  factory Task.fromJson(Map<String, dynamic> json,
      {List<SubTask>? subtasks, List<Tag>? tags}) {
    return Task(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      dueDate: json['due_date'] != null
          ? DateTime.parse(json['due_date'] as String)
          : null,
      estimatedMinutes: json['estimated_minutes'] as int?,
      priority: json['priority'] as int? ?? 0,
      isCompleted: json['is_completed'] as bool? ?? false,
      completedAt: json['completed_at'] != null
          ? DateTime.parse(json['completed_at'] as String)
          : null,
      sortOrder: json['sort_order'] as int? ?? 0,
      reminderAt: json['reminder_at'] != null
          ? DateTime.parse(json['reminder_at'] as String)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      subtasks: subtasks ?? [],
      tags: tags ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'title': title,
      'description': description,
      'due_date': dueDate?.toIso8601String(),
      'estimated_minutes': estimatedMinutes,
      'priority': priority,
      'is_completed': isCompleted,
      'completed_at': completedAt?.toIso8601String(),
      'sort_order': sortOrder,
      'reminder_at': reminderAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  Map<String, dynamic> toInsertJson() {
    return {
      'id': id,
      'user_id': userId,
      'title': title,
      'description': description,
      'due_date': dueDate?.toIso8601String(),
      'estimated_minutes': estimatedMinutes,
      'priority': priority,
      'is_completed': isCompleted,
      'sort_order': sortOrder,
      'reminder_at': reminderAt?.toIso8601String(),
    };
  }

  Task copyWith({
    String? id,
    String? userId,
    String? title,
    String? description,
    bool clearDescription = false,
    DateTime? dueDate,
    bool clearDueDate = false,
    int? estimatedMinutes,
    bool clearEstimatedMinutes = false,
    int? priority,
    bool? isCompleted,
    DateTime? completedAt,
    bool clearCompletedAt = false,
    int? sortOrder,
    DateTime? reminderAt,
    bool clearReminderAt = false,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<SubTask>? subtasks,
    List<Tag>? tags,
  }) {
    return Task(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      description:
          clearDescription ? null : (description ?? this.description),
      dueDate: clearDueDate ? null : (dueDate ?? this.dueDate),
      estimatedMinutes: clearEstimatedMinutes
          ? null
          : (estimatedMinutes ?? this.estimatedMinutes),
      priority: priority ?? this.priority,
      isCompleted: isCompleted ?? this.isCompleted,
      completedAt:
          clearCompletedAt ? null : (completedAt ?? this.completedAt),
      sortOrder: sortOrder ?? this.sortOrder,
      reminderAt: clearReminderAt ? null : (reminderAt ?? this.reminderAt),
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      subtasks: subtasks ?? this.subtasks,
      tags: tags ?? this.tags,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Task && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
