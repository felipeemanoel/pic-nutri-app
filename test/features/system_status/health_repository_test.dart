import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnutri/core/error/app_failure.dart';
import 'package:picnutri/features/system_status/data/health_repository.dart';

import '../../helpers/fake_http_adapter.dart';

void main() {
  late FakeHttpAdapter adapter;
  late HealthRepository repository;

  setUp(() {
    adapter = FakeHttpAdapter();
    final dio = Dio(BaseOptions(baseUrl: 'https://api.exemplo/api/v1/'))
      ..httpClientAdapter = adapter;
    repository = HealthRepository(dio);
  });

  test('lê o estado saudável da API', () async {
    adapter.body = {
      'status': 'ok',
      'environment': 'local',
      'checks': {'database': 'ok', 'cache': 'ok', 'storage': 'ok'},
    };

    final health = await repository.fetch();

    expect(
      adapter.lastRequest?.uri.toString(),
      'https://api.exemplo/api/v1/health',
    );
    expect(health.isHealthy, isTrue);
    expect(health.checks, {'database': true, 'cache': true, 'storage': true});
  });

  test('trata 503 como estado degradado, não como exceção', () async {
    adapter
      ..statusCode = 503
      ..body = {
        'status': 'degraded',
        'environment': 'local',
        'checks': {'database': 'fail', 'cache': 'ok', 'storage': 'ok'},
      };

    final health = await repository.fetch();

    expect(health.isHealthy, isFalse);
    expect(health.checks['database'], isFalse);
  });

  test('converte outros erros em AppFailure', () async {
    adapter
      ..statusCode = 500
      ..body = {
        'error': {'code': 'server_error', 'message': 'Erro'},
      };

    await expectLater(repository.fetch(), throwsA(isA<ServerFailure>()));
  });
}
