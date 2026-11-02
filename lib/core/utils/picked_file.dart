import 'dart:io';

/// Apaga a cópia temporária que o seletor de imagens grava no aparelho.
///
/// Fotos de refeição, de evolução e de perfil são dados pessoais: depois do
/// envio (ou da desistência) não devem ficar no cache do app.
Future<void> discardPickedFile(String? path) async {
  if (path == null || path.isEmpty) return;
  try {
    final file = File(path);
    if (file.existsSync()) await file.delete();
  } on Object {
    // Arquivo já removido pelo sistema ou sem permissão: nada a fazer.
  }
}
