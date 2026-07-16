// lib/features/note/data/datasources/category_remote_datasource.dart

import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/category_model.dart';

/// Remote data source responsible for all direct Firestore operations related to categories.
abstract class CategoryRemoteDataSource {
  /// Returns a real-time stream of the user's categories
  Stream<List<CategoryModel>> getUserCategoriesStream(String userId);

  /// Creates a new category in the user's categories sub-collection
  Future<void> createCategory(String userId, CategoryModel category);

  /// Updates an existing category
  Future<void> updateCategory(String userId, CategoryModel category);

  /// Deletes a category by its ID
  Future<void> deleteCategory(String userId, String categoryId);
}

/// Concrete implementation using Firebase Firestore
class CategoryRemoteDataSourceImpl implements CategoryRemoteDataSource {
  final FirebaseFirestore _firestore;

  CategoryRemoteDataSourceImpl({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Stream<List<CategoryModel>> getUserCategoriesStream(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('categories')
        .orderBy('name', descending: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => CategoryModel.fromFirestore(doc.data(), doc.id)).toList();
    });
  }

  @override
  Future<void> createCategory(String userId, CategoryModel category) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('categories')
        .doc(category.id)
        .set(category.toFirestore());
  }

  @override
  Future<void> updateCategory(String userId, CategoryModel category) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('categories')
        .doc(category.id)
        .update(category.toFirestore());
  }

  @override
  Future<void> deleteCategory(String userId, String categoryId) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('categories')
        .doc(categoryId)
        .delete();
  }
}
