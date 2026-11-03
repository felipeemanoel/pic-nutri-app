import 'package:flutter/widgets.dart';

/// Idiomas oferecidos no app.
///
/// `complete`: a tradução de todas as telas foi concluída e revisada. Enquanto
/// for `false`, o idioma aparece na lista com o aviso "tradução em andamento"
/// e os textos ainda não traduzidos ficam em português (modelo).
enum AppLanguage {
  ptBR('pt', 'BR', 'Português (Brasil)', '🇧🇷', complete: true),
  en('en', null, 'English', '🇺🇸'),
  es('es', null, 'Español', '🇪🇸'),
  fr('fr', null, 'Français', '🇫🇷'),
  de('de', null, 'Deutsch', '🇩🇪'),
  zh('zh', null, '简体中文', '🇨🇳'),
  ja('ja', null, '日本語', '🇯🇵');

  const AppLanguage(
    this.languageCode,
    this.countryCode,
    this.nativeName,
    this.flag, {
    this.complete = false,
  });

  final String languageCode;
  final String? countryCode;

  /// Nome do idioma escrito nele mesmo (não muda com o idioma do app).
  final String nativeName;

  /// Bandeira em emoji: dispensa imagens e funciona em Android e iOS.
  final String flag;
  final bool complete;

  Locale get locale => Locale(languageCode, countryCode);

  /// Código guardado no aparelho e enviado à API (`pt-BR`, `en`, `ja`...).
  String get tag =>
      countryCode == null ? languageCode : '$languageCode-$countryCode';

  /// Idioma usado quando o do aparelho não é oferecido (ou ainda não está
  /// com a tradução concluída). Quando o inglês estiver completo, trocar
  /// para [AppLanguage.en], que atende melhor quem é de fora.
  static const fallback = AppLanguage.ptBR;

  static AppLanguage? fromTag(String? tag) {
    if (tag == null || tag.isEmpty) return null;
    for (final language in values) {
      if (language.tag == tag) return language;
    }
    return null;
  }

  /// Idioma oferecido para um locale (qualquer português vira pt-BR).
  static AppLanguage? fromLocale(Locale locale) {
    for (final language in values) {
      if (language.languageCode == locale.languageCode) return language;
    }
    return null;
  }

  /// Idioma automático, sem escolha da pessoa: o primeiro idioma da lista do
  /// sistema que o app oferece **com a tradução concluída**. Assim, um
  /// aparelho em inglês não abre o app meio traduzido; a pessoa ainda pode
  /// escolher um idioma em andamento no seletor.
  static AppLanguage fromDevice(Iterable<Locale> deviceLocales) {
    for (final locale in deviceLocales) {
      final language = fromLocale(locale);
      if (language != null && language.complete) return language;
    }
    return fallback;
  }

  static List<Locale> get supportedLocales => [
    for (final language in values) language.locale,
  ];
}
