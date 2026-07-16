// lib/features/note/domain/entities/note_entity.dart

import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

class NoteChecklistItem extends Equatable {
  final String id;
  final String text;
  final bool isCompleted;

  const NoteChecklistItem({
    required this.id,
    required this.text,
    this.isCompleted = false,
  });

  NoteChecklistItem copyWith({
    String? id,
    String? text,
    bool? isCompleted,
  }) {
    return NoteChecklistItem(
      id: id ?? this.id,
      text: text ?? this.text,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }

  @override
  List<Object?> get props => [id, text, isCompleted];
}

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
  final bool isArchived;
  final bool isDeleted;
  final DateTime? deletedAt;
  final DateTime lastEdit;      // آخر تعديل
  final Color? categoryColor;   // للـ UI فقط (اختياري – يمكن تخزينه كـ hex string)
  final List<NoteChecklistItem> checklistItems;
  
  // Notification fields
  final bool reminderEnabled;   // تفعيل التذكير
  final DateTime? reminderDate; // تاريخ التذكير
  final int? reminderInterval;  // فترة التكرار بالأيام (مثلاً 3 = كل 3 أيام)

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
    this.isArchived = false,
    this.isDeleted = false,
    this.deletedAt,
    this.checklistItems = const [],
    this.reminderEnabled = false,
    this.reminderDate,
    this.reminderInterval,
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
    bool? isArchived,
    bool? isDeleted,
    DateTime? deletedAt,
    List<NoteChecklistItem>? checklistItems,
    bool? reminderEnabled,
    DateTime? reminderDate,
    int? reminderInterval,
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
      isArchived: isArchived ?? this.isArchived,
      isDeleted: isDeleted ?? this.isDeleted,
      deletedAt: deletedAt ?? this.deletedAt,
      checklistItems: checklistItems ?? this.checklistItems,
      reminderEnabled: reminderEnabled ?? this.reminderEnabled,
      reminderDate: reminderDate ?? this.reminderDate,
      reminderInterval: reminderInterval ?? this.reminderInterval,
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
    isArchived,
    isDeleted,
    deletedAt,
    checklistItems,
    reminderEnabled,
    reminderDate,
    reminderInterval,
  ];
}