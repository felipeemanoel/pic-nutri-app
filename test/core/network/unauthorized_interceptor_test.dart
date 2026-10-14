import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnutri/core/network/unauthorized_interceptor.dart';

import '../../helpers/fake_http_adapter.dart';

void main() {
  Future<int> callsFor(String path) async {
    var calls = 0;
    final dio = Dio(BaseOptions(baseUrl: 'https://api.exemplo/api/v1/'))
      ..httpClientAdapter = FakeHttpAdapter(statusCode: 401, body: const {})
      ..interceptors.add(UnauthorizedInterceptor(() => calls++));
    try {
      await dio.post<dynamic>(path);
    } on DioException {
      // esperado
    }
    return calls;
  }

  test('401 numa rota autenticada sinaliza sessão expirada', () async {
    expect(await callsFor('me'), 1);
  });

  test('401 no login é credencial errada, não sessão expirada', () async {
    expect(await callsFor('auth/login'), 0);
  });
}
