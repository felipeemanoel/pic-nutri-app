import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/app_failure.dart';
import '../../../core/network/api_client.dart';
import 'medication_models.dart';

/// Registro informativo de medicamentos e aplicações. O app não calcula,
/// sugere nem valida doses: envia apenas o que o usuário informa.
class MedicationRepository {
  const MedicationRepository(this._dio);

  final Dio _dio;

  Future<MedicationOptions> options() async {
    final response = await guard(
      () => _dio.get<Map<String, dynamic>>('medication/options'),
    );
    return MedicationOptions.fromJson(
      response.data!['data'] as Map<String, dynamic>,
    );
  }

  Future<List<Medication>> medications() async {
    final response = await guard(
      () => _dio.get<Map<String, dynamic>>('medications'),
    );
    return (response.data!['data'] as List<dynamic>)
        .cast<Map<String, dynamic>>()
        .map(Medication.fromJson)
        .toList();
  }

  Future<Medication> saveMedication({
    String? id,
    required String name,
    required String form,
    required String doseUnit,
    required String frequency,
    bool? isActive,
    String? notes,
    DateTime? startedOn,
    String? requestId,
  }) async {
    final body = {
      'name': name.trim(),
      'form': form,
      'dose_unit': doseUnit,
      'frequency': frequency,
      'is_active': ?isActive,
      'notes': (notes?.trim().isEmpty ?? true) ? null : notes!.trim(),
      'started_on': ?startedOn?.toIso8601String().substring(0, 10),
      'client_request_id': ?requestId,
    };
    final response = await guard(
      () => id == null
          ? _dio.post<Map<String, dynamic>>('medications', data: body)
          : _dio.patch<Map<String, dynamic>>('medications/$id', data: body),
    );
    return Medication.fromJson(response.data!['data'] as Map<String, dynamic>);
  }

  Future<void> deleteMedication(String id) =>
      guard(() => _dio.delete<void>('medications/$id'));

  Future<List<MedicationDose>> recentDoses() async {
    final response = await guard(
      () => _dio.get<Map<String, dynamic>>('medication-doses'),
    );
    return (response.data!['data'] as List<dynamic>)
        .cast<Map<String, dynamic>>()
        .map(MedicationDose.fromJson)
        .toList();
  }

  Future<SavedDose> saveDose({
    String? id,
    required String medicationId,
    required DateTime takenAt,
    required String doseUnit,
    double? doseAmount,
    String? injectionSite,
    List<SymptomEntry> symptoms = const [],
    String? notes,
    String? requestId,
  }) async {
    final body = {
      'medication_id': medicationId,
      'taken_at': takenAt.toUtc().toIso8601String(),
      'dose_amount': doseAmount,
      'dose_unit': doseUnit,
      'injection_site': injectionSite,
      'symptoms': symptoms.map((s) => s.toJson()).toList(),
      'notes': (notes?.trim().isEmpty ?? true) ? null : notes!.trim(),
      'client_request_id': ?requestId,
    };
    final response = await guard(
      () => id == null
          ? _dio.post<Map<String, dynamic>>('medication-doses', data: body)
          : _dio.patch<Map<String, dynamic>>(
              'medication-doses/$id',
              data: body,
            ),
    );
    final meta = response.data!['meta'] as Map<String, dynamic>?;
    return SavedDose(
      MedicationDose.fromJson(response.data!['data'] as Map<String, dynamic>),
      meta?['alert'] as String?,
    );
  }

  Future<void> deleteDose(String id) =>
      guard(() => _dio.delete<void>('medication-doses/$id'));
}

final medicationRepositoryProvider = Provider<MedicationRepository>(
  (ref) => MedicationRepository(ref.watch(dioProvider)),
);

final medicationOptionsProvider = FutureProvider<MedicationOptions>(
  (ref) => ref.watch(medicationRepositoryProvider).options(),
);

final medicationsProvider = FutureProvider<List<Medication>>(
  (ref) => ref.watch(medicationRepositoryProvider).medications(),
);

final recentDosesProvider = FutureProvider<List<MedicationDose>>(
  (ref) => ref.watch(medicationRepositoryProvider).recentDoses(),
);
