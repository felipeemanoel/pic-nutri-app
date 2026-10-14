import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:mocktail/mocktail.dart';
import 'package:picnutri/app/env.dart';
import 'package:picnutri/core/notifications/local_notifications.dart';
import 'package:picnutri/core/storage/token_storage.dart';
import 'package:picnutri/features/auth/application/session_controller.dart';
import 'package:picnutri/features/auth/data/account.dart';
import 'package:picnutri/features/auth/data/auth_repository.dart';
import 'package:picnutri/features/engagement/data/engagement_models.dart';
import 'package:picnutri/features/engagement/data/engagement_repository.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

/// Armazenamento de token em memória (sem Keychain/Keystore nos testes).
class MemoryTokenStorage implements TokenStorage {
  String? token;
  DateTime? expiresAt;

  @override
  Future<String?> readAccessToken() async => token;

  @override
  Future<DateTime?> readExpiresAt() async => expiresAt;

  @override
  Future<void> writeAccessToken(String value) async => token = value;

  @override
  Future<void> writeSession(String value, DateTime? expires) async {
    token = value;
    expiresAt = expires;
  }

  @override
  Future<void> clear() async {
    token = null;
    expiresAt = null;
  }
}

const testEnv = AppEnv(
  flavor: AppFlavor.dev,
  apiBaseUrl: 'http://localhost:8080',
);

Account testAccount({bool onboarded = true, String name = 'Maria Silva'}) =>
    Account(
      name: name,
      email: 'maria@example.com',
      onboardingCompleted: onboarded,
      consents: const Consents(terms: true, privacy: true, healthData: true),
      profile: Profile(
        goal: 'lose_weight',
        dailyCalorieGoal: 1700,
        waterGoalMl: 2400,
        onboardingCompleted: onboarded,
      ),
    );

/// Sessão fixa para testes de tela.
class FixedSession extends SessionController {
  FixedSession(this.initial);

  final SessionState initial;

  @override
  Future<SessionState> build() async => initial;
}

/// Notificações locais que só registram as chamadas (sem plugin nativo).
class FakeLocalNotifications extends LocalNotifications {
  List<WeeklyNotification> scheduled = [];
  int cancelCalls = 0;
  bool grant = true;

  @override
  Future<bool> requestPermission() async => grant;

  @override
  Future<void> replaceAll(
    List<WeeklyNotification> notifications, {
    required String timezone,
  }) async => scheduled = notifications;

  @override
  Future<void> cancelAll() async {
    cancelCalls++;
    scheduled = [];
  }
}

List<Override> sessionOverrides(SessionState state, {Map<String, dynamic>? engagement}) => [
  appEnvProvider.overrideWithValue(testEnv),
  sessionControllerProvider.overrideWith(() => FixedSession(state)),
  localNotificationsProvider.overrideWithValue(FakeLocalNotifications()),
  // Sem API nos testes: resumo de engajamento vazio.
  engagementProvider.overrideWith((ref) async => Engagement.fromJson(engagement ?? emptyEngagementJson())),
];

Map<String, dynamic> emptyEngagementJson({
  int streak = 0,
  int last7 = 0,
  List<Map<String, dynamic>> achievements = const [],
}) => {
  'streak': {'current': streak, 'best': streak, 'today_logged': streak > 0},
  'consistency': {'last_7_days': last7, 'last_30_days': last7},
  'message': 'Comece com um registro simples.',
  'achievements': achievements,
  'challenges': {
    'active': <Object>[],
    'recent': <Object>[],
    'available': <Object>[],
    'completed_count': 0,
  },
};
