import '../../domain/entities/shoot_session.dart';
import '../../domain/entities/user_profile.dart';
import '../utils/logger.dart';
import 'base_agent.dart';

class PrompterInput {
  final UserProfile userProfile;
  final ShootSession session;

  const PrompterInput({required this.userProfile, required this.session});
}

class PrompterOutput {
  final String geminiPrompt;       // Gemini'ye gidecek ham prompt
  final Map<String, dynamic> shotstackJson; // Shotstack render talimatları

  const PrompterOutput({
    required this.geminiPrompt,
    required this.shotstackJson,
  });
}

/// Prompter Agent — ham esnaf verisini AI modellerinin
/// anlayacağı teknik prompt setlerine çevirir.
class PrompterAgent extends BaseAgent<PrompterInput, PrompterOutput> {
  @override
  String get agentName => 'PrompterAgent';

  @override
  Future<PrompterOutput> process(PrompterInput input) async {
    emitProcessing();
    log('Building prompts for sector: ${input.session.sector.name}');

    final geminiPrompt = _buildGeminiPrompt(input);
    final shotstackJson = _buildShotstackJson(input);

    final output = PrompterOutput(
      geminiPrompt: geminiPrompt,
      shotstackJson: shotstackJson,
    );

    emitSuccess();
    log('Prompt built. Shotstack clips: ${input.session.clips.length}');
    return output;
  }

  String _buildGeminiPrompt(PrompterInput input) {
    final profile = input.userProfile;
    final sector = input.session.sector;

    return '''
Sen bir profesyonel sosyal medya içerik uzmanısın.

İşletme Bilgileri:
- İsim: ${profile.businessName}
- Sektör: ${sector.name}
- En çok satan ürünler: ${profile.topProducts.join(', ')}
- Mağaza karakteri: ${profile.vibe.label}
- Hedef kitle: ${profile.audience.label}
${profile.brandToneAnalysis != null ? '- Marka tonu analizi: ${profile.brandToneAnalysis}' : ''}

Görsel stil: ${sector.visualStyle.fontStyle}, ${sector.visualStyle.musicMood} müzik
Çekim sayısı: ${input.session.clips.length} klip

Görev: Bu içerik için Instagram Reels açıklaması yaz.
- Türkçe olsun
- 3-5 hashtag ekle (sektöre ve trende özel)
- İlk cümle hook olsun — okuyucuyu durduracak
- Emoji kullan ama abartma
- Max 150 kelime

Sadece açıklama metnini döndür, başka bir şey ekleme.
''';
  }

  Map<String, dynamic> _buildShotstackJson(PrompterInput input) {
    final style = input.session.sector.visualStyle;
    final clips = input.session.clips;

    // Shotstack timeline JSON yapısı
    return {
      'timeline': {
        'background': '#000000',
        'tracks': [
          {
            'clips': clips.asMap().entries.map((entry) {
              final index = entry.key;
              final clip = entry.value;
              final startTime = index * style.cutRhythm;

              return {
                'asset': {
                  'type': 'video',
                  'src': clip.localPath, // Faz 2'de cloud URL olacak
                  'trim': 0,
                  'volume': 0,
                },
                'start': startTime,
                'length': style.cutRhythm,
                'transition': {
                  'in': 'fade',
                  'out': 'fade',
                },
                'effect': _getEffectForStep(index),
              };
            }).toList(),
          },
          {
            'clips': [
              {
                'asset': {
                  'type': 'title',
                  'text': input.userProfile.businessName,
                  'style': style.fontStyle,
                  'color': style.accentColorHex,
                  'size': 'medium',
                },
                'start': 0,
                'length': 3.0,
                'position': 'bottomLeft',
              },
            ],
          },
        ],
      },
      'output': {
        'format': 'mp4',
        'resolution': 'hd',
        'aspectRatio': '9:16',
        'fps': 30,
      },
    };
  }

  String _getEffectForStep(int index) {
    const effects = ['zoomIn', 'slideLeft', 'zoomOut'];
    return effects[index % effects.length];
  }
}
