/// Mensagem da central de notificações (enviada pelo servidor).
class AppNotification {
  const AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.category,
    required this.read,
    required this.createdAt,
    this.route,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) =>
      AppNotification(
        id: json['id'] as String,
        title: json['title'] as String,
        body: json['body'] as String? ?? '',
        category: json['category'] as String? ?? 'system',
        route: json['route'] as String?,
        read: json['read'] as bool? ?? false,
        createdAt: DateTime.parse(json['created_at'] as String).toLocal(),
      );

  final String id;
  final String title;
  final String body;
  final String category;

  /// Tela aberta ao tocar (validada por [NotificationRoutes]).
  final String? route;
  final bool read;
  final DateTime createdAt;

  AppNotification markedRead() => AppNotification(
    id: id,
    title: title,
    body: body,
    category: category,
    route: route,
    read: true,
    createdAt: createdAt,
  );
}

/// Uma página da central.
class NotificationPage {
  const NotificationPage({
    required this.items,
    required this.page,
    required this.lastPage,
    required this.unreadCount,
  });

  factory NotificationPage.fromJson(Map<String, dynamic> json) {
    final meta = json['meta'] as Map<String, dynamic>? ?? const {};
    return NotificationPage(
      items: (json['data'] as List<dynamic>)
          .cast<Map<String, dynamic>>()
          .map(AppNotification.fromJson)
          .toList(),
      page: (meta['current_page'] as num?)?.toInt() ?? 1,
      lastPage: (meta['last_page'] as num?)?.toInt() ?? 1,
      unreadCount: (meta['unread_count'] as num?)?.toInt() ?? 0,
    );
  }

  final List<AppNotification> items;
  final int page;
  final int lastPage;
  final int unreadCount;

  bool get hasMore => page < lastPage;
}

/// Categoria de notificação que o usuário liga ou desliga.
class NotificationCategoryPref {
  const NotificationCategoryPref({
    required this.key,
    required this.label,
    required this.enabled,
    required this.localReminders,
  });

  factory NotificationCategoryPref.fromJson(Map<String, dynamic> json) =>
      NotificationCategoryPref(
        key: json['key'] as String,
        label: json['label'] as String? ?? json['key'] as String,
        enabled: json['enabled'] as bool? ?? true,
        localReminders: json['local_reminders'] as bool? ?? false,
      );

  final String key;
  final String label;
  final bool enabled;

  /// Lembretes com horário definido pelo usuário (notificações locais).
  final bool localReminders;
}

/// Preferências de notificação: categorias e período de silêncio.
class NotificationPreferences {
  const NotificationPreferences({
    required this.categories,
    this.quietHoursEnabled = false,
    this.quietStart,
    this.quietEnd,
  });

  factory NotificationPreferences.fromJson(Map<String, dynamic> json) =>
      NotificationPreferences(
        categories: (json['categories'] as List<dynamic>)
            .cast<Map<String, dynamic>>()
            .map(NotificationCategoryPref.fromJson)
            .toList(),
        quietHoursEnabled: json['quiet_hours_enabled'] as bool? ?? false,
        quietStart: json['quiet_start'] as String?,
        quietEnd: json['quiet_end'] as String?,
      );

  final List<NotificationCategoryPref> categories;
  final bool quietHoursEnabled;

  /// "HH:MM" no fuso do perfil.
  final String? quietStart;
  final String? quietEnd;

  /// Categoria ausente (ex.: app mais novo que a API) conta como ligada.
  bool allows(String category) =>
      categories.where((c) => c.key == category).firstOrNull?.enabled ?? true;

  /// O horário "HH:MM" cai no período de silêncio? (pode atravessar a meia-noite)
  bool isQuiet(int hour, int minute) {
    final start = _minutes(quietStart);
    final end = _minutes(quietEnd);
    if (!quietHoursEnabled || start == null || end == null || start == end) {
      return false;
    }
    final m = hour * 60 + minute;
    return start < end ? m >= start && m < end : m >= start || m < end;
  }

  static int? _minutes(String? hhmm) {
    if (hhmm == null || hhmm.length < 5) return null;
    return int.parse(hhmm.substring(0, 2)) * 60 +
        int.parse(hhmm.substring(3, 5));
  }
}
