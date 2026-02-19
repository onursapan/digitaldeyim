import 'package:dio/dio.dart';
import '../../config/app_config.dart';
import '../../core/network/api_client.dart';
import '../../core/utils/logger.dart';
import '../../domain/entities/sector.dart';
import '../../domain/entities/user_profile.dart';

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

  // ─── Public API ────────────────────────────────────────────────────────────

  /// Onboarding ses transkripsiyonundan marka tonu analizi üretir.
  Future<String> analyzeBrandTone({
    required String transcribedText,
    required String sectorName,
  }) async {
    final prompt = '''
Sen bir marka stratejisti ve pazarlama uzmanısın.
Aşağıdaki metin bir KOBİ sahibinin kendi işletmesini 15 saniyede anlattığı ses kaydının transkripsiyonudur.

Metin: "$transcribedText"
Sektör: $sectorName

Marka tonunu kısa ve net şekilde analiz et (maksimum 3 cümle):
- Konuşma enerjisi (sakin / heyecanlı / profesyonel / samimi)
- İletişim tarzı (resmi / samimi / teknik / sıcak)
- Öne çıkan değer vurgusu (kalite / fiyat / müşteri ilişkisi / uzmanlık)

Sadece özeti döndür, başlık veya madde işareti kullanma.
''';
    return _generate(prompt: prompt, fallback: 'Samimi ve müşteri odaklı bir işletme tonu.');
  }

  /// Director çekimi tamamlandıktan sonra sosyal medya caption'ı üretir.
  Future<String> generateCaption(String shotstackPrompt) async {
    return _generate(
      prompt: shotstackPrompt,
      fallback: _fallbackCaption(),
    );
  }

  /// Esnaf profili + çekim oturumundan Shotstack render için prompt üretir.
  Future<String> generateShotstackPrompt({
    required UserProfile profile,
    required Sector sector,
    required List<String> clipPaths,
  }) async {
    final prompt = '''
Sen bir sosyal medya içerik uzmanısın. Aşağıdaki bilgilere göre Türkçe bir video caption ve hashtag seti oluştur.

İşletme: ${profile.businessName}
Sektör: ${sector.name}
Öne çıkan ürünler: ${profile.topProducts.join(', ')}
Marka tonu: ${profile.brandToneAnalysis ?? 'Samimi ve güvenilir'}
Hedef kitle: ${profile.audience.label}
İşletme vibe'ı: ${profile.vibe.label}

Video klip sayısı: ${clipPaths.length}

Lütfen şunları üret:
1. Ana caption (maksimum 2 cümle, etkileyici ve doğal)
2. 5-7 alakalı hashtag (Türkçe ve İngilizce karışık)
3. Çağrı yapma ifadesi (call-to-action, tek cümle)

Format:
CAPTION: [caption metni]
HASHTAGS: [hashtag'ler]
CTA: [çağrı ifadesi]
''';
    return _generate(prompt: prompt, fallback: _fallbackCaption());
  }

  /// Kamera öncesi checklist için AI destekli öneri üretir.
  Future<String> generateShootingTip({
    required String sectorName,
    required String stepTitle,
  }) async {
    final prompt = '''
Sen bir profesyonel kamera yönetmenisin.
Sektör: $sectorName
Çekim adımı: $stepTitle

Bu çekim adımı için 1 cümlelik pratik ipucu ver. Kısa ve uygulanabilir olsun.
''';
    return _generate(
      prompt: prompt,
      fallback: 'Kamerayı sabit tut ve ışığın önden geldiğinden emin ol.',
    );
  }

  // ─── Private ───────────────────────────────────────────────────────────────

  Future<String> _generate({
    required String prompt,
    required String fallback,
    double temperature = 0.8,
    int maxTokens = 500,
  }) async {
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
            'temperature': temperature,
            'maxOutputTokens': maxTokens,
          },
          'safetySettings': [
            {
              'category': 'HARM_CATEGORY_HARASSMENT',
              'threshold': 'BLOCK_NONE',
            },
            {
              'category': 'HARM_CATEGORY_HATE_SPEECH',
              'threshold': 'BLOCK_NONE',
            },
          ],
        },
      );

      final candidates = response.data['candidates'] as List?;
      if (candidates == null || candidates.isEmpty) return fallback;

      final text = candidates[0]['content']['parts'][0]['text'] as String?;
      if (text == null || text.trim().isEmpty) return fallback;

      appLogger.d('[GeminiService] Response: ${text.substring(0, text.length.clamp(0, 80))}...');
      return text.trim();
    } on DioException catch (e) {
      appLogger.e('[GeminiService] DioException: ${e.response?.statusCode} — ${e.message}');
      return fallback;
    } catch (e) {
      appLogger.e('[GeminiService] Unexpected error: $e');
      return fallback;
    }
  }

  String _fallbackCaption() =>
      'CAPTION: Kaliteli ürünlerimizi keşfedin!\nHASTAGS: #yerel #kalite #güvenilir #türkiye #esnaf\nCTA: Hemen ziyaret edin!';
}
