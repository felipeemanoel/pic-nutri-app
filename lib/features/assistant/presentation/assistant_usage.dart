import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../../../core/design/design_system.dart';
import '../../ai/data/ai_models.dart';

/// Contagem vinda da API; nenhum limite de plano é inventado no aparelho.
class AssistantUsage extends StatelessWidget {
  const AssistantUsage({super.key, required this.status, this.onRefresh});
  final AiFeatureStatus status;
  final VoidCallback? onRefresh;

  @override
  Widget build(BuildContext context) {
    final valid = status.hasValidFiniteQuota;
    final exhausted = valid && status.remaining == 0;
    final label = !status.available
        ? 'Assistente indisponível no momento'
        : !valid
        ? 'Não foi possível confirmar o limite do seu plano'
        : exhausted
        ? 'Você atingiu o limite diário do seu plano'
        : '${status.remaining} ${status.remaining == 1 ? 'mensagem restante' : 'mensagens restantes'} hoje';
    return Semantics(
      liveRegion: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: context.text.titleSmall),
          if (valid) ...[
            const SizedBox(height: Space.xs),
            Text(
              '${status.used} de ${status.limit} mensagens utilizadas hoje',
              style: context.text.bodySmall,
            ),
            const SizedBox(height: Space.sm),
            ProgressBar(
              progress: status.limit! > 0 ? status.used! / status.limit! : 0,
            ),
          ],
          if (exhausted || !valid)
            Wrap(
              spacing: Space.sm,
              children: [
                if (onRefresh != null)
                  TextButton.icon(
                    onPressed: onRefresh,
                    icon: const Icon(Icons.refresh, size: 18),
                    label: const Text('Atualizar limite'),
                  ),
                TextButton(
                  onPressed: () => context.push(AppRoutes.plan),
                  child: const Text('Ver meu plano'),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
