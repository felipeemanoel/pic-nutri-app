import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/design/design_system.dart';
import '../../core/notifications/local_notifications.dart';
import '../../core/notifications/push_messaging.dart';
import '../../features/auth/application/session_controller.dart';
import '../../features/plan/application/store_purchases.dart';
import '../../features/reminders/application/reminder_scheduler.dart';
import '../features.dart';

/// Navegação principal: Início, Alimentação, Evolução, Assistente e
/// Profissionais. O Perfil abre pelo avatar no topo de cada aba.
class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key, required this.shell});

  final StatefulNavigationShell shell;

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  StreamSubscription<String>? _taps;

  @override
  void initState() {
    super.initState();
    // Toque em notificação: abre a tela relacionada ao lembrete.
    _taps = ref.read(localNotificationsProvider).taps.listen((route) {
      if (mounted && route.startsWith('/')) context.go(route);
    });
    // Ao entrar no app, alinha as notificações do aparelho com os lembretes da conta.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(ref.read(reminderSchedulerProvider).sync());
      // Push do servidor (se configurado), conforme a preferência do perfil.
      final enabled = ref.read(currentAccountProvider)?.profile.notificationsEnabled ?? false;
      final push = ref.read(pushMessagingProvider);
      unawaited(enabled ? push.enable() : push.disable());
      // Compras de assinatura pendentes (ex.: app fechado durante a compra).
      ref.read(storePurchasesProvider).listen();
    });
  }

  @override
  void dispose() {
    _taps?.cancel();
    super.dispose();
  }

  static final _destinations = <NavigationDestination>[
    const NavigationDestination(
      icon: Icon(Icons.home_outlined),
      selectedIcon: Icon(Icons.home),
      label: 'Início',
    ),
    const NavigationDestination(
      icon: Icon(Icons.restaurant_menu_outlined),
      selectedIcon: Icon(Icons.restaurant_menu),
      label: 'Alimentação',
    ),
    const NavigationDestination(
      icon: Icon(Icons.insights_outlined),
      selectedIcon: Icon(Icons.insights),
      label: 'Evolução',
    ),
    const NavigationDestination(
      icon: Icon(Icons.auto_awesome_outlined),
      selectedIcon: Icon(Icons.auto_awesome),
      label: 'Assistente',
    ),
    if (AppFeatures.medical) const NavigationDestination(
      icon: Icon(Icons.groups_outlined),
      selectedIcon: Icon(Icons.groups),
      label: 'Profissionais',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final shell = widget.shell;
    return Scaffold(
      body: shell,
      bottomNavigationBar: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: context.pic.border)),
        ),
        child: NavigationBar(
        selectedIndex: shell.currentIndex,
        destinations: _destinations,
        onDestinationSelected: (index) =>
            shell.goBranch(index, initialLocation: index == shell.currentIndex),
        ),
      ),
    );
  }
}
