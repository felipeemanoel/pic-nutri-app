import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design/design_system.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/widgets/feedback.dart';
import '../../../shared/widgets/state_views.dart';
import '../data/professional_models.dart';
import '../data/professional_repository.dart';

/// Autorizações de compartilhamento: quem pode ver o quê, até quando e
/// quantas vezes consultou. Revogar corta o acesso na hora.
class ShareGrantsPage extends ConsumerWidget {
  const ShareGrantsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final value = ref.watch(shareGrantsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Compartilhamentos de dados')),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(shareGrantsProvider.future),
        child: AsyncValueView<List<ShareGrant>>(
          value: value,
          onRetry: () => ref.invalidate(shareGrantsProvider),
          data: (grants) => ListView(
            padding: const EdgeInsets.all(Space.page),
            children: [
              Text(
                'Seus dados só são vistos por um profissional quando você autoriza, nas categorias e pelo prazo '
                'escolhidos. Cada consulta fica registrada aqui.',
                style: context.text.bodySmall,
              ),
              const SizedBox(height: Space.md),
              if (grants.isEmpty)
                const EmptyState(
                  icon: Icons.shield_outlined,
                  title: 'Nenhum compartilhamento',
                  message: 'Você pode autorizar ao pedir contato a um profissional.',
                )
              else
                for (final g in grants) ...[_GrantCard(grant: g), const SizedBox(height: Space.sm)],
            ],
          ),
        ),
      ),
    );
  }
}

class _GrantCard extends ConsumerWidget {
  const _GrantCard({required this.grant});

  final ShareGrant grant;

  Future<void> _revoke(BuildContext context, WidgetRef ref) async {
    final ok = await confirmAction(
      context,
      title: 'Revogar compartilhamento?',
      message: '${grant.professionalName ?? 'O profissional'} deixará de ver seus dados imediatamente.',
      confirmLabel: 'Revogar',
      destructive: true,
    );
    if (!ok) return;
    try {
      await ref.read(professionalRepositoryProvider).revokeGrant(grant.id);
      ref
        ..invalidate(shareGrantsProvider)
        ..invalidate(contactRequestsProvider);
    } on Object catch (e) {
      if (context.mounted) showFailure(context, e);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final g = grant;
    final last = g.lastAccessAt;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(g.professionalName ?? 'Profissional', style: context.text.titleMedium)),
              Text(
                g.statusLabel,
                style: context.text.labelMedium?.copyWith(color: g.active ? context.pic.success : context.pic.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: Space.xs),
          Text('Dados: ${g.categories.map((c) => c.label).join(', ')}'),
          Text('Finalidade: ${g.purpose}', style: context.text.bodySmall),
          Text(
            g.active
                ? 'Válido até ${Fmt.shortDate(g.expiresAt.toLocal())}'
                : g.revokedAt != null
                ? 'Revogado em ${Fmt.shortDate(g.revokedAt!.toLocal())}'
                : 'Expirou em ${Fmt.shortDate(g.expiresAt.toLocal())}',
            style: context.text.bodySmall,
          ),
          Text(
            g.accesses == 0
                ? 'Ainda não consultado'
                : 'Consultado ${g.accesses == 1 ? '1 vez' : '${g.accesses} vezes'}'
                      '${last == null ? '' : ' · último acesso em ${Fmt.shortDate(last.toLocal())} às ${Fmt.time(last)}'}',
            style: context.text.bodySmall,
          ),
          if (g.active)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(onPressed: () => _revoke(context, ref), child: const Text('Revogar')),
            ),
        ],
      ),
    );
  }
}
