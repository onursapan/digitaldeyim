# Digitaldeyim

**AI destekli KOBİ içerik üretim platformu** — Yerel esnafların profesyonel Instagram Reels üretmesini sağlayan Flutter tabanlı mobil uygulama.

---

## Vizyon

> "Sıradan bir esnaf çekimini, Kling 2.5 ve Google Veo kalitesinde viral bir sanat eserine dönüştür."

Kullanıcı yolculuğu:
1. **Giriş (Identity):** Meslek/sektör seçimi + işletme bilgileri
2. **Digital DNA:** Ses kaydı → AI marka tonu analizi
3. **Director Mode:** Validator Agent eşliğinde 3 kliplik çekim paketi
4. **Draft Studio:** Taslak izleme ve onay
5. **AI Mutfak:** Kling 2.5 / Veo / Shotstack ile 4K çıktı
6. **Dağıtım:** IG, FB, X otomatik paylaşım

---

## Mimari

```
Clean Architecture + Riverpod + GoRouter + Multi-Agent System
```

```
lib/
├── config/
│   ├── app_config.dart          # API key'ler, eşik değerleri, kredi sistemi
│   └── app_router.dart          # GoRouter (5 ekran + route guard)
├── core/
│   ├── agents/
│   │   ├── base_agent.dart      # Generic abstract agent (stream state machine)
│   │   ├── orchestrator.dart    # Event bus + agent-to-agent chain()
│   │   ├── prompter_agent.dart  # Gemini prompt + Shotstack JSON üretimi
│   │   └── validator_agent.dart # Isolate tabanlı video kalite analizi
│   ├── network/
│   │   └── api_client.dart      # Dio factory (logging + retry interceptors)
│   ├── providers/
│   │   ├── core_providers.dart  # Servis + agent Riverpod provider'ları
│   │   └── user_profile_provider.dart  # Mutable UserProfile + kredi yönetimi
│   ├── theme/
│   │   └── app_theme.dart       # Dark tema, gold (#C9A96E) accent
│   └── utils/                   # Logger, Either extensions
├── data/
│   ├── datasources/
│   │   └── sector_local_datasource.dart  # JSON sektör konfigürasyonu
│   └── repositories/
│       ├── gemini_service.dart   # Gemini 2.0 Flash (caption + brand tone)
│       └── shotstack_service.dart # Video render + polling
├── domain/entities/
│   ├── sector.dart               # Sector, ShootStep, CameraChecklist, VisualStyle
│   ├── shoot_session.dart        # ShootSession, ShootClip, ValidationResult
│   └── user_profile.dart         # UserProfile, BusinessVibe, TargetAudience
└── presentation/
    ├── onboarding/               # Sector seçimi → İşletme bilgisi → Ses kaydı
    ├── director/                 # Kamera yönetmen modu
    ├── studio/                   # Taslak + render ekranı
    └── shared/widgets/           # CreditBadge, StepProgressBar, ErrorStateView
```

---

## FAZ 1 — Simülasyon Modu (Mevcut)

Tüm temel akış uçtan uca çalışır. Gerçek donanım yerine simülasyon kullanılır:

| Bileşen | FAZ 1 (Simülasyon) | FAZ 2 (Gerçek) |
|---------|-------------------|----------------|
| Kamera önizleme | `_SimulatedCameraView` (statik) | `CameraPreview` (`camera` paketi) |
| Video kaydı | `local://simulated_clip.mp4` hardcoded | `CameraController.stopVideoRecording()` |
| Ses kaydı | UI simülasyonu | `record` paketi + gerçek .m4a dosyası |
| Ses analizi | Onboarding form verisinden metin | Gemini Audio API transkripsiyonu |
| Video validasyonu | Isolate stub (her zaman geçer) | ML Kit / MediaPipe kalite analizi |
| Live lux/shake | `processLiveFrame()` var, çağrılmıyor | `CameraController.imageStream` callback |
| Render | `local_sim_` Shotstack fallback | Gerçek Shotstack API key |
| Draft önizleme | Statik play icon | `VideoPlayer` + FFmpeg local render |
| Auth | `user_001` hardcoded | Firebase Auth UID |
| Profil | Onboarding state'den inşa | Firestore `users/{uid}` |
| Share/Galeri | Stub butonlar | `share_plus` + `image_picker` |

---

## FAZ 2 Yol Haritası

