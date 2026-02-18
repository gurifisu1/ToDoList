import 'package:flutter/material.dart';

class Tag {
  final String id;
  final String userId;
  final String name;
  final String color;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Tag({
    required this.id,
    required this.userId,
    required this.name,
    this.color = '#6C63FF',
    required this.createdAt,
    required this.updatedAt,
  });

  Color get colorValue {
    final hex = color.replaceFirst('#', '');
    return Color(int.parse('FF$hex', radix: 16));
  }

  factory Tag.fromJson(Map<String, dynamic> json) {
    return Tag(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      name: json['name'] as String,
      color: json['color'] as String? ?? '#6C63FF',
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'name': name,
      'color': color,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  Map<String, dynamic> toInsertJson() {
    return {
      'id': id,
      'user_id': userId,
      'name': name,
      'color': color,
    };
  }

  Tag copyWith({
    String? id,
    String? userId,
    String? name,
    String? color,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Tag(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      color: color ?? this.color,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Tag && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
