// lib/core/utils/validators.dart

import 'package:formz/formz.dart';

/// Validation input states using Formz (pure, immutable, and easy to use in Riverpod/Bloc)
/// All validators return FormzInput with error messages in Arabic for better UX

// ────────────────────────────────────────────────
// Email Validator
// ────────────────────────────────────────────────
class Email extends FormzInput<String, String> {
  const Email.pure([super.value = '']) : super.pure();
  const Email.dirty([super.value = '']) : super.dirty();

  static final _emailRegex = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  );

  @override
  String? validator(String? value) {
    if (value == null || value.isEmpty) {
      return 'البريد الإلكتروني مطلوب';
    }
    if (!_emailRegex.hasMatch(value)) {
      return 'صيغة البريد الإلكتروني غير صحيحة';
    }
    return null;
  }
}

// ────────────────────────────────────────────────
// Password Validator
// ────────────────────────────────────────────────
class Password extends FormzInput<String, String> {
  const Password.pure([super.value = '']) : super.pure();
  const Password.dirty([super.value = '']) : super.dirty();

  @override
  String? validator(String? value) {
    if (value == null || value.isEmpty) {
      return 'كلمة المرور مطلوبة';
    }
    if (value.length < 6) {
      return 'كلمة المرور يجب أن تكون 6 أحرف على الأقل';
    }
    // يمكن إضافة شروط أكثر صرامة لاحقًا (أرقام، رموز، حروف كبيرة...)
    return null;
  }
}

// ────────────────────────────────────────────────
// Confirm Password Validator (يحتاج إلى مقارنة مع كلمة المرور الأصلية)
// ────────────────────────────────────────────────
class ConfirmPassword extends FormzInput<String, String> {
  const ConfirmPassword.pure({
    required this.originalPassword,
    String value = '',
  }) : super.pure(value);

  const ConfirmPassword.dirty({
    required this.originalPassword,
    String value = '',
  }) : super.dirty(value);

  final String originalPassword;

  @override
  String? validator(String? value) {
    if (value == null || value.isEmpty) {
      return 'تأكيد كلمة المرور مطلوب';
    }
    if (value != originalPassword) {
      return 'كلمتا المرور غير متطابقتين';
    }
    return null;
  }
}

// ────────────────────────────────────────────────
// Full Name Validator
// ────────────────────────────────────────────────
class FullName extends FormzInput<String, String> {
  const FullName.pure([super.value = '']) : super.pure();
  const FullName.dirty([super.value = '']) : super.dirty();

  @override
  String? validator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'الاسم الكامل مطلوب';
    }
    if (value.trim().length < 2) {
      return 'الاسم قصير جدًا';
    }
    if (value.trim().length > 60) {
      return 'الاسم طويل جدًا';
    }
    return null;
  }
}

// ────────────────────────────────────────────────
// Simple utility functions (إذا أردت استخدامها بدون Formz في بعض الحالات)
// ────────────────────────────────────────────────

String? validateEmail(String? email) {
  if (email == null || email.isEmpty) return 'البريد الإلكتروني مطلوب';
  if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(email)) {
    return 'صيغة البريد الإلكتروني غير صحيحة';
  }
  return null;
}

String? validatePassword(String? password) {
  if (password == null || password.isEmpty) return 'كلمة المرور مطلوبة';
  if (password.length < 6) return 'كلمة المرور يجب أن تكون 6 أحرف على الأقل';
  return null;
}

String? validateConfirmPassword(String? confirm, String? original) {
  if (confirm == null || confirm.isEmpty) return 'تأكيد كلمة المرور مطلوب';
  if (confirm != original) return 'كلمتا المرور غير متطابقتين';
  return null;
}

String? validateFullName(String? name) {
  if (name == null || name.trim().isEmpty) return 'الاسم الكامل مطلوب';
  if (name.trim().length < 2) return 'الاسم قصير جدًا';
  return null;
}