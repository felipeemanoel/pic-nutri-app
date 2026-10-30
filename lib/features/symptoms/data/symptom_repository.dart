import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/app_failure.dart';
import '../../../core/network/api_client.dart';
import '../../../core/utils/formatters.dart';
import 'symptom_models.dart';

class SymptomRepository {
  const SymptomRepository(this._dio);

  final Dio _dio;

  Future<SymptomOptions> options() async {
    final r = await guard(() => _dio.get<Map<String, dynamic>>('symptoms/options'));
    return SymptomOptions.fromJson(r.data!['data'] as Map<String, dynamic>);
  }

  Future<SymptomTimeline> timeline({required DateTime from, required DateTime to}) async {
    final r = await guard(
      () => _dio.get<Map<String, dynamic>>(
        'symptoms',
        queryParameters: {'from': Fmt.apiDate(from), 'to': Fmt.apiDate(to)},
      ),
    );
    final meta = r.data!['meta'] as Map<String, dynamic>? ?? const {};
    return SymptomTimeline(
      items: (r.data!['data'] as List<dynamic>).cast<Map<String, dynamic>>().map(SymptomItem.fromJson).toList(),
      nearbyNote: meta['nearby_note'] as String? ?? '',
    );
  }

  /// Registra e devolve a orientação de segurança, quando houver.
  Future<SafetyAlert?> create({
    required String symptom,
    required int intensity,
    required DateTime occurredAt,
    required String requestId,
    String? otherLabel,
    String? context,
    String? notes,
    List<String> warningSigns = const [],
  }) async {
    final r = await guard(
      () => _dio.post<Map<String, dynamic>>(
        'symptoms',
        data: {
          'symptom': symptom,
          'other_label': ?otherLabel,
          'intensity': intensity,
          'occurred_at': occurredAt.toUtc().toIso8601String(),
          'context': ?context,
          'notes': ?notes,
          'warning_signs': warningSigns,
          'client_request_id': requestId,
        },
      ),
    );
    final safety = r.data!['safety'];
    return safety is Map<String, dynamic> ? SafetyAlert.fromJson(safety) : null;
  }

  Future<void> delete(String id) => guard(() => _dio.delete<void>('symptoms/$id'));

  /// Texto do resumo do período, para o usuário compartilhar se quiser.
  Future<String> summary({required DateTime from, required DateTime to}) async {
    final r = await guard(
      () => _dio.get<Map<String, dynamic>>(
        'symptoms/summary',
        queryParameters: {'from': Fmt.apiDate(from), 'to': Fmt.apiDate(to)},
      ),
    );
    return (r.data!['data'] as Map<String, dynamic>)['text'] as String;
  }
}

final symptomRepositoryProvider = Provider<SymptomRepository>(
  (ref) => SymptomRepository(ref.watch(dioProvider)),
);

final symptomOptionsProvider = FutureProvider<SymptomOptions>(
  (ref) => ref.watch(symptomRepositoryProvider).options(),
);

/// Período exibido na linha do tempo, em dias (30, 90 ou 365).
final symptomDaysProvider = NotifierProvider<SymptomDays, int>(SymptomDays.new);

class SymptomDays extends Notifier<int> {
  @override
  int build() => 30;

  void set(int days) => state = days;
}

final symptomTimelineProvider = FutureProvider<SymptomTimeline>((ref) {
  final days = ref.watch(symptomDaysProvider);
  final to = DateTime.now();
  return ref.watch(symptomRepositoryProvider).timeline(from: to.subtract(Duration(days: days - 1)), to: to);
});

/// Sintomas dos últimos 90 dias, marcados no gráfico de nível estimado.
final levelSymptomsProvider = FutureProvider<List<SymptomItem>>((ref) async {
  final to = DateTime.now();
  final timeline = await ref
      .watch(symptomRepositoryProvider)
      .timeline(from: to.subtract(const Duration(days: 89)), to: to);
  return timeline.items;
});
