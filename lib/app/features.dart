/// Recursos ligados ou desligados no build (`--dart-define-from-file`).
///
/// `FEATURE_MEDICAL=false` gera a versão sem recursos de saúde do grupo
/// "Medicina" do Google Play: registro de medicamentos e busca/compartilhamento
/// com profissionais. A Play Store só aceita esses recursos de contas de
/// organização. O padrão é `true` (app completo).
abstract final class AppFeatures {
  /// OFF no lançamento: mantém texto/voz guardados para uma etapa futura.
  /// Reativar exige habilitação explícita no app e no backend.
  static const mealTextVoice = bool.fromEnvironment(
    'FEATURE_MEAL_TEXT_VOICE',
    defaultValue: false,
  );

  static const medical = bool.fromEnvironment(
    'FEATURE_MEDICAL',
    defaultValue: true,
  );

  /// Seletor de idioma no login, no início do cadastro e no Perfil.
  /// Desligar (`FEATURE_LANGUAGES=false`) esconde o seletor e mantém o app
  /// no idioma do aparelho.
  static const languages = bool.fromEnvironment(
    'FEATURE_LANGUAGES',
    defaultValue: true,
  );
}
