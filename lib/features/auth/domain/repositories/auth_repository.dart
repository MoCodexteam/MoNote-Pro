// lib/features/auth/domain/repositories/auth_repository.dart

import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/user_entity.dart';

/// Abstract interface for authentication operations.
/// This is the contract that both data layer (impl) and presentation layer will depend on.
/// No Firebase or external details here — pure domain.
abstract class AuthRepository {
  /// Signs up a new user with email & password and creates profile in Firestore
  Future<Either<Failure, UserEntity>> signUp({
    required String email,
    required String password,
    required String fullName,
  });

  /// Signs in an existing user with email & password
  Future<Either<Failure, UserEntity>> signIn({
    required String email,
    required String password,
  });

  /// Signs out the current user
  Future<Either<Failure, Unit>> signOut();

  /// Gets the current authenticated user (if any)
  Future<Either<Failure, UserEntity?>> getCurrentUser();

  /// Stream of authentication state changes (used for auto-login / redirect)
  Stream<UserEntity?> authStateChanges();
}