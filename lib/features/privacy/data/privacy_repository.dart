import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/app_failure.dart';
import '../../../core/network/api_client.dart';
import '../../../core/utils/formatters.dart';

class DataExport {
  const DataExport({
    required this.id,
    required this.status,
    required this.createdAt,
    this.sizeBytes,
    this.expiresAt,
  });

  factory DataExport.fromJson(Map<String, dynamic> json) => DataExport(
    id: json['id'] as String,
    status: json['status'] as String,
    sizeBytes: toInt(json['size_bytes']),
    createdAt: DateTime.parse(json['created_at'] as String).toLocal(),
    expiresAt: json['expires_at'] == null
        ? null
        : DateTime.parse(json['expires_at'] as String).toLocal(),
  );

  final String id;

  /// pending, ready, failed, expired.
  final String status;
  final int? sizeBytes;
  final DateTime createdAt;
  final DateTime? expiresAt;

  bool get isPending => status == 'pending';
  bool get isReady => status == 'ready';
}

/// Direitos do titular: exportar e excluir dados.
class PrivacyRepository {
  const PrivacyRepository(this._dio);

  final Dio _dio;

  Future<List<DataExport>> exports() async {
    final response = await guard(
      () => _dio.get<Map<String, dynamic>>('privacy/exports'),
    );
    return (response.data!['data'] as List<dynamic>)
        .cast<Map<String, dynamic>>()
        .map(DataExport.fromJson)
        .toList();
  }

  Future<DataExport> requestExport() async {
    final response = await guard(
      () => _dio.post<Map<String, dynamic>>('privacy/exports'),
    );
    return DataExport.fromJson(response.data!['data'] as Map<String, dynamic>);
  }

  /// Baixa o arquivo para [savePath] (pasta temporária do app).
  Future<void> download(String id, String savePath) => guard(
    () => _dio.download(
      'privacy/exports/$id/download',
      savePath,
      options: Options(receiveTimeout: const Duration(minutes: 2)),
    ),
  );

  Future<void> deleteAccount({required String password}) => guard(
    () => _dio.delete<void>(
      'privacy/account',
      data: {'password': password, 'confirmation': 'EXCLUIR'},
    ),
  );
}

final privacyRepositoryProvider = Provider<PrivacyRepository>(
  (ref) => PrivacyRepository(ref.watch(dioProvider)),
);

final dataExportsProvider = FutureProvider<List<DataExport>>(
  (ref) => ref.watch(privacyRepositoryProvider).exports(),
);
