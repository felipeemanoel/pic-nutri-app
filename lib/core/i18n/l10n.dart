import 'package:flutter/widgets.dart';

import '../../l10n/app_localizations.dart';

export '../../l10n/app_localizations.dart';

final _fallback = lookupAppLocalizations(const Locale('pt'));

extension L10nContext on BuildContext {
  /// Textos traduzidos da tela: `context.l10n.profileTitle`.
  ///
  /// Fora de um MaterialApp com os delegates (alguns testes de widget),
  /// usa o português, sem quebrar.
  AppLocalizations get l10n => AppLocalizations.of(this) ?? _fallback;
}

/// Nome do tipo de refeição da API (`breakfast`, `lunch`...) no idioma do
/// app; `null` para um tipo desconhecido.
String? mealTypeLabel(AppLocalizations l10n, String? type) => switch (type) {
  'breakfast' => l10n.mealBreakfast,
  'morning_snack' => l10n.mealMorningSnack,
  'lunch' => l10n.mealLunch,
  'afternoon_snack' => l10n.mealAfternoonSnack,
  'dinner' => l10n.mealDinner,
  'supper' => l10n.mealSupper,
  'other' => l10n.mealOther,
  _ => null,
};
