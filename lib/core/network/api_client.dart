import 'package:dio/dio.dart';
import '../utils/logger.dart';

class ApiClient {
  static Dio create({
    required String baseUrl,
    required String apiKey,
    String apiKeyHeader = 'Authorization',
    String apiKeyPrefix = 'Bearer',
  }) {
    final dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 60),
        headers: {
          'Content-Type': 'application/json',
          apiKeyHeader: '$apiKeyPrefix $apiKey',
        },
      ),
    );

    dio.interceptors.add(_LoggingInterceptor());
    dio.interceptors.add(_RetryInterceptor(dio));

    return dio;
  }
}

class _LoggingInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    appLogger.d('[API] ${options.method} ${options.path}');
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    appLogger.e('[API] Error: ${err.message}', error: err);
    handler.next(err);
  }
}

class _RetryInterceptor extends Interceptor {
  final Dio dio;
  _RetryInterceptor(this.dio);

  @override
  Future<void> onError(
      DioException err, ErrorInterceptorHandler handler) async {
    final options = err.requestOptions;
    final retryCount = options.extra['retryCount'] ?? 0;

    if (retryCount < 2 &&
        err.type == DioExceptionType.connectionTimeout) {
      options.extra['retryCount'] = retryCount + 1;
      appLogger.w('[API] Retrying request (${retryCount + 1}/2)...');
      try {
        final response = await dio.fetch(options);
        handler.resolve(response);
        return;
      } catch (_) {}
    }
    handler.next(err);
  }
}
