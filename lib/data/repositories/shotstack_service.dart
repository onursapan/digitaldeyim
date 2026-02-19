import 'package:dio/dio.dart';
import '../../config/app_config.dart';
import '../../core/network/api_client.dart';
import '../../core/utils/logger.dart';

enum RenderStatus { queued, fetching, rendering, done, failed }

class RenderJob {
  final String jobId;
  final RenderStatus status;
  final String? videoUrl;
  final String? errorMessage;

  const RenderJob({
    required this.jobId,
    required this.status,
    this.videoUrl,
    this.errorMessage,
  });
}

class ShotstackService {
  late final Dio _dio;

  ShotstackService() {
    // Shotstack API: x-api-key header (Authorization: Bearer değil)
    _dio = ApiClient.create(
      baseUrl: AppConfig.shotstackBaseUrl,
      apiKey: AppConfig.shotstackApiKey,
      apiKeyHeader: 'x-api-key',
      apiKeyPrefix: '',
    );
  }

  /// Render işini kuyruğa alır; başarıda jobId, hata halinde null döner.
  /// Endpoint: POST /v1/render (sandbox env)
  Future<String?> submitRender(Map<String, dynamic> timeline) async {
    try {
      final env = AppConfig.shotstackEnv; // 'stage' veya 'v1'
      final response = await _dio.post('/$env/render', data: timeline);
      final id = response.data?['response']?['id'] as String?;
      if (id == null) {
        appLogger.e('[Shotstack] Missing id in response: ${response.data}');
        return null;
      }
      appLogger.d('[Shotstack] Job submitted: $id');
      return id;
    } on DioException catch (e) {
      appLogger.e(
        '[Shotstack] Submit error: ${e.response?.statusCode} — ${e.response?.data}',
        error: e,
      );
      return null;
    }
  }

  /// Job durumunu sorgular.
  /// Endpoint: GET /v1/render/{id}
  Future<RenderJob> checkStatus(String jobId) async {
    // Local simülasyon (gerçek API key yokken Phase 1 fallback)
    if (jobId.startsWith('local_sim_')) {
      await Future.delayed(const Duration(seconds: 3));
      return RenderJob(
        jobId: jobId,
        status: RenderStatus.done,
        videoUrl: 'local://draft_preview.mp4',
      );
    }

    try {
      final env = AppConfig.shotstackEnv;
      final response = await _dio.get('/$env/render/$jobId');
      final data = response.data?['response'] as Map<String, dynamic>?;

      if (data == null) {
        return RenderJob(
          jobId: jobId,
          status: RenderStatus.failed,
          errorMessage: 'Geçersiz API yanıtı.',
        );
      }

      final statusStr = data['status'] as String? ?? 'failed';
      final url = data['url'] as String?;

      appLogger.d('[Shotstack] Status for $jobId: $statusStr  url=$url');

      return RenderJob(
        jobId: jobId,
        status: _parseStatus(statusStr),
        videoUrl: url,
      );
    } on DioException catch (e) {
      appLogger.e('[Shotstack] Status check error', error: e);
      return RenderJob(
        jobId: jobId,
        status: RenderStatus.failed,
        errorMessage: 'Durum sorgulanamadı: ${e.message}',
      );
    }
  }

  RenderStatus _parseStatus(String status) {
    return switch (status) {
      'queued' => RenderStatus.queued,
      'fetching' => RenderStatus.fetching,
      'rendering' => RenderStatus.rendering,
      'done' => RenderStatus.done,
      _ => RenderStatus.failed,
    };
  }
}
