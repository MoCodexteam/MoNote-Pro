// lib/features/note/data/repositories/notes_repository_impl.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../../domain/entities/note_entity.dart';
import '../../domain/repositories/notes_repository.dart';
import '../datasources/notes_remote_datasource.dart';
import '../models/note_model.dart';

/// Concrete implementation of NotesRepository.
/// This class bridges the domain layer and the data sources (Firestore).
/// All external dependencies (Firebase) are hidden here.
class NotesRepositoryImpl implements NotesRepository {
  final NotesRemoteDataSource _remoteDataSource;

  NotesRepositoryImpl({
    NotesRemoteDataSource? remoteDataSource,
  }) : _remoteDataSource = remoteDataSource ?? NotesRemoteDataSourceImpl();

  @override
  Stream<List<NoteEntity>> getUserNotesStream(String userId) {
    return _remoteDataSource.getUserNotesStream(userId).map(
          (models) => models.map((m) => m.toEntity()).toList(),
    );
  }

  @override
  Future<Either<Failure, Unit>> createNote(String userId, NoteEntity note) async {
    try {
      final model = NoteModel(
        id: note.id,
        title: note.title,
        content: note.content,
        dateCreated: note.dateCreated,
        lastEdit: note.lastEdit,
        tags: note.tags,
        category: note.category,
        categoryColor: note.categoryColor,
        isPinned: note.isPinned,
      );

      await _remoteDataSource.createNote(userId, model);
      return const Right(unit);
    } on FirebaseException catch (e) {
      return Left(ServerFailure(e.message ?? 'Firestore error during note creation'));
    } catch (e) {
      return Left(ServerFailure('Unexpected error: $e'));
    }
  }

  @override
  Future<Either<Failure, Unit>> updateNote(String userId, NoteEntity note) async {
    try {
      final model = NoteModel(
        id: note.id,
        title: note.title,
        content: note.content,
        dateCreated: note.dateCreated,
        lastEdit: note.lastEdit,
        tags: note.tags,
        category: note.category,
        categoryColor: note.categoryColor,
        isPinned: note.isPinned,
      );

      await _remoteDataSource.updateNote(userId, model);
      return const Right(unit);
    } on FirebaseException catch (e) {
      return Left(ServerFailure(e.message ?? 'Firestore error during note update'));
    } catch (e) {
      return Left(ServerFailure('Unexpected error: $e'));
    }
  }

  @override
  Future<Either<Failure, Unit>> deleteNote(String userId, String noteId) async {
    try {
      await _remoteDataSource.deleteNote(userId, noteId);
      return const Right(unit);
    } on FirebaseException catch (e) {
      return Left(ServerFailure(e.message ?? 'Firestore error during note deletion'));
    } catch (e) {
      return Left(ServerFailure('Unexpected error: $e'));
    }
  }

  @override
  Future<Either<Failure, Unit>> togglePin(String userId, String noteId, bool newPinValue) async {
    try {
      await _remoteDataSource.togglePin(userId, noteId, newPinValue);
      return const Right(unit);
    } on FirebaseException catch (e) {
      return Left(ServerFailure(e.message ?? 'Firestore error during pin toggle'));
    } catch (e) {
      return Left(ServerFailure('Unexpected error: $e'));
    }
  }
}