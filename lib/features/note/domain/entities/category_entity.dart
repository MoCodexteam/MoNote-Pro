// lib/features/note/domain/entities/category_entity.dart

import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

/// Pure domain entity representing a category for notes.
/// Immutable, Equatable for easy comparison & state management.
class CategoryEntity extends Equatable {
  /// Unique identifier (can be slug, name lowercase, or UUID)
  final String id;

  /// Display name of the category (e.g. "Personal", "Work")
  final String name;

  /// Visual color associated with this category
  final Color color;

  /// Number of notes currently in this category (computed)
  final int noteCount;

  const CategoryEntity({
    required this.id,
    required this.name,
    required this.color,
    this.noteCount = 0,
  });

  /// Creates a new copy with optional overrides (immutable pattern)
  CategoryEntity copyWith({
    String? id,
    String? name,
    Color? color,
    int? noteCount,
  }) {
    return CategoryEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      color: color ?? this.color,
      noteCount: noteCount ?? this.noteCount,
    );
  }

  /// For better debugging / logging
  @override
  String toString() {
    return 'CategoryEntity(id: $id, name: $name, noteCount: $noteCount)';
  }

  @override
  List<Object?> get props => [id, name, color, noteCount];
}