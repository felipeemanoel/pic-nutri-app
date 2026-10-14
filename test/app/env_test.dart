import 'package:flutter_test/flutter_test.dart';
import 'package:picnutri/app/env.dart';

void main() {
  test('normaliza a URL e monta o caminho da v1', () {
    final env = AppEnv.parse(
      flavorName: 'dev',
      apiBaseUrl: 'http://10.0.2.2:8080/',
    );

    expect(env.flavor, AppFlavor.dev);
    expect(env.apiV1Url, 'http://10.0.2.2:8080/api/v1');
  });

  test('exige HTTPS fora de dev', () {
    expect(
      () => AppEnv.parse(flavorName: 'prod', apiBaseUrl: 'http://api.exemplo'),
      throwsStateError,
    );
  });

  test('rejeita ambiente desconhecido ou URL ausente', () {
    expect(
      () => AppEnv.parse(flavorName: 'qa', apiBaseUrl: 'https://api.exemplo'),
      throwsStateError,
    );
    expect(
      () => AppEnv.parse(flavorName: 'dev', apiBaseUrl: ''),
      throwsStateError,
    );
  });
}
