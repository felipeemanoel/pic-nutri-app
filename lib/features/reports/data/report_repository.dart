import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/app_failure.dart';
import '../../../core/network/api_client.dart';
import '../../../core/utils/formatters.dart';
import 'report_models.dart';

/// Parâmetros de um relatório: período e um dia de referência.
typedef ReportQuery = ({String period, DateTime reference});

class ReportRepository {
  const ReportRepository(this._dio);

  final Dio _dio;

  Map<String, String> _params(ReportQuery q) => {
    'period': q.period,
    'date': Fmt.apiDate(q.reference),
  };

  Future<PeriodReport> summary(ReportQuery q) async {
    final response = await guard(
      () => _dio.get<Map<String, dynamic>>('reports/summary', queryParameters: _params(q)),
    );
    return PeriodReport.fromJson(response.data!['data'] as Map<String, dynamic>);
  }

  /// Baixa o PDF para consulta dos últimos [days] dias (recurso do plano).
  Future<void> consultationPdf(int days, String savePath) => guard(
    () => _dio.download('reports/consultation', savePath, queryParameters: {'days': days}),
  );

  /// Baixa o CSV do período para [savePath] (recurso do plano).
  Future<void> export(ReportQuery q, String savePath) => guard(
    () => _dio.download('reports/export', savePath, queryParameters: _params(q)),
  );
}

final reportRepositoryProvider = Provider<ReportRepository>(
  (ref) => ReportRepository(ref.watch(dioProvider)),
);

final periodReportProvider = FutureProvider.family<PeriodReport, ReportQuery>(
  (ref, q) => ref.watch(reportRepositoryProvider).summary(q),
);
