import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/app_failure.dart';
import '../../../core/network/api_client.dart';
import '../../auth/application/session_controller.dart';

/// Progresso calculado no servidor: abrir ou atualizar a tela não duplica estrelas.
class DailyMissions {
  const DailyMissions({
    required this.streak,
    required this.bestStreak,
    required this.streakBroken,
    required this.missions,
  });

  factory DailyMissions.fromJson(Map<String, dynamic> json) => DailyMissions(
    streak: (json['current_streak'] as num).toInt(),
    bestStreak: (json['best_streak'] as num).toInt(),
    streakBroken: json['streak_broken'] as bool? ?? false,
    missions: (json['missions'] as List<dynamic>)
        .map((m) => DailyMission.fromJson(m as Map<String, dynamic>))
        .toList(),
  );

  final int streak;
  final int bestStreak;
  final bool streakBroken;
  final List<DailyMission> missions;
  int get stars => missions.where((m) => m.completed).length;
  MissionLevel get level => MissionLevel.forDays(streak);
  MissionLevel? get nextLevel =>
      MissionLevel.values.where((level) => level.days > streak).firstOrNull;
}

class DailyMission {
  const DailyMission({
    required this.code,
    required this.title,
    required this.completed,
  });
  factory DailyMission.fromJson(Map<String, dynamic> json) => DailyMission(
    code: json['code'] as String,
    title: json['title'] as String,
    completed: json['completed'] as bool,
  );
  final String code;
  final String title;
  final bool completed;
}

enum MissionLevel {
  beginner('Começo', 0),
  bronze('Bronze', 3),
  silver('Prata', 10),
  gold('Ouro', 30),
  diamond('Diamante', 100);

  const MissionLevel(this.label, this.days);
  final String label;
  final int days;
  static MissionLevel forDays(int days) =>
      values.lastWhere((l) => days >= l.days);
}

final dailyMissionsProvider = FutureProvider.autoDispose<DailyMissions>((
  ref,
) async {
  ref.watch(sessionScopeProvider);
  final dio = ref.watch(dioProvider);
  final response = await guard(
    () => dio.post<Map<String, dynamic>>(
      'engagement/daily-missions/visit',
      data: {'utc_offset_minutes': DateTime.now().timeZoneOffset.inMinutes},
    ),
  );
  return DailyMissions.fromJson(response.data!['data'] as Map<String, dynamic>);
});
