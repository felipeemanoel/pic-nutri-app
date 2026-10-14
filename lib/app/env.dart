import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Ambientes de execução do app.
enum AppFlavor { dev, staging, prod }

/// Configuração lida em tempo de compilação via `--dart-define-from-file`.
///
/// Só contém valores públicos (URL da API e DSN de erros). Nenhum segredo
/// pode ser colocado aqui: tudo que vai no binário pode ser extraído.
class AppEnv {
  const AppEnv({
    required this.flavor,
    required this.apiBaseUrl,
    this.sentryDsn = '',
  });

  /// Lê `APP_FLAVOR`, `API_BASE_URL` e `SENTRY_DSN` definidos no build.
  factory AppEnv.fromEnvironment() {
    const flavorName = String.fromEnvironment(
      'APP_FLAVOR',
      defaultValue: 'dev',
    );
    const apiBaseUrl = String.fromEnvironment('API_BASE_URL');
    const sentryDsn = String.fromEnvironment('SENTRY_DSN');

    return AppEnv.parse(
      flavorName: flavorName,
      apiBaseUrl: apiBaseUrl,
      sentryDsn: sentryDsn,
    );
  }

  /// Valida os valores recebidos; separado de [AppEnv.fromEnvironment] para teste.
  factory AppEnv.parse({
    required String flavorName,
    required String apiBaseUrl,
    String sentryDsn = '',
  }) {
    if (apiBaseUrl.isEmpty) {
      throw StateError(
        'API_BASE_URL não definido. Rode com --dart-define-from-file=env/dev.json',
      );
    }

    final flavor = AppFlavor.values.asNameMap()[flavorName];
    if (flavor == null) {
      throw StateError('APP_FLAVOR inválido: "$flavorName".');
    }

    final uri = Uri.parse(apiBaseUrl);
    if (flavor != AppFlavor.dev && uri.scheme != 'https') {
      throw StateError('Fora de dev, API_BASE_URL precisa usar HTTPS.');
    }

    return AppEnv(
      flavor: flavor,
      apiBaseUrl: apiBaseUrl.endsWith('/')
          ? apiBaseUrl.substring(0, apiBaseUrl.length - 1)
          : apiBaseUrl,
      sentryDsn: sentryDsn,
    );
  }

  final AppFlavor flavor;
  final String apiBaseUrl;
  final String sentryDsn;

  bool get isDev => flavor == AppFlavor.dev;

  /// URL base da versão atual da API.
  String get apiV1Url => '$apiBaseUrl/api/v1';
}

/// Sobrescrito em `main.dart` com o ambiente real (e nos testes com um fake).
final appEnvProvider = Provider<AppEnv>(
  (ref) => throw UnimplementedError('appEnvProvider deve ser sobrescrito.'),
);

/// Política de retry do Riverpod usada no app: nunca repetir sozinho.
Duration? noAutomaticRetry(int retryCount, Object error) => null;
