// lib/core/constants/app_constants.dart

/// Central place for all application-wide constants
/// This helps avoid magic strings/numbers and makes maintenance easier
class AppConstants {
  // ────────────────────────────────────────────────
  // App Info
  // ────────────────────────────────────────────────
  static const String appName = 'MoNote Pro';
  static const String appVersion = '1.0.0';
  static const String appDescription = 'تطبيق تدوين الملاحظات الذكي مع المزامنة السحابية';
  static const String developerTeam = 'MoCodex';

  // ────────────────────────────────────────────────
  // Firebase Collections & Fields
  // ────────────────────────────────────────────────
  static const String usersCollection = 'users';
  static const String notesSubCollection = 'notes';

  // User document fields
  static const String userFieldUid = 'uid';
  static const String userFieldEmail = 'email';
  static const String userFieldFullName = 'fullName';
  static const String userFieldImageUrl = 'imageUrl';
  static const String userFieldToken = 'token';
  static const String userFieldCreatedAt = 'createdAt';

  // Note document fields
  static const String noteFieldId = 'id';
  static const String noteFieldTitle = 'title';
  static const String noteFieldContent = 'content';
  static const String noteFieldDateCreated = 'dateCreated';
  static const String noteFieldLastEdit = 'lastEdit';
  static const String noteFieldTags = 'tags';
  static const String noteFieldCategory = 'category';
  static const String noteFieldPin = 'pin';

  // ────────────────────────────────────────────────
  // UI & Design Constants
  // ────────────────────────────────────────────────
  static const double defaultPadding = 16.0;
  static const double cardElevation = 2.0;
  static const double borderRadius = 16.0;
  static const double iconSizeLarge = 80.0;
  static const double buttonHeight = 54.0;
  static const double textFieldHeight = 56.0;

  // ────────────────────────────────────────────────
  // Duration & Timing
  // ────────────────────────────────────────────────
  static const Duration splashDuration = Duration(seconds: 3);
  static const Duration animationDuration = Duration(milliseconds: 300);
  static const Duration debounceTime = Duration(milliseconds: 500);
  static const Duration networkTimeout = Duration(seconds: 30);

  // ────────────────────────────────────────────────
  // Routes / Navigation (إذا كنت تستخدم named routes أو go_router)
  // ────────────────────────────────────────────────
  static const String routeSplash = '/splash';
  static const String routeLogin = '/login';
  static const String routeSignup = '/signup';
  static const String routeHome = '/home';
  static const String routeNoteDetail = '/note/:id';
  static const String routeProfile = '/profile';

  // ────────────────────────────────────────────────
  // Shared Preferences Keys (إذا كنت تستخدم shared_preferences)
  // ────────────────────────────────────────────────
  static const String prefKeyOnboardingShown = 'onboarding_shown';
  static const String prefKeyThemeMode = 'theme_mode';
  static const String prefKeyLastSync = 'last_sync_timestamp';

  // ────────────────────────────────────────────────
  // Error & Message Strings
  // ────────────────────────────────────────────────
  static const String defaultErrorMessage = 'حدث خطأ غير متوقع، حاول مرة أخرى لاحقًا';
  static const String noInternetMessage = 'لا يوجد اتصال بالإنترنت';
  static const String sessionExpiredMessage = 'انتهت الجلسة، يرجى تسجيل الدخول مجدداً';
  static const String weakPasswordMessage = 'كلمة المرور ضعيفة جدًا، يجب أن تحتوي على 6 أحرف على الأقل';
  static const String emailAlreadyInUse = 'البريد الإلكتروني مستخدم بالفعل';
  static const String noteFieldCategoryColor = 'categoryColor';
}