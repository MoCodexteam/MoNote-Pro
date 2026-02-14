// lib/features/note/presentation/providers/notes_provider.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_notifier.dart';
import '../../data/repositories/notes_repository_impl.dart';
import '../../domain/entities/note_entity.dart';
import '../../domain/repositories/notes_repository.dart';

// ────────────────────────────────────────────────
// Repository Provider (concrete implementation)
// ────────────────────────────────────────────────

final notesRepositoryProvider = Provider<NotesRepository>((ref) {
  return NotesRepositoryImpl();
});

// ────────────────────────────────────────────────
// Current user ID provider (for filtering notes)
// ────────────────────────────────────────────────

final currentUserIdProvider = Provider<String?>((ref) {
  final authState = ref.watch(authNotifierProvider);
  return authState.maybeWhen(
    authenticated: (user) => user.uid,
    orElse: () => null,
  );
});

// ────────────────────────────────────────────────
// Stream of user's notes (real-time from Firestore)
// ────────────────────────────────────────────────

final notesStreamProvider = StreamProvider.autoDispose<List<NoteEntity>>((ref) {
  final userId = ref.watch(currentUserIdProvider);

  if (userId == null) {
    return Stream.value(<NoteEntity>[]);
  }

  final repo = ref.watch(notesRepositoryProvider);

  return repo.getUserNotesStream(userId);
});

// ────────────────────────────────────────────────
// Filtered notes (search + pinned/regular separation)
// ────────────────────────────────────────────────

final filteredNotesProvider = Provider.autoDispose.family<List<NoteEntity>, String>((ref, searchQuery) {
  final notesAsync = ref.watch(notesStreamProvider);

  return notesAsync.when(
    data: (notes) {
      if (searchQuery.isEmpty) return notes;

      final query = searchQuery.toLowerCase().trim();
      return notes.where((note) {
        return note.title.toLowerCase().contains(query) ||
            note.content.toLowerCase().contains(query) ||
            note.category?.toLowerCase().contains(query) == true ||
            note.tags.any((tag) => tag.toLowerCase().contains(query));
      }).toList();
    },
    loading: () => <NoteEntity>[],
    error: (_, __) => <NoteEntity>[],
  );
});

// ────────────────────────────────────────────────
// Pinned notes (derived from filtered)
// ────────────────────────────────────────────────

final pinnedNotesProvider = Provider.autoDispose<List<NoteEntity>>((ref) {
  final filtered = ref.watch(filteredNotesProvider(''));
  return filtered.where((n) => n.isPinned).toList();
});

// ────────────────────────────────────────────────
// Regular (non-pinned) notes
// ────────────────────────────────────────────────

final regularNotesProvider = Provider.autoDispose<List<NoteEntity>>((ref) {
  final filtered = ref.watch(filteredNotesProvider(''));
  return filtered.where((n) => !n.isPinned).toList();
});

// ────────────────────────────────────────────────
// CRUD Operations (add / update / delete / toggle pin)
// ────────────────────────────────────────────────

final notesActionsProvider = Provider<NotesActions>((ref) {
  final repo = ref.watch(notesRepositoryProvider);
  final userId = ref.watch(currentUserIdProvider);

  return NotesActions(
    repo: repo,
    userId: userId,
  );
});

class NotesActions {
  final NotesRepository repo;
  final String? userId;

  NotesActions({required this.repo, required this.userId});

  Future<void> createNote(NoteEntity note) async {
    if (userId == null) throw Exception('User not authenticated');
    await repo.createNote(userId!, note);
  }

  Future<void> updateNote(NoteEntity note) async {
    if (userId == null) throw Exception('User not authenticated');
    await repo.updateNote(userId!, note);
  }

  Future<void> deleteNote(String noteId) async {
    if (userId == null) throw Exception('User not authenticated');
    await repo.deleteNote(userId!, noteId);
  }

  Future<void> togglePin(String noteId, bool currentValue) async {
    if (userId == null) throw Exception('User not authenticated');
    await repo.togglePin(userId!, noteId, !currentValue);
  }
}