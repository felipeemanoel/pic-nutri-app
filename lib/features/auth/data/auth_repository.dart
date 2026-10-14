import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/app_failure.dart';
import '../../../core/network/api_client.dart';
import 'account.dart';

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

  /// Entra com Google/Apple: o servidor confere o token e vincula/cria a conta.
  Future<AuthSession> social({
    required String provider,
    required String idToken,
    required String deviceName,
    String? nonce,
    String? name,
    bool acceptTerms = false,
    String? timezone,
  }) => _session('auth/social/$provider', {
    'id_token': idToken,
    'nonce': ?nonce,
    'name': ?name,
    'accept_terms': acceptTerms,
    'device_name': deviceName,
    'timezone': ?timezone,
  });

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
