// lib/features/auth/data/models/user_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../../core/constants/app_constants.dart';
import '../../domain/entities/user_entity.dart';

/// Data layer model that extends the pure domain entity (UserEntity).
/// This class handles JSON serialization / deserialization for Firestore.
class UserModel extends UserEntity {
  final DateTime? createdAt;

  const UserModel({
    required super.uid,
    required super.email,
    super.fullName,
    super.imageUrl,
    super.token,
    this.createdAt,
  });

  /// Creates a UserModel from Firestore document data
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      uid: json[AppConstants.userFieldUid] as String? ?? '',
      email: json[AppConstants.userFieldEmail] as String? ?? '',
      fullName: json[AppConstants.userFieldFullName] as String?,
      imageUrl: json[AppConstants.userFieldImageUrl] as String?,
      token: json[AppConstants.userFieldToken] as String?,
      createdAt: (json[AppConstants.userFieldCreatedAt] as Timestamp?)?.toDate(),
    );
  }

  /// Converts the model to a JSON-compatible map for Firestore
  Map<String, dynamic> toJson() {
    return {
      AppConstants.userFieldUid: uid,
      AppConstants.userFieldEmail: email,
      if (fullName != null) AppConstants.userFieldFullName: fullName,
      if (imageUrl != null) AppConstants.userFieldImageUrl: imageUrl,
      if (token != null) AppConstants.userFieldToken: token,
      AppConstants.userFieldCreatedAt: createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
    };
  }

  /// Factory to create from Firebase User + additional profile data
  factory UserModel.fromFirebaseUser(
      User firebaseUser, {
        String? fullName,
        String? imageUrl,
        String? token,
      }) {
    return UserModel(
      uid: firebaseUser.uid,
      email: firebaseUser.email ?? '',
      fullName: fullName,
      imageUrl: imageUrl,
      token: token,
      createdAt: DateTime.now(),
    );
  }

  /// Converts back to the pure domain entity (when passing to domain/use-cases)
  UserEntity toEntity() {
    return UserEntity(
      uid: uid,
      email: email,
      fullName: fullName,
      imageUrl: imageUrl,
      token: token,
    );
  }
}