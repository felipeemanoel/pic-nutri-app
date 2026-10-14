import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/env.dart';
import '../storage/token_storage.dart';
import 'auth_interceptor.dart';
import 'unauthorized_interceptor.dart';

/// Sinal disparado quando a API responde 401 numa rota autenticada.
/// O controlador de sessão escuta este sinal e encerra a sessão local.
class SessionExpiredSignal extends Notifier<int> {
  @override
  int build() => 0;

  void fire() => state++;
}

final sessionExpiredSignalProvider =
    NotifierProvider<SessionExpiredSignal, int>(SessionExpiredSignal.new);

/// Cliente HTTP único do app, apontando para `/api/v1`.
final dioProvider = Provider<Dio>((ref) {
  final env = ref.watch(appEnvProvider);

  final dio = Dio(
    BaseOptions(
      baseUrl: '${env.apiV1Url}/',
      connectTimeout: const Duration(seconds: 10),
      sendTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 20),
      headers: {Headers.acceptHeader: Headers.jsonContentType},
      responseType: ResponseType.json,
    ),
  );

  dio.interceptors.addAll([
    AuthInterceptor(ref.watch(tokenStorageProvider)),
    // Lido no momento do erro, para não criar dependência circular com a sessão.
    UnauthorizedInterceptor(
      () => ref.read(sessionExpiredSignalProvider.notifier).fire(),
    ),
  ]);

  ref.onDispose(dio.close);
  return dio;
});
