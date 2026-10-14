import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/app_failure.dart';
import '../../../core/network/api_client.dart';
import '../../../core/utils/formatters.dart';

class PlanInfo {
  const PlanInfo({
    required this.code,
    required this.name,
    required this.features,
    this.description,
  });

  factory PlanInfo.fromJson(Map<String, dynamic> json) => PlanInfo(
    code: json['code'] as String,
    name: json['name'] as String,
    description: json['description'] as String?,
    features: (json['features'] as List<dynamic>? ?? [])
        .whereType<String>()
        .toList(),
  );

  final String code;
  final String name;
  final String? description;
  final List<String> features;
}

class FeatureUsage {
  const FeatureUsage({
    required this.label,
    this.feature = '',
    required this.used,
    this.limit,
    this.remaining,
  });

  factory FeatureUsage.fromJson(Map<String, dynamic> json) => FeatureUsage(
    label: json['label'] as String,
    feature: json['feature'] as String? ?? '',
    limit: toInt(json['limit']),
    used: toInt(json['used']) ?? 0,
    remaining: toInt(json['remaining']),
  );

  final String label;
  final String feature;

  /// `null` = ilimitado.
  final int? limit;
  final int used;
  final int? remaining;
}

class CurrentPlan {
  const CurrentPlan({
    required this.plan,
    required this.usage,
    required this.paymentsAvailable,
    this.endsAt,
    this.store = const StoreInfo(),
  });

  factory CurrentPlan.fromJson(Map<String, dynamic> json) => CurrentPlan(
    plan: PlanInfo.fromJson(json['plan'] as Map<String, dynamic>),
    endsAt: json['ends_at'] == null
        ? null
        : DateTime.parse(json['ends_at'] as String).toLocal(),
    usage: (json['usage_today'] as List<dynamic>)
        .cast<Map<String, dynamic>>()
        .map(FeatureUsage.fromJson)
        .toList(),
    paymentsAvailable: json['payments_available'] as bool? ?? false,
    store: json['store'] == null ? const StoreInfo() : StoreInfo.fromJson(json['store'] as Map<String, dynamic>),
  );

  final PlanInfo plan;
  final DateTime? endsAt;
  final List<FeatureUsage> usage;
  final bool paymentsAvailable;
  final StoreInfo store;

  /// Uso de um recurso pelo código (ex.: `report_export`).
  FeatureUsage? usageOf(String feature) {
    for (final u in usage) {
      if (u.feature == feature) return u;
    }
    return null;
  }
}

/// Compras pelas lojas, conforme o servidor.
class StoreInfo {
  const StoreInfo({this.android = false, this.ios = false, this.productIds = const [], this.source, this.autoRenew});

  factory StoreInfo.fromJson(Map<String, dynamic> json) => StoreInfo(
    android: json['android'] as bool? ?? false,
    ios: json['ios'] as bool? ?? false,
    productIds: [
      for (final p in (json['products'] as List<dynamic>? ?? const []).cast<Map<String, dynamic>>())
        p['product_id'] as String,
    ],
    source: json['source'] as String?,
    autoRenew: json['auto_renew'] as bool?,
  );

  final bool android;
  final bool ios;
  final List<String> productIds;

  /// Origem do plano atual: manual, google_play ou app_store.
  final String? source;
  final bool? autoRenew;
}

class PlanRepository {
  const PlanRepository(this._dio);

  final Dio _dio;

  Future<CurrentPlan> current() async {
    final response = await guard(() => _dio.get<Map<String, dynamic>>('plan'));
    return CurrentPlan.fromJson(response.data!['data'] as Map<String, dynamic>);
  }

  /// Identificador opaco da conta enviado à loja na compra.
  Future<String> accountToken() async {
    final response = await guard(() => _dio.get<Map<String, dynamic>>('billing/account-token'));
    return (response.data!['data'] as Map<String, dynamic>)['account_token'] as String;
  }

  /// Envia o comprovante da loja; o servidor confere e libera o plano.
  Future<void> submitPurchase({required String platform, required String verificationData}) => guard(
    () => _dio.post<void>(
      'billing/purchases',
      data: {
        'platform': platform,
        if (platform == 'android') 'purchase_token': verificationData else 'signed_transaction': verificationData,
      },
    ),
  );

  Future<List<PlanInfo>> plans() async {
    final response = await guard(() => _dio.get<Map<String, dynamic>>('plans'));
    return (response.data!['data'] as List<dynamic>)
        .cast<Map<String, dynamic>>()
        .map(PlanInfo.fromJson)
        .toList();
  }
}

final planRepositoryProvider = Provider<PlanRepository>(
  (ref) => PlanRepository(ref.watch(dioProvider)),
);

final currentPlanProvider = FutureProvider<CurrentPlan>(
  (ref) => ref.watch(planRepositoryProvider).current(),
);

final plansProvider = FutureProvider<List<PlanInfo>>(
  (ref) => ref.watch(planRepositoryProvider).plans(),
);
