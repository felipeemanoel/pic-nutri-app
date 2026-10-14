import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/env.dart';
import '../../../core/error/app_failure.dart';
import '../data/system_health.dart';
import 'system_status_providers.dart';

/// Tela técnica da etapa de base: mostra o ambiente e o estado da API.
///
/// Não faz parte do produto; será substituída pelas telas reais.
class SystemStatusPage extends ConsumerWidget {
  const SystemStatusPage({super.key});

  static const _serviceLabels = {
    'database': 'Banco de dados',
    'cache': 'Cache e filas',
    'storage': 'Armazenamento de arquivos',
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final env = ref.watch(appEnvProvider);
    final health = ref.watch(systemHealthProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('PicNutri · Status')),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(systemHealthProvider);
          try {
            await ref.read(systemHealthProvider.future);
          } on Object {
            // O erro já é exibido pelo estado do provider.
          }
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _InfoTile(label: 'Ambiente', value: env.flavor.name),
            _InfoTile(label: 'API', value: env.apiV1Url),
            const Divider(height: 32),
            health.when(
              data: (data) => _HealthView(health: data, labels: _serviceLabels),
              loading: () => const Padding(
                padding: EdgeInsets.all(24),
                child: Center(
                  child: CircularProgressIndicator(
                    semanticsLabel: 'Verificando a API',
                  ),
                ),
              ),
              error: (error, _) => _ErrorView(
                message: error is AppFailure
                    ? error.message
                    : 'Algo deu errado. Tente novamente.',
                onRetry: () => ref.invalidate(systemHealthProvider),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(label),
      subtitle: Text(value),
    );
  }
}

class _HealthView extends StatelessWidget {
  const _HealthView({required this.health, required this.labels});

  final SystemHealth health;
  final Map<String, String> labels;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          health.isHealthy ? 'API operando normalmente' : 'API com falhas',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        for (final entry in health.checks.entries)
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(
              entry.value ? Icons.check_circle : Icons.error,
              color: entry.value ? scheme.primary : scheme.error,
              semanticLabel: entry.value ? 'ok' : 'falha',
            ),
            title: Text(labels[entry.key] ?? entry.key),
            trailing: Text(entry.value ? 'ok' : 'falha'),
          ),
      ],
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(message, textAlign: TextAlign.center),
        const SizedBox(height: 16),
        FilledButton(onPressed: onRetry, child: const Text('Tentar novamente')),
      ],
    );
  }
}
