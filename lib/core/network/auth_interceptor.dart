import 'package:dio/dio.dart';

import '../storage/token_storage.dart';

/// Anexa o token Sanctum (`Authorization: Bearer ...`) às requisições.
///
/// A renovação e a revogação do token serão tratadas no módulo de
/// autenticação; aqui só há a leitura segura do token atual.
class AuthInterceptor extends Interceptor {
  AuthInterceptor(this._tokenStorage);

  final TokenStorage _tokenStorage;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await _tokenStorage.readAccessToken();
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }
}
