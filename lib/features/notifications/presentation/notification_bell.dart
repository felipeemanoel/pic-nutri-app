import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../../../core/i18n/l10n.dart';
import '../data/notification_repository.dart';

/// Sino do topo com a quantidade de notificações não lidas.
class NotificationBell extends ConsumerWidget {
  const NotificationBell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unread = ref.watch(unreadNotificationsProvider).value ?? 0;
    final label = unread == 0
        ? context.l10n.notificationsTitle
        : context.l10n.notificationsUnread(unread);
    return IconButton(
      tooltip: label,
      onPressed: () => context.push(AppRoutes.notifications),
      icon: Badge(
        isLabelVisible: unread > 0,
        label: Text(unread > 99 ? '99+' : '$unread'),
        child: Icon(
          unread > 0
              ? Icons.notifications_rounded
              : Icons.notifications_none_rounded,
        ),
      ),
    );
  }
}
