// lib/features/auth/domain/usecases/sign_in_usecase.dart

import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/user_entity.dart';
import '../repositories/auth_repository.dart';

/// Use case responsible for signing in an existing user with email & password.
///
/// This use case:
/// - Takes email & password as input
/// - Calls the repository to perform the sign-in
/// - Returns either the authenticated UserEntity or a Failure
class SignInUseCase {
  final AuthRepository _repository;

  SignInUseCase(this._repository);

  /// Executes the sign-in operation
  ///
  /// Parameters:
  ///   - email: user's email address
  ///   - password: user's password
  ///
  /// Returns:
  ///   - Right(UserEntity) → on successful sign-in
  ///   - Left(Failure) → on any error (wrong credentials, network, server, etc.)
  Future<Either<Failure, UserEntity>> call({
    required String email,
    required String password,
  }) async {
    // Basic input validation (optional – can be moved to presentation layer)
    if (email.trim().isEmpty) {
      return Left(AuthFailure('Email is required'));
    }
    if (password.trim().isEmpty) {
      return Left(AuthFailure('Password required'));
    }

    try {
      return await _repository.signIn(
        email: email.trim(),
        password: password.trim(),
      );
    } catch (e) {
      // Catch any unexpected errors not handled by repository
      return Left(ServerFailure('An error occurred while logging in: $e'));
    }
  }
}