// lib/features/notifications/presentation/providers/notifications_provider.dart

import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../../domain/entities/notification_entity.dart';

class NotificationsState {
  final List<NotificationEntity> notifications;
  final bool isLoading;
  final String? error;

  const NotificationsState({
    this.notifications = const [],
    this.isLoading = false,
    this.error,
  });

  NotificationsState copyWith({
    List<NotificationEntity>? notifications,
    bool? isLoading,
    String? error,
  }) {
    return NotificationsState(
      notifications: notifications ?? this.notifications,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class NotificationsNotifier extends StateNotifier<NotificationsState> {
  NotificationsNotifier() : super(const NotificationsState()) {
    _loadNotifications();
  }

  static const String _storageKey = 'notifications';

  Future<void> _loadNotifications() async {
    state = state.copyWith(isLoading: true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final notificationsJson = prefs.getString(_storageKey);

      if (notificationsJson != null) {
        final List<dynamic> decoded = json.decode(notificationsJson);
        final notifications = decoded
            .map((json) => NotificationEntity(
                  id: json['id'],
                  title: json['title'],
                  body: json['body'],
                  scheduledDate: DateTime.parse(json['scheduledDate']),
                  noteId: json['noteId'],
                  isRead: json['isRead'] ?? false,
                  createdAt: DateTime.parse(json['createdAt']),
                ))
            .toList();

        // Sort by scheduled date (nearest first)
        notifications
            .sort((a, b) => a.scheduledDate.compareTo(b.scheduledDate));

        state = state.copyWith(notifications: notifications, isLoading: false);
      } else {
        state = state.copyWith(isLoading: false);
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load notifications: $e',
      );
    }
  }

  Future<void> _saveNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final notificationsJson = json.encode(
        state.notifications
            .map((n) => {
                  'id': n.id,
                  'title': n.title,
                  'body': n.body,
                  'scheduledDate': n.scheduledDate.toIso8601String(),
                  'noteId': n.noteId,
                  'isRead': n.isRead,
                  'createdAt': n.createdAt.toIso8601String(),
                })
            .toList(),
      );
      await prefs.setString(_storageKey, notificationsJson);
    } catch (e) {
      state = state.copyWith(error: 'Failed to save notifications: $e');
    }
  }

  Future<void> addNotification({
    required String title,
    required String body,
    required DateTime scheduledDate,
    String? noteId,
  }) async {
    final notification = NotificationEntity(
      id: const Uuid().v4(),
      title: title,
      body: body,
      scheduledDate: scheduledDate,
      noteId: noteId,
      createdAt: DateTime.now(),
    );

    final updatedNotifications = [...state.notifications, notification];
    updatedNotifications
        .sort((a, b) => a.scheduledDate.compareTo(b.scheduledDate));

    state = state.copyWith(notifications: updatedNotifications);
    await _saveNotifications();
  }

  Future<void> removeNotification(String id) async {
    final updatedNotifications =
        state.notifications.where((n) => n.id != id).toList();
    state = state.copyWith(notifications: updatedNotifications);
    await _saveNotifications();
  }

  Future<void> markAsRead(String id) async {
    final updatedNotifications = state.notifications.map((n) {
      if (n.id == id) {
        return n.copyWith(isRead: true);
      }
      return n;
    }).toList();
    state = state.copyWith(notifications: updatedNotifications);
    await _saveNotifications();
  }

  Future<void> markAllAsRead() async {
    final updatedNotifications =
        state.notifications.map((n) => n.copyWith(isRead: true)).toList();
    state = state.copyWith(notifications: updatedNotifications);
    await _saveNotifications();
  }

  Future<void> clearAll() async {
    state = state.copyWith(notifications: []);
    await _saveNotifications();
  }

  // Remove notifications for a specific note (when note is deleted)
  Future<void> removeNotificationsForNote(String noteId) async {
    final updatedNotifications =
        state.notifications.where((n) => n.noteId != noteId).toList();
    state = state.copyWith(notifications: updatedNotifications);
    await _saveNotifications();
  }
}

final notificationsProvider =
    StateNotifierProvider<NotificationsNotifier, NotificationsState>((ref) {
  return NotificationsNotifier();
});
