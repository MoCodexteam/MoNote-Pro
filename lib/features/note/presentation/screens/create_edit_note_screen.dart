// lib/features/note/presentation/screens/create_edit_note_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart'; // لتوليد ID جديد (أضف في pubspec: uuid: ^4.0.0)

import '../../../auth/presentation/providers/auth_notifier.dart';
import '../../../auth/presentation/providers/auth_state.dart';
import '../../../../core/utils/notification_service.dart';
import '../../domain/entities/note_entity.dart';
import '../providers/notes_provider.dart';
import '../providers/categories_provider.dart';
import '../../../notifications/presentation/providers/notifications_provider.dart';

/// شاشة إنشاء أو تعديل ملاحظة
/// تدعم: عنوان، محتوى، فئة (مع ألوان)، تاجات، تثبيت، حفظ
class CreateEditNoteScreen extends ConsumerStatefulWidget {
  final NoteEntity? existingNote; // null لو ملاحظة جديدة
  final VoidCallback onBack;

  const CreateEditNoteScreen({
    super.key,
    this.existingNote,
    required this.onBack,
  });

  @override
  ConsumerState<CreateEditNoteScreen> createState() =>
      _CreateEditNoteScreenState();
}

class _CreateEditNoteScreenState extends ConsumerState<CreateEditNoteScreen> {
  late final TextEditingController _titleController;
  late final TextEditingController _contentController;
  late final TextEditingController _tagsController;
  late final List<TextEditingController> _checklistControllers;
  late List<NoteChecklistItem> _checklistItems;

  String _selectedCategory = 'Personal';
  bool _isPinned = false;
  bool _isSaving = false;
  TextDirection _titleDirection = TextDirection.ltr;
  TextDirection _contentDirection = TextDirection.ltr;

  // Notification fields
  bool _reminderEnabled = false;
  DateTime? _reminderDate;
  TimeOfDay? _reminderTime;
  int _reminderInterval = 3; // Default: every 3 days

  @override
  void initState() {
    super.initState();

    _titleController =
        TextEditingController(text: widget.existingNote?.title ?? '');
    _contentController =
        TextEditingController(text: widget.existingNote?.content ?? '');
    _tagsController = TextEditingController(
      text: widget.existingNote?.tags.join(', ') ?? '',
    );
    _checklistItems = List<NoteChecklistItem>.from(
        widget.existingNote?.checklistItems ?? const []);
    _checklistControllers = _checklistItems
        .map((item) => TextEditingController(text: item.text))
        .toList();

    _selectedCategory = widget.existingNote?.category ?? 'Personal';
    _isPinned = widget.existingNote?.isPinned ?? false;
    _reminderEnabled = widget.existingNote?.reminderEnabled ?? false;
    _reminderInterval = widget.existingNote?.reminderInterval ?? 3;

    // Load reminder date and time from saved reminder date
    if (widget.existingNote?.reminderDate != null) {
      final savedDateTime = widget.existingNote!.reminderDate!;
      _reminderDate =
          DateTime(savedDateTime.year, savedDateTime.month, savedDateTime.day);
      _reminderTime =
          TimeOfDay(hour: savedDateTime.hour, minute: savedDateTime.minute);
    } else {
      _reminderDate = null;
      _reminderTime = null;
    }

    // Detect text direction from existing content
    _detectTitleDirection();
    _detectContentDirection();

    // Listen for text changes to update direction
    _titleController.addListener(_detectTitleDirection);
    _contentController.addListener(_detectContentDirection);
  }

  void _detectTitleDirection() {
    final hasArabic =
        RegExp(r'[\u0600-\u06FF]').hasMatch(_titleController.text);
    final direction = hasArabic ? TextDirection.rtl : TextDirection.ltr;
    if (_titleDirection != direction) {
      setState(() => _titleDirection = direction);
    }
  }

