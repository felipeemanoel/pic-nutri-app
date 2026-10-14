import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:picnutri/core/network/auth_interceptor.dart';
import 'package:picnutri/core/storage/token_storage.dart';

import '../../helpers/fake_http_adapter.dart';

class _MockTokenStorage extends Mock implements TokenStorage {}

void main() {
  late _MockTokenStorage storage;
  late FakeHttpAdapter adapter;
  late Dio dio;

  setUp(() {
    storage = _MockTokenStorage();
    adapter = FakeHttpAdapter();
    dio = Dio(BaseOptions(baseUrl: 'https://api.exemplo/api/v1/'))
      ..httpClientAdapter = adapter
      ..interceptors.add(AuthInterceptor(storage));
  });

  test('envia o token Bearer quando existe', () async {
    when(() => storage.readAccessToken()).thenAnswer((_) async => 'pn_abc');

    await dio.get<dynamic>('health');

    expect(adapter.lastRequest?.headers['Authorization'], 'Bearer pn_abc');
  });

  test('não envia cabeçalho sem token', () async {
    when(() => storage.readAccessToken()).thenAnswer((_) async => null);

    await dio.get<dynamic>('health');

    expect(adapter.lastRequest?.headers.containsKey('Authorization'), isFalse);
  });
}
