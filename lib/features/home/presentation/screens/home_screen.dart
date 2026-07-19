// lib/features/home/presentation/screens/home_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/domain/entities/user_entity.dart';
import '../../../profile/presentation/screens/profile_screen.dart';
import '../../../note/domain/entities/note_entity.dart';
import '../../../note/presentation/providers/notes_provider.dart';
import '../../../note/presentation/providers/categories_provider.dart';
import '../../../note/presentation/screens/create_edit_note_screen.dart';
import '../../../home/presentation/widgets/note_card.dart';
import '../../../categories/presentation/screens/categories_screen.dart';
import '../../../search/presentation/screens/search_screen.dart';
import '../../../notifications/presentation/screens/notifications_screen.dart';
import '../../../notifications/presentation/providers/notifications_provider.dart';
import '../../../calendar/presentation/screens/calendar_screen.dart';
import '../../../../core/utils/notification_service.dart';
import 'dart:async';

/// الشاشة الرئيسية بعد تسجيل الدخول
/// تحتوي على Bottom Navigation Bar مع 5 تبويبات:
/// Home (الملاحظات), Categories, Calendar, Search, Profile
class HomeScreen extends ConsumerStatefulWidget {
  final UserEntity user;

  const HomeScreen({super.key, required this.user});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _currentIndex = 0;

