// lib/features/search/presentation/screens/search_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../note/domain/entities/note_entity.dart';
import '../../../note/presentation/providers/categories_provider.dart';
import '../../../note/presentation/providers/notes_provider.dart';
import '../../../home/presentation/widgets/note_card.dart';
import '../../../note/presentation/screens/create_edit_note_screen.dart';

/// شاشة البحث المتقدم (Search Screen)
/// تدعم:
/// - بحث فوري في العنوان + المحتوى + التاجات
/// - فلاتر: ترتيب (Recent/Oldest/Title) + تصفية (All/Pinned/Category)
/// - Highlight للكلمة المبحوث عنها
/// - الانتقال لتعديل الملاحظة عند الضغط
class SearchScreen extends ConsumerStatefulWidget {
  final VoidCallback onBack;

  const SearchScreen({
    super.key,
    required this.onBack,
  });

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  SortOption _sortBy = SortOption.recent;
  FilterOption _filterBy = const FilterAll();

  bool _showFilters = false;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() => _searchQuery = _searchController.text.trim());
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final notesAsync = ref.watch(notesStreamProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            // Header مع زر رجوع + بحث + زر فلاتر
            _buildHeader(context),

            // الفلاتر (تظهر عند الضغط على زر Filter)
            if (_showFilters) _buildFilters(context),

            // نتائج البحث
            Expanded(
              child: notesAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, stack) => Center(
                  child: Text('Error loading notes: $err', style: const TextStyle(color: Colors.red)),
                ),
                data: (allNotes) {
                  // تصفية + ترتيب الملاحظات
                  var filtered = _applyFilters(allNotes);
                  filtered = _applySort(filtered);

                  return filtered.isEmpty
                      ? _buildEmptyState(context)
                      : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final note = filtered[index];
                      return SearchResultCard(
                        note: note,
                        searchQuery: _searchQuery,
                        onTap: () => _onViewNote(note),
                      );
                    },
                  );
                },
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
            icon: const Icon(Icons.arrow_back),
            onPressed: widget.onBack,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _searchController,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Search notes, tags...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: Icon(
              Icons.filter_list,
              color: _showFilters ? Theme.of(context).colorScheme.primary : null,
            ),
            onPressed: () => setState(() => _showFilters = !_showFilters),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLowest,
        border: Border(
          bottom: BorderSide(color: Theme.of(context).dividerColor),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Sort by
          Row(
            children: [
              const Icon(Icons.sort, size: 20),
              const SizedBox(width: 8),
              Text('Sort by', style: Theme.of(context).textTheme.titleMedium),
            ],
          ),
          const SizedBox(height: 8),
          SegmentedButton<SortOption>(
            segments: const [
              ButtonSegment(value: SortOption.recent, label: Text('Recent')),
              ButtonSegment(value: SortOption.oldest, label: Text('Oldest')),
              ButtonSegment(value: SortOption.title, label: Text('Title')),
            ],
            selected: {_sortBy},
            onSelectionChanged: (newSelection) {
              setState(() => _sortBy = newSelection.first);
            },
          ),
          const SizedBox(height: 16),

          // Filter by
          Row(
            children: [
              const Icon(Icons.filter_alt, size: 20),
              const SizedBox(width: 8),
              Text('Filter by', style: Theme.of(context).textTheme.titleMedium),
            ],
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<FilterOption>(
            value: _filterBy,
            decoration: InputDecoration(
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            items: [
              const DropdownMenuItem(value: FilterAll(), child: Text('All Notes')),
              const DropdownMenuItem(value: FilterPinned(), child: Text('Pinned Only')),
              ...ref.watch(enrichedCategoriesProvider).map(
                    (cat) => DropdownMenuItem(
                  value: FilterCategory(cat.name),
                  child: Text(cat.name),
                ),
              ),
            ],
            onChanged: (value) {
              if (value != null) setState(() => _filterBy = value);
            },
          ),
        ],
      ),
    );
  }

  List<NoteEntity> _applyFilters(List<NoteEntity> notes) {
    return notes.where((note) {
      final matchesSearch = _searchQuery.isEmpty ||
          note.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          note.content.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          note.tags.any((tag) => tag.toLowerCase().contains(_searchQuery.toLowerCase()));

      if (_filterBy is FilterAll) return matchesSearch;
      if (_filterBy is FilterPinned) return matchesSearch && note.isPinned;
      if (_filterBy is FilterCategory) {
        final catFilter = _filterBy as FilterCategory;
        return matchesSearch && note.category == catFilter.name;
      }
      return matchesSearch;
    }).toList();
  }

  List<NoteEntity> _applySort(List<NoteEntity> notes) {
    final sorted = List<NoteEntity>.from(notes);
    sorted.sort((a, b) {
      switch (_sortBy) {
        case SortOption.recent:
          return b.lastEdit.compareTo(a.lastEdit);
        case SortOption.oldest:
          return a.lastEdit.compareTo(b.lastEdit);
        case SortOption.title:
          return a.title.compareTo(b.title);
      }
    });
    return sorted;
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 80,
            color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.6),
          ),
          const SizedBox(height: 24),
          Text(
            _searchQuery.isEmpty ? 'Start searching...' : 'No notes found',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          if (_searchQuery.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Try different keywords or adjust filters',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
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
}

/// Enum-like class for filter options
sealed class FilterOption {
  const FilterOption();
}

class FilterAll extends FilterOption {
  const FilterAll();
}

class FilterPinned extends FilterOption {
  const FilterPinned();
}

class FilterCategory extends FilterOption {
  final String name;
  const FilterCategory(this.name);
}

/// Sort options
enum SortOption { recent, oldest, title }

/// Card لعرض نتيجة بحث واحدة (مع Highlight)
class SearchResultCard extends StatelessWidget {
  final NoteEntity note;
  final String searchQuery;
  final VoidCallback onTap;

  const SearchResultCard({
    super.key,
    required this.note,
    required this.searchQuery,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        margin: const EdgeInsets.only(bottom: 12),
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 4,
                height: 64,
                decoration: BoxDecoration(
                  color: note.categoryColor ?? Theme.of(context).colorScheme.primary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _highlightText(
                            context,
                            note.title,
                            searchQuery,
                            isTitle: true,
                          ),
                        ),
                        if (note.isPinned)
                          const Padding(
                            padding: EdgeInsets.only(left: 8),
                            child: Icon(Icons.push_pin, size: 18, color: Colors.blue),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    _highlightText(
                      context,
                      note.content,
                      searchQuery,
                      maxLines: 2,
                    ),
                    // ... باقي الـ footer (time, category, tags)
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // الدالة نفسها (مع context كـ أول parameter)
  Widget _highlightText(
      BuildContext context,
      String text,
      String query, {
        bool isTitle = false,
        int? maxLines,
      }) {
    if (query.isEmpty) {
      return Text(
        text,
        maxLines: maxLines ?? 1,
        overflow: TextOverflow.ellipsis,
        style: isTitle
            ? Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)
            : Theme.of(context).textTheme.bodyMedium,
      );
    }

    final parts = text.split(RegExp('(${RegExp.escape(query)})', caseSensitive: false));

    return Text.rich(
      TextSpan(
        children: parts.map((part) {
          final match = RegExp(query, caseSensitive: false).hasMatch(part);
          return TextSpan(
            text: part,
            style: match
                ? TextStyle(
              backgroundColor: Colors.yellow.withOpacity(0.4),
              fontWeight: isTitle ? FontWeight.w600 : null,
            )
                : null,
          );
        }).toList(),
      ),
      maxLines: maxLines,
      overflow: TextOverflow.ellipsis,
    );
  }
}