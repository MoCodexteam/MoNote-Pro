// lib/features/auth/domain/usecases/sign_out_usecase.dart

import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../repositories/auth_repository.dart';

/// Use case responsible for signing out the current authenticated user.
///
/// This use case:
/// - Calls the repository to perform sign-out operation
/// - Clears any local auth state or cached data
/// - Returns unit (void success) or Failure on error
class SignOutUseCase {
  final AuthRepository _repository;

  SignOutUseCase(this._repository);

  /// Executes the sign-out operation
  ///
  /// Returns:
  ///   - Right(unit) → on successful sign-out
  ///   - Left(Failure) → on any error (network, server, permission, etc.)
  Future<Either<Failure, Unit>> call() async {
    try {
      return await _repository.signOut();
    } on AuthFailure catch (e) {
      return Left(e);
    } on ServerFailure catch (e) {
      return Left(e);
    } catch (e) {
      return Left(ServerFailure('An error occurred while logging in: $e'));
    }
  }
}