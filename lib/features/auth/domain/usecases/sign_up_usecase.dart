// lib/features/auth/domain/usecases/sign_up_usecase.dart

import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/user_entity.dart';
import '../repositories/auth_repository.dart';

/// Use case responsible for registering a new user with email & password,
/// and creating the initial user profile in Firestore.
///
/// This use case:
/// - Validates basic input requirements
/// - Calls the repository to perform sign-up + profile creation
/// - Returns either the newly created UserEntity or a Failure
class SignUpUseCase {
  final AuthRepository _repository;

  SignUpUseCase(this._repository);

  /// Executes the sign-up operation
  ///
  /// Parameters:
  ///   - email: user's email address
  ///   - password: user's password
  ///   - fullName: user's full name (required for profile)
  ///
  /// Returns:
  ///   - Right(UserEntity) → on successful registration and profile creation
  ///   - Left(Failure) → on validation error, auth error, network issue, etc.
  Future<Either<Failure, UserEntity>> call({
    required String email,
    required String password,
    required String fullName,
  }) async {
    // Basic input validation (can be moved to presentation if preferred)
    if (email.trim().isEmpty) {
      return Left(AuthFailure('Email is required'));
    }

    if (password.trim().isEmpty) {
      return Left(AuthFailure('Password required'));
    }

    if (fullName.trim().isEmpty) {
      return Left(AuthFailure('Fullname required'));
    }

    if (fullName.trim().length < 2) {
      return Left(AuthFailure('The full name is very short'));
    }

    try {
      return await _repository.signUp(
        email: email.trim(),
        password: password.trim(),
        fullName: fullName.trim(),
      );
    } on AuthFailure catch (e) {
      return Left(e);
    } on ServerFailure catch (e) {
      return Left(e);
    } catch (e) {
      return Left(ServerFailure('حدث خطأ أثناء التسجيل: $e'));
    }
  }
}