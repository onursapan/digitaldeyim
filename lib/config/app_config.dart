import '../core/config/env.dart';

class AppConfig {
  static const String appName = 'Digitaldeyim';
  static const String geminiBaseUrl =
      'https://generativelanguage.googleapis.com/v1beta';
  static const String shotstackBaseUrl = 'https://api.shotstack.io';
  static const String klingBaseUrl = 'https://api.klingai.com/v1';

  // API keys — env.dart'tan okunur (gitignored)
  static String get geminiApiKey => Env.geminiApiKey;
  static String get shotstackApiKey => Env.shotstackApiKey;
  static String get shotstackOwnerId => Env.shotstackOwnerId;
  static String get shotstackEnv => Env.shotstackEnv;

  // Validator thresholds
  static const double minLuxLevel = 300.0;
  static const double maxShakeLevel = 0.5;
  static const int maxVideoDurationSeconds = 60;

  // Credit system
  static const int renderCostPerVideo = 1;
  static const int initialCredits = 3;
}
