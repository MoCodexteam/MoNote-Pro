// lib/features/auth/data/datasources/auth_remote_datasource.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/errors/failures.dart';
import '../models/user_model.dart';

/// Remote data source that handles all Firebase Authentication & Firestore operations
/// related to user authentication and profile management.
abstract class AuthRemoteDataSource {
  /// Creates a new user account using email & password
  Future<UserModel> signUpWithEmailAndPassword({
    required String email,
    required String password,
    required String fullName,
  });

  /// Signs in an existing user with email & password
  Future<UserModel> signInWithEmailAndPassword({
    required String email,
    required String password,
  });

  /// Signs out the current user
  Future<void> signOut();

  /// Gets the currently signed-in user (if any)
  Future<UserModel?> getCurrentUser();

  /// Stream of authentication state changes
  Stream<UserModel?> authStateChanges();
}

/// Concrete implementation using Firebase Auth & Firestore
class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final FirebaseAuth _firebaseAuth;
  final FirebaseFirestore _firestore;

  AuthRemoteDataSourceImpl({
    FirebaseAuth? firebaseAuth,
    FirebaseFirestore? firestore,
  })  : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Future<UserModel> signUpWithEmailAndPassword({
    required String email,
    required String password,
    required String fullName,
  }) async {
    try {
      // إنشاء حساب جديد في Firebase Authentication
      final userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );

      final user = userCredential.user;
      if (user == null) {
        throw const AuthFailure('فشل إنشاء الحساب');
      }

      // إنشاء ملف المستخدم في Firestore
      final userModel = UserModel(
        uid: user.uid,
        email: user.email ?? email,
        fullName: fullName.trim(),
        imageUrl: null,
        token: null, // يمكن تحديثه لاحقًا عند الحصول على FCM token
        createdAt: DateTime.now(),
      );

      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(user.uid)
          .set(userModel.toJson());

      return userModel;
    } on FirebaseAuthException catch (e) {
      throw AuthFailure.fromFirebaseCode(e.code);
    } on FirebaseException catch (_) {
      throw const ServerFailure();
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }

  @override
  Future<UserModel> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final userCredential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );

      final user = userCredential.user;
      if (user == null) {
        throw const AuthFailure('login failed');
      }

      // جلب بيانات المستخدم من Firestore
      final doc = await _firestore
          .collection(AppConstants.usersCollection)
          .doc(user.uid)
          .get();

      if (!doc.exists || doc.data() == null) {
        throw const ServerFailure('User data not found');
      }

      return UserModel.fromJson(doc.data()!);
    } on FirebaseAuthException catch (e) {
      throw AuthFailure.fromFirebaseCode(e.code);
    } on FirebaseException catch (_) {
      throw const ServerFailure();
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await _firebaseAuth.signOut();
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }

  @override
  Future<UserModel?> getCurrentUser() async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) return null;

      final doc = await _firestore
          .collection(AppConstants.usersCollection)
          .doc(user.uid)
          .get();

      if (!doc.exists || doc.data() == null) return null;

      return UserModel.fromJson(doc.data()!);
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }

  @override
  Stream<UserModel?> authStateChanges() {
    return _firebaseAuth.authStateChanges().asyncMap((firebaseUser) async {
      if (firebaseUser == null) return null;

      try {
        final doc = await _firestore
            .collection(AppConstants.usersCollection)
            .doc(firebaseUser.uid)
            .get();

        if (doc.exists && doc.data() != null) {
          return UserModel.fromJson(doc.data()!);
        }
        return null;
      } catch (_) {
        return null;
      }
    });
  }
}