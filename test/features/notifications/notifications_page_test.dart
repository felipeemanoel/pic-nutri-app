import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnutri/features/auth/application/session_controller.dart';
import 'package:picnutri/features/notifications/data/notification_models.dart';
import 'package:picnutri/features/notifications/data/notification_repository.dart';
import 'package:picnutri/features/notifications/presentation/notifications_page.dart';

import '../../helpers/fakes.dart';

/// Central em memória: 25 mensagens, as 3 primeiras não lidas.
class FakeNotificationRepository extends NotificationRepository {
  FakeNotificationRepository({int total = 25}) : super(Dio()) {
    items = [
      for (var i = 0; i < total; i++)
        AppNotification(
          id: 'n$i',
          title: 'Mensagem $i',
          body: 'Texto $i',
          category: 'announcements',
          read: i >= 3,
          createdAt: DateTime(2026, 10, 19, 10).subtract(Duration(hours: i)),
          route: i == 0 ? '/food' : null,
        ),
    ];
  }

  late List<AppNotification> items;
  final read = <String>[];
  final pages = <int>[];
  int get pagesLoaded => pages.length;

  int get _unread => items.where((n) => !n.read).length;

  @override
  Future<NotificationPage> list({int page = 1, int perPage = 20}) async {
    pages.add(page);
    final start = (page - 1) * perPage;
    return NotificationPage(
      items: items.skip(start).take(perPage).toList(),
      page: page,
      lastPage: (items.length / perPage).ceil().clamp(1, 999),
      unreadCount: _unread,
    );
  }

  @override
  Future<int> unreadCount() async => _unread;

  @override
  Future<void> markRead(String id) async {
    read.add(id);
    items = [for (final n in items) n.id == id ? n.markedRead() : n];
  }

  @override
  Future<void> markAllRead() async =>
      items = [for (final n in items) n.markedRead()];
}

Widget _app(
  FakeNotificationRepository repo, {
  bool notificationsEnabled = true,
}) => ProviderScope(
  overrides: [
    ...sessionOverrides(
      SessionSignedIn(testAccount(notificationsEnabled: notificationsEnabled)),
    ),
    notificationRepositoryProvider.overrideWithValue(repo),
  ],
  child: const MaterialApp(home: NotificationsPage()),
);

void main() {
  testWidgets('lista mensagens, mostra não lidas e marca todas como lidas', (
    tester,
  ) async {
    final repo = FakeNotificationRepository();
    await tester.pumpWidget(_app(repo));
    await tester.pumpAndSettle();

    expect(find.text('Mensagem 0'), findsOneWidget);
    expect(find.text('3 não lidas'), findsOneWidget);
    expect(find.bySemanticsLabel(RegExp('Não lida')), findsNWidgets(3));

    await tester.tap(find.text('Marcar todas como lidas'));
    await tester.pumpAndSettle();

    expect(find.text('Tudo lido'), findsOneWidget);
    expect(find.text('Marcar todas como lidas'), findsNothing);
  });

  testWidgets('tocar numa mensagem sem destino só marca como lida', (
    tester,
  ) async {
    final repo = FakeNotificationRepository();
    await tester.pumpWidget(_app(repo));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Mensagem 1'));
    await tester.pumpAndSettle();

    expect(repo.read, ['n1']);
    expect(find.text('2 não lidas'), findsOneWidget);
  });

  testWidgets('carrega a próxima página ao rolar', (tester) async {
    final repo = FakeNotificationRepository();
    await tester.pumpWidget(_app(repo));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(find.text('Mensagem 24'), 300);
    await tester.pumpAndSettle();

    expect(find.text('Mensagem 24'), findsOneWidget);
    expect(repo.pages, [1, 2], reason: '${repo.pages}');
  });

  testWidgets('sem mensagens e sem push, mostra estado vazio e o aviso', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(FakeNotificationRepository(total: 0), notificationsEnabled: false),
    );
    await tester.pumpAndSettle();

    expect(find.text('Nenhuma notificação'), findsOneWidget);
    expect(
      find.textContaining('mas as mensagens continuam chegando aqui'),
      findsOneWidget,
    );
  });
}
