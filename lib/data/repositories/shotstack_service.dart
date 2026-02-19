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
    _dio = ApiClient.create(
      baseUrl: AppConfig.shotstackBaseUrl,
      apiKey: AppConfig.shotstackApiKey,
    );
  }

  /// Render işini kuyruğa alır, jobId döner.
  Future<String> submitRender(Map<String, dynamic> timeline) async {
    try {
      final response = await _dio.post('/render', data: timeline);
      final jobId = response.data['response']['id'] as String;
      appLogger.d('[Shotstack] Job submitted: $jobId');
      return jobId;
    } on DioException catch (e) {
      appLogger.e('[Shotstack] Submit error', error: e);
      // Faz 1: API yoksa simüle et
      return 'local_sim_${DateTime.now().millisecondsSinceEpoch}';
    }
  }

  /// Job durumunu sorgular (polling için kullanılır)
  Future<RenderJob> checkStatus(String jobId) async {
    // Faz 1 local simulation: 3 saniye sonra "done" döndür
    if (jobId.startsWith('local_sim_')) {
      await Future.delayed(const Duration(seconds: 3));
      return RenderJob(
        jobId: jobId,
        status: RenderStatus.done,
        videoUrl: 'local://draft_preview.mp4',
      );
    }

    try {
      final response = await _dio.get('/render/$jobId');
      final data = response.data['response'];
      final statusStr = data['status'] as String;

      return RenderJob(
        jobId: jobId,
        status: _parseStatus(statusStr),
        videoUrl: data['url'] as String?,
      );
    } on DioException catch (e) {
      appLogger.e('[Shotstack] Status check error', error: e);
      return RenderJob(
        jobId: jobId,
        status: RenderStatus.failed,
        errorMessage: 'Durum sorgulanamadı.',
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
