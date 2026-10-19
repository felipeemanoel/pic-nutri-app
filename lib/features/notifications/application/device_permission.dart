import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/notifications/local_notifications.dart';

/// Permissão de notificações no sistema (separada do histórico: a central
/// funciona mesmo sem ela). Recarregada ao voltar das configurações.
final notificationPermissionProvider = FutureProvider<NotificationPermission>(
  (ref) => ref.watch(localNotificationsProvider).permissionStatus(),
);
