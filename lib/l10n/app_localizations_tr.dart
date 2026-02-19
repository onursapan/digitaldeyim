// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Turkish (`tr`).
class AppLocalizationsTr extends AppLocalizations {
  AppLocalizationsTr([String locale = 'tr']) : super(locale);

  @override
  String get appName => 'digitaldeyim';

  @override
  String get loginSubtitle =>
      'KOBİ\'ler için AI destekli\nprofesyonel içerik üretimi';

  @override
  String get loginError => 'Giriş yapılamadı. Lütfen tekrar deneyin.';

  @override
  String get googleSignInButton => 'Google ile devam et';

  @override
  String get loginTermsNotice =>
      'Devam ederek Kullanım Koşullarını ve\nGizlilik Politikasını kabul etmiş olursunuz.';

  @override
  String get sectorGreeting => 'Merhaba!';

  @override
  String get sectorTitle => 'Ne satıyorsun?';

  @override
  String get sectorSubtitle => 'Sektörüne özel AI yönetmen seni bekliyor.';

  @override
  String get sectorLoadError => 'Sektörler yüklenemedi';

  @override
  String get sectorLoadErrorRetryHint => 'Lütfen tekrar deneyin.';

  @override
  String get sectorRetryButton => 'Tekrar Dene';

  @override
  String get sectorContinueButton => 'Devam Et';

  @override
  String get businessInfoAppBarTitle => 'İşletmeni Tanı';

  @override
  String get stepSector => 'Sektör';

  @override
  String get stepInfo => 'Bilgiler';

  @override
  String get stepVoice => 'Ses';

  @override
  String get stepReady => 'Hazır';

  @override
  String get businessNameLabel => 'İşletme Adın';

  @override
  String get businessNameHint => 'Örn: Ayşe Gelinlik Evi';

  @override
  String get topProductsLabel => 'En Çok Satan 3 Ürün';

  @override
  String get productNameHint => 'Ürün adı yaz';

  @override
  String get vibeLabel => 'Dükkanın Karakteri';

  @override
  String get audienceLabel => 'Müşterilerin Kimler?';

  @override
  String get businessInfoNextButton => 'Sonraki Adım';

  @override
  String get vibeLuxury => 'Lüks & Sofistike';

  @override
  String get vibeFriendly => 'Samimi & Sıcak';

  @override
  String get vibeTech => 'Teknolojik & Modern';

  @override
  String get vibeTraditional => 'Geleneksel & Güvenilir';

  @override
  String get audienceYouth => 'Gençler (18-30)';

  @override
  String get audienceFamilies => 'Aileler';

  @override
  String get audienceProfessionals => 'Profesyoneller';

  @override
  String get audienceMixed => 'Karma';

  @override
  String get voiceAppBarTitle => 'Marka Sesini Kaydet';

  @override
  String get voicePromptTitle => '15 saniyede dükkanını anlat';

  @override
  String get voicePromptBody =>
      'AI, konuşma tonundan markanın karakterini ve enerjisini analiz edecek. Doğal konuş, performans yapma.';

  @override
  String get voiceStatusRecording => 'Kayıt yapılıyor...';

  @override
  String get voiceStatusDone => 'Kayıt tamamlandı';

  @override
  String get voiceStatusIdle => 'Mikrofona bas ve konuş';

  @override
  String get voiceAnalyzingLabel => 'AI markanı analiz ediyor...';

  @override
  String get voiceAnalyzeButton => 'Analiz Et ve Başla';

  @override
  String get voiceSkipButton => 'Şimdilik atla';

  @override
  String voiceMicError(String error) {
    return 'Mikrofon başlatılamadı: $error';
  }

  @override
  String get voiceDefaultBusinessName => 'İşletmem';

  @override
  String get cameraReadyLabel => 'Kamera Hazır';

  @override
  String get recordingIndicator => '● REC';

  @override
  String get validationLightLabel => 'Işık';

  @override
  String get validationStabilityLabel => 'Sabit';

  @override
  String get goToStudioButton => 'Stüdyoya Git';

  @override
  String get nextClipButton => 'Sonraki Klip';

  @override
  String get retakeButton => 'Tekrar çek';

  @override
  String cameraNotInitialized(String error) {
    return 'Kamera başlatılamadı: $error';
  }

  @override
  String get studioAppBarTitle => 'Taslak Stüdyo';

  @override
  String get studioRejectButton => 'Reddet';

  @override
  String get loadingBuildingPrompt => 'İçerik kurgusu hazırlanıyor...';

  @override
  String get loadingGeneratingCaption => 'AI açıklama yazıyor...';

  @override
  String get loadingGeneric => 'Yükleniyor...';

  @override
  String get draftPreviewLabel => 'Taslak Önizleme';

  @override
  String get aiCaptionSectionTitle => 'AI Açıklama';

  @override
  String get regenerateCaptionButton => 'Yeniden Yaz';

  @override
  String get upscaleButton => '4K\'ya Yükselt';

  @override
  String creditsWillBeUsed(int count) {
    return '$count kredi kullanılacak';
  }

  @override
  String get insufficientCreditsSnackbar =>
      'Yetersiz kredi. Lütfen kredi satın alın.';

  @override
  String get renderingTitle => '4K render yapılıyor...';

  @override
  String get renderingSubtitle => 'İçerik hazır olunca bildirim alacaksın.';

  @override
  String get contentReadyTitle => 'İçerik Hazır!';

  @override
  String get shareInstagramButton => 'Instagram\'a Paylaş';

  @override
  String get saveToGalleryButton => 'Galeriye Kaydet';

  @override
  String get unknownError => 'Bilinmeyen hata.';

  @override
  String get studioRetryButton => 'Tekrar Dene';

  @override
  String get creditDialogTitle => 'Render Onayı';

  @override
  String creditDialogBody(int credits, int remaining, int afterDeduct) {
    return 'Bu içeriği 4K ve AI efektleriyle oluşturmak için $credits kredin kullanılacak. Kalan kredin: $remaining → $afterDeduct. Devam etmek istiyor musun?';
  }

  @override
  String get creditDialogCancel => 'İptal';

  @override
  String get creditDialogConfirm => 'Onayla';
}
