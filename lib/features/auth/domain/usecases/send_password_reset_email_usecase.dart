// lib/features/auth/domain/usecases/send_password_reset_email_usecase.dart

import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../repositories/auth_repository.dart';

/// Use case responsible for sending password reset email to a user.
///
/// This use case:
/// - Takes email as input
/// - Calls the repository to send the password reset email
/// - Returns either Unit (success) or a Failure
class SendPasswordResetEmailUseCase {
  final AuthRepository _repository;

  SendPasswordResetEmailUseCase(this._repository);

  /// Executes the password reset email operation
  ///
  /// Parameters:
  ///   - email: user's email address
  ///
  /// Returns:
  ///   - Right(Unit) → on successful email send
  ///   - Left(Failure) → on any error (invalid email, network, server, etc.)
  Future<Either<Failure, Unit>> call({
    required String email,
  }) async {
    // Basic input validation
    if (email.trim().isEmpty) {
      return Left(AuthFailure('Email is required'));
    }

    try {
      return await _repository.sendPasswordResetEmail(email.trim());
    } catch (e) {
      // Catch any unexpected errors not handled by repository
      return Left(
          ServerFailure('An error occurred while sending reset email: $e'));
    }
  }
}
