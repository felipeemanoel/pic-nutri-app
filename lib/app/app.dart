import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/design/theme_preference.dart';
import '../core/i18n/app_language.dart';
import '../core/i18n/l10n.dart';
import '../core/i18n/locale_controller.dart';
import '../core/notifications/local_notifications.dart';
import '../core/utils/formatters.dart';
import '../features/app_update/presentation/app_update_gate.dart';
import '../features/auth/application/session_controller.dart';
import '../shared/widgets/keyboard_dismiss.dart';
import 'env.dart';
import 'features.dart';
import 'router.dart';
import 'theme/app_theme.dart';

class PicNutriApp extends ConsumerWidget {
  const PicNutriApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final env = ref.watch(appEnvProvider);
    final chosen = AppFeatures.languages
        ? ref.watch(languageControllerProvider)
        : AppLanguage.ptBR;

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
      builder: (context, child) {
        // Números e datas no idioma da tela (Fmt é usado fora dos widgets).
        Fmt.useLocale(Localizations.localeOf(context));
        return AppUpdateGate(
          child: KeyboardDismiss(child: child ?? const SizedBox.shrink()),
        );
      },
      debugShowCheckedModeBanner: env.isDev,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      routerConfig: ref.watch(routerProvider),
      // Sem escolha (null), segue o idioma do aparelho quando ele está
      // traduzido; senão, português (ver AppLanguage.fromDevice). O Flutter
      // também chama o callback com o idioma escolhido, por isso ele decide
      // pela escolha primeiro.
      locale: chosen?.locale,
      supportedLocales: AppLanguage.supportedLocales,
      localeListResolutionCallback: (locales, supported) =>
          (chosen ?? AppLanguage.fromDevice(locales ?? const [])).locale,
      // Textos do app + Material/Cupertino/Widgets traduzidos.
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      themeMode: ref.watch(themeModeProvider),
    );
  }
}
