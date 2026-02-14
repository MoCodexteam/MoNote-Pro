// lib/features/note/presentation/providers/categories_provider.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/category_entity.dart';
import 'notes_provider.dart'; // لربط عدد الملاحظات لكل فئة

/// قائمة الفئات المتاحة (ثابتة حاليًا – يمكن جلبها من Firestore لاحقًا)
final categoriesProvider = Provider<List<CategoryEntity>>((ref) {
  return [
    CategoryEntity(id: 'personal', name: 'Personal', color: Colors.green),
    CategoryEntity(id: 'work', name: 'Work', color: Colors.blue),
    CategoryEntity(id: 'ideas', name: 'Ideas', color: Colors.purple),
    CategoryEntity(id: 'books', name: 'Books', color: Colors.orange),
    CategoryEntity(id: 'other', name: 'Other', color: Colors.grey),
  ];
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

/// فئات مع عدد الملاحظات (merged)
final enrichedCategoriesProvider = Provider<List<CategoryEntity>>((ref) {
  final categories = ref.watch(categoriesProvider);
  final stats = ref.watch(categoryStatsProvider);

  return categories.map((cat) {
    final count = stats[cat.name] ?? 0;
    return cat.copyWith(noteCount: count);
  }).toList();
});