import 'package:flutter_test/flutter_test.dart';
import 'package:picnutri/app/routes.dart';
import 'package:picnutri/core/notifications/local_notifications.dart';
import 'package:picnutri/features/notifications/application/notification_routes.dart';
import 'package:picnutri/features/notifications/data/notification_models.dart';

void main() {
  test('lê a página da central com contador e paginação', () {
    final page = NotificationPage.fromJson({
      'data': [
        {
          'id': '01JNOTIF',
          'title': 'Novidade',
          'body': 'Planeje a semana.',
          'category': 'announcements',
          'route': '/food',
          'read': false,
          'read_at': null,
          'created_at': '2026-10-19T12:00:00-03:00',
        },
      ],
      'meta': {
        'current_page': 1,
        'last_page': 3,
        'total': 45,
        'unread_count': 7,
      },
    });

    expect(page.items.single.title, 'Novidade');
    expect(page.items.single.read, isFalse);
    expect(page.items.single.markedRead().read, isTrue);
    expect(page.hasMore, isTrue);
    expect(page.unreadCount, 7);
  });

  test(
    'preferências: categorias e período de silêncio que atravessa a meia-noite',
    () {
      final prefs = NotificationPreferences.fromJson({
        'categories': [
          {
            'key': 'water',
            'label': 'Beber água',
            'enabled': false,
            'local_reminders': true,
          },
          {
            'key': 'announcements',
            'label': 'Comunicados',
            'enabled': true,
            'local_reminders': false,
          },
        ],
        'quiet_hours_enabled': true,
        'quiet_start': '22:00',
        'quiet_end': '07:00',
      });

      expect(prefs.allows('water'), isFalse);
      expect(prefs.allows('announcements'), isTrue);
      expect(prefs.allows('categoria_nova'), isTrue);
      expect(prefs.isQuiet(23, 30), isTrue);
      expect(prefs.isQuiet(6, 59), isTrue);
      expect(prefs.isQuiet(7, 0), isFalse);
      expect(prefs.isQuiet(12, 0), isFalse);
    },
  );

  test(
    'toque guarda rota e id da mensagem; lembrete antigo guarda só a rota',
    () {
      final tap = NotificationTap.parse(
        NotificationTap.encode(route: '/food', notificationId: '01JX'),
      );
      expect(tap?.route, '/food');
      expect(tap?.notificationId, '01JX');

      expect(NotificationTap.parse('/home/water')?.route, '/home/water');
      expect(NotificationTap.parse('lixo'), isNull);
    },
  );

  test('só abre telas da lista; o resto vai para a central', () {
    expect(NotificationRoutes.resolve('/home/water'), AppRoutes.water);
    expect(
      NotificationRoutes.resolve('/profile/notifications'),
      AppRoutes.notificationSettings,
    );
    expect(
      NotificationRoutes.resolve('https://site.com'),
      AppRoutes.notifications,
    );
    expect(
      NotificationRoutes.resolve('/profile/privacy'),
      AppRoutes.notifications,
    );
    expect(NotificationRoutes.resolve(null), AppRoutes.notifications);
  });
}
