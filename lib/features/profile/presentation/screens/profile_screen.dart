// lib/features/profile/presentation/screens/profile_screen.dart


import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../../auth/presentation/providers/auth_notifier.dart';
import '../../../auth/presentation/providers/auth_state.dart';
import '/core/theme/theme_provider.dart';
import '../../../note/presentation/providers/notes_provider.dart';

/// شاشة الملف الشخصي والإعدادات – كاملة الوظائف
/// يدعم:
/// - عرض بيانات المستخدم الحقيقية
/// - إحصائيات دقيقة (ملاحظات، مثبتة، فئات)
/// - تبديل Dark Mode مع حفظ دائم
/// - تصدير جميع الملاحظات كـ JSON (مشاركة أو حفظ)
/// - تسجيل الخروج
class ProfileScreen extends ConsumerStatefulWidget {
  final VoidCallback onBack;

  const ProfileScreen({super.key, required this.onBack});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _isSyncing = false;
  String _syncStatus = 'All changes saved';
  bool _notificationsEnabled = true;

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authNotifierProvider).currentUser;
    final themeMode = ref.watch(themeModeProvider);

    final notesAsync = ref.watch(allNotesStreamProvider);
    final notesCount = notesAsync.value?.where((n) => !n.isDeleted).length ?? 0;
    final pinnedCount = notesAsync.value?.where((n) => !n.isDeleted && n.isPinned).length ?? 0;
    final archivedCount = notesAsync.value?.where((n) => !n.isDeleted && n.isArchived).length ?? 0;
    final trashCount = notesAsync.value?.where((n) => n.isDeleted).length ?? 0;

    final categoriesCount = notesAsync.value
        ?.where((n) => !n.isDeleted)
        .map((n) => n.category)
        .where((c) => c != null && c.isNotEmpty)
        .toSet()
        .length ??
        0;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            _buildHeader(context),

            // المحتوى الرئيسي
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // بطاقة المستخدم + الإحصائيات
                    _buildUserInfoCard(
                      context,
                      user,
                      notesCount,
                      pinnedCount,
                      archivedCount,
                      trashCount,
                      categoriesCount,
                    ),

                    const SizedBox(height: 24),

                    // الإعدادات
                    _buildSettingsCard(context, themeMode, ref),

                    const SizedBox(height: 48),

                    // App Info
                    _buildAppInfo(context),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
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
            icon: Icon(Icons.arrow_back, color: Theme.of(context).colorScheme.onSurface),
            onPressed: onBack,
          ),
          const SizedBox(width: 12),
          Text(
            'Profile & Settings',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildUserInfoCard(
      BuildContext context,
      UserEntity? user,
      int notesCount,
      int pinnedCount,
      int archivedCount,
      int trashCount,
      int categoriesCount,
      ) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  child: Text(
                    user?.fullName?.substring(0, 1).toUpperCase() ?? '?',
                    style: const TextStyle(fontSize: 32, color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user?.fullName ?? 'User',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.mail_outline, size: 16, color: Theme.of(context).colorScheme.onSurfaceVariant),
                          const SizedBox(width: 6),
                          Text(
                            user?.email ?? 'No email',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildStatItem(context, Icons.note_alt_outlined, Colors.blue, notesCount, 'Notes'),
                _buildStatItem(context, Icons.folder_outlined, Colors.teal, categoriesCount, 'Categories'),
                _buildStatItem(context, Icons.push_pin_outlined, Colors.purple, pinnedCount, 'Pinned'),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildStatItem(context, Icons.archive_outlined, Colors.orange, archivedCount, 'Archive'),
                _buildStatItem(context, Icons.delete_outline, Colors.red, trashCount, 'Trash'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(BuildContext context, IconData icon, Color color, int value, String label) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, color: color, size: 28),
        ),
        const SizedBox(height: 8),
        Text('$value', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
        Text(label, style: Theme.of(context).textTheme.labelMedium?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
      ],
    );
  }

  Widget _buildProfileActionTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    String? subtitle,
    Widget? trailing,
    VoidCallback? onTap,
    Color? accentColor,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final accent = accentColor ?? colorScheme.primary;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: accent.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: accent),
      ),
      title: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            )
          : null,
      trailing: trailing ?? Icon(Icons.chevron_right, color: colorScheme.onSurfaceVariant),
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }

  Widget _buildSettingsCard(BuildContext context, ThemeMode themeMode, WidgetRef ref) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          _buildProfileActionTile(
            context,
            icon: Icons.dark_mode_outlined,
            title: 'Dark Mode',
            subtitle: themeMode == ThemeMode.dark ? 'Enabled' : 'Disabled',
            trailing: Switch(
              value: themeMode == ThemeMode.dark,
              onChanged: (value) async {
                final newMode = value ? ThemeMode.dark : ThemeMode.light;
                ref.read(themeModeProvider.notifier).setTheme(newMode);
              },
              activeThumbColor: Theme.of(context).colorScheme.primary,
            ),
            onTap: null,
          ),
          const Divider(height: 1),

          _buildProfileActionTile(
            context,
            icon: Icons.notifications_outlined,
            title: 'Notifications',
            subtitle: _notificationsEnabled ? 'Enabled' : 'Disabled',
            trailing: Switch(
              value: _notificationsEnabled,
              onChanged: (value) {
                setState(() {
                  _notificationsEnabled = value;
                });
              },
              activeThumbColor: Theme.of(context).colorScheme.primary,
            ),
            onTap: null,
          ),
          const Divider(height: 1),

          _buildProfileActionTile(
            context,
            icon: _isSyncing ? Icons.sync_problem : Icons.sync,
            title: 'Sync',
            subtitle: _isSyncing ? 'Syncing...' : _syncStatus,
            trailing: _isSyncing
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: _syncStatus == 'All changes saved' ? Colors.green : Colors.orange,
                      shape: BoxShape.circle,
                    ),
                  ),
            onTap: () => _performManualSync(ref),
            accentColor: Colors.green,
          ),
          const Divider(height: 1),

          _buildProfileActionTile(
            context,
            icon: Icons.archive_outlined,
            title: 'Archive',
            subtitle: 'View archived notes',
            onTap: () => _showNotesList(context, ref, filter: 'archive'),
            accentColor: Colors.orange,
          ),
          const Divider(height: 1),

          _buildProfileActionTile(
            context,
            icon: Icons.delete_outline,
            title: 'Trash',
            subtitle: 'Restore or remove notes',
            onTap: () => _showNotesList(context, ref, filter: 'trash'),
            accentColor: Colors.red,
          ),
          const Divider(height: 1),

          _buildProfileActionTile(
            context,
            icon: Icons.help_outline,
            title: 'Help & Support',
            subtitle: 'Get assistance',
            onTap: () => _showSupportDialog(context),
            accentColor: Colors.blue,
          ),
          const Divider(height: 1),

          _buildProfileActionTile(
            context,
            icon: Icons.logout,
            title: 'Sign Out',
            subtitle: 'Exit the current account',
            onTap: () => ref.read(authNotifierProvider.notifier).signOut(),
            accentColor: Colors.red,
          ),
          const Divider(height: 1),

          _buildProfileActionTile(
            context,
            icon: Icons.person_remove_alt_1_outlined,
            title: 'Delete Account',
            subtitle: 'Permanently remove your account',
            onTap: () => _showDeleteAccountDialog(context, ref),
            accentColor: Colors.deepPurple,
          ),
        ],
      ),
    );
  }

  void _showSupportDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Help & Support'),
        content: const Text('For help, contact support at support@monotepro.app or use the in-app feedback option.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
        ],
      ),
    );
  }

  Future<void> _showDeleteAccountDialog(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.maybeOf(context);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Account'),
        content: const Text('This will permanently delete your account and all notes associated with it. Continue?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await user.delete();
      }
      await ref.read(authNotifierProvider.notifier).signOut();
      if (!mounted) return;
      messenger?.showSnackBar(const SnackBar(content: Text('Account deleted successfully')));
    } catch (e) {
      if (!mounted) return;
      messenger?.showSnackBar(SnackBar(content: Text('Unable to delete account: $e')));
    }
  }

  void _showNotesList(BuildContext context, WidgetRef ref, {required String filter}) {
    final notesAsync = ref.read(allNotesStreamProvider);
    final notes = notesAsync.valueOrNull ?? [];
    final now = DateTime.now();
    final filtered = notes.where((note) {
      if (filter == 'archive') return note.isArchived && !note.isDeleted;
      if (filter == 'trash') {
        if (!note.isDeleted) return false;
        final deletedAt = note.deletedAt;
        if (deletedAt != null && now.difference(deletedAt).inDays >= AppConstants.trashRetentionDays) {
          Future.microtask(() async {
            if (!context.mounted) return;
            await ref.read(notesActionsProvider).deleteNotePermanently(note.id);
          });
          return false;
        }
        return true;
      }
      return false;
    }).toList();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.4,
        builder: (context, scrollController) {
          return Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(filter == 'archive' ? 'Archived Notes' : 'Trash', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                Expanded(
                  child: filtered.isEmpty
                      ? Center(child: Text(filter == 'archive' ? 'No archived notes yet' : 'No notes in trash'))
                      : ListView.builder(
                          controller: scrollController,
                          itemCount: filtered.length,
                          itemBuilder: (context, index) {
                            final note = filtered[index];
                            return Card(
                              child: ListTile(
                                title: Text(note.title.isEmpty ? 'Untitled' : note.title),
                                subtitle: Text(note.content.isEmpty ? 'No content' : note.content, maxLines: 2, overflow: TextOverflow.ellipsis),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (filter == 'trash')
                                      IconButton(
                                        icon: const Icon(Icons.restore),
                                        onPressed: () async {
                                          Navigator.pop(context);
                                          final messenger = ScaffoldMessenger.of(context);
                                          await ref.read(notesActionsProvider).restoreNote(note.id);
                                          if (!mounted) return;
                                          messenger.showSnackBar(const SnackBar(content: Text('Note restored')));
                                        },
                                      ),
                                    IconButton(
                                      icon: Icon(filter == 'trash' ? Icons.delete_forever : Icons.delete_outline),
                                      onPressed: () async {
                                        Navigator.pop(context);
                                        final messenger = ScaffoldMessenger.of(context);
                                        if (filter == 'trash') {
                                          await ref.read(notesActionsProvider).deleteNotePermanently(note.id);
                                        } else {
                                          await ref.read(notesActionsProvider).deleteNote(note.id);
                                        }
                                        if (!mounted) return;
                                        messenger.showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              filter == 'trash' ? 'Note permanently deleted' : 'Note moved to trash',
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildAppInfo(BuildContext context) {
    return Center(
      child: Column(
        children: [
          Text(
            'MoNote Pro v2.0.1',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 4),
          Text(
            'Made by MoCodex',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  Future<void> _performManualSync(WidgetRef ref) async {
    if (_isSyncing) return;

    setState(() {
      _isSyncing = true;
      _syncStatus = 'Syncing...';
    });

    try {
      // Force refresh of notes from Firestore
      ref.invalidate(notesStreamProvider);
      
      // Wait for the stream to emit new data
      await ref.read(notesStreamProvider.future);
      
      setState(() {
        _isSyncing = false;
        _syncStatus = 'All changes saved';
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sync completed successfully'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isSyncing = false;
        _syncStatus = 'Sync failed';
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sync failed: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  void onBack() {

  }
}