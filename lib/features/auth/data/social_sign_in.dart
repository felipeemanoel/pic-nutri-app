import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../../../app/integrations.dart';
import '../../../core/network/api_client.dart';
import 'sign_in_methods.dart';

/// Credencial obtida no fluxo oficial do provedor e enviada ao servidor,
/// que a valida. O app nunca pede a senha do Google, Facebook ou Apple.
class SocialCredential {
  const SocialCredential({
    required this.provider,
    this.idToken,
    this.accessToken,
    this.nonce,
    this.name,
    this.authorizationCode,
  });

  final String provider;

  /// Google, Apple e Facebook no iOS (Limited Login): token OIDC.
  final String? idToken;

  /// Facebook no Android: access token (validado pelo servidor na Graph API).
  final String? accessToken;

  /// Apple e Facebook Limited Login: nonce original (o token traz o SHA-256 dele).
  final String? nonce;

  /// A Apple só envia o nome na primeira autorização.
  final String? name;

  /// Apple: código trocado no servidor por um token revogável (exclusão de conta).
  final String? authorizationCode;

  SocialCredentialData get data => SocialCredentialData(provider, toJson());

  Map<String, dynamic> toJson() => {
    'id_token': ?idToken,
    'access_token': ?accessToken,
    'nonce': ?nonce,
    'name': ?name,
    'authorization_code': ?authorizationCode,
  };
}

/// Usuário fechou a tela do provedor: não é erro.
class SocialSignInCanceled implements Exception {
  const SocialSignInCanceled();
}

/// Falha no fluxo do provedor (sem rede, app do provedor indisponível...).
class SocialSignInFailed implements Exception {
  const SocialSignInFailed(this.provider);

  final String provider;

  String get message =>
      'Não foi possível continuar com ${SocialProviders.label(provider)}. '
      'Confira sua conexão e tente novamente.';
}

abstract final class SocialProviders {
  /// Nome no botão "Continuar com ...": Google e Facebook sem artigo;
  /// a Apple mantém o texto oficial em português ("Continuar com a Apple").
  static String buttonName(String provider) => switch (provider) {
    'google' => 'Google',
    'facebook' => 'Facebook',
    _ => label(provider),
  };

  static String label(String provider) => switch (provider) {
    'google' => 'o Google',
    'facebook' => 'o Facebook',
    'apple' => 'a Apple',
    _ => provider,
  };

  static String name(String provider) => switch (provider) {
    'google' => 'Google',
    'facebook' => 'Facebook',
    'apple' => 'Apple',
    _ => provider,
  };
}

/// Obtém a credencial do Google, Facebook ou Apple. Não decide nada sobre a
/// conta: o servidor valida a credencial e vincula ou cria a conta.
class SocialSignIn {
  bool _googleReady = false;

  Future<SocialCredential> signIn(String provider) => switch (provider) {
    'google' => google(),
    'facebook' => facebook(),
    'apple' => apple(),
    _ => throw ArgumentError.value(provider, 'provider'),
  };

