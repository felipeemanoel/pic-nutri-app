import '../../../app/features.dart';
import '../../../core/utils/formatters.dart';

/// Conta autenticada, como devolvida por `GET /me`.
class Account {
  const Account({
    required this.name,
    required this.email,
    required this.onboardingCompleted,
    required this.consents,
    required this.profile,
    this.avatarVersion,
    this.onboardingStep,
    this.onboardingSkipped = const [],
    this.introTourPending = false,
  });

  factory Account.fromJson(Map<String, dynamic> json) => Account(
    avatarVersion: json['avatar_version'] as String?,
    name: json['name'] as String? ?? '',
    email: json['email'] as String? ?? '',
    onboardingCompleted: json['onboarding_completed'] as bool? ?? false,
    consents: Consents.fromJson(
      json['consents'] as Map<String, dynamic>? ?? const {},
    ),
    profile: Profile.fromJson(
      json['profile'] as Map<String, dynamic>? ?? const {},
    ),
    onboardingStep:
        (json['onboarding'] as Map<String, dynamic>?)?['step'] as String?,
    onboardingSkipped:
        ((json['onboarding'] as Map<String, dynamic>?)?['skipped']
                    as List<dynamic>? ??
                const [])
            .whereType<String>()
            .toList(),
    introTourPending:
        (json['onboarding'] as Map<String, dynamic>?)?['intro_tour_pending']
            as bool? ??
        false,
  );

  final String? avatarVersion;
  final String name;
  final String email;
  final bool onboardingCompleted;
  final Consents consents;
  final Profile profile;

  /// Etapa do onboarding em que a pessoa parou (null = não iniciado ou concluído).
  final String? onboardingStep;

  /// Etapas puladas para completar depois.
  final List<String> onboardingSkipped;

  /// Primeira visita guiada ainda não concluída nem dispensada (mostrada uma vez por conta).
  final bool introTourPending;

  String get firstName => name.trim().split(RegExp(r'\s+')).first;
}

class Consents {
  const Consents({
    required this.terms,
    required this.privacy,
    required this.healthData,
  });

  factory Consents.fromJson(Map<String, dynamic> json) => Consents(
    terms: json['terms'] as bool? ?? false,
    privacy: json['privacy'] as bool? ?? false,
    healthData: json['health_data'] as bool? ?? false,
  );

  final bool terms;
  final bool privacy;
  final bool healthData;
}

/// Perfil nutricional. Campos ausentes significam "não informado".
class Profile {
  const Profile({
    this.birthDate,
    this.age,
    this.sex,
    this.heightCm,
    this.currentWeightKg,
    this.goal,
    this.goals = const [],
    this.supportPreferences = const [],
    this.professionalGuidance,
    this.professionalGuidanceSource,
    this.careCategories = const [],
    this.careModality,
    this.careCity,
    this.careState,
    this.goalWeightKg,
    this.activityLevel,
    this.dietaryPreferences = const [],
    this.dietaryRestrictions,
    this.allergies = const [],
    this.avoidFoods,
    this.plannedMeals = const ['breakfast', 'lunch', 'dinner'],
    this.dailyCalorieGoal,
    this.proteinGoalG,
    this.carbsGoalG,
    this.fatGoalG,
    this.waterGoalMl = 2000,
    this.timezone = 'America/Sao_Paulo',
    this.notificationsEnabled = false,
    this.medicationTrackingEnabled = false,
    this.onboardingCompleted = false,
  });

