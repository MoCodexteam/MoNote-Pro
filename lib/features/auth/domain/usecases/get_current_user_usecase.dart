// lib/features/auth/domain/usecases/get_current_user_usecase.dart

import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/user_entity.dart';
import '../repositories/auth_repository.dart';

/// Use case responsible for retrieving the currently authenticated user.
/// This is typically used at app startup or after auth state changes
/// to determine if the user is already logged in or not.
class GetCurrentUserUseCase {
  final AuthRepository _repository;

  GetCurrentUserUseCase(this._repository);

  /// Returns the current authenticated user (if any) or null if no user is signed in.
  ///
  /// Returns:
  /// - Right(UserEntity?) → current user or null if not authenticated
  /// - Left(Failure) → any error during retrieval
  Future<Either<Failure, UserEntity?>> call() async {
    return await _repository.getCurrentUser();
  }
}