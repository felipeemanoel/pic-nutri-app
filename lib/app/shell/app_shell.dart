import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/design/design_system.dart';
import '../../core/notifications/local_notifications.dart';
import '../../core/notifications/push_messaging.dart';
import '../../features/auth/application/session_controller.dart';
import '../../features/auth/data/auth_repository.dart';
import '../../features/engagement/data/engagement_repository.dart';
import '../../features/engagement/presentation/celebrations.dart';
import '../../features/intro_tour/data/intro_tour_store.dart';
import '../../features/notifications/application/device_permission.dart';
import '../../features/notifications/application/notification_inbox.dart';
import '../../features/notifications/application/notification_routes.dart';
import '../../features/notifications/data/notification_repository.dart';
import '../../features/plan/application/store_purchases.dart';
import '../../features/reminders/application/reminder_scheduler.dart';
import '../../shared/widgets/account_avatar.dart';
import '../routes.dart';

/// Navegação principal: Início, Alimentação, Evolução, Conteúdo e Perfil.
class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key, required this.shell});

  final StatefulNavigationShell shell;

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell>
    with WidgetsBindingObserver {
  StreamSubscription<NotificationTap>? _taps;
  StreamSubscription<void>? _received;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Toque em notificação: marca como aberta e abre a tela relacionada.
    _taps = ref.read(localNotificationsProvider).taps.listen(_openTap);
    // Push recebido com o app aberto: atualiza a central e o contador.
    _received = ref
        .read(pushMessagingProvider)
        .received
        .listen((_) => _refreshInbox());
    // Ao entrar no app, alinha as notificações do aparelho com os lembretes da conta.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(ref.read(localNotificationsProvider).ensureInitialized());
      unawaited(ref.read(reminderSchedulerProvider).sync());
      // Push do servidor (se configurado), conforme a preferência do perfil.
      final enabled =
          ref.read(currentAccountProvider)?.profile.notificationsEnabled ??
          false;
      final push = ref.read(pushMessagingProvider);
      unawaited(enabled ? push.enable() : push.disable());
      // Compras de assinatura pendentes (ex.: app fechado durante a compra).
      ref.read(storePurchasesProvider).listen();
      _maybeShowIntroTour();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _taps?.cancel();
    _received?.cancel();
    super.dispose();
  }

  /// De volta ao app: a API registra o uso (e reavalia os avisos de
  /// inatividade); o contador e os lembretes condicionais são atualizados.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;
    _refreshInbox();
    ref.invalidate(celebrationsProvider);
    unawaited(ref.read(reminderSchedulerProvider).sync());
  }

  bool _tourShown = false;

  /// Recibo local impede reapresentação mesmo se a API estiver indisponível.
  Future<void> _maybeShowIntroTour() async {
    final account = ref.read(currentAccountProvider);
    if (account == null || _tourShown || !mounted) return;
    _tourShown = true;
    final store = ref.read(introTourStoreProvider);
    final repository = ref.read(authRepositoryProvider);
    final show = await store.shouldShow(account);
    if (!mounted || ref.read(currentAccountProvider)?.email != account.email) {
      return;
    }
    if (show) {
      await context.push(AppRoutes.introTour);
    } else if (account.introTourPending) {
      unawaited(store.sync(account.email, repository));
    }
  }

  void _refreshInbox() {
    if (!mounted) return;
    ref
      ..invalidate(unreadNotificationsProvider)
      ..invalidate(notificationInboxProvider)
      ..invalidate(notificationPermissionProvider);
  }

  void _openTap(NotificationTap tap) {
    final id = tap.notificationId;
    if (id != null) {
      unawaited(
        ref
            .read(notificationRepositoryProvider)
            .markOpened(id)
            .then((_) => _refreshInbox(), onError: (Object _) {}),
      );
    }
    // Lembrete local sem rota: fica onde está. Mensagem do servidor sem rota (ou desconhecida): central.
    if (!mounted || (id == null && tap.route == null)) return;
    final target = NotificationRoutes.resolve(tap.route);
    // Telas das abas trocam de aba; as de fora (Perfil, Profissionais,
    // notificações) empilham, para o "voltar" funcionar.
    if (AppRoutes.isInTabs(target)) {
      context.go(target);
    } else {
      context.push(target);
    }
  }

  static const _destinations = <NavigationDestination>[
    NavigationDestination(
      icon: Icon(Icons.home_outlined),
      selectedIcon: Icon(Icons.home),
      label: 'Início',
    ),
    NavigationDestination(
      icon: Icon(Icons.restaurant_menu_outlined),
      selectedIcon: Icon(Icons.restaurant_menu),
      label: 'Alimentação',
    ),
    NavigationDestination(
      icon: Icon(Icons.insights_outlined),
      selectedIcon: Icon(Icons.insights),
      label: 'Evolução',
    ),
    NavigationDestination(
      icon: Icon(Icons.auto_stories_outlined),
      selectedIcon: Icon(Icons.auto_stories),
      label: 'Conteúdo',
    ),
    NavigationDestination(
      icon: AccountAvatar(size: 24),
      selectedIcon: AccountAvatar(size: 24),
      label: 'Perfil',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final shell = widget.shell;
    return Scaffold(
      body: CelebrationHost(child: shell),
      bottomNavigationBar: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: context.pic.border)),
        ),
        child: NavigationBar(
          selectedIndex: shell.currentIndex,
          destinations: _destinations,
          onDestinationSelected: (index) => shell.goBranch(
            index,
            initialLocation: index == shell.currentIndex,
          ),
        ),
      ),
    );
  }
}
