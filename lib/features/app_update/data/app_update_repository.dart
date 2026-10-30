import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/app_failure.dart';
import '../../../core/network/api_client.dart';

/// Situação da versão instalada em relação à publicada na loja.
enum AppUpdateStatus {
  upToDate,

  /// Há versão nova: o app convida a atualizar a cada abertura.
  optional,

  /// Versão abaixo da mínima aceita: o app só segue depois de atualizar.
  required;

  static AppUpdateStatus parse(Object? value) => switch (value) {
    'required' => required,
    'optional' => optional,
    _ => upToDate,
  };
}

class AppUpdateInfo {
  const AppUpdateInfo({
    required this.status,
    required this.message,
    this.latestVersion,
    this.storeUrl,
  });

  factory AppUpdateInfo.fromJson(Map<String, dynamic> json) => AppUpdateInfo(
    status: AppUpdateStatus.parse(json['status']),
    message: json['message'] as String? ?? '',
    latestVersion: json['latest_version'] as String?,
    storeUrl: json['store_url'] as String?,
  );

  final AppUpdateStatus status;
  final String message;
  final String? latestVersion;
  final String? storeUrl;
}

class AppUpdateRepository {
  const AppUpdateRepository(this._dio);

  final Dio _dio;

  Future<AppUpdateInfo> check({
    required String platform,
    required int build,
  }) async {
    final r = await guard(
      () => _dio.get<Map<String, dynamic>>(
        'app/version',
        queryParameters: {'platform': platform, 'build': build},
      ),
    );
    return AppUpdateInfo.fromJson(r.data!['data'] as Map<String, dynamic>);
  }
}

final appUpdateRepositoryProvider = Provider<AppUpdateRepository>(
  (ref) => AppUpdateRepository(ref.watch(dioProvider)),
);
