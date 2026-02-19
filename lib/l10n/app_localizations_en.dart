// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'digitaldeyim';

  @override
  String get loginSubtitle =>
      'AI-powered professional content creation for SMEs';

  @override
  String get loginError => 'Sign-in failed. Please try again.';

  @override
  String get googleSignInButton => 'Continue with Google';

  @override
  String get loginTermsNotice =>
      'By continuing, you agree to the Terms of Service\nand Privacy Policy.';

  @override
  String get sectorGreeting => 'Hello!';

  @override
  String get sectorTitle => 'What do you sell?';

  @override
  String get sectorSubtitle =>
      'Your sector-specific AI director is waiting for you.';

  @override
  String get sectorLoadError => 'Sectors could not be loaded';

  @override
  String get sectorLoadErrorRetryHint => 'Please try again.';

  @override
  String get sectorRetryButton => 'Try Again';

  @override
  String get sectorContinueButton => 'Continue';

  @override
  String get businessInfoAppBarTitle => 'Tell Us About Your Business';

  @override
  String get stepSector => 'Sector';

  @override
  String get stepInfo => 'Details';

  @override
  String get stepVoice => 'Voice';

  @override
  String get stepReady => 'Ready';

  @override
  String get businessNameLabel => 'Your Business Name';

  @override
  String get businessNameHint => 'e.g. Ayşe Bridal Boutique';

  @override
  String get topProductsLabel => 'Top 3 Best-Selling Products';

  @override
  String get productNameHint => 'Enter product name';

  @override
  String get vibeLabel => 'Your Store\'s Character';

  @override
  String get audienceLabel => 'Who Are Your Customers?';

  @override
  String get businessInfoNextButton => 'Next Step';

  @override
  String get vibeLuxury => 'Luxury & Sophisticated';

  @override
  String get vibeFriendly => 'Friendly & Warm';

  @override
  String get vibeTech => 'Technological & Modern';

  @override
  String get vibeTraditional => 'Traditional & Trustworthy';

  @override
  String get audienceYouth => 'Youth (18-30)';

  @override
  String get audienceFamilies => 'Families';

  @override
  String get audienceProfessionals => 'Professionals';

  @override
  String get audienceMixed => 'Mixed';

  @override
  String get voiceAppBarTitle => 'Record Your Brand Voice';

  @override
  String get voicePromptTitle => 'Describe your store in 15 seconds';

  @override
  String get voicePromptBody =>
      'The AI will analyze your brand\'s character and energy from your tone of voice. Speak naturally, don\'t perform.';

  @override
  String get voiceStatusRecording => 'Recording...';

  @override
  String get voiceStatusDone => 'Recording complete';

  @override
  String get voiceStatusIdle => 'Tap the microphone and speak';

  @override
  String get voiceAnalyzingLabel => 'AI is analyzing your brand...';

  @override
  String get voiceAnalyzeButton => 'Analyze and Start';

  @override
  String get voiceSkipButton => 'Skip for now';

  @override
  String voiceMicError(String error) {
    return 'Could not start microphone: $error';
  }

  @override
  String get voiceDefaultBusinessName => 'My Business';

  @override
  String get cameraReadyLabel => 'Camera Ready';

  @override
  String get recordingIndicator => '● REC';

  @override
  String get validationLightLabel => 'Light';

  @override
  String get validationStabilityLabel => 'Stable';

  @override
  String get goToStudioButton => 'Go to Studio';

  @override
  String get nextClipButton => 'Next Clip';

  @override
  String get retakeButton => 'Retake';

  @override
  String cameraNotInitialized(String error) {
    return 'Camera could not start: $error';
  }

  @override
  String get studioAppBarTitle => 'Draft Studio';

  @override
  String get studioRejectButton => 'Reject';

  @override
  String get loadingBuildingPrompt => 'Preparing content concept...';

  @override
  String get loadingGeneratingCaption => 'AI is writing the caption...';

  @override
  String get loadingGeneric => 'Loading...';

  @override
  String get draftPreviewLabel => 'Draft Preview';

  @override
  String get aiCaptionSectionTitle => 'AI Caption';

  @override
  String get regenerateCaptionButton => 'Rewrite';

  @override
  String get upscaleButton => 'Upscale to 4K';

  @override
  String creditsWillBeUsed(int count) {
    return '$count credits will be used';
  }

  @override
  String get insufficientCreditsSnackbar =>
      'Insufficient credits. Please purchase more credits.';

  @override
  String get renderingTitle => 'Rendering in 4K...';

  @override
  String get renderingSubtitle =>
      'You\'ll get a notification when your content is ready.';

  @override
  String get contentReadyTitle => 'Content Ready!';

  @override
  String get shareInstagramButton => 'Share to Instagram';

  @override
  String get saveToGalleryButton => 'Save to Gallery';

  @override
  String get unknownError => 'Unknown error.';

  @override
  String get studioRetryButton => 'Try Again';

  @override
  String get creditDialogTitle => 'Render Confirmation';

  @override
  String creditDialogBody(int credits, int remaining, int afterDeduct) {
    return 'To create this content with 4K and AI effects, $credits of your credits will be used. Remaining: $remaining → $afterDeduct. Do you want to continue?';
  }

  @override
  String get creditDialogCancel => 'Cancel';

  @override
  String get creditDialogConfirm => 'Confirm';
}
