import 'package:dio/dio.dart';

/// Detecta sessão expirada ou revogada (HTTP 401) e conta bloqueada (403
/// `account_blocked`) em rotas autenticadas.
///
/// Não age nas rotas de login/cadastro, onde 401 significa credencial errada.
class UnauthorizedInterceptor extends Interceptor {
  UnauthorizedInterceptor(this._onUnauthorized);

  final void Function() _onUnauthorized;

  static const _publicPaths = [
    'auth/login',
    'auth/register',
    'auth/forgot-password',
    'auth/reset-password',
  ];

  /// Conta bloqueada pela equipe: encerra a sessão como um token revogado.
  static bool _isBlocked(Object? data) =>
      data is Map<String, dynamic> &&
      data['error'] is Map<String, dynamic> &&
      (data['error'] as Map<String, dynamic>)['code'] == 'account_blocked';

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final path = err.requestOptions.path;
    final isPublic = _publicPaths.any(path.endsWith) || path.contains('auth/social/');
    final status = err.response?.statusCode;
    if (!isPublic && (status == 401 || (status == 403 && _isBlocked(err.response?.data)))) {
      _onUnauthorized();
    }
    handler.next(err);
  }
}
