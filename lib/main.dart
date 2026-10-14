import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'app/app.dart';
import 'app/env.dart';
import 'core/logging/error_reporting.dart';

/// Rode sempre com um arquivo de ambiente, por exemplo:
/// `flutter run --dart-define-from-file=env/dev.json`
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await initializeDateFormatting('pt_BR');

  final AppEnv env;
  try {
    env = AppEnv.fromEnvironment();
  } on StateError catch (error) {
    // Sem isto, um erro de configuração deixa o app parado na tela inicial
    // nativa, sem nenhuma mensagem.
    runApp(_ConfigErrorApp(message: error.message));
    return;
  }

  await ErrorReporting.run(
    env: env,
    app: () => ProviderScope(
      // Sem nova tentativa automática: o usuário decide quando tentar de novo,
      // evitando rajadas de requisições à API (e custos de IA no futuro).
      retry: noAutomaticRetry,
      overrides: [appEnvProvider.overrideWithValue(env)],
      child: const PicNutriApp(),
    ),
  );
}

/// Tela exibida quando o app foi compilado sem o arquivo de ambiente.
class _ConfigErrorApp extends StatelessWidget {
  const _ConfigErrorApp({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    home: Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.settings_suggest_outlined, size: 48),
              const SizedBox(height: 16),
              const Text(
                'Configuração do app incompleta',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              Text(message, textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    ),
  );
}