  final _searchController = TextEditingController();
  String _searchQuery = '';
  StreamSubscription<String?>? _notificationSubscription;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      final newText = _searchController.text.trim();
      if (newText != _searchQuery) {
        setState(() => _searchQuery = newText);
      }
    });

    _notificationSubscription =
        NotificationService.onNotificationClick.stream.listen((payload) {
      if (payload != null && mounted) {
        final notes = ref.read(notesStreamProvider).value;
        if (notes != null) {
          try {
            final note = notes.firstWhere((n) => n.id == payload);
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => CreateEditNoteScreen(
                  existingNote: note,
                  onBack: () {},
                ),
              ),
            );
          } catch (e) {
            debugPrint('Note with id $payload not found: $e');
          }
        }
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _notificationSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: IndexedStack(
          index: _currentIndex,
          children: [
            // Tab 0: Home – الملاحظات
            _buildHomeTab(context),

            // Tab 1: Categories
            CategoriesScreen(
              onBack: () {
                setState(() => _currentIndex = 0);
              },
              onSelectCategory: (categoryName) {
                ref.read(selectedCategoryProvider.notifier).state =
                    categoryName;
                setState(() => _currentIndex = 0);
              },
            ),

            // Tab 2: Calendar
            CalendarScreen(
              onBack: () {
                setState(() => _currentIndex = 0);
              },
            ),

            // Tab 3: Search
            SearchScreen(
              onBack: () {
                setState(() => _currentIndex = 0);
              },
            ),
            // Tab 4: Profile
            ProfileScreen(
              onBack: () {
                setState(() => _currentIndex = 0); // رجوع للـ Home
              },
            ),
          ],
        ),
      ),

      // FAB يظهر فقط في تبويب Home
      floatingActionButton: _currentIndex == 0
          ? FloatingActionButton(
              onPressed: _onCreateNote,
              backgroundColor: Theme.of(context).colorScheme.primary,
              elevation: 6,
              child: const Icon(Icons.add, size: 28),
            )
          : null,

      // Bottom Navigation Bar مع تأثير gradient على التبويب النشط
      bottomNavigationBar: _buildBottomNav(context),
    );
  }

  // ────────────────────────────────────────────────
  // Tab 0: محتوى الـ Home (الملاحظات)
  // ────────────────────────────────────────────────
  Widget _buildHomeTab(BuildContext context) {
    final selectedCategory = ref.watch(selectedCategoryProvider);
    final notesAsync = selectedCategory == null
        ? ref.watch(notesStreamProvider)
        : ref.watch(categoryFilteredNotesProvider);

    return Column(
      children: [
        _buildHeader(context),
        Expanded(
          child: notesAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) => Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('حدث خطأ أثناء تحميل الملاحظات',
                      style: Theme.of(context).textTheme.titleMedium),
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 32, vertical: 8),
                    child: Text(
                      err.toString(),
                      textAlign: TextAlign.center,
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: Colors.red),
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.refresh),
                    label: const Text('إعادة المحاولة'),
                    onPressed: () => ref.invalidate(notesStreamProvider),
                  ),
                ],
              ),
            ),
            data: (notes) {
              // Filter out deleted notes first
              final activeNotes =
                  notes.where((note) => !note.isDeleted).toList();

              // Apply search filter
              final filteredNotes = activeNotes.where((note) {
                if (_searchQuery.isEmpty) return true;

                final query = _searchQuery.toLowerCase();
                return note.title.toLowerCase().contains(query) ||
                    note.content.toLowerCase().contains(query) ||
                    (note.category?.toLowerCase().contains(query) ?? false) ||
                    note.tags.any((tag) => tag.toLowerCase().contains(query));
              }).toList();

              final pinnedNotes =
                  filteredNotes.where((n) => n.isPinned).toList();
              final regularNotes =
                  filteredNotes.where((n) => !n.isPinned).toList();

              return filteredNotes.isEmpty
                  ? EmptyState(onCreateNote: _onCreateNote)
                  : ListView(
                      padding: const EdgeInsets.all(24),
                      children: [
                        if (selectedCategory != null) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            margin: const EdgeInsets.only(bottom: 16),
                            decoration: BoxDecoration(
                              color: Theme.of(context)
                                  .colorScheme
                                  .primaryContainer,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.filter_list,
                                  size: 20,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onPrimaryContainer,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Filtered by: $selectedCategory',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onPrimaryContainer,
                                          fontWeight: FontWeight.w500,
                                        ),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.clear, size: 20),
                                  onPressed: () {
                                    ref
                                        .read(selectedCategoryProvider.notifier)
                                        .state = null;
                                  },
                                  tooltip: 'Clear filter',
                                ),
                              ],
                            ),
                          ),
                        ],
                        if (pinnedNotes.isNotEmpty) ...[
                          _buildSectionHeader(
                              context, 'Pinned', Icons.push_pin),
                          ...pinnedNotes.asMap().entries.map(
                                (e) => NoteCard(
                                  note: e.value,
                                  index: e.key,
                                  onTap: () => _onViewNote(e.value),
                                  onPin: () => _onTogglePin(e.value),
                                  onArchive: () => _onToggleArchive(e.value),
                                  onDelete: () => _onDeleteNote(e.value),
                                ),
                              ),
                          const SizedBox(height: 32),
                        ],
                        if (regularNotes.isNotEmpty) ...[
                          if (pinnedNotes.isNotEmpty)
                            _buildSectionHeader(
                                context,
                                selectedCategory != null
                                    ? 'Notes in this category'
                                    : 'All Notes',
                                null),
                          ...regularNotes.asMap().entries.map(
                                (e) => NoteCard(
                                  note: e.value,
                                  index: e.key + pinnedNotes.length,
                                  onTap: () => _onViewNote(e.value),
                                  onPin: () => _onTogglePin(e.value),
                                  onArchive: () => _onToggleArchive(e.value),
                                  onDelete: () => _onDeleteNote(e.value),
                                ),
                              ),
                        ],
                      ],
                    );
            },
          ),
        ),
      ],
    );
  }

  // ────────────────────────────────────────────────
  // Bottom Navigation Bar – مع gradient active state
  // ────────────────────────────────────────────────
  Widget _buildBottomNav(BuildContext context) {
    const tabs = [
      {'icon': Icons.home, 'label': 'Home'},
      {'icon': Icons.folder_outlined, 'label': 'Categories'},
      {'icon': Icons.calendar_today, 'label': 'Calendar'},
      {'icon': Icons.search, 'label': 'Search'},
      {'icon': Icons.person_outline, 'label': 'Profile'},
    ];

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: Theme.of(context).dividerColor,
            width: 1,
          ),
        ),
      ),
      child: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.transparent,
        elevation: 0,
        selectedItemColor: Theme.of(context).colorScheme.primary,
        unselectedItemColor: Theme.of(context).colorScheme.onSurfaceVariant,
        showSelectedLabels: true,
        showUnselectedLabels: true,
        selectedFontSize: 12,
        unselectedFontSize: 12,
        iconSize: 26,
        items: tabs.asMap().entries.map((entry) {
          final index = entry.key;
          final tab = entry.value;
          final isActive = _currentIndex == index;

          return BottomNavigationBarItem(
            icon: AnimatedContainer(
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeOutCubic,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                gradient: isActive
                    ? LinearGradient(
                        colors: [
                          Theme.of(context)
                              .colorScheme
                              .primary
                              .withValues(alpha: 0.25),
                          Theme.of(context)
                              .colorScheme
                              .secondary
                              .withValues(alpha: 0.25),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                tab['icon'] as IconData,
                size: 26,
              ),
            ),
            label: tab['label'] as String,
            tooltip: tab['label'] as String,
          );
        }).toList(),
      ),
    );
  }

  // ────────────────────────────────────────────────
  // Header مع اسم التطبيق + عدد الملاحظات + أفاتار + بحث
  // ────────────────────────────────────────────────
  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).dividerColor,
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'MoNote Pro',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${ref.watch(notesStreamProvider).value?.length ?? 0} ${ref.watch(notesStreamProvider).value?.length == 1 ? "note" : "notes"}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
              Row(
                children: [
                  // Notification icon
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => NotificationsScreen(
                            onBack: () => Navigator.pop(context),
                          ),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Stack(
                        children: [
                          Icon(
                            Icons.notifications_outlined,
                            color: Theme.of(context).colorScheme.onSurface,
                            size: 24,
                          ),
                          if (ref
                              .watch(notificationsProvider)
                              .notifications
                              .any((n) => !n.isRead))
                            Positioned(
                              right: 2,
                              top: 2,
                              child: Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Profile avatar
                  GestureDetector(
                    onTap: () {
                      setState(
                          () => _currentIndex = 3); // الانتقال لتبويب Profile
                    },
                    child: CircleAvatar(
                      radius: 20,
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      child: Text(
                        widget.user.fullName?.substring(0, 1).toUpperCase() ??
                            '?',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search notes...',
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 0),
            ),
          ),
        ],
      ),
    );
  }

  // ────────────────────────────────────────────────
  // رأس القسم (Pinned / All Notes)
  // ────────────────────────────────────────────────
  Widget _buildSectionHeader(
      BuildContext context, String title, IconData? icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, size: 16, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 8),
          ],
          Text(
            title.toUpperCase(),
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.2,
                  color: Theme.of(context).colorScheme.primary,
                ),
          ),
        ],
      ),
    );
  }

  // ────────────────────────────────────────────────
  // إجراءات المستخدم
  // ────────────────────────────────────────────────
  void _onCreateNote() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreateEditNoteScreen(
          onBack: () => Navigator.pop(context),
        ),
      ),
    );
  }

  void _onViewNote(NoteEntity note) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreateEditNoteScreen(
          existingNote: note,
          onBack: () => Navigator.pop(context),
        ),
      ),
    );
  }

  void _onTogglePin(NoteEntity note) {
    final actions = ref.read(notesActionsProvider);
    actions.togglePin(note.id, note.isPinned);
  }

  void _onDeleteNote(NoteEntity note) {
    final actions = ref.read(notesActionsProvider);
    actions.deleteNote(note.id);
  }

  void _onToggleArchive(NoteEntity note) {
    final actions = ref.read(notesActionsProvider);
    actions.toggleArchive(note.id, note.isArchived);
  }
}

/// حالة فارغة (Empty State)
class EmptyState extends StatelessWidget {
  final VoidCallback onCreateNote;

  const EmptyState({super.key, required this.onCreateNote});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.note_alt_outlined,
                size: 48,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No notes yet',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            Text(
              'Start organizing your thoughts by creating your first note',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              icon: const Icon(Icons.add),
              label: const Text('Create Note'),
              style: FilledButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
              ),
              onPressed: onCreateNote,
            ),
          ],
        ),
      ),
    );
  }
}
