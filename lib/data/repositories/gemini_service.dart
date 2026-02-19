import 'package:dio/dio.dart';
import '../../config/app_config.dart';
import '../../core/network/api_client.dart';
import '../../core/utils/logger.dart';

class GeminiService {
  late final Dio _dio;

  GeminiService() {
    _dio = ApiClient.create(
      baseUrl: AppConfig.geminiBaseUrl,
      apiKey: AppConfig.geminiApiKey,
      apiKeyHeader: 'x-goog-api-key',
      apiKeyPrefix: '',
    );
  }

  /// Esnafın ham verisini alıp Shotstack için kurgu talimatı üretir.
  Future<String> generateCaption(String prompt) async {
    try {
      final response = await _dio.post(
        '/models/gemini-2.0-flash:generateContent',
        data: {
          'contents': [
            {
              'parts': [
                {'text': prompt}
              ]
            }
          ],
          'generationConfig': {
            'temperature': 0.8,
            'maxOutputTokens': 300,
          },
        },
      );

      final text = response.data['candidates'][0]['content']['parts'][0]['text']
          as String;
      appLogger.d('[GeminiService] Caption generated: ${text.substring(0, 50)}...');
      return text;
    } on DioException catch (e) {
      appLogger.e('[GeminiService] Error', error: e);
      // Faz 1 fallback: API yoksa default caption döndür
      return _fallbackCaption();
    }
  }

  /// Ses kaydından marka tonu analizi
  Future<String> analyzeBrandTone(String transcribedText, String sector) async {
    try {
      final prompt = '''
Aşağıdaki metni analiz et. Bu metin bir esnafın dükkanını 15 saniyede anlattığı ses kaydının transkripsiyonudur.

Metin: "$transcribedText"
Sektör: $sector

Marka tonunu 2-3 cümleyle özetle:
- Ses tonunun enerjisi (sakin/heyecanlı/profesyonel)
- İletişim tarzı (resmi/samimi/teknik)
- Öne çıkan değer (kalite/fiyat/müşteri ilişkisi)

Sadece özeti döndür.
''';

      return await generateCaption(prompt);
    } catch (_) {
      return 'Samimi ve müşteri odaklı bir işletme tonu.';
    }
  }

  String _fallbackCaption() =>
      'Kaliteli ürünlerimizi keşfedin! ✨\n\n#yerel #kalite #güvenilir';
}
