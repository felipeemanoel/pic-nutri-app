import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design/design_system.dart';
import '../data/daily_missions.dart';

class DailyMissionsCard extends ConsumerStatefulWidget {
  const DailyMissionsCard({super.key});

  @override
  ConsumerState<DailyMissionsCard> createState() => _DailyMissionsCardState();
}

class _DailyMissionsCardState extends ConsumerState<DailyMissionsCard>
    with WidgetsBindingObserver {
  Timer? _midnightCheck;
  DateTime _day = DateUtils.dateOnly(DateTime.now());

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _midnightCheck = Timer.periodic(const Duration(minutes: 1), (_) {
      final today = DateUtils.dateOnly(DateTime.now());
      if (today != _day) {
        _day = today;
        ref.invalidate(dailyMissionsProvider);
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.invalidate(dailyMissionsProvider);
    }
  }

  @override
  void dispose() {
    _midnightCheck?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(dailyMissionsProvider);
    return AppCard(
      child: switch (state) {
        AsyncData(:final value) => _Progress(data: value),
        AsyncError() => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Metas de hoje', style: context.text.titleMedium),
            const Text('Não foi possível carregar suas estrelas.'),
            TextButton.icon(
              onPressed: () => ref.invalidate(dailyMissionsProvider),
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Tentar novamente'),
            ),
          ],
        ),
        _ => const SkeletonCard(lines: 2),
      },
    );
  }
}

class _Progress extends StatelessWidget {
  const _Progress({required this.data});
  final DailyMissions data;

  @override
  Widget build(BuildContext context) {
    final colors = [
      context.colors.primary,
      const Color(0xFFAD6836),
      const Color(0xFF637C99),
      const Color(0xFFB17A00),
      const Color(0xFF7B51C9),
    ];
    final color = colors[data.level.index];
    final next = data.nextLevel;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Icon(
              data.streakBroken
                  ? Icons.sentiment_dissatisfied_rounded
                  : Icons.auto_awesome_rounded,
              color: color,
              size: 30,
            ),
            const SizedBox(width: Space.sm),
            Expanded(
              child: Text('Metas de hoje', style: context.text.titleMedium),
            ),
            Text(
              '${data.stars}/${data.missions.length}',
              style: context.text.titleMedium?.copyWith(color: color),
            ),
          ],
        ),
        const SizedBox(height: Space.md),
        Container(
          padding: const EdgeInsets.all(Space.md),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                color.withValues(alpha: .18),
                color.withValues(alpha: .04),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.emoji_events_rounded, size: 36, color: color),
                  const SizedBox(width: Space.sm),
                  Expanded(
                    child: Text(
                      'Minha conquista de hoje',
                      style: context.text.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: Space.sm),
              Text(
                'Nível ${data.level.label} · ${data.streak} ${data.streak == 1 ? 'dia seguido' : 'dias seguidos'}',
                style: context.text.titleSmall?.copyWith(color: color),
              ),
              const SizedBox(height: Space.xs),
              Text(
                data.streakBroken
                    ? 'Sua sequência terminou. Vamos começar de novo hoje?'
                    : data.streak == data.level.days && data.streak > 0
                    ? 'Parabéns! Você conquistou o nível ${data.level.label}!'
                    : data.streak > 0
                    ? 'Cada dia de cuidado vale uma conquista!'
                    : 'Seu primeiro dia começa com um registro.',
              ),
              const SizedBox(height: Space.sm),
              LinearProgressIndicator(
                value: next == null
                    ? 1
                    : ((data.streak - data.level.days) /
                              (next.days - data.level.days))
                          .clamp(0.0, 1.0),
                color: color,
                backgroundColor: color.withValues(alpha: .12),
                minHeight: 6,
                borderRadius: BorderRadius.circular(8),
              ),
              const SizedBox(height: Space.xs),
              Text(
                next == null
                    ? 'Diamante conquistado! Continue sua sequência.'
                    : 'Faltam ${next.days - data.streak} dias para ${next.label}',
                style: context.text.bodySmall,
              ),
            ],
          ),
        ),
        const SizedBox(height: Space.sm),
        for (final mission in data.missions)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: Space.xs),
            child: Row(
              children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 350),
                  child: Icon(
                    key: ValueKey(mission.completed),
                    mission.completed
                        ? Icons.star_rounded
                        : Icons.star_outline_rounded,
                    color: mission.completed
                        ? const Color(0xFFB17A00)
                        : context.pic.textSecondary,
                  ),
                ),
                const SizedBox(width: Space.sm),
                Expanded(child: Text(mission.title)),
                if (mission.completed)
                  Icon(
                    Icons.check_circle_rounded,
                    size: 18,
                    color: context.pic.success,
                  ),
              ],
            ),
          ),
        const SizedBox(height: Space.xs),
        Text(
          'Recorde: ${data.bestStreak} ${data.bestStreak == 1 ? 'dia' : 'dias'}. Um dia sem registro reinicia a sequência.',
          style: context.text.bodySmall,
        ),
      ],
    );
  }
}
