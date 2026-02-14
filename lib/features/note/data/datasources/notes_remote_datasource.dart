// lib/features/note/data/datasources/notes_remote_datasource.dart

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/note_entity.dart';
import '../models/note_model.dart';

/// Remote data source responsible for all direct Firestore operations related to notes.
/// This is the only file in the app that directly uses FirebaseFirestore.
abstract class NotesRemoteDataSource {
  /// Returns a real-time stream of the user's notes (sorted by lastEdit descending)
  Stream<List<NoteModel>> getUserNotesStream(String userId);

  /// Creates a new note in the user's notes sub-collection
  Future<void> createNote(String userId, NoteModel note);

  /// Updates an existing note
  Future<void> updateNote(String userId, NoteModel note);

  /// Deletes a note by its ID
  Future<void> deleteNote(String userId, String noteId);

  /// Toggles the pin status of a note
  Future<void> togglePin(String userId, String noteId, bool newPinValue);
}

/// Concrete implementation using Firebase Firestore
class NotesRemoteDataSourceImpl implements NotesRemoteDataSource {
  final FirebaseFirestore _firestore;

  NotesRemoteDataSourceImpl({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Stream<List<NoteModel>> getUserNotesStream(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('notes')
        .orderBy('lastEdit', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => NoteModel.fromFirestore(doc)).toList();
    });
  }

  @override
  Future<void> createNote(String userId, NoteModel note) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('notes')
        .doc(note.id)
        .set(note.toFirestore());
  }

  @override
  Future<void> updateNote(String userId, NoteModel note) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('notes')
        .doc(note.id)
        .update(note.toFirestore());
  }

  @override
  Future<void> deleteNote(String userId, String noteId) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('notes')
        .doc(noteId)
        .delete();
  }

  @override
  Future<void> togglePin(String userId, String noteId, bool newPinValue) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('notes')
        .doc(noteId)
        .update({'pin': newPinValue});
  }
}