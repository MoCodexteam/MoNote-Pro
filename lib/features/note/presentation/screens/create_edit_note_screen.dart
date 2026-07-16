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
  ConsumerState<CreateEditNoteScreen> createState() => _CreateEditNoteScreenState();
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
  TextDirection _textDirection = TextDirection.ltr;
  
  // Notification fields
  bool _reminderEnabled = false;
  DateTime? _reminderDate;
  TimeOfDay? _reminderTime;
  int _reminderInterval = 3; // Default: every 3 days

  @override
  void initState() {
    super.initState();

    _titleController = TextEditingController(text: widget.existingNote?.title ?? '');
    _contentController = TextEditingController(text: widget.existingNote?.content ?? '');
    _tagsController = TextEditingController(
      text: widget.existingNote?.tags.join(', ') ?? '',
    );
    _checklistItems = List<NoteChecklistItem>.from(widget.existingNote?.checklistItems ?? const []);
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
      _reminderDate = DateTime(savedDateTime.year, savedDateTime.month, savedDateTime.day);
      _reminderTime = TimeOfDay(hour: savedDateTime.hour, minute: savedDateTime.minute);
    } else {
      _reminderDate = null;
      _reminderTime = null;
    }

    // Detect text direction from existing content
    _detectTextDirection();

    // Listen for text changes to update direction
    _titleController.addListener(_detectTextDirection);
    _contentController.addListener(_detectTextDirection);
  }

  void _detectTextDirection() {
    final text = _titleController.text.isNotEmpty 
        ? _titleController.text 
        : _contentController.text;
    
    // Check if text contains Arabic characters
    final hasArabic = RegExp(r'[\u0600-\u06FF]').hasMatch(text);
    setState(() {
      _textDirection = hasArabic ? TextDirection.rtl : TextDirection.ltr;
    });
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
    if (_titleController.text.trim().isEmpty && _contentController.text.trim().isEmpty) {
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
      title: _titleController.text.trim().isEmpty ? 'Without Title' : _titleController.text.trim(),
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
      reminderDate: _reminderEnabled && _reminderDate != null && _reminderTime != null
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
        await ref.read(notificationsProvider.notifier).removeNotificationsForNote(note.id);
        
        // Schedule new notification
        try {
          if (_reminderInterval != null && _reminderInterval! > 1) {
            // Recurring notification
            await notificationService.scheduleRecurringNotification(
              id: note.id.hashCode,
              title: note.title,
              body: note.content.isNotEmpty 
                  ? note.content.substring(0, note.content.length > 50 ? 50 : note.content.length)
                  : 'Note reminder',
              startDate: scheduledDateTime,
              intervalDays: _reminderInterval!,
              payload: note.id,
            );
          } else {
            // One-time notification
            await notificationService.scheduleNotification(
              id: note.id.hashCode,
              title: note.title,
              body: note.content.isNotEmpty 
                  ? note.content.substring(0, note.content.length > 50 ? 50 : note.content.length)
                  : 'Note reminder',
              scheduledDate: scheduledDateTime,
              payload: note.id,
            );
          }
          
          // Add to notifications provider for UI display
          await ref.read(notificationsProvider.notifier).addNotification(
            title: note.title,
            body: note.content.isNotEmpty 
                ? note.content.substring(0, note.content.length > 50 ? 50 : note.content.length)
                : 'Note reminder',
            scheduledDate: scheduledDateTime,
            noteId: note.id,
          );
          
          if (mounted) {
            // Check pending notifications to verify
            final pending = await notificationService.getPendingNotifications();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Note saved with reminder. Pending notifications: ${pending.length}'),
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
              content: Text('Note saved, but reminder not scheduled (time must be in future)'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      } else {
        // Cancel notification if reminder is disabled
        await NotificationService().cancelNotification(note.id.hashCode);
        // Remove from notifications provider
        await ref.read(notificationsProvider.notifier).removeNotificationsForNote(note.id);
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
        content: const Text('Are you sure you want to delete this note? This action cannot be undone.'),
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
      await ref.read(notificationsProvider.notifier).removeNotificationsForNote(widget.existingNote!.id);
      
      // Cancel system notification
      await NotificationService().cancelNotification(widget.existingNote!.id.hashCode);
      
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
        child: Column(
          children: [
            // Header مع زر رجوع + حفظ + تثبيت
            Container(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                border: Border(
                  bottom: BorderSide(
                    color: Theme.of(context).dividerColor,
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: widget.onBack,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    widget.existingNote == null ? 'New Note' : 'Edit Note',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  if (_isSaving)
                    Padding(
                      padding: const EdgeInsets.only(right: 16),
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  IconButton(
                    icon: Icon(
                      Icons.push_pin,
                      color: _isPinned ? Theme.of(context).colorScheme.primary : null,
                      fill: _isPinned ? 1.0 : 0.0,
                    ),
                    onPressed: _togglePin,
                  ),
                  if (widget.existingNote != null)
                    IconButton(
                      icon: Icon(
                        Icons.delete_outline,
                        color: Theme.of(context).colorScheme.error,
                      ),
                      onPressed: _deleteNote,
                    ),
                  IconButton(
                    icon: Icon(Icons.check, color: Theme.of(context).colorScheme.primary),
                    onPressed: _isSaving ? null : _saveNote,
                  ),
                ],
              ),
            ),

            // المحرر
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // عنوان الملاحظة
                    TextField(
                      controller: _titleController,
                      textDirection: _textDirection,
                      textAlign: _textDirection == TextDirection.rtl ? TextAlign.right : TextAlign.left,
                      decoration: const InputDecoration(
                        hintText: 'Note title',
                        border: InputBorder.none,
                        hintStyle: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                    ),

                    const SizedBox(height: 16),

                    const Divider(height: 32),

                    // محتوى الملاحظة
                    TextField(
                      controller: _contentController,
                      textDirection: _textDirection,
                      textAlign: _textDirection == TextDirection.rtl ? TextAlign.right : TextAlign.left,
                      decoration: const InputDecoration(
                        hintText: 'start writing..',
                        border: InputBorder.none,
                        hintStyle: TextStyle(fontSize: 16),
                      ),
                      style: Theme.of(context).textTheme.bodyLarge,
                      maxLines: null,
                      minLines: 10,
                    ),

                    const SizedBox(height: 24),

                    // قائمة التحقق
                    Row(
                      children: [
                        Text(
                          'Checklist',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const Spacer(),
                        TextButton.icon(
                          onPressed: _addChecklistItem,
                          icon: const Icon(Icons.add_circle_outline),
                          label: const Text('Add item'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (_checklistControllers.isEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.35),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'Add a checklist for tasks, shopping, or plans.',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      )
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _checklistControllers.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final item = _checklistItems.length > index ? _checklistItems[index] : null;
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.25),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Checkbox(
                                  value: item?.isCompleted ?? false,
                                  onChanged: (_) => _toggleChecklistItem(index),
                                ),
                                Expanded(
                                  child: TextField(
                                    controller: _checklistControllers[index],
                                    textDirection: _textDirection,
                                    textAlign: _textDirection == TextDirection.rtl ? TextAlign.right : TextAlign.left,
                                    decoration: const InputDecoration(
                                      hintText: 'Checklist item',
                                      border: InputBorder.none,
                                      contentPadding: EdgeInsets.zero,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  onPressed: () => _removeChecklistItem(index),
                                  icon: const Icon(Icons.close),
                                  tooltip: 'Remove item',
                                ),
                              ],
                            ),
                          );
                        },
                      ),

                    const SizedBox(height: 24),

                    // اختيار الفئة
                    Text(
                      'Category',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Consumer(
                      builder: (context, ref, child) {
                        final categories = ref.watch(enrichedCategoriesProvider);
                        return DropdownButtonFormField<String>(
                          value: categories.any((cat) => cat.name == _selectedCategory) 
                              ? _selectedCategory 
                              : categories.first.name,
                          decoration: InputDecoration(
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                            if (value != null) setState(() => _selectedCategory = value);
                          },
                        );
                      },
                    ),

                    const SizedBox(height: 24),

                    // إدخال التاجات
                    Text(
                      'Tags (separated by commas)',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _tagsController,
                      decoration: InputDecoration(
                        hintText: 'Work, important, idea',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Reminder settings
                    Text(
                      'Reminder',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.25),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Enable reminder toggle
                          SwitchListTile(
                            title: const Text('Enable Reminder'),
                            subtitle: const Text('Get notified about this note'),
                            value: _reminderEnabled,
                            onChanged: (value) {
                              setState(() {
                                _reminderEnabled = value;
                                if (value && _reminderDate == null) {
                                  _reminderDate = DateTime.now().add(const Duration(days: 3));
                                }
                              });
                            },
                          ),
                          if (_reminderEnabled) ...[
                            const SizedBox(height: 16),
                            // Reminder date picker
                            ListTile(
                              leading: const Icon(Icons.calendar_today),
                              title: Text(
                                'Reminder Date: ${_reminderDate != null ? "${_reminderDate!.day}/${_reminderDate!.month}/${_reminderDate!.year}" : "Not set"}',
                              ),
                              trailing: const Icon(Icons.chevron_right),
                              onTap: () async {
                                final pickedDate = await showDatePicker(
                                  context: context,
                                  initialDate: _reminderDate ?? DateTime.now().add(const Duration(days: 3)),
                                  firstDate: DateTime.now(),
                                  lastDate: DateTime.now().add(const Duration(days: 365)),
                                );
                                if (pickedDate != null) {
                                  setState(() {
                                    _reminderDate = pickedDate;
                                  });
                                }
                              },
                            ),
                            const SizedBox(height: 8),
                            // Reminder time picker
                            ListTile(
                              leading: const Icon(Icons.access_time),
                              title: Text(
                                'Reminder Time: ${_reminderTime != null ? "${_reminderTime!.format(context)}" : "Not set"}',
                              ),
                              trailing: const Icon(Icons.chevron_right),
                              onTap: () async {
                                final now = DateTime.now();
                                final isToday = _reminderDate != null &&
                                    _reminderDate!.year == now.year &&
                                    _reminderDate!.month == now.month &&
                                    _reminderDate!.day == now.day;
                                
                                final pickedTime = await showTimePicker(
                                  context: context,
                                  initialTime: _reminderTime ?? TimeOfDay.now(),
                                );
                                
                                if (pickedTime != null) {
                                  // Check if selected time is in the past (for today)
                                  if (isToday) {
                                    final selectedDateTime = DateTime(
                                      _reminderDate!.year,
                                      _reminderDate!.month,
                                      _reminderDate!.day,
                                      pickedTime.hour,
                                      pickedTime.minute,
                                    );
                                    
                                    if (selectedDateTime.isBefore(now.add(const Duration(minutes: 2)))) {
                                      if (mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                            content: Text('Please select a time at least 2 minutes in the future'),
                                            backgroundColor: Colors.red,
                                          ),
                                        );
                                      }
                                      return;
                                    }
                                  }
                                  
                                  setState(() {
                                    _reminderTime = pickedTime;
                                  });
                                }
                              },
                            ),
                            const SizedBox(height: 16),
                            // Reminder interval
                            Text(
                              'Repeat every (days)',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.remove_circle_outline),
                                  onPressed: _reminderInterval > 1
                                      ? () {
                                          setState(() {
                                            _reminderInterval--;
                                          });
                                        }
                                      : null,
                                ),
                                Expanded(
                                  child: Center(
                                    child: Text(
                                      '$_reminderInterval days',
                                      style: Theme.of(context).textTheme.titleLarge,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.add_circle_outline),
                                  onPressed: () {
                                    setState(() {
                                      _reminderInterval++;
                                    });
                                  },
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
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