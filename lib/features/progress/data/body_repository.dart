import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/app_failure.dart';
import '../../../core/network/api_client.dart';
import '../../../core/utils/formatters.dart';
import 'body_models.dart';

class BodyRepository {
  const BodyRepository(this._dio);

  final Dio _dio;

  Future<BodyProgress> progress(int days) async {
    final response = await guard(
      () => _dio.get<Map<String, dynamic>>(
        'body/progress',
        queryParameters: {'days': days},
      ),
    );
    return BodyProgress.fromJson(
      response.data!['data'] as Map<String, dynamic>,
    );
  }

  Future<List<WeightEntry>> weights() async {
    final response = await guard(
      () => _dio.get<Map<String, dynamic>>(
        'body/weights',
        queryParameters: _lastTenYears(),
      ),
    );
    return (response.data!['data'] as List<dynamic>)
        .cast<Map<String, dynamic>>()
        .map(WeightEntry.fromJson)
        .toList();
  }

  Future<void> saveWeight({
    String? id,
    required double weightKg,
    required DateTime measuredAt,
    String? notes,
    String? requestId,
  }) {
    final body = {
      'weight_kg': weightKg,
      'measured_at': measuredAt.toUtc().toIso8601String(),
      'notes': (notes?.trim().isEmpty ?? true) ? null : notes!.trim(),
      'client_request_id': ?requestId,
    };
    return guard(
      () => id == null
          ? _dio.post<void>('body/weights', data: body)
          : _dio.patch<void>('body/weights/$id', data: body),
    );
  }

  Future<void> deleteWeight(String id) =>
      guard(() => _dio.delete<void>('body/weights/$id'));

  Future<List<Measurement>> measurements() async {
    final response = await guard(
      () => _dio.get<Map<String, dynamic>>(
        'body/measurements',
        queryParameters: _lastTenYears(),
      ),
    );
    return (response.data!['data'] as List<dynamic>)
        .cast<Map<String, dynamic>>()
        .map(Measurement.fromJson)
        .toList();
  }

  Future<void> saveMeasurement({
    String? id,
    required String type,
    String? label,
    required double valueCm,
    required DateTime measuredAt,
    String? requestId,
  }) {
    final body = {
      if (id == null) 'type': type,
      'label': label,
      'value_cm': valueCm,
      'measured_at': measuredAt.toUtc().toIso8601String(),
      'client_request_id': ?requestId,
    };
    return guard(
      () => id == null
          ? _dio.post<void>('body/measurements', data: body)
          : _dio.patch<void>('body/measurements/$id', data: body),
    );
  }

  Future<void> deleteMeasurement(String id) =>
      guard(() => _dio.delete<void>('body/measurements/$id'));

  Future<List<ProgressPhoto>> photos() async {
    final response = await guard(() => _dio.get<Map<String, dynamic>>('body/photos'));
    return (response.data!['data'] as List<dynamic>)
        .cast<Map<String, dynamic>>()
        .map(ProgressPhoto.fromJson)
        .toList();
  }

  /// Envia a foto (o servidor reduz, remove metadados e guarda cifrada).
  Future<ProgressPhoto> uploadPhoto({
    required String path,
    required String pose,
    required DateTime takenAt,
    required String requestId,
    String? notes,
  }) async {
    final form = FormData.fromMap({
      'photo': await MultipartFile.fromFile(path, filename: 'evolucao.jpg'),
      'pose': pose,
      'taken_at': takenAt.toUtc().toIso8601String(),
      if (notes != null && notes.trim().isNotEmpty) 'notes': notes.trim(),
      'client_request_id': requestId,
    });
    final response = await guard(
      () => _dio.post<Map<String, dynamic>>(
        'body/photos',
        data: form,
        options: Options(sendTimeout: const Duration(minutes: 2)),
      ),
    );
    return ProgressPhoto.fromJson(response.data!['data'] as Map<String, dynamic>);
  }

  Future<void> updatePhoto(String id, {required String pose, String? notes}) => guard(
    () => _dio.patch<void>(
      'body/photos/$id',
      data: {'pose': pose, 'notes': (notes?.trim().isEmpty ?? true) ? null : notes!.trim()},
    ),
  );

  Future<void> deletePhoto(String id) => guard(() => _dio.delete<void>('body/photos/$id'));

  /// Bytes JPEG da foto (requisição autenticada; não fica em cache em disco).
  Future<Uint8List> photoBytes(String id) async {
    final response = await guard(
      () => _dio.get<List<int>>('body/photos/$id/image', options: Options(responseType: ResponseType.bytes)),
    );
    return Uint8List.fromList(response.data!);
  }

  /// Histórico completo dentro do limite da API (até ~10 anos).
  static Map<String, String> _lastTenYears() {
    final to = DateTime.now().add(const Duration(days: 1));
    final from = to.subtract(const Duration(days: 3600));
    return {'from': Fmt.apiDate(from), 'to': Fmt.apiDate(to)};
  }
}

final bodyRepositoryProvider = Provider<BodyRepository>(
  (ref) => BodyRepository(ref.watch(dioProvider)),
);

final bodyProgressProvider = FutureProvider.family<BodyProgress, int>(
  (ref, days) => ref.watch(bodyRepositoryProvider).progress(days),
);

final weightEntriesProvider = FutureProvider<List<WeightEntry>>(
  (ref) => ref.watch(bodyRepositoryProvider).weights(),
);

final measurementsProvider = FutureProvider<List<Measurement>>(
  (ref) => ref.watch(bodyRepositoryProvider).measurements(),
);

final progressPhotosProvider = FutureProvider<List<ProgressPhoto>>(
  (ref) => ref.watch(bodyRepositoryProvider).photos(),
);

/// Imagem de uma foto; liberada da memória quando sai da tela.
final progressPhotoBytesProvider = FutureProvider.autoDispose.family<Uint8List, String>(
  (ref, id) => ref.watch(bodyRepositoryProvider).photoBytes(id),
);
