/// Resultado de `GET /api/v1/health`.
class SystemHealth {
  const SystemHealth({
    required this.status,
    required this.environment,
    required this.checks,
  });

  factory SystemHealth.fromJson(Map<String, dynamic> json) {
    final rawChecks = json['checks'];

    return SystemHealth(
      status: json['status'] as String? ?? 'unknown',
      environment: json['environment'] as String? ?? 'unknown',
      checks: rawChecks is Map<String, dynamic>
          ? {
              for (final entry in rawChecks.entries)
                entry.key: entry.value == 'ok',
            }
          : const {},
    );
  }

  /// "ok" ou "degraded".
  final String status;
  final String environment;

  /// Serviço -> respondeu corretamente.
  final Map<String, bool> checks;

  bool get isHealthy => status == 'ok';
}
