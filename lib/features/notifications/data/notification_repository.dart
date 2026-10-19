import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/app_failure.dart';
import '../../../core/network/api_client.dart';
import '../../auth/application/session_controller.dart';
import 'notification_models.dart';

class NotificationRepository {
  const NotificationRepository(this._dio);

  final Dio _dio;

  Future<NotificationPage> list({int page = 1, int perPage = 20}) async {
    final response = await guard(
      () => _dio.get<Map<String, dynamic>>(
        'notifications',
        queryParameters: {'page': page, 'per_page': perPage},
      ),
    );
    return NotificationPage.fromJson(response.data!);
  }

  Future<int> unreadCount() async {
    final response = await guard(
      () => _dio.get<Map<String, dynamic>>('notifications/unread-count'),
    );
    final data = response.data!['data'] as Map<String, dynamic>;
    return (data['unread_count'] as num).toInt();
  }

  Future<void> markRead(String id) =>
      guard(() => _dio.post<void>('notifications/$id/read'));

  /// Aberta pelo push (também conta como lida).
  Future<void> markOpened(String id) =>
      guard(() => _dio.post<void>('notifications/$id/opened'));

  Future<void> markAllRead() =>
      guard(() => _dio.post<void>('notifications/read-all'));

  Future<NotificationPreferences> preferences() async {
    final response = await guard(
      () => _dio.get<Map<String, dynamic>>('notification-preferences'),
    );
    return NotificationPreferences.fromJson(
      response.data!['data'] as Map<String, dynamic>,
    );
  }

  Future<NotificationPreferences> updatePreferences({
    Map<String, bool>? categories,
    bool? quietHoursEnabled,
    String? quietStart,
    String? quietEnd,
  }) async {
    final response = await guard(
      () => _dio.patch<Map<String, dynamic>>(
        'notification-preferences',
        data: {
          'categories': ?categories,
          'quiet_hours_enabled': ?quietHoursEnabled,
          'quiet_start': ?quietStart,
          'quiet_end': ?quietEnd,
        },
      ),
    );
    return NotificationPreferences.fromJson(
      response.data!['data'] as Map<String, dynamic>,
    );
  }
}

/// Conta atual (muda no login/logout): dados de notificação são por conta.
final accountKeyProvider = Provider<String?>(
  (ref) =>
      ref.watch(currentAccountProvider.select((account) => account?.email)),
);

final notificationRepositoryProvider = Provider<NotificationRepository>(
  (ref) => NotificationRepository(ref.watch(dioProvider)),
);

final notificationPreferencesProvider = FutureProvider<NotificationPreferences>(
  (ref) {
    ref.watch(accountKeyProvider);
    return ref.watch(notificationRepositoryProvider).preferences();
  },
);

/// Quantidade de não lidas (sem rede, mostra zero em vez de erro).
final unreadNotificationsProvider = FutureProvider<int>((ref) async {
  if (ref.watch(accountKeyProvider) == null) return 0;
  try {
    return await ref.watch(notificationRepositoryProvider).unreadCount();
  } on AppFailure {
    return 0;
  }
});
