import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../../../core/design/design_system.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/widgets/profile_button.dart';
import '../../../shared/widgets/state_views.dart';
import '../../ai/data/ai_models.dart';
import '../../ai/data/ai_repository.dart';
import 'chat_page.dart';

/// Aba "Assistente": apresentação do assistente de IA e conversas anteriores.
class AssistantPage extends ConsumerWidget {
  const AssistantPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(aiStatusProvider);
    final conversations = ref.watch(conversationsProvider);
    final available = status.value?.assistant.available ?? false;

    return Scaffold(
      appBar: AppBar(title: const Text('Assistente'), actions: const [ProfileButton()]),
      floatingActionButton: available
          ? FloatingActionButton.extended(
              backgroundColor: context.pic.ai,
              foregroundColor: context.colors.onTertiary,
              onPressed: () => context.push(AppRoutes.chat),
              icon: const Icon(Icons.add_comment_outlined),
              label: const Text('Nova conversa'),
            )
          : null,
      body: RefreshIndicator(
        onRefresh: () async {
          ref
            ..invalidate(aiStatusProvider)
            ..invalidate(conversationsProvider);
          await ref.read(conversationsProvider.future);
        },
        child: AsyncValueView<AiStatus>(
          value: status,
          onRetry: () => ref.invalidate(aiStatusProvider),
          data: (s) => ListView(
            padding: const EdgeInsets.fromLTRB(
              Space.page,
              Space.sm,
              Space.page,
              Space.fabClearance,
            ),
            children: [
              _Intro(status: s.assistant),
              const SectionHeader(title: 'Conversas'),
              AsyncValueView<List<Conversation>>(
                value: conversations,
                onRetry: () => ref.invalidate(conversationsProvider),
                loading: const SkeletonCard(lines: 2),
                data: (list) => list.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.symmetric(vertical: Space.lg),
                        child: Text(
                          s.assistant.available
                              ? 'Nenhuma conversa ainda. Toque em "Nova conversa" para começar.'
                              : 'Nenhuma conversa ainda.',
                          style: context.text.bodySmall,
                          textAlign: TextAlign.center,
                        ),
                      )
                    : Column(
                        children: [
                          for (final c in list) ...[
                            AppCard(
                              onTap: () =>
                                  context.push(AppRoutes.chat, extra: c.id),
                              padding: const EdgeInsets.symmetric(
                                horizontal: Space.lg,
                                vertical: Space.md,
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    c.isEnded
                                        ? Icons.lock_outline
                                        : Icons.chat_bubble_outline,
                                    color: context.pic.ai,
                                    size: 20,
                                  ),
                                  const SizedBox(width: Space.md),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          c.displayTitle,
                                          style: context.text.titleSmall,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        Text(
                                          '${Fmt.shortDate(c.lastMessageAt ?? c.createdAt)}${c.isEnded ? ' · encerrada' : ''}',
                                          style: context.text.bodySmall,
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Icon(Icons.chevron_right),
                                ],
                              ),
                            ),
                            const SizedBox(height: Space.sm),
                          ],
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Intro extends StatelessWidget {
  const _Intro({required this.status});

  final AiFeatureStatus status;

  @override
  Widget build(BuildContext context) {
    final p = context.pic;
    return Container(
      padding: const EdgeInsets.all(Space.xl),
      decoration: BoxDecoration(color: p.aiContainer, borderRadius: Radii.card),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const AssistantAvatar(size: 44),
              const SizedBox(width: Space.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Assistente PicNutri',
                      style: context.text.titleMedium?.copyWith(
                        color: p.onAiContainer,
                      ),
                    ),
                    Text(
                      status.available
                          ? 'Tira dúvidas a partir dos seus registros'
                          : 'Indisponível no momento',
                      style: context.text.bodySmall?.copyWith(
                        color: p.onAiContainer,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: Space.md),
          Text(
            status.disclaimer,
            style: context.text.bodySmall?.copyWith(color: p.onAiContainer),
          ),
          if (status.quotaLabel != null) ...[
            const SizedBox(height: Space.sm),
            Text(
              'Mensagens: ${status.quotaLabel}',
              style: context.text.labelMedium?.copyWith(color: p.onAiContainer),
            ),
          ],
        ],
      ),
    );
  }
}
