import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../../../core/design/design_system.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/widgets/feedback.dart';
import '../../../shared/widgets/state_views.dart';
import '../data/professional_models.dart';
import '../data/professional_repository.dart';
import 'professional_widgets.dart';

/// Minhas solicitações de contato e as respostas dos profissionais.
class ContactRequestsPage extends ConsumerWidget {
  const ContactRequestsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final value = ref.watch(contactRequestsProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Minhas solicitações'),
        actions: [
          IconButton(
            tooltip: 'Compartilhamentos de dados',
            icon: const Icon(Icons.shield_outlined),
            onPressed: () => context.push(AppRoutes.shareGrants),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(contactRequestsProvider.future),
        child: AsyncValueView<List<ContactRequestItem>>(
          value: value,
          onRetry: () => ref.invalidate(contactRequestsProvider),
          data: (items) => items.isEmpty
              ? ListView(
                  children: const [
                    EmptyState(
                      icon: Icons.inbox_outlined,
                      title: 'Nenhuma solicitação',
                      message: 'Quando você pedir contato a um profissional, a resposta aparece aqui.',
                    ),
                  ],
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(Space.page),
                  itemCount: items.length,
                  separatorBuilder: (_, _) => const SizedBox(height: Space.sm),
                  itemBuilder: (_, i) => _RequestCard(item: items[i]),
                ),
        ),
      ),
    );
  }
}

class _RequestCard extends ConsumerWidget {
  const _RequestCard({required this.item});

  final ContactRequestItem item;

  Future<void> _cancel(BuildContext context, WidgetRef ref) async {
    final ok = await confirmAction(
      context,
      title: 'Cancelar solicitação?',
      message: item.grant?.active ?? false
          ? 'A autorização de compartilhamento de dados também será revogada.'
          : 'O profissional não poderá mais responder.',
      confirmLabel: 'Cancelar solicitação',
      destructive: true,
    );
    if (!ok) return;
    try {
      await ref.read(professionalRepositoryProvider).cancelRequest(item.id);
      ref
        ..invalidate(contactRequestsProvider)
        ..invalidate(shareGrantsProvider)
        ..invalidate(professionalProvider(item.professionalId));
    } on Object catch (e) {
      if (context.mounted) showFailure(context, e);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pic = context.pic;
    final (Color color, IconData icon) = switch (item.status) {
      'accepted' => (pic.success, Icons.check_circle_outline),
      'declined' => (pic.error, Icons.cancel_outlined),
      'pending' => (pic.warning, Icons.hourglass_empty),
      _ => (pic.textSecondary, Icons.block),
    };
    return AppCard(
      onTap: item.professionalId.isEmpty ? null : () => context.push(AppRoutes.professional(item.professionalId)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(item.professionalName, style: context.text.titleMedium)),
              Icon(icon, size: 18, color: color),
              const SizedBox(width: Space.xs),
              Text(item.statusLabel, style: context.text.labelMedium?.copyWith(color: color)),
            ],
          ),
          Text(
            '${item.professionalCategory} · ${modalityLabel(item.modality)} · enviada em ${Fmt.shortDate(item.createdAt.toLocal())}',
            style: context.text.bodySmall,
          ),
          if (item.reply != null && item.reply!.isNotEmpty) ...[
            const SizedBox(height: Space.sm),
            Text('Resposta', style: context.text.labelLarge),
            Text(item.reply!),
          ],
          if (item.grant != null) ...[
            const SizedBox(height: Space.sm),
            Text(
              item.grant!.active
                  ? 'Dados compartilhados até ${Fmt.shortDate(item.grant!.expiresAt.toLocal())}'
                  : 'Compartilhamento de dados: ${item.grant!.statusLabel.toLowerCase()}',
              style: context.text.bodySmall,
            ),
          ],
          if (item.pending)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(onPressed: () => _cancel(context, ref), child: const Text('Cancelar')),
            ),
        ],
      ),
    );
  }
}
