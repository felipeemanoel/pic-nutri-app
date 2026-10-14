import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/app_failure.dart';
import '../../../core/network/api_client.dart';
import '../../auth/data/account.dart';
import '../../onboarding/data/goal_suggestion.dart';

/// Perfil, onboarding, consentimentos e dados da conta.
class ProfileRepository {
  const ProfileRepository(this._dio);

  final Dio _dio;

  Future<Profile> updateProfile(Map<String, Object?> changes) async {
    final response = await guard(
      () => _dio.patch<Map<String, dynamic>>('profile', data: changes),
    );
    return Profile.fromJson(response.data!['data'] as Map<String, dynamic>);
  }

  Future<Account> completeOnboarding(
    Map<String, Object?> data, {
    required String requestId,
  }) async {
    final response = await guard(
      () => _dio.post<Map<String, dynamic>>(
        'profile/onboarding',
        data: {
          ...data,
          'health_data_consent': true,
          'client_request_id': requestId,
        },
      ),
    );
    return Account.fromJson(response.data!['data'] as Map<String, dynamic>);
  }

  /// Salva o progresso do onboarding (campos respondidos e etapa atual).
  Future<Account> saveOnboardingProgress({
    required String step,
    Map<String, Object?> data = const {},
    List<String>? skipped,
  }) async {
    final response = await guard(
      () => _dio.put<Map<String, dynamic>>(
        'profile/onboarding/progress',
        data: {...data, 'step': step, 'skipped': ?skipped},
      ),
    );
    return Account.fromJson(response.data!['data'] as Map<String, dynamic>);
  }

  /// Conclui o onboarding (o peso inicial, se houver, vira o primeiro registro).
  Future<Account> finishOnboarding({double? currentWeightKg, required String requestId}) async {
    final response = await guard(
      () => _dio.post<Map<String, dynamic>>(
        'profile/onboarding/finish',
        data: {'current_weight_kg': ?currentWeightKg, 'client_request_id': requestId},
      ),
    );
    return Account.fromJson(response.data!['data'] as Map<String, dynamic>);
  }

  Future<GoalSuggestion> suggestGoals({
    required String sex,
    required DateTime birthDate,
    required double heightCm,
    required double weightKg,
    required String activityLevel,
    required String goal,
  }) async {
    final response = await guard(
      () => _dio.post<Map<String, dynamic>>(
        'profile/goal-suggestion',
        data: {
          'sex': sex,
          'birth_date': birthDate.toIso8601String().substring(0, 10),
          'height_cm': heightCm,
          'weight_kg': weightKg,
          'activity_level': activityLevel,
          'goal': goal,
        },
      ),
    );
    return GoalSuggestion.fromJson(
      response.data!['data'] as Map<String, dynamic>,
    );
  }

  Future<Account> updateName(String name) async {
    final response = await guard(
      () => _dio.patch<Map<String, dynamic>>('me', data: {'name': name.trim()}),
    );
    return Account.fromJson(response.data!['data'] as Map<String, dynamic>);
  }

  Future<void> changePassword({
    required String current,
    required String newPassword,
  }) => guard(
    () => _dio.put<void>(
      'me/password',
      data: {
        'current_password': current,
        'password': newPassword,
        'password_confirmation': newPassword,
      },
    ),
  );

  Future<void> setConsent(String type, {required bool granted}) => guard(
    () => _dio.post<void>(
      'me/consents',
      data: {'type': type, 'granted': granted},
    ),
  );
}

final profileRepositoryProvider = Provider<ProfileRepository>(
  (ref) => ProfileRepository(ref.watch(dioProvider)),
);
