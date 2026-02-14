// lib/features/note/domain/entities/note_entity.dart

import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

/// Pure domain entity for a Note in MoNote Pro
/// No Firebase/JSON dependencies here – clean and testable
class NoteEntity extends Equatable {
  final String id;              // document ID
  final String title;
  final String content;
  final DateTime dateCreated;   // تاريخ الإنشاء
  final String? category;
  final List<String> tags;
  final bool isPinned;
  final DateTime lastEdit;      // آخر تعديل
  final Color? categoryColor;   // للـ UI فقط (اختياري – يمكن تخزينه كـ hex string)

  const NoteEntity({
    required this.id,
    required this.title,
    required this.content,
    required this.dateCreated,
    required this.lastEdit,
    this.tags = const [],
    this.category,
    this.categoryColor,
    this.isPinned = false,
  });

  // Copy with for immutable updates
  NoteEntity copyWith({
    String? id,
    String? title,
    String? content,
    DateTime? dateCreated,
    DateTime? lastEdit,
    List<String>? tags,
    String? category,
    Color? categoryColor,
    bool? isPinned,
  }) {
    return NoteEntity(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      dateCreated: dateCreated ?? this.dateCreated,
      lastEdit: lastEdit ?? this.lastEdit,
      tags: tags ?? this.tags,
      category: category ?? this.category,
      categoryColor: categoryColor ?? this.categoryColor,
      isPinned: isPinned ?? this.isPinned,
    );
  }

  @override
  List<Object?> get props => [
    id,
    title,
    content,
    dateCreated,
    lastEdit,
    tags,
    category,
    categoryColor,
    isPinned,
  ];
}