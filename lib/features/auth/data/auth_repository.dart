import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/app_failure.dart';
import '../../../core/network/api_client.dart';
import 'account.dart';
import 'sign_in_methods.dart';

export 'sign_in_methods.dart';

/// Chamadas de autenticação e conta. Toda falha vira [AppFailure].
class AuthRepository {
  const AuthRepository(this._dio);

  final Dio _dio;

  Future<AuthSession> login({
    required String email,
    required String password,
    required String deviceName,
  }) => _session('auth/login', {
    'email': email.trim(),
    'password': password,
    'device_name': deviceName,
  });

  Future<AuthSession> register({
    required String name,
    required String email,
    required String password,
    required bool acceptTerms,
    required String deviceName,
    String? timezone,
  }) => _session('auth/register', {
    'name': name.trim(),
    'email': email.trim(),
    'password': password,
    'password_confirmation': password,
    'accept_terms': acceptTerms,
    'device_name': deviceName,
    'timezone': ?timezone,
  });

  /// Entra com Google, Facebook ou Apple: o servidor valida a credencial.
  ///
  /// Pode falhar com `terms_acceptance_required`, `social_email_required` ou
  /// `account_link_required` (com `details.pending_token`), tratados em
  /// [SocialFlowStep].
  Future<AuthSession> social(
    SocialCredentialData credential, {
    required String deviceName,
    bool acceptTerms = false,
    String? timezone,
  }) => _session('auth/social/${credential.provider}', {
    ...credential.body,
    'accept_terms': acceptTerms,
    'device_name': deviceName,
    'timezone': ?timezone,
  });

  /// Continua um cadastro pendente. Devolve a sessão, ou `null` quando o
  /// servidor enviou um código ao e-mail informado.
  Future<AuthSession?> socialComplete({
    required String pendingToken,
    required String deviceName,
    bool acceptTerms = false,
    String? email,
    String? code,
    String? timezone,
  }) async {
    final response = await guard(
      () => _dio.post<Map<String, dynamic>>(
        'auth/social/complete',
        data: {
          'pending_token': pendingToken,
          'accept_terms': acceptTerms,
          'email': ?email,
          'code': ?code,
          'timezone': ?timezone,
          'device_name': deviceName,
        },
      ),
    );
    if (response.statusCode == 202) return null;
    return AuthSession.fromJson(response.data!['data'] as Map<String, dynamic>);
  }

  /// Envia código ao e-mail da conta existente (comprovação para vincular).
  Future<void> socialLinkCode(String pendingToken) => guard(
    () => _dio.post<void>(
      'auth/social/link/code',
      data: {'pending_token': pendingToken},
    ),
  );

  /// Vincula o acesso à conta existente após a comprovação.
  Future<AuthSession> socialLink({
    required String pendingToken,
    required String deviceName,
    String? password,
    String? code,
  }) => _session('auth/social/link', {
    'pending_token': pendingToken,
    'password': ?password,
    'code': ?code,
    'device_name': deviceName,
  });

  Future<SignInMethods> signInMethods() async {
    final response = await guard(
      () => _dio.get<Map<String, dynamic>>('me/sign-in-methods'),
    );
    return SignInMethods.fromJson(
      response.data!['data'] as Map<String, dynamic>,
    );
  }

  Future<SignInMethods> linkProvider(SocialCredentialData credential) async {
    final response = await guard(
      () => _dio.post<Map<String, dynamic>>(
        'me/social/${credential.provider}',
        data: credential.body,
      ),
    );
    return SignInMethods.fromJson(
      response.data!['data'] as Map<String, dynamic>,
    );
  }

  Future<SignInMethods> unlinkProvider(String provider) async {
    final response = await guard(
      () => _dio.delete<Map<String, dynamic>>('me/social/$provider'),
    );
    return SignInMethods.fromJson(
      response.data!['data'] as Map<String, dynamic>,
    );
  }

  /// Código para definir senha local (contas só com login social).
  Future<void> sendPasswordCode() =>
      guard(() => _dio.post<void>('me/password/code'));

  Future<void> setPassword({required String code, required String password}) =>
      guard(
        () => _dio.post<void>(
          'me/password',
          data: {
            'code': code.trim(),
            'password': password,
            'password_confirmation': password,
          },
        ),
      );

  Future<AuthSession> refresh() => _session('auth/refresh', const {});

  Future<void> logout() => guard(() => _dio.post<void>('auth/logout'));

  Future<Account> me() async {
    final response = await guard(() => _dio.get<Map<String, dynamic>>('me'));
    return Account.fromJson(response.data!['data'] as Map<String, dynamic>);
  }

  Future<void> forgotPassword(String email) => guard(
    () =>
        _dio.post<void>('auth/forgot-password', data: {'email': email.trim()}),
  );

  Future<void> resetPassword({
    required String email,
    required String code,
    required String password,
  }) => guard(
    () => _dio.post<void>(
      'auth/reset-password',
      data: {
        'email': email.trim(),
        'code': code.trim(),
        'password': password,
        'password_confirmation': password,
      },
    ),
  );

  Future<AuthSession> _session(String path, Map<String, Object?> body) async {
    final response = await guard(
      () => _dio.post<Map<String, dynamic>>(path, data: body),
    );
    return AuthSession.fromJson(response.data!['data'] as Map<String, dynamic>);
  }
}

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepository(ref.watch(dioProvider)),
);
