import 'tag.dart';

class SubTask {
  final String id;
  final String taskId;
  final String userId;
  final String title;
  final DateTime? dueDate;
  final int priority; // 0: none, 1: low, 2: medium, 3: high
  final bool isCompleted;
  final DateTime? completedAt;
  final int sortOrder;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<Tag> tags;

  const SubTask({
    required this.id,
    required this.taskId,
    required this.userId,
    required this.title,
    this.dueDate,
    this.priority = 0,
    this.isCompleted = false,
    this.completedAt,
    this.sortOrder = 0,
    required this.createdAt,
    required this.updatedAt,
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

  factory SubTask.fromJson(Map<String, dynamic> json, {List<Tag>? tags}) {
    return SubTask(
      id: json['id'] as String,
      taskId: json['task_id'] as String,
      userId: json['user_id'] as String,
      title: json['title'] as String,
      dueDate: json['due_date'] != null
          ? DateTime.parse(json['due_date'] as String)
          : null,
      priority: json['priority'] as int? ?? 0,
      isCompleted: json['is_completed'] as bool? ?? false,
      completedAt: json['completed_at'] != null
          ? DateTime.parse(json['completed_at'] as String)
          : null,
      sortOrder: json['sort_order'] as int? ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      tags: tags ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'task_id': taskId,
      'user_id': userId,
      'title': title,
      'due_date': dueDate?.toIso8601String(),
      'priority': priority,
      'is_completed': isCompleted,
      'completed_at': completedAt?.toIso8601String(),
      'sort_order': sortOrder,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  Map<String, dynamic> toInsertJson() {
    return {
      'id': id,
      'task_id': taskId,
      'user_id': userId,
      'title': title,
      'due_date': dueDate?.toIso8601String(),
      'priority': priority,
      'is_completed': isCompleted,
      'sort_order': sortOrder,
    };
  }

  SubTask copyWith({
    String? id,
    String? taskId,
    String? userId,
    String? title,
    DateTime? dueDate,
    bool clearDueDate = false,
    int? priority,
    bool? isCompleted,
    DateTime? completedAt,
    bool clearCompletedAt = false,
    int? sortOrder,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<Tag>? tags,
  }) {
    return SubTask(
      id: id ?? this.id,
      taskId: taskId ?? this.taskId,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      dueDate: clearDueDate ? null : (dueDate ?? this.dueDate),
      priority: priority ?? this.priority,
      isCompleted: isCompleted ?? this.isCompleted,
      completedAt:
          clearCompletedAt ? null : (completedAt ?? this.completedAt),
      sortOrder: sortOrder ?? this.sortOrder,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      tags: tags ?? this.tags,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is SubTask && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
