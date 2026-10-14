import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Guarda a preferência de tema do aparelho (claro, escuro ou do sistema).
/// Reaproveita o armazenamento seguro já usado pelo app, sem nova dependência.
class ThemePreferenceStore {
  ThemePreferenceStore([FlutterSecureStorage? storage])
    : _storage = storage ?? const FlutterSecureStorage();

  static const _key = 'picnutri.theme_mode';
  final FlutterSecureStorage _storage;

  Future<ThemeMode> read() async {
    try {
      return switch (await _storage.read(key: _key)) {
        'light' => ThemeMode.light,
        'dark' => ThemeMode.dark,
        _ => ThemeMode.system,
      };
    } on PlatformException {
      return ThemeMode.system;
    } on MissingPluginException {
      return ThemeMode.system;
    }
  }

  Future<void> write(ThemeMode mode) async {
    try {
      await _storage.write(key: _key, value: mode.name);
    } on PlatformException {
      // Preferência visual: se não puder salvar, vale só nesta sessão.
    } on MissingPluginException {
      // Idem (testes).
    }
  }
}

final themePreferenceStoreProvider = Provider<ThemePreferenceStore>(
  (ref) => ThemePreferenceStore(),
);

class ThemeModeController extends Notifier<ThemeMode> {
  @override
  ThemeMode build() {
    ref.read(themePreferenceStoreProvider).read().then((saved) {
      if (saved != state) state = saved;
    });
    return ThemeMode.system;
  }

  Future<void> set(ThemeMode mode) async {
    state = mode;
    await ref.read(themePreferenceStoreProvider).write(mode);
  }
}

final themeModeProvider = NotifierProvider<ThemeModeController, ThemeMode>(
  ThemeModeController.new,
);
