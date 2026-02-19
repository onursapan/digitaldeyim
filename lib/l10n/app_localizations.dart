import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_tr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('tr'),
  ];

  /// Uygulama adı
  ///
  /// In tr, this message translates to:
  /// **'digitaldeyim'**
  String get appName;

  /// Giriş ekranı alt başlığı
  ///
  /// In tr, this message translates to:
  /// **'KOBİ\'ler için AI destekli\nprofesyonel içerik üretimi'**
  String get loginSubtitle;

  /// Google Sign-In hata mesajı
  ///
  /// In tr, this message translates to:
  /// **'Giriş yapılamadı. Lütfen tekrar deneyin.'**
  String get loginError;

  /// Google giriş butonu
  ///
  /// In tr, this message translates to:
  /// **'Google ile devam et'**
  String get googleSignInButton;

  /// Giriş ekranı hüküm metni
  ///
  /// In tr, this message translates to:
  /// **'Devam ederek Kullanım Koşullarını ve\nGizlilik Politikasını kabul etmiş olursunuz.'**
  String get loginTermsNotice;

  /// Sektör seçim ekranı selamlama
  ///
  /// In tr, this message translates to:
  /// **'Merhaba!'**
  String get sectorGreeting;

  /// Sektör seçim başlığı
  ///
  /// In tr, this message translates to:
  /// **'Ne satıyorsun?'**
  String get sectorTitle;

  /// Sektör seçim alt başlığı
  ///
  /// In tr, this message translates to:
  /// **'Sektörüne özel AI yönetmen seni bekliyor.'**
  String get sectorSubtitle;

  /// Sektör yükleme hata başlığı
  ///
  /// In tr, this message translates to:
  /// **'Sektörler yüklenemedi'**
  String get sectorLoadError;

  /// Sektör yükleme hata ipucu
  ///
  /// In tr, this message translates to:
  /// **'Lütfen tekrar deneyin.'**
  String get sectorLoadErrorRetryHint;

  /// Tekrar dene butonu
  ///
  /// In tr, this message translates to:
  /// **'Tekrar Dene'**
  String get sectorRetryButton;

  /// Devam et butonu
  ///
  /// In tr, this message translates to:
  /// **'Devam Et'**
  String get sectorContinueButton;

  /// İşletme bilgisi ekranı başlığı
  ///
  /// In tr, this message translates to:
  /// **'İşletmeni Tanı'**
  String get businessInfoAppBarTitle;

  /// Adım göstergesi - sektör
  ///
  /// In tr, this message translates to:
  /// **'Sektör'**
  String get stepSector;

  /// Adım göstergesi - bilgiler
  ///
  /// In tr, this message translates to:
  /// **'Bilgiler'**
  String get stepInfo;

  /// Adım göstergesi - ses
  ///
  /// In tr, this message translates to:
  /// **'Ses'**
  String get stepVoice;

  /// Adım göstergesi - hazır
  ///
  /// In tr, this message translates to:
  /// **'Hazır'**
  String get stepReady;

  /// İşletme adı form etiketi
  ///
  /// In tr, this message translates to:
  /// **'İşletme Adın'**
  String get businessNameLabel;

  /// İşletme adı placeholder
  ///
  /// In tr, this message translates to:
  /// **'Örn: Ayşe Gelinlik Evi'**
  String get businessNameHint;

  /// En çok satan ürünler etiketi
  ///
  /// In tr, this message translates to:
  /// **'En Çok Satan 3 Ürün'**
  String get topProductsLabel;

  /// Ürün adı placeholder
  ///
  /// In tr, this message translates to:
  /// **'Ürün adı yaz'**
  String get productNameHint;

  /// Karakter seçim etiketi
  ///
  /// In tr, this message translates to:
  /// **'Dükkanın Karakteri'**
  String get vibeLabel;

  /// Hedef kitle etiketi
  ///
  /// In tr, this message translates to:
  /// **'Müşterilerin Kimler?'**
  String get audienceLabel;

  /// Sonraki adım butonu
  ///
  /// In tr, this message translates to:
  /// **'Sonraki Adım'**
  String get businessInfoNextButton;

  /// BusinessVibe: luxury
  ///
  /// In tr, this message translates to:
  /// **'Lüks & Sofistike'**
  String get vibeLuxury;

  /// BusinessVibe: friendly
  ///
  /// In tr, this message translates to:
  /// **'Samimi & Sıcak'**
  String get vibeFriendly;

  /// BusinessVibe: tech
  ///
  /// In tr, this message translates to:
  /// **'Teknolojik & Modern'**
  String get vibeTech;

  /// BusinessVibe: traditional
  ///
  /// In tr, this message translates to:
  /// **'Geleneksel & Güvenilir'**
  String get vibeTraditional;

  /// TargetAudience: youth
  ///
  /// In tr, this message translates to:
  /// **'Gençler (18-30)'**
  String get audienceYouth;

  /// TargetAudience: families
  ///
  /// In tr, this message translates to:
  /// **'Aileler'**
  String get audienceFamilies;

  /// TargetAudience: professionals
  ///
  /// In tr, this message translates to:
  /// **'Profesyoneller'**
  String get audienceProfessionals;

  /// TargetAudience: mixed
  ///
  /// In tr, this message translates to:
  /// **'Karma'**
  String get audienceMixed;

  /// Ses kaydı ekranı başlığı
  ///
  /// In tr, this message translates to:
  /// **'Marka Sesini Kaydet'**
  String get voiceAppBarTitle;

  /// Ses kaydı prompt başlığı
  ///
  /// In tr, this message translates to:
  /// **'15 saniyede dükkanını anlat'**
  String get voicePromptTitle;

  /// Ses kaydı açıklama metni
  ///
  /// In tr, this message translates to:
  /// **'AI, konuşma tonundan markanın karakterini ve enerjisini analiz edecek. Doğal konuş, performans yapma.'**
  String get voicePromptBody;

  /// Kayıt durumu etiketi
  ///
  /// In tr, this message translates to:
  /// **'Kayıt yapılıyor...'**
  String get voiceStatusRecording;

  /// Kayıt tamamlandı etiketi
  ///
  /// In tr, this message translates to:
  /// **'Kayıt tamamlandı'**
  String get voiceStatusDone;

  /// Kayıt bekleme etiketi
  ///
  /// In tr, this message translates to:
  /// **'Mikrofona bas ve konuş'**
  String get voiceStatusIdle;

  /// Analiz yükleme etiketi
  ///
  /// In tr, this message translates to:
  /// **'AI markanı analiz ediyor...'**
  String get voiceAnalyzingLabel;

  /// Analiz et butonu
  ///
  /// In tr, this message translates to:
  /// **'Analiz Et ve Başla'**
  String get voiceAnalyzeButton;

  /// Atla butonu
  ///
  /// In tr, this message translates to:
  /// **'Şimdilik atla'**
  String get voiceSkipButton;

  /// Mikrofon hata mesajı
  ///
  /// In tr, this message translates to:
  /// **'Mikrofon başlatılamadı: {error}'**
  String voiceMicError(String error);

  /// Varsayılan işletme adı
  ///
  /// In tr, this message translates to:
  /// **'İşletmem'**
  String get voiceDefaultBusinessName;

  /// Kamera hazır etiketi
  ///
  /// In tr, this message translates to:
  /// **'Kamera Hazır'**
  String get cameraReadyLabel;

  /// Kayıt göstergesi
  ///
  /// In tr, this message translates to:
  /// **'● REC'**
  String get recordingIndicator;

  /// Işık validasyon etiketi
  ///
  /// In tr, this message translates to:
  /// **'Işık'**
  String get validationLightLabel;

  /// Stabilite validasyon etiketi
  ///
  /// In tr, this message translates to:
  /// **'Sabit'**
  String get validationStabilityLabel;

  /// Stüdyo yönlendirme butonu
  ///
  /// In tr, this message translates to:
  /// **'Stüdyoya Git'**
  String get goToStudioButton;

  /// Sonraki klip butonu
  ///
  /// In tr, this message translates to:
  /// **'Sonraki Klip'**
  String get nextClipButton;

  /// Tekrar çekim butonu
  ///
  /// In tr, this message translates to:
  /// **'Tekrar çek'**
  String get retakeButton;

  /// Kamera başlatma hatası
  ///
  /// In tr, this message translates to:
  /// **'Kamera başlatılamadı: {error}'**
  String cameraNotInitialized(String error);

  /// Stüdyo ekranı başlığı
  ///
  /// In tr, this message translates to:
  /// **'Taslak Stüdyo'**
  String get studioAppBarTitle;

  /// Draft reddet butonu
  ///
  /// In tr, this message translates to:
  /// **'Reddet'**
  String get studioRejectButton;

  /// Prompt hazırlama yükleme
  ///
  /// In tr, this message translates to:
  /// **'İçerik kurgusu hazırlanıyor...'**
  String get loadingBuildingPrompt;

  /// Caption üretme yükleme
  ///
  /// In tr, this message translates to:
  /// **'AI açıklama yazıyor...'**
  String get loadingGeneratingCaption;

  /// Genel yükleme etiketi
  ///
  /// In tr, this message translates to:
  /// **'Yükleniyor...'**
  String get loadingGeneric;

  /// Taslak önizleme başlığı
  ///
  /// In tr, this message translates to:
  /// **'Taslak Önizleme'**
  String get draftPreviewLabel;

  /// AI caption bölüm başlığı
  ///
  /// In tr, this message translates to:
  /// **'AI Açıklama'**
  String get aiCaptionSectionTitle;

  /// Caption yenile butonu
  ///
  /// In tr, this message translates to:
  /// **'Yeniden Yaz'**
  String get regenerateCaptionButton;

  /// 4K render butonu
  ///
  /// In tr, this message translates to:
  /// **'4K\'ya Yükselt'**
  String get upscaleButton;

  /// Kredi kullanım bilgisi
  ///
  /// In tr, this message translates to:
  /// **'{count} kredi kullanılacak'**
  String creditsWillBeUsed(int count);

  /// Yetersiz kredi uyarısı
  ///
  /// In tr, this message translates to:
  /// **'Yetersiz kredi. Lütfen kredi satın alın.'**
  String get insufficientCreditsSnackbar;

  /// Render başlığı
  ///
  /// In tr, this message translates to:
  /// **'4K render yapılıyor...'**
  String get renderingTitle;

  /// Render alt başlığı
  ///
  /// In tr, this message translates to:
  /// **'İçerik hazır olunca bildirim alacaksın.'**
  String get renderingSubtitle;

  /// İçerik hazır başlığı
  ///
  /// In tr, this message translates to:
  /// **'İçerik Hazır!'**
  String get contentReadyTitle;

  /// Instagram paylaş butonu
  ///
  /// In tr, this message translates to:
  /// **'Instagram\'a Paylaş'**
  String get shareInstagramButton;

  /// Galeriye kaydet butonu
  ///
  /// In tr, this message translates to:
  /// **'Galeriye Kaydet'**
  String get saveToGalleryButton;

  /// Genel hata mesajı
  ///
  /// In tr, this message translates to:
  /// **'Bilinmeyen hata.'**
  String get unknownError;

  /// Stüdyo tekrar dene butonu
  ///
  /// In tr, this message translates to:
  /// **'Tekrar Dene'**
  String get studioRetryButton;

  /// Kredi onay diyalog başlığı
  ///
  /// In tr, this message translates to:
  /// **'Render Onayı'**
  String get creditDialogTitle;

  /// Kredi onay diyalog metni
  ///
  /// In tr, this message translates to:
  /// **'Bu içeriği 4K ve AI efektleriyle oluşturmak için {credits} kredin kullanılacak. Kalan kredin: {remaining} → {afterDeduct}. Devam etmek istiyor musun?'**
  String creditDialogBody(int credits, int remaining, int afterDeduct);

  /// Diyalog iptal butonu
  ///
  /// In tr, this message translates to:
  /// **'İptal'**
  String get creditDialogCancel;

  /// Diyalog onayla butonu
  ///
  /// In tr, this message translates to:
  /// **'Onayla'**
  String get creditDialogConfirm;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'tr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'tr':
      return AppLocalizationsTr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
