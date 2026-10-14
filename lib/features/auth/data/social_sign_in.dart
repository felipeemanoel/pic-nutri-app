import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../../../app/integrations.dart';
import '../../../core/network/api_client.dart';

/// Credencial obtida no aparelho e enviada ao servidor, que a confere.
class SocialCredential {
  const SocialCredential({required this.provider, required this.idToken, this.nonce, this.name});

  final String provider;
  final String idToken;

  /// Apple: nonce original (o token traz o SHA-256 dele).
  final String? nonce;

  /// Apple só envia o nome no primeiro login.
  final String? name;
}

/// Usuário fechou a tela do provedor: não é erro.
class SocialSignInCanceled implements Exception {
  const SocialSignInCanceled();
}

/// Obtém o ID token do Google ou da Apple. Não decide nada sobre a conta: o
/// servidor valida o token e vincula ou cria a conta.
class SocialSignIn {
  bool _googleReady = false;

  Future<SocialCredential> google() async {
    final signIn = GoogleSignIn.instance;
    if (!_googleReady) {
      await signIn.initialize(
        clientId: Integrations.googleIosClientId.isEmpty ? null : Integrations.googleIosClientId,
        serverClientId: Integrations.googleServerClientId,
      );
      _googleReady = true;
    }
    try {
      final account = await signIn.authenticate();
      final token = account.authentication.idToken;
      if (token == null) throw StateError('Google não retornou o ID token.');
      return SocialCredential(provider: 'google', idToken: token, name: account.displayName);
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled || e.code == GoogleSignInExceptionCode.interrupted) {
        throw const SocialSignInCanceled();
      }
      rethrow;
    }
  }

  Future<SocialCredential> apple() async {
    final rawNonce = _nonce();
    try {
      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: const [AppleIDAuthorizationScopes.email, AppleIDAuthorizationScopes.fullName],
        nonce: sha256.convert(utf8.encode(rawNonce)).toString(),
      );
      final token = credential.identityToken;
      if (token == null) throw StateError('Apple não retornou o token.');
      final name = [credential.givenName, credential.familyName].whereType<String>().join(' ').trim();
      return SocialCredential(provider: 'apple', idToken: token, nonce: rawNonce, name: name.isEmpty ? null : name);
    } on SignInWithAppleAuthorizationException catch (e) {
      if (e.code == AuthorizationErrorCode.canceled) throw const SocialSignInCanceled();
      rethrow;
    }
  }

  Future<void> signOut() async {
    if (_googleReady) await GoogleSignIn.instance.signOut();
  }

  static String _nonce([int length = 32]) {
    const chars = '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(length, (_) => chars[random.nextInt(chars.length)]).join();
  }
}

final socialSignInProvider = Provider<SocialSignIn>((ref) => SocialSignIn());

/// Provedores disponíveis: configurados no app E habilitados no servidor.
final socialProvidersProvider = FutureProvider<Set<String>>((ref) async {
  final local = {
    if (Integrations.googleSignIn) 'google',
    if (Integrations.appleSignIn) 'apple',
  };
  if (local.isEmpty) return const {};
  try {
    final response = await ref.watch(dioProvider).get<Map<String, dynamic>>('auth/providers');
    final data = response.data!['data'] as Map<String, dynamic>;
    return local.where((p) => data[p] == true).toSet();
  } on Object {
    return const {};
  }
});