### 2A — Gerçek Kamera ve Ses
- [ ] `camera` paketi ile `CameraController` entegrasyonu
- [ ] `record` paketi ile gerçek ses kaydı (.m4a)
- [ ] Gemini Audio API ile ses transkripsiyonu (brand tone analizi)
- [ ] `ValidatorAgent._simulateValidation` → ML Kit video kalite analizi (isolate'de)
- [ ] `processLiveFrame()` → `CameraController.imageStream` ile lux/shake ölçümü
- [ ] `ShootStep.durationSeconds` → kayıt süre sınırı (otomatik durdurma)
- [ ] `CameraMotion` enum → görsel hareket rehberi (ghost overlay animasyonu)

### 2B — Gerçek Render Pipeline
- [ ] Firebase Storage'a klip yükleme (Shotstack public URL gerektirir)
- [ ] Shotstack gerçek API key ile render (`--dart-define=SHOTSTACK_API_KEY=...`)
- [ ] `SectorVisualStyle.shotstackTemplateIds` kullanımı (PrompterAgent'a ekle)
- [ ] Local FFmpeg önizleme (`ffmpeg_kit_flutter`)
- [ ] `VideoPlayer` widget ile draft önizleme

### 2C — Auth ve Profil
- [ ] Firebase Auth (Google/Apple SSO veya OTP)
- [ ] Firestore `users/{uid}` koleksiyonu
- [ ] `UserProfile.fromJson` / `toJson` implementasyonu
- [ ] Kredi yönetimi backend tarafında (Firestore transaction)
- [ ] `UserProfile.copyWith` tüm alanlar için genişletme

### 2D — Paylaşım ve Dağıtım
- [ ] `share_plus` ile Instagram caption + video paylaşımı
- [ ] `image_picker` (GallerySaver) ile galeriye kayıt
- [ ] Ayrshare API ile çoklu platform dağıtım (IG, FB, X)
- [ ] Google Business Profile API ile Google Yorum yönetimi

### 2E — AI Yükseltme (Kling / Veo)
- [ ] `KlingService` — Kling 2.5 API entegrasyonu (`AppConfig.klingBaseUrl` hazır)
- [ ] `VeoService` — Google Veo 3.1 API entegrasyonu
- [ ] `--dart-define=KLING_API_KEY=...` aktif etme
- [ ] `PrompterAgent._buildShotstackJson` → Kling timeline JSON üretimine geçiş

### 2F — Viral Radar (Stratejik Zeka)
- [ ] Instagram / TikTok Trends API entegrasyonu
- [ ] Rakip profil analizi modülü
- [ ] Milli gün / dini gün / özel gün takvimi farkındalığı
- [ ] Haftalık dinamik briefing (FAZ 1'de `ShootStep`'ler sabit şablon)
- [ ] `DirectorAgent`: trend bazlı şablon seçimi

---

## Sektör Konfigürasyonu

Yeni sektör eklemek için iki adım:

**1.** `assets/sector_configs/` altına JSON dosyası ekle:

```json
{
  "id": "sektör_id",
  "name": "Sektör Adı",
  "emoji": "🏪",
  "directorBrief": {
    "hook":   { "id": "...", "title": "...", "instruction": "...", "overlayHint": "...", "durationSeconds": 5, "motion": "zoomPunch" },
    "detail": { "id": "...", "title": "...", "instruction": "...", "overlayHint": "...", "durationSeconds": 4, "motion": "still" },
    "exit":   { "id": "...", "title": "...", "instruction": "...", "overlayHint": "...", "durationSeconds": 6, "motion": "still" },
    "checklist": { "minLux": 300.0, "maxShake": 0.5, "lightingTip": "...", "backgroundTip": "..." }
  },
  "visualStyle": {
    "primaryColorHex": "#FF6B35",
    "accentColorHex": "#FFFFFF",
    "fontStyle": "bold",
    "musicMood": "upbeat",
    "cutRhythm": 2.5,
    "shotstackTemplateIds": ["sektör_v1"]
  }
}
```

**2.** `lib/data/datasources/sector_local_datasource.dart` içindeki listeye ekle:

```dart
static const _availableSectors = ['gelinlik', 'market', 'sektör_id'];
```

Mevcut `CameraMotion` değerleri: `still`, `slowUp`, `zoomIn`, `zoomPunch`, `halfCircle`, `slideRight`

---

## Kurulum

```bash
# Bağımlılıkları yükle
flutter pub get

# Simülasyon modu (API key gerekmez)
flutter run

# Gerçek API'larla çalıştır
flutter run \
  --dart-define=GEMINI_API_KEY=xxx \
  --dart-define=SHOTSTACK_API_KEY=xxx \
  --dart-define=KLING_API_KEY=xxx
```

## Teknoloji Yığını

| Katman | Tercih | Alternatif |
|--------|--------|------------|
| Mobil Framework | Flutter | React Native |
| AI Beyin (LLM) | Gemini 2.0 Flash | GPT-4o |
| Video Üretimi | Kling 2.5 | Runway Gen-3 |
| Gerçekçi Video | Google Veo 3.1 | Sora |
| Kurgu Motoru | Shotstack | Creatomate |
| Görüntü İşleme | ML Kit / MediaPipe | CoreML |
| Çoklu Paylaşım | Ayrshare | Buffer API |
| State Management | Riverpod | Bloc |
| Navigation | GoRouter | Auto Route |
