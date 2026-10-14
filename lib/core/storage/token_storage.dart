import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Guarda o token de acesso da API no Keychain (iOS) ou Keystore (Android).
///
/// Único lugar do app onde credenciais são persistidas. Nunca usar
/// SharedPreferences, arquivos ou logs para tokens.
class TokenStorage {
  TokenStorage([FlutterSecureStorage? storage])
    : _storage =
          storage ??
          const FlutterSecureStorage(
            aOptions: AndroidOptions(),
            // Disponível após o primeiro desbloqueio e nunca migrado para
            // outro aparelho via backup.
            iOptions: IOSOptions(
              accessibility: KeychainAccessibility.first_unlock_this_device,
            ),
          );

  static const _accessTokenKey = 'picnutri.access_token';
  static const _expiresAtKey = 'picnutri.access_token_expires_at';

  final FlutterSecureStorage _storage;

  Future<String?> readAccessToken() => _storage.read(key: _accessTokenKey);

  Future<void> writeAccessToken(String token) =>
      _storage.write(key: _accessTokenKey, value: token);

  /// Momento em que o token expira (UTC), quando informado pela API.
  Future<DateTime?> readExpiresAt() async {
    final raw = await _storage.read(key: _expiresAtKey);
    return raw == null ? null : DateTime.tryParse(raw)?.toUtc();
  }

  Future<void> writeSession(String token, DateTime? expiresAt) async {
    await _storage.write(key: _accessTokenKey, value: token);
    if (expiresAt == null) {
      await _storage.delete(key: _expiresAtKey);
    } else {
      await _storage.write(
        key: _expiresAtKey,
        value: expiresAt.toUtc().toIso8601String(),
      );
    }
  }

  Future<void> clear() async {
    await _storage.delete(key: _accessTokenKey);
    await _storage.delete(key: _expiresAtKey);
  }
}

final tokenStorageProvider = Provider<TokenStorage>((ref) => TokenStorage());
