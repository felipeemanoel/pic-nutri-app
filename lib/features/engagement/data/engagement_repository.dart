import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/app_failure.dart';
import '../../../core/network/api_client.dart';
import 'engagement_models.dart';

class EngagementRepository {
  const EngagementRepository(this._dio);

  final Dio _dio;

  Engagement _parse(Response<Map<String, dynamic>> r) =>
      Engagement.fromJson(r.data!['data'] as Map<String, dynamic>);

  Future<Engagement> load() async =>
      _parse(await guard(() => _dio.get<Map<String, dynamic>>('engagement')));

  Future<Engagement> startChallenge(String code) async => _parse(
    await guard(
      () => _dio.post<Map<String, dynamic>>(
        'engagement/challenges',
        data: {'code': code},
      ),
    ),
  );

  Future<void> abandonChallenge(String id) =>
      guard(() => _dio.delete<void>('engagement/challenges/$id'));

  Future<void> markAchievementsSeen() =>
      guard(() => _dio.post<void>('engagement/achievements/seen'));

  Future<List<Celebration>> celebrations() async {
    final response = await guard(() => _dio.get<Map<String, dynamic>>('engagement/celebrations'));
    return (response.data!['data'] as List<dynamic>).cast<Map<String, dynamic>>().map(Celebration.fromJson).toList();
  }

  Future<void> markCelebrationsSeen(List<String> keys) =>
      guard(() => _dio.post<void>('engagement/celebrations/seen', data: {'keys': keys}));
}

final engagementRepositoryProvider = Provider<EngagementRepository>(
  (ref) => EngagementRepository(ref.watch(dioProvider)),
);

final engagementProvider = FutureProvider<Engagement>(
  (ref) => ref.watch(engagementRepositoryProvider).load(),
);

/// Celebrações pendentes; recarregadas ao abrir o app e após cada registro.
final celebrationsProvider = FutureProvider<List<Celebration>>(
  (ref) => ref.watch(engagementRepositoryProvider).celebrations(),
);
