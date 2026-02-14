// app_constants.dart
// Central place for all application-wide constants
// Rules we follow:
// - All constants are 'static const' (compile-time constants when possible)
// - Group related constants together
// - Use meaningful names (avoid abbreviations when readability suffers)
// - Prefer Duration, Size, EdgeInsets, etc. typed values over raw numbers

import 'package:flutter/material.dart';

class AppConstants {
  // ────────────────────────────────────────────────
  // App Metadata
  // ────────────────────────────────────────────────
  static const String appName = 'MoCodex';
  static const String appVersion = '1.0.0';           // update on each release
  static const String appPackageName = 'com.mocodex.app';
  static const String developerName = 'MoCodex Team';
  static const int yearFounded = 2025;

  // ────────────────────────────────────────────────
  // API / Backend
  // ────────────────────────────────────────────────
  // We usually keep production URL here and use flavors/env for dev/staging
  static const String baseUrlProduction = 'https://api.mocodex.com/v1';
  static const String baseUrlDevelopment = 'http://10.0.2.2:8000/api/v1'; // Android emulator localhost
  static const Duration apiTimeout = Duration(seconds: 30);

  // ────────────────────────────────────────────────
  // UI / Design System Constants
  // ────────────────────────────────────────────────
  // Spacing & Layout
  static const double spacingXs = 4.0;
  static const double spacingSm = 8.0;
  static const double spacingMd = 16.0;
  static const double spacingLg = 24.0;
  static const double spacingXl = 32.0;
  static const double spacingXxl = 48.0;

  // Border radius
  static const double radiusXs = 4.0;
  static const double radiusSm = 8.0;
  static const double radiusMd = 12.0;
  static const double radiusLg = 16.0;
  static const double radiusXl = 24.0;
  static const double radiusPill = 999.0; // for pill-shaped buttons/chips

  // Icon sizes
  static const double iconSizeXs = 16.0;
  static const double iconSizeSm = 20.0;
  static const double iconSizeMd = 24.0;
  static const double iconSizeLg = 32.0;

  // Elevation / Shadows
  static const double elevationLow = 1.0;
  static const double elevationMedium = 4.0;
  static const double elevationHigh = 8.0;

  // Animation durations
  static const Duration animFast = Duration(milliseconds: 200);
  static const Duration animNormal = Duration(milliseconds: 350);
  static const Duration animSlow = Duration(milliseconds: 600);

  // ────────────────────────────────────────────────
  // Typography - Font sizes (use with Theme.of(context).textTheme)
  // ────────────────────────────────────────────────
  static const double fontSizeXs = 10.0;
  static const double fontSizeSm = 12.0;
  static const double fontSizeMd = 14.0;
  static const double fontSizeBase = 16.0;
  static const double fontSizeLg = 18.0;
  static const double fontSizeXl = 24.0;
  static const double fontSizeXxl = 32.0;
  static const double fontSizeHero = 48.0;

  // ────────────────────────────────────────────────
  // Shared Preferences / Storage Keys
  // ────────────────────────────────────────────────
  static const String prefKeyAuthToken = 'auth_token';
  static const String prefKeyUserId = 'user_id';
  static const String prefKeyThemeMode = 'theme_mode';
  static const String prefKeyOnboardingCompleted = 'onboarding_done_v1';
  static const String prefKeyLastSync = 'last_sync_timestamp';

  // ────────────────────────────────────────────────
  // Deep Links / Routes (if using go_router or auto_route)
  // ────────────────────────────────────────────────
  static const String routeHome = '/home';
  static const String routeLogin = '/login';
  static const String routeProfile = '/profile';
  static const String routeSettings = '/settings';

  // ────────────────────────────────────────────────
  // Asset Paths (use only if not using pubspec.yaml aliases)
  // ────────────────────────────────────────────────
  static const String assetsImagesPath = 'assets/images/';
  static const String assetsIconsPath = 'assets/icons/';
  static const String assetsLottiePath = 'assets/lottie/';

  // ────────────────────────────────────────────────
  // Helper getters (convenience)
  // ────────────────────────────────────────────────
  static EdgeInsets get defaultPadding => const EdgeInsets.all(spacingMd);
  static EdgeInsets get pagePadding => const EdgeInsets.symmetric(
    horizontal: spacingLg,
    vertical: spacingXl,
  );

  static BorderRadius get defaultBorderRadius => BorderRadius.circular(radiusMd);
  static BorderRadius get cardBorderRadius => BorderRadius.circular(radiusLg);
}
// Category Colors (hex strings or Color)
const Map<String, Color> categoryColors = {
  'Work': Color(0xFF2196F3),      // Blue
  'Personal': Color(0xFF4CAF50),  // Green
  'Ideas': Color(0xFF9C27B0),     // Purple
  'Books': Color(0xFFFF9800),     // Orange
  'Other': Color(0xFF607D8B),     // Grey
};