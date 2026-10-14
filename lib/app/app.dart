import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/design/theme_preference.dart';
import '../core/notifications/local_notifications.dart';
import '../features/auth/application/session_controller.dart';
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
