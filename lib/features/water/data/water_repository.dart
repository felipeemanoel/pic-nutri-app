import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/app_failure.dart';
import '../../../core/network/api_client.dart';
import '../../../core/utils/formatters.dart';

class WaterEntry {
  const WaterEntry({
    required this.id,
    required this.amountMl,
    required this.consumedAt,
  });

  factory WaterEntry.fromJson(Map<String, dynamic> json) => WaterEntry(
    id: json['id'] as String,
    amountMl: toInt(json['amount_ml']) ?? 0,
    consumedAt: DateTime.parse(json['consumed_at'] as String).toLocal(),
  );

  final String id;
  final int amountMl;
  final DateTime consumedAt;
}

class WaterDay {
  const WaterDay({
    required this.totalMl,
    required this.goalMl,
    required this.entries,
  });

  factory WaterDay.fromJson(Map<String, dynamic> json) => WaterDay(
    totalMl: toInt(json['total_ml']) ?? 0,
    goalMl: toInt(json['goal_ml']) ?? 2000,
    entries: (json['entries'] as List<dynamic>)
        .cast<Map<String, dynamic>>()
        .map(WaterEntry.fromJson)
        .toList(),
  );

  final int totalMl;
  final int goalMl;
  final List<WaterEntry> entries;

  double get progress => goalMl <= 0 ? 0 : (totalMl / goalMl).clamp(0, 1);
}

class WaterHistoryDay {
  const WaterHistoryDay(this.date, this.totalMl);

  final DateTime date;
  final int totalMl;
}

class WaterRepository {
  const WaterRepository(this._dio);

  final Dio _dio;

  Future<WaterDay> day(DateTime day) async {
    final response = await guard(
      () => _dio.get<Map<String, dynamic>>(
        'water',
        queryParameters: {'date': Fmt.apiDate(day)},
      ),
    );
    return WaterDay.fromJson(response.data!['data'] as Map<String, dynamic>);
  }

  Future<List<WaterHistoryDay>> lastDays(DateTime until, int days) async {
    final from = until.subtract(Duration(days: days - 1));
    final response = await guard(
      () => _dio.get<Map<String, dynamic>>(
        'water/history',
        queryParameters: {'from': Fmt.apiDate(from), 'to': Fmt.apiDate(until)},
      ),
    );
    final data = response.data!['data'] as Map<String, dynamic>;
    return (data['days'] as List<dynamic>)
        .cast<Map<String, dynamic>>()
        .map(
          (e) => WaterHistoryDay(
            DateTime.parse(e['date'] as String),
            toInt(e['total_ml']) ?? 0,
          ),
        )
        .toList();
  }

  Future<void> add(int amountMl, {required String requestId, DateTime? at}) =>
      guard(
        () => _dio.post<void>(
          'water',
          data: {
            'amount_ml': amountMl,
            'client_request_id': requestId,
            if (at != null) 'consumed_at': at.toUtc().toIso8601String(),
          },
        ),
      );

  Future<void> update(String id, int amountMl) =>
      guard(() => _dio.patch<void>('water/$id', data: {'amount_ml': amountMl}));

  Future<void> delete(String id) => guard(() => _dio.delete<void>('water/$id'));
}

final waterRepositoryProvider = Provider<WaterRepository>(
  (ref) => WaterRepository(ref.watch(dioProvider)),
);

final waterDayProvider = FutureProvider.family<WaterDay, DateTime>(
  (ref, day) => ref.watch(waterRepositoryProvider).day(day),
);

final waterHistoryProvider =
    FutureProvider.family<List<WaterHistoryDay>, DateTime>(
      (ref, until) => ref.watch(waterRepositoryProvider).lastDays(until, 7),
    );
