import 'dart:ui' show PlatformDispatcher;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../app/features.dart';
import 'app_language.dart';

/// Guarda o idioma escolhido neste aparelho. Sem escolha, o app segue o
/// idioma do sistema. Reaproveita o armazenamento seguro (como o tema).
class LanguagePreferenceStore {
  LanguagePreferenceStore([FlutterSecureStorage? storage])
    : _storage = storage ?? const FlutterSecureStorage();

  static const _key = 'picnutri.language';
  final FlutterSecureStorage _storage;

  Future<AppLanguage?> read() async {
    try {
      return AppLanguage.fromTag(await _storage.read(key: _key));
    } on Object {
      // Sem armazenamento (testes sem plugin): segue o idioma automático.
      return null;
    }
  }

  Future<void> write(AppLanguage? language) async {
    try {
      if (language == null) {
        await _storage.delete(key: _key);
      } else {
        await _storage.write(key: _key, value: language.tag);
      }
    } on Object {
      // Preferência do aparelho: se não puder salvar, vale só nesta sessão.
    }
  }
}

final languagePreferenceStoreProvider = Provider<LanguagePreferenceStore>(
  (ref) => LanguagePreferenceStore(),
);

/// Idioma escolhido pela pessoa; `null` = seguir o idioma do aparelho.
class LanguageController extends Notifier<AppLanguage?> {
  bool _changed = false;

  @override
  AppLanguage? build() {
    ref.read(languagePreferenceStoreProvider).read().then((saved) {
      // Uma escolha feita enquanto a leitura não terminava prevalece.
      if (!_changed && saved != state) state = saved;
    });
    return null;
  }

  Future<void> set(AppLanguage? language) async {
    _changed = true;
    state = language;
    await ref.read(languagePreferenceStoreProvider).write(language);
  }
}

final languageControllerProvider =
    NotifierProvider<LanguageController, AppLanguage?>(LanguageController.new);

/// Idioma em uso agora: o escolhido ou, sem escolha, o automático do
/// aparelho. Usado fora da árvore de widgets (cabeçalho das requisições).
final currentLanguageProvider = Provider<AppLanguage>((ref) {
  if (!AppFeatures.languages) return AppLanguage.ptBR;
  final chosen = ref.watch(languageControllerProvider);
  if (chosen != null) return chosen;
  return AppLanguage.fromDevice(PlatformDispatcher.instance.locales);
});
