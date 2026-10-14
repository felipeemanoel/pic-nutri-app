import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/app_failure.dart';
import '../../../core/network/api_client.dart';
import '../../../core/utils/formatters.dart';
import 'dashboard.dart';

class DashboardRepository {
  const DashboardRepository(this._dio);

  final Dio _dio;

  Future<Dashboard> load(DateTime day) async {
    final response = await guard(
      () => _dio.get<Map<String, dynamic>>(
        'dashboard',
        queryParameters: {'date': Fmt.apiDate(day)},
      ),
    );
    return Dashboard.fromJson(response.data!['data'] as Map<String, dynamic>);
  }
}

final dashboardRepositoryProvider = Provider<DashboardRepository>(
  (ref) => DashboardRepository(ref.watch(dioProvider)),
);

final dashboardProvider = FutureProvider.family<Dashboard, DateTime>(
  (ref, day) => ref.watch(dashboardRepositoryProvider).load(day),
);
