// lib/features/note/presentation/screens/create_edit_note_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart'; // لتوليد ID جديد (أضف في pubspec: uuid: ^4.0.0)

import '../../../auth/presentation/providers/auth_notifier.dart';
import '../../../auth/presentation/providers/auth_state.dart';
import '../../domain/entities/note_entity.dart';
import '../../presentation/providers/notes_provider.dart';

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
  late TextEditingController _titleController;
  late TextEditingController _contentController;
  late TextEditingController _tagsController;

  String _selectedCategory = 'Personal';
  bool _isPinned = false;
  bool _isSaving = false;

  // قائمة فئات مؤقتة (يمكن جلبها من provider لاحقًا)
  final List<Map<String, dynamic>> _categories = [
    {'name': 'Personal', 'color': Colors.green},
    {'name': 'Work', 'color': Colors.blue},
    {'name': 'Ideas', 'color': Colors.purple},
    {'name': 'Books', 'color': Colors.orange},
    {'name': 'Other', 'color': Colors.grey},
  ];

  @override
  void initState() {
    super.initState();

    _titleController = TextEditingController(text: widget.existingNote?.title ?? '');
    _contentController = TextEditingController(text: widget.existingNote?.content ?? '');
    _tagsController = TextEditingController(
      text: widget.existingNote?.tags.join(', ') ?? '',
    );

    _selectedCategory = widget.existingNote?.category ?? 'Personal';
    _isPinned = widget.existingNote?.isPinned ?? false;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _tagsController.dispose();
    super.dispose();
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

    final note = NoteEntity(
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
      categoryColor: _categories.firstWhere((c) => c['name'] == _selectedCategory)['color'] as Color?,
      isPinned: _isPinned,
    );

    final actions = ref.read(notesActionsProvider);

    try {
      if (widget.existingNote != null) {
        await actions.updateNote(note);
      } else {
        await actions.createNote(note);
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
                    icon: Icon(Icons.arrow_back, color: Theme.of(context).colorScheme.onSurface),
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

                    // شريط الأدوات (placeholder حاليًا)
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.format_bold),
                          onPressed: () {}, // TODO: تنسيق bold
                        ),
                        IconButton(
                          icon: const Icon(Icons.format_italic),
                          onPressed: () {},
                        ),
                        IconButton(
                          icon: const Icon(Icons.code),
                          onPressed: () {},
                        ),
                        IconButton(
                          icon: const Icon(Icons.checklist),
                          onPressed: () {},
                        ),
                      ],
                    ),

                    const Divider(height: 32),

                    // محتوى الملاحظة
                    TextField(
                      controller: _contentController,
                      decoration: const InputDecoration(
                        hintText: 'start writing..',
                        border: InputBorder.none,
                        hintStyle: TextStyle(fontSize: 16),
                      ),
                      style: Theme.of(context).textTheme.bodyLarge,
                      maxLines: null,
                      minLines: 10,
                    ),

                    const SizedBox(height: 32),

                    // اختيار الفئة
                    Text(
                      'Category',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _selectedCategory,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      items: _categories.map((cat) {
                        return DropdownMenuItem<String>(
                          value: cat['name'] as String,
                          child: Row(
                            children: [
                              Container(
                                width: 16,
                                height: 16,
                                decoration: BoxDecoration(
                                  color: cat['color'] as Color,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(cat['name'] as String),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) setState(() => _selectedCategory = value);
                      },
                    ),

                    const SizedBox(height: 24),

                    // إدخال التاجات
                    Text(
                      'Crowns (separated by commas)',
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