/// Base class for all custom exceptions in the app
abstract class AppException implements Exception {
  final String message;
  final String? code;
  final dynamic details;

  const AppException({
    required this.message,
    this.code,
    this.details,
  });

  @override
  String toString() {
    return 'AppException: $message${code != null ? ' (code: $code)' : ''}';
  }
}

/// Thrown when there is no authenticated user
class AuthException extends AppException {
  const AuthException(String message, {String? code})
      : super(message: message, code: code);
}

/// Thrown when a requested resource (e.g. note) is not found
class NotFoundException extends AppException {
  const NotFoundException(String message, {String? code})
      : super(message: message, code: code);
}

/// Thrown when there is a problem with the server / backend (Firebase, API, etc.)
class ServerException extends AppException {
  const ServerException(String message, {String? code, dynamic details})
      : super(message: message, code: code, details: details);
}

/// Thrown when there is no internet connection or network issue
class NetworkException extends AppException {
  const NetworkException([String message = 'No internet connection'])
      : super(message: message);
}

/// Thrown when input data is invalid (validation errors before sending to backend)
class ValidationException extends AppException {
  final Map<String, String>? fieldErrors;

  const ValidationException(
      String message, {
        this.fieldErrors,
        String? code,
      }) : super(message: message, code: code);
}

/// Thrown when the cache is empty or outdated and no remote data is available
class CacheException extends AppException {
  const CacheException([String message = 'Cache error / No cached data'])
      : super(message: message);
}

/// General unexpected error (fallback when we don't know the exact type)
class UnexpectedException extends AppException {
  const UnexpectedException(String message, {dynamic details})
      : super(message: message, details: details);
}

/// Firebase-specific exceptions wrapper
class FirebaseAuthExceptionWrapper extends AppException {
  const FirebaseAuthExceptionWrapper({
    required String message,
    String? code,
    dynamic details,
  }) : super(message: message, code: code, details: details);
}

class FirebaseFirestoreExceptionWrapper extends AppException {
  const FirebaseFirestoreExceptionWrapper({
    required String message,
    String? code,
    dynamic details,
  }) : super(message: message, code: code, details: details);
}