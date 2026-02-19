import 'package:flutter/widgets.dart';
import '../../l10n/app_localizations.dart';

/// BuildContext üzerinden kısa localization erişimi.
///
/// Kullanım:
///   context.l10n.loginTitle
///   context.l10n.creditsWillBeUsed(count: 2)
extension L10nX on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}
