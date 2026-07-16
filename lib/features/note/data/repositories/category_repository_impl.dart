// lib/features/note/data/repositories/category_repository_impl.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../../domain/entities/category_entity.dart';
import '../../domain/repositories/category_repository.dart';
import '../datasources/category_remote_datasource.dart';
import '../models/category_model.dart';

/// Concrete implementation of CategoryRepository.
class CategoryRepositoryImpl implements CategoryRepository {
  final CategoryRemoteDataSource _remoteDataSource;

  CategoryRepositoryImpl({
    CategoryRemoteDataSource? remoteDataSource,
  }) : _remoteDataSource = remoteDataSource ?? CategoryRemoteDataSourceImpl();

  @override
  Stream<List<CategoryEntity>> getUserCategoriesStream(String userId) {
    return _remoteDataSource.getUserCategoriesStream(userId).map(
          (models) => models.map((m) => m.toEntity()).toList(),
    );
  }

  @override
  Future<Either<Failure, Unit>> createCategory(String userId, CategoryEntity category) async {
    try {
      final model = CategoryModel(
        id: category.id,
        name: category.name,
        color: category.color,
        userId: category.userId,
        noteCount: category.noteCount,
      );

      await _remoteDataSource.createCategory(userId, model);
      return const Right(unit);
    } on FirebaseException catch (e) {
      return Left(ServerFailure(e.message ?? 'Firestore error during category creation'));
    } catch (e) {
      return Left(ServerFailure('Unexpected error: $e'));
    }
  }

  @override
  Future<Either<Failure, Unit>> updateCategory(String userId, CategoryEntity category) async {
    try {
      final model = CategoryModel(
        id: category.id,
        name: category.name,
        color: category.color,
        userId: category.userId,
        noteCount: category.noteCount,
      );

      await _remoteDataSource.updateCategory(userId, model);
      return const Right(unit);
    } on FirebaseException catch (e) {
      return Left(ServerFailure(e.message ?? 'Firestore error during category update'));
    } catch (e) {
      return Left(ServerFailure('Unexpected error: $e'));
    }
  }

  @override
  Future<Either<Failure, Unit>> deleteCategory(String userId, String categoryId) async {
    try {
      await _remoteDataSource.deleteCategory(userId, categoryId);
      return const Right(unit);
    } on FirebaseException catch (e) {
      return Left(ServerFailure(e.message ?? 'Firestore error during category deletion'));
    } catch (e) {
      return Left(ServerFailure('Unexpected error: $e'));
    }
  }
}
