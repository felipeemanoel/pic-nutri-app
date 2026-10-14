import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/app_failure.dart';
import '../../../core/network/api_client.dart';
import 'system_health.dart';

/// Consulta o estado da API. Usado pela tela técnica desta etapa.
class HealthRepository {
  const HealthRepository(this._dio);

  final Dio _dio;

  /// Lança [AppFailure] quando a API não responde no formato esperado.
  Future<SystemHealth> fetch() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        'health',
        // 503 também traz o corpo com o estado de cada serviço.
        options: Options(validateStatus: (s) => s == 200 || s == 503),
      );
      final data = response.data;
      if (data == null) {
        throw const UnknownFailure();
      }
      return SystemHealth.fromJson(data);
    } on DioException catch (error) {
      throw AppFailure.fromDioException(error);
    }
  }
}

final healthRepositoryProvider = Provider<HealthRepository>(
  (ref) => HealthRepository(ref.watch(dioProvider)),
);
