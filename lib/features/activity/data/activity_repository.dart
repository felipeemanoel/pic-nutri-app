import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/app_failure.dart';
import '../../../core/network/api_client.dart';
import '../../../core/utils/formatters.dart';
import 'activity_models.dart';

class ActivityRepository {
  const ActivityRepository(this._dio);

  final Dio _dio;

  Future<ActivityOptions> options() async {
    final r = await guard(
      () => _dio.get<Map<String, dynamic>>('activity/options'),
    );
    return ActivityOptions.fromJson(r.data!['data'] as Map<String, dynamic>);
  }

  Future<ActivitySummary> summary({DateTime? date}) async {
    final r = await guard(
      () => _dio.get<Map<String, dynamic>>(
        'activity/summary',
        queryParameters: {if (date != null) 'date': Fmt.apiDate(date)},
      ),
    );
    return ActivitySummary.fromJson(r.data!['data'] as Map<String, dynamic>);
  }

  Future<List<ActivityPlan>> plans() async {
    final r = await guard(
      () => _dio.get<Map<String, dynamic>>('activity/plans'),
    );
    return [
      for (final p in r.data!['data'] as List<dynamic>)
        ActivityPlan.fromJson(p as Map<String, dynamic>),
    ];
  }

  Future<ActivityPlan> savePlan({
    String? id,
    required String type,
    required int timesPerWeek,
    String? title,
    String? location,
    List<int> days = const [],
    String? time,
    int? durationMin,
    bool reminderEnabled = false,
    bool? isActive,
    String? requestId,
  }) async {
    final body = {
      'type': type,
      'times_per_week': timesPerWeek,
      'title': title,
      'location': location,
      'days': days,
      'time': time,
      'duration_min': durationMin,
      'reminder_enabled': reminderEnabled,
      'is_active': ?isActive,
      'client_request_id': ?requestId,
    };
    final r = await guard(
      () => id == null
          ? _dio.post<Map<String, dynamic>>('activity/plans', data: body)
          : _dio.patch<Map<String, dynamic>>('activity/plans/$id', data: body),
    );
    return ActivityPlan.fromJson(r.data!['data'] as Map<String, dynamic>);
  }

  Future<void> setPlanActive(String id, {required bool active}) => guard(
    () => _dio.patch<void>('activity/plans/$id', data: {'is_active': active}),
  );

  Future<void> deletePlan(String id) =>
      guard(() => _dio.delete<void>('activity/plans/$id'));

  Future<List<ActivitySession>> sessions({
    required DateTime from,
    required DateTime to,
  }) async {
    final r = await guard(
      () => _dio.get<Map<String, dynamic>>(
        'activity/sessions',
        queryParameters: {'from': Fmt.apiDate(from), 'to': Fmt.apiDate(to)},
      ),
    );
    return [
      for (final s in r.data!['data'] as List<dynamic>)
        ActivitySession.fromJson(s as Map<String, dynamic>),
    ];
  }

  Future<ActivitySession> saveSession({
    String? id,
    required String type,
    required int durationMin,
    required DateTime performedAt,
    String? planId,
    String? eventId,
    String? title,
    String? intensity,
    double? distanceKm,
    String? notes,
    String? requestId,
  }) async {
    final body = {
      'type': type,
      'duration_min': durationMin,
      'performed_at': performedAt.toUtc().toIso8601String(),
      'plan_id': planId,
      'event_id': eventId,
      'title': title,
      'intensity': intensity,
      'distance_km': distanceKm,
      'notes': notes,
      'client_request_id': ?requestId,
    };
    final r = await guard(
      () => id == null
          ? _dio.post<Map<String, dynamic>>('activity/sessions', data: body)
          : _dio.patch<Map<String, dynamic>>(
              'activity/sessions/$id',
              data: body,
            ),
    );
    return ActivitySession.fromJson(r.data!['data'] as Map<String, dynamic>);
  }

  Future<void> deleteSession(String id) =>
      guard(() => _dio.delete<void>('activity/sessions/$id'));

  Future<List<ActivityEvent>> events() async {
    final r = await guard(
      () => _dio.get<Map<String, dynamic>>('activity/events'),
    );
    return [
      for (final e in r.data!['data'] as List<dynamic>)
        ActivityEvent.fromJson(e as Map<String, dynamic>),
    ];
  }

  Future<ActivityEvent> saveEvent({
    String? id,
    required String name,
    required String type,
    required DateTime startsAt,
    String? location,
    double? distanceKm,
    String? url,
    String? notes,
    bool reminderEnabled = true,
    String? requestId,
  }) async {
    final body = {
      'name': name,
      'type': type,
      'starts_at': startsAt.toUtc().toIso8601String(),
      'location': location,
      'distance_km': distanceKm,
      'url': url,
      'notes': notes,
      'reminder_enabled': reminderEnabled,
      'client_request_id': ?requestId,
    };
    final r = await guard(
      () => id == null
          ? _dio.post<Map<String, dynamic>>('activity/events', data: body)
          : _dio.patch<Map<String, dynamic>>('activity/events/$id', data: body),
    );
    return ActivityEvent.fromJson(r.data!['data'] as Map<String, dynamic>);
  }

  Future<void> deleteEvent(String id) =>
      guard(() => _dio.delete<void>('activity/events/$id'));
}

final activityRepositoryProvider = Provider<ActivityRepository>(
  (ref) => ActivityRepository(ref.watch(dioProvider)),
);

final activityOptionsProvider = FutureProvider<ActivityOptions>(
  (ref) => ref.watch(activityRepositoryProvider).options(),
);

final activitySummaryProvider = FutureProvider<ActivitySummary>(
  (ref) => ref.watch(activityRepositoryProvider).summary(),
);

final activityPlansProvider = FutureProvider<List<ActivityPlan>>(
  (ref) => ref.watch(activityRepositoryProvider).plans(),
);

final activityEventsProvider = FutureProvider<List<ActivityEvent>>(
  (ref) => ref.watch(activityRepositoryProvider).events(),
);

/// Histórico dos últimos 60 dias.
final activitySessionsProvider = FutureProvider<List<ActivitySession>>((ref) {
  final to = DateTime.now();
  return ref
      .watch(activityRepositoryProvider)
      .sessions(from: to.subtract(const Duration(days: 59)), to: to);
});
