import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/app_failure.dart';
import '../../../core/network/api_client.dart';
import 'reminder_models.dart';

class ReminderRepository {
  const ReminderRepository(this._dio);

  final Dio _dio;

  Future<List<Reminder>> list() async {
    final response = await guard(
      () => _dio.get<Map<String, dynamic>>('reminders'),
    );
    return (response.data!['data'] as List<dynamic>)
        .cast<Map<String, dynamic>>()
        .map(Reminder.fromJson)
        .toList();
  }

  Future<Reminder> save({
    String? id,
    required String type,
    required String time,
    required List<int> days,
    String? title,
    bool? enabled,
    String? medicationId,
    String? requestId,
    int? intervalMinutes,
    String? endTime,
  }) async {
    final body = {
      'type': type,
      'title': (title?.trim().isEmpty ?? true) ? null : title!.trim(),
      'time': time,
      // Sem repetição, os dois vão nulos (a API limpa o horário final).
      'interval_minutes': intervalMinutes,
      'end_time': intervalMinutes == null ? null : endTime,
      'days': days,
      'enabled': ?enabled,
      'medication_id': medicationId,
      'client_request_id': ?requestId,
    };
    final response = await guard(
      () => id == null
          ? _dio.post<Map<String, dynamic>>('reminders', data: body)
          : _dio.patch<Map<String, dynamic>>('reminders/$id', data: body),
    );
    return Reminder.fromJson(response.data!['data'] as Map<String, dynamic>);
  }

  Future<Reminder> setEnabled(String id, bool enabled) async {
    final response = await guard(
      () => _dio.patch<Map<String, dynamic>>(
        'reminders/$id',
        data: {'enabled': enabled},
      ),
    );
    return Reminder.fromJson(response.data!['data'] as Map<String, dynamic>);
  }

  Future<void> delete(String id) =>
      guard(() => _dio.delete<void>('reminders/$id'));
}

final reminderRepositoryProvider = Provider<ReminderRepository>(
  (ref) => ReminderRepository(ref.watch(dioProvider)),
);

final remindersProvider = FutureProvider<List<Reminder>>(
  (ref) => ref.watch(reminderRepositoryProvider).list(),
);
