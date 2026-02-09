// lib/features/auth/domain/entities/user_entity.dart

/// Pure domain entity representing a user in MoNote Pro.
/// This class has NO dependencies on external libraries (Firebase, JSON, etc.)
class UserEntity {
  final String uid;
  final String email;
  final String? fullName;
  final String? imageUrl;
  final String? token; // e.g., FCM token for notifications

  const UserEntity({
    required this.uid,
    required this.email,
    this.fullName,
    this.imageUrl,
    this.token,
  });

  /// Used for equality checks (useful in state management and testing)
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserEntity &&
        other.uid == uid &&
        other.email == email &&
        other.fullName == fullName &&
        other.imageUrl == imageUrl &&
        other.token == token;
  }

  @override
  int get hashCode =>
      uid.hashCode ^
      email.hashCode ^
      fullName.hashCode ^
      imageUrl.hashCode ^
      token.hashCode;

  @override
  String toString() =>
      'UserEntity(uid: $uid, email: $email, fullName: $fullName)';
}