// lib/features/home/presentation/widgets/note_card.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../note/domain/entities/note_entity.dart';

/// Flutter equivalent of the React <NoteCard /> component
/// Matches the visual structure and behavior:
///   - Vertical category color bar on left
///   - Title (single line ellipsis) + pinned icon (filled when pinned)
///   - Content preview (2 lines ellipsis)
///   - Footer: relative time + category chip + tags count
///   - Subtle hover/tap feedback (shadow + scale)
class NoteCard extends StatelessWidget {
  final NoteEntity note;
  final int index; // Used for staggered animation delay
  final VoidCallback onTap;

  const NoteCard({
    super.key,
    required this.note,
    required this.index,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final timeAgo = _formatTimeAgo(note.lastEdit);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: Duration(milliseconds: 180 + index * 60),
        curve: Curves.easeOutCubic,
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: colorScheme.outlineVariant.withOpacity(0.3),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Vertical category color indicator
                  Container(
                    width: 4,
                    height: 64,
                    decoration: BoxDecoration(
                      color: note.categoryColor ?? colorScheme.primary,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),

                  const SizedBox(width: 12),

                  // Main content column
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title + Pin icon row
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                note.title.isEmpty ? 'Untitled' : note.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            if (note.isPinned)
                              Padding(
                                padding: const EdgeInsets.only(left: 8, top: 2),
                                child: Icon(
                                  Icons.push_pin,
                                  size: 18,
                                  color: colorScheme.primary,
                                  fill: 1.0, // filled pin
                                ),
                              ),
                          ],
                        ),

                        const SizedBox(height: 4),

                        // Content preview
                        Text(
                          note.content.isEmpty
                              ? 'No content yet...'
                              : note.content,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                            height: 1.4,
                          ),
                        ),

                        const SizedBox(height: 12),

                        // Footer row
                        Wrap(
                          spacing: 12,
                          runSpacing: 8,
                          children: [
                            // Timestamp
                            Text(
                              timeAgo,
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: colorScheme.onSurfaceVariant.withOpacity(0.8),
                              ),
                            ),

                            // Category chip
                            if (note.category != null && note.category!.isNotEmpty)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: colorScheme.surfaceContainerHighest,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  note.category!,
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ),

                            // Tags count
                            if (note.tags.isNotEmpty)
                              Text(
                                '${note.tags.length} ${note.tags.length == 1 ? "tag" : "tags"}',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: colorScheme.onSurfaceVariant.withOpacity(0.8),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Format relative time (similar to date-fns formatDistanceToNow)
  String _formatTimeAgo(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays > 365) {
      final years = (diff.inDays / 365).floor();
      return '$years${years == 1 ? "y" : "y"} ago';
    } else if (diff.inDays > 30) {
      final months = (diff.inDays / 30).floor();
      return '$months${months == 1 ? "mo" : "mo"} ago';
    } else if (diff.inDays > 0) {
      return '${diff.inDays}d ago';
    } else if (diff.inHours > 0) {
      return '${diff.inHours}h ago';
    } else if (diff.inMinutes > 0) {
      return '${diff.inMinutes}m ago';
    } else {
      return 'just now';
    }
  }
}