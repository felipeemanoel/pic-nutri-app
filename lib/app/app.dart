import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/design/theme_preference.dart';
import '../core/notifications/local_notifications.dart';
import '../features/app_update/presentation/app_update_gate.dart';
import '../features/auth/application/session_controller.dart';
import '../shared/widgets/keyboard_dismiss.dart';
import 'env.dart';
import 'router.dart';
import 'theme/app_theme.dart';

class PicNutriApp extends ConsumerWidget {
  const PicNutriApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final env = ref.watch(appEnvProvider);

    // Ao sair da conta, nenhum lembrete do usuário anterior continua no aparelho.
    ref.listen(sessionControllerProvider, (previous, next) {
      if (previous?.value is SessionSignedIn &&
          next.value is SessionSignedOut) {
        ref.read(localNotificationsProvider).cancelAll();
      }
    });

    return MaterialApp.router(
      title: 'PicNutri',
      // Convite para atualizar (ou bloqueio, abaixo da versão mínima) acima
      // de todas as telas.
      builder: (context, child) => AppUpdateGate(
        child: KeyboardDismiss(child: child ?? const SizedBox.shrink()),
      ),
      debugShowCheckedModeBanner: env.isDev,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      routerConfig: ref.watch(routerProvider),
      locale: const Locale('pt', 'BR'),
      supportedLocales: const [Locale('pt', 'BR')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      themeMode: ref.watch(themeModeProvider),
    );
  }
}
