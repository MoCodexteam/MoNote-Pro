// lib/features/note/data/models/category_model.dart

import 'package:flutter/material.dart';

import '../../domain/entities/category_entity.dart';

class CategoryModel extends CategoryEntity {
  const CategoryModel({
    required super.id,
    required super.name,
    required super.color,
    required super.userId,
    super.noteCount,
  });

  /// من Firestore
  factory CategoryModel.fromFirestore(Map<String, dynamic> data, String id) {
    return CategoryModel(
      id: id,
      name: data['name'] as String? ?? 'Unknown',
      color: _parseColor(data['color'] as String? ?? '#808080'),
      userId: data['userId'] as String? ?? '',
      noteCount: data['noteCount'] as int? ?? 0,
    );
  }

  /// إلى Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'color': _colorToHex(color),
      'userId': userId,
      'noteCount': noteCount,
    };
  }

  static Color _parseColor(String? hex) {
    if (hex == null || hex.isEmpty) return Colors.grey;
    try {
      String clean = hex.replaceAll('#', '').padLeft(8, 'ff');
      return Color(int.parse(clean, radix: 16));
    } catch (_) {
      return Colors.grey;
    }
  }

  static String _colorToHex(Color color) {
    return '#${color.toARGB32().toRadixString(16).padLeft(8, '0').substring(2)}';
  }

  /// Converts this model back to the pure domain entity
  CategoryEntity toEntity() => this;
}