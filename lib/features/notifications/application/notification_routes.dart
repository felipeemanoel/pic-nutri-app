import '../../../app/features.dart';
import '../../../app/routes.dart';

/// Telas que uma notificação pode abrir. Lista fechada (a mesma do painel):
/// rota desconhecida ou ausente abre a central de notificações.
abstract final class NotificationRoutes {
  static const allowed = {
    AppRoutes.home,
    AppRoutes.water,
    AppRoutes.food,
    AppRoutes.newMeal,
    AppRoutes.progress,
    AppRoutes.reports,
    AppRoutes.engagement,
    AppRoutes.assistant,
    AppRoutes.plan,
    AppRoutes.notifications,
    AppRoutes.notificationSettings,
    AppRoutes.help,
  };

  static String resolve(String? route) {
    if (route == null) return AppRoutes.notifications;
    if (allowed.contains(route)) return route;
    if (AppFeatures.medical && route == AppRoutes.contactRequests) return route;
    return AppRoutes.notifications;
  }
}
