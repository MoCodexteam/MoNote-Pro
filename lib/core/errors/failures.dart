// lib/core/errors/failures.dart

/// Base class for all failures in the application.
/// Every specific failure should extend this class.
abstract class Failure {
  final String message;

  const Failure(this.message);

  @override
  String toString() => message;
}

/// General server-side or unexpected failures
class ServerFailure extends Failure {
  const ServerFailure([super.message = 'Server failure occurred']);
}

/// Authentication related failures
class AuthFailure extends Failure {
  const AuthFailure(super.message);

  factory AuthFailure.fromFirebaseCode(String code) {
    switch (code) {
      case 'user-not-found':
        return const AuthFailure('No user found with this email.');
      case 'wrong-password':
        return const AuthFailure('Incorrect password.');
      case 'email-already-in-use':
        return const AuthFailure('The email is already in use.');
      case 'weak-password':
        return const AuthFailure('Password is too weak.');
      case 'invalid-email':
        return const AuthFailure('Invalid email format.');
      case 'too-many-requests':
        return const AuthFailure('Too many attempts. Please try again later.');
      default:
        return AuthFailure('Authentication error: $code');
    }
  }
}

/// No internet connection
class NetworkFailure extends Failure {
  const NetworkFailure() : super('No internet connection');
}

/// Cache / local storage failures (if used later)
class CacheFailure extends Failure {
  const CacheFailure([super.message = 'Cache failure occurred']);
}