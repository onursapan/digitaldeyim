class AppConfig {
  static const String appName = 'Digitaldeyim';
  static const String geminiBaseUrl = 'https://generativelanguage.googleapis.com/v1beta';
  static const String shotstackBaseUrl = 'https://api.shotstack.io/v1';
  static const String klingBaseUrl = 'https://api.klingai.com/v1';

  // Faz 1: Local simulation — API key'ler env'den gelecek
  static const String geminiApiKey = String.fromEnvironment('GEMINI_API_KEY');
  static const String shotstackApiKey = String.fromEnvironment('SHOTSTACK_API_KEY');
  static const String klingApiKey = String.fromEnvironment('KLING_API_KEY');

  // Validator thresholds
  static const double minLuxLevel = 300.0;
  static const double maxShakeLevel = 0.5;
  static const int maxVideoDurationSeconds = 60;

  // Credit system
  static const int renderCostPerVideo = 1;
  static const int initialCredits = 3;
}
