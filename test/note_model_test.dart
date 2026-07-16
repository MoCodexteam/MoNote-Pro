import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:monotepro/core/constants/app_constants.dart';
import 'package:monotepro/features/note/data/models/note_model.dart';
import 'package:monotepro/features/note/domain/entities/note_entity.dart';

void main() {
  test('serializes checklist items to Firestore data', () {
    final now = DateTime(2026, 7, 12);

    final note = NoteModel(
      id: 'note-1',
      title: 'Shopping list',
      content: 'Buy groceries',
      dateCreated: now,
      lastEdit: now,
      checklistItems: const [
        NoteChecklistItem(id: '1', text: 'Milk', isCompleted: false),
        NoteChecklistItem(id: '2', text: 'Bread', isCompleted: true),
      ],
    );

    final data = note.toFirestore();

    expect(data[AppConstants.noteFieldChecklistItems], isA<List<Map<String, dynamic>>>());
    expect(data[AppConstants.noteFieldChecklistItems].length, 2);
  });

  test('serializes soft-delete fields for trash flow', () {
    final now = DateTime(2026, 7, 12);
    final deletedAt = DateTime(2026, 7, 10);

    final note = NoteModel(
      id: 'note-2',
      title: 'Trash test',
      content: 'Will be restored later',
      dateCreated: now,
      lastEdit: now,
      isDeleted: true,
      deletedAt: deletedAt,
    );

    final data = note.toFirestore();

    expect(data['isDeleted'], isTrue);
    expect(data['deletedAt'], isA<Timestamp>());
    expect((data['deletedAt'] as Timestamp).toDate(), equals(deletedAt));
  });
}
