/// Recursos ligados ou desligados no build (`--dart-define-from-file`).
///
/// `FEATURE_MEDICAL=false` gera a versão sem recursos de saúde do grupo
/// "Medicina" do Google Play: registro de medicamentos e busca/compartilhamento
/// com profissionais. A Play Store só aceita esses recursos de contas de
/// organização. O padrão é `true` (app completo).
abstract final class AppFeatures {
  static const medical = bool.fromEnvironment('FEATURE_MEDICAL', defaultValue: true);
}
