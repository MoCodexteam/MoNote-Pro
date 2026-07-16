// lib/features/notifications/domain/entities/notification_entity.dart

import 'package:equatable/equatable.dart';

class NotificationEntity extends Equatable {
  final String id;
  final String title;
  final String body;
  final DateTime scheduledDate;
  final String? noteId; // Reference to the note this notification is for
  final bool isRead;
  final DateTime createdAt;

  const NotificationEntity({
    required this.id,
    required this.title,
    required this.body,
    required this.scheduledDate,
    this.noteId,
    this.isRead = false,
    required this.createdAt,
  });

  NotificationEntity copyWith({
    String? id,
    String? title,
    String? body,
    DateTime? scheduledDate,
    String? noteId,
    bool? isRead,
    DateTime? createdAt,
  }) {
    return NotificationEntity(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      scheduledDate: scheduledDate ?? this.scheduledDate,
      noteId: noteId ?? this.noteId,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        title,
        body,
        scheduledDate,
        noteId,
        isRead,
        createdAt,
      ];
}
