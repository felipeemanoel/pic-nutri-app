import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design/design_system.dart';
import '../../../shared/widgets/feedback.dart';
import '../../../shared/widgets/state_views.dart';
import '../data/engagement_models.dart';
import '../data/engagement_repository.dart';
import 'engagement_widgets.dart';

/// Hábitos: sequência, consistência, desafios opcionais e conquistas.
class EngagementPage extends ConsumerWidget {
  const EngagementPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final value = ref.watch(engagementProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Hábitos e conquistas')),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(engagementProvider.future),
        child: AsyncValueView<Engagement>(
          value: value,
          onRetry: () => ref.invalidate(engagementProvider),
          data: (data) => ListView(
            padding: const EdgeInsets.fromLTRB(Space.page, Space.md, Space.page, Space.xxl),
            children: [
              _StatsCard(data: data),
              const SectionHeader(title: 'Desafios'),
              Text(
                'Opcionais, de 7 dias. Você pode desistir quando quiser, sem penalidade.',
                style: context.text.bodySmall,
              ),
              const SizedBox(height: Space.sm),
              for (final c in data.activeChallenges) ...[
                _ActiveChallenge(challenge: c),
                const SizedBox(height: Space.sm),
              ],
              for (final o in data.availableChallenges) ...[
                _AvailableChallenge(option: o),
                const SizedBox(height: Space.sm),
              ],
              if (data.recentChallenges.isNotEmpty) ...[
                const SectionHeader(title: 'Desafios recentes'),
                for (final c in data.recentChallenges)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(
                      c.isCompleted ? Icons.check_circle_rounded : Icons.history_rounded,
                      color: c.isCompleted ? context.pic.success : context.pic.textSecondary,
                    ),
                    title: Text(c.title),
                    subtitle: Text(
                      '${_statusLabel(c.status)} · ${c.progress} de ${c.target}',
                    ),
                  ),
              ],
              SectionHeader(
                title: 'Conquistas (${data.unlocked.length}/${data.achievements.length})',
              ),
              _AchievementGrid(items: data.achievements),
            ],
          ),
        ),
      ),
    );
  }
}

String _statusLabel(String status) => switch (status) {
  'completed' => 'Concluído',
  'expired' => 'Encerrado',
  'abandoned' => 'Interrompido',
  _ => 'Em andamento',
};

class _StatsCard extends StatelessWidget {
  const _StatsCard({required this.data});

  final Engagement data;

  @override
  Widget build(BuildContext context) => AppCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(data.message, style: context.text.bodyMedium),
        const SizedBox(height: Space.lg),
        Row(
          children: [
            Expanded(child: _Stat(label: 'Sequência atual', value: dayCount(data.currentStreak))),
            Expanded(child: _Stat(label: 'Melhor sequência', value: dayCount(data.bestStreak))),
          ],
        ),
        const SizedBox(height: Space.md),
        Row(
          children: [
            Expanded(child: _Stat(label: 'Últimos 7 dias', value: '${data.last7Days}/7')),
            Expanded(child: _Stat(label: 'Últimos 30 dias', value: '${data.last30Days}/30')),
          ],
        ),
        const SizedBox(height: Space.sm),
        Text(
          'Conta como dia registrado qualquer refeição, água ou peso anotado.',
          style: context.text.bodySmall,
        ),
      ],
    ),
  );
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => MergeSemantics(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: context.text.bodySmall),
        Text(value, style: context.text.titleMedium),
      ],
    ),
  );
}

class _ActiveChallenge extends ConsumerStatefulWidget {
  const _ActiveChallenge({required this.challenge});

  final Challenge challenge;

  @override
  ConsumerState<_ActiveChallenge> createState() => _ActiveChallengeState();
}

class _ActiveChallengeState extends ConsumerState<_ActiveChallenge> {
  bool _busy = false;

  Future<void> _abandon() async {
    final ok = await confirmAction(
      context,
      title: 'Desistir do desafio?',
      message: 'O progresso deste desafio será encerrado. Você pode começar de novo depois.',
      confirmLabel: 'Desistir',
    );
    if (!ok || !mounted) return;
    setState(() => _busy = true);
    try {
      await ref.read(engagementRepositoryProvider).abandonChallenge(widget.challenge.id);
      ref.invalidate(engagementProvider);
    } on Object catch (e) {
      if (mounted) showFailure(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.challenge;
    return AppCard(
      borderColor: context.colors.primary,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(c.title, style: context.text.titleSmall)),
              TextButton(
                onPressed: _busy ? null : _abandon,
                child: const Text('Desistir'),
              ),
            ],
          ),
          Text(c.description, style: context.text.bodySmall),
          const SizedBox(height: Space.sm),
          ProgressBar(progress: c.ratio),
          const SizedBox(height: Space.xs),
          Text('${c.progress} de ${c.target}', style: context.text.labelSmall),
        ],
      ),
    );
  }
}

class _AvailableChallenge extends ConsumerStatefulWidget {
  const _AvailableChallenge({required this.option});

  final ChallengeOption option;

  @override
  ConsumerState<_AvailableChallenge> createState() => _AvailableChallengeState();
}

class _AvailableChallengeState extends ConsumerState<_AvailableChallenge> {
  bool _busy = false;

  Future<void> _start() async {
    setState(() => _busy = true);
    try {
      await ref.read(engagementRepositoryProvider).startChallenge(widget.option.code);
      ref.invalidate(engagementProvider);
      if (mounted) showMessage(context, 'Desafio iniciado. Bons registros!');
    } on Object catch (e) {
      if (mounted) showFailure(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => AppCard(
    child: Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(widget.option.title, style: context.text.titleSmall),
              Text(widget.option.description, style: context.text.bodySmall),
            ],
          ),
        ),
        const SizedBox(width: Space.sm),
        OutlinedButton(
          onPressed: _busy ? null : _start,
          child: const Text('Começar'),
        ),
      ],
    ),
  );
}

class _AchievementGrid extends StatelessWidget {
  const _AchievementGrid({required this.items});

  final List<Achievement> items;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final columns = constraints.maxWidth > 520 ? 4 : 3;
      final width = (constraints.maxWidth - Space.sm * (columns - 1)) / columns;
      return Wrap(
        spacing: Space.sm,
        runSpacing: Space.sm,
        children: [
          for (final a in items)
            SizedBox(width: width, child: _AchievementTile(item: a)),
        ],
      );
    },
  );
}

class _AchievementTile extends StatelessWidget {
  const _AchievementTile({required this.item});

  final Achievement item;

  @override
  Widget build(BuildContext context) {
    final pic = context.pic;
    final on = item.achieved;
    return Semantics(
      label: '${item.title}: ${item.description} ${on ? 'Conquistada.' : 'Ainda não conquistada.'}',
      excludeSemantics: true,
      child: Tooltip(
        message: item.description,
        child: Container(
          padding: const EdgeInsets.all(Space.md),
          decoration: BoxDecoration(
            color: on ? pic.brandContainer : pic.surfaceMuted,
            borderRadius: BorderRadius.circular(Radii.md),
          ),
          child: Column(
            children: [
              Icon(
                on ? achievementIcon(item.icon) : Icons.lock_outline_rounded,
                color: on ? context.colors.primary : pic.textSecondary,
              ),
              const SizedBox(height: Space.xs),
              Text(
                item.title,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: context.text.labelSmall?.copyWith(
                  color: on ? pic.onBrandContainer : pic.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