  Future<SocialCredential> google() async {
    final signIn = GoogleSignIn.instance;
    try {
      if (!_googleReady) {
        await signIn.initialize(
          clientId: Integrations.googleIosClientId.isEmpty
              ? null
              : Integrations.googleIosClientId,
          serverClientId: Integrations.googleServerClientId,
        );
        _googleReady = true;
      }
      final account = await signIn.authenticate(
        scopeHint: const ['email', 'profile'],
      );
      final token = account.authentication.idToken;
      if (token == null) throw const SocialSignInFailed('google');
      return SocialCredential(
        provider: 'google',
        idToken: token,
        name: account.displayName,
      );
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled ||
          e.code == GoogleSignInExceptionCode.interrupted) {
        throw const SocialSignInCanceled();
      }
      throw const SocialSignInFailed('google');
    } on PlatformException {
      throw const SocialSignInFailed('google');
    }
  }

  /// Android: login clássico (access token validado na Graph API).
  /// iOS: Limited Login (token OIDC com nonce), sem rastreamento.
  /// Pede só o perfil público e o e-mail.
  Future<SocialCredential> facebook() async {
    final auth = FacebookAuth.instance;
    final rawNonce = _nonce();
    final LoginResult result;
    try {
      result = await auth.login(
        permissions: const ['public_profile', 'email'],
        loginTracking: Platform.isIOS
            ? LoginTracking.limited
            : LoginTracking.enabled,
        nonce: Platform.isIOS
            ? sha256.convert(utf8.encode(rawNonce)).toString()
            : null,
      );
    } on PlatformException {
      throw const SocialSignInFailed('facebook');
    }
    switch (result.status) {
      case LoginStatus.cancelled:
        throw const SocialSignInCanceled();
      case LoginStatus.success:
        break;
      case LoginStatus.failed:
      case LoginStatus.operationInProgress:
        throw const SocialSignInFailed('facebook');
    }
    final token = result.accessToken;
    return switch (token) {
      final LimitedToken limited => SocialCredential(
        provider: 'facebook',
        idToken: limited.tokenString,
        nonce: rawNonce,
        name: limited.userName,
      ),
      final ClassicToken classic => SocialCredential(
        provider: 'facebook',
        accessToken: classic.tokenString,
      ),
      _ => throw const SocialSignInFailed('facebook'),
    };
  }

  Future<SocialCredential> apple() async {
    final rawNonce = _nonce();
    try {
      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: const [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: sha256.convert(utf8.encode(rawNonce)).toString(),
      );
      final token = credential.identityToken;
      if (token == null) throw const SocialSignInFailed('apple');
      final name = [
        credential.givenName,
        credential.familyName,
      ].whereType<String>().join(' ').trim();
      return SocialCredential(
        provider: 'apple',
        idToken: token,
        nonce: rawNonce,
        name: name.isEmpty ? null : name,
        authorizationCode: credential.authorizationCode,
      );
    } on SignInWithAppleAuthorizationException catch (e) {
      if (e.code == AuthorizationErrorCode.canceled) {
        throw const SocialSignInCanceled();
      }
      throw const SocialSignInFailed('apple');
    } on PlatformException {
      throw const SocialSignInFailed('apple');
    }
  }

  /// Encerra as sessões locais dos provedores (logout do PicNutri).
  Future<void> signOut() async {
    if (_googleReady) {
      try {
        await GoogleSignIn.instance.signOut();
      } on Object {
        // Sem sessão do Google: nada a fazer.
      }
    }
    if (Integrations.facebookSignIn) {
      try {
        await FacebookAuth.instance.logOut();
      } on Object {
        // Sem sessão do Facebook: nada a fazer.
      }
    }
  }

  static String _nonce([int length = 32]) {
    const chars =
        '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(
      length,
      (_) => chars[random.nextInt(chars.length)],
    ).join();
  }
}

final socialSignInProvider = Provider<SocialSignIn>((ref) => SocialSignIn());

/// Provedores por plataforma: Android = Google e Facebook; iOS = Google,
/// Facebook e Apple (Sign in with Apple só existe no iOS).
Set<String> platformSocialProviders(TargetPlatform platform, {required bool google, required bool facebook}) {
  final mobile = platform == TargetPlatform.android || platform == TargetPlatform.iOS;
  if (!mobile) return const {};
  return {
    if (google) 'google',
    if (facebook) 'facebook',
    if (platform == TargetPlatform.iOS) 'apple',
  };
}

/// Provedores configurados neste build e nesta plataforma.
Set<String> localSocialProviders() => platformSocialProviders(
  defaultTargetPlatform,
  google: Integrations.googleSignIn,
  facebook: Integrations.facebookSignIn,
);

/// Só aparecem os configurados no app E habilitados no servidor.
final socialProvidersProvider = FutureProvider<Set<String>>((ref) async {
  final local = localSocialProviders();
  if (local.isEmpty) return const {};
  try {
    final response = await ref
        .watch(dioProvider)
        .get<Map<String, dynamic>>('auth/providers');
    final data = response.data!['data'] as Map<String, dynamic>;
    return local.where((p) => data[p] == true).toSet();
  } on Object {
    return const {};
  }
});
