// lib/features/notifications/presentation/screens/notifications_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/notifications_provider.dart';

class NotificationsScreen extends ConsumerWidget {
  final VoidCallback onBack;

  const NotificationsScreen({super.key, required this.onBack});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsState = ref.watch(notificationsProvider);
    final notifications = notificationsState.notifications;
    final notifier = ref.read(notificationsProvider.notifier);

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                border: Border(
                  bottom: BorderSide(color: Theme.of(context).dividerColor),
                ),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: onBack,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Notifications',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  if (notifications.isNotEmpty)
                    TextButton.icon(
                      onPressed: () async {
                        await notifier.clearAll();
                      },
                      icon: const Icon(Icons.delete_sweep, size: 18),
                      label: const Text('Clear All'),
                      style: TextButton.styleFrom(
                        foregroundColor: Theme.of(context).colorScheme.error,
                      ),
                    ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: notificationsState.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : notifications.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.notifications_outlined,
                                size: 64,
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No notifications yet',
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Your reminders and notifications will appear here',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: notifications.length,
                          itemBuilder: (context, index) {
                            final notification = notifications[index];
                            final isPast = notification.scheduledDate.isBefore(DateTime.now());
                            
                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              elevation: notification.isRead ? 0 : 2,
                              color: notification.isRead 
                                  ? null 
                                  : Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.3),
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                leading: Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: isPast
                                        ? Theme.of(context).colorScheme.errorContainer
                                        : Theme.of(context).colorScheme.primaryContainer,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    isPast ? Icons.event_busy : Icons.notification_important,
                                    color: isPast
                                        ? Theme.of(context).colorScheme.onErrorContainer
                                        : Theme.of(context).colorScheme.onPrimaryContainer,
                                  ),
                                ),
                                title: Text(
                                  notification.title,
                                  style: TextStyle(
                                    fontWeight: notification.isRead ? FontWeight.normal : FontWeight.bold,
                                  ),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 4),
                                    Text(
                                      notification.body,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.access_time,
                                          size: 14,
                                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          _formatDateTime(notification.scheduledDate),
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: isPast
                                                ? Theme.of(context).colorScheme.error
                                                : Theme.of(context).colorScheme.onSurfaceVariant,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                trailing: IconButton(
                                  icon: const Icon(Icons.close, size: 20),
                                  onPressed: () async {
                                    await notifier.removeNotification(notification.id);
                                  },
                                ),
                                onTap: () async {
                                  if (!notification.isRead) {
                                    await notifier.markAsRead(notification.id);
                                  }
                                },
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = dateTime.difference(now);
    
    if (difference.isNegative) {
      final pastDifference = now.difference(dateTime);
      if (pastDifference.inDays > 0) {
        return '${pastDifference.inDays} days ago';
      } else if (pastDifference.inHours > 0) {
        return '${pastDifference.inHours} hours ago';
      } else if (pastDifference.inMinutes > 0) {
        return '${pastDifference.inMinutes} minutes ago';
      } else {
        return 'Just now';
      }
    } else {
      if (difference.inDays > 0) {
        return 'In ${difference.inDays} days';
      } else if (difference.inHours > 0) {
        return 'In ${difference.inHours} hours';
      } else if (difference.inMinutes > 0) {
        return 'In ${difference.inMinutes} minutes';
      } else {
        return 'Soon';
      }
    }
  }
}
