import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../../../core/design/design_system.dart';
import '../../../core/notifications/local_notifications.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/widgets/feedback.dart';
import '../../../shared/widgets/state_views.dart';
import '../../auth/application/session_controller.dart';
import '../application/device_permission.dart';
import '../application/notification_inbox.dart';
import '../application/notification_routes.dart';
import '../data/notification_models.dart';

/// Central de notificações: histórico das mensagens do PicNutri, com lidas
/// e não lidas. Funciona mesmo sem permissão de push no aparelho.
class NotificationsPage extends ConsumerStatefulWidget {
  const NotificationsPage({super.key});

  @override
  ConsumerState<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends ConsumerState<NotificationsPage> {
  final _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    _scroll.addListener(() {
      if (_scroll.position.extentAfter < 400) _loadMore();
    });
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _loadMore() async {
    try {
      await ref.read(notificationInboxProvider.notifier).loadMore();
    } on Object catch (error) {
      if (mounted) showFailure(context, error);
    }
  }

  Future<void> _open(AppNotification n) async {
    unawaited(
      ref
          .read(notificationInboxProvider.notifier)
          .markRead(n.id)
          .catchError((Object _) {}),
    );
    if (n.route == null) return;
    final target = NotificationRoutes.resolve(n.route);
    if (target == AppRoutes.notifications) return;
    if (AppRoutes.isInTabs(target)) {
      context.go(target);
    } else {
      unawaited(context.push(target));
    }
  }

  Future<void> _markAll() async {
    try {
      await ref.read(notificationInboxProvider.notifier).markAllRead();
    } on Object catch (error) {
      if (mounted) showFailure(context, error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final inbox = ref.watch(notificationInboxProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notificações'),
        centerTitle: false,
        actions: [
          IconButton(
            tooltip: 'Configurar notificações',
            icon: const Icon(Icons.tune_rounded),
            onPressed: () => context.push(AppRoutes.notificationSettings),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(notificationInboxProvider.future),
        child: AsyncValueView<InboxState>(
          value: inbox,
          onRetry: () => ref.invalidate(notificationInboxProvider),
          data: (state) => ListView.builder(
            controller: _scroll,
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.only(bottom: Space.xxl),
            itemCount: state.items.length + 2,
            itemBuilder: (context, index) {
              if (index == 0) {
                return _Header(
                  unread: state.unreadCount,
                  empty: state.items.isEmpty,
                  onMarkAll: _markAll,
                );
              }
              if (index == state.items.length + 1) {
                if (state.items.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.only(top: Space.xxl),
                    child: EmptyState(
                      icon: Icons.notifications_none_rounded,
                      title: 'Nenhuma notificação',
                      message:
                          'Mensagens do PicNutri, como novidades e incentivos, aparecem aqui.',
                    ),
                  );
                }
                if (state.loadingMore) {
                  return const Padding(
                    padding: EdgeInsets.all(Space.lg),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                if (state.hasMore) {
                  return Center(
                    child: TextButton(
                      onPressed: _loadMore,
                      child: const Text('Carregar mais'),
                    ),
                  );
                }
                return const SizedBox.shrink();
              }
              final n = state.items[index - 1];
              return Padding(
                padding: const EdgeInsets.fromLTRB(
                  Space.page,
                  0,
                  Space.page,
                  Space.sm,
                ),
                child: _NotificationTile(
                  notification: n,
                  onTap: () => _open(n),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

/// Contador de não lidas e aviso quando o push está desligado.
class _Header extends ConsumerWidget {
  const _Header({
    required this.unread,
    required this.empty,
    required this.onMarkAll,
  });

  final int unread;
  final bool empty;
  final VoidCallback onMarkAll;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final enabled =
        ref.watch(currentAccountProvider)?.profile.notificationsEnabled ??
        false;
    final permission = ref.watch(notificationPermissionProvider).value;
    final pushOff = !enabled || permission == NotificationPermission.denied;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        Space.page,
        Space.md,
        Space.page,
        Space.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Seu acompanhamento, por aqui',
            style: context.text.bodyMedium?.copyWith(
              color: context.pic.textSecondary,
            ),
          ),
          const SizedBox(height: Space.lg),
          if (pushOff) ...[
            StatusBanner(
              tone: BannerTone.info,
              icon: Icons.notifications_off_outlined,
              message:
                  'Você não está recebendo avisos no aparelho, mas as mensagens continuam chegando aqui.',
              actionLabel: 'Configurar',
              onAction: () => context.push(AppRoutes.notificationSettings),
            ),
            const SizedBox(height: Space.md),
          ],
          if (!empty)
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: Space.sm,
              runSpacing: Space.xs,
              children: [
                Semantics(
                  liveRegion: true,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: Space.md,
                      vertical: Space.sm,
                    ),
                    decoration: BoxDecoration(
                      color: context.pic.brandContainer,
                      borderRadius: BorderRadius.circular(Radii.pill),
                    ),
                    child: Text(
                      unread == 0
                          ? 'Tudo lido'
                          : '$unread não lida${unread == 1 ? '' : 's'}',
                      style: context.text.labelMedium?.copyWith(
                        color: context.pic.onBrandContainer,
                      ),
                    ),
                  ),
                ),
                if (unread > 0)
                  TextButton.icon(
                    onPressed: onMarkAll,
                    icon: const Icon(Icons.done_all_rounded, size: 18),
                    label: const Text('Marcar todas como lidas'),
                  ),
              ],
            ),
          const SizedBox(height: Space.sm),
        ],
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({required this.notification, required this.onTap});

  final AppNotification notification;
  final VoidCallback onTap;

  String get _when {
    final d = notification.createdAt;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(d.year, d.month, d.day);
    final date = day == today
        ? 'Hoje'
        : day == today.subtract(const Duration(days: 1))
        ? 'Ontem'
        : Fmt.shortDate(d);
    return '$date, ${Fmt.time(d)}';
  }

  @override
  Widget build(BuildContext context) {
    final unread = !notification.read;
    return Semantics(
      label: unread ? 'Não lida' : null,
      child: Material(
        color: context.colors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Radii.lg),
          side: BorderSide(
            color: unread
                ? context.colors.primary.withValues(alpha: 0.25)
                : context.pic.border,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: Space.lg,
              vertical: Space.lg,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 6, right: Space.md),
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: unread
                          ? context.colors.primary
                          : Colors.transparent,
                    ),
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        notification.title,
                        style: context.text.titleSmall?.copyWith(
                          fontWeight: unread
                              ? FontWeight.w700
                              : FontWeight.w500,
                        ),
                      ),
                      if (notification.body.isNotEmpty) ...[
                        const SizedBox(height: Space.xs),
                        Text(
                          notification.body,
                          style: context.text.bodyMedium?.copyWith(
                            color: context.pic.textSecondary,
                            height: 1.45,
                          ),
                        ),
                      ],
                      const SizedBox(height: Space.md),
                      Text(
                        _when,
                        style: context.text.bodySmall?.copyWith(
                          color: context.pic.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                if (notification.route != null)
                  Padding(
                    padding: const EdgeInsets.only(left: Space.sm, top: 2),
                    child: Icon(
                      Icons.chevron_right,
                      color: context.pic.textSecondary,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
