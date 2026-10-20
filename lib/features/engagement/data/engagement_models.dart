/// Sequência, consistência, conquistas e desafios (dados da API).
class Engagement {
  const Engagement({
    required this.currentStreak,
    required this.bestStreak,
    required this.todayLogged,
    required this.last7Days,
    required this.last30Days,
    required this.message,
    required this.achievements,
    required this.activeChallenges,
    required this.recentChallenges,
    required this.availableChallenges,
    required this.completedChallenges,
  });

  factory Engagement.fromJson(Map<String, dynamic> json) {
    final streak = json['streak'] as Map<String, dynamic>;
    final consistency = json['consistency'] as Map<String, dynamic>;
    final challenges = json['challenges'] as Map<String, dynamic>;
    List<Map<String, dynamic>> list(Object? v) =>
        (v as List<dynamic>? ?? const []).cast<Map<String, dynamic>>();

    return Engagement(
      currentStreak: (streak['current'] as num).toInt(),
      bestStreak: (streak['best'] as num).toInt(),
      todayLogged: streak['today_logged'] as bool? ?? false,
      last7Days: (consistency['last_7_days'] as num).toInt(),
      last30Days: (consistency['last_30_days'] as num).toInt(),
      message: json['message'] as String? ?? '',
      achievements: list(json['achievements']).map(Achievement.fromJson).toList(),
      activeChallenges: list(challenges['active']).map(Challenge.fromJson).toList(),
      recentChallenges: list(challenges['recent']).map(Challenge.fromJson).toList(),
      availableChallenges: list(
        challenges['available'],
      ).map(ChallengeOption.fromJson).toList(),
      completedChallenges: (challenges['completed_count'] as num?)?.toInt() ?? 0,
    );
  }

  final int currentStreak;
  final int bestStreak;
  final bool todayLogged;
  final int last7Days;
  final int last30Days;
  final String message;
  final List<Achievement> achievements;
  final List<Challenge> activeChallenges;
  final List<Challenge> recentChallenges;
  final List<ChallengeOption> availableChallenges;
  final int completedChallenges;

  List<Achievement> get unlocked => achievements.where((a) => a.achieved).toList();
  List<Achievement> get newlyUnlocked => achievements.where((a) => a.isNew).toList();
}

class Achievement {
  const Achievement({
    required this.code,
    required this.title,
    required this.description,
    required this.icon,
    required this.achieved,
    required this.isNew,
    this.achievedAt,
  });

  factory Achievement.fromJson(Map<String, dynamic> json) => Achievement(
    code: json['code'] as String,
    title: json['title'] as String? ?? '',
    description: json['description'] as String? ?? '',
    icon: json['icon'] as String? ?? '',
    achieved: json['achieved'] as bool? ?? false,
    isNew: json['is_new'] as bool? ?? false,
    achievedAt: DateTime.tryParse(json['achieved_at'] as String? ?? '')?.toLocal(),
  );

  final String code;
  final String title;
  final String description;

  /// Nome do ícone (Material) sugerido pela API.
  final String icon;
  final bool achieved;
  final bool isNew;
  final DateTime? achievedAt;
}

class Challenge {
  const Challenge({
    required this.id,
    required this.code,
    required this.title,
    required this.description,
    required this.status,
    required this.progress,
    required this.target,
    required this.startsOn,
    required this.endsOn,
  });

  factory Challenge.fromJson(Map<String, dynamic> json) => Challenge(
    id: json['id'] as String,
    code: json['code'] as String,
    title: json['title'] as String? ?? '',
    description: json['description'] as String? ?? '',
    status: json['status'] as String? ?? 'active',
    progress: (json['progress'] as num?)?.toInt() ?? 0,
    target: (json['target'] as num?)?.toInt() ?? 1,
    startsOn: json['starts_on'] as String? ?? '',
    endsOn: json['ends_on'] as String? ?? '',
  );

  final String id;
  final String code;
  final String title;
  final String description;

  /// active, completed, expired ou abandoned.
  final String status;
  final int progress;
  final int target;

  /// Datas locais "AAAA-MM-DD".
  final String startsOn;
  final String endsOn;

  double get ratio => target <= 0 ? 0 : (progress / target).clamp(0, 1).toDouble();
  bool get isCompleted => status == 'completed';
}

class ChallengeOption {
  const ChallengeOption({
    required this.code,
    required this.title,
    required this.description,
    required this.target,
  });

  factory ChallengeOption.fromJson(Map<String, dynamic> json) => ChallengeOption(
    code: json['code'] as String,
    title: json['title'] as String? ?? '',
    description: json['description'] as String? ?? '',
    target: (json['target'] as num?)?.toInt() ?? 1,
  );

  final String code;
  final String title;
  final String description;
  final int target;
}

/// Celebração pendente: conquista nova ou meta do dia (água, proteína).
/// Cada uma aparece uma única vez (o servidor guarda o que já foi visto).
class Celebration {
  const Celebration({required this.key, required this.kind, required this.title, required this.message, required this.icon});

  factory Celebration.fromJson(Map<String, dynamic> json) => Celebration(
    key: json['key'] as String,
    kind: json['kind'] as String? ?? 'achievement',
    title: json['title'] as String? ?? '',
    message: json['message'] as String? ?? '',
    icon: json['icon'] as String? ?? 'star',
  );

  final String key;

  /// `achievement`, `water_goal` ou `protein_goal`.
  final String kind;
  final String title;
  final String message;
  final String icon;
}
