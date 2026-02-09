// lib/features/auth/presentation/providers/auth_state.dart

import 'package:freezed_annotation/freezed_annotation.dart';

import '../../domain/entities/user_entity.dart';

part 'auth_state.freezed.dart';

/// Immutable authentication state using freezed
/// This class represents all possible states of the auth flow
@freezed
class AuthState with _$AuthState {
  /// Initial state before any auth check
  const factory AuthState.initial() = _Initial;

  /// Loading / in-progress state (sign in, sign up, sign out, fetching current user)
  const factory AuthState.loading() = _Loading;

  /// User is successfully authenticated
  const factory AuthState.authenticated({
    required UserEntity user,
  }) = _Authenticated;

  /// No user is signed in (guest / unauthenticated)
  const factory AuthState.unauthenticated() = _Unauthenticated;

  /// Error state with message
  const factory AuthState.error({
    required String message,
    String? code, // optional Firebase error code if needed
  }) = _Error;
}

// ────────────────────────────────────────────────
// Extension helpers for easier state checking in UI
// ────────────────────────────────────────────────

extension AuthStateX on AuthState {
  /// Returns true if the state is loading
  bool get isLoading => this is _Loading;

  /// Returns true if user is authenticated
  bool get isAuthenticated => this is _Authenticated;

  /// Returns true if user is NOT authenticated
  bool get isUnauthenticated => this is _Unauthenticated;

  /// Returns true if there is an error
  bool get hasError => this is _Error;

  /// Returns the authenticated user or null
  UserEntity? get currentUser {
    return maybeWhen(
      authenticated: (user) => user,
      orElse: () => null,
    );
  }

  /// Returns the error message or empty string
  String get errorMessage {
    return maybeWhen(
      error: (message, _) => message,
      orElse: () => '',
    );
  }
}