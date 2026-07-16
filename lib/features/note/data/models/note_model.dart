// lib/features/note/data/models/note_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../../../core/constants/app_constants.dart';
import '../../domain/entities/note_entity.dart';

/// Data layer model that maps between Firestore documents and the pure domain entity (NoteEntity).
/// This class handles serialization/deserialization for Firestore only.
/// No business logic here – just data mapping.
class NoteModel extends NoteEntity {
  const NoteModel({
    required super.id,
    required super.title,
    required super.content,
    required super.dateCreated,
    required super.lastEdit,
    super.tags,
    super.category,
    super.categoryColor,
    super.isPinned,
    super.isArchived,
    super.isDeleted,
    super.deletedAt,
    super.checklistItems,
    super.reminderEnabled,
    super.reminderDate,
    super.reminderInterval,
  });

  /// Creates a NoteModel from a Firestore document snapshot
  factory NoteModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    return NoteModel(
      id: doc.id,
      title: data[AppConstants.noteFieldTitle] as String? ?? 'Untitled',
      content: data[AppConstants.noteFieldContent] as String? ?? '',
      dateCreated: (data[AppConstants.noteFieldDateCreated] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastEdit: (data[AppConstants.noteFieldLastEdit] as Timestamp?)?.toDate() ?? DateTime.now(),
      tags: List<String>.from(data[AppConstants.noteFieldTags] ?? []),
      category: data[AppConstants.noteFieldCategory] as String?,
      // If categoryColor is stored as hex string, parse it here (optional)
      categoryColor: data[AppConstants.noteFieldCategoryColor] != null
          ? Color(int.parse(data[AppConstants.noteFieldCategoryColor] as String, radix: 16))
          : null,
      isPinned: data[AppConstants.noteFieldPin] as bool? ?? false,
      isArchived: data[AppConstants.noteFieldArchive] as bool? ?? false,
      isDeleted: data[AppConstants.noteFieldDeleted] as bool? ?? false,
      deletedAt: (data[AppConstants.noteFieldDeletedAt] as Timestamp?)?.toDate(),
      checklistItems: _parseChecklistItems(data[AppConstants.noteFieldChecklistItems]),
      reminderEnabled: data[AppConstants.noteFieldReminderEnabled] as bool? ?? false,
      reminderDate: (data[AppConstants.noteFieldReminderDate] as Timestamp?)?.toDate(),
      reminderInterval: data[AppConstants.noteFieldReminderInterval] as int?,
    );
  }

  static List<NoteChecklistItem> _parseChecklistItems(Object? value) {
    if (value is! List) return const [];

    return value.map((item) {
      if (item is! Map) {
        return const NoteChecklistItem(id: '', text: '');
      }

      final map = Map<String, dynamic>.from(item);
      return NoteChecklistItem(
        id: map['id']?.toString() ?? '',
        text: map['text']?.toString() ?? '',
        isCompleted: map['isCompleted'] as bool? ?? false,
      );
    }).where((item) => item.text.isNotEmpty || item.id.isNotEmpty).toList();
  }

  /// Converts the model back to a Firestore-compatible map
  Map<String, dynamic> toFirestore() {
    return {
      AppConstants.noteFieldTitle: title,
      AppConstants.noteFieldContent: content,
      AppConstants.noteFieldDateCreated: Timestamp.fromDate(dateCreated),
      AppConstants.noteFieldLastEdit: Timestamp.fromDate(lastEdit),
      AppConstants.noteFieldTags: tags,
      if (category != null) AppConstants.noteFieldCategory: category,
      if (categoryColor != null)
        AppConstants.noteFieldCategoryColor: categoryColor!.toARGB32().toRadixString(16).padLeft(8, '0'),
      AppConstants.noteFieldPin: isPinned,
      AppConstants.noteFieldArchive: isArchived,
      AppConstants.noteFieldDeleted: isDeleted,
      AppConstants.noteFieldDeletedAt: deletedAt != null ? Timestamp.fromDate(deletedAt!) : null,
      AppConstants.noteFieldChecklistItems: checklistItems
          .map((item) => {
            'id': item.id,
            'text': item.text,
            'isCompleted': item.isCompleted,
          })
          .toList(),
      AppConstants.noteFieldReminderEnabled: reminderEnabled,
      if (reminderDate != null) AppConstants.noteFieldReminderDate: Timestamp.fromDate(reminderDate!),
      if (reminderInterval != null) AppConstants.noteFieldReminderInterval: reminderInterval,
    };
  }

  /// Converts this model back to the pure domain entity (when passing to use-cases or UI)
  NoteEntity toEntity() => this;

  /// Factory to create a new empty note model (useful for create/edit forms)
  factory NoteModel.empty({
    required String id,
    required DateTime now,
  }) {
    return NoteModel(
      id: id,
      title: '',
      content: '',
      dateCreated: now,
      lastEdit: now,
      tags: const [],
      isPinned: false,
      isArchived: false,
      checklistItems: const [],
    );
  }
}