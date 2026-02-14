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
    );
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
        AppConstants.noteFieldCategoryColor: categoryColor!.value.toRadixString(16).padLeft(8, '0'),
      AppConstants.noteFieldPin: isPinned,
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
    );
  }
}