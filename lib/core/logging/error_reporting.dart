import 'package:flutter/widgets.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import '../../app/env.dart';

/// Inicializa o envio de erros (GlitchTip ou Sentry) e roda o app.
///
/// Sem DSN configurado (padrão em dev), o app roda sem enviar nada.
/// Dados pessoais nunca são anexados aos eventos.
abstract final class ErrorReporting {
  static Future<void> run({
    required AppEnv env,
    required Widget Function() app,
  }) async {
    if (env.sentryDsn.isEmpty) {
      runApp(app());
      return;
    }

    await SentryFlutter.init((options) {
      options
        ..dsn = env.sentryDsn
        ..environment = env.flavor.name
        ..sendDefaultPii = false
        ..attachScreenshot = false
        ..attachViewHierarchy = false
        ..tracesSampleRate = 0;
    }, appRunner: () => runApp(app()));
  }
}
