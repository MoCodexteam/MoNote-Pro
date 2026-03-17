// lib/features/home/presentation/providers/notes_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../note/domain/entities/note_entity.dart';

// مؤقت: بيانات وهمية للملاحظات حتى نربط Firestore لاحقًا
final notesProvider = Provider<List<NoteEntity>>((ref) {
  return [];
});