  void _detectContentDirection() {
    final hasArabic =
        RegExp(r'[\u0600-\u06FF]').hasMatch(_contentController.text);
    final direction = hasArabic ? TextDirection.rtl : TextDirection.ltr;
    if (_contentDirection != direction) {
      setState(() => _contentDirection = direction);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _tagsController.dispose();
    for (final controller in _checklistControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _addChecklistItem() {
    setState(() {
      _checklistItems = [
        ..._checklistItems,
        const NoteChecklistItem(id: '', text: '', isCompleted: false),
      ];
      _checklistControllers.add(TextEditingController());
    });
  }

  void _removeChecklistItem(int index) {
    if (index < 0 || index >= _checklistControllers.length) return;

    setState(() {
      _checklistItems.removeAt(index);
      _checklistControllers.removeAt(index);
    });
  }

  void _toggleChecklistItem(int index) {
    if (index < 0 || index >= _checklistItems.length) return;

    setState(() {
      _checklistItems[index] = _checklistItems[index].copyWith(
        isCompleted: !_checklistItems[index].isCompleted,
      );
    });
  }

  List<NoteChecklistItem> _buildChecklistItems() {
    final items = <NoteChecklistItem>[];
    for (var i = 0; i < _checklistControllers.length; i++) {
      final controller = _checklistControllers[i];
      final text = controller.text.trim();
      if (text.isEmpty) continue;

      final existing = i < _checklistItems.length ? _checklistItems[i] : null;
      items.add(
        NoteChecklistItem(
          id: existing?.id ?? const Uuid().v4(),
          text: text,
          isCompleted: existing?.isCompleted ?? false,
        ),
      );
    }
    return items;
  }

  Future<void> _saveNote() async {
    if (_titleController.text.trim().isEmpty &&
        _contentController.text.trim().isEmpty) {
      widget.onBack();
      return;
    }

    setState(() => _isSaving = true);

    final now = DateTime.now();
    final user = ref.read(authNotifierProvider).currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You must log in first.ً')),
      );
      setState(() => _isSaving = false);
      return;
    }

    var note = NoteEntity(
      id: widget.existingNote?.id ?? const Uuid().v4(),
      title: _titleController.text.trim().isEmpty
          ? 'Without Title'
          : _titleController.text.trim(),
      content: _contentController.text.trim(),
      dateCreated: widget.existingNote?.dateCreated ?? now,
      lastEdit: now,
      tags: _tagsController.text
          .split(',')
          .map((t) => t.trim())
          .where((t) => t.isNotEmpty)
          .toList(),
      category: _selectedCategory,
      categoryColor: _getCategoryColor(_selectedCategory),
      isPinned: _isPinned,
      checklistItems: _buildChecklistItems(),
      reminderEnabled: _reminderEnabled,
      reminderDate:
          _reminderEnabled && _reminderDate != null && _reminderTime != null
              ? DateTime(
                  _reminderDate!.year,
                  _reminderDate!.month,
                  _reminderDate!.day,
                  _reminderTime!.hour,
                  _reminderTime!.minute,
                )
              : null,
      reminderInterval: _reminderEnabled ? _reminderInterval : null,
    );

    // Calculate the scheduled datetime for notification
    DateTime? scheduledDateTime;
    bool reminderTimeValid = true;
    if (_reminderEnabled && _reminderDate != null && _reminderTime != null) {
      scheduledDateTime = DateTime(
        _reminderDate!.year,
        _reminderDate!.month,
        _reminderDate!.day,
        _reminderTime!.hour,
        _reminderTime!.minute,
      );

      // Check if the scheduled time is in the future (at least 2 minutes from now)
      final now = DateTime.now();
      if (scheduledDateTime.isBefore(now.add(const Duration(minutes: 2)))) {
        reminderTimeValid = false;
        scheduledDateTime = null;
      }
    }

    final actions = ref.read(notesActionsProvider);

    try {
      if (widget.existingNote != null) {
        await actions.updateNote(note);
      } else {
        await actions.createNote(note);
      }

      // Schedule notification if reminder is enabled and time is valid
      if (_reminderEnabled && scheduledDateTime != null && reminderTimeValid) {
        final notificationService = NotificationService();

        // Cancel any existing notification for this note
        await notificationService.cancelNotification(note.id.hashCode);

        // Remove old notifications for this note from the notifications provider
        await ref
            .read(notificationsProvider.notifier)
            .removeNotificationsForNote(note.id);

        // Schedule new notification
        try {
          if (_reminderInterval > 1) {
            // Recurring notification
            await notificationService.scheduleRecurringNotification(
              id: note.id.hashCode,
              title: note.title,
              body: note.content.isNotEmpty
                  ? note.content.substring(
                      0, note.content.length > 50 ? 50 : note.content.length)
                  : 'Note reminder',
              startDate: scheduledDateTime,
              intervalDays: _reminderInterval,
              payload: note.id,
            );
          } else {
            // One-time notification
            await notificationService.scheduleNotification(
              id: note.id.hashCode,
              title: note.title,
              body: note.content.isNotEmpty
                  ? note.content.substring(
                      0, note.content.length > 50 ? 50 : note.content.length)
                  : 'Note reminder',
              scheduledDate: scheduledDateTime,
              payload: note.id,
            );
          }

          // Add to notifications provider for UI display
          await ref.read(notificationsProvider.notifier).addNotification(
                title: note.title,
                body: note.content.isNotEmpty
                    ? note.content.substring(
                        0, note.content.length > 50 ? 50 : note.content.length)
                    : 'Note reminder',
                scheduledDate: scheduledDateTime,
                noteId: note.id,
              );

          if (mounted) {
            // Check pending notifications to verify
            final pending = await notificationService.getPendingNotifications();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                    'Note saved with reminder. Pending notifications: ${pending.length}'),
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 3),
              ),
            );
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Note saved, but notification failed: $e'),
                backgroundColor: Colors.orange,
              ),
            );
          }
        }
      } else if (_reminderEnabled && !reminderTimeValid) {
        // Show warning that reminder wasn't scheduled due to invalid time
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                  'Note saved, but reminder not scheduled (time must be in future)'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      } else {
        // Cancel notification if reminder is disabled
        await NotificationService().cancelNotification(note.id.hashCode);
        // Remove from notifications provider
        await ref
            .read(notificationsProvider.notifier)
            .removeNotificationsForNote(note.id);
      }

      widget.onBack();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('An error occurred while saving: $e')),
      );
    } finally {
      setState(() => _isSaving = false);
    }
  }

  void _togglePin() {
    setState(() => _isPinned = !_isPinned);
  }

  Color? _getCategoryColor(String categoryName) {
    final categories = ref.read(enrichedCategoriesProvider);
    final category = categories.firstWhere(
      (cat) => cat.name == categoryName,
      orElse: () => categories.first,
    );
    return category.color;
  }

  Future<void> _deleteNote() async {
    if (widget.existingNote == null) return;

    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Note'),
        content: const Text(
            'Are you sure you want to delete this note? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isSaving = true);

    try {
      final actions = ref.read(notesActionsProvider);
      await actions.deleteNote(widget.existingNote!.id);

      // Remove notifications for this note
      await ref
          .read(notificationsProvider.notifier)
          .removeNotificationsForNote(widget.existingNote!.id);

      // Cancel system notification
      await NotificationService()
          .cancelNotification(widget.existingNote!.id.hashCode);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Note deleted successfully')),
        );
        widget.onBack();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting note: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              floating: true,
              pinned: true,
              backgroundColor:
                  Theme.of(context).colorScheme.surface.withOpacity(0.9),
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: widget.onBack,
              ),
              title: Text(
                widget.existingNote == null ? 'New Note' : 'Edit Note',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              actions: [
                if (_isSaving)
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Center(
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  ),
                Container(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                  decoration: BoxDecoration(
                    color: _isPinned
                        ? Theme.of(context).colorScheme.primaryContainer
                        : Colors.transparent,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: Icon(
                      _isPinned ? Icons.push_pin : Icons.push_pin_outlined,
                      color: _isPinned
                          ? Theme.of(context).colorScheme.onPrimaryContainer
                          : null,
                    ),
                    onPressed: _togglePin,
                  ),
                ),
                if (widget.existingNote != null)
                  Container(
                    margin:
                        const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                    child: IconButton(
                      icon: Icon(
                        Icons.delete_outline,
                        color: Theme.of(context).colorScheme.error,
                      ),
                      onPressed: _deleteNote,
                    ),
                  ),
                Container(
                  margin: const EdgeInsets.only(
                      right: 16, left: 8, top: 8, bottom: 8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: IconButton(
                    icon: Icon(Icons.check,
                        color: Theme.of(context).colorScheme.onPrimary),
                    onPressed: _isSaving ? null : _saveNote,
                  ),
                ),
              ],
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // عنوان الملاحظة
                    TextField(
                      controller: _titleController,
                      textDirection: _titleDirection,
                      textAlign: _titleDirection == TextDirection.rtl
                          ? TextAlign.right
                          : TextAlign.left,
                      decoration: InputDecoration(
                        hintText: 'Title',
                        border: InputBorder.none,
                        hintStyle: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withOpacity(0.3),
                        ),
                      ),
                      style:
                          Theme.of(context).textTheme.headlineLarge?.copyWith(
                                fontWeight: FontWeight.w800,
                                fontSize: 32,
                                letterSpacing: -0.5,
                              ),
                      maxLines: null,
                    ),

                    const SizedBox(height: 16),

                    // محتوى الملاحظة
                    TextField(
                      controller: _contentController,
                      textDirection: _contentDirection,
                      textAlign: _contentDirection == TextDirection.rtl
                          ? TextAlign.right
                          : TextAlign.left,
                      decoration: InputDecoration(
                        hintText: 'Start writing...',
                        border: InputBorder.none,
                        hintStyle: TextStyle(
                          fontSize: 18,
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withOpacity(0.4),
                        ),
                      ),
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            fontSize: 18,
                            height: 1.6,
                            letterSpacing: 0.2,
                          ),
                      maxLines: null,
                      minLines: 5,
                    ),

                    const SizedBox(height: 32),

                    // Metadata & Settings Section
                    Text(
                      'Note Settings',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 16),

                    // Checklist Card
                    Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color:
                                Theme.of(context).shadowColor.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.check_box_outlined,
                                    color:
                                        Theme.of(context).colorScheme.primary),
                                const SizedBox(width: 8),
                                Text(
                                  'Checklist',
                                  style:
                                      Theme.of(context).textTheme.titleMedium,
                                ),
                                const Spacer(),
                                TextButton.icon(
                                  onPressed: _addChecklistItem,
                                  icon: const Icon(Icons.add),
                                  label: const Text('Add'),
                                ),
                              ],
                            ),
                            if (_checklistControllers.isNotEmpty) ...[
                              const SizedBox(height: 12),
                              ListView.separated(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: _checklistControllers.length,
                                separatorBuilder: (context, index) =>
                                    const SizedBox(height: 8),
                                itemBuilder: (context, index) {
                                  final item = _checklistItems.length > index
                                      ? _checklistItems[index]
                                      : null;
                                  return Container(
                                    decoration: BoxDecoration(
                                      color:
                                          Theme.of(context).colorScheme.surface,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .outlineVariant
                                              .withOpacity(0.3)),
                                    ),
                                    child: Row(
                                      children: [
                                        Checkbox(
                                          value: item?.isCompleted ?? false,
                                          onChanged: (_) =>
                                              _toggleChecklistItem(index),
                                          shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(4)),
                                        ),
                                        Expanded(
                                          child: ValueListenableBuilder<
                                              TextEditingValue>(
                                            valueListenable:
                                                _checklistControllers[index],
                                            builder: (context, value, child) {
                                              final hasArabic =
                                                  RegExp(r'[\u0600-\u06FF]')
                                                      .hasMatch(value.text);
                                              final dir = hasArabic
                                                  ? TextDirection.rtl
                                                  : TextDirection.ltr;
                                              return TextField(
                                                controller:
                                                    _checklistControllers[
                                                        index],
                                                textDirection: dir,
                                                textAlign:
                                                    dir == TextDirection.rtl
                                                        ? TextAlign.right
                                                        : TextAlign.left,
                                                style: TextStyle(
                                                  decoration:
                                                      (item?.isCompleted ??
                                                              false)
                                                          ? TextDecoration
                                                              .lineThrough
                                                          : null,
                                                ),
                                                decoration:
                                                    const InputDecoration(
                                                  hintText: 'Task...',
                                                  border: InputBorder.none,
                                                  contentPadding:
                                                      EdgeInsets.zero,
                                                ),
                                              );
                                            },
                                          ),
                                        ),
                                        IconButton(
                                          onPressed: () =>
                                              _removeChecklistItem(index),
                                          icon:
                                              const Icon(Icons.close, size: 20),
                                          color: Theme.of(context)
                                              .colorScheme
                                              .error,
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Category & Tags Card
                    Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color:
                                Theme.of(context).shadowColor.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.folder_outlined,
                                    color:
                                        Theme.of(context).colorScheme.primary),
                                const SizedBox(width: 8),
                                Text(
                                  'Category',
                                  style:
                                      Theme.of(context).textTheme.titleMedium,
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Consumer(
                              builder: (context, ref, child) {
                                final categories =
                                    ref.watch(enrichedCategoriesProvider);
                                return DropdownButtonFormField<String>(
                                  initialValue: categories.any((cat) =>
                                          cat.name == _selectedCategory)
                                      ? _selectedCategory
                                      : categories.first.name,
                                  decoration: InputDecoration(
                                    filled: true,
                                    fillColor:
                                        Theme.of(context).colorScheme.surface,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide.none,
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 12),
                                  ),
                                  items: categories.map((cat) {
                                    return DropdownMenuItem<String>(
                                      value: cat.name,
                                      child: Row(
                                        children: [
                                          Container(
                                            width: 16,
                                            height: 16,
                                            decoration: BoxDecoration(
                                              color: cat.color,
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Text(cat.name),
                                        ],
                                      ),
                                    );
                                  }).toList(),
                                  onChanged: (value) {
                                    if (value != null) {
                                      setState(() => _selectedCategory = value);
                                    }
                                  },
                                );
                              },
                            ),
                            const SizedBox(height: 24),
                            Row(
                              children: [
                                Icon(Icons.tag,
                                    color:
                                        Theme.of(context).colorScheme.primary),
                                const SizedBox(width: 8),
                                Text(
                                  'Tags',
                                  style:
                                      Theme.of(context).textTheme.titleMedium,
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              controller: _tagsController,
                              decoration: InputDecoration(
                                hintText: 'Work, important, idea',
                                filled: true,
                                fillColor:
                                    Theme.of(context).colorScheme.surface,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 12),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Reminder Card
                    Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color:
                                Theme.of(context).shadowColor.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SwitchListTile(
                              contentPadding: EdgeInsets.zero,
                              title: Row(
                                children: [
                                  Icon(Icons.notifications_active_outlined,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .primary),
                                  const SizedBox(width: 8),
                                  const Text('Enable Reminder'),
                                ],
                              ),
                              subtitle: const Padding(
                                padding: EdgeInsets.only(left: 32),
                                child: Text('Get notified about this note'),
                              ),
                              value: _reminderEnabled,
                              onChanged: (value) {
                                setState(() {
                                  _reminderEnabled = value;
                                  if (value && _reminderDate == null) {
                                    _reminderDate = DateTime.now()
                                        .add(const Duration(days: 3));
                                  }
                                });
                              },
                            ),
                            if (_reminderEnabled) ...[
                              const SizedBox(height: 16),
                              Container(
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.surface,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Column(
                                  children: [
                                    ListTile(
                                      leading: const Icon(Icons.calendar_today),
                                      title: Text(
                                        'Date: ${_reminderDate != null ? "${_reminderDate!.day}/${_reminderDate!.month}/${_reminderDate!.year}" : "Not set"}',
                                      ),
                                      trailing: const Icon(Icons.chevron_right),
                                      onTap: () async {
                                        final pickedDate = await showDatePicker(
                                          context: context,
                                          initialDate: _reminderDate ??
                                              DateTime.now()
                                                  .add(const Duration(days: 3)),
                                          firstDate: DateTime.now(),
                                          lastDate: DateTime.now()
                                              .add(const Duration(days: 365)),
                                        );
                                        if (pickedDate != null) {
                                          setState(
                                              () => _reminderDate = pickedDate);
                                        }
                                      },
                                    ),
                                    const Divider(height: 1),
                                    ListTile(
                                      leading: const Icon(Icons.access_time),
                                      title: Text(
                                        'Time: ${_reminderTime != null ? _reminderTime!.format(context) : "Not set"}',
                                      ),
                                      trailing: const Icon(Icons.chevron_right),
                                      onTap: () async {
                                        final pickedTime = await showTimePicker(
                                          context: context,
                                          initialTime:
                                              _reminderTime ?? TimeOfDay.now(),
                                        );
                                        if (pickedTime != null) {
                                          setState(
                                              () => _reminderTime = pickedTime);
                                        }
                                      },
                                    ),
                                    const Divider(height: 1),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 16, vertical: 12),
                                      child: Row(
                                        children: [
                                          const Icon(Icons.repeat),
                                          const SizedBox(width: 16),
                                          Text(
                                            'Repeat every',
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodyLarge,
                                          ),
                                          const Spacer(),
                                          IconButton(
                                            icon: const Icon(
                                                Icons.remove_circle_outline),
                                            onPressed: _reminderInterval > 1
                                                ? () => setState(
                                                    () => _reminderInterval--)
                                                : null,
                                          ),
                                          Text(
                                            '$_reminderInterval d',
                                            style: Theme.of(context)
                                                .textTheme
                                                .titleMedium
                                                ?.copyWith(
                                                    fontWeight:
                                                        FontWeight.bold),
                                          ),
                                          IconButton(
                                            icon: const Icon(
                                                Icons.add_circle_outline),
                                            onPressed: () => setState(
                                                () => _reminderInterval++),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 80), // Padding at the bottom
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
