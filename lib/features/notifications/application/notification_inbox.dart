import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/notification_models.dart';
import '../data/notification_repository.dart';

/// Estado da central: mensagens carregadas até agora e paginação.
class InboxState {
  const InboxState({
    required this.items,
    required this.page,
    required this.hasMore,
    required this.unreadCount,
    this.loadingMore = false,
  });

  final List<AppNotification> items;
  final int page;
  final bool hasMore;
  final int unreadCount;
  final bool loadingMore;

  InboxState copyWith({
    List<AppNotification>? items,
    int? page,
    bool? hasMore,
    int? unreadCount,
    bool? loadingMore,
  }) => InboxState(
    items: items ?? this.items,
    page: page ?? this.page,
    hasMore: hasMore ?? this.hasMore,
    unreadCount: unreadCount ?? this.unreadCount,
    loadingMore: loadingMore ?? this.loadingMore,
  );
}

/// Central de notificações com carregamento por páginas.
class NotificationInbox extends AsyncNotifier<InboxState> {
  static const perPage = 20;

  NotificationRepository get _repository =>
      ref.read(notificationRepositoryProvider);

  @override
  Future<InboxState> build() async {
    // Sem conta (sessão carregando ou encerrada): nada a buscar.
    if (ref.watch(accountKeyProvider) == null) {
      return const InboxState(
        items: [],
        page: 1,
        hasMore: false,
        unreadCount: 0,
      );
    }
    final first = await ref
        .watch(notificationRepositoryProvider)
        .list(perPage: perPage);
    return InboxState(
      items: first.items,
      page: first.page,
      hasMore: first.hasMore,
      unreadCount: first.unreadCount,
    );
  }

  Future<void> loadMore() async {
    final current = state.value;
    if (current == null || !current.hasMore || current.loadingMore) return;
    state = AsyncData(current.copyWith(loadingMore: true));
    try {
      final next = await _repository.list(
        page: current.page + 1,
        perPage: perPage,
      );
      final known = {for (final n in current.items) n.id};
      state = AsyncData(
        current.copyWith(
          // Mensagens novas deslocam as páginas: ignora repetidas.
          items: [
            ...current.items,
            ...next.items.where((n) => !known.contains(n.id)),
          ],
          page: next.page,
          hasMore: next.hasMore,
          unreadCount: next.unreadCount,
          loadingMore: false,
        ),
      );
    } on Object {
      state = AsyncData(current.copyWith(loadingMore: false));
      rethrow;
    }
  }

  Future<void> markRead(String id) async {
    final current = state.value;
    final target = current?.items.where((n) => n.id == id).firstOrNull;
    if (current == null || target == null || target.read) return;
    await _repository.markRead(id);
    state = AsyncData(
      current.copyWith(
        items: [for (final n in current.items) n.id == id ? n.markedRead() : n],
        unreadCount: current.unreadCount > 0 ? current.unreadCount - 1 : 0,
      ),
    );
    ref.invalidate(unreadNotificationsProvider);
  }

  Future<void> markAllRead() async {
    final current = state.value;
    if (current == null) return;
    await _repository.markAllRead();
    state = AsyncData(
      current.copyWith(
        items: [for (final n in current.items) n.markedRead()],
        unreadCount: 0,
      ),
    );
    ref.invalidate(unreadNotificationsProvider);
  }
}

final notificationInboxProvider =
    AsyncNotifierProvider<NotificationInbox, InboxState>(NotificationInbox.new);
