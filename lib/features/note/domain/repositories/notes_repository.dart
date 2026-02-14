// lib/features/note/domain/repositories/notes_repository.dart

import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/note_entity.dart';

/// Abstract repository interface for all note-related operations.
/// This is the contract that:
/// - Presentation layer (use cases, providers) depends on
/// - Data layer (NotesRepositoryImpl) implements
abstract class NotesRepository {
  /// Real-time stream of the current user's notes
  /// Returns notes sorted by lastEdit descending (most recent first)
  Stream<List<NoteEntity>> getUserNotesStream(String userId);

  /// Creates a new note in the user's notes sub-collection
  Future<Either<Failure, Unit>> createNote(
      String userId,
      NoteEntity note,
      );

  /// Updates an existing note
  Future<Either<Failure, Unit>> updateNote(
      String userId,
      NoteEntity note,
      );

  /// Deletes a note by its ID
  Future<Either<Failure, Unit>> deleteNote(
      String userId,
      String noteId,
      );

  /// Toggles the pin status of a note
  Future<Either<Failure, Unit>> togglePin(
      String userId,
      String noteId,
      bool newPinValue,
      );

// Optional future methods (can be added later):
// Future<Either<Failure, NoteEntity>> getNoteById(String userId, String noteId);
// Future<Either<Failure, Unit>> archiveNote(String userId, String noteId);
// Future<Either<Failure, List<NoteEntity>>> searchNotes(String userId, String query);
}