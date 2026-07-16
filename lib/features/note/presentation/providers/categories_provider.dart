// lib/features/note/presentation/providers/categories_provider.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_notifier.dart';
import '../../data/repositories/category_repository_impl.dart';
import '../../domain/entities/category_entity.dart';
import '../../domain/entities/note_entity.dart';
import '../../domain/repositories/category_repository.dart';
import 'notes_provider.dart'; // لربط عدد الملاحظات لكل فئة

// ────────────────────────────────────────────────
// Repository Provider (concrete implementation)
// ────────────────────────────────────────────────

final categoryRepositoryProvider = Provider<CategoryRepository>((ref) {
  return CategoryRepositoryImpl();
});

// ────────────────────────────────────────────────
// Current user ID provider (for filtering categories)
// ────────────────────────────────────────────────

final currentUserIdProvider = Provider<String?>((ref) {
  final authState = ref.watch(authNotifierProvider);
  return authState.maybeWhen(
    authenticated: (user) => user.uid,
    orElse: () => null,
  );
});

// ────────────────────────────────────────────────
// Default categories (available to all users)
// ────────────────────────────────────────────────

final defaultCategoriesProvider = Provider<List<CategoryEntity>>((ref) {
  return [
    CategoryEntity(
      id: 'personal',
      name: 'Personal',
      color: const Color(0xFF22C55E), // Green
      userId: 'system',
    ),
    CategoryEntity(
      id: 'work',
      name: 'Work',
      color: const Color(0xFF3B82F6), // Blue
      userId: 'system',
    ),
    CategoryEntity(
      id: 'idea',
      name: 'Idea',
      color: const Color(0xFFEC4899), // Pink
      userId: 'system',
    ),
    CategoryEntity(
      id: 'book',
      name: 'Book',
      color: const Color(0xFFF97316), // Orange
      userId: 'system',
    ),
    CategoryEntity(
      id: 'other',
      name: 'Other',
      color: const Color(0xFF64748B), // Gray
      userId: 'system',
    ),
  ];
});

// ────────────────────────────────────────────────
// Stream of user's categories (real-time from Firestore)
// ────────────────────────────────────────────────

final categoriesStreamProvider = StreamProvider.autoDispose<List<CategoryEntity>>((ref) {
  final userId = ref.watch(currentUserIdProvider);

  if (userId == null) {
    return Stream.value(<CategoryEntity>[]);
  }

  final repo = ref.watch(categoryRepositoryProvider);

  return repo.getUserCategoriesStream(userId);
});

/// عدد الملاحظات لكل فئة (محسوب من notesProvider)
final categoryStatsProvider = Provider<Map<String, int>>((ref) {
  final notes = ref.watch(notesStreamProvider).value ?? [];
  final Map<String, int> stats = {};

  for (final note in notes) {
    final cat = note.category ?? 'Other';
    stats.update(cat, (count) => count + 1, ifAbsent: () => 1);
  }

  return stats;
});

/// فئات مع عدد الملاحظات (merged - default + user categories)
final enrichedCategoriesProvider = Provider<List<CategoryEntity>>((ref) {
  final defaultCategories = ref.watch(defaultCategoriesProvider);
  final userCategoriesAsync = ref.watch(categoriesStreamProvider);
  final stats = ref.watch(categoryStatsProvider);

  final userCategories = userCategoriesAsync.value ?? [];
  
  // Combine default categories with user's custom categories
  final allCategories = [...defaultCategories, ...userCategories];
  
  // Add note counts to each category
  return allCategories.map((cat) {
    final count = stats[cat.name] ?? 0;
    return cat.copyWith(noteCount: count);
  }).toList();
});

/// Provider for selected category filter
final selectedCategoryProvider = StateProvider<String?>((ref) => null);

/// Provider for filtered notes by category
final categoryFilteredNotesProvider = Provider<AsyncValue<List<NoteEntity>>>((ref) {
  final notesAsync = ref.watch(notesStreamProvider);
  final selectedCategory = ref.watch(selectedCategoryProvider);
  
  return notesAsync.when(
    data: (notes) {
      if (selectedCategory == null || selectedCategory.isEmpty) {
        return AsyncValue.data(notes);
      }
      
      final filteredNotes = notes.where((note) => note.category == selectedCategory).toList();
      return AsyncValue.data(filteredNotes);
    },
    loading: () => const AsyncValue.loading(),
    error: (error, stack) => AsyncValue.error(error, stack),
  );
});

// ────────────────────────────────────────────────
// CRUD Operations (add / update / delete)
// ────────────────────────────────────────────────

final categoryActionsProvider = Provider<CategoryActions>((ref) {
  final repo = ref.watch(categoryRepositoryProvider);
  final userId = ref.watch(currentUserIdProvider);

  return CategoryActions(
    repo: repo,
    userId: userId,
  );
});

class CategoryActions {
  final CategoryRepository repo;
  final String? userId;

  CategoryActions({required this.repo, required this.userId});

  Future<void> createCategory(CategoryEntity category) async {
    if (userId == null) throw Exception('User not authenticated');
    await repo.createCategory(userId!, category);
  }

  Future<void> updateCategory(CategoryEntity category) async {
    if (userId == null) throw Exception('User not authenticated');
    await repo.updateCategory(userId!, category);
  }

  Future<void> deleteCategory(String categoryId) async {
    if (userId == null) throw Exception('User not authenticated');
    await repo.deleteCategory(userId!, categoryId);
  }
}