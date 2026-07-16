// lib/features/note/domain/repositories/category_repository.dart

import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/category_entity.dart';

/// Abstract repository interface for all category-related operations.
abstract class CategoryRepository {
  /// Real-time stream of the current user's categories
  Stream<List<CategoryEntity>> getUserCategoriesStream(String userId);

  /// Creates a new category for the user
  Future<Either<Failure, Unit>> createCategory(
    String userId,
    CategoryEntity category,
  );

  /// Updates an existing category
  Future<Either<Failure, Unit>> updateCategory(
    String userId,
    CategoryEntity category,
  );

  /// Deletes a category by its ID
  Future<Either<Failure, Unit>> deleteCategory(
    String userId,
    String categoryId,
  );
}