  factory Profile.fromJson(Map<String, dynamic> json) => Profile(
    birthDate: DateTime.tryParse(json['birth_date'] as String? ?? ''),
    age: toInt(json['age']),
    sex: json['sex'] as String?,
    heightCm: toDouble(json['height_cm']),
    currentWeightKg: toDouble(json['current_weight_kg']),
    goal: json['goal'] as String?,
    goals: (json['goals'] as List<dynamic>? ?? const [])
        .whereType<String>()
        .toList(),
    supportPreferences:
        (json['support_preferences'] as List<dynamic>? ?? const [])
            .whereType<String>()
            .toList(),
    professionalGuidance: json['professional_guidance'] as String?,
    professionalGuidanceSource: json['professional_guidance_source'] as String?,
    careCategories:
        ((json['care_preferences'] as Map<String, dynamic>?)?['categories']
                    as List<dynamic>? ??
                const [])
            .whereType<String>()
            .toList(),
    careModality:
        (json['care_preferences'] as Map<String, dynamic>?)?['modality']
            as String?,
    careCity:
        (json['care_preferences'] as Map<String, dynamic>?)?['city'] as String?,
    careState:
        (json['care_preferences'] as Map<String, dynamic>?)?['state']
            as String?,
    goalWeightKg: toDouble(json['goal_weight_kg']),
    activityLevel: json['activity_level'] as String?,
    dietaryPreferences: (json['dietary_preferences'] as List<dynamic>? ?? [])
        .whereType<String>()
        .toList(),
    dietaryRestrictions: json['dietary_restrictions'] as String?,
    allergies: (json['allergies'] as List<dynamic>? ?? [])
        .whereType<String>()
        .toList(),
    avoidFoods: json['avoid_foods'] as String?,
    plannedMeals:
        (json['planned_meals'] as List<dynamic>? ??
                const ['breakfast', 'lunch', 'dinner'])
            .whereType<String>()
            .toList(),
    dailyCalorieGoal: toInt(json['daily_calorie_goal']),
    proteinGoalG: toInt(json['protein_goal_g']),
    carbsGoalG: toInt(json['carbs_goal_g']),
    fatGoalG: toInt(json['fat_goal_g']),
    waterGoalMl: toInt(json['water_goal_ml']) ?? 2000,
    timezone: json['timezone'] as String? ?? 'America/Sao_Paulo',
    notificationsEnabled: json['notifications_enabled'] as bool? ?? false,
    medicationTrackingEnabled:
        AppFeatures.medical &&
        (json['medication_tracking_enabled'] as bool? ?? false),
    onboardingCompleted: json['onboarding_completed'] as bool? ?? false,
  );

  final DateTime? birthDate;
  final int? age;
  final String? sex;
  final double? heightCm;
  final double? currentWeightKg;
  final String? goal;

  /// Objetivos escolhidos; o primeiro é o principal ([goal]).
  final List<String> goals;

  /// Como a pessoa quer ser acompanhada (organize_eating, has_professional_plan, ...).
  final List<String> supportPreferences;
  final String? professionalGuidance;
  final String? professionalGuidanceSource;

  /// Preferências para encontrar profissionais.
  final List<String> careCategories;
  final String? careModality;
  final String? careCity;
  final String? careState;
  final double? goalWeightKg;
  final String? activityLevel;
  final List<String> dietaryPreferences;
  final String? dietaryRestrictions;
  final List<String> allergies;
  final String? avoidFoods;

  /// Refeições que o usuário costuma fazer (para avisar das pendentes).
  final List<String> plannedMeals;
  final int? dailyCalorieGoal;
  final int? proteinGoalG;
  final int? carbsGoalG;
  final int? fatGoalG;
  final int waterGoalMl;
  final String timezone;
  final bool notificationsEnabled;
  final bool medicationTrackingEnabled;
  final bool onboardingCompleted;
}

/// Resposta de login/cadastro/renovação.
class AuthSession {
  const AuthSession({
    required this.token,
    required this.expiresAt,
    required this.account,
  });

  factory AuthSession.fromJson(Map<String, dynamic> json) => AuthSession(
    token: json['token'] as String,
    expiresAt: DateTime.tryParse(json['expires_at'] as String? ?? '')?.toUtc(),
    account: Account.fromJson(json['user'] as Map<String, dynamic>),
  );

  final String token;
  final DateTime? expiresAt;
  final Account account;
}
