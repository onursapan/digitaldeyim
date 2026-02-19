import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/core_providers.dart';
import '../../../domain/entities/sector.dart';
import '../../../domain/entities/user_profile.dart';

class OnboardingState {
  final int currentStep;
  final String? selectedSectorId;
  final List<Sector> availableSectors;
  final bool isLoadingSectors;
  // B4: Sektör yüklenemediğinde hata göstermek için flag.
  final bool hasSectorLoadError;
  final String? businessName;
  final List<String> topProducts;
  final BusinessVibe? vibe;
  final TargetAudience? audience;
  final bool isAnalyzingVoice;
  final String? brandToneAnalysis;

  const OnboardingState({
    this.currentStep = 0,
    this.selectedSectorId,
    this.availableSectors = const [],
    this.isLoadingSectors = false,
    this.hasSectorLoadError = false,
    this.businessName,
    this.topProducts = const [],
    this.vibe,
    this.audience,
    this.isAnalyzingVoice = false,
    this.brandToneAnalysis,
  });

  bool get canProceedToDirector =>
      selectedSectorId != null &&
      businessName != null &&
      businessName!.isNotEmpty &&
      topProducts.isNotEmpty &&
      vibe != null &&
      audience != null;

  OnboardingState copyWith({
    int? currentStep,
    String? selectedSectorId,
    List<Sector>? availableSectors,
    bool? isLoadingSectors,
    bool? hasSectorLoadError,
    String? businessName,
    List<String>? topProducts,
    BusinessVibe? vibe,
    TargetAudience? audience,
    bool? isAnalyzingVoice,
    String? brandToneAnalysis,
  }) {
    return OnboardingState(
      currentStep: currentStep ?? this.currentStep,
      selectedSectorId: selectedSectorId ?? this.selectedSectorId,
      availableSectors: availableSectors ?? this.availableSectors,
      isLoadingSectors: isLoadingSectors ?? this.isLoadingSectors,
      hasSectorLoadError: hasSectorLoadError ?? this.hasSectorLoadError,
      businessName: businessName ?? this.businessName,
      topProducts: topProducts ?? this.topProducts,
      vibe: vibe ?? this.vibe,
      audience: audience ?? this.audience,
      isAnalyzingVoice: isAnalyzingVoice ?? this.isAnalyzingVoice,
      brandToneAnalysis: brandToneAnalysis ?? this.brandToneAnalysis,
    );
  }
}

class OnboardingNotifier extends StateNotifier<OnboardingState> {
  final Ref _ref;

  OnboardingNotifier(this._ref) : super(const OnboardingState()) {
    _loadSectors();
  }

  Future<void> _loadSectors() async {
    state = state.copyWith(isLoadingSectors: true, hasSectorLoadError: false);
    try {
      final sectors =
          await _ref.read(sectorDatasourceProvider).loadAllSectors();
      if (sectors.isEmpty) {
        // JSON parse başarılı ama boş liste: hata olarak işle.
        state = state.copyWith(
          isLoadingSectors: false,
          hasSectorLoadError: true,
        );
      } else {
        state = state.copyWith(
          availableSectors: sectors,
          isLoadingSectors: false,
        );
      }
    } catch (_) {
      // B4: Asset yükleme veya parse hatası → retry butonu göster.
      state = state.copyWith(
        isLoadingSectors: false,
        hasSectorLoadError: true,
      );
    }
  }

  /// B4: Retry butonu için public metod.
  Future<void> retryLoadSectors() => _loadSectors();

  void selectSector(String sectorId) {
    state = state.copyWith(selectedSectorId: sectorId, currentStep: 1);
  }

  void setBusinessName(String name) =>
      state = state.copyWith(businessName: name);

  void addProduct(String product) {
    if (state.topProducts.length < 3 && product.isNotEmpty) {
      state = state.copyWith(topProducts: [...state.topProducts, product]);
    }
  }

  void removeProduct(String product) {
    state = state.copyWith(
      topProducts: state.topProducts.where((p) => p != product).toList(),
    );
  }

  void setVibe(BusinessVibe vibe) => state = state.copyWith(vibe: vibe);
  void setAudience(TargetAudience audience) =>
      state = state.copyWith(audience: audience);

  void nextStep() => state = state.copyWith(currentStep: state.currentStep + 1);
  void prevStep() {
    if (state.currentStep > 0) {
      state = state.copyWith(currentStep: state.currentStep - 1);
    }
  }

  Future<void> analyzeVoiceRecording(String audioPath) async {
    state = state.copyWith(isAnalyzingVoice: true);

    // Gemini'ye gönderilecek transkript metni.
    // Phase 2: Gerçek ses dosyası → Gemini Audio API ile transkripsiyon yapılacak.
    // Phase 1: Onboarding verilerinden sentetik metin oluşturuluyor.
    final syntheticText =
        'Merhaba, ben ${state.businessName ?? "esnaf"}, '
        '${state.selectedSectorId ?? "sektör"} alanında hizmet veriyorum. '
        'En çok satan ürünlerim: ${state.topProducts.join(", ")}.';

    final geminiService = _ref.read(geminiServiceProvider);
    final analysis = await geminiService.analyzeBrandTone(
      transcribedText: syntheticText,
      sectorName: state.selectedSectorId ?? '',
    );

    state = state.copyWith(
      isAnalyzingVoice: false,
      brandToneAnalysis: analysis,
      currentStep: state.currentStep + 1,
    );
  }
}

final onboardingProvider =
    StateNotifierProvider<OnboardingNotifier, OnboardingState>(
  (ref) => OnboardingNotifier(ref),
);
