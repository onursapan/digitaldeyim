import 'package:logger/logger.dart';

final appLogger = Logger(
  printer: PrettyPrinter(
    methodCount: 2,
    errorMethodCount: 8,
    lineLength: 120,
    colors: true,
    printEmojis: true,
  ),
);

extension LoggerExtension on Object {
  void log(String message) => appLogger.d('[$runtimeType] $message');
  void logError(String message, [dynamic error]) =>
      appLogger.e('[$runtimeType] $message', error: error);
  void logWarning(String message) => appLogger.w('[$runtimeType] $message');
}
