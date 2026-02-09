// lib/features/auth/presentation/providers/auth_notifier.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/repositories/auth_repository.dart';
import '../../domain/usecases/get_current_user_usecase.dart';
import '../../domain/usecases/sign_in_usecase.dart';
import '../../domain/usecases/sign_out_usecase.dart';
import '../../domain/usecases/sign_up_usecase.dart';
import '../providers/auth_state.dart';
import '../../data/datasources/auth_remote_datasource.dart';
import '../../data/repositories/auth_repository_impl.dart';

/// Riverpod Notifier that manages authentication state
/// Handles sign-up, sign-in, sign-out, and current user loading
class AuthNotifier extends AutoDisposeNotifier<AuthState> {
  late final SignUpUseCase _signUpUseCase;
  late final SignInUseCase _signInUseCase;
  late final SignOutUseCase _signOutUseCase;
  late final GetCurrentUserUseCase _getCurrentUserUseCase;

  @override
  AuthState build() {
    // Initialize use cases
    _signUpUseCase = ref.read(signUpUseCaseProvider);
    _signInUseCase = ref.read(signInUseCaseProvider);
    _signOutUseCase = ref.read(signOutUseCaseProvider);
    _getCurrentUserUseCase = ref.read(getCurrentUserUseCaseProvider);

    // Load current user immediately when provider is created
    _loadCurrentUser();

    return const AuthState.initial();
  }

  /// Loads the currently authenticated user
  Future<void> _loadCurrentUser() async {
    state = const AuthState.loading();

    final result = await _getCurrentUserUseCase();

    state = result.fold(
          (failure) => AuthState.error(message: failure.message),
          (user) => user != null
          ? AuthState.authenticated(user: user)
          : const AuthState.unauthenticated(),
    );
  }

  /// Signs up a new user
  Future<void> signUp({
    required String email,
    required String password,
    required String fullName,
  }) async {
    state = const AuthState.loading();

    final result = await _signUpUseCase(
      email: email,
      password: password,
      fullName: fullName,
    );

    state = result.fold(
          (failure) => AuthState.error(message: failure.message),
          (user) => AuthState.authenticated(user: user),
    );
  }

  /// Signs in an existing user
  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    state = const AuthState.loading();

    final result = await _signInUseCase(
      email: email,
      password: password,
    );

    state = result.fold(
          (failure) => AuthState.error(message: failure.message),
          (user) => AuthState.authenticated(user: user),
    );
  }

  /// Signs out the current user
  Future<void> signOut() async {
    state = const AuthState.loading();

    final result = await _signOutUseCase();

    state = result.fold(
          (failure) => AuthState.error(message: failure.message),
          (_) {
        // After successful sign out → reload (should be unauthenticated)
        _loadCurrentUser();
        return const AuthState.unauthenticated();
      },
    );
  }

  /// Manually refresh current user state
  Future<void> refresh() => _loadCurrentUser();
}

// ────────────────────────────────────────────────
// Providers
// ────────────────────────────────────────────────

final authNotifierProvider = NotifierProvider.autoDispose<AuthNotifier, AuthState>(
  AuthNotifier.new,
);

// ────────────────────────────────────────────────
// UseCase Providers (dependency injection style)
// ────────────────────────────────────────────────

final signUpUseCaseProvider = Provider<SignUpUseCase>(
      (ref) => SignUpUseCase(ref.read(authRepositoryProvider)),
);

final signInUseCaseProvider = Provider<SignInUseCase>(
      (ref) => SignInUseCase(ref.read(authRepositoryProvider)),
);

final signOutUseCaseProvider = Provider<SignOutUseCase>(
      (ref) => SignOutUseCase(ref.read(authRepositoryProvider)),
);

final getCurrentUserUseCaseProvider = Provider<GetCurrentUserUseCase>(
      (ref) => GetCurrentUserUseCase(ref.read(authRepositoryProvider)),
);

// ────────────────────────────────────────────────
// Repository Provider (concrete implementation)
// ────────────────────────────────────────────────

final authRepositoryProvider = Provider<AuthRepository>(
      (ref) => AuthRepositoryImpl(
    remoteDataSource: AuthRemoteDataSourceImpl(),
  ),
);